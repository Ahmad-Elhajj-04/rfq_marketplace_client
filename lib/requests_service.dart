import 'api_client.dart';

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
}