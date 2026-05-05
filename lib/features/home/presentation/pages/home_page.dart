import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../ai_reviewer/presentation/providers/reviewer_provider.dart';
import '../../../ai_reviewer/presentation/utils/reviewer_navigation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../file_manager/presentation/providers/file_manager_provider.dart';
import '../../../usage/presentation/providers/usage_provider.dart';
import '../../../usage/presentation/widgets/usage_transparency_card.dart';
import '../../../usage/presentation/widgets/upgrade_modal.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final files = ref.watch(userFilesProvider).valueOrNull ?? const [];
    final usageAsync = ref.watch(usageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }
    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0F1A), Color(0xFF111A2E)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFF009DFF)],
          );
    final sectionLabelColor = isDark ? scheme.onSurface : Colors.white;
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: bgGradient),
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 62, 16, 110),
              children: [
                _buildGreetingCard(context, greeting, user?.name ?? 'Student'),
                const SizedBox(height: 16),
                usageAsync.when(
                  data: (usage) => _buildStreakCard(context, usage.streak),
                  loading: () => _buildStreakCard(context, 0),
                  error: (_, _) => _buildStreakCard(context, 0),
                ),
                const SizedBox(height: 16),
                _buildHeroCard(context, files),
                const SizedBox(height: 16),
                usageAsync.when(data: (usage) => UsageTransparencyCard(usage: usage, onUpgrade: () => _showUpgradeDialog(context)), loading: () => const SizedBox.shrink(), error: (error, stack) => const SizedBox.shrink()),
                const SizedBox(height: 16),
                Text('Recent Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: sectionLabelColor, fontFamily: 'Poppins')),
                const SizedBox(height: 16),
                if (files.isEmpty)
                  Text('Upload your first study file to begin.', style: TextStyle(fontSize: 14, color: sectionLabelColor.withValues(alpha: 0.8)))
                else
                  ...files.take(2).map((file) {
                    final reviewerId = ref.watch(reviewerIdForFileProvider(file.id));
                    final hasReviewer = reviewerId != null && reviewerId.isNotEmpty;
                    return _RecentActivityCard(
                      name: file.name,
                      type: hasReviewer ? 'Reviewer' : file.type.toUpperCase(),
                      meta: hasReviewer ? 'Reviewer ready · Tap to open' : '${file.type.toUpperCase()} · ${(file.sizeBytes / 1000000).toStringAsFixed(1)} MB',
                      onTap: () => openOrGenerateReviewer(context: context, ref: ref, fileId: file.id),
                    );
                  }),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(index: 0),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => UpgradeModal(onSubscribe: () => Navigator.pop(context), onMaybeLater: () => Navigator.pop(context)));
  }

  Widget _buildGreetingCard(BuildContext context, String greeting, String name) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Theme.of(context).colorScheme.surface
        : Colors.white.withValues(alpha: 0.85);
    final nameColor = isDark ? Theme.of(context).colorScheme.onSurface : Colors.black;
    final subColor = isDark ? const Color(0xFFA6B0C2) : const Color(0xFF8B95A4);
    final avatarBg = isDark ? const Color(0xFF1F2940) : const Color(0xFFE9EEF3);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
            child: Icon(Icons.person, size: 28, color: subColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(greeting, style: TextStyle(fontSize: 13, color: subColor, fontFamily: 'Poppins', height: 1.2)),
                const SizedBox(height: 2),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: nameColor, fontFamily: 'Poppins', height: 1.2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, int streak) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Theme.of(context).colorScheme.surface
        : Colors.white.withValues(alpha: 0.85);
    final titleColor = isDark ? Theme.of(context).colorScheme.onSurface : Colors.black;
    final subColor = isDark ? const Color(0xFFA6B0C2) : const Color(0xFF8B95A4);
    
    // Logic for the encouraging subtitle
    String encouragement;
    if (streak == 0) {
      encouragement = "Start your learning streak today!";
    } else if (streak < 3) {
      encouragement = "Great start! Keep it up.";
    } else {
      encouragement = "You're in the top 5% of students";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: streak > 0 ? const Color(0xFFFFE9C7) : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.local_fire_department, 
              size: 22, 
              color: streak > 0 ? const Color(0xFFFF6B00) : Colors.grey
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$streak Day Streak', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: titleColor, fontFamily: 'Poppins', height: 1.2)),
                const SizedBox(height: 2),
                Text(encouragement, style: TextStyle(fontSize: 12, color: subColor, fontFamily: 'Poppins', height: 1.2)),
              ],
            ),
          ),
          Icon(Icons.calendar_today_outlined, size: 24, color: subColor),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, List<dynamic> files) {
    final bool hasFiles = files.isNotEmpty;
    final String title = hasFiles ? 'Ready for your\nnext exam?' : 'Start your\nlearning journey';
    final String description = hasFiles
        ? "Our AI has analyzed your weak spots and generated insights. Let's tackle them now!"
        : "Upload your lecture notes or textbooks, and our AI will generate personalized study guides for you.";
    final String buttonText = hasFiles ? 'Start Review' : 'Upload File';
    final String route = hasFiles ? AppRoutes.reviewers : AppRoutes.upload;

    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF69BCCF), Color(0xFF789BC8)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.psychology, size: 16, color: Colors.white),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'AI REVIEWER READY',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: 'Poppins', letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(hasFiles ? Icons.edit_note : Icons.cloud_upload_outlined, size: 56, color: Colors.white.withValues(alpha: 0.75)),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.92),
                  fontFamily: 'Poppins',
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward, size: 16, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.name, required this.type, required this.meta, required this.onTap});

  final String name;
  final String type;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E5E5).withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment(-0.7, 0.9),
          end: Alignment(1.2, -0.9),
          colors: [Color(0xFF69BCCF), Color(0xFF789BC8)],
          stops: [0.14, 0.98],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              const SizedBox(width: 15),
              Container(
                width: 54,
                height: 52,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: type == 'PDF' ? const Color(0xFF00ACDC).withValues(alpha: 0.41) : const Color(0xFF00FF3B).withValues(alpha: 0.41),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(type == 'PDF' ? Icons.picture_as_pdf : Icons.quiz, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white, fontFamily: 'Poppins')),
                    const SizedBox(height: 4),
                    Text(meta, style: const TextStyle(fontSize: 16, color: Color(0xFFAAAAAA), fontFamily: 'Poppins')),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(type, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: type == 'PDF' ? const Color(0xFF0088FF) : const Color(0xFF00FF3B), fontFamily: 'Poppins')),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}
