#
#
#

class GPIO
  IN         = 0b0000_0001
  OUT        = 0b0000_0010
  HIGH_Z     = 0b0000_0100
  PULL_UP    = 0b0000_1000
  PULL_DOWN  = 0b0001_0000
  OPEN_DRAIN = 0b0010_0000

  # extend
  RISING     = 0b0100_0000
  FALLING    = 0b1000_0000
  BOTH       = 0b1100_0000
  UNUSED     = 0b0000_0000

  PATH_SYSFS = "/sys/class/gpio"


  ##
  # set pin to use
  #
  #@param  [Integer] pin        pin number
  #
  def self._set_use( pin )
    File.binwrite("#{PATH_SYSFS}/export", pin.to_s) rescue nil
    10.times {
      return if File.writable?("#{PATH_SYSFS}/gpio#{pin}/direction")
      sleep 0.1
    }
    raise "Can't write SYSFS node"
  end


  ##
  # set pin to unused.
  #
  #@param  [Integer] pin        pin number
  #
  def self._set_unused( pin )
    File.binwrite("#{PATH_SYSFS}/unexport", pin.to_s) rescue nil
  end


  ##
  # set in or out setting.
  #
  #@param  [Integer] pin        pin number
  #@param  [Constant] params    modes
  #
  def self._set_dir( pin, params )
    flag_retry = false

    begin
      case (params & (IN|OUT|HIGH_Z|OPEN_DRAIN))
      when IN
        File.binwrite("#{PATH_SYSFS}/gpio#{pin}/direction", "in")
        return IN
      when OUT
        File.binwrite("#{PATH_SYSFS}/gpio#{pin}/direction", "out")
        return OUT
      when HIGH_Z, OPEN_DRAIN
        raise ArgumentError, "Unsupported."
      end

    rescue Errno::ENOENT =>ex
      raise ex  if flag_retry
      _set_use( pin )
      flag_retry = true
      retry
    end

    return nil
  end


  ##
  # set pull-up or pull-down
  #
  def self._set_pull( pin, params )
    case (params & (PULL_UP|PULL_DOWN))
    when PULL_UP, PULL_DOWN
      raise "Unsupported."
    end
  end


  ##
  # Specify the physical pin indicated by "pin" and change the mode of the GPIO.
  #
  #@param  [Integer] pin        pin number
  #@param  [Constant] params    modes
  #
  def self.setmode( pin, params )
    if params == UNUSED
      _set_unused( pin )
      return nil
    end

    if ! _set_dir( pin, params )
      raise ArgumentError, "You must specify one of IN, OUT and HIGH_Z"
    end

    _set_pull( pin, params )

    return nil
  end


  ##
  # Returns the value read from the specified pin as either 0 or 1.
  #
  #@param  [Integer] pin        pin number
  #@return [Integer]
  #
  def self.read_at( pin )
    return File.binread("#{PATH_SYSFS}/gpio#{pin}/value", 10).to_i
  end


  ##
  # Return true If the value read from the specified pin is high (==1)
  #
  #@param  [Integer] pin        pin number
  #@return [Bool]
  #
  def self.high_at?( pin )
    return read_at(pin) == 1
  end


  ##
  # Return true If the value read from the specified pin is low (==0)
  #
  #@param  [Integer] pin        pin number
  #@return [Bool]
  #
  def self.low_at?( pin )
    return read_at(pin) == 0
  end


  ##
  # Output a value to the specified pin.
  #
  #@param  [Integer] pin        pin number
  #@param  [Integer] value      data
  #
  def self.write_at( pin, value )
    case value
    when 0,1
      File.binwrite("#{PATH_SYSFS}/gpio#{pin}/value", value.to_s)
    else
      raise RangeError
    end
  end


  ##
  # constructor
  #
  #@param  [Integer] pin        pin number
  #@param  [Constant] params    modes
  #
  def initialize( pin, params )
    @pin = pin
    GPIO.setmode( pin, params )
    @value = File.open("#{PATH_SYSFS}/gpio#{pin}/value", "r+:ASCII-8BIT")
  end


  ##
  # Return the loaded value as 0 or 1.
  #
  #@return [Integer]
  #
  def read()
    @value.sysseek( 0 )
    return @value.sysread( 10 ).to_i
  end


  ##
  # If the loaded value is high level (==1), it returns true.
  #
  #@return [Bool]
  #
  def high?()
    return read() == 1
  end


  ##
  # If the loaded value is low-level (==0), return true.
  #
  #@return [Bool]
  #
  def low?()
    return read() == 0
  end


  ##
  # Specify the value to output to the pin as either 0 or 1.
  #
  #@param [Integer] value
  #
  def write( value )
    @value.syswrite( value == 0 ? "0" : "1" )
  end


  ##
  # Change the GPIO mode at any timing.
  #
  #@param  [Constant] params    modes
  #
  def setmode( params )
    if params == UNUSED
      GPIO._set_unused( @pin )
      return nil
    end

    GPIO._set_dir( @pin, params )
    GPIO._set_pull( @pin, params )

    return nil
  end


  ##
  # rising/falling edge event
  # (extend)
  #
  #@param  [Constant]   edge    GPIO::RISING, GPIO::FALLING or GPIO::BOTH
  #@param  [Integer]    bounce_ms       bounce time (milliseconds)
  #
  #@example
  # gpio.event( GPIO::RISING ) { puts "Rising UP." }
  #
  def event( edge, bounce_ms:50, &block )
    if !@event_init
      File.binwrite("#{PATH_SYSFS}/gpio#{@pin}/edge", "both")
      @bounce_time = bounce_ms / 1000.0
      @events_rising = []
      @events_falling = []
      @event_init = true

      @value.sysseek( 0 )
      v1 = @value.sysread( 10 ).to_i

      th = Thread.new {
        while true
          @value.sysseek(0)
          rs,ws,es = IO.select(nil, nil, [@value], 1)

          sleep @bounce_time
          v2 = @value.sysread(10).to_i

          if v1 == 0 && v2 == 1
            @events_rising.each {|event| event.call( v2 ) }
          elsif v1 == 1 && v2 == 0
            @events_falling.each {|event| event.call( v2 ) }
          end

          v1 = v2
        end
      }
    end

    case edge
    when RISING
      @events_rising << block
    when FALLING
      @events_falling << block
    when BOTH
      @events_rising << block
      @events_falling << block
    end
  end

end
