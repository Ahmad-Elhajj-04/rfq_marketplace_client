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

  double _norm(double value, double min, double max) {
    if (max <= min) return 0; // all equal
    return (value - min) / (max - min);
  }

  List<Map<String, dynamic>> _rank(List<dynamic> raw) {
    final list = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    // consider only "submitted" for ranking; keep others at bottom
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

    // weights (easy to explain)
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

    submitted.sort((a, b) => (_toDouble(a["_score"]) * 100000).toInt()
        .compareTo((_toDouble(b["_score"]) * 100000).toInt()));

    // add rank fields
    for (int i = 0; i < submitted.length; i++) {
      submitted[i]["_rank"] = i + 1;
    }

    // keep non-submitted at bottom
    return [...submitted, ...others];
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Only users should be allowed; if company calls and gets 403, we show a message
      final raw = await _service.byRequest(widget.requestId);
      final ranked = _rank(raw);

      setState(() {
        _quotes = ranked;
      });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Accepted ✅")),
      );
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }
  }

  Future<void> _reject(int quotationId) async {
    try {
      await _service.rejectQuotation(quotationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rejected ✅")),
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
    final isUser = Session.role == "user";

    return Scaffold(
      appBar: AppBar(
        title: Text("Quotations (Request ${widget.requestId})"),
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
          : ListView.separated(
        itemCount: _quotes.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final q = _quotes[i];

          final id = _toInt(q["id"]);
          final status = (q["status"] ?? "").toString();

          final total = _toDouble(q["total_price"]);
          final days = _toInt(q["delivery_days"]);
          final cost = _toDouble(q["delivery_cost"]);
          final terms = (q["payment_terms"] ?? "").toString();
          final notes = (q["notes"] ?? "").toString();

          final rank = q["_rank"];
          final isBest = (rank is int && rank == 1 && status == "submitted");

          return ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    "Total: ${total.toStringAsFixed(2)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                "Delivery: $days days • Delivery cost: ${cost.toStringAsFixed(2)}\n"
                    "Terms: $terms\n"
                    "Notes: $notes\n"
                    "Status: $status",
              ),
            ),
            isThreeLine: true,
            trailing: isUser && status == "submitted"
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () async {
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
                  },
                  child: const Text("Accept"),
                ),
                TextButton(
                  onPressed: () async {
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
                  },
                  child: const Text("Reject"),
                ),
              ],
            )
                : null,
          );
        },
      ),
    );
  }
}