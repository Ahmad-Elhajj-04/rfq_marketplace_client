import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'token_store.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _companyName = TextEditingController();

  bool _isCompany = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _companyName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = _isCompany
          ? await _auth.registerCompany(_name.text, _email.text, _password.text, _companyName.text)
          : await _auth.registerUser(_name.text, _email.text, _password.text);

      final token = res["token"] as String;
      await TokenStore.save(token);

      if (!mounted) return;
      Navigator.popUntil(context, (r) => r.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created and logged in")),
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
      appBar: AppBar(title: const Text("Register")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text("Register as Company"),
                    value: _isCompany,
                    onChanged: (v) => setState(() => _isCompany = v),
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: "Name", border: OutlineInputBorder()),
                    validator: (v) => (v ?? "").trim().isEmpty ? "Name is required" : null,
                  ),
                  const SizedBox(height: 12),

                  if (_isCompany) ...[
                    TextFormField(
                      controller: _companyName,
                      decoration: const InputDecoration(labelText: "Company Name", border: OutlineInputBorder()),
                      validator: (v) => (v ?? "").trim().isEmpty ? "Company name is required" : null,
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

                  const SizedBox(height: 10),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),

                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
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