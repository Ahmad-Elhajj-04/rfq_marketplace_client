import 'api_client.dart';

class QuotationsService {
  final ApiClient _api = ApiClient();

  Future<List<dynamic>> byRequest(int requestId) async {
    final res = await _api.get("/v1/quotations/by-request?request_id=$requestId");
    return (res["quotations"] as List<dynamic>);
  }

  Future<Map<String, dynamic>> submitQuotation(Map<String, dynamic> payload) async {
    final res = await _api.post("/v1/quotations", payload);
    return res["quotation"] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> acceptQuotation(int quotationId) async {
    final res = await _api.post("/v1/quotations/$quotationId/accept", {});
    return res;
  }
}