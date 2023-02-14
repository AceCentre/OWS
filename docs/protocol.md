# Protocol

We are using a Nordic nrf52840 chipset for our work - but really any number of Bluetooth boards should support this technique as we are really just using the advertising feature of BLE.&#x20;

### Advertisement (Switch side)

On the advertisement (switch sending) board there are two aspects. Pairing and sending

#### Pairing

* A press of the Pairing button will wake the device up and place it into pairing mode.
* A set of pairing packages are advertised

#### Switch depress:

* When switch is pressed  board starts collecting button data into packages and advertise them.
* It then sends out packages. These data packages are changed every 100ms. Each package has recorded 10 buttons states with interval 10 ms(which in total 100ms).
* After some time of inactivity (5sec default) it will go back to sleep.

### Central (Receiving):

#### Pairing



#### Switch depress:

* It scans BLE devices and for the MAC address device it receives package which has recorded button states over 100ms and then replays these states via USB keyboard (of course you could choose to do this as a joystick button or whatever. That I'm not too bothered about)

