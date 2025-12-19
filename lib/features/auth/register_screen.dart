import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../widgets/auth_background.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import 'auth_api.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String _role = "client";

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final data = await AuthApi.register(
        name: _name.text,
        email: _email.text,
        password: _pass.text,
        role: _role,
      );

      final status = (data["status"] ?? "").toString().toLowerCase();
      final msg = (data["msg"] ?? data["message"] ?? "Done").toString();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

      if (status == "ok" || status == "success") {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: _GlassCard(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Create account",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _name,
                      label: "Name",
                      hint: "Your name",
                      prefixIcon: const Icon(Icons.person_outline),
                      validator: (v) => (v == null || v.trim().length < 2) ? "Name required" : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _email,
                      label: "Email",
                      hint: "you@example.com",
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: (v) => (v == null || !v.contains("@")) ? "Valid email" : null,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _pass,
                      label: "Password",
                      hint: "••••••••",
                      obscureText: _obscure,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? "Min 6 chars" : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _role,
                      items: const [
                        DropdownMenuItem(value: "client", child: Text("Client")),
                        DropdownMenuItem(value: "worker", child: Text("Worker")),
                      ],
                      onChanged: (v) => setState(() => _role = v ?? "client"),
                      decoration: const InputDecoration(labelText: "Role"),
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      text: "Create account",
                      icon: Icons.check_rounded,
                      loading: _loading,
                      onTap: _handleRegister,
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

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.65)),
          ),
          child: child,
        ),
      ),
    );
  }
}
