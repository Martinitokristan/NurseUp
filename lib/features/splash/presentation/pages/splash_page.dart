import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/nurseup_logo.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Splash / loading screen — a single centered NurseUp logo on a soft
/// blue backdrop with a subtle expanding ripple (matching the four
/// splash variants in Figma where the ellipse grows). After ~1.6s the
/// user is routed to Get Started, or Home if already authenticated.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _routed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), _route);
  }

  void _route() {
    if (!mounted || _routed) return;
    _routed = true;
    final authed = ref.read(authStateProvider).valueOrNull != null;
    GoRouter.of(context).go(authed ? AppRoutes.home : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    // Figma splash4: soft blue background (#D6ECFF)
    return Scaffold(
      backgroundColor: const Color(0xFFD6ECFF),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Figma: dark blue circle matching splash design
            Container(
              width: 294,
              height: 294,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1565C0).withValues(alpha: 0.35),
                border: Border.all(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.5),
                  width: 2.5,
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1.4, 1.4),
                  duration: 1400.ms,
                  curve: Curves.easeOut,
                )
                .fadeOut(duration: 1400.ms),
            // Figma: logo 280x253, zoom-in animation
            SizedBox(
              width: 280,
              height: 253,
              child: const NurseUpLogo(size: 253),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1, 1),
                  duration: 800.ms,
                  curve: Curves.easeOutBack,
                  delay: 400.ms,
                ),
          ],
        ),
      ),
    );
  }
}
