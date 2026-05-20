import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class UserService {
  static const String _boxName = 'user_data';
  static const String _levelBoxName = 'level_data';

  static late Box _userBox;
  static late Box _levelBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _userBox = await Hive.openBox(_boxName);
    _levelBox = await Hive.openBox(_levelBoxName);

    // Generate UUID if first launch
    if (_userBox.get('uuid') == null) {
      _userBox.put('uuid', const Uuid().v4());
    }

    // Set default nickname if first launch
    if (_userBox.get('nickname') == null) {
      _userBox.put('nickname', 'Arıcı${_generateRandomTag()}');
    }

    // Set default current level
    if (_userBox.get('currentLevel') == null) {
      _userBox.put('currentLevel', 1);
    }
  }

  static String _generateRandomTag() {
    final now = DateTime.now();
    return '${now.millisecond}${now.second}'.padLeft(4, '0').substring(0, 4);
  }

  // ==================== USER INFO ====================

  static String get uuid => _userBox.get('uuid', defaultValue: '');
  static String get nickname => _userBox.get('nickname', defaultValue: 'Arıcı');

  static set nickname(String value) => _userBox.put('nickname', value);

  // ==================== SOUND SETTINGS ====================

  static bool get isSoundEnabled => _userBox.get('soundEnabled', defaultValue: true);

  static set isSoundEnabled(bool value) => _userBox.put('soundEnabled', value);

  // ==================== LEVEL PROGRESS ====================

  static int get currentLevel => _userBox.get('currentLevel', defaultValue: 1);

  static set currentLevel(int value) => _userBox.put('currentLevel', value);

  /// Get the highest unlocked level
  static int get maxUnlockedLevel => _userBox.get('maxUnlockedLevel', defaultValue: 1);

  static void unlockNextLevel(int completedLevel) {
    final next = completedLevel + 1;
    if (next > maxUnlockedLevel) {
      _userBox.put('maxUnlockedLevel', next);
    }
  }

  // ==================== LEVEL SCORES ====================

  /// Save score for a level (only if higher than existing)
  static void saveLevelScore(int levelId, int score, int stars) {
    final key = 'level_$levelId';
    final existing = _levelBox.get(key);

    if (existing == null || (existing as Map)['score'] < score) {
      _levelBox.put(key, {
        'score': score,
        'stars': stars,
        'completedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Get best score for a level
  static int getLevelScore(int levelId) {
    final data = _levelBox.get('level_$levelId');
    if (data == null) return 0;
    return (data as Map)['score'] ?? 0;
  }

  /// Get stars earned for a level
  static int getLevelStars(int levelId) {
    final data = _levelBox.get('level_$levelId');
    if (data == null) return 0;
    return (data as Map)['stars'] ?? 0;
  }

  /// Get total score across all levels
  static int get totalScore {
    int total = 0;
    for (int i = 1; i <= maxUnlockedLevel; i++) {
      total += getLevelScore(i);
    }
    return total;
  }

  /// Get total stars across all levels
  static int get totalStars {
    int total = 0;
    for (int i = 1; i <= maxUnlockedLevel; i++) {
      total += getLevelStars(i);
    }
    return total;
  }

  // ==================== FAIL TRACKING ====================

  /// Increment fail count for a level, returns new count
  static int recordLevelFail(int levelId) {
    final key = 'fails_$levelId';
    final current = _userBox.get(key, defaultValue: 0) as int;
    final newCount = current + 1;
    _userBox.put(key, newCount);
    return newCount;
  }

  /// Get fail count for a level
  static int getLevelFailCount(int levelId) {
    return _userBox.get('fails_$levelId', defaultValue: 0) as int;
  }

  /// Reset fail count for a level (on level complete)
  static void resetLevelFails(int levelId) {
    _userBox.put('fails_$levelId', 0);
  }
}
