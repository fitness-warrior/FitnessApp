// lib/models/boss.dart
//
// Simple data class for a boss enemy.
// I'm keeping this as a plain Dart class (not a full ChangeNotifier or anything)
// because all we really need is somewhere to store the boss's info.
// The game page itself will handle all the logic (HP tracking, etc.).

class Boss {
  final String name;          // e.g. "Burger Baron"
  final String imagePath;     // path to the boss sprite asset
  final String background;    // which city background to use for this fight
  final int maxHealth;        // how much HP the boss starts with
  final String rewardCostume; // costume key unlocked on defeat (e.g. "earth")
  final String rewardImagePath; // path to the costume image to show on victory screen
  final int coinReward;       // coins the player gets for winning
  final String flavorText;    // fun little description shown during the fight

  // I'm using a const constructor so these boss objects can be compile-time constants.
  // That way I don't accidentally mutate them somewhere.
  const Boss({
    required this.name,
    required this.imagePath,
    required this.background,
    required this.maxHealth,
    required this.rewardCostume,
    required this.rewardImagePath,
    required this.coinReward,
    required this.flavorText,
  });
}
