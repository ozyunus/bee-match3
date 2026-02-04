/// Game constants for Bee Match-3
class GameConstants {
  GameConstants._();

  // Grid settings
  static const int minGridSize = 6;
  static const int maxGridSize = 8;
  static const int gridSizeIncrementEvery = 5; // Her 5 levelde 1 artar
  static const int animalTypeCount = 5;

  /// Level'a göre grid boyutunu hesaplar
  /// Level 1-5: 6x6, Level 6-10: 7x7, Level 11+: 8x8
  static int getGridSizeForLevel(int level) {
    final increment = (level - 1) ~/ gridSizeIncrementEvery;
    final size = minGridSize + increment;
    return size > maxGridSize ? maxGridSize : size;
  }

  // Animation durations (in milliseconds)
  static const int swapDuration = 200;
  static const int matchFadeDuration = 150;
  static const int fallDuration = 100; // per row
  static const int cascadeDelay = 50;

  // Timing
  static const int splashScreenDuration = 5000; // 5 seconds
  static const int maxSplashDuration = 7000; // 7 seconds

  // Level settings
  static const int totalLevels = 30;
  static const int easyLevelsEnd = 10;
  static const int mediumLevelsEnd = 20;

  // Moves for difficulty levels
  static const int easyMinMoves = 25;
  static const int easyMaxMoves = 30;
  static const int mediumMinMoves = 20;
  static const int mediumMaxMoves = 25;
  static const int hardMinMoves = 15;
  static const int hardMaxMoves = 20;

  // Extra moves from rewarded ad
  static const int extraMovesReward = 5;

  // Star calculation thresholds
  static const double threeStarThreshold = 0.4; // 40% moves remaining
  static const double twoStarThreshold = 0.2; // 20% moves remaining

  // Offline queue settings
  static const int maxQueuedEvents = 100;
  static const int eventExpirationHours = 48;
}
