import 'package:flutter/material.dart';
import 'package:flutter_app/weather/weather_loading.dart';
import 'package:flutter_app/weather/weather_screen.dart';

class WeatherMain extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather app',
      theme: ThemeData(primarySwatch: Colors.cyan),
      home: WeatherScreen(),
    );
  }
}
