import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/auth/data/auth_data_providers.dart';
import 'package:hiddify/features/auth/model/telegram_auth_payload.dart';
import 'package:hiddify/features/auth/model/telegram_auth_session.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _sessionPreferenceKey = 'auth_session';

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, TelegramAuthSession?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<TelegramAuthSession?> with AppLogger {
  late PreferencesEntry<String, String> _sessionEntry;

  @override
  Future<TelegramAuthSession?> build() async {
    final preferences = await ref.watch(sharedPreferencesProvider.future);
    _sessionEntry = PreferencesEntry<String, String>(
      preferences: preferences,
      key: _sessionPreferenceKey,
      defaultValue: '',
    );

    final raw = _sessionEntry.read();
    if (raw.isEmpty) {
      loggy.debug('no persisted session found');
      return null;
    }

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final session = TelegramAuthSession.fromJson(map);
      loggy.debug('restored session for ${session.telegramId}');
      await _syncSubscription(session);
      return session;
    } catch (error, stackTrace) {
      loggy.warning('failed to restore stored session', error, stackTrace);
      await _sessionEntry.remove();
      return null;
    }
  }

  Future<void> completeTelegramLogin(TelegramAuthPayload payload) async {
    loggy.debug('completing telegram login');
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final session = await repository.completeTelegramLogin(payload);
      await _persistSession(session);
      await _syncSubscription(session);
      return session;
    });
  }

  Future<void> refreshSubscription() async {
    final current = state.valueOrNull ?? await future;
    if (current == null) {
      state = const AsyncData(null);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      final updated = await repository.refreshSession(current.accessToken);
      await _persistSession(updated);
      await _syncSubscription(updated);
      return updated;
    });
  }

  Future<void> signOut() async {
    final session = state.valueOrNull ?? await future;
    state = const AsyncData(null);
    await _sessionEntry.remove();

    if (session == null) return;

    try {
      await ref.read(authRepositoryProvider).revokeSession(session.accessToken);
    } catch (error, stackTrace) {
      loggy.debug('failed to revoke remote session', error, stackTrace);
    }
  }

  Future<void> _persistSession(TelegramAuthSession session) async {
    await _sessionEntry.write(jsonEncode(session.toJson()));
  }

  Future<Unit> _syncSubscription(TelegramAuthSession session) async {
    final repository = await ref.read(profileRepositoryProvider.future);
    final result = await repository
        .addByUrl(
          session.subscriptionUrl.toString(),
          markAsActive: true,
        )
        .run();

    return result.match(
      (failure) => throw failure,
      (_) => unit,
    );
  }
}
