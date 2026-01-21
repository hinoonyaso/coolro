import '../controller/login_controller.dart';
import '../service/auth_handler.dart';
import 'package:get/get.dart';

class InitBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(AuthHandler());
    Get.put(LoginController());
  }
}