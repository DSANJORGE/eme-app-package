import 'package:dio/dio.dart';

import '../eme_http.dart';

/// Test fake at the EmeHttp seam: services (and app screens) are tested
/// through this, so they survive any DioEmeHttp refactor.
///
/// Canned responses are keyed by path; unknown paths throw a 404
/// [EmeHttpException]. Every call is recorded in [requests] as
/// (path, query/fields); form posts additionally land in [posted] with
/// their fields already collapsed to a map, which is what most assertions
/// want.
class FakeEmeHttp implements EmeHttp {
  final requests = <(String, Object?)>[];

  /// Every [postForm] call, recorded before the canned lookup so failed
  /// posts show up too.
  final posted = <({String path, Map<String, String> fields})>[];
  final canned = <String, Map<String, dynamic>>{};

  Map<String, dynamic> _lookup(String path, Object? detail) {
    requests.add((path, detail));
    final r = canned[path];
    if (r == null) {
      throw EmeHttpException(uri: Uri.parse(path), statusCode: 404);
    }
    return r;
  }

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String> query = const {},
    EmeAuth auth = EmeAuth.token,
  }) async => _lookup(path, query);

  @override
  Future<Map<String, dynamic>> postForm(
    String path,
    Iterable<MapEntry<String, String>> fields, {
    EmeAuth auth = EmeAuth.token,
  }) async {
    final list = fields.toList();
    posted.add((path: path, fields: Map.fromEntries(list)));
    return _lookup(path, list);
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Iterable<MapEntry<String, String>> query = const [],
    List<MapEntry<String, MultipartFile>>? files,
    EmeAuth auth = EmeAuth.token,
  }) async => _lookup(path, query.toList());
}
