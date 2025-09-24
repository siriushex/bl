import 'package:freezed_annotation/freezed_annotation.dart';

class IntervalInSecondsConverter implements JsonConverter<Duration, int> {
  const IntervalInSecondsConverter();

  @override
  Duration fromJson(int json) => Duration(seconds: json);

  @override
  int toJson(Duration object) => object.inSeconds;
}

class UriJsonConverter implements JsonConverter<Uri, String> {
  const UriJsonConverter();

  @override
  Uri fromJson(String json) => Uri.parse(json);

  @override
  String toJson(Uri object) => object.toString();
}

class NullableUriJsonConverter implements JsonConverter<Uri?, String?> {
  const NullableUriJsonConverter();

  @override
  Uri? fromJson(String? json) =>
      json == null || json.isEmpty ? null : Uri.parse(json);

  @override
  String? toJson(Uri? object) => object?.toString();
}
