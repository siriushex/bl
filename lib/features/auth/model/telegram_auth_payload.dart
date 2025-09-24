import 'dart:convert';

class TelegramAuthPayload {
  const TelegramAuthPayload({
    required this.id,
    required this.firstName,
    this.lastName,
    this.username,
    this.photoUrl,
    required this.authDate,
    required this.hash,
    this.authToken,
    this.queryId,
    this.phoneNumber,
  });

  final int id;
  final String firstName;
  final String? lastName;
  final String? username;
  final String? photoUrl;
  final int authDate;
  final String hash;
  final String? authToken;
  final String? queryId;
  final String? phoneNumber;

  factory TelegramAuthPayload.fromJson(Map<String, dynamic> json) {
    return TelegramAuthPayload(
      id: json['id'] is String ? int.parse(json['id'] as String) : json['id'] as int,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String?,
      username: json['username'] as String?,
      photoUrl: json['photo_url'] as String?,
      authDate: json['auth_date'] is String
          ? int.parse(json['auth_date'] as String)
          : json['auth_date'] as int,
      hash: json['hash'] as String,
      authToken: json['auth_token'] as String?,
      queryId: json['query_id'] as String?,
      phoneNumber: json['phone_number'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        if (lastName != null) 'last_name': lastName,
        if (username != null) 'username': username,
        if (photoUrl != null) 'photo_url': photoUrl,
        'auth_date': authDate,
        'hash': hash,
        if (authToken != null) 'auth_token': authToken,
        if (queryId != null) 'query_id': queryId,
        if (phoneNumber != null) 'phone_number': phoneNumber,
      };

  TelegramAuthPayload copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? username,
    String? photoUrl,
    int? authDate,
    String? hash,
    String? authToken,
    String? queryId,
    String? phoneNumber,
  }) {
    return TelegramAuthPayload(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      authDate: authDate ?? this.authDate,
      hash: hash ?? this.hash,
      authToken: authToken ?? this.authToken,
      queryId: queryId ?? this.queryId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }

  factory TelegramAuthPayload.fromEncoded(String encoded) {
    final normalized = base64Url.normalize(encoded);
    final raw = utf8.decode(base64Url.decode(normalized));
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return TelegramAuthPayload.fromJson(map);
  }

  static TelegramAuthPayload? maybeFromUri(Uri uri) {
    final encoded =
        uri.queryParameters['payload'] ?? uri.queryParameters['data'];
    if (encoded == null) return null;
    try {
      final payload = TelegramAuthPayload.fromEncoded(encoded);
      final token = uri.queryParameters['token'];
      return token == null
          ? payload
          : payload.copyWith(authToken: token.isEmpty ? null : token);
    } catch (_) {
      return null;
    }
  }

  DateTime get authenticatedAt =>
      DateTime.fromMillisecondsSinceEpoch(authDate * 1000);

  bool get isFresh =>
      DateTime.now().difference(authenticatedAt) <=
      const Duration(minutes: 5);

  String encode() =>
      base64Url.encode(utf8.encode(jsonEncode(toJson()))).replaceAll('=', '');
}
