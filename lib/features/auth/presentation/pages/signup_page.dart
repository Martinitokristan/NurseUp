import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/widgets/auth_background.dart';
import '../../../../core/widgets/nurseup_logo.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final schoolController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Per-field error messages
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    schoolController.dispose();
    super.dispose();
  }

  /// Validate all fields and return true if all pass.
  bool _validate() {
    String? nameErr;
    String? emailErr;
    String? passwordErr;
    String? confirmErr;

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty) {
      nameErr = 'Please enter your name.';
    }

    if (email.isEmpty) {
      emailErr = 'Please enter your email address.';
    } else if (!_isValidEmail(email)) {
      emailErr = 'Please enter a valid email address.';
    }

    if (password.isEmpty) {
      passwordErr = 'Please enter a password.';
    } else if (password.length < 6) {
      passwordErr = 'Password must be at least 6 characters.';
    }

    if (confirmPassword.isEmpty) {
      confirmErr = 'Please confirm your password.';
    } else if (password != confirmPassword) {
      confirmErr = 'Passwords do not match.';
    }

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passwordErr;
      _confirmPasswordError = confirmErr;
    });

    return nameErr == null && emailErr == null && passwordErr == null && confirmErr == null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(30, 16, 30, 24),
            children: [
              const SizedBox(height: 16),
              const Center(child: NurseUpLogo(size: 110, showWordmark: true)),
              const SizedBox(height: 8),
              const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 18),
              AuthTextField(
                label: 'Name',
                hint: 'Enter your name',
                controller: nameController,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                errorText: _nameError,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Email',
                hint: 'Enter your email',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                errorText: _emailError,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Password',
                hint: 'Enter your password',
                controller: passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                errorText: _passwordError,
                suffix: _EyeToggle(
                  obscured: _obscurePassword,
                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 14),
              AuthTextField(
                label: 'Confirm Password',
                hint: 'Enter your confirm password',
                controller: confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                errorText: _confirmPasswordError,
                suffix: _EyeToggle(
                  obscured: _obscureConfirmPassword,
                  onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              // Server-side error message (user-friendly)
              if (authState.errorMessage != null) ...[
                const SizedBox(height: 12),
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
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 220,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: authState.isLoading ? null : () => _signUp(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF57A4CD),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF57A4CD).withValues(alpha: 0.6),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    ),
                    child: Text(
                      authState.isLoading ? 'Creating account…' : 'Sign Up',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(
                        color: Color(0xFFAAAAAA),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: 'Log In',
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
    );
  }

  Future<void> _signUp(BuildContext context) async {
    // Clear previous server errors
    ref.read(authControllerProvider.notifier).clearError();

    // Validate locally first
    if (!_validate()) return;

    final success = await ref.read(authControllerProvider.notifier).signUpWithEmail(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
          school: schoolController.text.trim().isEmpty ? null : schoolController.text.trim(),
        );
    if (success && context.mounted) context.go(AppRoutes.home);
  }
}

class _EyeToggle extends StatelessWidget {
  const _EyeToggle({required this.obscured, required this.onTap});

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
