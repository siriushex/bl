import 'dart:io';

import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/features/auth/model/telegram_auth_payload.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:protocol_handler/protocol_handler.dart';

final telegramLoginLinkNotifierProvider =
    AsyncNotifierProvider<TelegramLoginLinkNotifier, TelegramAuthPayload?>(
  TelegramLoginLinkNotifier.new,
);

class TelegramLoginLinkNotifier
    extends AsyncNotifier<TelegramAuthPayload?>
    with ProtocolListener, InfraLogger {
  @override
  Future<TelegramAuthPayload?> build() async {
    if (Constants.deepLinkScheme.isEmpty) {
      loggy.warning('deep link scheme is empty');
      return null;
    }

    if (Platform.isLinux) return null;

    await protocolHandler.register(Constants.deepLinkScheme);
    protocolHandler.addListener(this);
    ref.onDispose(() {
      protocolHandler.removeListener(this);
    });

    final initialUrl = await protocolHandler.getInitialUrl();
    if (initialUrl != null) {
      final payload = _parse(initialUrl);
      if (payload != null) {
        return payload;
      }
    }

    return null;
  }

  @override
  void onProtocolUrlReceived(String url) {
    super.onProtocolUrlReceived(url);
    final payload = _parse(url);
    if (payload == null) {
      loggy.debug('invalid telegram login url: $url');
      return;
    }
    state = AsyncData(payload);
  }

  TelegramAuthPayload? _parse(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.scheme != Constants.deepLinkScheme) return null;
    if (uri.host != 'auth') return null;
    return TelegramAuthPayload.maybeFromUri(uri);
  }
}
