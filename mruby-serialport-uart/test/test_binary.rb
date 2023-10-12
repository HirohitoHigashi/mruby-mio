#
# バイナリAPIテスト
# ブロックせずに、5バイト固定長読み込み
#

require "mruby/uart"

READ_LEN = 5

uart = UART.new("/dev/serial0")
while true
  if uart.bytes_available() >= READ_LEN
    s = uart.read( READ_LEN )
    puts "READ: #{s.inspect}"
    uart.write("READ: #{s.inspect}\r\n")
  else
    puts "Buffering #{uart.bytes_available} byte"
    sleep 1
  end
end
