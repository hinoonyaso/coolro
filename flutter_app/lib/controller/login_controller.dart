import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../binding/register_binding.dart';
import '../service/auth_handler.dart';
import '../login/resister.dart';
import 'package:get/get.dart';
import 'package:rive/rive.dart';

class LoginController extends GetxController {
  final RxBool _isLoading = false.obs;

  final _email = TextEditingController();
  final _password = TextEditingController();

  bool get isLoading => _isLoading.value;
  TextEditingController get email => _email;
  TextEditingController get password => _password;

  // 이메일과 패스워드를 검사하고, 유효하면 로그인 시도
  Future<void> validate() async {
    if (_email.text.trim().isEmpty || _password.text.trim().isEmpty) {
      Get.snackbar('Error', 'Email and password cannot be empty');
      return;
    }

    _isLoading.value = true;

    try {
      // 로그인 시도
      await AuthHandler.signIn(_email.text.trim(), _password.text.trim());

      // 로그인 성공 시에만 애니메이션 실행
      Get.dialog(_accept());
      Future.delayed(const Duration(seconds: 2)).then((_) {
        Get.back(); // 확인 창 닫기
      });

    } on FirebaseAuthException catch (e) {
      // FirebaseAuthException 처리
      Get.snackbar('Login Failed', e.message ?? 'Firebase error occurred.');
    } catch (e) {
      // 기타 예외 처리
      Get.snackbar('Login Failed', 'An error occurred: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // 회원가입 페이지로 이동
  void moveToRegister() {
    Get.to(() => const Resister(), binding: RegisterBinding());
  }

  // 로그인 성공 시 애니메이션
  Widget _accept() {
    return const SizedBox(
      width: 100,
      height: 100,
      child: RiveAnimation.asset('assets/images/check_icon.riv'),
    );
  }
}