import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_auth_state_changes.dart';
import '../../domain/usecases/sign_in_with_email_password.dart';
import '../../domain/usecases/sign_in_with_microsoft.dart';
import '../../domain/usecases/sign_out.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthRemoteDataSourceImpl(firebaseAuth);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource);
});

final getAuthStateChangesUseCaseProvider = Provider<GetAuthStateChanges>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetAuthStateChanges(repository);
});

final signInWithEmailPasswordUseCaseProvider =
    Provider<SignInWithEmailPassword>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithEmailPassword(repository);
});

final signInWithMicrosoftUseCaseProvider =
    Provider<SignInWithMicrosoft>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithMicrosoft(repository);
});

final signOutUseCaseProvider = Provider<SignOut>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOut(repository);
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  final getAuthStateChanges = ref.watch(getAuthStateChangesUseCaseProvider);
  return getAuthStateChanges();
});

final authActionsProvider =
    AsyncNotifierProvider<AuthActionsNotifier, void>(AuthActionsNotifier.new);

class AuthActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> signInWithEmailPassword(String email, String password) async {
    state = const AsyncLoading();
    final signIn = ref.read(signInWithEmailPasswordUseCaseProvider);
    final result = await signIn(email, password);

    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        SnackbarService.showError(failure.message);
        return false;
      },
      (user) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<bool> signInWithMicrosoft() async {
    state = const AsyncLoading();
    final signIn = ref.read(signInWithMicrosoftUseCaseProvider);
    final result = await signIn();

    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        SnackbarService.showError(failure.message);
        return false;
      },
      (user) {
        state = const AsyncData(null);
        return true;
      },
    );
  }

  Future<bool> signOut() async {
    state = const AsyncLoading();
    final signOutUseCase = ref.read(signOutUseCaseProvider);
    final result = await signOutUseCase();

    return result.fold(
      (failure) {
        state = AsyncError(failure.message, StackTrace.current);
        SnackbarService.showError(failure.message);
        return false;
      },
      (_) {
        state = const AsyncData(null);
        return true;
      },
    );
  }
}
