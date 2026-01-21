import os
from typing import Any

from flask import Flask, jsonify, request, send_from_directory

from .config import FLASK_HOST, FLASK_PORT, MP4_DIR
from .utils import ensure_dirs


def create_app() -> Flask:
    ensure_dirs(MP4_DIR)
    app = Flask(__name__)
    stored_data: list[dict[str, Any]] = []

    @app.route("/api/submit-score", methods=["GET", "POST"])
    def submit_score():
        if request.method == "POST":
            data = request.json or {}
            stored_data.append(data)
            return jsonify({"message": "Data received", "data": data}), 200
        return jsonify({"stored_data": stored_data}), 200

    @app.route("/api/upload-video", methods=["GET", "POST"])
    def upload_video():
        if request.method == "POST":
            file = request.files.get("file")
            if not file or not file.filename:
                return jsonify({"message": "Missing file"}), 400
            safe_name = os.path.basename(file.filename)
            file.save(str(MP4_DIR / safe_name))
            return jsonify({"message": "Video uploaded successfully!"}), 200
        video_files = os.listdir(MP4_DIR)
        return jsonify({"videos": video_files}), 200

    @app.route("/video/<filename>")
    def serve_video(filename):
        return send_from_directory(str(MP4_DIR), filename)

    return app


def run_flask_server() -> None:
    app = create_app()
    app.run(host=FLASK_HOST, port=FLASK_PORT)
