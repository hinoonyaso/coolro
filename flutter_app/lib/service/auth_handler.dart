import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/screens/intro_screen.dart';
import '../binding/app_binding.dart';
import '../binding/login_binding.dart';
import '../constants/firebase_const.dart';
import '../login/home.dart';
import '../login/login.dart';
import 'package:get/get.dart';

class AuthHandler extends GetxService {
  final _user = auth.currentUser.obs;

  @override
  void onReady() {
    super.onReady();
    _user.bindStream(auth.authStateChanges());
    ever(_user, moveToPage);
  }

  moveToPage(User? user) {
    if (user == null) {
      Get.off(() => const Login(), binding: LoginBinding());
    } else {
      Get.off(() => const IntroScreen(), binding: AppBinding());
    }
  }

  static Future<void> signIn(String email, String password) async {
    try {
      // Firebase 이메일/비밀번호 로그인 시도
      await auth.signInWithEmailAndPassword(email: email, password: password);

      // 로그인 성공 시 사용자 정보 가져오기
      User? user = auth.currentUser;

      if (user != null) {
        // 로그인 성공 시 홈 화면으로 이동
        print('User signed in successfully: ${user.email}');
        Get.off(() => const IntroScreen());
      } else {
        // 로그인 실패 시 예외 발생
        throw FirebaseAuthException(
            code: 'unknown', message: 'User not found after sign-in.');
      }
    } on FirebaseAuthException catch (e) {
      // Firebase 인증 관련 오류 처리
      if (e.code == 'user-not-found') {
        throw FirebaseAuthException(
            code: 'user-not-found', message: 'No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw FirebaseAuthException(
            code: 'wrong-password', message: 'Wrong password provided.');
      } else {
        throw FirebaseAuthException(code: e.code, message: e.message);
      }
    } catch (e) {
      // 기타 예외 처리
      debugPrint('Error during sign-in: $e');
      throw Exception('An unexpected error occurred during sign-in.');
    }
  }

  static Future<void> signUp(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 사용자 회원가입 성공 후 처리
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('User successfully registered: ${user.email}');
        Get.off(() => const Login());
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
        Get.snackbar('Sign Up Failed', 'The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
        Get.snackbar('Sign Up Failed', 'The account already exists for that email.');
      }
    } catch (e) {
      debugPrint('Error during sign up: $e');
      Get.snackbar('Error', 'An error occurred during sign up.');
    }
  }
}