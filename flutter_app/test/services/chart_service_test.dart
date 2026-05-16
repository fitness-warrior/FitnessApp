import 'dart:convert';
import 'package:fitness_app_flutter/services/chart_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../helpers/http_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(secureStorageChannel, (call) async {
      if (call.method == 'read') return 'fake_token';
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(secureStorageChannel, null);
    HttpOverrides.global = null;
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
      HttpOverrides.global = FakeHttpOverrides((req) async {
        return FakeHttpClientResponse(200, '');
      });
      await ChartService.hideChart('test@test.com', 'Chart', 'Measure');
    });

    test('getHiddenCharts', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        return FakeHttpClientResponse(200, jsonEncode([
          {'chart_name': 'My Chart', 'option': 'Weight'}
        ]));
      });
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
      HttpOverrides.global = FakeHttpOverrides((req) async {
        return FakeHttpClientResponse(200, jsonEncode({
          'Bench Press': [['2023-01-01', 50.0], ['2023-01-02', 55.0]]
        }));
      });
      final progress = await ChartService.getAllExercisesProgress();
      expect(progress.containsKey('Bench Press'), isTrue);
      expect(progress['Bench Press']?.first[1], 50.0);
    });

    test('unhideChart success and failure handling', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        if (req.uri.path.contains('hidden-charts')) {
          return FakeHttpClientResponse(200, '');
        }
        return FakeHttpClientResponse(500, 'Error');
      });
      await ChartService.unhideChart('test@test.com', 'Chart', 'Option');
    });

    test('isChartHidden returns correct boolean', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async { 
        return FakeHttpClientResponse(200, jsonEncode([
          {'chart_name': 'Bench Press', 'option': '1RM'}
        ]));
      });
      final hidden = await ChartService.isChartHidden('test@test.com', 'Bench Press', '1RM');
      expect(hidden, isTrue);
      final notHidden = await ChartService.isChartHidden('test@test.com', 'Squat', '1RM');
      expect(notHidden, isFalse);
    });

    test('getBodyId success and failure', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        if (req.uri.path.endsWith('/users/profile')) {
          return FakeHttpClientResponse(200, jsonEncode({'body_id': 10}));
        }
        return FakeHttpClientResponse(500, '');
      });
      final bodyId = await ChartService.getBodyId();
      expect(bodyId, 10);
    });

    test('getWorkoutVolume success and failure', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        if (req.uri.path.contains('workout-volume')) {
          return FakeHttpClientResponse(200, jsonEncode([
            {'date': '2023-05-01', 'total_kg': 1500.5, 'id': 1},
            'InvalidItem'
          ]));
        }
        return FakeHttpClientResponse(500, '');
      });
      final volume = await ChartService.getWorkoutVolume();
      expect(volume.length, 2);
      expect(volume[0][0], '2023-05-01');
      expect(volume[0][1], 1500.5);
      expect(volume[0][2], 1);
      expect(volume[1][0], 'InvalidItem');
      expect(volume[1][1], 0.0);
    });

    test('getCardioSpeed success and non-200', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        if (req.uri.path.contains('cardio-speed')) {
          return FakeHttpClientResponse(200, jsonEncode(['10 km/h']));
        }
        return FakeHttpClientResponse(404, '');
      });
      final speed = await ChartService.getCardioSpeed('Running', 1);
      expect(speed, ['10 km/h']);
    });

    test('getCardioEndurance success', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        return FakeHttpClientResponse(200, jsonEncode(['30 mins']));
      });
      final end = await ChartService.getCardioEndurance('Running', 1);
      expect(end, ['30 mins']);
    });

    test('getWeight success', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        return FakeHttpClientResponse(200, jsonEncode([75.0, 74.5]));
      });
      final weight = await ChartService.getWeight(1);
      expect(weight, [75.0, 74.5]);
    });

    test('getBodyType success', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        return FakeHttpClientResponse(200, jsonEncode(['Mesomorph']));
      });
      final type = await ChartService.getBodyType(1);
      expect(type, ['Mesomorph']);
    });

    test('getChartOptions success', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        return FakeHttpClientResponse(200, jsonEncode([
          {'name': 'Volume', 'measure': ['kg', 'lbs']}
        ]));
      });
      final options = await ChartService.getChartOptions(1);
      expect(options.length, 1);
      expect(options[0].name, 'Volume');
      expect(options[0].measure, ['kg', 'lbs']);
    });

    test('getTodayExercises success', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        return FakeHttpClientResponse(200, jsonEncode(['Squat', 'Bench Press']));
      });
      final today = await ChartService.getTodayExercises();
      expect(today, ['Squat', 'Bench Press']);
    });

    test('getStrengthTotal success', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        return FakeHttpClientResponse(200, jsonEncode([100, 110]));
      });
      final strength = await ChartService.getStrengthTotal('Bench Press', 1);
      expect(strength, [100, 110]);
    });

    test('getTotalVolume success', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        return FakeHttpClientResponse(200, jsonEncode([5000, 5200]));
      });
      final vol = await ChartService.getTotalVolume(1);
      expect(vol, [5000, 5200]);
    });

    test('getDailyCardioCalories success', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        return FakeHttpClientResponse(200, jsonEncode([300, 450]));
      });
      final cal = await ChartService.getDailyCardioCalories(1);
      expect(cal, [300, 450]);
    });

    test('Exception and error handling for endpoints', () async {
      HttpOverrides.global = FakeHttpOverrides((req) async {
        return FakeHttpClientResponse(500, 'Server Error');
      });
      expect(await ChartService.getCardioSpeed('Run', 1), isEmpty);
      expect(await ChartService.getCardioEndurance('Run', 1), isEmpty);
      expect(await ChartService.getWeight(1), isEmpty);
      expect(await ChartService.getBodyType(1), isEmpty);
      expect(await ChartService.getChartOptions(1), isEmpty);
      expect(await ChartService.getTodayExercises(), isEmpty);
      expect(await ChartService.getStrengthTotal('Squat', 1), isEmpty);
      expect(await ChartService.getTotalVolume(1), isEmpty);
      expect(await ChartService.getDailyCardioCalories(1), isEmpty);
      expect(await ChartService.getBodyId(), 0);
      expect(await ChartService.getWorkoutVolume(), isEmpty);
      expect(await ChartService.getAllExercisesProgress(), isEmpty);
      expect(await ChartService.getHiddenCharts(), isEmpty);
    });

    test('pythonBaseUrl returns correct URL per platform', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(ChartService.pythonBaseUrl, 'http://10.0.2.2:8000');
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      expect(ChartService.pythonBaseUrl, 'http://localhost:8000');
    });
  });
}
