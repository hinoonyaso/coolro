import math
import time
from typing import Callable, Optional

import cv2
import mediapipe as mp
from PyQt5 import QtGui
from PyQt5.QtCore import QThread, pyqtSignal

from .config import VIDEO_DIR
from .utils import ensure_dirs, unique_video_name


class CameraHub(QThread):
    frame_signal = pyqtSignal(QtGui.QImage)
    pose_signal = pyqtSignal(bool, bool)

    def __init__(self, tracking_callback: Optional[Callable[[int | None, int], None]] = None) -> None:
        super().__init__()
        self.tracking_callback = tracking_callback
        self.recording = False
        self.running = False
        self.out = None
        self.pose = mp.solutions.pose.Pose()
        self.stop_record_at: float | None = None
        ensure_dirs(VIDEO_DIR)

    def start_capture(self) -> None:
        if not self.isRunning():
            self.running = True
            self.start()
        else:
            self.running = True

    def stop_capture(self) -> None:
        self.running = False

    def run(self) -> None:
        cap = cv2.VideoCapture(0)
        if not cap.isOpened():
            print("카메라를 열 수 없습니다.")
            return

        width = round(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = round(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        fourcc = cv2.VideoWriter_fourcc(*"DIVX")
        out_filename = unique_video_name(VIDEO_DIR, "SaveVideo", "avi")
        self.out = cv2.VideoWriter(out_filename, fourcc, 20.0, (width, height))

        preparation_detected = False

        while self.running:
            ret, frame = cap.read()
            if not ret:
                break

            img_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = self.pose.process(img_rgb)

            golf_preparation = False
            golf_swing = False

            person_x = None
            if results.pose_landmarks:
                person_x = self._person_center(results.pose_landmarks.landmark, width)

                if self.is_golf_preparation_pose(results.pose_landmarks.landmark):
                    golf_preparation = True
                    preparation_detected = True
                    if not self.recording:
                        print("골프 준비 동작 인식, 녹화를 시작합니다.")
                        self.start_recording()

                if preparation_detected and self.is_golf_swing(results.pose_landmarks.landmark):
                    golf_swing = True
                    if self.recording and self.stop_record_at is None:
                        print("골프 스윙 인식, 3초 뒤 녹화를 종료합니다.")
                        self.stop_record_at = time.time() + 3.0
                        preparation_detected = False

            if self.stop_record_at and time.time() >= self.stop_record_at:
                self.stop_recording()
                self.stop_record_at = None

            if self.recording:
                self.out.write(frame)

            if self.tracking_callback:
                self.tracking_callback(person_x, width)

            h, w, ch = img_rgb.shape
            bytes_per_line = ch * w
            qt_image = QtGui.QImage(img_rgb.data, w, h, bytes_per_line, QtGui.QImage.Format_RGB888)
            self.frame_signal.emit(qt_image)
            self.pose_signal.emit(golf_preparation, golf_swing)

        cap.release()
        if self.out:
            self.out.release()

    def start_recording(self) -> None:
        if not self.recording:
            self.recording = True
            print("녹화 시작")

    def stop_recording(self) -> None:
        if self.recording:
            self.recording = False
            print("녹화 중지")

    @staticmethod
    def calculate_angle(a, b, c) -> float:
        radians = math.atan2(c.y - b.y, c.x - b.x) - math.atan2(a.y - b.y, a.x - b.x)
        angle = abs(radians * 180.0 / math.pi)
        if angle > 180.0:
            angle = 360.0 - angle
        return angle

    def is_golf_preparation_pose(self, landmarks) -> bool:
        left_shoulder = landmarks[mp.solutions.pose.PoseLandmark.LEFT_SHOULDER.value]
        right_shoulder = landmarks[mp.solutions.pose.PoseLandmark.RIGHT_SHOULDER.value]
        left_hip = landmarks[mp.solutions.pose.PoseLandmark.LEFT_HIP.value]
        right_hip = landmarks[mp.solutions.pose.PoseLandmark.RIGHT_HIP.value]
        left_knee = landmarks[mp.solutions.pose.PoseLandmark.LEFT_KNEE.value]
        right_knee = landmarks[mp.solutions.pose.PoseLandmark.RIGHT_KNEE.value]
        left_ankle = landmarks[mp.solutions.pose.PoseLandmark.LEFT_ANKLE.value]
        right_ankle = landmarks[mp.solutions.pose.PoseLandmark.RIGHT_ANKLE.value]

        left_knee_angle = self.calculate_angle(left_hip, left_knee, left_ankle)
        right_knee_angle = self.calculate_angle(right_hip, right_knee, right_ankle)
        left_hip_angle = self.calculate_angle(left_shoulder, left_hip, left_knee)
        right_hip_angle = self.calculate_angle(right_shoulder, right_hip, right_knee)

        knee_angle_threshold = 150
        hip_angle_threshold = 160

        left_ready = left_knee_angle > knee_angle_threshold and left_hip_angle < hip_angle_threshold
        right_ready = right_knee_angle > knee_angle_threshold and right_hip_angle < hip_angle_threshold
        return left_ready and right_ready

    def is_golf_swing(self, landmarks) -> bool:
        left_wrist = landmarks[mp.solutions.pose.PoseLandmark.LEFT_WRIST.value]
        right_wrist = landmarks[mp.solutions.pose.PoseLandmark.RIGHT_WRIST.value]
        left_hip = landmarks[mp.solutions.pose.PoseLandmark.LEFT_HIP.value]
        right_hip = landmarks[mp.solutions.pose.PoseLandmark.RIGHT_HIP.value]

        left_wrist_swing = left_wrist.y < left_hip.y - 0.15
        right_wrist_swing = right_wrist.y < right_hip.y - 0.15
        return left_wrist_swing or right_wrist_swing

    @staticmethod
    def _person_center(landmarks, width: int) -> int:
        x_coords = [lm.x for lm in landmarks]
        return int(sum(x_coords) / len(x_coords) * width)
