import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rfq_marketplace_flutter/core/network/api_client.dart';
import 'package:rfq_marketplace_flutter/requests/data/requests_service.dart';

class RequestCreatePage extends StatefulWidget {
  const RequestCreatePage({super.key});

  @override
  State<RequestCreatePage> createState() => _RequestCreatePageState();
}

class _RequestCreatePageState extends State<RequestCreatePage> {
  final _service = RequestsService();
  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _qty = TextEditingController(text: "1"); // used only for material
  final _city = TextEditingController(); // ✅ no default

  final _budgetMin = TextEditingController();
  final _budgetMax = TextEditingController();

  // Categories loaded from backend
  bool _catsLoading = true;
  List<Map<String, dynamic>> _categories = [];

  int? _categoryId;
  String _categoryType = "material"; // material | service (derived)
  String _unit = "ton";

  DateTime? _requiredDeliveryDate; // required
  DateTime? _expiresAt; // required

  bool _showOptional = false;

  bool _loading = false;
  String? _error;

  final _df = DateFormat("yyyy-MM-dd");
  final _dfDateTime = DateFormat("yyyy-MM-dd HH:mm:ss");

  // fallback if backend doesn't send type
  static const Map<int, String> _fallbackTypeById = {
    1: "material", // Iron
    2: "material", // Cement
    3: "service",  // Electrical
    4: "service",  // Logistics
    5: "service",  // Plumbing
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
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

  Future<void> _loadCategories() async {
    setState(() => _catsLoading = true);

    try {
      final res = await _api.get("/v1/categories");
      final list = (res["categories"] as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      setState(() {
        _categories = list;
        _catsLoading = false;
      });

      // default select first category if exists
      if (_categories.isNotEmpty) {
        _setCategory(_categories.first["id"] as int);
      }
    } catch (e) {
      setState(() {
        _catsLoading = false;
        _error = "Failed to load categories: $e";
      });
    }
  }

  void _setCategory(int id) {
    final cat = _categories.firstWhere(
          (c) => (c["id"] as int) == id,
      orElse: () => {"id": id},
    );

    final backendType = cat["type"]?.toString();
    final type = backendType ?? (_fallbackTypeById[id] ?? "material");

    setState(() {
      _categoryId = id;
      _categoryType = type;

      // If service: enforce service unit + quantity 1
      if (_categoryType == "service") {
        _unit = "service";
        _qty.text = "1";
      } else {
        if (_unit == "service") _unit = "ton";
      }
    });
  }

  bool get _isMaterial => _categoryType == "material";
  bool get _isService => _categoryType == "service";

  double? _parseOptionalDouble(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  Future<void> _pickRequiredDeliveryDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _requiredDeliveryDate ?? today,
      firstDate: today, // ✅ today forward
      lastDate: today.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _requiredDeliveryDate = picked);
    }
  }

