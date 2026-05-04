import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class UpgradeModal extends StatelessWidget {
  const UpgradeModal({super.key, required this.onSubscribe, required this.onMaybeLater});

  final VoidCallback onSubscribe;
  final VoidCallback onMaybeLater;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Upgrade to Pro', style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            _buildComparisonRow('Words', '500/wk', '5,000/wk'),
            const Divider(),
            _buildComparisonRow('Reset', 'Weekly', 'Weekly'),
            const Divider(),
            _buildComparisonRow('3D View', '✗', '✓', isProFeature: true),
            const Divider(),
            _buildComparisonRow('PDF Export', '✓', '✓'),
            const Divider(),
            _buildComparisonRow('Priority', '✗', '✓', isProFeature: true),
            const SizedBox(height: AppSpacing.xl),
            AppButton(label: 'Subscribe ₱300/month', icon: Icons.star_rounded, onPressed: onSubscribe),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onMaybeLater, child: const Text('Maybe later')),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(String label, String freeValue, String proValue, {bool isProFeature = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label, style: AppTextStyles.bodyMedium)),
          Expanded(flex: 2, child: Text(freeValue, style: AppTextStyles.bodySmall, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text(proValue, style: AppTextStyles.bodySmall.copyWith(color: isProFeature ? AppColors.primary : null, fontWeight: isProFeature ? FontWeight.bold : null), textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}
