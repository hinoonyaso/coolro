from typing import Any

import cv2
import mediapipe as mp

from .config import Config


class PersonTracker:
    def __init__(self, config: Config) -> None:
        self.config = config
        self.mp_pose = mp.solutions.pose
        self.pose = self.mp_pose.Pose()
        self.drawer = mp.solutions.drawing_utils

    def detect(self, frame) -> tuple[int | None, Any]:
        rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = self.pose.process(rgb_frame)
        if not results.pose_landmarks:
            return None, results
        x_coords = [lm.x for lm in results.pose_landmarks.landmark]
        person_x = int(sum(x_coords) / len(x_coords) * frame.shape[1])
        return person_x, results

    def decide_command(self, person_x: int, frame_center: int, distance: float | None) -> int:
        if person_x < frame_center - self.config.center_tolerance_px:
            return 1  # left
        if person_x > frame_center + self.config.center_tolerance_px:
            return 2  # right
        if distance is not None and distance > self.config.distance_threshold_cm:
            return 3  # forward
        return 4  # stop
