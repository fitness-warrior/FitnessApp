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
//   activeBoosts   - list of boost IDs purchased from the shop (e.g. ["double_damage"])

class GameState {
  int coins;
  Set<String> ownedCostumes;
  String? equippedCostume; // null means default character appearance
  List<String> activeBoosts;

  GameState({
    this.coins = 0,
    Set<String>? ownedCostumes,
    this.equippedCostume,
    List<String>? activeBoosts,
  })  : ownedCostumes = ownedCostumes ?? {},
        activeBoosts = activeBoosts ?? [];

  // --- Helper getters so the GamePage can read these without doing the
  //     math inline. Easier to understand at a glance. ---

  // How much damage each tap does.
  // Double Damage boost doubles it, otherwise it's just 10 per tap.
  int get tapDamage => activeBoosts.contains('double_damage') ? 20 : 10;

  // How many extra seconds are added to the 2-minute round timer.
  // Time Extension boost adds 30 seconds.
  int get timeBonus => activeBoosts.contains('time_ext') ? 30 : 0;

  // Whether the auto-clicker boost is active (taps once per second automatically).
  bool get hasAutoClick => activeBoosts.contains('auto_click');
}
