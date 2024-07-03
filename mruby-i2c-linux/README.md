# I2C class using Linux i2cdev.

## Overview

This is an implementation of the I2C class library for Linux.
Follows [mruby, mruby/c common I/O API guidelines.](https://github.com/mruby/microcontroller-peripheral-interface-guide)

This library uses the Linux i2cdev device driver.
Works well on 32-bit and 64-bit OS.


## Installation

    $ gem install mruby-i2c-linux


## Features

  * This library only implements the high-level methods that the guidelines say.
  * This library only supports master devices with 7-bit addresses.


## Operation check target

  * [Raspberry Pi 4](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/)
  * [Armadillo-IoT G3](https://armadillo.atmark-techno.com/armadillo-iot-g3)


## Usage

about RaspberryPi...

```
# Connect pin #3 as SDA, #5 as SCL.

require "mruby/i2c"

# create instance
i2c = I2C.new("/dev/i2c-1")

# Write to device at address 0x5c, data 0x20, 0x90.
i2c.write( 0x5c, 0x20, 0x90 )

# Read 5 bytes from the device at address 0x5c.
# Outputs 0xa8 before reading.
s = i2c.read( 0x5c, 5, 0xa8 )
```

Other case, see original guidelines.
https://github.com/mruby/microcontroller-peripheral-interface-guide/blob/main/mruby_io_I2C_en.md


## Licence

BSD 3-Clause License. see LICENSE file.
