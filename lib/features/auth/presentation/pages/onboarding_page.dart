import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';

import '../../../../core/widgets/nurseup_logo.dart';

/// "Get Started" onboarding screen built to the Figma design
/// (frame `iPhone 17 - 7`, node `14:668`). Headline at the top,
/// two slightly tilted feature cards in the middle, and a pill
/// "Get Started" button at the bottom.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/getstarted_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                _Headline()
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.15, end: 0, duration: 500.ms, curve: Curves.easeOut),
                const SizedBox(height: 20),
                Expanded(
                  child: Align(
                    alignment: const Alignment(0, 0.55),
                    child: _FeatureCardsStack(width: size.width - 48)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms),
                  ),
                ),
                _GetStartedButton(
                  onTap: () => context.go(AppRoutes.login),
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.login),
                    child: const Text(
                      'I already have an account',
                      style: TextStyle(
                        color: Color(0xFF55A8C9),
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              'Elevate Your Nursing Studies with AI',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 28,
                height: 1.15,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(width: 6),
          Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.auto_awesome, color: Color(0xFF1A1A2E), size: 28),
          ),
        ],
      ),
    );
  }
}

class _FeatureCardsStack extends StatelessWidget {
  const _FeatureCardsStack({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: width,
        height: 320,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 60,
              child: Transform.rotate(
                angle: -10 * 3.1415926 / 180,
                child: _FeatureCard(
                  width: 256,
                  background: Colors.white,
                  textColor: Colors.black,
                  title: 'Personalized\nAI Tutoring',
                  body: 'Targeted study sessions and\ninstantly answered questions on\nnursing concepts.',
                  trailingLogo: true,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Transform.rotate(
                angle: -10 * 3.1415926 / 180,
                child: _FeatureCard(
                  width: 256,
                  background: const Color(0xFF579EE5),
                  textColor: Colors.white,
                  title: 'Visualize Complex\nAnatomy',
                  body: 'AI-powered, interactive 3D\nvisualization of physiological\nsystems for deeper learning.',
                  trailingIcon: Icons.psychology_outlined,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.width,
    required this.background,
    required this.textColor,
    required this.title,
    required this.body,
    this.trailingLogo = false,
    this.trailingIcon,
  });

  final double width;
  final Color background;
  final Color textColor;
  final String title;
  final String body;
  final bool trailingLogo;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    height: 1.25,
                    color: textColor,
                  ),
                ),
              ),
              if (trailingLogo)
                NurseUpLogo(size: 36, showWordmark: false)
              else if (trailingIcon != null)
                Icon(trailingIcon, color: textColor, size: 32),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w300,
              fontSize: 13,
              height: 1.35,
              color: textColor.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE2F0FF),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 15,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(left: 40),
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF050505),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF4EA0FD),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_outward, color: Colors.white, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
