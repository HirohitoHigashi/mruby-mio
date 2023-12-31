#
# SPI class using Linux spidev.
#
# Copyright (c) 2023 Shimane IT Open-Innovation Center.
#
# see: LICENSE file.
# see: https://github.com/mruby/microcontroller-peripheral-interface-guide/blob/main/mruby_io_SPI_en.md
#
# frozen_string_literal: true
#

require_relative "spi/version"

##
# SPI namespace
#
module SPI

  MSB_FIRST = 0
  LSB_FIRST = 1


  ##
  # constructor
  #
  #@see SPI::LinuxSPIdev.initialize
  #
  def self.new(node = "/dev/spidev0.0", frequency:1_000_000, mode:0, first_bit:SPI::MSB_FIRST )
    SPI::LinuxSPIdev.new(node, frequency, mode, first_bit)
  end
end


##
# Linux SPI Device driver
#
class SPI::LinuxSPIdev

  # Constants
  # see: /usr/include/linux/spi/spidev.h, /usr/include/asm-generic/ioctl.h
  IOC_NONE = 0
  IOC_WRITE = 1
  IOC_READ = 2
  SPI_IOC_MAGIC = 'k'.ord

  # Read / Write of SPI mode (SPI_MODE_0..SPI_MODE_3) (limited to 8 bits)
  # define SPI_IOC_RD_MODE                 _IOR(SPI_IOC_MAGIC, 1, __u8)
  # define SPI_IOC_WR_MODE                 _IOW(SPI_IOC_MAGIC, 1, __u8)
  #  _IOx( type, nr, size ) is bit mapped [RW][size:14][type:8][nr:8]
  #                          dir             | size    | type               | nr
  SPI_IOC_RD_MODE          = IOC_READ  << 30 | 1 << 16 | SPI_IOC_MAGIC << 8 | 1
  SPI_IOC_WR_MODE          = IOC_WRITE << 30 | 1 << 16 | SPI_IOC_MAGIC << 8 | 1

  # Read / Write SPI bit justification
  # define SPI_IOC_RD_LSB_FIRST            _IOR(SPI_IOC_MAGIC, 2, __u8)
  # define SPI_IOC_WR_LSB_FIRST            _IOW(SPI_IOC_MAGIC, 2, __u8)
  #                          dir             | size    | type               | nr
  SPI_IOC_RD_LSB_FIRST     = IOC_READ  << 30 | 1 << 16 | SPI_IOC_MAGIC << 8 | 2
  SPI_IOC_WR_LSB_FIRST     = IOC_WRITE << 30 | 1 << 16 | SPI_IOC_MAGIC << 8 | 2

  # Read / Write SPI device word length (1..N)
  # define SPI_IOC_RD_BITS_PER_WORD        _IOR(SPI_IOC_MAGIC, 3, __u8)
  # define SPI_IOC_WR_BITS_PER_WORD        _IOW(SPI_IOC_MAGIC, 3, __u8)
  #                          dir             | size    | type               | nr
  SPI_IOC_RD_BITS_PER_WORD = IOC_READ  << 30 | 1 << 16 | SPI_IOC_MAGIC << 8 | 3
  SPI_IOC_WR_BITS_PER_WORD = IOC_WRITE << 30 | 1 << 16 | SPI_IOC_MAGIC << 8 | 3

  # Read / Write SPI device default max speed hz
  # define SPI_IOC_RD_MAX_SPEED_HZ         _IOR(SPI_IOC_MAGIC, 4, __u32)
  # define SPI_IOC_WR_MAX_SPEED_HZ         _IOW(SPI_IOC_MAGIC, 4, __u32)
  #                          dir             | size    | type               | nr
  SPI_IOC_RD_MAX_SPEED_HZ  = IOC_READ  << 30 | 4 << 16 | SPI_IOC_MAGIC << 8 | 4
  SPI_IOC_WR_MAX_SPEED_HZ  = IOC_WRITE << 30 | 4 << 16 | SPI_IOC_MAGIC << 8 | 4

  # define SPI_IOC_MESSAGE(N) _IOW(SPI_IOC_MAGIC, 0, char[SPI_MSGSIZE(N)])
  #  char[SPI_MSGSIZE(1) is 32 bytes.
  #  NOTE: struct layout is the same in 64bit and 32bit userspace.
  #                          dir             | size    | type               | nr
  SPI_IOC_MESSAGE          = IOC_WRITE << 30 |32 << 16 | SPI_IOC_MAGIC << 8 | 0


  ##
  # constructor
  #
  #@param  [String]  node       device node of SPI
  #@param  [Integer] frequency  SCLK frequency.
  #@param  [Integer] mode       SPI mode (0..3)
  #@param  [Constant] first_bit MSB_FIRST or LSB_FIRST
  #@see SPI.new
  #
  def initialize(node, frequency, mode, first_bit)
    @device = File.open(node, "r+:ASCII-8BIT")

    _set_max_speed_hz( frequency )
    _set_mode( mode )
    _set_lsb_first( first_bit )
  end


  ##
  # Changes the operating mode (parameters) of the SPI.
  #
  #@param  [Integer] frequency  SCLK frequency.
  #@param  [Integer] mode       SPI mode (0..3)
  #@return [void]
  #
  def setmode( frequency:nil, mode:nil )
    _set_max_speed_hz( frequency )  if frequency
    _set_mode( mode )  if mode
  end


  ##
  # Reads data of read_bytes bytes from the SPI bus.
  #
  #@param [Integer] read_bytes  read bytes.
  #@return [String]             reading datas.
  #
  def read( read_bytes )
    @device.sysread( read_bytes )
  end


  ##
  # Outputs data specified in outputs to the SPI bus.
  #
  #@param [Integer,String,Array<Integer>] outputs  output data.
  #@return [nil]
  #
  def write( *outputs )
    send_data = _rebuild_output_data( outputs )
    @device.syswrite( send_data )
    return nil
  end


  ##
  # Outputs data specified in outputs to the SPI bus while
  # simultaneously reading data (General-purpose transfer).
  #
  #@param [Integer,String,Array<Integer>] outputs  output data.
  #@param [Integer]  additional_read_bytes      additional read bytes
  #@return [String]             reading datas.
  #
  def transfer( outputs, additional_read_bytes = 0 )

    # prepare the send buffer and receive buffer.
    send_data = _rebuild_output_data( [outputs] )
    len = send_data.size
    if additional_read_bytes > 0
      send_data << ("\x00".b * additional_read_bytes)
      len += additional_read_bytes
    end
    recv_data = "\x00".b * len

    # prepare the struct spi_ioc_transfer. (spidev.h)
    arg = [ [send_data].pack("P").unpack1("J"), # __u64           tx_buf;
            [recv_data].pack("P").unpack1("J"), # __u64           rx_buf;

            len,        # __u32           len;
            0,          # __u32           speed_hz;

            0,          # __u16           delay_usecs;
            0,          # __u8            bits_per_word;
            0,          # __u8            cs_change;
            0,          # __u8            tx_nbits;
            0,          # __u8            rx_nbits;
            0,          # __u8            word_delay_usecs;
            0,          # __u8            pad;
          ].pack("QQLLSCCCCCC")

    # trigger IOCTL.
    @device.ioctl( SPI_IOC_MESSAGE, arg )
    return recv_data
  end


  private
  def _get_mode()
    arg = "\x00".b
    @device.ioctl( SPI_IOC_RD_MODE, arg )
    return arg.unpack("C")[0]
  end

  def _set_mode( mode )
    arg = [mode].pack("C")
    @device.ioctl( SPI_IOC_WR_MODE, arg )
  end

  def _get_lsb_first()
    arg = "\x00".b
    @device.ioctl( SPI_IOC_RD_LSB_FIRST, arg )
    return arg.unpack("C")[0]
  end

  def _set_lsb_first( flag )
    #(note) Legal operation could not be confirmed with RasPi OS ioctl.
    arg = [flag].pack("C")
    @device.ioctl( SPI_IOC_WR_LSB_FIRST, arg )
  end

  def _get_bits_per_word()
    arg = "\x00".b
    @device.ioctl( SPI_IOC_RD_BITS_PER_WORD, arg )
    return arg.unpack("C")[0]
  end

  def _set_bits_per_word( bits_per_word )
    arg = [bits_per_word].pack("C")
    @device.ioctl( SPI_IOC_WR_BITS_PER_WORD, arg )
  end

  def _get_max_speed_hz()
    arg = "\x00\x00\x00\x00".b
    @device.ioctl( SPI_IOC_RD_MAX_SPEED_HZ, arg )
    return arg.unpack("L")[0]
  end

  def _set_max_speed_hz( freq )
    arg = [freq].pack("L")
    @device.ioctl( SPI_IOC_WR_MAX_SPEED_HZ, arg )
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
