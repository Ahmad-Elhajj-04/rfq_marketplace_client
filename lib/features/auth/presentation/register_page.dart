import 'package:flutter/material.dart';
import 'package:rfq_marketplace_flutter/features/auth/data/auth_service.dart';
import 'package:rfq_marketplace_flutter/core/storage/token_store.dart';
import 'package:rfq_marketplace_flutter/requests/presentation/requests_page.dart';
import 'package:rfq_marketplace_flutter/requests/presentation/company_requests_page.dart';

class RegisterPage extends StatefulWidget {
  final String role; // "user" or "company"
  const RegisterPage({super.key, required this.role});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _companyName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String? _error;

  bool get isCompany => widget.role == "company";

  @override
  void dispose() {
    _name.dispose();
    _companyName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = isCompany
          ? await _auth.registerCompany(
        _name.text,
        _email.text,
        _password.text,
        _companyName.text,
      )
          : await _auth.registerUser(
        _name.text,
        _email.text,
        _password.text,
      );

      final token = res["token"] as String;
      await TokenStore.save(token);

      final user = res["user"] as Map<String, dynamic>;
      final role = (user["role"] ?? "").toString();

      if (!mounted) return;

      if (role == "company") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompanyRequestsPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RequestsPage()),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = isCompany ? "Company Sign up" : "User Sign up";

    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
                    controller: _name,
                    decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder()),
                    validator: (v) => (v ?? "").trim().isEmpty ? "Name is required" : null,
                  ),
                  const SizedBox(height: 12),

                  if (isCompany) ...[
                    TextFormField(
                      controller: _companyName,
                      decoration: const InputDecoration(labelText: "Company Name", border: OutlineInputBorder()),
                      validator: (v) => (v ?? "").trim().isEmpty ? "Company Name is required" : null,
                    ),
                    const SizedBox(height: 12),
                  ],

                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                    validator: (v) {
                      final x = (v ?? "").trim();
                      if (x.isEmpty) return "Email is required";
                      if (!x.contains("@")) return "Enter a valid email";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                    validator: (v) => (v ?? "").isEmpty ? "Password is required" : null,
                  ),

                  const SizedBox(height: 12),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text("Create account"),
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