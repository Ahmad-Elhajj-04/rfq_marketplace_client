import 'package:flutter/material.dart';

import 'package:rfq_marketplace_flutter/core/network/api_client.dart';
import 'package:rfq_marketplace_flutter/shared/session.dart';
import 'package:rfq_marketplace_flutter/shared/nav_intent.dart';
import 'package:rfq_marketplace_flutter/requests/presentation/request_details_page.dart';
import 'package:rfq_marketplace_flutter/quotations/presentation/quotation_submit_page.dart';

class ExploreRequestsPage extends StatefulWidget {
  final int categoryId;
  final String title;
  final String subtitle;
  final String assetPath;

  const ExploreRequestsPage({
    super.key,
    required this.categoryId,
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });

  @override
  State<ExploreRequestsPage> createState() => _ExploreRequestsPageState();
}

class _ExploreRequestsPageState extends State<ExploreRequestsPage> {
  final _api = ApiClient();

  bool _loading = true;
  String? _error;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
    // If user came back from login, try to continue pending action
    WidgetsBinding.instance.addPostFrameCallback((_) => _resumePendingIfAny());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.get("/v1/public/requests?category_id=${widget.categoryId}");
      setState(() => _requests = (res["requests"] as List<dynamic>));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _resumePendingIfAny() {
    final pending = NavIntent.take();
    if (pending == null) return;

    final action = pending["action"]?.toString();
    final req = pending["request"];

    if (action == "submit-quotation" && req is Map<String, dynamic>) {
      // Only continue if user is now a company
      if (Session.role == "company") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QuotationSubmitPage(requestId: req["id"]),
          ),
        );
      } else {
        // If they logged in as user, show message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Company login required to submit a quotation.")),
        );
      }
    }
  }

  Future<void> _openDetails(Map<String, dynamic> r) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RequestDetailsPage(request: r),
      ),
    );
  }

  Future<void> _submitQuotationFlow(Map<String, dynamic> r) async {
    // If already company, go directly
    if (Session.role == "company") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuotationSubmitPage(requestId: r["id"])),
      );
      return;
    }

    // Not company: store pending action then go to company login
    NavIntent.set({
      "action": "submit-quotation",
      "request": r,
    });

    await Navigator.pushNamed(context, "/login", arguments: "company");

    // When login page pops back, resume happens in initState callback (next frame)
    _resumePendingIfAny();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 950),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Image.asset(
                      widget.assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black12,
                        child: const Center(child: Icon(Icons.image, size: 64)),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(widget.subtitle, style: const TextStyle(color: Colors.black54)),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text(_error!))
                    : _requests.isEmpty
                    ? const Center(child: Text("No open requests found for this category."))
                    : ListView.separated(
                  itemCount: _requests.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = _requests[i] as Map<String, dynamic>;
                    final title = r["title"]?.toString() ?? "Untitled";
                    final city = r["delivery_city"]?.toString() ?? "-";
                    final status = r["status"]?.toString() ?? "-";

                    return ListTile(
                      title: Text(title),
                      subtitle: Text("$city • $status"),
                      onTap: () => _openDetails(r),
                      trailing: TextButton(
                        onPressed: () => _submitQuotationFlow(r),
                        child: const Text("Quote"),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}