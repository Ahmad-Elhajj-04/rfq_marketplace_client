import 'package:flutter/material.dart';
import 'requests_service.dart';
import 'quotations_page.dart';

class RequestDetailsPage extends StatefulWidget {
  final Map<String, dynamic> request;
  const RequestDetailsPage({super.key, required this.request});

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  final _service = RequestsService();

  late int _id;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _request;

  @override
  void initState() {
    super.initState();
    _id = (widget.request["id"] as int);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final r = await _service.getRequest(_id);
      setState(() => _request = r);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openQuotations() async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuotationsPage(requestId: _id),
      ),
    );

    //  If quotations page says something changed (accept), reload request
    if (changed == true) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Request #$_id"),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _request == null
          ? const Center(child: Text("Request not found"))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              _request!["title"]?.toString() ?? "Request",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("Status: ${_request!["status"]}"),
            const SizedBox(height: 6),
            Text("City: ${_request!["delivery_city"]}"),
            const SizedBox(height: 6),
            Text("Quantity: ${_request!["quantity"]} ${_request!["unit"]}"),
            const SizedBox(height: 6),
            Text("Budget: ${_request!["budget_min"]} - ${_request!["budget_max"]}"),
            const SizedBox(height: 14),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _openQuotations,
                child: const Text("View Quotations"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}