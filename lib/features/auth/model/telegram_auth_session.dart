class TelegramAuthSession {
  const TelegramAuthSession({
    required this.telegramId,
    this.username,
    this.firstName,
    this.lastName,
    this.authenticatedAt,
    required this.accessToken,
    required this.subscriptionUrl,
    this.managementUrl,
    this.subscriptionValidUntil,
    this.subscriptionTrafficTotal,
    this.subscriptionTrafficUsed,
  });

  final int telegramId;
  final String? username;
  final String? firstName;
  final String? lastName;
  final DateTime? authenticatedAt;
  final String accessToken;
  final Uri subscriptionUrl;
  final Uri? managementUrl;
  final DateTime? subscriptionValidUntil;
  final int? subscriptionTrafficTotal;
  final int? subscriptionTrafficUsed;

  factory TelegramAuthSession.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true)
            .toLocal();
      }
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value)?.toLocal();
      }
      return null;
    }

    return TelegramAuthSession(
      telegramId: json['telegram_id'] is String
          ? int.parse(json['telegram_id'] as String)
          : (json['telegram_id'] ?? json['id']) as int,
      username: json['username'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      authenticatedAt: parseDate(json['authenticated_at']),
      accessToken: json['access_token'] as String,
      subscriptionUrl: Uri.parse(json['subscription_url'] as String),
      managementUrl: json['management_url'] == null
          ? null
          : Uri.parse(json['management_url'] as String),
      subscriptionValidUntil: parseDate(json['subscription_valid_until']),
      subscriptionTrafficTotal:
          (json['subscription_traffic_total'] as num?)?.toInt(),
      subscriptionTrafficUsed:
          (json['subscription_traffic_used'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'telegram_id': telegramId,
        if (username != null) 'username': username,
        if (firstName != null) 'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (authenticatedAt != null)
          'authenticated_at': authenticatedAt!.toIso8601String(),
        'access_token': accessToken,
        'subscription_url': subscriptionUrl.toString(),
        if (managementUrl != null) 'management_url': managementUrl.toString(),
        if (subscriptionValidUntil != null)
          'subscription_valid_until':
              subscriptionValidUntil!.toIso8601String(),
        if (subscriptionTrafficTotal != null)
          'subscription_traffic_total': subscriptionTrafficTotal,
        if (subscriptionTrafficUsed != null)
          'subscription_traffic_used': subscriptionTrafficUsed,
      };

  TelegramAuthSession copyWith({
    int? telegramId,
    String? username,
    String? firstName,
    String? lastName,
    DateTime? authenticatedAt,
    String? accessToken,
    Uri? subscriptionUrl,
    Uri? managementUrl,
    DateTime? subscriptionValidUntil,
    int? subscriptionTrafficTotal,
    int? subscriptionTrafficUsed,
  }) {
    return TelegramAuthSession(
      telegramId: telegramId ?? this.telegramId,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      authenticatedAt: authenticatedAt ?? this.authenticatedAt,
      accessToken: accessToken ?? this.accessToken,
      subscriptionUrl: subscriptionUrl ?? this.subscriptionUrl,
      managementUrl: managementUrl ?? this.managementUrl,
      subscriptionValidUntil:
          subscriptionValidUntil ?? this.subscriptionValidUntil,
      subscriptionTrafficTotal:
          subscriptionTrafficTotal ?? this.subscriptionTrafficTotal,
      subscriptionTrafficUsed:
          subscriptionTrafficUsed ?? this.subscriptionTrafficUsed,
    );
  }

  String get displayName =>
      username ?? firstName ?? telegramId.toString();

  bool get hasActiveSubscription => subscriptionValidUntil == null
      ? true
      : subscriptionValidUntil!.isAfter(DateTime.now());

  Duration? get remainingSubscriptionDuration =>
      subscriptionValidUntil?.difference(DateTime.now());

  double? get subscriptionUsageRatio {
    if (subscriptionTrafficTotal == null ||
        subscriptionTrafficTotal == 0 ||
        subscriptionTrafficUsed == null) {
      return null;
    }
    final ratio = subscriptionTrafficUsed! / subscriptionTrafficTotal!;
    return ratio.clamp(0, 1).toDouble();
  }

  int? get subscriptionTrafficRemaining {
    if (subscriptionTrafficTotal == null || subscriptionTrafficUsed == null) {
      return null;
    }
    final remaining = subscriptionTrafficTotal! - subscriptionTrafficUsed!;
    return remaining < 0 ? 0 : remaining;
  }
}
