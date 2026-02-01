import 'package:flutter/material.dart';

import 'package:rfq_marketplace_flutter/core/network/api_client.dart';
import 'package:rfq_marketplace_flutter/requests/presentation/request_details_page.dart';
import 'package:rfq_marketplace_flutter/notifications/presentation/notifications_page.dart';
import 'package:rfq_marketplace_flutter/subscriptions/presentation/subscriptions_page.dart';
import 'package:rfq_marketplace_flutter/quotations/presentation/my_quotations_page.dart';

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

  static const Map<int, String> _categoryTypeById = {
    1: "material",
    2: "material",
    3: "service",
    4: "service",
    5: "service",
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _getCategoryType(Map<String, dynamic> r) {
    final t = r["category_type"];
    if (t != null) return t.toString();
    final cid = (r["category_id"] as int?) ?? 0;
    return _categoryTypeById[cid] ?? "material";
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
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()));
  }

  Future<void> _openSubscriptions() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionsPage()));
    _load();
  }

  void _openMyQuotations() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyQuotationsPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Requests"),
        actions: [
          IconButton(onPressed: _openMyQuotations, icon: const Icon(Icons.receipt_long), tooltip: "My Quotations"),
          IconButton(onPressed: _openSubscriptions, icon: const Icon(Icons.tune), tooltip: "Subscriptions"),
          IconButton(onPressed: _openNotifications, icon: const Icon(Icons.notifications)),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _requests.isEmpty
          ? const Center(child: Text("No matching requests.\nSubscribe to categories to receive RFQs."))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _requests.length,
        itemBuilder: (context, i) {
          final r = _requests[i] as Map<String, dynamic>;
          final type = _getCategoryType(r);
          final isMaterial = type == "material";

          return _CompanyRequestCard(
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

class _CompanyRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final bool isMaterial;
  final VoidCallback onTap;

  const _CompanyRequestCard({
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
              Row(
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
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