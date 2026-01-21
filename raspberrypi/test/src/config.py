from dataclasses import dataclass
from pathlib import Path

import yaml

CONFIG_PATH = Path(__file__).resolve().parents[1] / "config.yaml"


@dataclass
class Config:
    trig_pin: int = 23
    echo_pin: int = 24
    serial_port: str = "/dev/ttyS0"
    baudrate: int = 9600
    distance_threshold_cm: float = 50.0
    center_tolerance_px: int = 50
    sensor_interval_s: float = 0.1
    message_interval_s: float = 1.0
    echo_timeout_s: float = 0.03


def load_config(path: Path = CONFIG_PATH) -> Config:
    if not path.exists():
        raise FileNotFoundError(f"Missing config file: {path}")
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle) or {}
    return Config(**data)
