import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/models/game_state.dart';

void main() {
  group('GameState Model Tests', () {
    test('GameState initializes with default values', () {
      final gameState = GameState();

      expect(gameState.coins, equals(0));
      expect(gameState.ownedCostumes, isEmpty);
      expect(gameState.equippedCostume, isNull);
      expect(gameState.upgrades, isEmpty);
    });

    test('GameState initializes with provided values', () {
      final ownedCostumes = {'earth', 'water'};
      final upgrades = {'dmg_up': 2, 'time_up': 1};

      final gameState = GameState(
        coins: 100,
        ownedCostumes: ownedCostumes,
        equippedCostume: 'earth',
        upgrades: upgrades,
      );

      expect(gameState.coins, equals(100));
      expect(gameState.ownedCostumes, equals(ownedCostumes));
      expect(gameState.equippedCostume, equals('earth'));
      expect(gameState.upgrades, equals(upgrades));
    });

    test('tapDamage calculates correctly: base 10 + (5 per dmg_up)', () {
      // No upgrades
      final gameState1 = GameState();
      expect(gameState1.tapDamage, equals(10));

      // 1 dmg_up
      final gameState2 = GameState(
        upgrades: {'dmg_up': 1},
      );
      expect(gameState2.tapDamage, equals(15)); // 10 + (5 * 1)

      // 3 dmg_up
      final gameState3 = GameState(
        upgrades: {'dmg_up': 3},
      );
      expect(gameState3.tapDamage, equals(25)); // 10 + (5 * 3)
    });

    test('timeBonus calculates correctly: 10s per time_up', () {
      // No upgrades
      final gameState1 = GameState();
      expect(gameState1.timeBonus, equals(0));

      // 1 time_up
      final gameState2 = GameState(
        upgrades: {'time_up': 1},
      );
      expect(gameState2.timeBonus, equals(10)); // 10 * 1

      // 5 time_up
      final gameState3 = GameState(
        upgrades: {'time_up': 5},
      );
      expect(gameState3.timeBonus, equals(50)); // 10 * 5
    });

    test('hasAutoClick returns true when auto_click upgrade exists', () {
      final gameStateWithoutAutoClick = GameState();
      expect(gameStateWithoutAutoClick.hasAutoClick, isFalse);

      final gameStateWithAutoClick = GameState(
        upgrades: {'auto_click': 1},
      );
      expect(gameStateWithAutoClick.hasAutoClick, isTrue);
    });

    test('tapDamage and timeBonus work together correctly', () {
      final gameState = GameState(
        coins: 500,
        ownedCostumes: {'fire', 'ice'},
        equippedCostume: 'fire',
        upgrades: {
          'dmg_up': 2,
          'time_up': 3,
          'auto_click': 1,
        },
      );

      expect(gameState.tapDamage, equals(20)); // 10 + (5 * 2)
      expect(gameState.timeBonus, equals(30)); // 10 * 3
      expect(gameState.hasAutoClick, isTrue);
      expect(gameState.coins, equals(500));
    });

    test('ownedCostumes set operations work correctly', () {
      final gameState = GameState(
        ownedCostumes: {'earth', 'water'},
      );

      expect(gameState.ownedCostumes.contains('earth'), isTrue);
      expect(gameState.ownedCostumes.contains('water'), isTrue);
      expect(gameState.ownedCostumes.contains('fire'), isFalse);

      // Add a new costume
      gameState.ownedCostumes.add('fire');
      expect(gameState.ownedCostumes.contains('fire'), isTrue);
      expect(gameState.ownedCostumes.length, equals(3));
    });

    test('upgrades map can be modified', () {
      final gameState = GameState();

      gameState.upgrades['dmg_up'] = 1;
      expect(gameState.tapDamage, equals(15)); // 10 + (5 * 1)

      gameState.upgrades['dmg_up'] = 5;
      expect(gameState.tapDamage, equals(35)); // 10 + (5 * 5)

      gameState.upgrades.remove('dmg_up');
      expect(gameState.tapDamage, equals(10)); // Back to base
    });

    test('coins can be incremented and decremented', () {
      final gameState = GameState(coins: 100);

      gameState.coins += 50;
      expect(gameState.coins, equals(150));

      gameState.coins -= 25;
      expect(gameState.coins, equals(125));
    });

    test('equippedCostume can be null or a string', () {
      final gameState1 = GameState();
      expect(gameState1.equippedCostume, isNull);

      final gameState2 = GameState(equippedCostume: 'earth');
      expect(gameState2.equippedCostume, equals('earth'));

      gameState2.equippedCostume = null;
      expect(gameState2.equippedCostume, isNull);
    });
  });
}
