import 'package:flutter/material.dart';

import 'requests_service.dart';
import 'request_create_page.dart';
import 'request_details_page.dart';
import 'notifications_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Requests"),
        actions: [
          // 🔔 Notifications button
          IconButton(
            onPressed: _openNotifications,
            icon: const Icon(Icons.notifications),
            tooltip: "Notifications",
          ),
          // 🔄 Refresh button
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
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
          final id = r["id"] ?? "-";

          return ListTile(
            title: Text(title),
            subtitle: Text("Status: $status"),
            trailing: Text("#$id"),
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