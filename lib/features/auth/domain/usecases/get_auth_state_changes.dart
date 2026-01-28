import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

class GetAuthStateChanges {
  final AuthRepository repository;

  GetAuthStateChanges(this.repository);

  Stream<AppUser?> call() {
    return repository.authStateChanges;
  }
}
