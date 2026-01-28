import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class SignInWithMicrosoft {
  final AuthRepository repository;

  SignInWithMicrosoft(this.repository);

  Future<Either<Failure, AppUser>> call() {
    return repository.signInWithMicrosoft();
  }
}
