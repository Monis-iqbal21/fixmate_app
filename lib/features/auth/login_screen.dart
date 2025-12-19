import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_colors.dart';
import '../../core/storage.dart';
import '../../widgets/auth_background.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../shell/app_shell.dart';
import 'auth_api.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  String _token(Map<String, dynamic> data) {
    final t = (data["token"] ?? data["access_token"] ?? "").toString();
    if (t.isNotEmpty) return t;
    if (data["data"] is Map) {
      final m = Map<String, dynamic>.from(data["data"]);
      return (m["token"] ?? m["access_token"] ?? "").toString();
    }
    return "";
  }

  int _userId(Map<String, dynamic> data) {
    if (data["user"] is Map) {
      final u = Map<String, dynamic>.from(data["user"]);
      return int.tryParse((u["id"] ?? "0").toString()) ?? 0;
    }
    return 0;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final data = await AuthApi.login(email: _email.text, password: _pass.text);
      final status = (data["status"] ?? "").toString().toLowerCase();

      if (status != "ok" && status != "success") {
        final msg = (data["msg"] ?? data["message"] ?? "Login failed").toString();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        return;
      }

      final token = _token(data);
      if (token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Token not received from API")),
        );
        return;
      }

      await AppStorage.saveToken(token);

      final uid = _userId(data);
      if (uid > 0) await AppStorage.saveUserId(uid);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final maxWidth = w > 520 ? 520.0 : w;

    return Scaffold(
      body: AuthBackground(
        child: Center(
          child: SizedBox(
            width: maxWidth,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BrandHeader(),
                  const SizedBox(height: 16),
                  _GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text("Welcome back",
                              style: GoogleFonts.poppins(
                                  fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                          const SizedBox(height: 6),
                          Text("Login to continue to FixMate",
                              style: GoogleFonts.poppins(fontSize: 13.5, color: AppColors.textLight)),
                          const SizedBox(height: 16),

                          AppTextField(
                            controller: _email,
                            label: "Email",
                            hint: "you@example.com",
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined),
                            validator: (v) {
                              if (v == null || !v.contains("@")) return "Valid email likho";
                              return null;
                            },
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
                            validator: (v) {
                              if (v == null || v.length < 6) return "Min 6 characters";
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),
                          PrimaryButton(
                            text: "Login",
                            icon: Icons.arrow_forward_rounded,
                            loading: _loading,
                            onTap: _handleLogin,
                          ),

                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.black.withOpacity(0.08))),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text("or", style: TextStyle(color: AppColors.textLight)),
                              ),
                              Expanded(child: Divider(color: Colors.black.withOpacity(0.08))),
                            ],
                          ),
                          const SizedBox(height: 10),

                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: const BorderSide(color: AppColors.border),
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            child: const Text("Create new account",
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
                          ),

                          const SizedBox(height: 10),
                          Text(
                            "By continuing, you agree to our Terms & Privacy.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text("Tip: Same WiFi pe ho to API fast chalegi ✅",
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.white60)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
          ),
          child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 12),
        Text("FixMate",
            style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 4),
        Text("Book trusted services in minutes", style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
      ],
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
