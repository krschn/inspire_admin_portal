import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  Future<Either<Failure, AppUser>> signInWithEmailPassword(
      String email, String password);

  Future<Either<Failure, AppUser>> signInWithMicrosoft();

  Future<Either<Failure, void>> signOut();
}
