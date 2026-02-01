import 'package:rfq_marketplace_flutter/core/network/api_client.dart';

class SubscriptionsService {
  final ApiClient _api = ApiClient();

  Future<List<dynamic>> categories() async {
    final res = await _api.get("/v1/categories");
    return (res["categories"] as List<dynamic>);
  }

  Future<List<dynamic>> mySubscriptions() async {
    final res = await _api.get("/v1/subscriptions");
    return (res["subscriptions"] as List<dynamic>);
  }

  Future<Map<String, dynamic>> subscribe(int categoryId) async {
    final res = await _api.post("/v1/subscriptions", {"category_id": categoryId});
    return res["subscription"] as Map<String, dynamic>;
  }

  Future<void> unsubscribe(int subscriptionId) async {
    await _api.delete("/v1/subscriptions/$subscriptionId");
  }
}