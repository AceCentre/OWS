---
description: Introduction
---

# Open Wireless Switch (OWS)

{% hint style="danger" %}
This project is very much **experimental** and **work-in-progress**. We have not yet all the aims of the work and may never get there. We hope though that key learning may be useful for others developing wireless switches in the future - HID or BLE advertisement.&#x20;
{% endhint %}

### Background

There are a lot of various switches in existence. The typical connection for this has been a 3.5mm jack and socket. For a computer to understand this switch press, you require a box that turns this into something useful. This has typically been either a keypress, mouse press or a game controller button. \
\
Being tied to a lead can be a nuisance and risk for some people. We need a way of wireless switches existing. You can do this right now either using a form of Radio or Bluetooth - where several commercial switches and switch boxes exist and act as a Bluetooth Keyboard. But, this protocol can be both costly in respect of battery life and in overheads to support a Bluetooth keyboard.&#x20;

Some companies have developed lower power switches using Bluetooth, but this is proprietary, and the technique is not open to allow others to use.&#x20;

### Aim&#x20;

* Define an open protocol for wireless switches that allows anyone to develop a switch for any system - and equally; software developers support the OWS standard
* It should be as energy conservative as possible. People should expect a battery life of months and years - not hours and days.&#x20;
* It should work with no dongle on the receiving end. This is because many devices either have no port or it becomes difficult to access a port on a computer. But of course, having a dongle may be preferable and allow support to systems which can't/won't be supported
* It should have a way of working with physical devices too
* It should allow for 1+ multiple switches to use the same protocol
* It should have documented the response times&#x20;
* It should be open to scrutiny and improvements from anyone

### What does this do?

As of right now, we have working firmware for a Bluetooth chipset and software to receive the switches without the hardware. This is currently in python. We are open to discussion about the protocol and code.&#x20;

### What techniques have you considered?

Let's consider the different ways we can wirelessly create a switch (let us know if we have missed something!)

| Technique            | Pros                                 | Cons                                                                                                                                               |
| -------------------- | ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| LoRa - Radio e.g 433 | Low low Low power                    | You would need a sender and receiving dongle.                                                                                                      |
| IR                   | Low power                            | Unreliable, needs a dongle to receive and send                                                                                                     |
| Chirp/Sound          | Low power ?                          | Now hard to do this as Spotify bought chrip. Could design your own thing.. but environmental noise? Unreliable? Fiddly on designing receiving code |
| Bluetooth HID        | Ubiquotous, Receiving easy           | Power hungry. A lot of wasted bandwith                                                                                                             |
| Bluetooth Beacon     | Low Power, Recieving straightforward | Need a dongle on some devices where a background task can't run (e.g. iOS)                                                                         |
