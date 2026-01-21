import threading


class SharedState:
    def __init__(self) -> None:
        self.distance: float | None = None
        self.lock = threading.Lock()

    def set_distance(self, value: float | None) -> None:
        with self.lock:
            self.distance = value

    def get_distance(self) -> float | None:
        with self.lock:
            return self.distance
