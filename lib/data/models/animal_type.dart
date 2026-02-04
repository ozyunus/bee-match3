import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Animal types available in the game
enum AnimalType {
  bee,
  rabbit,
  cat,
  duck,
  bear;

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
    }
  }

  /// Get animal type from string
  static AnimalType? fromString(String value) {
    switch (value.toLowerCase()) {
      case 'bee':
        return AnimalType.bee;
      case 'rabbit':
        return AnimalType.rabbit;
      case 'cat':
        return AnimalType.cat;
      case 'duck':
        return AnimalType.duck;
      case 'bear':
        return AnimalType.bear;
      default:
        return null;
    }
  }
}
