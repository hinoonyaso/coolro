import 'package:flutter/material.dart';

class MenuBottom extends StatelessWidget {
  const MenuBottom({super.key});
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      onTap: (int index) {
        switch (index) {
          case 0:
            Navigator.of(context, rootNavigator: true).pushNamed("/home");
            break;
          case 1:
            Navigator.of(context, rootNavigator: true)
                .pushNamed("/leaderboard");
            break;
          case 2:
            Navigator.of(context, rootNavigator: true).pushNamed("/videocam");
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home, color: Colors.cyan), label: ('home')),
        BottomNavigationBarItem(
            icon: Icon(
              Icons.leaderboard,
              color: Colors.cyan,
            ),
            label: 'Leaderboard'),
        BottomNavigationBarItem(
            icon: Icon(
              Icons.videocam,
              color: Colors.cyan,
            ),
            label: 'Videocam'),
        /*BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),*/
      ],
    );
  }
}
