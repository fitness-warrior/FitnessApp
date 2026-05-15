import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fitness_app_flutter/services/chart_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  HttpServer? server;
  
  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(secureStorageChannel, (call) async {
      if (call.method == 'read') return 'fake_token';
      return null;
    });
    try {
      server = await HttpServer.bind('127.0.0.1', 8000);
      server!.listen((HttpRequest request) async {
        await request.toList(); // Consume request body
        final response = request.response;
        print('MOCK SERVER GOT: ${request.uri.path}');
        response.headers.contentType = ContentType.json;
        
        if (request.uri.path == '/api/user/hidden-charts') {
          if (request.method == 'GET') {
            response.write(jsonEncode([
              {'chart_name': 'My Chart', 'option': 'Weight'}
            ]));
          } else {
            response.write('');
          }
        } else if (request.uri.path == '/api/users/profile') {
          response.write(jsonEncode({'body_id': 123}));
        } else if (request.uri.path == '/api/user/exercises-progress') {
          response.write(jsonEncode({
            'Bench Press': [['2023-01-01', 50.0], ['2023-01-02', 55.0]]
          }));
        } else {
          response.write('[]');
        }
        await response.close();
      });
    } catch (e) {
      print('Could not bind server: $e');
    }
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(secureStorageChannel, null);
    await server?.close(force: true);
    server = null;
    debugDefaultTargetPlatformOverride = null;
  });

  group('ChartService - SharedPreferences', () {
    test('saveChart and getSavedCharts', () async {
      await ChartService.saveChart('test@test.com', 1, 'My Chart', 'Weight');
      final charts = await ChartService.getSavedCharts('test@test.com');
      expect(charts.length, 1);
      expect(charts[0]['name'], 'My Chart');
      expect(charts[0]['measure'], 'Weight');
    });

    test('deleteChart', () async {
      await ChartService.saveChart('test@test.com', 1, 'My Chart', 'Weight');
      await ChartService.deleteChart('test@test.com', 'My Chart', 'Weight');
      final charts = await ChartService.getSavedCharts('test@test.com');
      expect(charts.isEmpty, isTrue);
    });
  });

  group('ChartService - HTTP Calls', () {
    test('hideChart', () async {
      print('PYTHON URL: ${ChartService.pythonBaseUrl}');
      await ChartService.hideChart('test@test.com', 'Chart', 'Measure');
    });

    test('getHiddenCharts', () async {
      final hidden = await ChartService.getHiddenCharts();
      expect(hidden, {'My Chart|Weight'});
    });

    test('extractValues', () {
      final data = [
        ['2023-01-01', 50.5, 1],
        ['2023-01-02', 51.0, 2]
      ];
      final values = ChartService.extractValues(data);
      expect(values, [50.5, 51.0]);
    });
    
    test('getAllExercisesProgress', () async {
      final progress = await ChartService.getAllExercisesProgress();
      expect(progress.containsKey('Bench Press'), isTrue);
      expect(progress['Bench Press']?.first[1], 50.0);
    });
  });
}
