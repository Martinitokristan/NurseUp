import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_bottom_nav.dart';
import '../../../ai_reviewer/presentation/providers/reviewer_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../file_manager/presentation/providers/file_manager_provider.dart';
import '../../../subscription/presentation/providers/subscription_provider.dart';
import '../../../usage/presentation/providers/usage_provider.dart';
import '../providers/profile_edit_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final firestoreUser = ref.watch(firestoreUserProvider).valueOrNull;
    final files = ref.watch(userFilesProvider).valueOrNull ?? const [];
    final reviewers = ref.watch(reviewersProvider).valueOrNull ?? const [];
    final themeMode = ref.watch(themeModeProvider);
    final usage = ref.watch(usageProvider).valueOrNull;
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          // Background gradient + decorative blobs (matches Figma look)
          const Positioned.fill(child: _ProfileBackdrop()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
              children: [
                _Header(isDark: isDark),
                const SizedBox(height: 24),
                _AvatarBlock(
                  name: user?.name ?? 'NurseUp Student',
                  subtitle: _profileSubtitle(user?.email),
                  photoUrl: firestoreUser?.photoUrl ?? user?.photoUrl,
                  onChangePhoto: () => _changeProfilePhoto(context, ref),
                ),
                const SizedBox(height: 18),
                _PlanCard(
                  tier: usage?.tier ?? 'free',
                  onManage: () => context.push(AppRoutes.paywall),
                ),
                const SizedBox(height: 18),
                _StatsRow(filesCount: files.length, reviewersCount: reviewers.length),
                const SizedBox(height: 18),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.edit_rounded,
                      label: 'Edit Profile',
                      onTap: () => _showEditProfileSheet(context, ref, user?.name ?? ''),
                    ),
                    _SettingsDivider(),
                    _SettingsToggleTile(
                      icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      label: 'Dark Mode',
                      value: isDark,
                      onChanged: (v) => ref.read(themeModeProvider.notifier).toggleDark(v),
                    ),
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Manage Subscription',
                      onTap: () => context.push(AppRoutes.paywall),
                    ),
                    _SettingsDivider(),
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      label: 'Privacy & Data',
                      onTap: () => _showInfoDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SettingsCard(
                  children: [
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      label: 'Sign Out',
                      tint: const Color(0xFFEF4444),
                      onTap: () => _confirmSignOut(context, ref),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(index: 3),
    );
  }

  static String _profileSubtitle(String? email) {
    if (email == null || email.isEmpty) return 'Sign in to sync your data';
    return email;
  }

  void _showEditProfileSheet(BuildContext context, WidgetRef ref, String currentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => _EditProfileSheet(initialName: currentName),
    );
  }

  Future<void> _changeProfilePhoto(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(profileEditControllerProvider.notifier);
    final ok = await notifier.updateProfileImage();
    if (!context.mounted) return;
    if (ok) {
      messenger.showSnackBar(const SnackBar(content: Text('Profile picture updated!')));
      return;
    }
    // Check if there was an actual error (vs. user just cancelled the picker)
    final errorState = ref.read(profileEditControllerProvider);
    if (errorState is AsyncError) {
      messenger.showSnackBar(SnackBar(content: Text('Upload failed: ${errorState.error}'), backgroundColor: Colors.red));
    }
    // If no error — user simply cancelled the picker; no snackbar needed.
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Privacy & Data'),
        content: const Text(
          'Your study files and reviewers are stored in your private Firebase account. '
          'Words are counted from extracted text only — images and formatting do not count. '
          'Weekly limit resets every Monday 12:00 AM and unused words do not roll over.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it')),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?'),
        content: const Text('You can sign back in any time to restore your files and reviewers.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authControllerProvider.notifier).signOut();
              ref.invalidate(userFilesProvider);
              ref.invalidate(reviewersProvider);
              ref.invalidate(flashcardsProvider);
              ref.invalidate(usageProvider);
              ref.invalidate(subscriptionDocProvider);
              if (context.mounted) context.go(AppRoutes.login);
            },
            child: const Text('Sign out', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }
}

