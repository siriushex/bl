import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/features/auth/model/telegram_auth_session.dart';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountSettingTiles extends HookConsumerWidget {
  const AccountSettingTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final session = authState.valueOrNull;
    final isLoading = authState.isLoading;

    final subtitle = session == null
        ? 'Authorize with Telegram to import subscription profiles.'
        : _formatSubscription(session);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_circle_outlined),
          title: Text(
            session == null
                ? 'Not authenticated'
                : 'Logged in as ${session.displayName}',
          ),
          subtitle: Text(subtitle),
          trailing: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => context.go(const AuthRoute().location),
              icon: const Icon(Icons.login),
              label: Text(session == null ? 'Sign in with Telegram' : 'Manage account'),
            ),
            OutlinedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => ref
                      .read(authNotifierProvider.notifier)
                      .refreshSubscription(),
              icon: const Icon(Icons.sync),
              label: const Text('Refresh subscription'),
            ),
            TextButton.icon(
              onPressed: () => _launchTelegramBot(context),
              icon: const Icon(Icons.send),
              label: Text('Open ${Constants.telegramBotUsername}'),
            ),
            if (session != null)
              TextButton.icon(
                onPressed: isLoading
                    ? null
                    : () => ref
                        .read(authNotifierProvider.notifier)
                        .signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
          ],
        ),
      ],
    );
  }

  String _formatSubscription(TelegramAuthSession session) {
    if (session.subscriptionValidUntil == null) {
      return 'Subscription active';
    }
    final formatted =
        DateFormat.yMMMMd().add_Hm().format(session.subscriptionValidUntil!.toLocal());
    return 'Subscription valid until $formatted';
  }
}

Future<void> _launchTelegramBot(BuildContext context) async {
  final uri = Constants.telegramBotAppLink;
  final fallback = Constants.telegramBotWebLink;
  final messenger = ScaffoldMessenger.of(context);
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      final fallbackLaunched =
          await launchUrl(fallback, mode: LaunchMode.externalApplication);
      if (!fallbackLaunched) {
        messenger.showSnackBar(
          SnackBar(content: Text('Unable to open ${Constants.telegramBotUsername}')),
        );
      }
    }
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Unable to open $uri')),
    );
  }
}
