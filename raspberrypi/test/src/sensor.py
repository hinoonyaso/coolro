import time

import RPi.GPIO as GPIO


class DistanceSensor:
    def __init__(self, trig_pin: int, echo_pin: int, echo_timeout_s: float) -> None:
        self.trig_pin = trig_pin
        self.echo_pin = echo_pin
        self.echo_timeout_s = echo_timeout_s

    def setup(self) -> None:
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.trig_pin, GPIO.OUT)
        GPIO.setup(self.echo_pin, GPIO.IN)

    def measure_distance(self) -> float | None:
        GPIO.output(self.trig_pin, True)
        time.sleep(0.00001)
        GPIO.output(self.trig_pin, False)

        start = time.time()
        while GPIO.input(self.echo_pin) == 0:
            if time.time() - start > self.echo_timeout_s:
                return None

        pulse_start = time.time()
        while GPIO.input(self.echo_pin) == 1:
            if time.time() - pulse_start > self.echo_timeout_s:
                return None

        pulse_duration = time.time() - pulse_start
        distance = pulse_duration * 17150
        return round(distance, 2)
