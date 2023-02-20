# Battery life

When transmitting data, an nrf52840 dongle consumes around 1000 uA (1mA)\
In sleep mode, it consumes 20 uA. \
A Good coin cell battery can have around 200 mAh. \
\
So sleep battery life. 200mAh/20uA = 10000 hrs in deep sleep mode. 10000hrs > 416 days > a bit more than a year.

In transmitting:\
\- Single press activates advertising, and if there is no next activity for half a second then advertising turns off. \
\- So we have a consumption of 1mA during half second for a single press. So about Coin cell has 200 mAh -> 200 \* 3600 mAsec or **7200 single presses.**&#x20;

But in general, cheap batteries will have less capacity.

Consumption can also vary on different boards. My measurements were made with the nrf52840 dongle.

### How does this compare with HID?

2532 uA (2.532 milliamperes) constant draw is seen on an HID connection with an nrf52840. So it consumes more than 2.5x more power.&#x20;
