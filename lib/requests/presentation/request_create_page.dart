import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rfq_marketplace_flutter/requests/data/requests_service.dart';

class RequestCreatePage extends StatefulWidget {
  const RequestCreatePage({super.key});

  @override
  State<RequestCreatePage> createState() => _RequestCreatePageState();
}

class _RequestCreatePageState extends State<RequestCreatePage> {
  final _service = RequestsService();
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _qty = TextEditingController(text: "1");
  final _city = TextEditingController(text: "Beirut");

  //  new budget controllers
  final _budgetMin = TextEditingController();
  final _budgetMax = TextEditingController();

  int _categoryId = 1;
  String _unit = "ton";

  //  dates
  DateTime? _requiredDeliveryDate;
  DateTime? _expiresAt;

  bool _loading = false;
  String? _error;

  final _df = DateFormat("yyyy-MM-dd");
  final _dfDateTime = DateFormat("yyyy-MM-dd HH:mm:ss");

  @override
  void initState() {
    super.initState();
    // Defaults: delivery date +7 days, expires +10 days
    final now = DateTime.now();
    _requiredDeliveryDate = now.add(const Duration(days: 7));
    _expiresAt = now.add(const Duration(days: 10));
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _qty.dispose();
    _city.dispose();
    _budgetMin.dispose();
    _budgetMax.dispose();
    super.dispose();
  }

  Future<void> _pickRequiredDeliveryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _requiredDeliveryDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _requiredDeliveryDate = picked);
    }
  }

  Future<void> _pickExpiresAt() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      // Set time to noon for consistency
      final dt = DateTime(picked.year, picked.month, picked.day, 12, 0, 0);
      setState(() => _expiresAt = dt);
    }
  }

  double? _parseOptionalDouble(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final qty = double.parse(_qty.text.trim());

      final budgetMin = _parseOptionalDouble(_budgetMin.text);
      final budgetMax = _parseOptionalDouble(_budgetMax.text);

      // Extra safety check (even though validator handles it)
      if (budgetMin != null && budgetMax != null && budgetMax < budgetMin) {
        throw Exception("Budget max must be greater than or equal to budget min.");
      }

      final deliveryDate = _requiredDeliveryDate;
      final expiresAt = _expiresAt;

      if (deliveryDate == null) throw Exception("Required delivery date is missing.");
      if (expiresAt == null) throw Exception("Expiration date is missing.");

      final payload = {
        "category_id": _categoryId,
        "title": _title.text.trim(),
        "description": _desc.text.trim(),
        "quantity": qty,
        "unit": _unit,
        "delivery_city": _city.text.trim(),

        // real values
        "required_delivery_date": _df.format(deliveryDate),
        "budget_min": budgetMin,
        "budget_max": budgetMax,
        "expires_at": _dfDateTime.format(expiresAt),
      };

      await _service.createRequest(payload);

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request created ✅")),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requiredDeliveryText = _requiredDeliveryDate == null
        ? "Select date"
        : _df.format(_requiredDeliveryDate!);

    final expiresText = _expiresAt == null
        ? "Select date"
        : _df.format(_expiresAt!);

    return Scaffold(
      appBar: AppBar(title: const Text("Create Request")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder()),
                    validator: (v) => (v ?? "").trim().isEmpty ? "Title required" : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _desc,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                    validator: (v) => (v ?? "").trim().isEmpty ? "Description required" : null,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qty,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Quantity", border: OutlineInputBorder()),
                          validator: (v) {
                            final t = (v ?? "").trim();
                            if (t.isEmpty) return "Qty required";
                            final x = double.tryParse(t);
                            if (x == null || x <= 0) return "Enter valid number";
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _unit,
                          items: const [
                            DropdownMenuItem(value: "ton", child: Text("ton")),
                            DropdownMenuItem(value: "kg", child: Text("kg")),
                            DropdownMenuItem(value: "piece", child: Text("piece")),
                            DropdownMenuItem(value: "meter", child: Text("meter")),
                            DropdownMenuItem(value: "other", child: Text("other")),
                          ],
                          onChanged: (v) => setState(() => _unit = v ?? "ton"),
                          decoration: const InputDecoration(labelText: "Unit", border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _city,
                    decoration: const InputDecoration(labelText: "Delivery City", border: OutlineInputBorder()),
                    validator: (v) => (v ?? "").trim().isEmpty ? "City required" : null,
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    value: _categoryId,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text("Iron")),
                      DropdownMenuItem(value: 2, child: Text("Cement")),
                      DropdownMenuItem(value: 3, child: Text("Electrical Services")),
                      DropdownMenuItem(value: 4, child: Text("Logistics")),
                      DropdownMenuItem(value: 5, child: Text("Plumbing")),
                    ],
                    onChanged: (v) => setState(() => _categoryId = v ?? 1),
                    decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),

                  // ✅ Dates
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickRequiredDeliveryDate,
                          child: Text("Delivery date: $requiredDeliveryText"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _pickExpiresAt,
                          child: Text("Expires at: $expiresText"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ✅ Budget inputs (optional)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _budgetMin,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Budget Min (optional)", border: OutlineInputBorder()),
                          validator: (v) {
                            final t = (v ?? "").trim();
                            if (t.isEmpty) return null;
                            final x = double.tryParse(t);
                            if (x == null || x < 0) return "Invalid";
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _budgetMax,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: "Budget Max (optional)", border: OutlineInputBorder()),
                          validator: (v) {
                            final t = (v ?? "").trim();
                            if (t.isEmpty) return null;
                            final x = double.tryParse(t);
                            if (x == null || x < 0) return "Invalid";

                            final minVal = _parseOptionalDouble(_budgetMin.text);
                            if (minVal != null && x < minVal) {
                              return "Must be ≥ min";
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Create"),
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