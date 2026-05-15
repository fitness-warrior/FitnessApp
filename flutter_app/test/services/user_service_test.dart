import 'dart:convert';
import 'dart:io';
import 'package:fitness_app_flutter/services/user_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import '../helpers/http_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(secureStorageChannel, (call) async {
      if (call.method == 'read') return 'fake_token';
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(secureStorageChannel, null);
    HttpOverrides.global = null;
  });

  group('UserService', () {
    test('saveQuestionnaireResponse', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        return FakeHttpClientResponse(201, jsonEncode({'success': true}));
      });
      final result = await UserService.saveQuestionnaireResponse({'age': 25});
      expect(result['success'], isTrue);
    });

    test('getQuestionnaireResponse', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        return FakeHttpClientResponse(200, jsonEncode({'age': 25}));
      });
      final result = await UserService.getQuestionnaireResponse();
      expect(result?['age'], 25);
    });

    test('getUserProfile', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        return FakeHttpClientResponse(200, jsonEncode({'username': 'testuser'}));
      });
      final result = await UserService.getUserProfile();
      expect(result?['username'], 'testuser');
    });

    test('updateUserProfile', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        return FakeHttpClientResponse(200, jsonEncode({'username': 'newuser'}));
      });
      final result = await UserService.updateUserProfile({'username': 'newuser'});
      expect(result['username'], 'newuser');
    });
  });
}
