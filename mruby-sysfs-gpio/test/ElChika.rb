# Flash LED a.k.a. ElChika (in japanese)
# Connect Pin #37 (GPIO26) to LED.

require "mruby/gpio"   # or "mruby/gpio/sysfs"

led = GPIO.new(26, GPIO::OUT)
while true
  led.write( 1 )
  sleep 1
  led.write( 0 )
  sleep 1
end
