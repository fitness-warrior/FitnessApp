import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef RequestHandler = Future<HttpClientResponse> Function(HttpClientRequest request);

class FakeHttpOverrides extends HttpOverrides {
  final RequestHandler handler;
  FakeHttpOverrides(this.handler);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return FakeHttpClient(handler);
  }
}

class FakeHttpClient implements HttpClient {
  final RequestHandler handler;
  FakeHttpClient(this.handler);
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return FakeHttpClientRequest(method, url, handler);
  }
  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl('POST', url);
  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl('DELETE', url);
  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl('PUT', url);
  @override
  void close({bool force = false}) {}
}

class FakeHttpClientRequest implements HttpClientRequest {
  final String method;
  final Uri url;
  final RequestHandler handler;
  final HttpHeaders headers = FakeHttpHeaders();
  
  FakeHttpClientRequest(this.method, this.url, this.handler);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<HttpClientResponse> close() => handler(this);
  
  @override
  void add(List<int> data) {}
  @override
  Future<void> addStream(Stream<List<int>> stream) async {}
  @override
  void write(Object? obj) {}
  @override
  bool followRedirects = true;
  @override
  int maxRedirects = 5;
  @override
  int contentLength = -1;
  @override
  Encoding encoding = utf8;
  @override
  bool persistentConnection = true;
}

class FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {};
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name] = [value.toString()];
  }
  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }
}

class FakeHttpClientResponse implements HttpClientResponse {
  final int statusCode;
  final String body;
  
  FakeHttpClientResponse(this.statusCode, this.body);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData, {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    return Stream<List<int>>.fromIterable([utf8.encode(body)]).listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
  
  @override
  int get contentLength => utf8.encode(body).length;
  @override
  HttpHeaders get headers => FakeHttpHeaders();
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
  Future<Socket> detachSocket() => throw UnimplementedError();
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;
}
