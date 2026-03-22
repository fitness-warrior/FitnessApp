// lib/services/game_storage.dart
//
// Handles saving and loading the player's game state using shared_preferences.
// I'm using a simple static class with two methods: save() and load().
// No streams, no repositories — just read and write when we need to.
//
// Keys I'm using in shared_preferences:
//   game_coins          -> int
//   game_owned_costumes -> String (comma-separated, e.g. "earth,water")
//   game_equipped       -> String (or empty if nothing equipped)
//   game_active_boosts  -> String (comma-separated, e.g. "double_damage")

import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_state.dart';

class GameStorage {
  // Private constructor — don't want anyone instantiating this,
  // it's just a helper with static methods.
  GameStorage._();

  // --- Key constants so I don't typo a string somewhere ---
  static const _keyCoins     = 'game_coins';
  static const _keyOwned     = 'game_owned_costumes';
  static const _keyEquipped  = 'game_equipped';
  static const _keyBoosts    = 'game_active_boosts';

  // Load the player's saved state from storage.
  // If nothing is saved yet (first launch), we just return a fresh GameState.
  static Future<GameState> load() async {
    final prefs = await SharedPreferences.getInstance();

    final coins = prefs.getInt(_keyCoins) ?? 0;

    // Stored as a comma-separated string, split it back into a Set.
    // If the key doesn't exist, getStringList returns null so we default to [].
    final ownedRaw = prefs.getString(_keyOwned) ?? '';
    final owned = ownedRaw.isEmpty
        ? <String>{}
        : ownedRaw.split(',').toSet();

    final equipped = prefs.getString(_keyEquipped); // null if not set - that's fine

    final boostsRaw = prefs.getString(_keyBoosts) ?? '';
    final boosts = boostsRaw.isEmpty
        ? <String>[]
        : boostsRaw.split(',').toList();

    return GameState(
      coins: coins,
      ownedCostumes: owned,
      equippedCostume: equipped,
      activeBoosts: boosts,
    );
  }

  // Save the current state to storage.
  // Called after the player beats a boss or buys something from the shop.
  static Future<void> save(GameState state) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_keyCoins, state.coins);
    await prefs.setString(_keyOwned, state.ownedCostumes.join(','));
    // If nothing is equipped, save an empty string (can't store null in prefs)
    await prefs.setString(_keyEquipped, state.equippedCostume ?? '');
    await prefs.setString(_keyBoosts, state.activeBoosts.join(','));
  }
}
