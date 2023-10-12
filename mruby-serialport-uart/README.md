# UART class using serialport gem.

## Overview

This is an implementation of the UART class library.
Follows [mruby, mruby/c common I/O API guidelines.](https://github.com/mruby/microcontroller-peripheral-interface-guide)

This is a wrapper for the [serialport gem](https://rubygems.org/gems/serialport).

## Installation

    $ gem install mruby-serialport-uart


## Features

  * Read and write by serialport.
  * Communication parameters can be changed at any time.
  * It has linewise methods and binary methods.


## Usage

about RaspberryPi...

```
#

require "mruby/uart"   # or "mruby/uart/serialport"


```

Other case, see original guidelines.

https://github.com/mruby/microcontroller-peripheral-interface-guide/blob/main/mruby_io_UART_en.md


## Licence

BSD 3-Clause License. see LICENSE file.
