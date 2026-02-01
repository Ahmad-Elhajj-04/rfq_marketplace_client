import 'package:flutter/material.dart';
import 'package:rfq_marketplace_flutter/quotations/data/quotations_service.dart';

class MyQuotationsPage extends StatefulWidget {
  const MyQuotationsPage({super.key});

  @override
  State<MyQuotationsPage> createState() => _MyQuotationsPageState();
}

class _MyQuotationsPageState extends State<MyQuotationsPage> {
  final _svc = QuotationsService();

  bool _loading = true;
  String? _error;
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
      final list = await _svc.mine();
      setState(() => _items = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _withdraw(int quotationId) async {
    try {
      await _svc.withdraw(quotationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Withdrawn ✅")));
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Quotations"),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _items.isEmpty
          ? const Center(child: Text("No quotations yet."))
          : ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final q = _items[i] as Map<String, dynamic>;
          final id = q["id"] as int;
          final requestId = q["request_id"];
          final status = (q["status"] ?? "").toString();
          final total = (q["total_price"] ?? "").toString();
          final days = (q["delivery_days"] ?? "").toString();

          final canWithdraw = status == "submitted";

          return ListTile(
            title: Text("Quotation #$id • Request #$requestId"),
            subtitle: Text("Total: $total • Delivery: $days days • Status: $status"),
            trailing: canWithdraw
                ? TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Withdraw quotation?"),
                    content: const Text("This will remove your quotation if it hasn’t been accepted."),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
                    ],
                  ),
                );
                if (ok == true) _withdraw(id);
              },
              child: const Text("Withdraw"),
            )
                : const Icon(Icons.check_circle, color: Colors.grey),
          );
        },
      ),
    );
  }
}