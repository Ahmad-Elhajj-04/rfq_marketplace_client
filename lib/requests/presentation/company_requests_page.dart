import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:rfq_marketplace_flutter/core/network/api_client.dart';
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

  // ----- WS Banner -----
  WebSocketChannel? _ws;
  OverlayEntry? _bannerEntry;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _startWs();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerEntry?.remove();
    _ws?.sink.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _api.get("/v1/requests"); // company browse endpoint
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

  // =========================
  // WebSocket (Centrifugo)
  // =========================
  void _startWs() {
    final userId = Session.userId; // must be set on login
    if (userId == null) return;

    final wsUrl = Uri.parse("ws://localhost:8000/connection/websocket");
    _ws = WebSocketChannel.connect(wsUrl);

    int id = 1;

    void send(Map<String, dynamic> msg) {
      _ws?.sink.add(jsonEncode(msg));
    }

    // Connect
    send({
      "id": id++,
      "method": "connect",
      "params": {}
    });

    // Subscribe to personal channel (company also uses user:{id})
    send({
      "id": id++,
      "method": "subscribe",
      "params": {"channel": "user:$userId"}
    });

    _ws!.stream.listen(
          (raw) {
        try {
          final msg = jsonDecode(raw.toString());
          final push = msg["push"];
          if (push is Map<String, dynamic>) {
            final pub = push["pub"];
            if (pub is Map<String, dynamic>) {
              final data = pub["data"];
              _handleBannerData(data);
            }
          }
        } catch (_) {}
      },
      onError: (_) {},
      onDone: () {
        _ws = null;
      },
    );
  }

  void _handleBannerData(dynamic data) {
    if (data is Map<String, dynamic>) {
      final title = (data["title"] ?? "Notification").toString();
      final body = (data["body"] ?? "").toString();
      _showBanner(title, body);
      return;
    }

    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          final title = (decoded["title"] ?? "Notification").toString();
          final body = (decoded["body"] ?? "").toString();
          _showBanner(title, body);
        }
      } catch (_) {}
    }
  }

  void _showBanner(String title, String body) {
    _bannerTimer?.cancel();
    _bannerEntry?.remove();

    _bannerEntry = OverlayEntry(
      builder: (_) => Positioned(
        top: 16,
        left: 16,
        right: 16,
        child: _BannerCard(
          title: title,
          body: body,
          onClose: () {
            _bannerEntry?.remove();
            _bannerEntry = null;
          },
        ),
      ),
    );

    Overlay.of(context).insert(_bannerEntry!);

    _bannerTimer = Timer(const Duration(seconds: 4), () {
      _bannerEntry?.remove();
      _bannerEntry = null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _requests.isEmpty
          ? const Center(
        child: Text("No matching requests.\nSubscribe to categories to receive RFQs."),
      )
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

// ---------------- Banner UI ----------------

class _BannerCard extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onClose;

  const _BannerCard({
    required this.title,
    required this.body,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.90),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              blurRadius: 16,
              color: Colors.black26,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.white70),
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}