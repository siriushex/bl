import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/model/constants.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/features/auth/model/telegram_auth_session.dart';
import 'package:hiddify/features/auth/notifier/auth_notifier.dart';
import 'package:hiddify/features/auth/notifier/telegram_login_link_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthPage extends HookConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final session = authState.valueOrNull;
    final isLoading = authState.isLoading;

    ref.listen(authNotifierProvider, (previous, next) {
      if (next.hasError) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
          ),
        );
        return;
      }

      final previousSession = previous?.valueOrNull;
      final nextSession = next.valueOrNull;
      if (previousSession == null && nextSession != null && context.mounted) {
        context.go(const HomeRoute().location);
      }
    });

    ref.listen(telegramLoginLinkNotifierProvider, (previous, next) async {
      if (next case AsyncError(:final error)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      } else if (next case AsyncData(value: final payload?)) {
        await ref
            .read(authNotifierProvider.notifier)
            .completeTelegramLogin(payload);
        ref.invalidate(telegramLoginLinkNotifierProvider);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(Constants.appName),
        actions: [
          IconButton(
            tooltip: 'Refresh subscription',
            onPressed: isLoading
                ? null
                : () => ref
                    .read(authNotifierProvider.notifier)
                    .refreshSubscription(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator.adaptive(
          onRefresh: () => ref
              .read(authNotifierProvider.notifier)
              .refreshSubscription(),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              Text(
                'Connect with Telegram',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Gap(8),
              const Text(
                'Use your Telegram account to unlock VPN access. We will import '
                'your active subscription profiles automatically after a '
                'successful login.',
              ),
              const Gap(24),
              _ActionButton(
                icon: Icons.login,
                label: 'Open Telegram Login',
                onPressed: isLoading
                    ? null
                    : () => _launchUri(
                          context,
                          Uri.parse(Constants.telegramLoginUrl),
                        ),
              ),
              const Gap(12),
              _ActionButton(
                icon: Icons.chat,
                label: 'Open ${Constants.telegramBotUsername}',
                onPressed: isLoading
                    ? null
                    : () => _launchUri(
                          context,
                          Constants.telegramBotAppLink,
                          fallback: Constants.telegramBotWebLink,
                        ),
              ),
              const Gap(12),
              OutlinedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text('Manage subscription in Telegram'),
                onPressed: () => _launchUri(
                  context,
                  Constants.telegramBotCheckoutAppLink,
                  fallback: Constants.telegramBotCheckoutWebLink,
                ),
              ),
              const Gap(24),
              if (authState.isLoading) ...[
                const LinearProgressIndicator(),
                const Gap(16),
              ],
              if (authState.hasError)
                Text(
                  authState.error.toString(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (session != null) ...[
                _SessionOverview(
                  session: session,
                  onSignOut: () => ref
                      .read(authNotifierProvider.notifier)
                      .signOut(),
                  isBusy: isLoading,
                ),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Waiting for authorization…',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Gap(8),
                        Text(
                          'After approving the login in Telegram you will be '
                          'redirected back to this app automatically.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _SessionOverview extends StatelessWidget {
  const _SessionOverview({
    required this.session,
    required this.onSignOut,
    required this.isBusy,
  });

  final TelegramAuthSession session;
  final VoidCallback onSignOut;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expireAt = session.subscriptionValidUntil;
    final usageText = (session.subscriptionTrafficUsed != null &&
            session.subscriptionTrafficTotal != null)
        ? '${_formatBytes(session.subscriptionTrafficUsed!)} / '
            '${_formatBytes(session.subscriptionTrafficTotal!)}'
        : null;
    final remaining = session.subscriptionTrafficRemaining;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Logged in as ${session.displayName}',
              style: theme.textTheme.titleMedium,
            ),
            const Gap(8),
            if (expireAt != null)
              Text(
                'Subscription valid until '
                '${DateFormat.yMMMMd().add_Hm().format(expireAt.toLocal())}',
              )
            else
              const Text('Active subscription'),
            if (session.subscriptionUsageRatio != null) ...[
              const Gap(16),
              LinearProgressIndicator(
                value: session.subscriptionUsageRatio,
              ),
              const Gap(4),
              if (usageText != null)
                Text(
                  'Traffic used: $usageText',
                  style: theme.textTheme.bodySmall,
                ),
              if (remaining != null)
                Text(
                  'Remaining traffic: ${_formatBytes(remaining)}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
            if (session.managementUrl != null) ...[
              const Gap(12),
              TextButton.icon(
                onPressed: () => _launchUri(
                  context,
                  session.managementUrl!,
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open dashboard'),
              ),
            ],
            const Gap(16),
            FilledButton.tonalIcon(
              onPressed: isBusy ? null : onSignOut,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _launchUri(
  BuildContext context,
  Uri uri, {
  LaunchMode mode = LaunchMode.externalApplication,
  Uri? fallback,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final launched = await launchUrl(uri, mode: mode);
    if (!launched && fallback != null) {
      await launchUrl(fallback, mode: mode);
    } else if (!launched) {
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to open $uri')),
      );
    }
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Unable to open $uri')),
    );
  }
}

String _formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  final formatted = value >= 10
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$formatted ${units[unitIndex]}';
}