  Future<void> _pickExpiresAt() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? today.add(const Duration(days: 7)),
      firstDate: today, // ✅ today forward
      lastDate: today.add(const Duration(days: 365)),
    );

    if (picked != null) {
      // keep consistent noon time
      setState(() => _expiresAt = DateTime(picked.year, picked.month, picked.day, 12, 0, 0));
    }
  }

  String? _validateQty(String? v) {
    if (!_isMaterial) return null; // service ignores qty
    final t = (v ?? "").trim();
    if (t.isEmpty) return "Quantity required";
    final x = double.tryParse(t);
    if (x == null || x <= 0) return "Enter a valid number";
    return null;
  }

  String? _validateBudgetMax(String? v) {
    if (!_showOptional) return null;

    final maxVal = _parseOptionalDouble(v ?? "");
    if ((v ?? "").trim().isNotEmpty && maxVal == null) return "Invalid number";
    if (maxVal != null && maxVal < 0) return "Must be ≥ 0";

    final minVal = _parseOptionalDouble(_budgetMin.text);
    if (minVal != null && maxVal != null && maxVal < minVal) return "Max ≥ Min";
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoryId == null) {
      setState(() => _error = "Please select a category.");
      return;
    }

    // Required dates validation
    final now = DateTime.now();
    if (_requiredDeliveryDate == null) {
      setState(() => _error = "Required delivery date is required.");
      return;
    }
    if (_expiresAt == null) {
      setState(() => _error = "Expiration date is required.");
      return;
    }
    if (_expiresAt!.isBefore(now)) {
      setState(() => _error = "Expiration date must be in the future.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final qty = _isService ? 1.0 : double.parse(_qty.text.trim());
      final unit = _isService ? "service" : _unit;

      final budgetMin = _showOptional ? _parseOptionalDouble(_budgetMin.text) : null;
      final budgetMax = _showOptional ? _parseOptionalDouble(_budgetMax.text) : null;

      final payload = {
        "category_id": _categoryId,
        "title": _title.text.trim(),
        "description": _desc.text.trim(),
        "quantity": qty,
        "unit": unit,
        "delivery_city": _city.text.trim(),
        "required_delivery_date": _df.format(_requiredDeliveryDate!),

        // Optional
        "budget_min": budgetMin,
        "budget_max": budgetMax,
        "expires_at": _dfDateTime.format(_expiresAt!),
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
    final deliveryText = _requiredDeliveryDate == null ? "Pick delivery date" : _df.format(_requiredDeliveryDate!);
    final expiresText = _expiresAt == null ? "Pick expiration date" : _df.format(_expiresAt!);

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
                    validator: (v) => (v ?? "").trim().isEmpty ? "Title is required" : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _desc,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                    validator: (v) => (v ?? "").trim().isEmpty ? "Description is required" : null,
                  ),
                  const SizedBox(height: 12),

                  // Category first (so we can switch service/material behavior)
                  _catsLoading
                      ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()))
                      : DropdownButtonFormField<int>(
                    value: _categoryId,
                    items: _categories
                        .map((c) => DropdownMenuItem<int>(
                      value: c["id"] as int,
                      child: Text((c["name"] ?? "").toString()),
                    ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) _setCategory(v);
                    },
                    decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                    validator: (v) => v == null ? "Category is required" : null,
                  ),
                  const SizedBox(height: 12),

                  // Material only: Quantity + Unit
                  if (_isMaterial) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _qty,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Quantity", border: OutlineInputBorder()),
                            validator: _validateQty,
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
                  ],

                  // Service only: show hint (no kg/ton)
                  if (_isService) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Text(
                        "Service request: quantity and unit are not required.",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextFormField(
                    controller: _city,
                    decoration: const InputDecoration(labelText: "Delivery City", border: OutlineInputBorder()),
                    validator: (v) => (v ?? "").trim().isEmpty ? "Delivery city is required" : null,
                  ),
                  const SizedBox(height: 12),

                  // Required dates
                  OutlinedButton(
                    onPressed: _pickRequiredDeliveryDate,
                    child: Text("Delivery date: $deliveryText"),
                  ),
                  const SizedBox(height: 10),

                  OutlinedButton(
                    onPressed: _pickExpiresAt,
                    child: Text("Expires at: $expiresText"),
                  ),
                  const SizedBox(height: 14),

                  // Optional details collapsible
                  InkWell(
                    onTap: () => setState(() => _showOptional = !_showOptional),
                    child: Row(
                      children: [
                        Icon(_showOptional ? Icons.expand_less : Icons.expand_more),
                        const SizedBox(width: 6),
                        const Text("Optional details", style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 180),
                    crossFadeState: _showOptional ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                    firstChild: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _budgetMin,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: "Budget Min", border: OutlineInputBorder()),
                              validator: (v) {
                                if (!_showOptional) return null;
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
                              decoration: const InputDecoration(labelText: "Budget Max", border: OutlineInputBorder()),
                              validator: _validateBudgetMax,
                            ),
                          ),
                        ],
                      ),
                    ),
                    secondChild: const SizedBox.shrink(),
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