import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart'; // Firebase Storage import
import 'dart:convert';
import 'dart:io'; // File 처리
import 'package:path_provider/path_provider.dart';

import '../shared/menu_bottom.dart'; // 임시 디렉토리 접근

class VideocamScreen extends StatefulWidget {
  const VideocamScreen({super.key});

  @override
  _VideocamScreenState createState() => _VideocamScreenState();
}

class _VideocamScreenState extends State<VideocamScreen> {
  VideoPlayerController? _videoController; // 비디오 플레이어 컨트롤러
  List<String> _videoUrls = []; // 서버에서 받아온 비디오 파일 목록
  bool _isLoading = false;
  String? _selectedVideoUrl; // 현재 선택된 비디오 URL

  // 서버에서 비디오 파일 목록을 받아오는 함수
  Future<void> _fetchVideoList() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('http://192.168.137.245:5000/api/upload-video'));

      if (response.statusCode == 200) {
        setState(() {
          _videoUrls = List<String>.from(json.decode(response.body)['videos'])
              .map((filename) => 'http://192.168.137.245:5000/video/$filename')
              .toList();
          _isLoading = false;
        });
      } else {
        print('Failed to load videos. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error occurred: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 비디오 플레이어 초기화
  Future<void> _initializeVideoPlayer(String videoUrl) async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    try {
      await _videoController!.initialize();
      setState(() {
        _videoController!.play(); // 초기화 후 재생
      });
    } catch (error) {
      print("비디오 플레이어 초기화 중 오류: $error");
    }
  }

  // 비디오 재생
  void _playVideo(String videoUrl) {
    setState(() {
      _selectedVideoUrl = videoUrl; // 선택된 비디오 URL을 저장
    });
    print("Playing video from URL: $videoUrl");
    _initializeVideoPlayer(videoUrl);
  }

  // 비디오 저장 로직 (Firebase Storage에 업로드)
  Future<void> _saveVideo() async {
    if (_selectedVideoUrl != null) {
      try {
        // 비디오 파일을 서버에서 다운로드하여 로컬에 저장
        final videoFile = await _downloadVideoFile(_selectedVideoUrl!);

        if (videoFile != null) {
          // Firebase Storage에 비디오 업로드
          String fileName = _selectedVideoUrl!.split('/').last;
          UploadTask uploadTask = FirebaseStorage.instance
              .ref('videos/$fileName')
              .putFile(videoFile);

          // 업로드 진행 상황 추적
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            print('Progress: ${(snapshot.bytesTransferred / snapshot.totalBytes) * 100} %');
          });

          // 업로드 완료 확인
          await uploadTask.whenComplete(() {
            print('Video uploaded to Firebase Storage');
          });

          final downloadURL = await FirebaseStorage.instance
              .ref('videos/$fileName')
              .getDownloadURL();
          print('Download URL: $downloadURL');
        }
      } catch (error) {
        print('Error saving video: $error');
      }
    } else {
      print("No video selected.");
    }
  }

  // 서버에서 비디오 파일을 다운로드하여 로컬 파일로 저장하는 함수
  Future<File?> _downloadVideoFile(String videoUrl) async {
    try {
      final response = await http.get(Uri.parse(videoUrl));
      if (response.statusCode == 200) {
        final directory = await getTemporaryDirectory();  // 임시 디렉토리 얻기
        final filePath = '${directory.path}/${videoUrl.split('/').last}';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        print('Failed to download video. Status code: ${response.statusCode}');
        return null;
      }
    } catch (error) {
      print('Error occurred while downloading video: $error');
      return null;
    }
  }

  @override
  void dispose() {
    _videoController?.dispose(); // 비디오 플레이어 컨트롤러 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Videocam'), backgroundColor: Colors.cyan),
      body: Column(
        children: [
          // 비디오 플레이어를 화면에 표시하는 부분
          if (_videoController != null && _videoController!.value.isInitialized)
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _videoUrls.isEmpty
              ? Center(child: Text('No videos available'))
              : Expanded(
            child: ListView.builder(
              itemCount: _videoUrls.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Video ${index + 1}'),
                  onTap: () => _playVideo(_videoUrls[index]),
                );
              },
            ),
          ),
          // 비디오가 선택되었을 때만 "저장하기" 버튼을 표시
          if (_selectedVideoUrl != null)
            ElevatedButton(
              onPressed: _saveVideo, // 저장 버튼 클릭 시 저장 함수 호출
              child: Text('Save Video'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchVideoList, // 서버에서 비디오 목록을 가져오는 함수 호출
        child: Icon(Icons.refresh),
        backgroundColor: Colors.cyan,
      ),
      backgroundColor: Colors.white,
      bottomNavigationBar: const MenuBottom(),
    );
  }
}
