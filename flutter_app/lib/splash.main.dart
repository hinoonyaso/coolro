import 'package:flutter/material.dart';
import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      Navigator.of(context).pushReplacementNamed('/login');//수정사항 나중에 다시 고쳐야함
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedTextKit(
          animatedTexts: [
            TyperAnimatedText(
              'C o o l R o',
              textStyle: TextStyle(
                fontSize: 50,
                color: Colors.cyan,
                fontWeight: FontWeight.bold,
              ),
              speed: Duration(milliseconds: 80),
            ),
          ],
          totalRepeatCount: 1,
          pause: Duration(milliseconds: 1500),
          displayFullTextOnTap: true,
          stopPauseOnTap: true,
        ),
      ),
    );
  }
}
