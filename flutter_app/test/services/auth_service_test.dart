import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:fitness_app_flutter/services/auth_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeHttpResult {
  _FakeHttpResult({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;
}

typedef _AuthResponder = _FakeHttpResult Function(
  String method,
  Uri url,
  String body,
);

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.responder);

  final _AuthResponder responder;

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

  @override
  final String method;
  final Uri url;
  final _AuthResponder responder;
  final BytesBuilder _bytes = BytesBuilder();
  final _FakeHttpHeaders _headers = _FakeHttpHeaders();

  @override
  HttpHeaders get headers => _headers;

  @override
  void add(List<int> data) {
    _bytes.add(data);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      add(chunk);
    }
  }

  @override
  Future<HttpClientResponse> close() async {
    final response = responder(method, url, utf8.decode(_bytes.takeBytes()));
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
  void write(Object? obj) {
    add(encoding.encode(obj.toString()));
  }

  @override
  void writeln([Object? obj = '']) {
    write('$obj\n');
  }

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
  _FakeHttpClientResponse(this.statusCode, Map<String, dynamic> responseBody)
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
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  final secureStorage = <String, String?>{};
  int signupStatusCode = 201;
  Map<String, dynamic> signupResponse = {};
  int loginStatusCode = 200;
  Map<String, dynamic> loginResponse = {};

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(secureStorageChannel, (call) async {
      switch (call.method) {
        case 'write':
          secureStorage[call.arguments['key'] as String] =
              call.arguments['value'] as String?;
          return null;
        case 'read':
          return secureStorage[call.arguments['key'] as String];
        case 'delete':
          secureStorage.remove(call.arguments['key'] as String);
          return null;
        default:
          return null;
      }
    });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(secureStorageChannel, null);
  });

  setUp(() {
    secureStorage.clear();
    signupStatusCode = 201;
    signupResponse = {
      'access_token': 'token_abc123',
      'user': {
        'id': 1,
        'email': 'user@test.com',
        'username': 'testuser',
      },
    };
    loginStatusCode = 200;
    loginResponse = {
      'access_token': 'session_token_xyz',
      'user': {
        'id': 2,
        'email': 'user@test.com',
      },
    };
  });

  Future<T> runWithFakeHttp<T>(Future<T> Function() action) {
    return HttpOverrides.runZoned(
      action,
      createHttpClient: (context) => _FakeHttpClient(
        (method, url, body) {
          if (url.path == '/api/auth/signup' && method == 'POST') {
            return _FakeHttpResult(
              statusCode: signupStatusCode,
              body: signupResponse,
            );
          }
          if (url.path == '/api/auth/login' && method == 'POST') {
            return _FakeHttpResult(
              statusCode: loginStatusCode,
              body: loginResponse,
            );
          }
          return _FakeHttpResult(
            statusCode: 404,
            body: {'detail': 'Not found'},
          );
        },
      ),
    );
  }

  group('AuthService', () {
    test('UTC-001 registration saves login details on success', () async {
      final result = await runWithFakeHttp(
        () => AuthService.signup(
          email: 'user@test.com',
          username: 'testuser',
          password: 'Password123!',
        ),
      );

      expect(result['success'], isTrue);
      expect(result['user']['email'], equals('user@test.com'));
      expect(secureStorage['auth_token'], equals('token_abc123'));
      expect(secureStorage['current_user'], isNotNull);

      final savedUser =
          jsonDecode(secureStorage['current_user']!) as Map<String, dynamic>;
      expect(savedUser['username'], equals('testuser'));
    });

    test('UTC-002 registration shows server error when details are invalid',
        () async {
      signupStatusCode = 400;
      signupResponse = {'detail': 'Email already registered'};

      await expectLater(
        () => runWithFakeHttp(
          () => AuthService.signup(
            email: 'taken@test.com',
            username: 'takenuser',
            password: 'Password123!',
          ),
        ),
        throwsA(
          predicate(
            (error) => error.toString().contains('Email already registered'),
          ),
        ),
      );

      expect(secureStorage['auth_token'], isNull);
      expect(secureStorage['current_user'], isNull);
    });

    test('UTC-003 registration fails cleanly when the server has an error',
        () async {
      signupStatusCode = 500;
      signupResponse = {'detail': 'Internal server error'};

      await expectLater(
        () => runWithFakeHttp(
          () => AuthService.signup(
            email: 'user@test.com',
            username: 'testuser',
            password: 'Password123!',
          ),
        ),
        throwsA(
          predicate(
            (error) => error.toString().contains('Error during signup'),
          ),
        ),
      );

      expect(secureStorage, isEmpty);
    });

    test('UTC-004 login saves session details on success', () async {
      final result = await runWithFakeHttp(
        () => AuthService.login(
          email: 'user@test.com',
          password: 'Password123!',
        ),
      );

      expect(result['success'], isTrue);
      expect(result['user']['id'], equals(2));
      expect(await AuthService.getToken(), equals('session_token_xyz'));
      expect(await AuthService.isLoggedIn(), isTrue);

      final currentUser = await AuthService.getCurrentUser();
      expect(currentUser, isNotNull);
      expect(currentUser!['email'], equals('user@test.com'));
    });

    test('UTC-005 login fails with wrong email or password', () async {
      loginStatusCode = 401;
      loginResponse = {'detail': 'Invalid email or password'};

      await expectLater(
        () => runWithFakeHttp(
          () => AuthService.login(
            email: 'wrong@test.com',
            password: 'wrong-password',
          ),
        ),
        throwsA(
          predicate(
            (error) => error.toString().contains('Invalid email or password'),
          ),
        ),
      );
    });

    test('UTC-006 login fails when account does not exist', () async {
      loginStatusCode = 404;
      loginResponse = {'detail': 'User not found'};

      await expectLater(
        () => runWithFakeHttp(
          () => AuthService.login(
            email: 'missing@test.com',
            password: 'Password123!',
          ),
        ),
        throwsA(
          predicate((error) => error.toString().contains('User not found')),
        ),
      );
    });

    test('UTC-007 app retrieves saved login session', () async {
      secureStorage['auth_token'] = 'saved_session_token_abc';

      final token = await AuthService.getToken();

      expect(token, equals('saved_session_token_abc'));
    });

    test('UTC-008 app finds no session when user has not logged in', () async {
      final token = await AuthService.getToken();

      expect(token, isNull);
    });

    test('UTC-009 app correctly identifies user as logged in', () async {
      secureStorage['auth_token'] = 'valid_token_123';

      final loggedIn = await AuthService.isLoggedIn();

      expect(loggedIn, isTrue);
    });

    test('UTC-010 app correctly identifies user as not logged in', () async {
      final loggedIn = await AuthService.isLoggedIn();

      expect(loggedIn, isFalse);
    });

    test('UTC-011 logging out removes all saved session data', () async {
      secureStorage['auth_token'] = 'old_token';
      secureStorage['current_user'] = '{"id":1,"email":"user@test.com"}';

      await AuthService.logout();

      expect(secureStorage['auth_token'], isNull);
      expect(secureStorage['current_user'], isNull);
    });

    test('UTC-012 app sends login session with requests when logged in',
        () async {
      secureStorage['auth_token'] = 'bearer_token_abc';

      final headers = await AuthService.getAuthHeaders();

      expect(headers['Authorization'], equals('Bearer bearer_token_abc'));
      expect(headers['Content-Type'], equals('application/json'));
    });

    test('UTC-013 app sends requests without session when not logged in',
        () async {
      final headers = await AuthService.getAuthHeaders();

      expect(headers.containsKey('Authorization'), isFalse);
      expect(headers['Content-Type'], equals('application/json'));
    });
  });
}
