class GameState {
  int coins;
  Set<String> ownedCostumes;
  String? equippedCostume;
  Map<String, int> upgrades;

  GameState({
    int coins = 0,
    Set<String>? ownedCostumes,
    String? equippedCostume,
    Map<String, int>? upgrades,
  })  : coins = coins,
        ownedCostumes = ownedCostumes ?? <String>{},
        equippedCostume = equippedCostume,
        upgrades = upgrades ?? <String, int>{};

  int get tapDamage => 10 + (upgrades['dmg_up'] ?? 0) * 5;

  int get timeBonus => (upgrades['time_up'] ?? 0) * 10;

  bool get hasAutoClick => (upgrades['auto_click'] ?? 0) > 0;
}
