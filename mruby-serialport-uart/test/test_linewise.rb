#
# 行志向APIテスト
# ブロックせずに１行読み込み
#

require "mruby/uart"

uart = UART.new("/dev/serial0")
while true
  if uart.can_read_line()
    s = uart.gets
    puts "\nREAD: #{s.inspect}"
    uart.puts "\nREAD: #{s.inspect}"
  else
    print "."
    sleep 1
  end
end
