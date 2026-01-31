import 'package:flutter/material.dart';
import 'quotations_service.dart';

class QuotationSubmitPage extends StatefulWidget {
  final int requestId;
  const QuotationSubmitPage({super.key, required this.requestId});

  @override
  State<QuotationSubmitPage> createState() => _QuotationSubmitPageState();
}

class _QuotationSubmitPageState extends State<QuotationSubmitPage> {
  final _service = QuotationsService();
  final _formKey = GlobalKey<FormState>();

  final _pricePerUnit = TextEditingController(text: "300");
  final _totalPrice = TextEditingController(text: "600");
  final _deliveryDays = TextEditingController(text: "3");
  final _deliveryCost = TextEditingController(text: "30");
  final _paymentTerms = TextEditingController(text: "Cash on delivery");
  final _notes = TextEditingController(text: "Best quality");

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _pricePerUnit.dispose();
    _totalPrice.dispose();
    _deliveryDays.dispose();
    _deliveryCost.dispose();
    _paymentTerms.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payload = {
        "request_id": widget.requestId,
        "price_per_unit": double.parse(_pricePerUnit.text.trim()),
        "total_price": double.parse(_totalPrice.text.trim()),
        "delivery_days": int.parse(_deliveryDays.text.trim()),
        "delivery_cost": double.parse(_deliveryCost.text.trim()),
        "payment_terms": _paymentTerms.text.trim(),
        "notes": _notes.text.trim(),
        "valid_until": "2026-03-01 12:00:00"
      };

      await _service.submitQuotation(payload);

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quotation submitted ✅")),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Submit Quotation (Request #${widget.requestId})")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _pricePerUnit,
                    decoration: const InputDecoration(labelText: "Price per unit", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => (double.tryParse((v ?? "").trim()) == null) ? "Enter number" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _totalPrice,
                    decoration: const InputDecoration(labelText: "Total price", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => (double.tryParse((v ?? "").trim()) == null) ? "Enter number" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _deliveryDays,
                    decoration: const InputDecoration(labelText: "Delivery days", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => (int.tryParse((v ?? "").trim()) == null) ? "Enter integer" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _deliveryCost,
                    decoration: const InputDecoration(labelText: "Delivery cost", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (v) => (double.tryParse((v ?? "").trim()) == null) ? "Enter number" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _paymentTerms,
                    decoration: const InputDecoration(labelText: "Payment terms", border: OutlineInputBorder()),
                    validator: (v) => (v ?? "").trim().isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notes,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: "Notes", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Submit"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}