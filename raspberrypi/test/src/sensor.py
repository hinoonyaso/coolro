import time
from collections import deque

import RPi.GPIO as GPIO


class DistanceSensor:
    def __init__(self, trig_pin: int, echo_pin: int, echo_timeout_s: float, filter_size: int = 5) -> None:
        self.trig_pin = trig_pin
        self.echo_pin = echo_pin
        self.echo_timeout_s = echo_timeout_s
        self._buffer: deque[float | None] = deque(maxlen=filter_size)

    def setup(self) -> None:
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.trig_pin, GPIO.OUT)
        GPIO.setup(self.echo_pin, GPIO.IN)

    def _measure_raw(self) -> float | None:
        """단일 초음파 측정 (원시 값)."""
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

    def measure_distance(self) -> float | None:
        """중앙값 필터가 적용된 거리 측정.

        최근 N회 측정값 중 유효 값의 중앙값을 반환하여
        야외 환경의 초음파 반사 노이즈를 제거합니다.
        """
        raw = self._measure_raw()
        self._buffer.append(raw)
        valid = [d for d in self._buffer if d is not None]
        if not valid:
            return None
        valid.sort()
        return valid[len(valid) // 2]
