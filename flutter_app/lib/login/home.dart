import 'package:flutter/material.dart';
import '../controller/app_controller.dart';
import 'package:get/get.dart';

class Home extends GetView<AppController> {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Login Success',
              style: TextStyle(
                  fontFamily: 'Ubuntu',
                  fontSize: 40,
                  fontWeight: FontWeight.bold),
            ),
            ElevatedButton(
                onPressed: controller.signOut, child: const Text('Sign Out'))
          ],
        ),
      ),
    );
  }
}