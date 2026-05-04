import 'package:firebase_auth/firebase_auth.dart';

/// Maps raw Firebase/platform error objects to user-friendly messages.
///
/// This eliminates cryptic technical error strings like
/// `[firebase_auth/channel-error] "dev.flutter.pigeon..."` and
/// replaces them with clear, actionable text.
class FirebaseErrorMapper {
  FirebaseErrorMapper._();

  /// Convert any error from auth operations to a user-friendly string.
  static String mapError(dynamic error) {
    // Handle FirebaseAuthException directly
    if (error is FirebaseAuthException) {
      return _mapAuthCode(error.code, error.message);
    }

    // Handle FirebaseException (parent class)
    if (error is FirebaseException) {
      return _mapAuthCode(error.code, error.message);
    }

    final errorString = error.toString().toLowerCase();

    // Detect common Firebase error codes from stringified errors
    if (errorString.contains('user-not-found') || errorString.contains('user not found')) {
      return 'No account found with this email. Please sign up first.';
    }
    if (errorString.contains('wrong-password') || errorString.contains('invalid-credential')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (errorString.contains('email-already-in-use')) {
      return 'An account already exists with this email. Try logging in instead.';
    }
    if (errorString.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (errorString.contains('weak-password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (errorString.contains('too-many-requests') || errorString.contains('rate-limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (errorString.contains('network-request-failed') || errorString.contains('network')) {
      return 'Network error. Please check your internet connection.';
    }
    if (errorString.contains('operation-not-allowed')) {
      return 'This sign-in method is not enabled. Please contact support.';
    }
    if (errorString.contains('account-exists-with-different-credential')) {
      return 'An account already exists with this email using a different sign-in method.';
    }
    if (errorString.contains('cancelled') || errorString.contains('canceled')) {
      return 'Sign-in was cancelled.';
    }
    if (errorString.contains('firebase-not-configured') || errorString.contains('no-app') || errorString.contains('app-not-authorized')) {
      return 'App configuration error. Please restart the app and try again.';
    }
    if (errorString.contains('channel-error') || errorString.contains('pigeon')) {
      return 'A connection error occurred. Please check your internet and try again.';
    }
    if (errorString.contains('missing-user') || errorString.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support.';
    }
    if (errorString.contains('requires-recent-login')) {
      return 'For security, please log in again to complete this action.';
    }
    if (errorString.contains('credential-already-in-use')) {
      return 'This credential is already linked to another account.';
    }
    if (errorString.contains('timeout') || errorString.contains('deadline-exceeded')) {
      return 'Request timed out. Please check your connection and try again.';
    }
    if (errorString.contains('permission-denied') || errorString.contains('permission_denied')) {
      return 'Permission denied. Please try again or contact support.';
    }

    // Fallback: show a generic friendly message
    return 'Something went wrong. Please try again.';
  }

  /// Map a known Firebase Auth error code to a friendly message.
  static String _mapAuthCode(String code, String? fallbackMessage) {
    return switch (code) {
      'user-not-found' => 'No account found with this email. Please sign up first.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'invalid-credential' || 'INVALID_LOGIN_CREDENTIALS' => 'Incorrect email or password. Please try again.',
      'invalid-email' => 'Please enter a valid email address.',
      'email-already-in-use' => 'An account already exists with this email. Try logging in instead.',
      'weak-password' => 'Password is too weak. Use at least 6 characters.',
      'too-many-requests' => 'Too many attempts. Please wait a moment and try again.',
      'network-request-failed' => 'Network error. Please check your internet connection.',
      'operation-not-allowed' => 'This sign-in method is not enabled. Please contact support.',
      'user-disabled' => 'This account has been disabled. Please contact support.',
      'account-exists-with-different-credential' => 'An account already exists with this email using a different sign-in method.',
      'cancelled' => 'Sign-in was cancelled.',
      'missing-user' => 'Authentication error. Please try again.',
      'firebase-not-configured' => 'App configuration error. Please restart the app.',
      'channel-error' => 'A connection error occurred. Please check your internet and try again.',
      'requires-recent-login' => 'For security, please log in again to complete this action.',
      'credential-already-in-use' => 'This credential is already linked to another account.',
      _ => fallbackMessage ?? 'Something went wrong. Please try again.',
    };
  }
}
