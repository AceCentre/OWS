# How to get started

To try this out get two [nrf52840 feather express boards](https://www.adafruit.com/product/4062) from adafruit. Then load up the firmware for each board (its a arduino sketch - you want to first follow the guide [here](https://learn.adafruit.com/introducing-the-adafruit-nrf52840-feather/arduino-bsp-setup)).

The firmware for the switch sending part is called _advertisement_. You need to add two switches - one for the actual switch (use a switch jack) and a tactile swich for pairing.

The firmware for the recievfing part is known as the _central_ firmware. There should be defined a LED for indicating pairing. By default it's the red led of a nrf52840 Feather express.

When pairing button is pressed on the advertisement board it will send a specific pairing package and dongle receives this package and MAC address of the board it will listen for. The MAC is saved in flash memory and can be read later on start of dongle code.

Note - to save battery the advertisement board is set to sleep. Pressing the switch will wake it up - all in all this takes around 1 second.

### Software only technique

So you can use a nrf52840 USB dongle to receive the switch press - or right now you could do it in software alone. See the python directory for this code.
