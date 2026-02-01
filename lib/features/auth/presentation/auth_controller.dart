import 'package:get/get.dart';
import 'package:rfq_marketplace_flutter/core/storage/token_store.dart';
import 'package:rfq_marketplace_flutter/shared/session.dart';
import 'package:rfq_marketplace_flutter/features/auth/data/auth_service.dart';

class AuthController extends GetxController {
  final _auth = AuthService();

  final isLoading = false.obs;
  final error = RxnString();

  Future<void> login(String email, String password, {String? expectedRole}) async {
    try {
      isLoading.value = true;
      error.value = null;

      final res = await _auth.login(email, password);
      final token = res["token"] as String;
      final user = res["user"] as Map<String, dynamic>;
      final role = (user["role"] ?? "").toString();

      if (expectedRole != null && role != expectedRole) {
        error.value = "This account is not a $expectedRole account.";
        return;
      }

      await TokenStore.save(token);

      Session.userId = user["id"] as int;
      Session.role = role;
      Session.name = (user["name"] ?? "").toString();

      // back to landing
      Get.offAllNamed("/");
    } finally {
      isLoading.value = false;
    }
  }
}