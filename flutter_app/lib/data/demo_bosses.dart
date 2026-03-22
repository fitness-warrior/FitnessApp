// lib/data/demo_bosses.dart
//
// This file just holds the list of bosses the player will fight.
// I'm keeping it separate from the model so the game page doesn't get cluttered
// with a bunch of hardcoded strings. Easy to add more bosses later too.
//
// Boss order: Burger Baron -> Pizza Phantom -> Fry King
// Each one is harder than the last (more HP, bigger coin reward).

import '../models/boss.dart';

// A constant I'll use elsewhere to identify the Wind costume
// (it's a bonus unlock when you clear ALL 3 bosses, not tied to one boss)
const String windCostumeKey = 'wind';

const List<Boss> demoBosses = [
  Boss(
    name: 'Burger Baron',
    // TODO: add a real boss sprite here later - using the fallback icon for now
    imagePath: 'images/game_costume/game_chars/boss1.png',
    background: 'images/game_costume/backgrounds/City1.png',
    maxHealth: 100,
    rewardCostume: 'earth',
    rewardImagePath: 'images/game_costume/earth.png',
    coinReward: 150,
    flavorText: 'A greasy overlord dripping in special sauce.',
  ),
  Boss(
    name: 'Pizza Phantom',
    imagePath: 'images/game_costume/game_chars/boss2.png',
    background: 'images/game_costume/backgrounds/City2.png',
    maxHealth: 200,
    rewardCostume: 'water',
    rewardImagePath: 'images/game_costume/water.png',
    coinReward: 250,
    flavorText: 'He slices, he dices, he haunts your macros.',
  ),
  Boss(
    name: 'Fry King',
    imagePath: 'images/game_costume/game_chars/boss3.png',
    background: 'images/game_costume/backgrounds/City3.png',
    maxHealth: 350,
    rewardCostume: 'fire',
    rewardImagePath: 'images/game_costume/fire.png',
    coinReward: 400,
    flavorText: 'Ruler of the deep fryer. Fear the salt.',
  ),
];
