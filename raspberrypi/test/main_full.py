import os
from threading import Thread

from local_app.api_server import run_flask_server
from local_app.camera_hub import CameraHub
from local_app.robot_control import RobotController
from local_app.ui import run_app
from src.config import load_config


def main() -> None:
    os.environ["QT_AUTO_SCREEN_SCALE_FACTOR"] = "1"
    os.environ["QT_SCALE_FACTOR"] = "1"

    flask_thread = Thread(target=run_flask_server, daemon=True)
    flask_thread.start()

    config = load_config()
    robot = RobotController(config)
    robot.start()

    camera = CameraHub(tracking_callback=robot.handle_tracking)
    run_app(camera_hub=camera, auto_start=True)

    robot.stop()


if __name__ == "__main__":
    main()
