import 'package:flutter/material.dart';

import 'package:rfq_marketplace_flutter/features/auth/data/auth_service.dart';
import 'package:rfq_marketplace_flutter/core/storage/token_store.dart';
import 'package:rfq_marketplace_flutter/shared/session.dart';

class RegisterPage extends StatefulWidget {
  final String role; // initial role: "user" or "company"
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

  late String _role; // current selected role

  bool get isCompany => _role == "company";

  @override
  void initState() {
    super.initState();
    _role = widget.role; // default from landing/routing
  }

  @override
  void dispose() {
    _name.dispose();
    _companyName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _setRole(String role) {
    setState(() {
      _role = role;
      _error = null;
    });
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
      Session.userId = user["id"] as int;
      Session.role = (user["role"] ?? "").toString();
      Session.name = (user["name"] ?? "").toString();

      if (!mounted) return;

      // ✅ Stay on landing: pop back to root
      Navigator.popUntil(context, (route) => route.isFirst);
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
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.black.withOpacity(0.12)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RoleToggle(
                        role: _role,
                        onUser: () => _setRole("user"),
                        onCompany: () => _setRole("company"),
                      ),
                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: "Name",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                        (v ?? "").trim().isEmpty ? "Name is required" : null,
                      ),
                      const SizedBox(height: 12),

                      if (isCompany) ...[
                        TextFormField(
                          controller: _companyName,
                          decoration: const InputDecoration(
                            labelText: "Company Name",
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                          (v ?? "").trim().isEmpty ? "Company Name is required" : null,
                        ),
                        const SizedBox(height: 12),
                      ],

                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: "Email",
                          border: OutlineInputBorder(),
                        ),
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
                        decoration: const InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                        (v ?? "").isEmpty ? "Password is required" : null,
                      ),

                      const SizedBox(height: 12),
                      if (_error != null)
                        Text(_error!, style: const TextStyle(color: Colors.red)),

                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Text("Create account"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleToggle extends StatelessWidget {
  final String role;
  final VoidCallback onUser;
  final VoidCallback onCompany;

  const _RoleToggle({
    required this.role,
    required this.onUser,
    required this.onCompany,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = role == "user";

    Widget pill(String text, bool active, VoidCallback onTap) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: active ? Colors.black : Colors.transparent,
              border: Border.all(color: Colors.black.withOpacity(0.12)),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text("Sign up as", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            pill("User", isUser, onUser),
            const SizedBox(width: 10),
            pill("Company", !isUser, onCompany),
          ],
        ),
      ],
    );
  }
}
