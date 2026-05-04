import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key, required this.onPressed, this.isLoading = false});

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _GoogleLogo(),
                      const SizedBox(width: 12),
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: Color(0xFF1A1A2E),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Blue section (top left)
    final bluePath = Path()
      ..moveTo(center.dx - radius * 0.17, center.dy - radius * 0.35)
      ..lineTo(center.dx + radius * 0.05, center.dy - radius * 0.35)
      ..lineTo(center.dx + radius * 0.05, center.dy - radius * 0.05)
      ..lineTo(center.dx - radius * 0.17, center.dy + radius * 0.05)
      ..close();
    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(bluePath, paint);

    // Red section (top right)
    final redPath = Path()
      ..moveTo(center.dx + radius * 0.05, center.dy - radius * 0.35)
      ..lineTo(center.dx + radius * 0.35, center.dy - radius * 0.17)
      ..lineTo(center.dx + radius * 0.35, center.dy + radius * 0.17)
      ..lineTo(center.dx + radius * 0.05, center.dy + radius * 0.05)
      ..close();
    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(redPath, paint);

    // Yellow section (bottom right)
    final yellowPath = Path()
      ..moveTo(center.dx + radius * 0.05, center.dy + radius * 0.05)
      ..lineTo(center.dx + radius * 0.35, center.dy + radius * 0.17)
      ..lineTo(center.dx + radius * 0.17, center.dy + radius * 0.35)
      ..lineTo(center.dx - radius * 0.05, center.dy + radius * 0.35)
      ..close();
    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(yellowPath, paint);

    // Green section (bottom left)
    final greenPath = Path()
      ..moveTo(center.dx - radius * 0.17, center.dy + radius * 0.05)
      ..lineTo(center.dx - radius * 0.05, center.dy + radius * 0.35)
      ..lineTo(center.dx - radius * 0.35, center.dy + radius * 0.17)
      ..lineTo(center.dx - radius * 0.35, center.dy - radius * 0.17)
      ..close();
    paint.color = const Color(0xFF34A853);
    canvas.drawPath(greenPath, paint);

    // White center "G" shape
    paint.color = Colors.white;
    final gPath = Path()
      ..moveTo(center.dx - radius * 0.1, center.dy - radius * 0.2)
      ..lineTo(center.dx + radius * 0.1, center.dy - radius * 0.2)
      ..lineTo(center.dx + radius * 0.1, center.dy - radius * 0.05)
      ..lineTo(center.dx + radius * 0.02, center.dy - radius * 0.05)
      ..lineTo(center.dx + radius * 0.02, center.dy + radius * 0.1)
      ..lineTo(center.dx - radius * 0.1, center.dy + radius * 0.1)
      ..lineTo(center.dx - radius * 0.1, center.dy - radius * 0.05)
      ..close();
    canvas.drawPath(gPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
