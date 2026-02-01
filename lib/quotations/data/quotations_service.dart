import 'package:rfq_marketplace_flutter/core/network/api_client.dart';

class QuotationsService {
  final ApiClient _api = ApiClient();

  // GET /v1/quotations/mine (company)
  Future<List<dynamic>> mine() async {
    final res = await _api.get("/v1/quotations/mine");
    return (res["quotations"] as List<dynamic>);
  }

  // GET /v1/quotations/by-request?request_id=ID (user)
  Future<List<dynamic>> byRequest(int requestId) async {
    final res = await _api.get("/v1/quotations/by-request?request_id=$requestId");
    return (res["quotations"] as List<dynamic>);
  }

  // POST /v1/quotations (company)
  Future<Map<String, dynamic>> submit(Map<String, dynamic> payload) async {
    final res = await _api.post("/v1/quotations", payload);
    return res["quotation"] as Map<String, dynamic>;
  }

  // ✅ Alias (keeps older UI code working)
  Future<Map<String, dynamic>> submitQuotation(Map<String, dynamic> payload) {
    return submit(payload);
  }

  // POST /v1/quotations/{id}/accept (user)
  Future<Map<String, dynamic>> acceptQuotation(int quotationId) async {
    final res = await _api.post("/v1/quotations/$quotationId/accept", {});
    return res;
  }

  // POST /v1/quotations/{id}/reject (user)
  Future<Map<String, dynamic>> rejectQuotation(int quotationId) async {
    final res = await _api.post("/v1/quotations/$quotationId/reject", {});
    return res;
  }

  // POST /v1/quotations/{id}/withdraw (company)
  Future<Map<String, dynamic>> withdraw(int quotationId) async {
    final res = await _api.post("/v1/quotations/$quotationId/withdraw", {});
    return res;
  }
}