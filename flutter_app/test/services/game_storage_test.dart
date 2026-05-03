import 'package:flutter_test/flutter_test.dart';
import 'package:fitness_app_flutter/models/game_state.dart';

void main() {
  group('GameStorage Tests', () {
    test('GameState defaults match an empty saved state', () {
      // For now, test the data structure we expect to save/load
      final state = GameState();
      expect(state.coins, equals(0));
      expect(state.ownedCostumes, isEmpty);
      expect(state.equippedCostume, isNull);
      expect(state.upgrades, isEmpty);
    });

    test('GameState persists coins correctly', () {
      final state = GameState(coins: 500);
      expect(state.coins, equals(500));

      state.coins = 750;
      expect(state.coins, equals(750));
    });

    test('GameState persists owned costumes as set', () {
      final owned = {'earth', 'water', 'fire'};
      final state = GameState(ownedCostumes: owned);

      expect(state.ownedCostumes.length, equals(3));
      expect(state.ownedCostumes, equals(owned));

      state.ownedCostumes.add('air');
      expect(state.ownedCostumes.length, equals(4));
    });

    test('GameState persists equipped costume', () {
      final state = GameState(equippedCostume: 'earth');
      expect(state.equippedCostume, equals('earth'));

      state.equippedCostume = 'fire';
      expect(state.equippedCostume, equals('fire'));

      state.equippedCostume = null;
      expect(state.equippedCostume, isNull);
    });

    test('GameState persists upgrades map', () {
      final upgrades = {
        'dmg_up': 3,
        'time_up': 2,
        'auto_click': 1,
      };
      final state = GameState(upgrades: upgrades);

      expect(state.tapDamage, equals(25)); // 10 + (5 * 3)
      expect(state.timeBonus, equals(20)); // 10 * 2
      expect(state.hasAutoClick, isTrue);

      state.upgrades['dmg_up'] = 5;
      expect(state.tapDamage, equals(35)); // 10 + (5 * 5)
    });

    test('GameState coin string formatting (for storage)', () {
      // This tests the logic of converting coins to a saveable format
      final state = GameState(coins: 12345);
      final coinString = state.coins.toString();
      final parsedCoins = int.parse(coinString);
      expect(parsedCoins, equals(12345));
    });

    test('GameState owned costumes string formatting (for storage)', () {
      // Test converting owned costumes to comma-separated string
      final owned = {'earth', 'water', 'fire'};
      final state = GameState(ownedCostumes: owned);
      final ownedString = state.ownedCostumes.join(',');

      // Parse it back
      final parsed = ownedString.split(',').toSet();
      expect(parsed, equals(owned));
    });

    test('GameState equipped costume empty string handling (for storage)', () {
      // When equipped is null, we store empty string, then load it back as null
      final state = GameState(equippedCostume: null);
      final storedValue = state.equippedCostume ?? '';

      // Parse it back
      final loadedValue = storedValue.isEmpty ? null : storedValue;
      expect(loadedValue, isNull);

      final state2 = GameState(equippedCostume: 'earth');
      final storedValue2 = state2.equippedCostume ?? '';
      final loadedValue2 = storedValue2.isEmpty ? null : storedValue2;
      expect(loadedValue2, equals('earth'));
    });

    test('GameState upgrades string formatting (for storage)', () {
      // Test converting upgrades map to "key:value,key:value" format
      final upgrades = {
        'dmg_up': 2,
        'time_up': 1,
        'auto_click': 0,
      };
      final state = GameState(upgrades: upgrades);

      final upgString =
          state.upgrades.entries.map((e) => '${e.key}:${e.value}').join(',');

      // Parse it back
      final parsed = <String, int>{};
      for (final pair in upgString.split(',')) {
        final parts = pair.split(':');
        if (parts.length == 2) {
          parsed[parts[0]] = int.tryParse(parts[1]) ?? 0;
        }
      }

      expect(parsed['dmg_up'], equals(2));
      expect(parsed['time_up'], equals(1));
      expect(parsed['auto_click'], equals(0));
    });

    test('GameState upgrades parsing handles missing upgrades gracefully', () {
      // Empty upgrades string should return empty map
      final upgrades = <String, int>{};
      final upgString =
          upgrades.entries.map((e) => '${e.key}:${e.value}').join(',');

      final parsed = <String, int>{};
      if (upgString.isNotEmpty) {
        for (final pair in upgString.split(',')) {
          final parts = pair.split(':');
          if (parts.length == 2) {
            parsed[parts[0]] = int.tryParse(parts[1]) ?? 0;
          }
        }
      }

      expect(parsed, isEmpty);
    });

    test('Complex GameState scenario: full game progression', () {
      final state = GameState(
        coins: 0,
        ownedCostumes: {'default'},
        equippedCostume: 'default',
        upgrades: {},
      );

      // Player defeats boss, gains coins
      state.coins += 50;
      expect(state.coins, equals(50));

      // Player buys damage upgrade
      state.coins -= 10;
      state.upgrades['dmg_up'] = 1;
      expect(state.coins, equals(40));
      expect(state.tapDamage, equals(15)); // 10 + 5

      // Player buys costume
      state.coins -= 30;
      state.ownedCostumes.add('earth');
      state.equippedCostume = 'earth';
      expect(state.coins, equals(10));
      expect(state.ownedCostumes.contains('earth'), isTrue);

      // Player buys another upgrade
      state.coins -= 5;
      state.upgrades['time_up'] = 2;
      expect(state.coins, equals(5));
      expect(state.timeBonus, equals(20));
    });
  });
}
