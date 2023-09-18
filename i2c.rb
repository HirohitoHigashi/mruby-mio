# coding: utf-8

##
# I2C namespace
#
module I2C
  def self.new(node = "/dev/i2c-1", *params)
    I2C::Device.new(node, *params )
  end
end


##
# I2C Device driver
# only implement high-level methods.
#
class I2C::Device
  ##
  # constructor
  #
  #@param  [String]  node       device node of I2C
  #@option params               dummy.
  #
  def initialize(node, *params)
    @device = File.open(node, "r+:ASCII-8BIT")
  end


  ##
  # Reads data of read_bytes bytes from the device with the address i2c_adrs_7.
  #
  #@param [Integer] i2c_adrs_7  I2C slave address (7bit address)
  #@param [Integer] read_bytes  read bytes.
  #@param [Integer,String,Array<Integer>] param  output data before reading.
  #@return [String]     reading datas.
  #
  def read( i2c_adrs_7, read_bytes, *param )
    out_data = _rebuild_output_data( param )

    _use_slave_adrs( i2c_adrs_7 )
    @device.syswrite( out_data )
    @device.sysread( read_bytes )
  end


  ##
  # Writes data specified in outputs to the device with the address i2c_adrs_7.
  #
  #@param [Integer] i2c_adrs_7  I2C slave address (7bit address)
  #@param [Integer,String,Array<Integer>] outputs  output data.
  #@return [Integer]     number of bytes actually write.
  #
  def write( i2c_adrs_7 , *outputs )
    out_data = _rebuild_output_data( outputs )

    # TODO data.empty? の時どうするか？

    _use_slave_adrs( i2c_adrs_7 )
    @device.syswrite( out_data )
  end


  private
  def _use_slave_adrs( i2c_adrs_7 )
    @device.ioctl( 0x0703, i2c_adrs_7 )         # see i2c-dev.h
  end

  def _rebuild_output_data( arg )
    data = ""
    arg.flatten.each {|d|
      case d
      when Integer
        data << d.chr
      when String
        data << d
      else
        raise ArgumentError
      end
    }

    return data
  end

end
