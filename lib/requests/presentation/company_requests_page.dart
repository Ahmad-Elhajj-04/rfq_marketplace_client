import 'package:flutter/material.dart';
import 'package:rfq_marketplace_flutter/core/network/api_client.dart';
import 'package:rfq_marketplace_flutter/core/ui/profile_avatar.dart';
import 'package:rfq_marketplace_flutter/requests/presentation/request_details_page.dart';
import 'package:rfq_marketplace_flutter/notifications/presentation/notifications_page.dart';
import 'package:rfq_marketplace_flutter/shared/session.dart';

class CompanyRequestsPage extends StatefulWidget {
  const CompanyRequestsPage({super.key});

  @override
  State<CompanyRequestsPage> createState() => _CompanyRequestsPageState();
}

class _CompanyRequestsPageState extends State<CompanyRequestsPage> {
  final _api = ApiClient();

  bool _loading = true;
  String? _error;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.get("/v1/requests");
      setState(() => _requests = (res["requests"] as List<dynamic>));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  void _openProfileMenu() {
    final name = Session.name ?? "Company";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Profile: $name (next feature)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (Session.name ?? "Company").trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Requests"),
        actions: [
          IconButton(
            onPressed: _openNotifications,
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: _openProfileMenu,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ProfileAvatar(name: displayName),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _requests.isEmpty
          ? const Center(child: Text("No matching requests.\nSubscribe to categories to receive RFQs."))
          : ListView.separated(
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final r = _requests[i] as Map<String, dynamic>;
          final title = r["title"]?.toString() ?? "Untitled";
          final status = r["status"]?.toString() ?? "-";

          return ListTile(
            title: Text(title),
            subtitle: Text("Status: $status"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RequestDetailsPage(request: r),
                ),
              );
            },
          );
        },
      ),
    );
  }
}