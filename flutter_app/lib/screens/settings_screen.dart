import 'package:flutter/material.dart';
import 'package:flutter_app/shared/menu_bottom.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings'), backgroundColor: Colors.cyan),
      body: Center(
        child: FlutterLogo(),
      ),
      backgroundColor: Colors.white,
      bottomNavigationBar: MenuBottom(),
    );
  }
}
