import 'package:flutter/material.dart';

/// Auth form field built to the Figma spec: 351x41, 8px radius,
/// visible border for better contrast, Poppins 14
/// placeholder at rgba(170,170,170,0.67), label rendered above.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.textInputAction,
    this.autofillHints,
    this.errorText,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? errorText;

  // Darker border for better visibility (was rgba(229,229,229,0.9) which was nearly invisible)
  static const _borderColor = Color(0xFFB0BEC5); // Blue-grey 200 — visible but not harsh
  static const _errorBorderColor = Color(0xFFEF4444);
  static const _hintColor = Color(0xABAAAAAA); // rgba(170,170,170,0.67)

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 48, // slightly taller for better tap target
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasError ? _errorBorderColor : _borderColor,
              width: hasError ? 1.5 : 1.2,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.black,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: _hintColor,
              ),
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: suffix,
              suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 24),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: _errorBorderColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
