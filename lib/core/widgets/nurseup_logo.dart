import 'package:flutter/material.dart';

/// Renders the NurseUp brand logo from the bundled asset that ships
/// the heart-with-cross mark and the wordmark together. Use [size] to
/// control the height; width scales proportionally.
class NurseUpLogo extends StatelessWidget {
  const NurseUpLogo({
    super.key,
    this.size = 150,
    this.showGlow = false,
    this.showWordmark = true,
  });

  final double size;
  final bool showGlow;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/nurseup_logo.png',
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    if (!showGlow) return image;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2196F3).withValues(alpha: 0.18),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
      child: image,
    );
  }
}

