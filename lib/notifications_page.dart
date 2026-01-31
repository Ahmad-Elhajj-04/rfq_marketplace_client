import 'package:flutter/material.dart';
import 'notifications_service.dart';

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
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text("Unread only"),
            value: _unreadOnly,
            onChanged: (v) {
              setState(() => _unreadOnly = v);
              _load();
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!))
                : _items.isEmpty
                ? const Center(child: Text("No notifications"))
                : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final n = _items[i] as Map<String, dynamic>;
                final id = n["id"];
                final title = n["title"]?.toString() ?? "";
                final body = n["body"]?.toString() ?? "";
                final type = n["type"]?.toString() ?? "";
                final isRead = (n["is_read"] == 1);

                return ListTile(
                  title: Text(title,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      )),
                  subtitle: Text("$type\n$body"),
                  isThreeLine: true,
                  trailing: isRead
                      ? const Icon(Icons.check, color: Colors.green)
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