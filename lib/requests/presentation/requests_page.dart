import 'package:flutter/material.dart';
import 'package:rfq_marketplace_flutter/core/ui/profile_avatar.dart';
import 'package:rfq_marketplace_flutter/requests/data/requests_service.dart';
import 'package:rfq_marketplace_flutter/requests/presentation/request_create_page.dart';
import 'package:rfq_marketplace_flutter/requests/presentation/request_details_page.dart';
import 'package:rfq_marketplace_flutter/notifications/presentation/notifications_page.dart';
import 'package:rfq_marketplace_flutter/shared/session.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final _service = RequestsService();

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
      final items = await _service.myRequests();
      setState(() => _requests = items);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RequestCreatePage()),
    );
    if (created == true) _load();
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  void _openProfileMenu() {
    // Simple placeholder for now (later: profile/settings/logout)
    final name = Session.name ?? "User";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Profile: $name (next feature)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (Session.name ?? "User").trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Requests"),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _requests.isEmpty
          ? const Center(child: Text("No requests yet. Tap + to create one."))
          : ListView.separated(
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final r = _requests[index] as Map<String, dynamic>;
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