from typing import Any

import cv2
import mediapipe as mp
import numpy as np

from .config import Config


class PersonTracker:
    def __init__(self, config: Config) -> None:
        self.config = config
        self.mp_pose = mp.solutions.pose
        self.pose = self.mp_pose.Pose()
        self.drawer = mp.solutions.drawing_utils

        # OpenCV 야외 환경 전처리: CLAHE
        self.clahe = cv2.createCLAHE(
            clipLimit=config.clahe_clip_limit,
            tileGridSize=(config.clahe_grid_size, config.clahe_grid_size),
        )

    def _preprocess_frame(self, frame: np.ndarray) -> np.ndarray:
        """야외 환경용 OpenCV 전처리 파이프라인.

        1. CLAHE: 역광/그림자 환경에서 Y 채널 대비를 적응적으로 보정
        2. GaussianBlur: 모션 블러·노이즈 완화
        """
        yuv = cv2.cvtColor(frame, cv2.COLOR_BGR2YUV)
        yuv[:, :, 0] = self.clahe.apply(yuv[:, :, 0])
        enhanced = cv2.cvtColor(yuv, cv2.COLOR_YUV2BGR)
        blurred = cv2.GaussianBlur(enhanced, (5, 5), 0)
        return blurred

    def detect(self, frame) -> tuple[int | None, Any]:
        preprocessed = self._preprocess_frame(frame)
        rgb_frame = cv2.cvtColor(preprocessed, cv2.COLOR_BGR2RGB)
        results = self.pose.process(rgb_frame)
        if not results.pose_landmarks:
            return None, results
        x_coords = [lm.x for lm in results.pose_landmarks.landmark]
        person_x = int(sum(x_coords) / len(x_coords) * frame.shape[1])
        return person_x, results

    def compute_error_and_mode(
        self, person_x: int, frame_center: int, distance: float | None
    ) -> tuple[int, int]:
        """조향 오차와 모드를 계산하여 STM32로 전송할 값을 반환.

        PID 제어는 STM32 펌웨어에서 실행됩니다.
        RPi는 오차 값과 동작 모드만 전송합니다.

        Args:
            person_x: 사람 중심 x좌표 (px)
            frame_center: 프레임 중앙 x좌표 (px)
            distance: 초음파 거리 (cm) 또는 None

        Returns:
            (error, mode)
            error: person_x - frame_center (signed, 픽셀 단위)
                   양수 = 사람이 오른쪽, 음수 = 사람이 왼쪽
            mode:  0=정지, 1=추종
        """
        error = person_x - frame_center

        # 거리 기반 전진/정지 판단
        if distance is None or distance <= self.config.distance_threshold_cm:
            mode = 0  # 정지 (충분히 가까움)
        else:
            mode = 1  # 추종

        return error, mode
