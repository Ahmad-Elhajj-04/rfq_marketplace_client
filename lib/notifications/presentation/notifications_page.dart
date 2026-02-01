import 'package:flutter/material.dart';
import 'package:rfq_marketplace_flutter/notifications/data/notifications_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _service = NotificationsService();

  bool _loading = true;
  String? _error;

  bool _unreadOnly = true;
  List<dynamic> _items = [];

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
      final list = await _service.list(unreadOnly: _unreadOnly);
      setState(() => _items = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await _service.markRead(id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Marked as read ✅")),
      );

      // Reload list after marking read
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _unreadOnly ? "Unread Notifications" : "All Notifications";

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Clear switch UX
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.08))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _unreadOnly ? "Showing: Unread only" : "Showing: All",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Switch(
                  value: _unreadOnly,
                  onChanged: (v) {
                    setState(() => _unreadOnly = v);
                    _load();
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : _items.isEmpty
                ? Center(
              child: Text(
                _unreadOnly ? "No unread notifications" : "No notifications",
              ),
            )
                : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = _items[i] as Map<String, dynamic>;
                final id = n["id"] as int;
                final title = (n["title"] ?? "").toString();
                final body = (n["body"] ?? "").toString();
                final type = (n["type"] ?? "").toString();
                final isRead = (n["is_read"] == 1);

                return ListTile(
                  title: Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text("$type\n$body"),
                  isThreeLine: true,
                  trailing: isRead
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : TextButton(
                    onPressed: () => _markRead(id),
                    child: const Text("Read"),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}