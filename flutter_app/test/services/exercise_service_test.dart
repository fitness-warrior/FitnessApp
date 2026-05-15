import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/services/exercise_service.dart';

class _FakeHttpResult {
  _FakeHttpResult({required this.statusCode, required this.body});

  final int statusCode;
  final dynamic body; // Can be List or Map
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
  _FakeHttpClientRequest(this.method, this.url, this.responder);
  final String method;
  @override
  final Uri url;
  final _ApiResponder responder;
  final _FakeHttpHeaders _headers = _FakeHttpHeaders();

  @override
  HttpHeaders get headers => _headers;

  @override
  Future<HttpClientResponse> close() async {
    final response = responder(method, url);
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

  group('ExerciseService Tests', () {
    test('ExerciseService base URL is configured', () {
      final baseUrl = ExerciseService.baseUrl;
      expect(baseUrl, isNotEmpty);
      expect(baseUrl, isA<String>());
    });

    test('UTC-055 Exercise data mapped to correct field names', () async {
      final rawResponse = [
        {
          'id': 5,
          'name': 'Pull-up',
          'area': 'Back',
          'type': 'strength',
          'description': 'Upper body pulling exercise',
          'equipment': ['pullup bar']
        },
      ];

      final exercises = await runWithFakeHttp(
        () => ExerciseService.listExercises(),
        (method, url) {
          return _FakeHttpResult(statusCode: 200, body: rawResponse);
        },
      );

      expect(exercises.length, equals(1));
      expect(exercises[0]['exer_id'], equals(5));
      expect(exercises[0]['exer_name'], equals('Pull-up'));
      expect(exercises[0]['exer_body_area'], equals('Back'));
      expect(exercises[0]['exer_type'], equals('strength'));
      expect(exercises[0]['exer_descrip'], equals('Upper body pulling exercise'));
    });

    test('UTC-056 Equipment list is formatted correctly', () async {
      final rawResponse = {
        'id': 1,
        'name': 'Circuit Training',
        'equipment': ['Dumbbell', 'Barbell', 'Rope'],
      };

      final exercise = await runWithFakeHttp(
        () => ExerciseService.getExercise(1),
        (method, url) {
          return _FakeHttpResult(statusCode: 200, body: rawResponse);
        },
      );

      expect(exercise['exer_equip'], equals('Dumbbell, Barbell, Rope'));
    });
  });
}
