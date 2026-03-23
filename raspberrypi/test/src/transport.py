import struct

import serial


# UART 패킷 헤더
PACKET_HEADER = 0xAA


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

    def send_error_packet(self, error: int, mode: int) -> None:
        """조향 오차 + 동작 모드 패킷을 STM32로 전송.

        STM32 내부의 PID 제어기가 이 오차를 입력으로 사용합니다.

        패킷 구조 (4 bytes):
            [0xAA] [error_hi] [error_lo] [mode]
            - error: signed 16-bit (person_x - frame_center, 픽셀)
            - mode:  0=정지, 1=추종
        """
        if not self.ser or not self.ser.is_open:
            return

        # error를 signed 16-bit로 클램핑
        error = max(-32767, min(32767, error))
        error_bytes = struct.pack('>h', error)  # big-endian signed short

        packet = bytes([PACKET_HEADER]) + error_bytes + bytes([mode & 0xFF])
        try:
            self.ser.write(packet)
            dir_str = "→" if error > 0 else "←" if error < 0 else "·"
            mode_str = "추종" if mode else "정지"
            print(f"STM32 전송: error={error:+d}px {dir_str} mode={mode_str}")
        except serial.SerialException as exc:
            print(f"UART 전송 중 오류 발생: {exc}")
            self.ser.close()
            try:
                self.ser.open()
            except Exception as open_exc:
                print(f"포트를 다시 여는 중 오류 발생: {open_exc}")

    def send_stop(self) -> None:
        """정지 패킷 전송 (error=0, mode=0)."""
        self.send_error_packet(0, 0)

    def close(self) -> None:
        if self.ser and self.ser.is_open:
            self.ser.close()
