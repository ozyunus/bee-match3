import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Animal types available in the game
/// First 4 (rabbit, cat, duck, bear) are base animals for levels 1-10
/// New animals unlock every 5 levels after level 10
enum AnimalType {
  bee,
  // Base animals (levels 1-10)
  rabbit,
  cat,
  duck,
  bear,
  // Unlock at level 11
  dog,
  // Unlock at level 16
  frog,
  // Unlock at level 21
  fox,
  // Unlock at level 26
  owl,
  // Unlock at level 31
  panda,
  // Unlock at level 36
  lion,
  // Fruits (visual density only)
  apple,
  orange,
  berry,
  grape,
  lemon;

  static const Set<AnimalType> _fruitTypes = {
    AnimalType.apple,
    AnimalType.orange,
    AnimalType.berry,
    AnimalType.grape,
    AnimalType.lemon,
  };

  bool get isBee => this == AnimalType.bee;
  bool get isFruit => _fruitTypes.contains(this);
  bool get isAnimal => !isBee && !isFruit;

  /// Asset path for the sprite that represents this tile.
  String get assetPath => 'assets/images/sprite/${name.toLowerCase()}.png';

  Color get fruitBackgroundColor {
    switch (this) {
      case AnimalType.apple:
        return AppColors.appleBg;
      case AnimalType.orange:
        return AppColors.orangeBg;
      case AnimalType.berry:
        return AppColors.berryBg;
      case AnimalType.grape:
        return AppColors.grapeBg;
      case AnimalType.lemon:
        return AppColors.lemonBg;
      default:
        return AppColors.surface;
    }
  }

  Color get tileBackgroundColor {
    if (isFruit) {
      return fruitBackgroundColor;
    }
    return color;
  }

  Color get tileBorderColor {
    if (isFruit) {
      return AppColors.fruitTileBorder;
    }
    return Colors.white.withValues(alpha: 0.6);
  }

  /// Get the display emoji for this animal
  String get emoji {
    switch (this) {
      case AnimalType.bee:
        return '🐝';
      case AnimalType.rabbit:
        return '🐰';
      case AnimalType.cat:
        return '🐱';
      case AnimalType.duck:
        return '🦆';
      case AnimalType.bear:
        return '🐻';
      case AnimalType.dog:
        return '🐶';
      case AnimalType.frog:
        return '🐸';
      case AnimalType.fox:
        return '🦊';
      case AnimalType.owl:
        return '🦉';
      case AnimalType.panda:
        return '🐼';
      case AnimalType.lion:
        return '🦁';
      case AnimalType.apple:
        return '🍎';
      case AnimalType.orange:
        return '🍊';
      case AnimalType.berry:
        return '🫐';
      case AnimalType.grape:
        return '🍇';
      case AnimalType.lemon:
        return '🍋';
    }
  }

  /// Get the color for this animal (for placeholder rendering)
  Color get color {
    switch (this) {
      case AnimalType.bee:
        return AppColors.beeColor;
      case AnimalType.rabbit:
        return AppColors.rabbitColor;
      case AnimalType.cat:
        return AppColors.catColor;
      case AnimalType.duck:
        return AppColors.duckColor;
      case AnimalType.bear:
        return AppColors.bearColor;
      case AnimalType.dog:
        return AppColors.dogColor;
      case AnimalType.frog:
        return AppColors.frogColor;
      case AnimalType.fox:
        return AppColors.foxColor;
      case AnimalType.owl:
        return AppColors.owlColor;
      case AnimalType.panda:
        return AppColors.pandaColor;
      case AnimalType.lion:
        return AppColors.lionColor;
      case AnimalType.apple:
        return AppColors.appleColor;
      case AnimalType.orange:
        return AppColors.orangeColor;
      case AnimalType.berry:
        return AppColors.berryColor;
      case AnimalType.grape:
        return AppColors.grapeColor;
      case AnimalType.lemon:
        return AppColors.lemonColor;
    }
  }

  /// Get the level at which this animal unlocks (bee is always available)
  int get unlockLevel {
    switch (this) {
      case AnimalType.bee:
        return 1;
      case AnimalType.rabbit:
      case AnimalType.cat:
      case AnimalType.duck:
      case AnimalType.bear:
        return 1;
      case AnimalType.dog:
        return 11;
      case AnimalType.frog:
        return 16;
      case AnimalType.fox:
        return 21;
      case AnimalType.owl:
        return 26;
      case AnimalType.panda:
        return 31;
      case AnimalType.lion:
        return 36;
      case AnimalType.apple:
      case AnimalType.orange:
      case AnimalType.berry:
      case AnimalType.grape:
      case AnimalType.lemon:
        return 1;
    }
  }

  /// Get all non-bee animals available at a given level
  static List<AnimalType> getAnimalsForLevel(int level) {
    return AnimalType.values
        .where((a) => a.isAnimal && a.unlockLevel <= level)
        .toList();
  }

  static List<AnimalType> getFruitsForLevel(int level) {
    return AnimalType.values
        .where((a) => a.isFruit && a.unlockLevel <= level)
        .toList();
  }
}
