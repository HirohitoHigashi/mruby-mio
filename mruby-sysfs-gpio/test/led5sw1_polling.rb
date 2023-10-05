#
# Poll the tact switch and animate LEDs.
#

require "mruby/gpio"

SW_PIN = 4
LED_PINS = [26,19,13,6,5]

$sw1 = GPIO.new( SW_PIN, GPIO::IN )
$leds = LED_PINS.map {|pin| GPIO.new( pin, GPIO::OUT ) }

$leds.each {|led| led.write( 0 ) }

n = 0
while true
  # waiting for sw1 press
  while $sw1.read == 1
    sleep 0.1
  end

  n1 = $leds.size
  if n != n1
    while true
      n1 -= 1
      $leds[n1].write( 1 )
      break if n1 == n

      sleep 0.1
      $leds[n1].write( 0 )
    end
    n += 1
  else
    n = 0
    $leds.each {|led| led.write( 0 ) }
  end

  sleep 0.2
end
