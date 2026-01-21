import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final double width;
  final double height;
  final Widget? child;
  final void Function()? onPressed;
  const GradientButton(
      {super.key,
        required this.width,
        required this.height,
        this.child,
        this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed!,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            gradient: const LinearGradient(
              colors: [
                Color.fromARGB(255, 14, 103, 255),
                Color.fromARGB(255, 47, 161, 255),
                Color.fromARGB(255, 80, 200, 255),
              ],
            )),
        child: Center(
          child: SizedBox(
            height: 30,
            child: child,
          ),
        ),
      ),
    );
  }
}