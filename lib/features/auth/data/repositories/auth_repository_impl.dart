import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/firebase_error_mapper.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.remoteDatasource);

  final AuthRemoteDatasource remoteDatasource;

  @override
  Stream<UserEntity?> authStateChanges() => remoteDatasource.authStateChanges();

  @override
  Future<Either<Failure, UserEntity>> signInWithEmail(String email, String password) async => _guard(() => remoteDatasource.signInWithEmail(email, password));

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async => _guard(remoteDatasource.signInWithGoogle);

  @override
  Future<Either<Failure, void>> signOut() async => _guard(remoteDatasource.signOut);

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmail({required String name, required String email, required String password, String? school}) async {
    return _guard(() => remoteDatasource.signUpWithEmail(name: name, email: email, password: password, school: school));
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } catch (error) {
      // Use the centralized error mapper for user-friendly messages
      final friendlyMessage = FirebaseErrorMapper.mapError(error);
      return Left(ServerFailure(friendlyMessage));
    }
  }
}
