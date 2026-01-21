import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage import
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart'; // Video Player import
import 'package:flutter_app/shared/menu_bottom.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class ReplayScreen extends StatefulWidget {
  const ReplayScreen({Key? key}) : super(key: key);

  @override
  _ReplayScreenState createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  List<String> _videoUrls = []; // Firebase에서 가져온 비디오 URL 리스트
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVideoUrls(); // 비디오 목록을 가져오는 함수 호출
  }

  // Firebase Storage에서 비디오 URL을 가져오는 함수
  Future<void> _fetchVideoUrls() async {
    setState(() {
      _isLoading = true; // 로딩 상태로 변경
    });

    try {
      final ListResult result = await FirebaseStorage.instance.ref('videos').listAll();
      final List<String> urls = [];
      for (var ref in result.items) {
        final String url = await ref.getDownloadURL();
        urls.add(url); // 비디오 파일의 다운로드 URL을 리스트에 추가
      }
      setState(() {
        _videoUrls = urls;
        _isLoading = false; // 로딩 완료
      });
    } catch (e) {
      print('Error fetching video URLs: $e');
      setState(() {
        _isLoading = false; // 에러 발생 시에도 로딩 종료
      });
    }
  }

  // 비디오 옵션 화면으로 이동하는 함수 (재생/분석/삭제)
  void _showVideoOptions(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoOptionsScreen(videoUrl: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Replay Videos'), backgroundColor: Colors.cyan),
      backgroundColor: Colors.white,
      bottomNavigationBar: MenuBottom(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _videoUrls.isEmpty
          ? const Center(child: Text('No videos available'))
          : ListView.builder(
        itemCount: _videoUrls.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Video ${index + 1}'),
            onTap: () => _showVideoOptions(_videoUrls[index]), // 비디오 클릭 시 옵션 화면으로 이동
          );
        },
      ),
      // 우측 하단 새로고침 버튼 추가
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchVideoUrls, // 버튼 클릭 시 비디오 목록 다시 불러오기
        child: const Icon(Icons.refresh),
        backgroundColor: Colors.cyan,
      ),
    );
  }
}

// 비디오 옵션 화면
class VideoOptionsScreen extends StatelessWidget {
  final String videoUrl;

  const VideoOptionsScreen({required this.videoUrl, Key? key}) : super(key: key);

  // 비디오 분석을 위해 AWS 서버로 비디오 파일 전송
  Future<void> analyzeVideo(BuildContext context, String videoUrl) async {
    try {
      var uri = Uri.parse('http://3.107.188.29:5000/analyze');  // AWS 서버 URL
      var request = http.MultipartRequest('POST', uri);

      // Firebase에서 비디오 파일 다운로드 후, 임시 폴더에 저장
      http.Response response = await http.get(Uri.parse(videoUrl));
      if (response.statusCode == 200) {
        // Firebase에서 다운로드한 비디오 파일을 임시 디렉토리에 저장
        File videoFile = File('${(await getTemporaryDirectory()).path}/temp_video.mp4');
        await videoFile.writeAsBytes(response.bodyBytes);

        // 비디오 파일을 AWS 서버로 전송
        request.files.add(await http.MultipartFile.fromPath('video', videoFile.path));
        var res = await request.send();

        // 서버 응답 처리 (비디오 파일 다운로드)
        if (res.statusCode == 200) {
          // 서버에서 받은 비디오 파일을 로컬에 저장
          final outputVideoPath = '${(await getTemporaryDirectory()).path}/analyzed_video.mp4';
          final videoBytes = await res.stream.toBytes();
          final outputVideoFile = File(outputVideoPath);
          await outputVideoFile.writeAsBytes(videoBytes);

          // 피드백과 비디오 재생 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerScreen(videoFilePath: outputVideoPath),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('분석 실패: 서버 오류 (상태 코드: ${res.statusCode})')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase에서 비디오를 다운로드할 수 없습니다. 상태 코드: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('분석 중 오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Options')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // 재생하기 버튼 클릭 시 비디오 재생 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VideoPlayerScreen(videoFilePath: videoUrl)),
                );
              },
              child: const Text('재생하기'),
            ),
            ElevatedButton(
              onPressed: () async {
                // 분석하기 버튼 클릭 시 비디오 분석
                await analyzeVideo(context, videoUrl);
              },
              child: const Text('분석하기'),
            ),
            ElevatedButton(
              onPressed: () async {
                // 삭제하기 버튼 클릭 시 Firebase Storage에서 비디오 삭제
                try {
                  await FirebaseStorage.instance.refFromURL(videoUrl).delete();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('비디오 삭제 완료')),
                  );
                  Navigator.pop(context); // 삭제 후 이전 화면으로 돌아감
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('삭제 실패: $e')),
                  );
                }
              },
              child: const Text('삭제하기'),
            ),
          ],
        ),
      ),
    );
  }
}

// 비디오 재생 화면
class VideoPlayerScreen extends StatefulWidget {
  final String videoFilePath;

  const VideoPlayerScreen({required this.videoFilePath, Key? key}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoFilePath)
      ..initialize().then((_) {
        setState(() {});
        _controller.play();  // 비디오 자동 재생
      }).catchError((error) {
        print('비디오 재생 중 오류 발생: $error');  // 오류를 출력하여 디버그
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('비디오 재생 중 오류가 발생했습니다: $error')),
        );
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video Player')),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying ? _controller.pause() : _controller.play();
          });
        },
        child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}
