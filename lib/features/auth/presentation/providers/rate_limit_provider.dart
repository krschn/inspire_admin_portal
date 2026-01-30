import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/services/rate_limit_storage.dart';
import '../../domain/entities/rate_limit_state.dart';

final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    webOptions: WebOptions(dbName: 'inspire_admin', publicKey: 'inspire_admin'),
  );
});

final rateLimitStorageProvider = Provider<RateLimitStorage>((ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return RateLimitStorage(storage);
});

final rateLimitProvider =
    AsyncNotifierProvider<RateLimitNotifier, RateLimitState>(
  RateLimitNotifier.new,
);

class RateLimitNotifier extends AsyncNotifier<RateLimitState> {
  Timer? _lockoutTimer;

  @override
  Future<RateLimitState> build() async {
    ref.onDispose(() {
      _lockoutTimer?.cancel();
    });

    final storage = ref.read(rateLimitStorageProvider);
    final savedState = await storage.load();

    // Check if lockout has expired
    if (savedState.lockoutExpiresAt != null &&
        DateTime.now().isAfter(savedState.lockoutExpiresAt!)) {
      final clearedState = RateLimitState.initial();
      await storage.save(clearedState);
      return clearedState;
    }

    // Start timer if currently locked out
    if (savedState.isLockedOut) {
      _startLockoutTimer(savedState.remainingLockoutDuration);
    }

    return savedState;
  }

  void _startLockoutTimer(Duration duration) {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer(duration, () async {
      final storage = ref.read(rateLimitStorageProvider);
      final clearedState = RateLimitState.initial();
      await storage.save(clearedState);
      state = AsyncData(clearedState);
    });
  }

  Future<void> recordFailedAttempt() async {
    final currentState = state.value ?? RateLimitState.initial();

    // Don't record if already locked out
    if (currentState.isLockedOut) return;

    final newAttempts = currentState.failedAttempts + 1;
    RateLimitState newState;

    if (newAttempts >= RateLimitState.maxAttempts) {
      // Lock out the user
      final lockoutExpiry = DateTime.now().add(RateLimitState.lockoutDuration);
      newState = RateLimitState(
        failedAttempts: newAttempts,
        lockoutExpiresAt: lockoutExpiry,
      );
      _startLockoutTimer(RateLimitState.lockoutDuration);
    } else {
      newState = currentState.copyWith(failedAttempts: newAttempts);
    }

    final storage = ref.read(rateLimitStorageProvider);
    await storage.save(newState);
    state = AsyncData(newState);
  }

  Future<void> resetOnSuccess() async {
    final storage = ref.read(rateLimitStorageProvider);
    final clearedState = RateLimitState.initial();
    await storage.save(clearedState);
    _lockoutTimer?.cancel();
    state = AsyncData(clearedState);
  }
}
