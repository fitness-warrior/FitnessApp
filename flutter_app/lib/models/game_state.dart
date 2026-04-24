// lib/models/game_state.dart
//
// Holds all the player's persistent game data in one place.
// I'm NOT extending ChangeNotifier or anything like that — the GamePage will
// just call setState() itself whenever something changes. Keeping it simple.
//
// Fields:
//   coins          - the currency earned by defeating bosses
//   ownedCostumes  - a Set of costume keys the player has unlocked (e.g. {"earth", "water"})
//   equippedCostume - which costume is currently shown on the player character
//   upgrades       - Map tracking the level of purchased shop upgrades (e.g. {"dmg_up": 2})

class GameState {
  int coins;
  Set<String> ownedCostumes;
  String? equippedCostume; // null means default character appearance
  Map<String, int> upgrades;

  GameState({
    this.coins = 0,
    Set<String>? ownedCostumes,
    this.equippedCostume,
    Map<String, int>? upgrades,
  })  : ownedCostumes = ownedCostumes ?? {},
        upgrades = upgrades ?? {};

  // --- Helper getters so the GamePage can read these without doing the
  //     math inline. Easier to understand at a glance. ---

  // Base 10 + (5 per Damage Upgrade)
  int get tapDamage => 10 + (5 * (upgrades['dmg_up'] ?? 0));

  // Base 120s timer + (10s per Time Upgrade)
  int get timeBonus => 10 * (upgrades['time_up'] ?? 0);

  // Auto-clicker is active if they bought it
  bool get hasAutoClick => (upgrades['auto_click'] ?? 0) > 0;
}
