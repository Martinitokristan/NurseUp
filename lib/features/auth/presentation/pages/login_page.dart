import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/auth_background.dart';
import '../../../../core/widgets/nurseup_logo.dart';
import '../../../../core/widgets/social_icons.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  /// Validate fields and return true if all pass.
  bool _validate() {
    String? emailErr;
    String? passwordErr;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty) {
      emailErr = 'Please enter your email address.';
    } else if (!_isValidEmail(email)) {
      emailErr = 'Please enter a valid email address.';
    }

    if (password.isEmpty) {
      passwordErr = 'Please enter your password.';
    } else if (password.length < 6) {
      passwordErr = 'Password must be at least 6 characters.';
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passwordErr;
    });

    return emailErr == null && passwordErr == null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    // Force light mode for Login screen regardless of system theme.
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
      ),
      child: Scaffold(
        body: AuthBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(30, 16, 30, 24),
            children: [
              const SizedBox(height: 24),
              // Figma: logo at x=135, y=92, width=150, height=123
              const Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: NurseUpLogo(size: 200, showWordmark: true),
                ),
              ),
              const SizedBox(height: 12),
              // Figma: "Login" text centered at x=163, width=93 on a 402-wide canvas.
              const Center(
                child: Text(
                  'Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AuthTextField(
                label: 'Email',
                hint: 'Enter your email',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                errorText: _emailError,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Password',
                hint: 'Enter your password',
                controller: passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                errorText: _passwordError,
                suffix: _PasswordEye(
                  obscured: _obscurePassword,
                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFF55A8C9),
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              // Server-side error message (user-friendly)
              if (authState.errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 13,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              _PrimaryButton(
                label: authState.isLoading ? 'Logging in…' : 'Login',
                onPressed: authState.isLoading ? null : () => _signInWithEmail(context),
              ),
              const SizedBox(height: 22),
              const _OrDivider(text: 'Or Login with'),
              const SizedBox(height: 18),
              _SocialRow(
                onGoogle: authState.isLoading ? null : () => _signInWithGoogle(context),
              ),
              const SizedBox(height: 28),
              Center(
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.signup),
                  child: const Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: Color(0xFF55A8C9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _signInWithEmail(BuildContext context) async {
    // Clear previous server error
    ref.read(authControllerProvider.notifier).clearError();
    
    // Validate locally first
    if (!_validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .signInWithEmail(emailController.text.trim(), passwordController.text);
    if (success && context.mounted) context.go(AppRoutes.home);
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    ref.read(authControllerProvider.notifier).clearError();
    final success = await ref.read(authControllerProvider.notifier).signInWithGoogle();
    if (success && context.mounted) context.go(AppRoutes.home);
  }
}

class _PasswordEye extends StatelessWidget {
  const _PasswordEye({required this.obscured, required this.onTap});

  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Icon(
          obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: const Color(0xFF8B95A4),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 220,
        height: 50,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF57A4CD),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF57A4CD).withValues(alpha: 0.6),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFFB7C0CC))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 14,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFFB7C0CC))),
      ],
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({required this.onGoogle});

  final VoidCallback? onGoogle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialButton(onPressed: onGoogle, child: const GoogleGIcon(size: 24)),
        const SizedBox(width: 19),
        const _SocialButton(onPressed: null, child: FacebookIcon(size: 24)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.child, required this.onPressed});

  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(50),
          child: Center(child: child),
        ),
      ),
    );
  }
}
