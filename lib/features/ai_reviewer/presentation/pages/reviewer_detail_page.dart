import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../anatomy_3d/domain/entities/anatomy_model_entity.dart';
import '../../../anatomy_3d/presentation/providers/anatomy_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../data/services/reviewer_pdf_export_service.dart';
import '../providers/reviewer_provider.dart';

class ReviewerDetailPage extends ConsumerStatefulWidget {
  const ReviewerDetailPage({super.key, this.reviewerId, this.showExportOnOpen = false});

  final String? reviewerId;
  final bool showExportOnOpen;

  @override
  ConsumerState<ReviewerDetailPage> createState() => _ReviewerDetailPageState();
}

class _ReviewerDetailPageState extends ConsumerState<ReviewerDetailPage> {
  final _exportService = const ReviewerPdfExportService();
  bool _shownInitialExportSheet = false;
  bool _isExporting = false;

  void _leaveReviewer(BuildContext context, {required bool openedAfterGenerate}) {
    if (openedAfterGenerate) {
      context.go(AppRoutes.home);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final params = GoRouterState.of(context).uri.queryParameters;
    final reviewerId = widget.reviewerId ?? params['id'] ?? '';
    final openedAfterGenerate = params['from'] == 'generate';
    final reviewerAsync = ref.watch(reviewerDocumentProvider(reviewerId));
    final isPro = ref.watch(subscriptionProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leaveReviewer(context, openedAfterGenerate: openedAfterGenerate);
      },
      child: reviewerAsync.when(
      data: (data) {
        final anatomyModelId = data?['anatomyModelId'] as String?;
        final anatomyModel = anatomyModelById(anatomyModelId);
        final reviewer = ReviewerPdfData.fromFirestore(data ?? _demoDetailData);

        if (!reviewer.hasContent) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => _leaveReviewer(context, openedAfterGenerate: openedAfterGenerate)),
              title: Text(reviewer.title),
            ),
            body: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    ),
                    child: const Text(
                      'The reviewer was created, but no study sections were found. Please try regenerating with a clearer file or photo.',
                      style: AppTextStyles.body,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton(
                    onPressed: () => context.go(AppRoutes.upload),
                    child: const Text('Upload another file'),
                  ),
                ],
              ),
            ),
          );
        }

        if (widget.showExportOnOpen && !_shownInitialExportSheet) {
          _shownInitialExportSheet = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showExportSheet(reviewer);
          });
        }
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => _leaveReviewer(context, openedAfterGenerate: openedAfterGenerate)),
            title: Text(reviewer.title),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.10)),
                ),
                child: Text(reviewer.overview, style: AppTextStyles.body, softWrap: true),
              ),
              if (anatomyModel != null) ...[const SizedBox(height: AppSpacing.md), _anatomyModelCard(context, model: anatomyModel, isPro: isPro)],
              const SizedBox(height: AppSpacing.xl),
              ...reviewer.sections.map(
                (section) => Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.heading, style: AppTextStyles.h3, maxLines: 3, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: AppSpacing.sm),
                        ...section.bullets.map(
                          (bullet) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('•  ', style: AppTextStyles.body),
                                Expanded(child: Text(bullet, style: AppTextStyles.body, softWrap: true)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (reviewer.keyTerms.isNotEmpty)
                Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Key Terms', style: AppTextStyles.h3),
                        const SizedBox(height: AppSpacing.sm),
                        ...reviewer.keyTerms.map(
                          (t) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('• ${t.term}: ${t.definition}', style: AppTextStyles.body),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (reviewer.mustRemember.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: AppColors.tipBackground, border: Border.all(color: AppColors.tipBorder), borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Must Remember', style: AppTextStyles.h3.copyWith(color: AppColors.primary)),
                      const SizedBox(height: 8),
                      Text(reviewer.mustRemember.map((item) => '• $item').join('\n'), style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
              if (reviewer.practiceQuestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: AppColors.tipBackground, border: Border.all(color: AppColors.tipBorder), borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                  child: Text('Practice Questions:\n${reviewer.practiceQuestions.map((item) => '- ${item.question}\n  Answer: ${item.answer}').join('\n')}', style: AppTextStyles.bodyMedium),
                ),
              if (reviewer.flashcards.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: AppSpacing.lg),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: Colors.orange.shade50, border: Border.all(color: Colors.orange.shade200), borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Flashcards (${reviewer.flashcards.length})', style: AppTextStyles.h3.copyWith(color: Colors.orange.shade800)),
                      const SizedBox(height: 8),
                      Text(reviewer.flashcards.take(5).map((c) => 'Q: ${c.front}\nA: ${c.back}').join('\n\n'), style: AppTextStyles.bodyMedium),
                      if (reviewer.flashcards.length > 5) Text('\n+ ${reviewer.flashcards.length - 5} more flashcards saved', style: AppTextStyles.caption),
                    ],
                  ),
                ),
            ],
          ),
          bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: AppButton(label: _isExporting ? 'Exporting...' : 'Export PDF', icon: Icons.file_download_rounded, onPressed: _isExporting ? null : () => _showExportSheet(reviewer)))),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const Scaffold(body: Center(child: Text('Unable to load reviewer.'))),
    ),
  );
  }

  Widget _anatomyModelCard(BuildContext context, {required AnatomyModelEntity model, required bool isPro}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
            child: Icon(anatomyIcon(model), color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${model.name} 3D Model', style: AppTextStyles.h3, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Detected from this reviewer', style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonalIcon(
            onPressed: () {
              if (isPro) {
                context.push('${AppRoutes.anatomyViewer}?modelId=${model.id}');
              } else {
                context.push(AppRoutes.paywall);
              }
            },
            icon: Icon(isPro ? Icons.view_in_ar_rounded : Icons.lock_rounded, size: 18),
            label: Text(isPro ? 'Open' : 'Pro'),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportSheet(ReviewerPdfData reviewer) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Export PDF', style: AppTextStyles.h2),
              const SizedBox(height: AppSpacing.md),
              ListTile(leading: const Icon(Icons.preview_rounded, color: AppColors.primary), title: const Text('Preview PDF'), subtitle: const Text('Open the formatted PDF'), onTap: () async { Navigator.pop(sheetContext); await _preview(reviewer); }),
              ListTile(leading: const Icon(Icons.file_download_rounded, color: AppColors.primary), title: const Text('Download PDF'), subtitle: const Text('Save to Downloads folder'), onTap: () async { Navigator.pop(sheetContext); await _download(reviewer); }),
              ListTile(leading: const Icon(Icons.ios_share_rounded, color: AppColors.primary), title: const Text('Share PDF'), subtitle: const Text('WhatsApp, Messenger, Gmail, and more'), onTap: () async { Navigator.pop(sheetContext); await _share(reviewer); }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _download(ReviewerPdfData reviewer) async {
    setState(() => _isExporting = true);
    try {
      final file = await _exportService.saveToDownloads(reviewer);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Reviewer saved to Downloads!'), action: SnackBarAction(label: 'Open', onPressed: () => _open(file))));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _preview(ReviewerPdfData reviewer) async {
    setState(() => _isExporting = true);
    try {
      final file = await _exportService.saveToDownloads(reviewer);
      await _open(file);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _share(ReviewerPdfData reviewer) async {
    setState(() => _isExporting = true);
    try {
      await _exportService.share(reviewer);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _open(File file) async {
    await _exportService.open(file);
  }
}

const _demoDetailData = {
  'title': 'Brain Anatomy Reviewer',
  'overview': 'This reviewer summarizes key concepts from the uploaded nursing lesson with exam-focused recall points.',
  'fileName': 'brain.pdf',
  'fullContent': '{"title":"Brain Anatomy Reviewer","overview":"This reviewer summarizes key concepts from the uploaded nursing lesson with exam-focused recall points.","sections":[{"heading":"Key Concepts","bullets":["Key nursing concept with short, board-exam ready wording.","Prioritize assessment, safety, and patient education."]}],"keyTerms":[{"term":"Neuron","definition":"Basic functional unit of the nervous system"}],"mustRemember":["Assess level of consciousness first"],"practiceQuestions":[{"question":"What is the primary function of the frontal lobe?","answer":"Executive functions and voluntary movement"}],"flashcards":[{"front":"What does CNS stand for?","back":"Central Nervous System"}]}',
};
