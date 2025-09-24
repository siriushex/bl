import 'package:dio/dio.dart';
import 'package:hiddify/features/auth/model/telegram_auth_payload.dart';
import 'package:hiddify/features/auth/model/telegram_auth_session.dart';
import 'package:hiddify/utils/custom_loggers.dart';

abstract interface class AuthRepository {
  Future<TelegramAuthSession> completeTelegramLogin(
    TelegramAuthPayload payload,
  );

  Future<TelegramAuthSession> refreshSession(String accessToken);

  Future<void> revokeSession(String accessToken);
}

class AuthRepositoryImpl with InfraLogger implements AuthRepository {
  AuthRepositoryImpl(this._dio);

  final Dio _dio;

  static const _loginEndpoint = '/auth/telegram';
  static const _sessionEndpoint = '/session';
  static const _subscriptionEndpoint = '/subscription';

  @override
  Future<TelegramAuthSession> completeTelegramLogin(
    TelegramAuthPayload payload,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      _loginEndpoint,
      data: {
        'auth_data': payload.toJson(),
        if (payload.authToken != null) 'auth_token': payload.authToken,
      },
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('Missing session payload');
    }
    final session = TelegramAuthSession.fromJson(data);
    loggy.debug('authenticated telegram user: ${session.telegramId}');
    return session;
  }

  @override
  Future<TelegramAuthSession> refreshSession(String accessToken) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _subscriptionEndpoint,
      options: _authorizedOptions(accessToken),
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Missing session payload');
    }
    return TelegramAuthSession.fromJson(data);
  }

  @override
  Future<void> revokeSession(String accessToken) async {
    await _dio.delete<void>(
      _sessionEndpoint,
      options: _authorizedOptions(accessToken),
    );
  }

  Options _authorizedOptions(String accessToken) => Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );
}
