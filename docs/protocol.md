# Protocol



{% hint style="info" %}
We are using a Nordic nrf52840 chipset for our work - but really any number of Bluetooth boards should support this technique as we are really just using the advertising feature of BLE.&#x20;
{% endhint %}

The Open Wireless Switch (OWS) system is designed to enable wireless communication between a switch (or button) and a central receiving device via Bluetooth Low Energy (BLE). This system is composed of two main components: the Advertisement (Switch Sending) board and the Central (Receiving) device. The switch board can enter pairing mode, send button press data, and enter sleep mode after a period of inactivity. The central device scans for BLE signals, pairs with the switch, and processes the button press data to simulate USB keyboard input or other actions.

#### Advertisement (Switch Sending) Board

The Advertisement board is responsible for sending BLE signals that represent button presses. It operates in two main modes: Pairing and Sending.

**1. Pairing Mode**

* **Activation**: Pairing mode is activated when the Pairing button on the Advertisement board is pressed.
* **Behavior**: When the device enters pairing mode, it wakes up from sleep and begins advertising a set of pairing packages. These packages contain specific data that allow the Central (Receiving) device to recognize and pair with the switch.
* **Purpose**: Pairing mode is essential for establishing a connection between the switch and the receiving device. It allows the receiving device to identify the switch's MAC address and prepare for subsequent data transmission.

**2. Sending Mode**

* **Switch Depress (Button Press)**:
  * When a button (or switch) on the Advertisement board is pressed, the board begins to collect button press data. This data is organized into packages.
  * Each data package represents the state of the button over a period of 100ms. Within this timeframe, the button state is sampled at 10ms intervals, resulting in 10 button states per package.
  * The data packages are advertised (broadcasted) via BLE at a rate of one package every 100ms.
* **Inactivity & Sleep Mode**:
  * After the button is released, if there is no further button activity for a specified period (default is 5 seconds), the Advertisement board will automatically enter sleep mode to conserve power.
  * In sleep mode, the device stops advertising and goes into a low-power state until it is reawakened by either another button press or the Pairing button.

#### Central (Receiving) Device

The Central device is responsible for scanning for BLE signals from the Advertisement board, pairing with it, and processing the received button press data.

**1. Pairing Mode**

* **Scanning**:
  * The Central device continuously scans for BLE devices in the vicinity. When it detects the pairing packages from the Advertisement board, it reads the MAC address and pairs with the device.
  * Pairing allows the Central device to recognize the specific switch and prepare to receive button press data.

**2. Button Press Data Handling**

* **Receiving Data Packages**:
  * After pairing, the Central device begins to receive the advertised data packages from the Advertisement board whenever the button is pressed.
  * Each package contains the button states recorded over 100ms. These packages are transmitted and received in real-time.
* **Processing and Replay**:
  * Upon receiving a data package, the Central device processes the button states contained within it.
  * The Central device can then replay these button states via USB as if they were keyboard inputs. This allows the button press on the switch to be translated into a corresponding action on the Central device, such as pressing a specific key on a keyboard.
  * The system is flexible, allowing the received data to be interpreted in different ways (e.g., as joystick input or other control mechanisms).

#### Detailed Specifications

**1. Manufacturer ID**

* **Purpose**: The Manufacturer ID is a unique identifier used in BLE advertising packets to distinguish the specific manufacturer or type of device. In the OWS system, this ID is used to identify the Advertisement board during the pairing process and when sending button press data.
* **Value**: The Manufacturer ID used in the OWS system is `0xFFFF`.
* **Usage**:
  * This ID is embedded in the BLE advertising packets sent by the Advertisement board.
  * The Central (Receiving) device listens for advertising packets with this specific Manufacturer ID to identify and pair with the switch.
  * The Manufacturer ID is included in every data package, allowing the Central device to verify the source of the received data.

**2. Button Pair Packages**

* **Purpose**: The button pair packages are special BLE advertising packets sent when the Advertisement board enters pairing mode. These packages contain a predefined data structure that allows the Central device to recognize the board and establish a connection.
* **Package Structure**:
  *   The button pair package is a fixed-size byte array with the following structure:

      ```csharp
      csharpCopy code[0xFF, 0xFF, 0x9C, 0x7C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
      ```
  * **Fields**:
    * **Bytes 0-1**: Manufacturer ID (`0xFFFF`).
    * **Bytes 2-3**: Pairing Identifier (`0x9C7C`).
    * **Bytes 4-19**: Reserved for additional data or padding (all `0x00` in this case).
* **Functionality**:
  * When the Pairing button on the Advertisement board is pressed, the board begins broadcasting these pairing packages.
  * The Central device scans for these packages and, upon detecting the correct Manufacturer ID and Pairing Identifier, will pair with the switch.

**3. Button Press Data Packages**

* **Purpose**: The button press data packages are BLE advertising packets sent by the Advertisement board when a button is pressed. These packages contain recorded button states over a short period (100ms) and are used by the Central device to emulate input actions.
* **Package Structure**:
  *   Each button press data package contains the following fields:

      ```java
      javaCopy code[Manufacturer ID (2 bytes), Package Index (1 byte), Button Data (4x4 bytes)]
      ```
  * **Fields**:
    * **Manufacturer ID (Bytes 0-1)**: `0xFFFF`.
    * **Package Index (Byte 2)**: A byte that increments with each new package, allowing the Central device to track the sequence of packages.
    * **Button Data (Bytes 3-18)**: A 4x4 matrix where each row represents a different button, and each column represents a 10ms interval within the 100ms timeframe. Each entry in this matrix is a 4-bit value (0 or 1), indicating whether the button was pressed (`1`) or not (`0`) at that specific time interval.
* **Data Layout Example**:
  *   For a setup with 4 buttons, a data package might look like this:

      ```csharp
      [0xFF, 0xFF, 0x01, 0x0A, 0x05, 0x03, 0x0F, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
      ```

      * **Manufacturer ID**: `0xFFFF` (Bytes 0-1)
      * **Package Index**: `0x01` (Byte 2)
      * **Button Data**:
        * Button 1 states over 100ms: `0x0A` (Byte 3)
        * Button 2 states over 100ms: `0x05` (Byte 4)
        * Button 3 states over 100ms: `0x03` (Byte 5)
        * Button 4 states over 100ms: `0x0F` (Byte 6)
        * Remaining bytes are padded with `0x00` for alignment.
* **Button States Interpretation**:
  *   Each button state byte can be interpreted as a sequence of bits representing the state of the button at each 10ms interval within the 100ms timeframe. For example, the byte `0x0A` (Button 1) could represent the following binary sequence:

      ```
      00001010
      ```

      * This indicates that the button was pressed during the 4th and 2nd 10ms intervals and released during the others.

**4. Buttons Configuration**

* **Number of Buttons**: The system supports up to 4 buttons by default, but this can be extended if needed by adjusting the data package format.
* **Button Identifiers**:
  * Buttons are identified numerically (Button 1, Button 2, etc.).
  * Each button’s state is recorded separately in the data package, allowing the Central device to determine which button was pressed and when.
