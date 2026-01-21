import time
import threading

from src.sensor import DistanceSensor
from src.state import SharedState
from src.tracker import PersonTracker
from src.transport import SerialTransport


class RobotController:
    def __init__(self, config) -> None:
        self.config = config
        self.sensor = DistanceSensor(config.trig_pin, config.echo_pin, config.echo_timeout_s)
        self.transport = SerialTransport(config.serial_port, config.baudrate)
        self.tracker = PersonTracker(config)
        self.state = SharedState()
        self.stop_event = threading.Event()
        self.last_send_time = 0.0
        self.sensor_thread: threading.Thread | None = None

    def start(self) -> None:
        self.sensor.setup()
        self.transport.connect()
        self.sensor_thread = threading.Thread(
            target=self._sensor_loop,
            args=(),
            daemon=True,
        )
        self.sensor_thread.start()

    def stop(self) -> None:
        self.stop_event.set()
        if self.sensor_thread:
            self.sensor_thread.join(timeout=1.0)
        self.transport.close()

    def _sensor_loop(self) -> None:
        while not self.stop_event.is_set():
            self.state.set_distance(self.sensor.measure_distance())
            time.sleep(self.config.sensor_interval_s)

    def handle_tracking(self, person_x: int | None, frame_width: int) -> None:
        if time.time() - self.last_send_time < self.config.message_interval_s:
            return
        if person_x is None:
            command = 4
        else:
            frame_center = frame_width // 2
            distance = self.state.get_distance()
            command = self.tracker.decide_command(person_x, frame_center, distance)
        self.transport.send_byte(command)
        self.last_send_time = time.time()
