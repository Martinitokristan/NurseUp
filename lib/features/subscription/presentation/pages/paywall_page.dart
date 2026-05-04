import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/subscription_provider.dart';

class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key});

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansProvider).valueOrNull ?? const {};
    final proPlan = plans['pro'];
    final actionState = ref.watch(subscriptionControllerProvider);

    final price = proPlan?.formattedPrice ?? 'PHP 300';
    final features = proPlan?.features.isNotEmpty == true
        ? proPlan!.features.map(_humanizeFeature).toList()
        : const [
            'Unlimited file uploads',
            'Unlimited AI reviewer generation',
            '3D anatomy viewer',
            'Exploded view and labels',
            'Priority AI processing',
          ];

    ref.listen(subscriptionControllerProvider, (prev, next) {
      if (next.successMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!)),
        );
        context.go(AppRoutes.subscriptionSuccess);
        ref.read(subscriptionControllerProvider.notifier).clearMessages();
      } else if (next.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          const Text('Unlock NurseUp Pro',
              style: AppTextStyles.displayLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                      child:
                          Text(feature, style: AppTextStyles.bodyMedium)),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('$price/month',
              style: AppTextStyles.displayLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: actionState.isLoading
                ? 'Processing…'
                : 'Subscribe - $price/month',
            onPressed: actionState.isLoading ? null : _activatePaidPro,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Pay with GCash',
            outlined: true,
            onPressed: _openGCash,
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: _restorePurchases,
            child: const Text('Restore Purchases'),
          ),
        ],
      ),
    );
  }

  String _humanizeFeature(String key) {
    switch (key) {
      case 'basic_reviewer':
        return 'AI reviewer generation';
      case 'unlimited_uploads':
        return 'Unlimited file uploads';
      case 'unlimited_reviewers':
        return 'Unlimited AI reviewers';
      case 'anatomy_3d':
        return '3D anatomy viewer';
      case 'priority_ai':
        return 'Priority AI processing';
      default:
        return key.replaceAll('_', ' ');
    }
  }

  Future<void> _activatePaidPro() async {
    final ok = await ref
        .read(subscriptionControllerProvider.notifier)
        .activatePaidPro();
    if (!ok && mounted) {
      // Fallback to the local demo override so the classroom demo still works
      // when Firestore is unavailable.
      ref.read(demoSubscriptionOverrideProvider.notifier).state = true;
      context.go(AppRoutes.subscriptionSuccess);
    }
  }

  void _restorePurchases() {
    ref.read(demoSubscriptionOverrideProvider.notifier).state = true;
    context.go(AppRoutes.subscriptionSuccess);
  }

  Future<void> _openGCash() async {
    final gcashUri = Uri.parse('gcash://');
    if (await canLaunchUrl(gcashUri)) {
      await launchUrl(gcashUri);
    } else {
      await launchUrl(Uri.parse(
          'https://play.google.com/store/apps/details?id=com.globe.gcash.android'));
    }
  }
}
