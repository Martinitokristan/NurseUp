import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/subscription/presentation/providers/subscription_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../constants/app_spacing.dart';
import '../constants/app_text_styles.dart';
import 'app_loading.dart';

class PaywallGate extends ConsumerWidget {
  const PaywallGate({super.key, required this.child, required this.featureName, this.description});

  final Widget child;
  final String featureName;
  final String? description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = ref.watch(subscriptionProvider);
    if (isActive) return child;
    return GestureDetector(
      onTap: () => context.push(AppRoutes.paywall),
      child: Stack(
        children: [
          IgnorePointer(child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), child: Opacity(opacity: 0.5, child: child))),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.78), borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle), child: const Icon(Icons.lock_rounded, color: Colors.white, size: 28)),
                  const SizedBox(height: 12),
                  Text('Unlock $featureName', style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  Text(description ?? 'Pro · ?300/month', style: AppTextStyles.bodySmall),
                  const SizedBox(height: 16),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: ElevatedButton(onPressed: () => context.push(AppRoutes.paywall), child: const Text('Upgrade to Pro'))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaywallGateLoading extends StatelessWidget {
  const PaywallGateLoading({super.key});

  @override
  Widget build(BuildContext context) => const AppLoading();
}

