import serial


class SerialTransport:
    def __init__(self, port: str, baudrate: int) -> None:
        self.port = port
        self.baudrate = baudrate
        self.ser: serial.Serial | None = None

    def connect(self) -> None:
        try:
            self.ser = serial.Serial(self.port, self.baudrate)
            print("UART 통신이 성공적으로 초기화되었습니다.")
        except Exception as exc:
            print(f"UART 초기화 중 오류 발생: {exc}")
            self.ser = None

    def send_byte(self, value: int) -> None:
        if not self.ser or not self.ser.is_open:
            return
        try:
            self.ser.write(bytes([value]))
            print("송신 데이터:", value)
        except serial.SerialException as exc:
            print(f"UART 전송 중 오류 발생: {exc}")
            self.ser.close()
            try:
                self.ser.open()
            except Exception as open_exc:
                print(f"포트를 다시 여는 중 오류 발생: {open_exc}")

    def close(self) -> None:
        if self.ser and self.ser.is_open:
            self.ser.close()
