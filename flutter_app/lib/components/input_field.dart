import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final TextEditingController? controller;
  final TextInputType? type;
  final String hintText;
  final Icon prefixIcon;
  final bool? obscure;
  const InputField(
      {super.key,
        this.controller,
        required this.hintText,
        required this.prefixIcon,
        this.obscure = false,
        this.type = TextInputType.emailAddress});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure!,
      keyboardType: type,
      decoration: InputDecoration(prefixIcon: prefixIcon, hintText: hintText),
    );
  }
}