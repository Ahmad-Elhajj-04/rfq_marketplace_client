import 'package:flutter/material.dart';

import 'package:rfq_marketplace_flutter/requests/data/requests_service.dart';
import 'package:rfq_marketplace_flutter/requests/presentation/request_create_page.dart';
import 'package:rfq_marketplace_flutter/requests/presentation/request_details_page.dart';
import 'package:rfq_marketplace_flutter/notifications/presentation/notifications_page.dart';
import 'package:rfq_marketplace_flutter/shared/session.dart';
import 'package:rfq_marketplace_flutter/core/ui/profile_avatar.dart';

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

  // Fallback map if request doesn't include category_type yet
  static const Map<int, String> _categoryTypeById = {
    1: "material", // Iron
    2: "material", // Cement
    3: "service",  // Electrical Services
    4: "service",  // Logistics
    5: "service",  // Plumbing
  };

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

  String _getCategoryType(Map<String, dynamic> r) {
    final t = r["category_type"];
    if (t != null) return t.toString();
    final cid = (r["category_id"] as int?) ?? 0;
    return _categoryTypeById[cid] ?? "material";
  }

  @override
  Widget build(BuildContext context) {
    final displayName = (Session.name ?? "User").trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Requests"),
        actions: [
          IconButton(onPressed: _openNotifications, icon: const Icon(Icons.notifications)),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ProfileAvatar(name: displayName),
            ),
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
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _requests.length,
        itemBuilder: (context, i) {
          final r = _requests[i] as Map<String, dynamic>;
          final type = _getCategoryType(r);
          final isMaterial = type == "material";

          return _RequestCard(
            request: r,
            isMaterial: isMaterial,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RequestDetailsPage(request: r)),
              );
            },
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool isMaterial;
  final VoidCallback onTap;

  const _RequestCard({
    required this.request,
    required this.isMaterial,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = request["title"]?.toString() ?? "Untitled";
    final status = request["status"]?.toString() ?? "-";
    final city = request["delivery_city"]?.toString() ?? "-";

    final qty = request["quantity"]?.toString() ?? "";
    final unit = request["unit"]?.toString() ?? "";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + badge
              Row(
                children: [
                  Expanded(
                    child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  _TypeBadge(isMaterial: isMaterial),
                ],
              ),
              const SizedBox(height: 8),

              if (isMaterial) ...[
                Text("Quantity: $qty $unit"),
                const SizedBox(height: 4),
              ] else ...[
                const Text("Service Request"),
                const SizedBox(height: 4),
              ],

              Text("City: $city"),
              const SizedBox(height: 6),

              _StatusLine(status: status),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final bool isMaterial;
  const _TypeBadge({required this.isMaterial});

  @override
  Widget build(BuildContext context) {
    final text = isMaterial ? "MATERIAL" : "SERVICE";
    final bg = isMaterial ? Colors.blue.shade100 : Colors.orange.shade100;
    final fg = isMaterial ? Colors.blue.shade900 : Colors.orange.shade900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final String status;
  const _StatusLine({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case "open":
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        break;
      case "awarded":
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        break;
      case "cancelled":
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        break;
      default:
        bg = Colors.black12;
        fg = Colors.black87;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(status.toUpperCase(), style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}