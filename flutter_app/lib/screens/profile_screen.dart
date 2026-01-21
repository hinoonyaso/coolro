import 'package:flutter/material.dart';
import 'package:flutter_app/screens/update_profile_screen.dart';
import 'package:flutter_app/shared/menu_drawer.dart';
import 'package:flutter_app/shared/menu_bottom.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text('Profile'), backgroundColor: Colors.cyan),
      drawer: MenuDrawer(),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(100),
          child: Column(
            children: [
              Stack(
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image(
                            image:
                                AssetImage('assets/images/Coolro_LoGo1.png'))),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          color: Colors.cyan),
                      child: const Icon(LineAwesomeIcons.pencil_alt_solid,
                          color: Colors.black, size: 30),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
              //Text('Coolro', style: Theme.of(context).textTheme.headlineLarge),//
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const UpdateProfileScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      side: BorderSide.none,
                      shape: const StadiumBorder()),
                  child: const Text('Edit Profile',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.white,
      bottomNavigationBar: MenuBottom(),
    );
  }
}
