import 'package:flutter/material.dart';
import 'package:rfq_marketplace_flutter/quotations/data/quotations_service.dart';

class QuotationSubmitPage extends StatefulWidget {
  final int requestId;
  const QuotationSubmitPage({super.key, required this.requestId});

  @override
  State<QuotationSubmitPage> createState() => _QuotationSubmitPageState();
}

class _QuotationSubmitPageState extends State<QuotationSubmitPage> {
  final _service = QuotationsService();
  final _formKey = GlobalKey<FormState>();
  final _pricePerUnit = TextEditingController();
  final _totalPrice = TextEditingController();
  final _deliveryDays = TextEditingController();
  final _deliveryCost = TextEditingController();
  final _paymentTerms = TextEditingController();
  final _notes = TextEditingController();

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

  double _parseNum(String v) => double.parse(v.trim());

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payload = {
        "request_id": widget.requestId,
        "price_per_unit": _parseNum(_pricePerUnit.text),
        "total_price": _parseNum(_totalPrice.text),
        "delivery_days": int.parse(_deliveryDays.text.trim()),
        "delivery_cost": _parseNum(_deliveryCost.text),
        "payment_terms": _paymentTerms.text.trim(),
        "notes": _notes.text.trim(),
        "valid_until": DateTime.now().add(const Duration(days: 10)).toIso8601String(),
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
      setState(() => _loading = false);
    }
  }

  String? _requiredNumber(String? v) {
    final t = (v ?? "").trim();
    if (t.isEmpty) return "Required";
    final x = double.tryParse(t);
    if (x == null || x < 0) return "Enter a valid number";
    return null;
  }

  String? _requiredInt(String? v) {
    final t = (v ?? "").trim();
    if (t.isEmpty) return "Required";
    final x = int.tryParse(t);
    if (x == null || x < 0) return "Enter a valid number";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Submit Quotation"),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _pricePerUnit,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Price per unit",
                      hintText: "e.g. 300",
                      border: OutlineInputBorder(),
                    ),
                    validator: _requiredNumber,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _totalPrice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Total price",
                      hintText: "e.g. 600",
                      border: OutlineInputBorder(),
                    ),
                    validator: _requiredNumber,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _deliveryDays,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Delivery days",
                      hintText: "e.g. 3",
                      border: OutlineInputBorder(),
                    ),
                    validator: _requiredInt,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _deliveryCost,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Delivery cost",
                      hintText: "e.g. 30",
                      border: OutlineInputBorder(),
                    ),
                    validator: _requiredNumber,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _paymentTerms,
                    decoration: const InputDecoration(
                      labelText: "Payment terms",
                      hintText: "e.g. Cash on delivery",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v ?? "").trim().isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _notes,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: "Notes",
                      hintText: "Any extra details…",
                      border: OutlineInputBorder(),
                    ),
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