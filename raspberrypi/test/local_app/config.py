from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
VIDEO_DIR = BASE_DIR / "video"
MP4_DIR = BASE_DIR / "mp4"
UI_FILE = BASE_DIR / "test5.ui"

FLASK_HOST = "0.0.0.0"
FLASK_PORT = 5000
LOCAL_API_BASE = f"http://localhost:{FLASK_PORT}"
