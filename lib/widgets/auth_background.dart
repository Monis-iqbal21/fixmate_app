import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1220), Color(0xFF111827)],
            ),
          ),
        ),
        Positioned(
          top: -120,
          left: -120,
          child: _Glow(color: AppColors.primary.withOpacity(0.22)),
        ),
        Positioned(
          bottom: -130,
          right: -130,
          child: _Glow(color: AppColors.secondary.withOpacity(0.18)),
        ),
        SafeArea(child: child),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  const _Glow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 120, spreadRadius: 40),
        ],
      ),
    );
  }
}
