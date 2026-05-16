import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/repositories/exercise_repository.dart';

class _FakeHttpResult {
  _FakeHttpResult({required this.statusCode, required this.body});

  final int statusCode;
  final dynamic body;
}

typedef _ApiResponder = _FakeHttpResult Function(String method, Uri url);

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.responder);
  final _ApiResponder responder;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _FakeHttpClientRequest(method, url, responder);
  }

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this.method, this.uri, this.responder);
  @override
  final String method;
  @override
  final Uri uri;
  final _ApiResponder responder;
  final _FakeHttpHeaders _headers = _FakeHttpHeaders();

  @override
  HttpHeaders get headers => _headers;

  @override
  Future<HttpClientResponse> close() async {
    final response = responder(method, uri);
    return _FakeHttpClientResponse(response.statusCode, response.body);
  }

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = true;

  @override
  int contentLength = -1;

  @override
  Encoding encoding = utf8;

  @override
  void write(Object? obj) {}
  @override
  void writeln([Object? obj = '']) {}
  @override
  void add(List<int> data) {}
  @override
  Future<void> addStream(Stream<List<int>> stream) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = {};
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name] = [value.toString()];
  }

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse(this.statusCode, dynamic responseBody)
      : _bytes = utf8.encode(jsonEncode(responseBody));

  final List<int> _bytes;
  @override
  final int statusCode;

  @override
  int get contentLength => _bytes.length;

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => '';

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  List<Cookie> get cookies => const [];

  @override
  Future<Socket> detachSocket() {
    throw UnimplementedError();
  }

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_bytes]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<T> runWithFakeHttp<T>(
      Future<T> Function() action, _ApiResponder responder) {
    return HttpOverrides.runZoned(
      action,
      createHttpClient: (context) => _FakeHttpClient(responder),
    );
  }

  group('ExerciseRepository Tests', () {
    setUp(() {
      ExerciseRepository.clearCache();
    });

    test('UTC-064 Returns nothing when exercise cannot be found anywhere',
        () async {
      final exercise = await runWithFakeHttp(
        () => ExerciseRepository.getExerciseById(999),
        (method, url) {
          // Always return 404 for both local ExerciseDb and remote ExerciseService
          return _FakeHttpResult(statusCode: 404, body: {});
        },
      );

      expect(exercise, isNull);
    });

    test('getExerciseById returns normalized local exercise when found in DB', () async {
      final fakeLocalRow = {
        'exer_id': 1,
        'exer_name': 'Squat',
        'exer_type': 'strength',
        'exer_body_area': 'legs',
        'exer_descrip': 'A basic squat',
        'exer_vid': 'http://vid',
        'exer_equip': 'Barbell, Dumbbell',
      };

      final exercise = await runWithFakeHttp(
        () => ExerciseRepository.getExerciseById(1),
        (method, url) {
          if (url.path.endsWith('/exercises/1')) {
            return _FakeHttpResult(statusCode: 200, body: fakeLocalRow);
          }
          return _FakeHttpResult(statusCode: 404, body: {});
        },
      );

      expect(exercise, isNotNull);
      expect(exercise!['id'], 1);
      expect(exercise['name'], 'Squat');
      expect(exercise['equipment'], ['Barbell', 'Dumbbell']);
      expect(exercise['meta']['source'], 'local');
    });

    test('getExerciseById falls back to remote when local returns null/404', () async {
      final fakeRemoteRow = {
        'id': 2,
        'name': 'Deadlift',
        'type': 'strength',
        'area': 'back',
        'description': 'A basic deadlift',
        'video': 'http://vid2',
        'equipment': ['Barbell'],
      };

      bool firstCall = true;
      final exercise = await runWithFakeHttp(
        () => ExerciseRepository.getExerciseById(2),
        (method, url) {
          if (url.path.endsWith('/exercises/2')) {
            if (firstCall) {
              firstCall = false;
              return _FakeHttpResult(statusCode: 404, body: {}); // Local fails
            }
            return _FakeHttpResult(statusCode: 200, body: fakeRemoteRow); // Remote succeeds
          }
          return _FakeHttpResult(statusCode: 404, body: {});
        },
      );

      expect(exercise, isNotNull);
      expect(exercise!['id'], 2);
      expect(exercise['name'], 'Deadlift');
      expect(exercise['meta']['source'], 'remote');
    });

    test('listExercises caches results and clearCache / invalidateCache work', () async {
      int apiCallCount = 0;
      final fakeList = [
        {
          'exer_id': 10,
          'exer_name': 'Pushup',
          'exer_type': 'strength',
          'exer_body_area': 'chest',
          'exer_equip': 'None',
        }
      ];

      _FakeHttpResult responder(String method, Uri url) {
        apiCallCount++;
        return _FakeHttpResult(statusCode: 200, body: fakeList);
      }

      // First call should hit API
      final res1 = await runWithFakeHttp(
        () => ExerciseRepository.listExercises(name: 'Pushup'),
        responder,
      );
      expect(res1.length, 1);
      expect(apiCallCount, 1);

      // Second call with same params should hit cache
      final res2 = await runWithFakeHttp(
        () => ExerciseRepository.listExercises(name: 'Pushup'),
        responder,
      );
      expect(res2.length, 1);
      expect(apiCallCount, 1);

      // Call with forceRefresh should hit API
      final res3 = await runWithFakeHttp(
        () => ExerciseRepository.listExercises(name: 'Pushup', forceRefresh: true),
        responder,
      );
      expect(res3.length, 1);
      expect(apiCallCount, 3); // local then remote

      // invalidateCache should remove specific key
      ExerciseRepository.invalidateCache(name: 'Pushup');
      final res4 = await runWithFakeHttp(
        () => ExerciseRepository.listExercises(name: 'Pushup'),
        responder,
      );
      expect(apiCallCount, 4);

      // clearCache should clear everything
      await runWithFakeHttp(() => ExerciseRepository.listExercises(name: 'Pushup'), responder);
      ExerciseRepository.clearCache();
      await runWithFakeHttp(() => ExerciseRepository.listExercises(name: 'Pushup'), responder);
      expect(apiCallCount, 5);
    });

    test('listExercises with ids fetches local exercises by ID', () async {
      final row10 = {'exer_id': 10, 'exer_name': 'Pushup', 'exer_equip': ''};
      final row20 = {'exer_id': 20, 'exer_name': 'Pullup', 'exer_equip': 'Bar'};

      final results = await runWithFakeHttp(
        () => ExerciseRepository.listExercises(ids: [10, 20, 99]),
        (method, url) {
          if (url.path.endsWith('/exercises/10')) {
            return _FakeHttpResult(statusCode: 200, body: row10);
          }
          if (url.path.endsWith('/exercises/20')) {
            return _FakeHttpResult(statusCode: 200, body: row20);
          }
          return _FakeHttpResult(statusCode: 404, body: {});
        },
      );

      expect(results.length, 2);
      expect(results[0]['name'], 'Pushup');
      expect(results[1]['name'], 'Pullup');
      expect(results[1]['equipment'], ['Bar']);
    });

    test('listExercises sorts by recommendationTags score', () async {
      final fakeList = [
        {
          'exer_id': 1,
          'exer_name': 'Running Fast',
          'exer_type': 'cardio',
          'exer_body_area': 'legs',
          'exer_equip': 'Shoes',
        },
        {
          'exer_id': 2,
          'exer_name': 'Bench Press',
          'exer_type': 'strength',
          'exer_body_area': 'chest',
          'exer_equip': 'Barbell',
        },
      ];

      final results = await runWithFakeHttp(
        () => ExerciseRepository.listExercises(
          recommendationTags: ['chest', 'barbell', 'bench'],
        ),
        (method, url) => _FakeHttpResult(statusCode: 200, body: fakeList),
      );

      expect(results.length, 2);
      expect(results[0]['name'], 'Bench Press');
      expect(results[0]['meta']['recommendationScore'], 3.0);
      expect(results[1]['name'], 'Running Fast');
      expect(results[1]['meta']['recommendationScore'], 0.0);
    });
  });
}
