import 'package:flutter/material.dart';
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

  int _categoryId = 1;
  String _unit = "ton";

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _qty.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final qty = double.parse(_qty.text.trim());
      final payload = {
        "category_id": _categoryId,
        "title": _title.text.trim(),
        "description": _desc.text.trim(),
        "quantity": qty,
        "unit": _unit,
        "delivery_city": _city.text.trim(),
        "required_delivery_date": "2026-02-20",
        "budget_min": 100,
        "budget_max": 500,
        "expires_at": "2026-03-01 12:00:00",
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
                    ],
                    onChanged: (v) => setState(() => _categoryId = v ?? 1),
                    decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
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