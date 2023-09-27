require "serialport"

node = "/dev/cuaU0"

module UART
  # Constants
  NONE = 0
  ODD = 1
  EVEN = 2
  RTSCTS = 4

  ##
  # constructor
  #
  def self.new( node=nil, baudrate:9600, baud:nil, data_bits:8, stop_bits:1,
                parity:NONE, flow_control:NONE, unit:nil )
    UART::GemSerialPort.new( node, baudrate, baud, data_bits, stop_bits,
                             parity, flow_control, unit )
  end
end


##
# gem serialport wrapper class
# https://rubygems.org/gems/serialport
#
class UART::GemSerialPort

  ##
  # constructor
  #
  #@param [String] node         device node.
  #@param [Integer] baudrate    baudrate
  #@param [Integer] baud        baudrate
  #@param [Integer] data_bits   data bits
  #@param [Integer] stop_bits   stop bits
  #@param [Constant] parity      parity bit (UART::NONE, ODD, EVEN)
  #@param [Constant] flow_control flow control (UART::NONE, RTSCTS)
  #@param [String] unit         device node.
  #
  def initialize( node, baudrate, baud, data_bits,
                  stop_bits, parity, flow_control, unit )
    @device = SerialPort.new(node||unit)
    @readbuf = "".b

    setmode( baudrate:baudrate, baud:baud, data_bits:data_bits,
             stop_bits:stop_bits, parity:parity, flow_control:flow_control )
  end


  ##
  # Changes the mode (parameters) of UART.
  #
  #@param [Integer] baudrate    baudrate
  #@param [Integer] baud        baudrate
  #@param [Integer] data_bits   data bits
  #@param [Integer] stop_bits   stop bits
  #@param [Constant] parity      parity bit (UART::NONE, ODD, EVEN)
  #@param [Constant] flow_control flow control (UART::NONE, RTSCTS)
  #
  def setmode( baudrate:nil, baud:nil, data_bits:nil, stop_bits:nil,
               parity:nil, flow_control:nil )
    if baud || baudrate
      @device.baud = baud || baudrate
    end

    if data_bits
      @device.data_bits = data_bits
    end

    if stop_bits
      @device.stop_bits = stop_bits
    end

    case parity
    when UART::NONE
      @device.parity = SerialPort::NONE
    when UART::ODD
      @device.parity = SerialPort::ODD
    when UART::EVEN
      @device.parity = SerialPort::EVEN
    when nil
      # nothing to do
    else
      raise ArgumentError
    end

    case flow_control
    when UART::NONE
      @device.flow_control = SerialPort::NONE
    when UART::RTSCTS
      @device.flow_control = SerialPort::HARD
    when nil
      # nothing to do
    else
      raise ArgumentError
    end
  end


  ##
  # Reads data of the specified number of bytes, read_bytes.
  #
  #@param [Integer] read_bytes  read bytes.
  #@return [String]     reading datas.
  #
  def read( read_bytes )
    while bytes_available() < read_bytes
      sleep 0.1
    end

    return @readbuf.slice!(0, read_bytes)
  end


  ##
  # Sends data.
  #
  #@param [String]  string      data to send.
  #@return [Integer]  the number of bytes sent.
  #
  def write( string )
    @device.write( string )
  end


  ##
  # Reads a line of string.
  #
  #@return [String]  reading data.
  #
  def gets()
    while true
      _fill_to_readbuf()
      pos = @readbuf.index("\n")
      break if pos
      sleep 0.1
    end

    return @readbuf.slice!(0, pos+1)
  end


  ##
  # Sends one line and sends a newline code at the end of the argument string.
  # The newline code is LF only by default.
  #
  #@param [String] string       string to send.
  #
  def puts( string )
    @device.write( string )
    if string[-1] != "\n"
      @device.write( "\n" )
    end

    return nil
  end


  ##
  # Returns the number of readable bytes in the read buffer.
  #
  #@return [Integer]  num of readable bytes.
  #
  def bytes_available()
    _fill_to_readbuf()

    return @readbuf.size
  end


  ##
  # Returns the number of bytes of data in the transmission buffer that have not been actually sent.
  #
  #@return [Integer]   num of bytes.
  #
  def bytes_to_write()
    return 0
  end


  ##
  # Returns true if reading a line of data is possible.
  #
  #@return [Bool]  true if a line of data can be read
  #
  def can_read_line()
    _fill_to_readbuf()

    return @readbuf.include?("\n")
  end


  ##
  # Block until transmission of data accumulated in the transmission buffer is completed.
  #
  def flush()
    @device.flush()
  end


  ##
  # Clears the receive buffer.
  #
  def clear_rx_buffer()
    @readbuf.clear
  end

  ##
  # Clears the transmission buffer.
  #
  def clear_tx_buffer()
    # nothing to do.
  end


  ##
  # Sends a break signal.
  # The time is optional and specified in seconds.
  #
  #@param [Integer,Float] time
  #
  def send_break( time = 0 )
    t = (time * 10).to_i
    t = [t, 1].max
    p t
    @device.break( t )
  end


  private
  def _fill_to_readbuf()
    while true
      s = @device.read_nonblock( 1024 ) rescue nil
      break if !s
      @readbuf << s
    end
  end

end
