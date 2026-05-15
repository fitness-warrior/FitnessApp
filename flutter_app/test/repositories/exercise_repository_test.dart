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
    test('UTC-064 Returns nothing when exercise cannot be found anywhere', () async {
      final exercise = await runWithFakeHttp(
        () => ExerciseRepository.getExerciseById(999),
        (method, url) {
          // Always return 404 for both local ExerciseDb and remote ExerciseService
          return _FakeHttpResult(statusCode: 404, body: {});
        },
      );

      expect(exercise, isNull);
    });
  });
}
