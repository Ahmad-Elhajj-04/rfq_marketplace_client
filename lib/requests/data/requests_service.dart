import 'package:rfq_marketplace_flutter/core/network/api_client.dart';

class RequestsService {
  final ApiClient _api = ApiClient();

  Future<List<dynamic>> myRequests() async {
    final res = await _api.get("/v1/requests/mine");
    return (res["requests"] as List<dynamic>);
  }

  Future<Map<String, dynamic>> createRequest(Map<String, dynamic> payload) async {
    final res = await _api.post("/v1/requests", payload);
    return res["request"] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRequest(int id) async {
    final res = await _api.get("/v1/requests/$id");
    return res["request"] as Map<String, dynamic>;
  }
  Future<Map<String, dynamic>> cancelRequest(int id) async {
    final res = await _api.post("/v1/requests/$id/cancel", {});
    return res["request"] as Map<String, dynamic>;
  }
}