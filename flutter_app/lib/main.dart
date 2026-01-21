import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/weather/weather_loading.dart';
import 'package:get/get.dart'; // GetX 추가
import 'package:flutter_app/screens/intro_screen.dart';
import 'package:flutter_app/screens/leaderboard_screen.dart';
import 'package:flutter_app/screens/profile_screen.dart';
import 'package:flutter_app/screens/videocam_screen.dart';
import 'package:flutter_app/screens/settings_screen.dart';
import 'package:flutter_app/weather/weather_screen.dart';
import 'package:flutter_app/splash.main.dart';
import '../login/login.dart'; // Login 페이지 import
import '../binding/login_binding.dart';
import 'controller/image_controller.dart';
import 'firebase_options.dart'; // LoginBinding import
import '../controller/login_controller.dart';
import '../service/auth_handler.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //Get.put(AuthHandler());
  Get.put(LoginController());
  Get.put(ImageController());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( // GetMaterialApp으로 변경
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash', // 초기 경로 설정
      getPages: [
        GetPage(name: '/splash', page: () => SplashScreen()),
        GetPage(name: '/home', page: () => IntroScreen()),
        GetPage(name: '/leaderboard', page: () => LeaderboardScreen()),
        GetPage(name: '/videocam', page: () => VideocamScreen()),
        GetPage(name: '/settings', page: () => SettingsScreen()),
        GetPage(name: '/profile', page: () => ProfileScreen()),
        GetPage(name: '/weather', page: () => WeatherLoading()),
        GetPage(
          name: '/login',
          page: () => Login(),
          binding: LoginBinding(), // Login 페이지와 컨트롤러 바인딩
        ),
      ],
    );
  }
}