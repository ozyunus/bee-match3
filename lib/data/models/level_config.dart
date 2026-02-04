import 'package:equatable/equatable.dart';

/// Level configuration model
class LevelConfig extends Equatable {
  const LevelConfig({
    required this.levelId,
    required this.difficultyTag,
    required this.gridSize,
    required this.movesAllowed,
    required this.objectives,
    this.initialBlockers = const [],
    this.ingredients = const [],
  });

  final int levelId;
  final String difficultyTag;
  final String gridSize;
  final int movesAllowed;
  final List<ObjectiveConfig> objectives;
  final List<BlockerPlacement> initialBlockers;
  final List<IngredientPlacement> ingredients;

  factory LevelConfig.fromJson(Map<String, dynamic> json) {
    return LevelConfig(
      levelId: json['level_id'] as int,
      difficultyTag: json['difficulty_tag'] as String,
      gridSize: json['grid_size'] as String? ?? '8x8',
      movesAllowed: json['moves_allowed'] as int,
      objectives: (json['objectives'] as List<dynamic>)
          .map((e) => ObjectiveConfig.fromJson(e as Map<String, dynamic>))
          .toList(),
      initialBlockers: (json['initial_blockers'] as List<dynamic>?)
              ?.map((e) => BlockerPlacement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map(
                  (e) => IngredientPlacement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level_id': levelId,
      'difficulty_tag': difficultyTag,
      'grid_size': gridSize,
      'moves_allowed': movesAllowed,
      'objectives': objectives.map((e) => e.toJson()).toList(),
      'initial_blockers': initialBlockers.map((e) => e.toJson()).toList(),
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        levelId,
        difficultyTag,
        gridSize,
        movesAllowed,
        objectives,
        initialBlockers,
        ingredients,
      ];
}

/// Objective configuration
class ObjectiveConfig extends Equatable {
  const ObjectiveConfig({
    required this.type,
    this.animalType,
    this.blockerType,
    required this.targetCount,
  });

  final String type; // 'collect', 'break_blockers', 'drop_ingredients'
  final String? animalType; // For collect objectives
  final String? blockerType; // For break_blockers objectives
  final int targetCount;

  factory ObjectiveConfig.fromJson(Map<String, dynamic> json) {
    return ObjectiveConfig(
      type: json['type'] as String,
      animalType: json['animal_type'] as String?,
      blockerType: json['blocker_type'] as String?,
      targetCount: json['target_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (animalType != null) 'animal_type': animalType,
      if (blockerType != null) 'blocker_type': blockerType,
      'target_count': targetCount,
    };
  }

  @override
  List<Object?> get props => [type, animalType, blockerType, targetCount];
}

/// Blocker placement on grid
class BlockerPlacement extends Equatable {
  const BlockerPlacement({
    required this.x,
    required this.y,
    required this.type,
  });

  final int x;
  final int y;
  final String type; // 'box', 'ice'

  factory BlockerPlacement.fromJson(Map<String, dynamic> json) {
    return BlockerPlacement(
      x: json['x'] as int,
      y: json['y'] as int,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [x, y, type];
}

/// Ingredient placement for drop objectives
class IngredientPlacement extends Equatable {
  const IngredientPlacement({
    required this.x,
    required this.type,
  });

  final int x; // Column where ingredient spawns
  final String type; // e.g., 'nut', 'cherry'

  factory IngredientPlacement.fromJson(Map<String, dynamic> json) {
    return IngredientPlacement(
      x: json['x'] as int,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [x, type];
}
