
import 'package:get/get.dart';
import 'package:rfq_marketplace_flutter/notifications/data/notifications_service.dart';

class NotificationsController extends GetxController {
  final _svc = NotificationsService();

  final isLoading = false.obs;
  final error = RxnString();
  final unreadOnly = true.obs;
  final items = <dynamic>[].obs;

  Future<void> load() async {
    try {
      isLoading.value = true;
      error.value = null;
      items.value = await _svc.list(unreadOnly: unreadOnly.value);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markRead(int id) async {
    await _svc.markRead(id);
    await load();
  }
}