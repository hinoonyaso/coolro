import os
from threading import Thread

from local_app.api_server import run_flask_server
from local_app.camera_hub import CameraHub
from local_app.ui import run_app


def main() -> None:
    os.environ["QT_AUTO_SCREEN_SCALE_FACTOR"] = "1"
    os.environ["QT_SCALE_FACTOR"] = "1"

    flask_thread = Thread(target=run_flask_server, daemon=True)
    flask_thread.start()

    camera = CameraHub()
    run_app(camera_hub=camera)


if __name__ == "__main__":
    main()
