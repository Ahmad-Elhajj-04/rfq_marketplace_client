import 'package:flutter/material.dart';
import 'quotations_service.dart';
import 'quotation_submit_page.dart';

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
  List<dynamic> _quotes = [];

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
      final items = await _service.byRequest(widget.requestId);
      setState(() => _quotes = items);
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
        const SnackBar(content: Text("Quotation accepted ✅")),
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Quotations (Request #${widget.requestId})"),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final ok = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => QuotationSubmitPage(requestId: widget.requestId)),
          );
          if (ok == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text("Submit"),
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
          final q = _quotes[i] as Map<String, dynamic>;
          final id = q["id"];
          final total = q["total_price"];
          final days = q["delivery_days"];
          final status = q["status"];

          return ListTile(
            title: Text("Quotation #$id — Total: $total"),
            subtitle: Text("Delivery: $days days | Status: $status"),
            trailing: ElevatedButton(
              onPressed: status == "submitted" || status == "updated"
                  ? () => _accept(id)
                  : null,
              child: const Text("Accept"),
            ),
          );
        },
      ),
    );
  }
}