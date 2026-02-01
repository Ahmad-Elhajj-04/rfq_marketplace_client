import 'package:flutter/material.dart';

import 'package:rfq_marketplace_flutter/core/storage/token_store.dart';
import 'package:rfq_marketplace_flutter/core/network/api_client.dart';
import 'package:rfq_marketplace_flutter/shared/session.dart';
import 'package:rfq_marketplace_flutter/app/landing_page.dart';
import 'package:rfq_marketplace_flutter/requests/presentation/requests_page.dart';
import 'package:rfq_marketplace_flutter/requests/presentation/company_requests_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}
class _AuthGateState extends State<AuthGate> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }
  Future<void> _bootstrap() async {
    final token = await TokenStore.get();

    if (token == null) {
      // Not logged in
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    try {
      final api = ApiClient();
      final res = await api.get("/v1/auth/me");
      final user = res["user"] as Map<String, dynamic>;

      Session.userId = user["id"] as int;
      Session.role = (user["role"] ?? "").toString();
    } catch (_) {
      await TokenStore.clear();
      Session.userId = null;
      Session.role = null;
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (Session.role == "company") return const CompanyRequestsPage();
    if (Session.role == "user") return const RequestsPage();
    return const LandingPage();
  }
}