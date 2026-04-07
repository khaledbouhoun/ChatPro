import 'package:get/get.dart';
import '../services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final RxBool isLogin = true.obs;
  final RxBool isLoading = false.obs;

  void toggleAuthMode() {
    isLogin.value = !isLogin.value;
  }

  /// [name] is only used for registration; pass empty string for login.
  Future<bool> authenticate(String email, String password, {String name = ''}) async {
    isLoading.value = true;
    try {
      bool success = false;
      if (isLogin.value) {
        success = await _authService.login(email, password);
      } else {
        // Use the provided name; fall back to the email prefix only as a last resort.
        final displayName = name.trim().isNotEmpty ? name.trim() : email.split('@')[0];
        success = await _authService.register(email, password, displayName);
      }
      return success;
    } finally {
      isLoading.value = false;
    }
  }
}
