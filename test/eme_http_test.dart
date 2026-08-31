import 'package:dio/dio.dart';
import 'package:eme_app_package/eme_http.dart';
import 'package:eme_app_package/services/topic_service.dart';
import 'package:eme_app_package/testing/fake_eme_http.dart';
import 'package:flutter_test/flutter_test.dart';

/// Internal-seam fake: captures what DioEmeHttp actually puts on the wire.
class CapturingAdapter implements HttpClientAdapter {
  RequestOptions? last;
  int status = 200;
  String body = '{}';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeSession implements EmeSession {
  @override
  String? token = 't1';
  @override
  String? userId = 'u1';
}

void main() {
  late CapturingAdapter adapter;
  late DioEmeHttp http;

  setUp(() {
    adapter = CapturingAdapter();
    http = DioEmeHttp(
      dio: () => Dio()..httpClientAdapter = adapter,
      session: FakeSession(),
      baseUrl: () => 'https://em.example.org/mediadb',
    );
  });

  test('token auth sends X- headers and percent-encodes query values',
      () async {
    await http.getJson('services/x.json', query: {'q': 'a&b=c d'});
    final r = adapter.last!;
    expect(
      r.uri.toString(),
      'https://em.example.org/mediadb/services/x.json?q=a%26b%3Dc+d',
    );
    expect(r.headers['X-tokentype'], 'entermedia');
    expect(r.headers['X-token'], 't1');
  });

  test('EmeAuth.none sends no auth headers; keyAndUser sends the legacy pair',
      () async {
    await http.getJson('a.json', auth: EmeAuth.none);
    expect(adapter.last!.headers.keys.where((k) => k.startsWith('X-')), isEmpty);

    await http.getJson('a.json', auth: EmeAuth.keyAndUser);
    expect(adapter.last!.headers['X-entermediakey'], 't1');
    expect(adapter.last!.headers['X-userid'], 'u1');
    expect(adapter.last!.headers.containsKey('X-token'), isFalse);
  });

  test('postForm form-encodes fields (repeats kept, values escaped)',
      () async {
    await http.postForm('continue.json', [
      const MapEntry('field', 'a'),
      const MapEntry('field', 'b'),
      const MapEntry('context_query', '5 & 5 = 10%'),
    ]);
    final r = adapter.last!;
    expect(r.method, 'POST');
    expect(r.contentType, contains('x-www-form-urlencoded'));
    expect(r.data, 'field=a&field=b&context_query=5+%26+5+%3D+10%25');
  });

  test('post: repeated query keys; files==null sends no body; multipart '
      'never forces Content-Type', () async {
    await http.post('usersave.json', query: [
      const MapEntry('field', 'a'),
      const MapEntry('field', 'b'),
    ]);
    expect(adapter.last!.uri.query, 'field=a&field=b');
    expect(adapter.last!.data, isNull);

    await http.post('usersave.json', files: [
      MapEntry('file.assetportrait', MultipartFile.fromString('img')),
    ]);
    expect(adapter.last!.data, isA<FormData>());
  });

  test('non-200 throws EmeHttpException carrying the decoded error body',
      () async {
    adapter.status = 401;
    adapter.body = '{"error_description":"expired"}';
    try {
      await http.getJson('a.json');
      fail('expected EmeHttpException');
    } on EmeHttpException catch (e) {
      expect(e.statusCode, 401);
      expect((e.body as Map)['error_description'], 'expired');
    }
  });

  test('decodes String bodies, wraps bare arrays, tolerates empty bodies',
      () async {
    adapter.body = '{"topics":[]}';
    expect(await http.getJson('a.json'), {'topics': []});

    adapter.body = '[1,2]';
    expect(await http.getJson('a.json'), {
      'data': [1, 2],
    });

    adapter.body = '';
    expect(await http.getJson('a.json'), isEmpty);
  });

  test('absolute URLs are rejected — tokens cannot leak off-workspace', () {
    expect(
      () => http.getJson('https://evil.example.com/a.json'),
      throwsAssertionError,
    );
  });

  group('TopicService through the seam', () {
    test('fetchTopics requests the topics path and parses the result',
        () async {
      final fake = FakeEmeHttp()
        ..canned['services/module/entitytopic/topics.json'] = {'topics': []};
      final topics = await TopicService(http: fake).fetchTopics();
      expect(topics, isEmpty);
      expect(
        fake.requests.single.$1,
        'services/module/entitytopic/topics.json',
      );
    });

    test('fetchTopics keeps its policy: HTTP failure → empty list', () async {
      final topics = await TopicService(http: FakeEmeHttp()).fetchTopics();
      expect(topics, isEmpty);
    });

    test('submitAnswer posts the continue.json form fields', () async {
      final fake = FakeEmeHttp()
        ..canned['services/module/entitytutorial/continue.json'] = {};
      await TopicService(http: fake).submitAnswer(
        channel: 'c1',
        questionId: 'q1',
        selectedOption: '2',
        confidence: '3',
        sectionId: 's1',
        componentId: 'k1',
      );
      final fields = (fake.requests.single.$2 as List)
          .cast<MapEntry<String, String>>();
      expect(
        fields.map((e) => '${e.key}=${e.value}'),
        contains('context_questionid=q1'),
      );
    });
  });
}
