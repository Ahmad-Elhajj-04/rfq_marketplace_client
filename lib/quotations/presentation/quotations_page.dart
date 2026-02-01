import 'package:flutter/material.dart';

import 'package:rfq_marketplace_flutter/quotations/data/quotations_service.dart';
import 'package:rfq_marketplace_flutter/shared/session.dart';

class QuotationsPage extends StatefulWidget {
  final int requestId;
  const QuotationsPage({super.key, required this.requestId});

  @override
  State<QuotationsPage> createState() => _QuotationsPageState();
}

class _QuotationsPageState extends State<QuotationsPage> {
  final _service = QuotationsService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _quotes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  // ---------- fallback client ranking (only used if backend doesn't provide is_best/rank) ----------
  double _norm(double value, double min, double max) {
    if (max <= min) return 0;
    return (value - min) / (max - min);
  }

  List<Map<String, dynamic>> _rankClient(List<Map<String, dynamic>> list) {
    final submitted = list.where((q) => (q["status"] ?? "") == "submitted").toList();
    final others = list.where((q) => (q["status"] ?? "") != "submitted").toList();
    if (submitted.isEmpty) return list;

    final prices = submitted.map((q) => _toDouble(q["total_price"])).toList();
    final days = submitted.map((q) => _toDouble(q["delivery_days"])).toList();
    final costs = submitted.map((q) => _toDouble(q["delivery_cost"])).toList();

    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final minDays = days.reduce((a, b) => a < b ? a : b);
    final maxDays = days.reduce((a, b) => a > b ? a : b);
    final minCost = costs.reduce((a, b) => a < b ? a : b);
    final maxCost = costs.reduce((a, b) => a > b ? a : b);

    const wPrice = 0.60;
    const wDays = 0.30;
    const wCost = 0.10;

    for (final q in submitted) {
      final p = _toDouble(q["total_price"]);
      final d = _toDouble(q["delivery_days"]);
      final c = _toDouble(q["delivery_cost"]);
      final score =
          wPrice * _norm(p, minPrice, maxPrice) +
              wDays * _norm(d, minDays, maxDays) +
              wCost * _norm(c, minCost, maxCost);
      q["_score"] = score;
    }

    submitted.sort((a, b) => (_toDouble(a["_score"]) * 100000).toInt().compareTo((_toDouble(b["_score"]) * 100000).toInt()));
    for (int i = 0; i < submitted.length; i++) {
      submitted[i]["_rank"] = i + 1;
      submitted[i]["is_best"] = (i == 0);
    }

    return [...submitted, ...others];
  }

  bool _hasBackendRanking(List<Map<String, dynamic>> list) {
    // backend returns is_best + rank + score
    for (final q in list) {
      if (q.containsKey("is_best") || q.containsKey("rank") || q.containsKey("score")) {
        return true;
      }
    }
    return false;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await _service.byRequest(widget.requestId);
      var list = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // If backend didn't rank, apply client fallback ranking
      if (!_hasBackendRanking(list)) {
        list = _rankClient(list);
      }

      setState(() => _quotes = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _accept(int quotationId) async {
    try {
      await _service.acceptQuotation(quotationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Accepted ✅")));
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  Future<void> _reject(int quotationId) async {
    try {
      await _service.rejectQuotation(quotationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rejected ✅")));
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  Future<void> _confirmAccept(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Accept quotation?"),
        content: const Text("This will award the request to this company."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
        ],
      ),
    );
    if (ok == true) _accept(id);
  }

  Future<void> _confirmReject(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reject quotation?"),
        content: const Text("This quotation will be marked as rejected."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
        ],
      ),
    );
    if (ok == true) _reject(id);
  }

  @override
  Widget build(BuildContext context) {
    final isUser = Session.role == "user";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Quotations"),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _quotes.isEmpty
          ? const Center(child: Text("No quotations yet."))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _quotes.length,
        itemBuilder: (context, i) {
          final q = _quotes[i];

          final id = _toInt(q["id"]);
          final status = (q["status"] ?? "").toString();

          final total = _toDouble(q["total_price"]);
          final days = _toInt(q["delivery_days"]);
          final cost = _toDouble(q["delivery_cost"]);
          final terms = (q["payment_terms"] ?? "").toString();
          final notes = (q["notes"] ?? "").toString();

          final isBest = (q["is_best"] == true) || ((q["_rank"] is int) && (q["_rank"] == 1) && status == "submitted");
          final rank = q["rank"] ?? q["_rank"];
          final score = q["score"] ?? q["_score"];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          "Total: ${total.toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      if (isBest)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            "BEST OFFER",
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),

                      // ✅ Menu actions to prevent overflow
                      if (isUser && status == "submitted")
                        PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == "accept") _confirmAccept(id);
                            if (v == "reject") _confirmReject(id);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: "accept", child: Text("Accept")),
                            PopupMenuItem(value: "reject", child: Text("Reject")),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _Chip(text: "Delivery: $days days"),
                      _Chip(text: "Delivery cost: ${cost.toStringAsFixed(2)}"),
                      _Chip(text: "Status: $status"),
                      if (rank != null) _Chip(text: "Rank: $rank"),
                      if (score != null) _Chip(text: "Score: ${_toDouble(score).toStringAsFixed(3)}"),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (terms.isNotEmpty) Text("Terms: $terms"),
                  if (notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text("Notes: $notes"),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    );
  }
}