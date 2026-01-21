import datetime
import glob
import os
import subprocess
from pathlib import Path


def ensure_dirs(*paths: Path) -> None:
    for path in paths:
        path.mkdir(parents=True, exist_ok=True)


def unique_video_name(base_dir: Path, prefix: str, extension: str) -> str:
    current_time = datetime.datetime.now().strftime("%y%m%d_%H%M%S")
    return str(base_dir / f"{prefix}_{current_time}.{extension}")


def get_latest_video_file(directory: Path, extension: str = "avi") -> str | None:
    list_of_files = glob.glob(str(directory / f"*.{extension}"))
    if not list_of_files:
        return None
    return max(list_of_files, key=os.path.getctime)


def convert_avi_to_mp4(input_path: str, output_path: str) -> None:
    command = [
        "ffmpeg",
        "-i",
        input_path,
        "-c:v",
        "libx264",
        "-crf",
        "23",
        "-preset",
        "medium",
        output_path,
    ]
    subprocess.run(command, check=True)
