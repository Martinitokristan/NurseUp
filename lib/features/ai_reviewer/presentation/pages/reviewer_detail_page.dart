import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
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

  @override
  Widget build(BuildContext context) {
    final reviewerId = widget.reviewerId ?? GoRouterState.of(context).uri.queryParameters['id'] ?? '';
    final reviewerAsync = ref.watch(reviewerDocumentProvider(reviewerId));

    return reviewerAsync.when(
      data: (data) {
        final reviewer = ReviewerPdfData.fromFirestore(data ?? _demoDetailData);
        if (widget.showExportOnOpen && !_shownInitialExportSheet) {
          _shownInitialExportSheet = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showExportSheet(reviewer);
          });
        }
        return Scaffold(
          appBar: AppBar(title: Text(reviewer.title)),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Container(padding: const EdgeInsets.all(AppSpacing.lg), decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(AppSpacing.radiusLg)), child: Text(reviewer.summary, style: AppTextStyles.body)),
              const SizedBox(height: AppSpacing.xl),
              ...reviewer.sections.map((section) => Card(child: ExpansionTile(title: Text(section.heading, style: AppTextStyles.h3), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [Text(section.bullets.map((bullet) => '- $bullet').join('\n'), style: AppTextStyles.body)]))),
              const SizedBox(height: AppSpacing.lg),
              if (reviewer.practiceQuestions.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: AppColors.tipBackground, border: Border.all(color: AppColors.tipBorder), borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                  child: Text('Practice Questions:\n${reviewer.practiceQuestions.map((item) => '- ${item.question}\n  Answer: ${item.answer}').join('\n')}', style: AppTextStyles.bodyMedium),
                ),
            ],
          ),
          bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: AppButton(label: _isExporting ? 'Exporting...' : 'Export PDF', icon: Icons.file_download_rounded, onPressed: _isExporting ? null : () => _showExportSheet(reviewer)))),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const Scaffold(body: Center(child: Text('Unable to load reviewer.'))),
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
  'summary': 'This reviewer summarizes key concepts from the uploaded nursing lesson with exam-focused recall points.',
  'fileName': 'brain.pdf',
  'fullContent': '{"title":"Brain Anatomy Reviewer","summary":"This reviewer summarizes key concepts from the uploaded nursing lesson with PNLE-focused recall points.","keyPoints":["Key nursing concept with short, board-exam ready wording.","Prioritize assessment, safety, and patient education.","Connect anatomy to clinical signs."],"nursingConsiderations":["Assess level of consciousness and neurological changes.","Report sudden changes promptly."],"pnleTips":["Focus on priority nursing actions and early warning signs before memorizing rare details."]}',
};
