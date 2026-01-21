import cv2
import requests
from PyQt5 import QtGui, uic
from PyQt5.QtCore import Qt
from PyQt5.QtWidgets import QApplication, QComboBox, QLabel, QMainWindow, QStackedWidget

from .camera_hub import CameraHub
from .config import LOCAL_API_BASE, UI_FILE, VIDEO_DIR, MP4_DIR
from .utils import convert_avi_to_mp4, get_latest_video_file

data = uic.loadUiType(str(UI_FILE))[0]


class GolfApp(QMainWindow, data):
    def __init__(self, camera_hub: CameraHub | None = None, auto_start: bool = False) -> None:
        super().__init__()
        self.setupUi(self)

        self.btn1.clicked.connect(self.onClick)
        self.btn2.clicked.connect(self.onClick2)
        self.btn3.clicked.connect(self.onClick3)
        self.btn4.clicked.connect(self.onClick4)
        self.par_save.clicked.connect(self.onClick5)
        self.score_save.clicked.connect(self.onClick6)
        self.play_video.clicked.connect(self.Play)
        self.save_video.clicked.connect(self.Save)
        self.camera_on.clicked.connect(self.start)
        self.camera_off.clicked.connect(self.stop)
        self.stackedWidget: QStackedWidget

        self.stackedWidget.setCurrentIndex(0)
        self.showFullScreen()

        self.camera = camera_hub or CameraHub()
        self.camera.frame_signal.connect(self.update_image)
        self.camera.pose_signal.connect(self.handle_pose_detection)

        self.label2.setFixedSize(640, 480)
        self.initUI()
        if auto_start:
            self.start()

    def update_image(self, qt_image) -> None:
        self.label2.setPixmap(QtGui.QPixmap.fromImage(qt_image))
        self.label2.setAlignment(Qt.AlignCenter)

    def handle_pose_detection(self, golf_preparation: bool, golf_swing: bool) -> None:
        if golf_preparation:
            print("Golf preparation detected!")
        if golf_swing:
            print("Golf swing detected!")

    def initUI(self) -> None:
        self.setWindowTitle("Golf Analysis App")

        self.combo_boxes = []
        scores = ["-4", "-3", "-2", "-1", "0", "1", "2", "3", "4", "5"]
        pars = ["1", "2", "3", "4", "5"]

        for _ in range(18):
            combo_box = QComboBox(self)
            for score in scores:
                combo_box.addItem(score)
            combo_box.setCurrentText("0")
            combo_box.currentIndexChanged.connect(self.calculate_sums)
            combo_box.setEditable(True)
            combo_box.lineEdit().setAlignment(Qt.AlignCenter)
            self.combo_boxes.append(combo_box)

        for i in range(1, 5, 3):
            for j in range(9):
                if i == 1:
                    self.ta1.setCellWidget(i, j, self.combo_boxes[j])
                if i == 4:
                    self.ta1.setCellWidget(i, j, self.combo_boxes[9 + j])

        out_sum = sum(int(self.combo_boxes[i].currentText()) for i in range(9))
        in_sum = sum(int(self.combo_boxes[i].currentText()) for i in range(9, 18))

        self.result_label = QLabel(self)
        self.result_label2 = QLabel(self)
        self.result_label.setStyleSheet("QLabel { text-align: center; }")
        self.result_label2.setStyleSheet("QLabel { text-align: center; }")
        self.result_label.setText(str(out_sum))
        self.result_label2.setText(str(in_sum))
        self.ta1.setCellWidget(1, 9, self.result_label)
        self.ta1.setCellWidget(4, 9, self.result_label2)

        self.par_box = []
        for _ in range(9):
            combo_box = QComboBox(self)
            for par in pars:
                combo_box.addItem(par)
            combo_box.setCurrentText("0")
            combo_box.setEditable(True)
            combo_box.lineEdit().setAlignment(Qt.AlignCenter)
            self.par_box.append(combo_box)

        for i in range(9):
            self.ta2.setCellWidget(i, 0, self.par_box[i])

        self.show()

    def calculate_sums(self) -> None:
        in_sum = sum(int(self.combo_boxes[i].currentText()) for i in range(9, 18))
        out_sum = sum(int(self.combo_boxes[i].currentText()) for i in range(9))
        self.result_label.setText(str(out_sum))
        self.result_label2.setText(str(in_sum))

    def onClick(self) -> None:
        self.stackedWidget.setCurrentIndex(0)

    def onClick2(self) -> None:
        self.stackedWidget.setCurrentIndex(2)

    def onClick3(self) -> None:
        self.stackedWidget.setCurrentIndex(1)

    def onClick4(self) -> None:
        self.stackedWidget.setCurrentIndex(3)

    def onClick5(self) -> None:
        for i in range(0, 4, 3):
            for j in range(9):
                value = self.par_box[j].currentText()
                label = QLabel(value, self)
                label.setAlignment(Qt.AlignCenter)
                if i == 0:
                    self.ta1.setCellWidget(i, j, label)
                if i == 3:
                    self.ta1.setCellWidget(i, j, label)

    def onClick6(self) -> None:
        score_data = []
        par_data = []
        hole_data = []
        for i in range(18):
            hole_value = i + 1
            score_value = self.combo_boxes[i].currentText()
            par_value = self.par_box[i % 9].currentText()
            score_data.append(score_value)
            par_data.append(par_value)
            hole_data.append(hole_value)

        url = f"{LOCAL_API_BASE}/api/submit-score"
        data = {"hole": hole_data, "par": par_data, "score": score_data}

        try:
            response = requests.post(url, json=data)
            if response.status_code == 200:
                print("Score data successfully sent.")
            else:
                print(f"Failed to send data. Status code: {response.status_code}")
        except Exception as exc:
            print(f"An error occurred: {exc}")

    def Play(self) -> None:
        latest_video_file = get_latest_video_file(VIDEO_DIR)
        if latest_video_file is None:
            print("No video file found or file does not exist.")
            return

        cap = cv2.VideoCapture(latest_video_file)
        if not cap.isOpened():
            print("Failed to open video file.")
            return

        while cap.isOpened():
            ret, frame = cap.read()
            if ret:
                rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                h, w, ch = rgb_frame.shape
                bytes_per_line = ch * w
                q_img = QtGui.QImage(rgb_frame.data, w, h, bytes_per_line, QtGui.QImage.Format_RGB888)
                pixmap = QtGui.QPixmap.fromImage(q_img)
                self.label2.setPixmap(pixmap)
                self.label2.setAlignment(Qt.AlignCenter)
                cv2.waitKey(30)
            else:
                break
        cap.release()

    def Save(self) -> None:
        latest_video_file = get_latest_video_file(VIDEO_DIR)
        if not latest_video_file:
            print("No video file found.")
            return
        mp4_file = latest_video_file.replace(str(VIDEO_DIR), str(MP4_DIR)).replace(".avi", ".mp4")
        try:
            convert_avi_to_mp4(latest_video_file, mp4_file)
            print("AVI 파일이 MP4로 변환되었습니다.")

            url = f"{LOCAL_API_BASE}/api/upload-video"
            with open(mp4_file, "rb") as video_file:
                files = {"file": video_file}
                response = requests.post(url, files=files)
            if response.status_code == 200:
                print("MP4 비디오가 성공적으로 업로드되었습니다.")
            else:
                print(f"Failed to upload video. Status code: {response.status_code}")
        except Exception as exc:
            print(f"An error occurred: {exc}")

    def start(self) -> None:
        self.label2.setHidden(False)
        self.camera.start_capture()

    def stop(self) -> None:
        self.camera.stop_capture()
        self.label2.setHidden(True)

    def onExit(self) -> None:
        self.stop()


def run_app(camera_hub: CameraHub | None = None, auto_start: bool = False) -> None:
    app = QApplication([])
    ex = GolfApp(camera_hub=camera_hub, auto_start=auto_start)
    ex.show()
    app.exec_()
