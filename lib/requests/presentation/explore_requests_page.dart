import 'package:flutter/material.dart';
import 'package:rfq_marketplace_flutter/core/network/api_client.dart';
import 'package:rfq_marketplace_flutter/shared/session.dart';
import 'package:rfq_marketplace_flutter/requests/presentation/request_details_page.dart';
import 'package:rfq_marketplace_flutter/requests/presentation/request_create_page.dart';

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

  Future<void> _createRequestForCategory() async {
    final created = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RequestCreatePage()),
    );
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = Session.role == "user";

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Image.asset(widget.assetPath, fit: BoxFit.cover),
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
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("No open requests found for this category."),
                      const SizedBox(height: 12),
                      if (isUser)
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _createRequestForCategory,
                            child: const Text("Create Request"),
                          ),
                        ),
                    ],
                  ),
                )
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RequestDetailsPage(request: r)),
                        );
                      },
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