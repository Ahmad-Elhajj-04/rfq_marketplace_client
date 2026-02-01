import 'package:get/get.dart';
import 'package:rfq_marketplace_flutter/requests/data/requests_service.dart';

class RequestsController extends GetxController {
  final _svc = RequestsService();

  final isLoading = false.obs;
  final error = RxnString();
  final items = <dynamic>[].obs;

  Future<void> loadMine() async {
    try {
      isLoading.value = true;
      error.value = null;
      items.value = await _svc.myRequests();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}