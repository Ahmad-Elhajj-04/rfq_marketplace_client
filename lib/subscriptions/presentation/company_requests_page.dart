import 'package:flutter/material.dart';
import 'package:rfq_marketplace_flutter/subscriptions/data/subscriptions_service.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  State<SubscriptionsPage> createState() => _SubscriptionsPageState();
}

class _SubscriptionsPageState extends State<SubscriptionsPage> {
  final _svc = SubscriptionsService();

  bool _loading = true;
  String? _error;

  List<dynamic> _categories = [];
  List<dynamic> _subs = [];

  // category_id -> subscription row
  final Map<int, Map<String, dynamic>> _subByCategory = {};

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
      final cats = await _svc.categories();
      final subs = await _svc.mySubscriptions();

      _subByCategory.clear();
      for (final s in subs) {
        final m = s as Map<String, dynamic>;
        final cid = (m["category_id"] as int);
        _subByCategory[cid] = m;
      }

      setState(() {
        _categories = cats;
        _subs = subs;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(int categoryId, bool value) async {
    try {
      if (value == true) {
        final sub = await _svc.subscribe(categoryId);
        _subByCategory[categoryId] = sub;
      } else {
        final existing = _subByCategory[categoryId];
        if (existing != null) {
          await _svc.unsubscribe(existing["id"] as int);
          _subByCategory.remove(categoryId);
        }
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _subByCategory.length;

    return Scaffold(
      appBar: AppBar(
        title: Text("Subscriptions ($selectedCount)"),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.separated(
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final c = _categories[i] as Map<String, dynamic>;
          final id = c["id"] as int;
          final name = (c["name"] ?? "").toString();
          final type = (c["type"] ?? "").toString();

          final isOn = _subByCategory.containsKey(id);

          return ListTile(
            title: Text(name),
            subtitle: Text(type),
            trailing: Switch(
              value: isOn,
              onChanged: (v) => _toggle(id, v),
            ),
          );
        },
      ),
    );
  }
}