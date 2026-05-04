import 'package:flutter/material.dart';

/// Soft sky-blue background with two large pastel circles bleeding off
/// the top-left and bottom-right corners. Matches the Figma auth flow.
class AuthBackground extends StatelessWidget {
  const AuthBackground({
    super.key,
    required this.child,
    this.showPerson = false,
  });

  final Widget child;
  final bool showPerson;

  static const Color _bgColor = Color(0xFFD2E9FD);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bgColor,
      child: Stack(
        children: [
          Positioned(
            left: -112,
            top: -97,
            child: const _GradientCircle(size: 364),
          ),
          Positioned(
            right: -57, // 402 - (307 + 364) = -269 from left maps to right offset
            top: 525,
            child: const _GradientCircle(size: 364),
          ),
          if (showPerson)
            Positioned.fill(
              child: Opacity(
                opacity: 0.8,
                child: Image.asset(
                  'assets/images/person.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _GradientCircle extends StatelessWidget {
  const _GradientCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment(-0.2, -0.2),
            radius: 0.85,
            colors: [
              Color(0xFFE9E1FB),
              Color(0xFFB8C9F6),
              Color(0xFF7E8EE0),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}
