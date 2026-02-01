import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:rfq_marketplace_flutter/features/auth/data/auth_service.dart';
import 'package:rfq_marketplace_flutter/core/storage/token_store.dart';
import 'package:rfq_marketplace_flutter/shared/session.dart';

class LoginPage extends StatefulWidget {
  final String? expectedRole; // "user" or "company"
  const LoginPage({super.key, this.expectedRole});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email.text = "";
    _password.text = "";
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.expectedRole == "company") return "Company Login";
    return "User Login";
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _auth.login(_email.text, _password.text);

      final token = res["token"] as String;
      final user = res["user"] as Map<String, dynamic>;
      final role = (user["role"] ?? "").toString();

      // Enforce role from landing choice
      if (widget.expectedRole != null && role != widget.expectedRole) {
        setState(() {
          _error = "This account is not a ${widget.expectedRole} account.";
        });
        return;
      }

      // ✅ Save token + session
      await TokenStore.save(token);
      Session.userId = (user["id"] as int);
      Session.role = role;
      Session.name = (user["name"] ?? "").toString();

      if (!mounted) return;

      // ✅ Go back to Landing (root) and clear navigation stack
      Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 18),

                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username],
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
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
                      validator: (v) => (v ?? "").isEmpty ? "Password is required" : null,
                      onEditingComplete: () => TextInput.finishAutofillContext(),
                    ),

                    const SizedBox(height: 10),
                    if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text("Login"),
                      ),
                    ),

                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, "/register", arguments: "user"),
                      child: const Text("Create account"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
