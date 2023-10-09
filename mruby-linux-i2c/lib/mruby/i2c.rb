#
# I2C class using Linux i2cdev.
#
# Copyright (c) 2023 Shimane IT Open-Innovation Center.
#
# see: LICENSE file.
# see: https://github.com/mruby/microcontroller-peripheral-interface-guide/blob/main/mruby_io_I2C_en.md
#
# frozen_string_literal: true
#

require_relative "i2c/version"

##
# I2C namespace
#
module I2C
  ##
  # constructor
  #
  #@see I2C::LinuxI2Cdev.initialize
  #
  def self.new(node = "/dev/i2c-1", *params)
    I2C::LinuxI2Cdev.new(node, *params)
  end
end


##
# I2C bus driver
#
# only implement high-level methods.
#
class I2C::LinuxI2Cdev

  # see /usr/include/linux/i2c.h i2c-dev.h
  I2C_SLAVE = 0x0703
  I2C_RDWR  = 0x0707
  I2C_M_RD  = 0x0001


  ##
  # constructor
  #
  #@param [String]  node        device node of I2C
  #@param [nil]  params         dummy.
  #@see I2C.new
  #
  def initialize(node, *params)
    @device = File.open(node, "r+:ASCII-8BIT")
  end


  def read
  end


  ##
  # Reads data of read_bytes bytes from the device with the address i2c_adrs_7.
  # using sysread
  #
  #@see #read_ioctl
  #
  def read_sysread( i2c_adrs_7, read_bytes, *param )
    out_data = _rebuild_output_data( param )

    _use_slave_adrs( i2c_adrs_7 )
    @device.syswrite( out_data )  if !out_data.empty?
    @device.sysread( read_bytes )
  end


  ##
  # Reads data of read_bytes bytes from the device with the address i2c_adrs_7.
  # using ioctl
  #
  #@param [Integer] i2c_adrs_7  I2C slave address (7bit address)
  #@param [Integer] read_bytes  read bytes.
  #@param [Integer,String,Array<Integer>] param  output data before reading.
  #@return [String]     reading datas.
  #
  def read_ioctl( i2c_adrs_7, read_bytes, *param )
    out_data = _rebuild_output_data( param )
    recv_data = "\x00".b * read_bytes

    # prepare the struct i2c_msg[2]
    # struct i2c_msg {
    #        __u16 addr;
    #        __u16 flags;
    #        __u16 len;         << hidden padding _u16
    #        __u8 *buf;
    # };
    i2c_msg_s = [ i2c_adrs_7, 0, out_data.bytesize, 0,
                  [out_data].pack('p').unpack1('J') ].pack('SSSSJ')
    i2c_msg_r = [ i2c_adrs_7, I2C_M_RD, read_bytes, 0,
                  [recv_data].pack('p').unpack1('J') ].pack('SSSSJ')

    # prepare the struct i2c_rdwr_ioctl_data
    # struct i2c_rdwr_ioctl_data {
    #         struct i2c_msg *msgs;   /* pointers to i2c_msgs */
    #         __u32 nmsgs;            /* number of i2c_msgs */
    # };
    if out_data.empty?
      arg = [ [i2c_msg_r            ].pack('P').unpack1('J'), 1 ].pack('JL')
    else
      arg = [ [i2c_msg_s + i2c_msg_r].pack('P').unpack1('J'), 2 ].pack('JL')
    end

    @device.ioctl( I2C_RDWR, arg )
    return recv_data
  end

  alias read read_ioctl


  ##
  # Writes data specified in outputs to the device with the address i2c_adrs_7.
  #
  #@param [Integer] i2c_adrs_7  I2C slave address (7bit address)
  #@param [Integer,String,Array<Integer>] outputs  output data.
  #@return [Integer]     number of bytes actually write.
  #
  def write( i2c_adrs_7 , *outputs )
    out_data = _rebuild_output_data( outputs )

    _use_slave_adrs( i2c_adrs_7 )
    @device.syswrite( out_data )
  end


  private
  def _use_slave_adrs( i2c_adrs_7 )
    @device.ioctl( I2C_SLAVE, i2c_adrs_7 )
  end

  def _rebuild_output_data( arg )
    data = "".b
    arg.flatten.each {|d|
      case d
      when Integer
        data << d.chr
      when String
        data << d.force_encoding(Encoding::ASCII_8BIT)
      else
        raise ArgumentError
      end
    }

    return data
  end

end
