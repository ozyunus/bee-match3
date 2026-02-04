import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../core/router/app_router.dart';
import '../../data/models/animal_type.dart';
import '../widgets/moves_counter.dart';
import '../widgets/objective_progress.dart';
import '../widgets/game_tile.dart';

/// Main game screen with dynamic grid size based on level
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.levelId,
  });

  final int levelId;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  // Grid state
  late List<List<AnimalType?>> grid;
  late int _gridSize; // Dynamic grid size based on level

  // Game state
  int movesRemaining = 25;
  int collectedBees = 0;
  final int targetBees = 30;
  int score = 0;
  int bestCombo = 0;
  bool isPaused = false;

  // Selection & interaction
  int? selectedX;
  int? selectedY;
  bool isProcessing = false;

  // Power-ups
  int shuffleCount = 2;
  int blastCount = 1;

  // Animation
  Set<String> matchedTiles = {};
  Set<String> fallingTiles = {};
  Set<String> specialMatchTiles = {}; // For 5+ matches

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _gridSize = GameConstants.getGridSizeForLevel(widget.levelId);
    _initGrid();
    _setMovesForLevel();
    // Remove initial matches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _removeInitialMatches();
    });
  }

  void _initGrid() {
    // Create grid with balanced bee distribution
    final totalTiles = _gridSize * _gridSize;

    // Calculate desired number of bees (15-20% of grid)
    final minBees = (totalTiles * 0.15).floor();
    final maxBees = (totalTiles * 0.20).ceil();
    final targetBees = minBees + _random.nextInt(maxBees - minBees + 1);

    // Create a list of all animal types with guaranteed bee count
    final animals = <AnimalType>[];

    // Add target number of bees
    for (int i = 0; i < targetBees; i++) {
      animals.add(AnimalType.bee);
    }

    // Fill remaining slots with other animals (evenly distributed)
    final otherAnimals = [
      AnimalType.rabbit,
      AnimalType.cat,
      AnimalType.duck,
      AnimalType.bear,
    ];

    for (int i = targetBees; i < totalTiles; i++) {
      animals.add(otherAnimals[_random.nextInt(otherAnimals.length)]);
    }

    // Shuffle the animals list to randomize positions
    animals.shuffle(_random);

    // Populate grid
    int index = 0;
    grid = List.generate(
      _gridSize,
      (y) => List.generate(
        _gridSize,
        (x) => animals[index++],
      ),
    );
  }

  void _removeInitialMatches() async {
    bool hasMatches = true;
    int iterations = 0;
    final maxIterations = 50; // Prevent infinite loops

    while (hasMatches && iterations < maxIterations) {
      iterations++;
      final matches = _findAllMatches();
      if (matches.isEmpty) {
        hasMatches = false;
      } else {
        // Calculate balanced replacement distribution
        final matchCount = matches.length;
        final beesToReplace = (matchCount * 0.15).floor() + _random.nextInt(2);

        final otherAnimals = [
          AnimalType.rabbit,
          AnimalType.cat,
          AnimalType.duck,
          AnimalType.bear,
        ];

        final replacements = <AnimalType>[];
        for (int i = 0; i < beesToReplace && i < matchCount; i++) {
          replacements.add(AnimalType.bee);
        }
        for (int i = beesToReplace; i < matchCount; i++) {
          replacements.add(otherAnimals[_random.nextInt(otherAnimals.length)]);
        }
        replacements.shuffle(_random);

        // Replace matched tiles
        int replaceIndex = 0;
        for (final pos in matches) {
          final parts = pos.split(',');
          final x = int.parse(parts[0]);
          final y = int.parse(parts[1]);
          grid[y][x] = replacements[replaceIndex++];
        }
      }
    }
    setState(() {});
  }

  void _setMovesForLevel() {
    if (widget.levelId <= GameConstants.easyLevelsEnd) {
      movesRemaining = 28;
    } else if (widget.levelId <= GameConstants.mediumLevelsEnd) {
      movesRemaining = 22;
    } else {
      movesRemaining = 18;
    }
  }

  void _resetGame() {
    setState(() {
      _initGrid();
      _setMovesForLevel();
      collectedBees = 0;
      score = 0;
      bestCombo = 0;
      isPaused = false;
      selectedX = null;
      selectedY = null;
      isProcessing = false;
      shuffleCount = 2;
      blastCount = 1;
      matchedTiles.clear();
    });
    _removeInitialMatches();
  }

  String get _difficultyTag {
    if (widget.levelId <= GameConstants.easyLevelsEnd) return 'Easy';
    if (widget.levelId <= GameConstants.mediumLevelsEnd) return 'Medium';
    return 'Hard';
  }

  // ==================== MATCH-3 LOGIC ====================

  Set<String> _findAllMatches() {
    final matches = <String>{};
    final horizontalMatches = <String, List<String>>{};
    final verticalMatches = <String, List<String>>{};

    // Check horizontal matches
    for (int y = 0; y < _gridSize; y++) {
      int matchStart = 0;
      AnimalType? currentAnimal = grid[y][0];

      for (int x = 1; x <= _gridSize; x++) {
        final animal = x < _gridSize ? grid[y][x] : null;

        if (animal == currentAnimal && animal != null) {
          continue;
        }

        // Check if we have a match of 3 or more
        final matchLength = x - matchStart;
        if (matchLength >= 3 && currentAnimal != null) {
          final matchList = <String>[];
          for (int i = matchStart; i < x; i++) {
            final pos = '$i,$y';
            matches.add(pos);
            matchList.add(pos);
          }
          // Store horizontal match group
          for (final pos in matchList) {
            horizontalMatches[pos] = matchList;
          }
        }

        matchStart = x;
        currentAnimal = animal;
      }
    }

    // Check vertical matches
    for (int x = 0; x < _gridSize; x++) {
      int matchStart = 0;
      AnimalType? currentAnimal = grid[0][x];

      for (int y = 1; y <= _gridSize; y++) {
        final animal = y < _gridSize ? grid[y][x] : null;

        if (animal == currentAnimal && animal != null) {
          continue;
        }

        // Check if we have a match of 3 or more
        final matchLength = y - matchStart;
        if (matchLength >= 3 && currentAnimal != null) {
          final matchList = <String>[];
          for (int i = matchStart; i < y; i++) {
            final pos = '$x,$i';
            matches.add(pos);
            matchList.add(pos);
          }
          // Store vertical match group
          for (final pos in matchList) {
            verticalMatches[pos] = matchList;
          }
        }

        matchStart = y;
        currentAnimal = animal;
      }
    }

    // Check for L-shapes and T-shapes
    // If a tile is in both horizontal and vertical matches, it forms an L or T
    final connectedMatches = <String>{};
    for (final pos in matches) {
      if (horizontalMatches.containsKey(pos) && verticalMatches.containsKey(pos)) {
        // This is a junction point - add all connected tiles
        connectedMatches.addAll(horizontalMatches[pos]!);
        connectedMatches.addAll(verticalMatches[pos]!);
      }
    }

    // Add all connected matches to the result
    matches.addAll(connectedMatches);

    return matches;
  }

  Future<void> _processMatches() async {
    int comboCount = 0;

    while (true) {
      final matches = _findAllMatches();
      if (matches.isEmpty) break;

      comboCount++;
      if (comboCount > bestCombo) bestCombo = comboCount;

      // Check if this is a special match (5+ tiles)
      final isSpecialMatch = matches.length >= 5;

      // OPTIMIZATION: Single setState for match start animation
      setState(() {
        matchedTiles = matches;
        if (isSpecialMatch) {
          specialMatchTiles = matches;
        }
      });

      // Longer animation for special matches
      await Future.delayed(Duration(milliseconds: isSpecialMatch ? 400 : 200));

      // Count collected animals and clear matched tiles (NO setState here - just data)
      int beeBonus = 0;
      for (final pos in matches) {
        final parts = pos.split(',');
        final x = int.parse(parts[0]);
        final y = int.parse(parts[1]);

        if (grid[y][x] == AnimalType.bee) {
          collectedBees++;
          beeBonus++;
        }

        // Special match bonus scoring
        if (isSpecialMatch) {
          score += 20 * comboCount; // Double points for 5+
        } else {
          score += 10 * comboCount;
        }

        grid[y][x] = null;
      }

      // Show bonus message (doesn't trigger rebuild)
      if (isSpecialMatch && beeBonus > 0 && mounted) {
        collectedBees += beeBonus; // Double bee collection for 5+ matches

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🌟 SÜPER COMBO! ${matches.length} eşleşme! +${beeBonus} bonus arı!'),
            duration: const Duration(milliseconds: 800),
            backgroundColor: AppColors.primary,
          ),
        );
      }

      // OPTIMIZATION: Clear match state without setState
      matchedTiles.clear();
      specialMatchTiles.clear();

      // Small delay before gravity (no setState needed)
      await Future.delayed(const Duration(milliseconds: 50));

      // Apply gravity (this will call setState internally)
      await _applyGravity();

      // Fill empty spaces (this will call setState internally)
      await _fillEmptySpaces();
    }
  }

  Future<void> _applyGravity() async {
    bool moved = true;
    int iterations = 0;

    while (moved && iterations < 10) {
      iterations++;
      moved = false;

      for (int x = 0; x < _gridSize; x++) {
        for (int y = _gridSize - 2; y >= 0; y--) {
          if (grid[y][x] != null && grid[y + 1][x] == null) {
            // Find the lowest empty spot
            int targetY = y + 1;
            while (targetY + 1 < _gridSize && grid[targetY + 1][x] == null) {
              targetY++;
            }

            grid[targetY][x] = grid[y][x];
            grid[y][x] = null;
            moved = true;
          }
        }
      }

      // OPTIMIZATION: Only setState if something actually moved
      if (moved) {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 30)); // Reduced from 50ms
      }
    }
  }

  Future<void> _fillEmptySpaces() async {
    // Count empty spaces
    int emptyCount = 0;
    for (int x = 0; x < _gridSize; x++) {
      for (int y = 0; y < _gridSize; y++) {
        if (grid[y][x] == null) {
          emptyCount++;
        }
      }
    }

    if (emptyCount == 0) return;

    // Calculate how many bees to spawn (15-20% of empty spaces)
    final minBees = (emptyCount * 0.15).floor();
    final maxBees = (emptyCount * 0.20).ceil();
    final beesToSpawn = minBees + _random.nextInt(maxBees - minBees + 1);

    // Create list of new animals
    final newAnimals = <AnimalType>[];
    for (int i = 0; i < beesToSpawn; i++) {
      newAnimals.add(AnimalType.bee);
    }

    // Fill remaining with other animals
    final otherAnimals = [
      AnimalType.rabbit,
      AnimalType.cat,
      AnimalType.duck,
      AnimalType.bear,
    ];

    for (int i = beesToSpawn; i < emptyCount; i++) {
      newAnimals.add(otherAnimals[_random.nextInt(otherAnimals.length)]);
    }

    // Shuffle
    newAnimals.shuffle(_random);

    // Fill empty spaces
    int index = 0;
    for (int x = 0; x < _gridSize; x++) {
      for (int y = 0; y < _gridSize; y++) {
        if (grid[y][x] == null) {
          grid[y][x] = newAnimals[index++];
        }
      }
    }

    // OPTIMIZATION: Single setState after all tiles are filled
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 80)); // Reduced from 100ms
  }

  // ==================== INTERACTION ====================

  void _onTileSelect(int x, int y) {
    if (isProcessing || isPaused) return;

    setState(() {
      if (selectedX == null || selectedY == null) {
        // First selection
        selectedX = x;
        selectedY = y;
      } else if (selectedX == x && selectedY == y) {
        // Deselect
        selectedX = null;
        selectedY = null;
      } else if (_isAdjacent(selectedX!, selectedY!, x, y)) {
        // Try to swap
        _trySwap(selectedX!, selectedY!, x, y);
        selectedX = null;
        selectedY = null;
      } else {
        // Select new tile
        selectedX = x;
        selectedY = y;
      }
    });
  }

  void _onTileSwipe(int x, int y, String direction) {
    if (isProcessing || isPaused) return;

    // Select the starting tile
    selectedX = x;
    selectedY = y;

    // Calculate target position based on swipe direction
    int targetX = x;
    int targetY = y;

    switch (direction) {
      case 'up':
        targetY = y - 1;
        break;
      case 'down':
        targetY = y + 1;
        break;
      case 'left':
        targetX = x - 1;
        break;
      case 'right':
        targetX = x + 1;
        break;
    }

    // Try to swap if target is valid and adjacent
    if (targetX >= 0 && targetX < _gridSize &&
        targetY >= 0 && targetY < _gridSize) {
      _trySwap(x, y, targetX, targetY);
      selectedX = null;
      selectedY = null;
    }
  }

  bool _isAdjacent(int x1, int y1, int x2, int y2) {
    return (x1 == x2 && (y1 - y2).abs() == 1) ||
           (y1 == y2 && (x1 - x2).abs() == 1);
  }

  Future<void> _trySwap(int x1, int y1, int x2, int y2) async {
    if (isProcessing || isPaused) return;

    setState(() {
      isProcessing = true;
    });

    // Perform swap
    final temp = grid[y1][x1];
    grid[y1][x1] = grid[y2][x2];
    grid[y2][x2] = temp;

    setState(() {});
    await Future.delayed(const Duration(milliseconds: 150));

    // Check if swap creates a match
    final matches = _findAllMatches();

    if (matches.isEmpty) {
      // Swap back - invalid move
      final temp = grid[y1][x1];
      grid[y1][x1] = grid[y2][x2];
      grid[y2][x2] = temp;

      setState(() {});
      await Future.delayed(const Duration(milliseconds: 150));
    } else {
      // Valid move - process matches
      movesRemaining--;
      await _processMatches();

      // Check win/lose
      _checkGameEnd();
    }

    setState(() {
      isProcessing = false;
    });
  }

  void _checkGameEnd() {
    if (collectedBees >= targetBees) {
      _showLevelComplete();
    } else if (movesRemaining <= 0) {
      _showLevelFailed();
    }
  }

  // ==================== PAUSE & RESTART ====================

  void _showRestartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.refresh_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Yeniden Başlat'),
          ],
        ),
        content: const Text('Oyunu yeniden başlatmak istediğinize emin misiniz? Mevcut ilerlemeniz kaybolacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Yeniden Başlat'),
          ),
        ],
      ),
    );
  }

  void _showPauseMenu() {
    setState(() => isPaused = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            '⏸️ Oyun Duraklatıldı',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            _buildPauseMenuButton(
              icon: Icons.play_arrow_rounded,
              label: 'Devam Et',
              color: AppColors.success,
              onTap: () {
                Navigator.pop(context);
                setState(() => isPaused = false);
              },
            ),
            const SizedBox(height: 12),
            _buildPauseMenuButton(
              icon: Icons.refresh_rounded,
              label: 'Yeniden Başlat',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(context);
                _resetGame();
              },
            ),
            const SizedBox(height: 12),
            _buildPauseMenuButton(
              icon: Icons.home_rounded,
              label: 'Ana Menü',
              color: Colors.grey,
              onTap: () {
                Navigator.pop(context);
                context.go(AppRoutes.splash);
              },
            ),
          ],
        ),
      ),
    ).then((_) {
      // Dialog kapanınca pause'u kaldır
      if (mounted) setState(() => isPaused = false);
    });
  }

  Widget _buildPauseMenuButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ==================== POWER-UPS ====================

  void _onSmash() {
    if (isProcessing || isPaused) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Smash: Bir tile\'a dokun, onu ve komşularını patlat!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onShuffle() async {
    if (isProcessing || shuffleCount <= 0 || isPaused) return;

    setState(() {
      isProcessing = true;
      shuffleCount--;
    });

    // Shuffle all tiles
    final allAnimals = <AnimalType>[];
    for (int y = 0; y < _gridSize; y++) {
      for (int x = 0; x < _gridSize; x++) {
        if (grid[y][x] != null) {
          allAnimals.add(grid[y][x]!);
        }
      }
    }

    allAnimals.shuffle(_random);

    int index = 0;
    for (int y = 0; y < _gridSize; y++) {
      for (int x = 0; x < _gridSize; x++) {
        grid[y][x] = allAnimals[index++];
      }
    }

    setState(() {});
    await Future.delayed(const Duration(milliseconds: 300));

    // Remove any matches created by shuffle
    await _processMatches();

    setState(() {
      isProcessing = false;
    });
  }

  void _onBlast() async {
    if (isProcessing || blastCount <= 0 || isPaused) return;

    setState(() {
      isProcessing = true;
      blastCount--;
    });

    // Clear center 3x3 area
    final centerX = _gridSize ~/ 2;
    final centerY = _gridSize ~/ 2;

    for (int dy = -1; dy <= 1; dy++) {
      for (int dx = -1; dx <= 1; dx++) {
        final x = centerX + dx;
        final y = centerY + dy;
        if (x >= 0 && x < _gridSize &&
            y >= 0 && y < _gridSize) {
          if (grid[y][x] == AnimalType.bee) {
            collectedBees++;
          }
          score += 10;
          grid[y][x] = null;
        }
      }
    }

    setState(() {});
    await Future.delayed(const Duration(milliseconds: 200));

    await _applyGravity();
    await _fillEmptySpaces();
    await _processMatches();

    _checkGameEnd();

    setState(() {
      isProcessing = false;
    });
  }

  // ==================== NAVIGATION ====================

  void _showLevelComplete() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.go(AppRoutes.levelComplete, extra: {
          'levelId': widget.levelId,
          'score': score,
          'starsEarned': _calculateStars(),
          'movesUsed': _getInitialMoves() - movesRemaining,
          'bestCombo': bestCombo,
        });
      }
    });
  }

  void _showLevelFailed() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.go(AppRoutes.levelFailed, extra: {
          'levelId': widget.levelId,
          'currentProgress': collectedBees,
          'targetProgress': targetBees,
          'objectiveLabel': 'Collect Bees',
        });
      }
    });
  }

  int _getInitialMoves() {
    if (widget.levelId <= GameConstants.easyLevelsEnd) return 28;
    if (widget.levelId <= GameConstants.mediumLevelsEnd) return 22;
    return 18;
  }

  int _calculateStars() {
    final remaining = movesRemaining / _getInitialMoves();
    if (remaining >= 0.4) return 3;
    if (remaining >= 0.2) return 2;
    return 1;
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade100,
              AppColors.backgroundLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildStatsBar(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: Center(
                      child: _buildGameGrid(),
                    ),
                  ),
                  _buildToolbar(),
                  const SizedBox(height: 16),
                ],
              ),
              // Pause overlay
              if (isPaused)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Text(
                      '⏸️ DURAKLATILDI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Level info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor.withValues(alpha: 0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flag_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Lv ${widget.levelId} • $_difficultyTag',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Score display
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowColor.withValues(alpha: 0.1),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Restart button
          _buildHeaderButton(
            icon: Icons.refresh_rounded,
            onTap: _showRestartDialog,
            tooltip: 'Yeniden Başlat',
          ),
          const SizedBox(width: 8),
          // Pause button
          _buildHeaderButton(
            icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            onTap: _showPauseMenu,
            tooltip: isPaused ? 'Devam Et' : 'Duraklat',
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: AppColors.textPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          MovesCounter(movesRemaining: movesRemaining),
          const SizedBox(width: 16),
          Expanded(
            child: ObjectiveProgress(
              label: 'Target: Collect Bees',
              current: collectedBees,
              target: targetBees,
              icon: '🐝',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.neutralDark,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              offset: const Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            // IMPORTANT: shrinkWrap is false by default, which is good for performance
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridSize,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: _gridSize * _gridSize,
            // Use addAutomaticKeepAlives to reduce rebuilds
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: false, // We're using RepaintBoundary in GameTile
            itemBuilder: (context, index) {
              final x = index % _gridSize;
              final y = index ~/ _gridSize;
              final animal = grid[y][x];

              return GameTile(
                key: ValueKey('tile_${x}_${y}_${animal?.name}'),
                animal: animal,
                isSelected: selectedX == x && selectedY == y,
                isMatched: matchedTiles.contains('$x,$y'),
                isSpecialMatch: specialMatchTiles.contains('$x,$y'),
                onTap: () => _onTileSelect(x, y),
                onSwipe: (direction) => _onTileSwipe(x, y, direction),
              );
            },
          ),
      ),
    );
  }

  // Removed _buildTile - now using GameTile widget with RepaintBoundary

  Widget _buildToolbar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(Icons.construction_rounded, 'Smash', null, _onSmash),
          _buildToolButton(Icons.shuffle_rounded, 'Shuffle', shuffleCount, _onShuffle),
          _buildToolButton(Icons.rocket_launch_rounded, 'Blast', blastCount, _onBlast),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, String label, int? count, VoidCallback onTap) {
    final isDisabled = (count != null && count <= 0) || isPaused;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isDisabled ? Colors.grey : AppColors.textSecondary,
                    size: 28,
                  ),
                ),
                if (count != null)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: count > 0 ? AppColors.primary : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDisabled ? Colors.grey : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
