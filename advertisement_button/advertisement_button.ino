#include <bluefruit.h>

//#define DEBUG                          // disables deep sleep and enables waiting for serial port

#define LED LED_BLUE                    // status led
#define PAIR_BUTTON A0                 // pairing button pin

uint8_t n_buttons = 4;                 // number of buttons to init and advertise
uint8_t button_pins[] = {A1,A2,A3,A4}; // buttons pins
bool pressed_button = 0;               // flag to check if there buttons pressed

uint32_t inactivity_timeout = 500;     // stop advertising buttons data after this timeout
uint32_t sleep_timeout = 5000;         // go to sleep mode after this timeout 
uint32_t pairing_timeout = 500;        // stop advertising pairing pakcage after this timeout     

// transmit power in dBm
// Supported values: -40dBm, -20dBm, -16dBm, -12dBm, -8dBm, -4dBm, 0dBm, +2dBm, +3dBm, +4dBm, +5dBm, +6dBm, +7dBm and +8dBm 
int8_t tx_power = 4;
 
uint32_t last_action = 0;

uint16_t button_packs[] = {0,0,0,0};
uint8_t package_size = 8;
uint8_t package_i = 0;
uint8_t sample_n = 0;
uint16_t set_bit;

uint8_t button_states[] = {0,0,0,0};
uint8_t button_states_prev[] = {0,0,0,0};

uint8_t pair_button_state = 0;
uint8_t pair_button_state_prev = 0;

uint32_t read_interval = 30;

uint8_t pair_package[] = {0xFF,0xFF,0x9C,0x7C,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

struct adv_package
{
  uint16_t manufacturer_id;
  uint8_t  package_index;
  uint8_t button_packs[4][4];
} buttons_data = {
  .manufacturer_id = 0xFFFF,
};

bool pairing = false;
bool sampling = false;

void update_advertisement_data() {  
  buttons_data.package_index = package_i;

  for(uint8_t i = 0; i < n_buttons; i++) {
    for(uint8_t j=3;j>0;j--) {
      buttons_data.button_packs[j][i] = buttons_data.button_packs[j-1][i];
    }
    buttons_data.button_packs[0][i] = button_packs[i];
  }
  
  Bluefruit.Advertising.clearData();    
  Bluefruit.Advertising.addManufacturerData(&buttons_data, sizeof(buttons_data));
}

void set_pair_data() {
  Bluefruit.Advertising.clearData();    
  Bluefruit.Advertising.addManufacturerData(pair_package, sizeof(pair_package));
}

void setup_advertisment(void)
{   
  // Advertising packet
  update_advertisement_data();
  //Bluefruit.Advertising.addFlags(BLE_GAP_ADV_FLAGS_LE_ONLY_GENERAL_DISC_MODE);
  Bluefruit.Advertising.setType(BLE_GAP_ADV_TYPE_NONCONNECTABLE_SCANNABLE_UNDIRECTED);

  Bluefruit.Advertising.restartOnDisconnect(true);
  Bluefruit.Advertising.setInterval(32, 32);    // in units of 0.625 ms
  Bluefruit.Advertising.setFastTimeout(30);      // number of seconds in fast mode
  //Bluefruit.Advertising.start(ADV_TIMEOUT);      // Stop advertising entirely after ADV_TIMEOUT seconds 
}

void enter_deepsleep() {
  digitalWrite(LED, LOW);                     
  pinMode(button_pins[0],  INPUT_PULLUP_SENSE);
  sd_power_system_off();
}

void setup() 
{
  set_bit = 1 << package_size;
  
  // configure buttons as input with a pullup (pin is active low)
  for(uint8_t i = 0; i < n_buttons; i++) {    
    pinMode(button_pins[i], INPUT_PULLUP);
  }
  
  pinMode(PAIR_BUTTON, INPUT_PULLUP);
  
  Serial.begin(115200);
  #ifdef DEBUG                      
    while ( !Serial ) delay(10);   // for nrf52840 with native usb
  #endif

  Bluefruit.begin();
  Bluefruit.setTxPower(4);
  
  // Set up advertisement
  setup_advertisment();

  /*
  ble_gap_addr_t button_address = Bluefruit.getAddr();
  Serial.print("Button MAC address: ");
  Serial.printf("%X");
  for(int i=1;i<6;i++) {
    Serial.printf(":%X", button_address.addr[i]);    
  }
  Serial.println();
  */
  
  Serial.printf("Board is set up after: %ums\n", (millis()-last_action));
  pinMode(LED, OUTPUT);
  digitalWrite(LED, HIGH);
  last_action = millis();
}

void loop() {
  // reading buttons states
  pressed_button = false;
  for(uint8_t i = 0; i < n_buttons;i++) {
    button_states[i] = !digitalRead(button_pins[i]);
    if(button_states[i] != button_states_prev[i]) {
      sampling = true;
      pairing = false;

      last_action = millis();
    }
    if(button_states[i] == 1){
      pressed_button = true;
    }
    button_states_prev[i] = button_states[i];
  }

  // reading pairing button state
  pair_button_state = ! digitalRead(PAIR_BUTTON);
  if(pair_button_state == 1 && pair_button_state_prev == 0) {    
    set_pair_data();
    
    if(!Bluefruit.Advertising.isRunning()) {
      Bluefruit.Advertising.start();
      Serial.println("Starting pairing advertisement");
    }

    pairing = true;        
    sampling = false;

    last_action = millis();
  }
  pair_button_state_prev = pair_button_state;

  
  if(sampling) {
    if((millis() - last_action) > inactivity_timeout && pressed_button == false && Bluefruit.Advertising.isRunning()) {
      Bluefruit.Advertising.stop();
      Serial.println("Stopping button advertisement");
      Serial.println("clearing advertising data");
      for(uint8_t i = 0; i < n_buttons; i++) {
        for(uint8_t j=0;j<4;j++) {
          //Serial.printf("%u:%u ", i,j);
          buttons_data.button_packs[i][j] = 0;
        }
        //Serial.println();
      }
      //Serial.println();
      
      sampling = false;
            
    } else {
      if(sample_n < package_size) {
        if(sample_n == 0){
          //Serial.printf("Gathering new package\n");
        }

        for(uint8_t i = 0; i < n_buttons; i++) {
          //Serial.printf("Button #%u state: %u\n", (i+1), button_state);
          if(button_states[i]) {
            button_packs[i] = button_packs[i] | set_bit;
          }
          button_packs[i] = button_packs[i] >> 1;
        }
        sample_n++;  
      } else {
        //Serial.printf("Package gathered; id: %X; sample: %X\n", package_i, button_packs[0]);
        update_advertisement_data();
        
        // start button avertising after package was gathered 
        if(!Bluefruit.Advertising.isRunning()) {
          Bluefruit.Advertising.start();
          Serial.println("Starting button advertisement");
        }
        
        for(uint8_t i = 0; i < n_buttons; i++) {
          button_packs[0] = 0;
        }
        
        sample_n = 0;
        package_i++;        
      }
    }
  }

  if(pairing) {
    if((millis() - last_action) > pairing_timeout && Bluefruit.Advertising.isRunning()) {
      Bluefruit.Advertising.stop();
      pairing = false;
      Serial.println("Stopping pairing advertisement");      
    }    
  }

  #ifndef DEBUG
  if((millis() - last_action) > sleep_timeout && pressed_button == false) {
    enter_deepsleep();
  }
  #endif
  
  delay(read_interval);
}
