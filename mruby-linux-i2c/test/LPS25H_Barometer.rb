#
# ST LPS25H
# MEMS pressure sensor: 260-1260 hPa absolute digital output barometer
# https://www.st.com/ja/mems-and-sensors/lps25h.html
#

require "mruby/i2c"


#
# define global functions.
#
def to_int16( b1, b2 )
  return (b1 << 8 | b2) - ((b1 & 0x80) << 9)
end
def to_uint24( b1, b2, b3 )
  return b1 << 16 | b2 << 8 | b3
end


#
# define class
#
class LPS25H
  I2C_ADRS = 0x5c

  #
  # instance initializer
  #
  def initialize( i2c_bus, address = I2C_ADRS )
    @bus = i2c_bus
    @address = address
  end

  #
  # sensor initialize
  #
  def init()
    @bus.write( @address, 0x20, 0x90 )
  end

  #
  # measure
  #
  def meas
    s = @bus.read( @address, 5, 0xa8 )
    ret = {
      :pressure => to_uint24( s.getbyte(2), s.getbyte(1), s.getbyte(0) ).to_f / 4096,
      :temperature => 42.5 + to_int16(s.getbyte(4), s.getbyte(3)).to_f / 480
    }

    return ret
  end
end


##
# main
#
puts "LPS25H Barometer"

i2c = I2C.new()

lps25h = LPS25H.new( i2c )
lps25h.init()

while true
  data = lps25h.meas()

  printf( "Temp:%5.1f C  ", data[:temperature] )
  printf( "Pres:%8.2f hPa\n", data[:pressure] )

  sleep 1
end
