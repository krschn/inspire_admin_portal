import 'package:equatable/equatable.dart';

class RateLimitState extends Equatable {
  const RateLimitState({
    required this.failedAttempts,
    this.lockoutExpiresAt,
  });

  final int failedAttempts;
  final DateTime? lockoutExpiresAt;

  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 10);

  bool get isLockedOut {
    if (lockoutExpiresAt == null) return false;
    return DateTime.now().isBefore(lockoutExpiresAt!);
  }

  Duration get remainingLockoutDuration {
    if (lockoutExpiresAt == null) return Duration.zero;
    final remaining = lockoutExpiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  RateLimitState copyWith({
    int? failedAttempts,
    DateTime? lockoutExpiresAt,
    bool clearLockout = false,
  }) {
    return RateLimitState(
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutExpiresAt:
          clearLockout ? null : (lockoutExpiresAt ?? this.lockoutExpiresAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'failedAttempts': failedAttempts,
      'lockoutExpiresAt': lockoutExpiresAt?.toIso8601String(),
    };
  }

  factory RateLimitState.fromJson(Map<String, dynamic> json) {
    return RateLimitState(
      failedAttempts: json['failedAttempts'] as int? ?? 0,
      lockoutExpiresAt: json['lockoutExpiresAt'] != null
          ? DateTime.parse(json['lockoutExpiresAt'] as String)
          : null,
    );
  }

  factory RateLimitState.initial() {
    return const RateLimitState(failedAttempts: 0);
  }

  @override
  List<Object?> get props => [failedAttempts, lockoutExpiresAt];
}
