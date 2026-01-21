import 'package:flutter/material.dart';
import 'package:flutter_app/screens/intro_screen.dart';
import 'package:flutter_app/screens/leaderboard_screen.dart';
import 'package:flutter_app/screens/profile_screen.dart';
import 'package:flutter_app/screens/settings_screen.dart';
import 'package:flutter_app/screens/videocam_screen.dart';
import 'package:flutter_app/weather/weather_screen.dart';
import '../login/login.dart';
import '../screens/profile_screen.dart';
import '../controller/image_controller.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences import
import '../screens/replay_screen.dart';
import '../weather/weather_loading.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ImageController imageController = Get.find<ImageController>(); // ImageController 사용

    return Drawer(
      child: ListView(
        children: buildMenuItems(context, imageController),
      ),
    );
  }
}

List<Widget> buildMenuItems(BuildContext context, ImageController imageController) {
  final List<String> menuTitles = ['Profile', 'Weather', 'Replay', 'Logout'];
  List<Widget> menuItems = [];

  // SharedPreferences에서 이름과 이메일을 비동기적으로 불러옴
  Future<Map<String, String>> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // 값이 없을 경우 기본값을 설정 (default values)
    String fullName = prefs.getString('fullName')?.isNotEmpty == true ? prefs.getString('fullName')! : 'Coolro';
    String email = prefs.getString('email')?.isNotEmpty == true ? prefs.getString('email')! : 'Coolro@naver.com';
    return {'fullName': fullName, 'email': email};
  }

  // FutureBuilder를 통해 비동기적으로 불러온 데이터를 처리하여 UserAccountsDrawerHeader 표시
  menuItems.add(
    FutureBuilder<Map<String, String>>(
      future: _loadProfileData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const UserAccountsDrawerHeader(
            accountName: Text('Loading...'),
            accountEmail: Text('Loading...'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage('assets/images/Coolro_LoGo1.png'),
            ),
          );
        }

        if (snapshot.hasError) {
          return const UserAccountsDrawerHeader(
            accountName: Text('Error'),
            accountEmail: Text('Error'),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage('assets/images/Coolro_LoGo1.png'),
            ),
          );
        }

        final profileData = snapshot.data!;
        return UserAccountsDrawerHeader(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40.0),
              bottomRight: Radius.circular(40.0),
            ),
            color: Colors.cyan,
          ),
          accountName: Text(
            profileData['fullName']!,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          accountEmail: Text(profileData['email']!),
          currentAccountPicture: Obx(() => CircleAvatar(
            backgroundImage: imageController.selectedImage.value != null
                ? imageController.selectedImage.value! // FileImage 또는 AssetImage 사용
                : const AssetImage('assets/images/Coolro_LoGo1.png'), // 기본 이미지 표시
          )),
        );
      },
    ),
  );

  // 메뉴 항목 추가
  for (var element in menuTitles) {
    Widget screen = Container();
    IconData leadingIcon;

    switch (element) {
      case 'Profile':
        leadingIcon = Icons.person;
        screen = ProfileScreen();
        break;

      case 'Weather':
        leadingIcon = Icons.sunny;
        screen = WeatherLoading();
        break;

      case 'Replay':
        leadingIcon = Icons.videocam;
        screen = ReplayScreen();
        break;

      case 'Logout':
        leadingIcon = Icons.logout;
        screen = Login();
        break;

      default:
        leadingIcon = Icons.help;
    }

    menuItems.add(ListTile(
      leading: Icon(leadingIcon),
      title: Text(element, style: const TextStyle(fontSize: 18)),
      onTap: () {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => screen));
      },
    ));
  }

  return menuItems;
}
