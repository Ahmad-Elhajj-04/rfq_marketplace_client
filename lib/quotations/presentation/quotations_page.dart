import 'package:flutter/material.dart';
import 'package:rfq_marketplace_flutter/quotations/data/quotations_service.dart';
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
  bool _forbidden = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _forbidden = false;
    });

    try {
      final items = await _service.byRequest(widget.requestId);
      setState(() => _quotes = items);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains("Forbidden") || msg.contains("403")) {
        setState(() => _forbidden = true);
      } else {
        setState(() => _error = msg);
      }
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

      // ✅ Tell previous page to refresh request status
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: $e")),
      );
    }
  }

  Future<void> _openSubmit() async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuotationSubmitPage(requestId: widget.requestId)),
    );
    if (ok == true) _load();
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
        onPressed: _openSubmit,
        icon: const Icon(Icons.add),
        label: const Text("Submit"),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _forbidden
          ? Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 44),
                const SizedBox(height: 10),
                const Text(
                  "You can’t view all quotations for this request.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "As a company, you can submit your own quotation.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _openSubmit,
                    child: const Text("Submit Quotation"),
                  ),
                )
              ],
            ),
          ),
        ),
      )
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

          final canAccept = (status == "submitted" || status == "updated");

          return ListTile(
            title: Text("Quotation #$id — Total: $total"),
            subtitle: Text("Delivery: $days days | Status: $status"),
            trailing: ElevatedButton(
              onPressed: canAccept ? () => _accept(id) : null,
              child: const Text("Accept"),
            ),
          );
        },
      ),
    );
  }
}