# SPI class using Linux spidev.

![ADXL345 Demo](img/adxl345_demo.gif) >> [source code](test/ADXL345_Accelerometer.rb)

## Overview

This is an implementation of the SPI class library for Linux.  
Follows [mruby, mruby/c common I/O API guidelines.](https://github.com/mruby/microcontroller-peripheral-interface-guide)

This library uses the Linux spidev device driver.

## Installation

    $ gem install mruby-linux-spi


## Features

  * This class defines only master devices and transfers in 8-bit units.
  * The Chip Select (CS/SS) will be managed spidev device driver automatically.

## Usage

about RaspberryPi...

```
# Connect pin #19 as MOSI, #21 as MISO, #23 as SCLK, #24 as CS.

require "mruby/spi"

# create instance
spi = SPI.new()

# read 4 bytes (send out 0x00 x 4bytes)
s = spi.read(4)
```

Other case, see original guidelines.  
https://github.com/mruby/microcontroller-peripheral-interface-guide/blob/main/mruby_io_SPI_en.md


## Licence

BSD 3-Clause License. see LICENSE file.
