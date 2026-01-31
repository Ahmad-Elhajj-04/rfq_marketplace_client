import 'package:rfq_marketplace_flutter/core/network/api_client.dart';

class NotificationsService {
  final ApiClient _api = ApiClient();

  Future<List<dynamic>> list({bool unreadOnly = false}) async {
    final path = unreadOnly
        ? "/v1/notifications?unread=1"
        : "/v1/notifications";
    final res = await _api.get(path);
    return (res["notifications"] as List<dynamic>);
  }

  Future<Map<String, dynamic>> markRead(int id) async {
    final res = await _api.post("/v1/notifications/$id/read", {});
    return res;
  }
}