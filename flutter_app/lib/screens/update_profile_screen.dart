import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:get/get.dart'; // GetX 사용
import 'package:shared_preferences/shared_preferences.dart';
import '../controller/image_controller.dart'; // ImageController import
import 'intro_screen.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({Key? key}) : super(key: key);

  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final ImageController imageController = Get.put(ImageController()); // GetX 컨트롤러
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData(); // 저장된 데이터를 불러오는 함수 호출
  }

  // 갤러리에서 이미지 선택 함수
  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imageController.updateImage(FileImage(File(pickedFile.path))); // 갤러리에서 선택한 이미지 저장
      });
    }
  }

  // 기본 이미지로 설정하는 함수
  void _setDefaultImage() {
    setState(() {
      imageController.updateImage(
        const AssetImage('assets/images/Coolro_LoGo1.png'), // 기본 이미지로 설정
      );
    });
  }

  // 이미지 선택 다이얼로그
  void _showImageSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('이미지 선택'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('기본 이미지'),
                onTap: () {
                  _setDefaultImage(); // 기본 이미지 선택
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_album),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  _pickImageFromGallery(); // 갤러리에서 이미지 선택
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullNameController.text = prefs.getString('fullName') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _phoneController.text = prefs.getString('phone') ?? '';
      _addressController.text = prefs.getString('address') ?? '';
    });
  }

  Future<void> _saveProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', _fullNameController.text);
    await prefs.setString('email', _emailController.text);
    await prefs.setString('phone', _phoneController.text);
    await prefs.setString('address', _addressController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile data saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context); // 이전 페이지로 돌아가기
          },
          icon: const Icon(LineAwesomeIcons.angle_left_solid),
        ),
        title: Text(
          'Edit Profile',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        backgroundColor: Colors.cyan,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20), // 패딩을 조정했습니다
          child: Column(
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: () => _showImageSelectionDialog(context), // 클릭 시 다이얼로그 표시
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Obx(() => imageController.selectedImage.value != null // 선택한 이미지가 있으면 해당 이미지 표시
                            ? Image(
                          image: imageController.selectedImage.value!, // AssetImage 또는 FileImage 사용
                          fit: BoxFit.cover,
                        )
                            : const Image(
                          image: AssetImage('assets/images/Coolro_LoGo1.png'),
                          fit: BoxFit.cover,
                        )),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.cyan,
                      ),
                      child: const Icon(LineAwesomeIcons.camera_retro_solid,
                          color: Colors.white, size: 30),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 50),
              Form(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        label: Text("Full Name"),
                        prefixIcon: Icon(LineAwesomeIcons.user),
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        label: Text("E-Mail"),
                        prefixIcon: Icon(LineAwesomeIcons.envelope),
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        label: Text("Phone No"),
                        prefixIcon: Icon(LineAwesomeIcons.phone_solid),
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        label: Text("Address"),
                        prefixIcon: Icon(LineAwesomeIcons.home_solid),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // 저장 버튼을 눌렀을 때의 로직 추가 가능
                          _saveProfileData();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const IntroScreen()),
                          ); // IntroScreen으로 이동
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          "Save",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white70,
    );
  }
}