# Battery life

When transmitting data, an nrf52840 dongle consumes around 1000 uA (1mA)\
In sleep mode, it consumes 20 uA. \
A Good coin cell battery can have around 200 mAh. \
\
So sleep battery life. 200mAh/20uA = 10000 hrs in deep sleep mode. 10000hrs > 416 days > a bit more than a year.

In transmitting:\
\- Single press activates advertising, and if there is no next activity for half a second then advertising turns off. \
\- So we have a consumption of 1mA during half second for a single press. So about Coin cell has 200 mAh -> 200 \* 3600 mAsec or **7200 single presses.**&#x20;

How long will then a average coin cell battery last in sleep mode only?

* 500 mAh / 0.02 mA = 25,000 hours ≈ 1,042 days or about 2.85 years How long will the battery last in active mode only?
* 500 mAh / 1 mA = 500 hours ≈ 20.83 days”

But in general, cheap batteries will have less capacity.

**If we have a 1000 mAh battery/ 0.02 mA = 50,000 hours ≈ 2,083 days or about 5.7 years sleep mode. Active mode only: 1000 mAh / 1 mA = 1000 hours ≈ 41.67 days**

### How does this compare with HID?

2532 uA (2.532 milliamperes) constant draw is seen on an HID connection with an nrf52840. So it consumes more than 2.5x more power.&#x20;
