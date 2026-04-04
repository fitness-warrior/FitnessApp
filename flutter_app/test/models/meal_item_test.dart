import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/models/meal_item.dart';

void main() {
  group('MealItem Model Tests', () {
    test('MealItem initializes with all fields', () {
      const item = MealItem(
        id: 1,
        name: 'Chicken Breast',
        type: 'Protein',
        calories: 165.5,
      );

      expect(item.id, equals(1));
      expect(item.name, equals('Chicken Breast'));
      expect(item.type, equals('Protein'));
      expect(item.calories, equals(165.5));
    });

    test('MealItem.fromMap creates instance from map', () {
      final map = {
        'id': 5,
        'name': 'Broccoli',
        'type': 'Vegetable',
        'calories': 55.0,
      };

      final item = MealItem.fromMap(map);

      expect(item.id, equals(5));
      expect(item.name, equals('Broccoli'));
      expect(item.type, equals('Vegetable'));
      expect(item.calories, equals(55.0));
    });

    test('MealItem.fromMap handles missing type field', () {
      final map = {
        'id': 3,
        'name': 'Rice',
        'calories': 130.0,
      };

      final item = MealItem.fromMap(map);

      expect(item.id, equals(3));
      expect(item.name, equals('Rice'));
      expect(item.type, isEmpty);
      expect(item.calories, equals(130.0));
    });

    test('MealItem.fromMap converts calories from int to double', () {
      final map = {
        'id': 2,
        'name': 'Apple',
        'type': 'Fruit',
        'calories': 52, // int, not double
      };

      final item = MealItem.fromMap(map);

      expect(item.calories, equals(52.0));
      expect(item.calories, isA<double>());
    });

    test('MealItem.toMap converts to map correctly', () {
      const item = MealItem(
        id: 1,
        name: 'Eggs',
        type: 'Protein',
        calories: 70.0,
      );

      final map = item.toMap();

      expect(map['id'], equals(1));
      expect(map['name'], equals('Eggs'));
      expect(map['type'], equals('Protein'));
      expect(map['calories'], equals(70.0));
    });

    test('MealItem.toString formats correctly', () {
      const item = MealItem(
        id: 1,
        name: 'Chicken',
        type: 'Protein',
        calories: 165.5,
      );

      expect(item.toString(), equals('Chicken (165 kcal)'));
    });

    test('MealItem.toString rounds down calories in display', () {
      const item = MealItem(
        id: 1,
        name: 'Salmon',
        type: 'Protein',
        calories: 280.8,
      );

      expect(item.toString(), equals('Salmon (280 kcal)'));
    });

    test('MealItem.fromMap and .toMap roundtrip', () {
      const original = MealItem(
        id: 42,
        name: 'Pizza',
        type: 'Mixed',
        calories: 285.3,
      );

      final map = original.toMap();
      final restored = MealItem.fromMap(map);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.type, equals(original.type));
      expect(restored.calories, equals(original.calories));
    });

    test('MealItem is immutable (const)', () {
      const item1 = MealItem(id: 1, name: 'Item', type: 'Type', calories: 100);
      const item2 = MealItem(id: 1, name: 'Item', type: 'Type', calories: 100);

      expect(identical(item1, item2), isTrue);
    });
  });
}
