# Battery life

When transmitting data, a nrf52840  dongle consumes around 1000 uA (1mA)\
In sleep mode, it consumes 20 uA. \
A Good coin cell battery can have around 200 mAh. \
\
So sleep battery life. 200mAh/20uA = 10000 hrs in deep sleep mode. 10000hrs > 416 days > a bit more than a year.

In transmitting - it's not so great - 200 presses. **We need to work on this!**

But in general, cheap batteries will have less capacity.

Consumption can also vary on different boards. My measurements were made with the nrf52840 dongle.
