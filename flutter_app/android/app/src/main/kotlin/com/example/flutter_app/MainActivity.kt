import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example/pose"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getPoseLandmarks") {
                    val videoPath: String? = call.argument<String>("videoPath")
                    if (videoPath != null) {
                        val poseLandmarks = extractPoseLandmarks(videoPath)
                        if (poseLandmarks != null) {
                            result.success(poseLandmarks)
                        } else {
                            result.error("UNAVAILABLE", "Pose landmarks not available.", null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Video path is null", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun extractPoseLandmarks(videoPath: String): List<List<Float>>? {
        val landmarks = ArrayList<List<Float>>()
        val point1 = ArrayList<Float>()
        point1.add(0.5f)
        point1.add(0.5f)
        val point2 = ArrayList<Float>()
        point2.add(0.7f)
        point2.add(0.7f)

        landmarks.add(point1)
        landmarks.add(point2)

        return landmarks
    }
}