import threading

import cv2
import RPi.GPIO as GPIO

from src.config import load_config
from src.loops import run_camera_loop, run_sensor_loop
from src.sensor import DistanceSensor
from src.state import SharedState
from src.tracker import PersonTracker
from src.transport import SerialTransport


def main() -> None:
    config = load_config()

    sensor = DistanceSensor(config.trig_pin, config.echo_pin, config.echo_timeout_s)
    sensor.setup()

    transport = SerialTransport(config.serial_port, config.baudrate)
    transport.connect()

    cap = cv2.VideoCapture(0)
    tracker = PersonTracker(config)

    state = SharedState()
    stop_event = threading.Event()

    sensor_thread = threading.Thread(
        target=run_sensor_loop,
        args=(sensor, state, stop_event, config.sensor_interval_s),
        daemon=True,
    )
    camera_thread = threading.Thread(
        target=run_camera_loop,
        args=(cap, tracker, transport, state, stop_event, config.message_interval_s),
        daemon=True,
    )

    sensor_thread.start()
    camera_thread.start()

    try:
        camera_thread.join()
    except KeyboardInterrupt:
        stop_event.set()
    finally:
        stop_event.set()
        sensor_thread.join(timeout=1.0)
        GPIO.cleanup()
        cap.release()
        cv2.destroyAllWindows()
        transport.close()


if __name__ == "__main__":
    main()
