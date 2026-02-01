import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:rfq_marketplace_flutter/core/constants/api.dart';
import 'package:rfq_marketplace_flutter/core/storage/token_store.dart';

class ApiClient {
  Future<Map<String, dynamic>> get(String path) async {
    final token = await TokenStore.get();
    final res = await http.get(
      Uri.parse("${Api.baseUrl}$path"),
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final token = await TokenStore.get();
    final res = await http.post(
      Uri.parse("${Api.baseUrl}$path"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final token = await TokenStore.get();
    final res = await http.patch(
      Uri.parse("${Api.baseUrl}$path"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  // ADD: delete() for unsubscribe endpoint
  Future<Map<String, dynamic>> delete(String path) async {
    final token = await TokenStore.get();
    final res = await http.delete(
      Uri.parse("${Api.baseUrl}$path"),
      headers: {
        "Accept": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      },
    );
    return _handle(res);
  }

  Map<String, dynamic> _handle(http.Response res) {
    final data = res.body.isNotEmpty ? jsonDecode(res.body) : {};

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data is Map<String, dynamic> ? data : {"data": data};
    }

    // try to extract a helpful message
    final msg = (data is Map<String, dynamic> && data["message"] != null)
        ? data["message"].toString()
        : "Request failed (${res.statusCode})";

    throw Exception(msg);
  }
}