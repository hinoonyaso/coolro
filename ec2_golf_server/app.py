import json
import math
import os
import tempfile
from pathlib import Path

import cv2
import mediapipe as mp
import numpy as np
from flask import Flask, after_this_request, jsonify, request, send_file

app = Flask(__name__)

BASE_DIR = Path(__file__).resolve().parent
VIDEO_DIR = BASE_DIR / "videos"
SCORES_PATH = BASE_DIR / "scores.json"
VIDEO_DIR.mkdir(parents=True, exist_ok=True)

mp_pose = mp.solutions.pose
mp_drawing = mp.solutions.drawing_utils


def _angle(a: np.ndarray, b: np.ndarray, c: np.ndarray) -> float:
    ba = a - b
    bc = c - b
    denom = (np.linalg.norm(ba) * np.linalg.norm(bc)) or 1.0
    cosine = float(np.dot(ba, bc) / denom)
    cosine = max(-1.0, min(1.0, cosine))
    return math.degrees(math.acos(cosine))


def _point(landmarks, idx: int, width: int, height: int) -> np.ndarray:
    lm = landmarks.landmark[idx]
    return np.array([lm.x * width, lm.y * height], dtype=np.float32)


def _feedback_from_landmarks(landmarks, width: int, height: int) -> list[str]:
    left = mp_pose.PoseLandmark
    right = mp_pose.PoseLandmark

    left_elbow = _angle(
        _point(landmarks, left.LEFT_SHOULDER, width, height),
        _point(landmarks, left.LEFT_ELBOW, width, height),
        _point(landmarks, left.LEFT_WRIST, width, height),
    )
    right_elbow = _angle(
        _point(landmarks, right.RIGHT_SHOULDER, width, height),
        _point(landmarks, right.RIGHT_ELBOW, width, height),
        _point(landmarks, right.RIGHT_WRIST, width, height),
    )
    left_knee = _angle(
        _point(landmarks, left.LEFT_HIP, width, height),
        _point(landmarks, left.LEFT_KNEE, width, height),
        _point(landmarks, left.LEFT_ANKLE, width, height),
    )
    right_knee = _angle(
        _point(landmarks, right.RIGHT_HIP, width, height),
        _point(landmarks, right.RIGHT_KNEE, width, height),
        _point(landmarks, right.RIGHT_ANKLE, width, height),
    )
    left_spine = _angle(
        _point(landmarks, left.LEFT_SHOULDER, width, height),
        _point(landmarks, left.LEFT_HIP, width, height),
        _point(landmarks, left.LEFT_KNEE, width, height),
    )
    right_spine = _angle(
        _point(landmarks, right.RIGHT_SHOULDER, width, height),
        _point(landmarks, right.RIGHT_HIP, width, height),
        _point(landmarks, right.RIGHT_KNEE, width, height),
    )

    feedback = []
    if min(left_elbow, right_elbow) < 155:
        feedback.append("Keep your arms straighter.")
    if min(left_knee, right_knee) < 155:
        feedback.append("Maintain stable knees.")
    if min(left_spine, right_spine) < 160:
        feedback.append("Keep your torso more upright.")
    if not feedback:
        feedback.append("Nice posture. Keep it up.")
    return feedback


def analyze_video(input_path: str, output_path: str) -> None:
    cap = cv2.VideoCapture(input_path)
    if not cap.isOpened():
        raise RuntimeError("Unable to open input video.")
    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)) or 1280
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)) or 720

    fourcc = cv2.VideoWriter_fourcc(*"mp4v")
    if width <= 0 or height <= 0:
        cap.release()
        raise RuntimeError("Invalid video dimensions.")
    writer = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

    with mp_pose.Pose(
        static_image_mode=False,
        model_complexity=1,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
    ) as pose:
        while True:
            ret, frame = cap.read()
            if not ret:
                break

            rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = pose.process(rgb_frame)

            if results.pose_landmarks:
                mp_drawing.draw_landmarks(frame, results.pose_landmarks, mp_pose.POSE_CONNECTIONS)
                feedback = _feedback_from_landmarks(results.pose_landmarks, width, height)
                for idx, line in enumerate(feedback):
                    y = 30 + idx * 30
                    cv2.putText(
                        frame,
                        line,
                        (10, y),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.8,
                        (0, 255, 0),
                        2,
                    )

            writer.write(frame)

    cap.release()
    writer.release()


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.get("/api/upload-video")
def list_videos():
    videos = sorted([p.name for p in VIDEO_DIR.glob("*") if p.is_file()])
    return jsonify({"videos": videos})


@app.post("/api/upload-video")
def upload_video():
    if "video" not in request.files:
        return jsonify({"error": "Missing video file"}), 400
    file = request.files["video"]
    if not file.filename:
        return jsonify({"error": "Empty filename"}), 400
    filename = os.path.basename(file.filename)
    target = VIDEO_DIR / filename
    file.save(target)
    return jsonify({"status": "ok", "filename": filename})


@app.get("/video/<path:filename>")
def serve_video(filename: str):
    safe_name = os.path.basename(filename)
    target = VIDEO_DIR / safe_name
    if not target.exists():
        return jsonify({"error": "Not found"}), 404
    return send_file(target, mimetype="video/mp4")


@app.route("/api/submit-score", methods=["GET", "POST"])
def submit_score():
    if request.method == "GET":
        if not SCORES_PATH.exists():
            return jsonify({"stored_data": []})
        with SCORES_PATH.open("r", encoding="utf-8") as handle:
            stored = json.load(handle)
        return jsonify({"stored_data": stored})

    payload = request.get_json(silent=True) or {}
    if not payload:
        return jsonify({"error": "Missing score payload"}), 400
    stored = []
    if SCORES_PATH.exists():
        with SCORES_PATH.open("r", encoding="utf-8") as handle:
            stored = json.load(handle) or []
    stored.append(payload)
    with SCORES_PATH.open("w", encoding="utf-8") as handle:
        json.dump(stored, handle, ensure_ascii=False, indent=2)
    return jsonify({"status": "ok"})


@app.post("/analyze")
def analyze():
    if "video" not in request.files:
        return jsonify({"error": "Missing video file"}), 400

    file = request.files["video"]
    if not file.filename:
        return jsonify({"error": "Empty filename"}), 400

    input_fd, input_path = tempfile.mkstemp(suffix=".mp4")
    output_fd, output_path = tempfile.mkstemp(suffix=".mp4")
    os.close(input_fd)
    os.close(output_fd)
    file.save(input_path)

    try:
        analyze_video(input_path, output_path)
    except Exception as exc:
        for path in (input_path, output_path):
            try:
                os.remove(path)
            except OSError:
                pass
        return jsonify({"error": f"Processing failed: {exc}"}), 500

    @after_this_request
    def cleanup(response):
        for path in (input_path, output_path):
            try:
                os.remove(path)
            except OSError:
                pass
        return response

    return send_file(output_path, mimetype="video/mp4")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
