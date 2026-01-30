import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/rate_limit_state.dart';

class RateLimitStorage {
  RateLimitStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _key = 'rate_limit_state';

  Future<RateLimitState> load() async {
    try {
      final json = await _storage.read(key: _key);
      if (json == null) {
        return RateLimitState.initial();
      }
      return RateLimitState.fromJson(
        jsonDecode(json) as Map<String, dynamic>,
      );
    } catch (_) {
      return RateLimitState.initial();
    }
  }

  Future<void> save(RateLimitState state) async {
    await _storage.write(
      key: _key,
      value: jsonEncode(state.toJson()),
    );
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
