import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>((ref) => AuthRemoteDatasource());
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl(ref.watch(authRemoteDatasourceProvider)));
final authStateProvider = StreamProvider<UserEntity?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());

/// Streams the Firestore `users/{uid}` document so that field updates
/// (e.g. photoUrl after a profile image upload) propagate to the UI
/// immediately without needing a sign-out/sign-in cycle.
final firestoreUserProvider = StreamProvider<UserEntity?>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final uid = authAsync.valueOrNull?.uid;
  if (uid == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => snap.exists ? UserModel.fromFirestore(snap) : null);
});

class AuthControllerState {
  const AuthControllerState({this.isLoading = false, this.errorMessage});

  final bool isLoading;
  final String? errorMessage;
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthControllerState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AuthControllerState> {
  AuthController(this._repository) : super(const AuthControllerState());

  final AuthRepository _repository;

  /// Clear any existing error message (e.g. before a new attempt).
  void clearError() {
    if (state.errorMessage != null) {
      state = const AuthControllerState();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    state = const AuthControllerState(isLoading: true);
    final result = await _repository.signInWithEmail(email, password);
    return _complete(result);
  }

  Future<bool> signUpWithEmail({required String name, required String email, required String password, String? school}) async {
    state = const AuthControllerState(isLoading: true);
    final result = await _repository.signUpWithEmail(name: name, email: email, password: password, school: school);
    return _complete(result);
  }

  Future<bool> signInWithGoogle() async {
    state = const AuthControllerState(isLoading: true);
    final result = await _repository.signInWithGoogle();
    return _complete(result);
  }

  Future<void> signOut() async {
    state = const AuthControllerState(isLoading: true);
    await _repository.signOut();
    state = const AuthControllerState();
  }

  bool _complete(dynamic result) {
    return result.fold((failure) {
      state = AuthControllerState(errorMessage: failure.message);
      return false;
    }, (_) {
      state = const AuthControllerState();
      return true;
    });
  }
}
