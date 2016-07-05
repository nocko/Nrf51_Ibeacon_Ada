# iBeacon written in Ada for nRF51822

An LED on pin 12 will be illuminated while the High Frequency Xtal
Oscillator is running. This corresponds closely to the time period
during which the core is running.

## Building

1. Download [GNAT GPL ARM-ELF toolchain from AdaCore](http://libre.adacore.com/download/configurations)
2. Prepare the build:
   ~~~ bash
   git clone https://github.com/nocko/Nrf51_Ibeacon_Ada.git
   cd Nrf51_Ibeacon_Ada
   git submodule init
   git submodule update
   ~~~

3. Press Return: `gprbuild`

4. Load onto your board in your usual way (OpenOCD, JLink, &c)

## Inspiration

[OpenBeacon](http://www.openbeacon.org/)
([Repo](https://github.com/meriac/openbeacon-ng)).
[@meriac](https://github.com/meriac) is a clever man.
