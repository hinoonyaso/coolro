Golf posture analysis server (EC2)

Endpoints
- POST /analyze: multipart form-data with file field "video"; returns analyzed mp4.
- GET /health: simple status check.

Run
1) Install deps: pip install -r requirements.txt
2) Start: python app.py

Notes
- The analysis uses MediaPipe Pose and overlays feedback text on the video.
- Adjust thresholds in app.py if you want stricter or looser feedback.
