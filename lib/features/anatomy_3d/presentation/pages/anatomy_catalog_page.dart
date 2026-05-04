import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../../core/widgets/app_gradient_card.dart';
import '../../../../core/widgets/paywall_gate.dart';
import '../../domain/entities/anatomy_model_entity.dart';
import '../providers/anatomy_provider.dart';

class AnatomyCatalogPage extends ConsumerWidget {
  const AnatomyCatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(anatomyModelsProvider);
    final categories = models.map((m) => m.category).where((c) => c != null).toSet().toList()..sort();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F1B2D);
    final bodyColor = isDark ? Colors.white70 : AppColors.textSecondary;
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF0B0F1A), Color(0xFF111A2E)]
                : const [Colors.white, Color(0xFFF4FBFF)],
          ),
        ),
        child: SafeArea(
          child: PaywallGate(
            featureName: '3D Anatomy',
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 110),
              children: [
                Text('3D Anatomy', style: AppTextStyles.displayLarge.copyWith(color: titleColor)),
                const SizedBox(height: 8),
                Text('Explore real GLB anatomy models with labels and study notes.', style: AppTextStyles.bodySmall.copyWith(color: bodyColor)),
                const SizedBox(height: AppSpacing.xl),
                if (models.isEmpty)
                  const _EmptyState()
                else
                  ...categories.map((category) => _CategorySection(category: category!, models: models.where((m) => m.category == category).toList())),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(index: 2),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.category, required this.models});

  final String category;
  final List<AnatomyModelEntity> models;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.category_rounded, color: AppColors.primary, size: 20), const SizedBox(width: AppSpacing.sm), Text(category, style: AppTextStyles.h3)]),
      const SizedBox(height: AppSpacing.md),
      GridView.builder(
        itemCount: models.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.88),
        itemBuilder: (context, index) {
          final model = models[index];
          return AppGradientCard(
            onTap: () => context.push('${AppRoutes.anatomyViewer}?modelId=${model.id}'),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Center(child: Container(width: 76, height: 76, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(anatomyIcon(model), size: 42, color: AppColors.primary)))),
              Text(model.name, style: AppTextStyles.h3),
              const SizedBox(height: 4),
              Text('${model.parts} parts', style: AppTextStyles.caption),
            ]),
          );
        },
      ),
      const SizedBox(height: AppSpacing.xl),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A2233) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F1B2D);
    final bodyColor = isDark ? Colors.white70 : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: isDark ? 0.55 : 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open, size: 64, color: AppColors.primary.withValues(alpha: isDark ? 0.85 : 0.3)),
          const SizedBox(height: 16),
          Text('No Anatomy Models Available', style: AppTextStyles.h3.copyWith(color: titleColor), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Upload study files with anatomy topics to unlock 3D models.', style: AppTextStyles.bodySmall.copyWith(color: bodyColor), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('For example: "Brain Anatomy Notes", "Cardiovascular System", "Respiratory Physiology"', style: AppTextStyles.caption.copyWith(color: AppColors.primary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