class _ProfileBackdrop extends StatelessWidget {
  const _ProfileBackdrop();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0B0F1A), Color(0xFF111A2E)],
          ),
        ),
      );
    }
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFEAF3FF), Color(0xFFB9DBF5)],
            ),
          ),
        ),
        Positioned(
          top: -120,
          left: -120,
          child: _Blob(size: 320, color: const Color(0xFF8FB6FF).withValues(alpha: 0.55)),
        ),
        Positioned(
          bottom: -160,
          right: -120,
          child: _Blob(size: 360, color: const Color(0xFF7AA8FF).withValues(alpha: 0.45)),
        ),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F1B2D);
    return Row(
      children: [
        Text(
          'Profile & Settings',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 26, fontWeight: FontWeight.w700, color: textColor),
        ),
      ],
    );
  }
}

class _AvatarBlock extends StatelessWidget {
  const _AvatarBlock({required this.name, required this.subtitle, required this.photoUrl, required this.onChangePhoto});
  final String name;
  final String subtitle;
  final String? photoUrl;
  final VoidCallback onChangePhoto;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F1B2D);
    final subColor = isDark ? Colors.white70 : const Color(0xFF4A5A72);
    return Column(
      children: [
        GestureDetector(
          onTap: onChangePhoto,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1A2233) : Colors.white,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 3),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                  image: photoUrl != null && photoUrl!.isNotEmpty
                      ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: photoUrl == null || photoUrl!.isEmpty ? Icon(Icons.person, size: 56, color: subColor) : null,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: Color(0xFF2196F3), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 17),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: textColor),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: subColor),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.tier, required this.onManage});
  final String tier;
  final VoidCallback onManage;
  @override
  Widget build(BuildContext context) {
    final bool isPro = tier.toLowerCase() == 'pro';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPro 
            ? [const Color(0xFF6FCFE0), const Color(0xFF6E9BD1)]
            : [const Color(0xFF9E9E9E), const Color(0xFF757575)],
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
            child: Icon(isPro ? Icons.diamond_outlined : Icons.person_outline, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isPro ? 'Pro Plan' : 'Free Plan', 
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)
                ),
                const SizedBox(height: 2),
                Text(
                  isPro ? 'Premium access active' : 'Upgrade for more words', 
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFFE9F4FF))
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onManage,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Text(
                  isPro ? 'Manage' : 'Upgrade', 
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.filesCount, required this.reviewersCount});
  final int filesCount;
  final int reviewersCount;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatTile(icon: Icons.folder_rounded, label: 'Files', value: '$filesCount')),
        const SizedBox(width: 12),
        Expanded(child: _StatTile(icon: Icons.description_rounded, label: 'Reviewers', value: '$reviewersCount')),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A2233) : Colors.white.withValues(alpha: 0.92);
    final textColor = isDark ? Colors.white : const Color(0xFF0F1B2D);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6B7A8F);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: const Color(0xFF2196F3).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.folder_rounded, color: Color(0xFF2196F3), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: textColor, height: 1.1)),
                Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: subColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A2233) : Colors.white.withValues(alpha: 0.95);
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: isDark ? const Color(0xFF273349) : const Color(0xFFE8EEF5),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.label, required this.onTap, this.tint});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tint;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = tint ?? (isDark ? Colors.white : const Color(0xFF0F1B2D));
    final iconColor = tint ?? const Color(0xFF2196F3);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
              ),
              Icon(Icons.chevron_right_rounded, color: textColor.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  const _SettingsToggleTile({required this.icon, required this.label, required this.value, required this.onChanged});
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F1B2D);
    const iconColor = Color(0xFF2196F3);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.brightness_6_rounded, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: textColor))),
          Switch.adaptive(value: value, onChanged: onChanged, activeThumbColor: const Color(0xFF2196F3)),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.initialName});
  final String initialName;
  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final ok = await ref
        .read(profileEditControllerProvider.notifier)
        .updateDisplayName(_nameController.text);
    if (!mounted) return;
    if (ok) {
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Profile updated')));
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('Could not update profile')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileEditControllerProvider);
    final isLoading = state.isLoading;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Edit Profile', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Display name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: isLoading ? null : _onSave,
            child: Text(isLoading ? 'Saving...' : 'Save changes'),
          ),
        ],
      ),
    );
  }
}
