#
# ADXL345 Digital Accelerometer
# https://www.analog.com/en/products/adxl345.html
#

require "mruby/spi"


#
# convert data to int16
#
def to_int16( b1, b2 )
  return (b1 << 8 | b2) - ((b1 & 0x80) << 9)
end

#
# Sensor device class
#
class SPI_ADXL345
  ##
  # constructor
  #
  def initialize( spi_bus )
    @bus = spi_bus
  end

  ##
  # ident device
  #
  def identify()
    res = @bus.transfer( 0b1000_0000, 1 )       # read device ID
    return res.getbyte(1) == 0xe5

  rescue
    return false
  end

  ##
  # sensor initialize
  #
  def init()
    @bus.write( 0x2d, 0b0000_1000 ) # POWER_CTL: Measure=1
    @bus.write( 0x31, 0b0000_1000 ) # DATA_FORMAT: FULL_RES=1
                                    #              Range=00 (2g)
  end

  ##
  # measure
  #
  def measure()
    # wait for data ready.
    while true
      res = @bus.transfer( 0b1000_0000|0x30, 1 ) # Read INT_SOURCE(30)
      break if (res.getbyte(1) & 0x80) != 0      # Check DATA_READY bit
    end

    # get X,Y,Z data
    res = @bus.transfer( 0b1100_0000|0x32, 6 )   # Read DATA X,Y,Z

    data = {}
    data[:x] = to_int16( res.getbyte(2), res.getbyte(1) ).to_f / 256
    data[:y] = to_int16( res.getbyte(4), res.getbyte(3) ).to_f / 256
    data[:z] = to_int16( res.getbyte(6), res.getbyte(5) ).to_f / 256

    return data
  end
end


#
# display
#
def display( x, y, z )
  # init
  width,height = 41,24
  xw,yw,zw = 20,12,15
  x0,y0 = 20,15
  buf = []
  height.times { buf << " " * width }

  # projection 3D to 2D but very simply method.
  x1 = x0 + (x * xw + y * yw).to_i
  y1 = y0 - (y * yw + z * zw).to_i

  # X-axis
  xp,yp = x0+1,y0
  xw.times {|n|
    buf[yp][xp] = "-"
    xp += 1
  }

  # Y-axis
  xp,yp = x0+1,y0-1
  yw.times {
    buf[yp][xp] = "/"
    xp += 1
    yp -= 1
  }

  # Z-axis
  xp,yp = x0,y0-1
  zw.times {
    buf[yp][xp] = "|"
    yp -= 1
  }

  # draw line.
  xp,yp = x0,y0
  dx = (x1 - x0).abs
  dy = (y1 - y0).abs
  sx = x0 < x1 ? 1 : -1
  sy = y0 < y1 ? 1 : -1
  err = dx - dy

  while 0 <= xp && xp < width && 0 <= yp && yp < height
    buf[yp][xp] = "#"
    break  if xp == x1 && yp == y1

    err2 = 2 * err
    if err2 > -dy
      err -= dy
      xp += sx
    end
    if err2 < dx
      err += dx
      yp += sy
    end
  end

  printf("\033[1;1H%15s[Z:%5.2f]      [Y:%5.2f]\n", "", z, y)
  buf[y0] << sprintf(" [X:%5.2f]", x)
  buf.each {|line| puts line }
end


#
# main
#
spi = SPI.new(mode:3)
sensor = SPI_ADXL345.new( spi )

if !sensor.identify()
  puts "Sensor not found"
  exit
end

sensor.init()

printf("\033[2J")     # clear screen.
while true
  data = sensor.measure()
  display( data[:x], data[:y], data[:z] )
  sleep 0.1
end
