import time

import cv2

from .sensor import DistanceSensor
from .state import SharedState
from .tracker import PersonTracker
from .transport import SerialTransport


def run_sensor_loop(
    sensor: DistanceSensor,
    state: SharedState,
    stop_event,
    interval_s: float,
) -> None:
    while not stop_event.is_set():
        state.set_distance(sensor.measure_distance())
        time.sleep(interval_s)


def run_camera_loop(
    cap: cv2.VideoCapture,
    tracker: PersonTracker,
    transport: SerialTransport,
    state: SharedState,
    stop_event,
    message_interval_s: float,
) -> None:
    frame_center = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH) // 2)
    last_send_time = 0.0

    while not stop_event.is_set():
        ret, frame = cap.read()
        if not ret:
            break

        person_x, results = tracker.detect(frame)
        should_send = time.time() - last_send_time >= message_interval_s
        if person_x is not None:
            distance = state.get_distance()
            error, mode = tracker.compute_error_and_mode(person_x, frame_center, distance)
            if should_send:
                transport.send_error_packet(error, mode)
                last_send_time = time.time()

            distance_text = f"{distance} cm" if distance is not None else "N/A"
            mode_text = "FOLLOW" if mode else "STOP"
            cv2.putText(
                frame,
                f"Dist:{distance_text} Err:{error:+d}px Mode:{mode_text}",
                (10, 50),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.7,
                (0, 255, 0),
                2,
            )
            tracker.drawer.draw_landmarks(frame, results.pose_landmarks, tracker.mp_pose.POSE_CONNECTIONS)
        elif should_send:
            transport.send_stop()
            last_send_time = time.time()

        cv2.imshow("Person Tracking", frame)
        if cv2.waitKey(1) & 0xFF == ord("q"):
            stop_event.set()
            break
