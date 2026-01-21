import 'package:flutter/material.dart';
import 'package:flutter_app/shared/menu_bottom.dart';
import 'package:flutter_app/shared/menu_drawer.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CoolRo'), backgroundColor: Colors.cyan),
      drawer: MenuDrawer(),
      body: Center(
        child: Image.asset('assets/images/Coolro_LoGo.png'),
      ),
      backgroundColor: Colors.white,
      bottomNavigationBar: MenuBottom(),
    );
  }
}
