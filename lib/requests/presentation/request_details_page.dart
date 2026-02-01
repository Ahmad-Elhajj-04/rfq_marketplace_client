import 'package:flutter/material.dart';

import 'package:rfq_marketplace_flutter/shared/session.dart';
import 'package:rfq_marketplace_flutter/requests/data/requests_service.dart';
import 'package:rfq_marketplace_flutter/quotations/presentation/quotation_submit_page.dart';
import 'package:rfq_marketplace_flutter/quotations/presentation/quotations_page.dart';

class RequestDetailsPage extends StatefulWidget {
  final Map<String, dynamic> request;
  const RequestDetailsPage({super.key, required this.request});

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  final _svc = RequestsService();

  late Map<String, dynamic> _request;
  bool _loading = false;
  String? _error;

  bool get isLoggedIn => Session.userId != null && Session.role != null;
  bool get isUser => Session.role == "user";
  bool get isCompany => Session.role == "company";

  @override
  void initState() {
    super.initState();
    _request = Map<String, dynamic>.from(widget.request);
  }

  Future<void> _cancelRequest() async {
    final id = _request["id"] as int;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final updated = await _svc.cancelRequest(id);
      setState(() => _request = updated);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Request cancelled ✅")));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _request["id"];
    final title = _request["title"]?.toString() ?? "Request";
    final desc = _request["description"]?.toString() ?? "";
    final city = _request["delivery_city"]?.toString() ?? "-";
    final qty = _request["quantity"]?.toString() ?? "-";
    final unit = _request["unit"]?.toString() ?? "-";
    final status = _request["status"]?.toString() ?? "-";

    final canCancel = isUser && status == "open";

    return Scaffold(
      appBar: AppBar(title: const Text("Request Details")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              _StatusPill(status: status),
              const SizedBox(height: 12),

              Text(desc),
              const SizedBox(height: 16),

              _InfoRow(label: "City", value: city),
              const SizedBox(height: 8),
              _InfoRow(label: "Quantity", value: "$qty $unit"),

              const SizedBox(height: 18),

              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              if (_loading) const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())),

              if (!isLoggedIn)
                const Text("Login to submit a quotation or manage requests.")
              else ...[
                if (isCompany) ...[
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.request_quote),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => QuotationSubmitPage(requestId: id)),
                        );
                      },
                      label: const Text("Submit Quotation"),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => QuotationsPage(requestId: id)),
                      );
                    },
                    child: const Text("View Quotations (restricted)"),
                  ),
                ],

                if (isUser) ...[
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.list_alt),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => QuotationsPage(requestId: id)),
                        );
                      },
                      label: const Text("View Quotations"),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                if (canCancel)
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cancel),
                      onPressed: _loading
                          ? null
                          : () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Cancel request?"),
                            content: const Text("This will close the request and stop receiving quotations."),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
                              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
                            ],
                          ),
                        );
                        if (ok == true) _cancelRequest();
                      },
                      label: const Text("Cancel Request"),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.black54))),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

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
      case "closed":
        bg = Colors.grey.shade300;
        fg = Colors.black87;
        break;
      default:
        bg = Colors.black12;
        fg = Colors.black87;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: fg, fontSize: 12)),
      ),
    );
  }
}