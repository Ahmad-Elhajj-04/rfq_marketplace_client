import 'package:flutter/material.dart';

import 'package:rfq_marketplace_flutter/shared/session.dart';
import 'package:rfq_marketplace_flutter/quotations/presentation/quotations_page.dart';
import 'package:rfq_marketplace_flutter/quotations/presentation/quotation_submit_page.dart';

class RequestDetailsPage extends StatelessWidget {
  final Map<String, dynamic> request;
  const RequestDetailsPage({super.key, required this.request});

  bool get isLoggedIn => Session.userId != null && Session.role != null;
  bool get isUser => Session.role == "user";
  bool get isCompany => Session.role == "company";

  @override
  Widget build(BuildContext context) {
    final id = request["id"];
    final title = request["title"]?.toString() ?? "Request";
    final desc = request["description"]?.toString() ?? "";
    final city = request["delivery_city"]?.toString() ?? "-";
    final qty = request["quantity"]?.toString() ?? "-";
    final unit = request["unit"]?.toString() ?? "-";
    final status = request["status"]?.toString() ?? "-";

    return Scaffold(
      appBar: AppBar(
        title: Text("Request #$id"),
      ),
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
              const SizedBox(height: 8),

              if (request["budget_min"] != null || request["budget_max"] != null) ...[
                _InfoRow(
                  label: "Budget",
                  value: "${request["budget_min"] ?? "-"} - ${request["budget_max"] ?? "-"}",
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 18),

              // --------------------
              // Actions (role-aware)
              // --------------------
              if (!isLoggedIn) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Want to interact with this request?", style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 6),
                      Text("Log in to submit a quotation (company) or manage your requests (user)."),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: null, // enabled by routes (landing already provides)
                        child: const Text("Login as User (from top bar)"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: null,
                        child: const Text("Login as Company (from top bar)"),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Company: submit quotation
                if (isCompany)
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.request_quote),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuotationSubmitPage(requestId: id),
                          ),
                        );
                      },
                      label: const Text("Submit Quotation"),
                    ),
                  ),

                if (isCompany) const SizedBox(height: 10),

                // User: view quotations
                if (isUser)
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.list_alt),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuotationsPage(requestId: id),
                          ),
                        );
                      },
                      label: const Text("View Quotations"),
                    ),
                  ),

                // Company can also open quotations page (it will show locked UI if forbidden)
                if (isCompany)
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.visibility),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuotationsPage(requestId: id),
                          ),
                        );
                      },
                      label: const Text("View Quotations (restricted)"),
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
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
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
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.bold, color: fg, fontSize: 12),
        ),
      ),
    );
  }
}