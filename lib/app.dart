import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'core/constants/app_spacing.dart';
import 'core/constants/app_text_styles.dart';
import 'core/theme/theme_provider.dart';
import 'features/ai_reviewer/presentation/pages/reviewer_detail_page.dart';
import 'features/ai_reviewer/presentation/pages/reviewer_generating_page.dart';
import 'features/ai_reviewer/presentation/pages/reviewer_list_page.dart';
import 'features/anatomy_3d/presentation/pages/anatomy_catalog_page.dart';
import 'features/anatomy_3d/presentation/pages/anatomy_viewer_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/onboarding_page.dart';
import 'features/auth/presentation/pages/signup_page.dart';
import 'features/file_manager/presentation/pages/file_manager_page.dart';
import 'features/file_manager/presentation/pages/file_upload_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'features/subscription/presentation/pages/paywall_page.dart';
import 'features/subscription/presentation/pages/subscription_success_page.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'NurseUp',
      theme: appTheme,
      darkTheme: appDarkTheme,
      themeMode: themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

final _router = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
    GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingPage()),
    GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
    GoRoute(path: AppRoutes.signup, builder: (_, _) => const SignupPage()),
    GoRoute(path: AppRoutes.home, builder: (_, _) => const HomePage()),
    GoRoute(path: AppRoutes.files, builder: (_, _) => const FileManagerPage()),
    GoRoute(path: AppRoutes.upload, builder: (_, _) => const FileUploadPage()),
    GoRoute(path: AppRoutes.reviewers, builder: (_, _) => const ReviewerListPage()),
    GoRoute(path: AppRoutes.reviewerGenerating, builder: (_, _) => const ReviewerGeneratingPage()),
    GoRoute(path: AppRoutes.reviewerDetail, builder: (_, state) => ReviewerDetailPage(reviewerId: state.uri.queryParameters['id'], showExportOnOpen: state.uri.queryParameters['export'] == 'true')), 
    GoRoute(path: AppRoutes.anatomy, builder: (_, _) => const AnatomyCatalogPage()),
    GoRoute(path: AppRoutes.anatomyViewer, builder: (_, _) => const AnatomyViewerPage()),
    GoRoute(path: AppRoutes.paywall, builder: (_, _) => const PaywallPage()),
    GoRoute(path: AppRoutes.subscriptionSuccess, builder: (_, _) => const SubscriptionSuccessPage()),
    GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfilePage()),
  ],
);

ThemeData get appTheme => ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, brightness: Brightness.light, surface: AppColors.surface),
  scaffoldBackgroundColor: AppColors.background,
  fontFamily: 'Inter',
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      textStyle: AppTextStyles.button,
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size(double.infinity, 52),
      side: const BorderSide(color: AppColors.primary, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      textStyle: AppTextStyles.button,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl), side: const BorderSide(color: AppColors.border)),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
    titleTextStyle: AppTextStyles.h2,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceLight,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
    hintStyle: AppTextStyles.body.copyWith(color: AppColors.textHint),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textHint,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
    selectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 11),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.primarySurface,
    labelStyle: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusFull)),
    padding: const EdgeInsets.symmetric(horizontal: 8),
  ),
  dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1, space: 0),
);

ThemeData get appDarkTheme {
  const darkBg = Color(0xFF0B0F1A);
  const darkSurface = Color(0xFF151C2C);
  const darkSurfaceVariant = Color(0xFF1A2233);
  const darkOutline = Color(0xFF273349);
  const darkOnSurface = Color(0xFFE8EDF5);
  const darkOnSurfaceDim = Color(0xFFA6B0C2);

  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    surface: darkSurface,
    onSurface: darkOnSurface,
    surfaceContainerHighest: darkSurfaceVariant,
    outline: darkOutline,
    primary: AppColors.primaryLight,
    onPrimary: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: darkBg,
    canvasColor: darkBg,
    cardColor: darkSurface,
    dialogTheme: const DialogThemeData(backgroundColor: darkSurface),
    fontFamily: 'Inter',
    // Every text style inherits onSurface by default now.
    textTheme: const TextTheme().apply(
      bodyColor: darkOnSurface,
      displayColor: darkOnSurface,
    ),
    primaryTextTheme: const TextTheme().apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    iconTheme: const IconThemeData(color: darkOnSurface),
    primaryIconTheme: const IconThemeData(color: Colors.white),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl), side: const BorderSide(color: darkOutline)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBg,
      foregroundColor: darkOnSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w600, color: darkOnSurface),
      iconTheme: IconThemeData(color: darkOnSurface),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl), borderSide: const BorderSide(color: darkOutline)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl), borderSide: const BorderSide(color: darkOutline)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl), borderSide: const BorderSide(color: AppColors.primaryLight, width: 2)),
      hintStyle: const TextStyle(color: darkOnSurfaceDim),
      labelStyle: const TextStyle(color: darkOnSurfaceDim),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: darkOnSurfaceDim,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontFamily: 'Inter', fontSize: 11),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.primaryLight : darkOnSurfaceDim,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? AppColors.primaryLight.withValues(alpha: 0.4)
            : darkOutline,
      ),
    ),
    dividerTheme: const DividerThemeData(color: darkOutline, thickness: 1, space: 0),
  );
}


