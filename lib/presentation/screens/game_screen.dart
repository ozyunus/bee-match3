import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../core/router/app_router.dart';
import '../../data/models/animal_type.dart';
import '../../services/ads/rewarded_ad_service.dart';
import '../../services/analytics_service.dart';
import '../../services/sound_service.dart';
import '../../services/user_service.dart';
import '../widgets/moves_counter.dart';
import '../widgets/objective_progress.dart';
import '../widgets/game_tile.dart';

/// Main game screen with dynamic grid size based on level
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.levelId});

  final int levelId;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum ToolHintTarget { none, smash, shuffle, blast }

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
  int smashCount = 1;
  int shuffleCount = 2;
  int blastCount = 1;
  bool isSmashMode = false;

  // Animation
  Set<String> matchedTiles = {};
  Set<String> fallingTiles = {};
  Set<String> specialMatchTiles = {}; // For 5+ matches

  // Undo state - snapshot before last valid move
  List<List<AnimalType?>>? _undoGrid;
  int? _undoMoves;
  int? _undoScore;
  int? _undoBees;
  int? _undoBestCombo;
  bool _hasUndo = false;
  List<List<AnimalType?>>? _pendingUndoGrid;
  int? _pendingUndoMoves;
  int? _pendingUndoScore;
  int? _pendingUndoBees;
  int? _pendingUndoBestCombo;

  final Random _random = Random();
  final Set<String> _hintTiles = {};
  Timer? _hintTimer;
  int _shuffleAttempts = 0;
  static const _hintDelay = Duration(seconds: 5);
  static const _toolHintTimeout = Duration(seconds: 5);
  ToolHintTarget _currentHintTool = ToolHintTarget.none;
  Timer? _toolHintTimer;
  Timer? _pendingLevelTransitionTimer;

  List<AnimalType> get _playableAnimals =>
      AnimalType.getAnimalsForLevel(widget.levelId);

  List<AnimalType> get _availableFruits =>
      AnimalType.getFruitsForLevel(widget.levelId);

  List<AnimalType> get _nonBeeAnimals =>
      _playableAnimals.where((a) => a != AnimalType.bee).toList();

  List<AnimalType> get _fruitPool =>
      _availableFruits.isNotEmpty ? _availableFruits : _nonBeeAnimals;

  List<AnimalType> get _animalPool =>
      _playableAnimals.isNotEmpty ? _playableAnimals : [AnimalType.rabbit];

  bool get _isEarlyLevel => widget.levelId <= 5;
  bool get _countsAllMatches => widget.levelId > 5;

  double get _animalRatio => widget.levelId <= 5
      ? GameConstants.earlyAnimalRatio
      : GameConstants.lateAnimalRatio;

  List<AnimalType> _generateTiles(int totalTiles) {
    final animalCount = max(1, (totalTiles * _animalRatio).round());
    final fruitCount = max(0, totalTiles - animalCount);

    final beeCount = min(
      animalCount,
      max(1, (animalCount * GameConstants.beeShareOfAnimals).round()),
    );
    final otherAnimalCount = max(0, animalCount - beeCount);

    final tiles = <AnimalType>[];
    tiles.addAll(List.generate(beeCount, (_) => AnimalType.bee));

    final nonBeePool = _nonBeeAnimals.isNotEmpty
        ? _nonBeeAnimals
        : _animalPool.where((a) => a != AnimalType.bee).toList();
    if (nonBeePool.isEmpty) {
      nonBeePool.add(AnimalType.rabbit);
    }

    tiles.addAll(
      List.generate(
        otherAnimalCount,
        (_) => nonBeePool[_random.nextInt(nonBeePool.length)],
      ),
    );

    final fruitPool = _fruitPool.isNotEmpty
        ? _fruitPool
        : [AnimalType.rabbit, AnimalType.cat, AnimalType.duck];

    tiles.addAll(
      List.generate(
        fruitCount,
        (_) => fruitPool[_random.nextInt(fruitPool.length)],
      ),
    );

    tiles.shuffle(_random);
    return tiles;
  }

  @override
  void initState() {
    super.initState();
    _gridSize = GameConstants.getGridSizeForLevel(widget.levelId);
    _initGrid();
    RewardedAdService.instance.loadRewardedAd();
    final initialMoves = _getInitialMoves();
    _setMovesForLevel();
    unawaited(
      AnalyticsService.logLevelStarted(
        levelId: widget.levelId,
        gridSize: _gridSize,
        movesAllowed: initialMoves,
      ),
    );
    // Remove initial matches
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _removeInitialMatches();
    });
    _recordPlayerAction();
  }

  void _initGrid() {
    final totalTiles = _gridSize * _gridSize;
    final tiles = _generateTiles(totalTiles);

    int index = 0;
    grid = List.generate(
      _gridSize,
      (y) => List.generate(_gridSize, (x) => tiles[index++]),
    );
  }

  Future<void> _removeInitialMatches() async {
    bool hasMatches = true;
    int iterations = 0;
    final maxIterations = 50; // Prevent infinite loops

    while (hasMatches && iterations < maxIterations) {
      iterations++;
      final matches = _findAllMatches();
      if (matches.isEmpty) {
        hasMatches = false;
      } else {
        final matchCount = matches.length;
        final replacements = _generateTiles(matchCount);

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

  int _scoreForMatchTile(AnimalType type, int comboCount, bool isSpecialMatch) {
    final base = isSpecialMatch ? 20 * comboCount : 10 * comboCount;
    if (type == AnimalType.bee && !_isEarlyLevel) {
      return base + 15;
    }
    return base;
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
    _cancelPendingLevelTransition();
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
      isSmashMode = false;
      matchedTiles.clear();
      _hasUndo = false;
      _undoGrid = null;
      _clearPendingUndoState();
    });
    _removeInitialMatches();
    _recordPlayerAction();
  }

  void _cancelPendingLevelTransition() {
    _pendingLevelTransitionTimer?.cancel();
    _pendingLevelTransitionTimer = null;
  }

  void _captureUndoState() {
    _pendingUndoGrid = grid.map((row) => List<AnimalType?>.from(row)).toList();
    _pendingUndoMoves = movesRemaining;
    _pendingUndoScore = score;
    _pendingUndoBees = collectedBees;
    _pendingUndoBestCombo = bestCombo;
  }

  void _commitUndoState() {
    if (_pendingUndoGrid == null) return;

    _undoGrid = _pendingUndoGrid;
    _undoMoves = _pendingUndoMoves;
    _undoScore = _pendingUndoScore;
    _undoBees = _pendingUndoBees;
    _undoBestCombo = _pendingUndoBestCombo;
    _hasUndo = true;
    _clearPendingUndoState();
  }

  void _clearPendingUndoState() {
    _pendingUndoGrid = null;
    _pendingUndoMoves = null;
    _pendingUndoScore = null;
    _pendingUndoBees = null;
    _pendingUndoBestCombo = null;
  }

  void _recordPlayerAction() {
    _clearHint();
    _clearToolHint();
    _shuffleAttempts = 0;
    _cancelStagnationTimers();
    _scheduleHintTimer();
  }

  void _cancelStagnationTimers() {
    _hintTimer?.cancel();
    _toolHintTimer?.cancel();
    _hintTimer = null;
    _toolHintTimer = null;
  }

  void _scheduleHintTimer() {
    _hintTimer?.cancel();
    _hintTimer = Timer(_hintDelay, _triggerHint);
  }

  void _clearHint() {
    if (_hintTiles.isNotEmpty) {
      setState(() => _hintTiles.clear());
    }
  }

  void _setToolHint(ToolHintTarget target) {
    if (_currentHintTool == target) return;
    setState(() => _currentHintTool = target);
    _hintTimer?.cancel();
    _hintTimer = null;
    _toolHintTimer?.cancel();
    _toolHintTimer = Timer(_toolHintTimeout, () {
      if (_currentHintTool == target) {
        _clearToolHint();
        if (!_hasValidMoveExists() && !_offerToolHint()) {
          _attemptAutoShuffle();
        } else {
          _scheduleHintTimer();
        }
      }
    });
  }

  void _clearToolHint() {
    if (_currentHintTool != ToolHintTarget.none) {
      setState(() => _currentHintTool = ToolHintTarget.none);
    }
    _toolHintTimer?.cancel();
    _toolHintTimer = null;
  }

  bool _offerToolHint() {
    if (smashCount > 0) {
      _setToolHint(ToolHintTarget.smash);
      return true;
    }
    if (shuffleCount > 0) {
      _setToolHint(ToolHintTarget.shuffle);
      return true;
    }
    if (blastCount > 0) {
      _setToolHint(ToolHintTarget.blast);
      return true;
    }
    return false;
  }

  void _triggerHint() {
    if (_hintTiles.isNotEmpty) return;
    if (!_hasValidMoveExists()) {
      if (!_offerToolHint()) {
        _attemptAutoShuffle();
      }
      return;
    }

    final pair = _findHintSwap();
    if (pair == null) {
      _attemptAutoShuffle();
      return;
    }

    setState(() {
      _hintTiles
        ..clear()
        ..addAll(pair);
    });
  }

  Future<void> _attemptAutoShuffle() async {
    if (_shuffleAttempts >= 2) return;
    _shuffleAttempts++;
    _clearHint();
    _cancelStagnationTimers();
    _clearToolHint();

    _initGrid();
    await _removeInitialMatches();
    setState(() {});
    await _triggerAutoExplosions();

    _scheduleHintTimer();
  }

  Future<void> _triggerAutoExplosions() async {
    final matches = _findAllMatches();
    if (matches.isEmpty) {
      if (_gridSize >= 3) {
        final fillType = AnimalType.bee;
        grid[0][0] = grid[0][1] = grid[0][2] = fillType;
        setState(() {});
      }
    }
    await _processMatches();
  }

  bool _hasValidMoveExists() {
    for (int y = 0; y < _gridSize; y++) {
      for (int x = 0; x < _gridSize; x++) {
        if (_checkSwapCreatesMatch(x, y, x + 1, y)) return true;
        if (_checkSwapCreatesMatch(x, y, x, y + 1)) return true;
      }
    }
    return false;
  }

  List<String>? _findHintSwap() {
    for (int y = 0; y < _gridSize; y++) {
      for (int x = 0; x < _gridSize; x++) {
        if (_checkSwapCreatesMatch(x, y, x + 1, y)) {
          return ['$x,$y', '${x + 1},$y'];
        }
        if (_checkSwapCreatesMatch(x, y, x, y + 1)) {
          return ['$x,$y', '$x,${y + 1}'];
        }
      }
    }
    return null;
  }

  bool _checkSwapCreatesMatch(int x1, int y1, int x2, int y2) {
    if (x2 >= _gridSize || y2 >= _gridSize) return false;
    final first = grid[y1][x1];
    final second = grid[y2][x2];
    if (first == null || second == null) return false;

    _swapGrid(x1, y1, x2, y2);
    final matches = _findAllMatches();
    _swapGrid(x1, y1, x2, y2);

    return matches.isNotEmpty;
  }

  void _swapGrid(int x1, int y1, int x2, int y2) {
    final temp = grid[y1][x1];
    grid[y1][x1] = grid[y2][x2];
    grid[y2][x2] = temp;
  }

  void _performUndo() {
    if (!_hasUndo || _undoGrid == null) return;

    _cancelPendingLevelTransition();
    setState(() {
      grid = _undoGrid!.map((row) => List<AnimalType?>.from(row)).toList();
      movesRemaining = _undoMoves!;
      score = _undoScore!;
      collectedBees = _undoBees!;
      bestCombo = _undoBestCombo!;
      _hasUndo = false;
      _undoGrid = null;
      selectedX = null;
      selectedY = null;
      matchedTiles.clear();
      specialMatchTiles.clear();
    });
    _recordPlayerAction();
  }

  void _onUndoPressed() {
    if (!_hasUndo) {
      _showUndoSnack('Geri alınacak hamle yok.');
      return;
    }

    if (GameConstants.rewardedUndoEnabled) {
      _showRewardedUndoDialog();
    } else {
      _performUndoAndNotify();
    }
  }

  void _performUndoAndNotify() {
    _performUndo();
    _showUndoSnack('Son hamle geri alındı.');
  }

  void _showUndoSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  void _showRewardedUndoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.undo_rounded, color: Colors.deepPurple),
            SizedBox(width: 8),
            Text('Hamleyi Geri Al'),
          ],
        ),
        content: const Text(
          'Bir reklam izleyerek son hamlenizi geri alabilirsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _tryShowRewardedUndoAd();
            },
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Reklam İzle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _tryShowRewardedUndoAd() async {
    final ready = await RewardedAdService.instance.ensureRewardedAdReady();
    if (!mounted) return;

    if (!ready) {
      final loadError =
          RewardedAdService.instance.lastLoadErrorMessage?.trim();
      final message = loadError == null || loadError.isEmpty
          ? 'Reklam henüz hazır değil, lütfen birkaç saniye sonra tekrar dene.'
          : 'Reklam yüklenemedi: $loadError';
      _showUndoSnack(
        message,
      );
      return;
    }

    RewardedAdService.instance.showRewardedAd(
      onUserEarnedReward: () {
        if (!mounted) return;
        _performUndoAndNotify();
      },
      onAdFailedToShow: () {
        if (!mounted) return;
        _showUndoSnack('Reklam gösterilemedi. Lütfen tekrar dene.');
      },
    );
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _toolHintTimer?.cancel();
    _cancelPendingLevelTransition();
    _clearPendingUndoState();
    super.dispose();
  }
  // ==================== MATCH-3 LOGIC ====================

  Set<String> _findAllMatches() {
    final matches = <String>{};
    final horizontalMatches = <String, List<String>>{};
    final verticalMatches = <String, List<String>>{};

    // Check horizontal matches (3+ in a row)
    for (int y = 0; y < _gridSize; y++) {
      int matchStart = 0;
      AnimalType? currentAnimal = grid[y][0];

      for (int x = 1; x <= _gridSize; x++) {
        final animal = x < _gridSize ? grid[y][x] : null;

        if (animal == currentAnimal && animal != null) {
          continue;
        }

        final matchLength = x - matchStart;
        if (matchLength >= 3 && currentAnimal != null) {
          final matchList = <String>[];
          for (int i = matchStart; i < x; i++) {
            final pos = '$i,$y';
            matches.add(pos);
            matchList.add(pos);
          }
          for (final pos in matchList) {
            horizontalMatches[pos] = matchList;
          }
        }

        matchStart = x;
        currentAnimal = animal;
      }
    }

    // Check vertical matches (3+ in a column)
    for (int x = 0; x < _gridSize; x++) {
      int matchStart = 0;
      AnimalType? currentAnimal = grid[0][x];

      for (int y = 1; y <= _gridSize; y++) {
        final animal = y < _gridSize ? grid[y][x] : null;

        if (animal == currentAnimal && animal != null) {
          continue;
        }

        final matchLength = y - matchStart;
        if (matchLength >= 3 && currentAnimal != null) {
          final matchList = <String>[];
          for (int i = matchStart; i < y; i++) {
            final pos = '$x,$i';
            matches.add(pos);
            matchList.add(pos);
          }
          for (final pos in matchList) {
            verticalMatches[pos] = matchList;
          }
        }

        matchStart = y;
        currentAnimal = animal;
      }
    }

    // Check for L-shapes and T-shapes (junction points)
    final connectedMatches = <String>{};
    for (final pos in matches) {
      if (horizontalMatches.containsKey(pos) &&
          verticalMatches.containsKey(pos)) {
        connectedMatches.addAll(horizontalMatches[pos]!);
        connectedMatches.addAll(verticalMatches[pos]!);
      }
    }
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

      // Play sound effect
      if (isSpecialMatch) {
        SoundService.playCombo();
      } else {
        SoundService.playMatch();
      }

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

        final currentTile = grid[y][x];
        if (currentTile == null) continue;

        final shouldScore = currentTile == AnimalType.bee || _countsAllMatches;
        if (shouldScore) {
          collectedBees++;
        }
        if (currentTile == AnimalType.bee) {
          beeBonus++;
        }

        score += _scoreForMatchTile(currentTile, comboCount, isSpecialMatch);

        grid[y][x] = null;
      }

      // Show bonus message (doesn't trigger rebuild)
      if (isSpecialMatch && beeBonus > 0 && mounted) {
        collectedBees += beeBonus; // Double bee collection for 5+ matches

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🌟 SÜPER COMBO! ${matches.length} eşleşme! +$beeBonus bonus arı!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.deepPurple,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
        await Future.delayed(
          const Duration(milliseconds: 30),
        ); // Reduced from 50ms
      }
    }
  }

  Future<void> _fillEmptySpaces() async {
    int emptyCount = 0;
    for (int x = 0; x < _gridSize; x++) {
      for (int y = 0; y < _gridSize; y++) {
        if (grid[y][x] == null) {
          emptyCount++;
        }
      }
    }

    if (emptyCount == 0) return;

    final newTiles = _generateTiles(emptyCount);

    int index = 0;
    for (int x = 0; x < _gridSize; x++) {
      for (int y = 0; y < _gridSize; y++) {
        if (grid[y][x] == null) {
          grid[y][x] = newTiles[index++];
        }
      }
    }

    setState(() {});
    await Future.delayed(const Duration(milliseconds: 80));
  }

  // ==================== INTERACTION ====================

  void _onTileSelect(int x, int y) {
    if (isProcessing || isPaused) return;

    // Smash mode: tap a tile to smash it + neighbors
    if (isSmashMode) {
      _executeSmash(x, y);
      return;
    }

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
    if (targetX >= 0 &&
        targetX < _gridSize &&
        targetY >= 0 &&
        targetY < _gridSize) {
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

    _captureUndoState();

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
      _clearPendingUndoState();

      setState(() {});
      await Future.delayed(const Duration(milliseconds: 150));
    } else {
      // Commit the pre-move snapshot only after confirming the move is valid.
      _commitUndoState();

      // Valid move - process matches
      movesRemaining--;
      await _processMatches();

      // Check win/lose
      _checkGameEnd();
    }

    setState(() {
      isProcessing = false;
    });
    _recordPlayerAction();
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
        content: const Text(
          'Oyunu yeniden başlatmak istediğinize emin misiniz? Mevcut ilerlemeniz kaybolacak.',
        ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ==================== POWER-UPS ====================

  void _onSmash() {
    if (isProcessing || isPaused || smashCount <= 0) return;

    setState(() {
      isSmashMode = !isSmashMode;
      selectedX = null;
      selectedY = null;
    });

    if (isSmashMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Smash: Bir tile\'a dokun, onu ve komşularını patlat!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _executeSmash(int x, int y) async {
    if (isProcessing) return;

    setState(() {
      isSmashMode = false;
      isProcessing = true;
      smashCount--;
    });

    // Smash target tile + 4 adjacent neighbors (cross shape)
    final targets = [
      [x, y],
      [x - 1, y],
      [x + 1, y],
      [x, y - 1],
      [x, y + 1],
    ];

    for (final t in targets) {
      final tx = t[0];
      final ty = t[1];
      if (tx >= 0 && tx < _gridSize && ty >= 0 && ty < _gridSize) {
        if (grid[ty][tx] == AnimalType.bee) {
          collectedBees++;
        }
        score += 10;
        grid[ty][tx] = null;
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
    _recordPlayerAction();
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
    _recordPlayerAction();
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
        if (x >= 0 && x < _gridSize && y >= 0 && y < _gridSize) {
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
    _recordPlayerAction();
  }

  // ==================== NAVIGATION ====================

  void _showLevelComplete() {
    _cancelPendingLevelTransition();
    UserService.resetLevelFails(widget.levelId);
    final movesUsed = _getInitialMoves() - movesRemaining;
    final starsEarned = _calculateStars();

    unawaited(
      AnalyticsService.logLevelComplete(
        levelId: widget.levelId,
        score: score,
        starsEarned: starsEarned,
        movesUsed: movesUsed,
        bestCombo: bestCombo,
      ),
    );
    _pendingLevelTransitionTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.go(
          AppRoutes.levelComplete,
          extra: {
            'levelId': widget.levelId,
            'score': score,
            'starsEarned': _calculateStars(),
            'movesUsed': _getInitialMoves() - movesRemaining,
            'bestCombo': bestCombo,
          },
        );
      }
    });
  }

  void _showLevelFailed() {
    _cancelPendingLevelTransition();
    final failCount = UserService.recordLevelFail(widget.levelId);

    // Every 3 fails, gift 2 shuffles and restart
    if (failCount % 3 == 0) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.card_giftcard_rounded,
                color: Colors.deepPurple,
                size: 28,
              ),
              SizedBox(width: 8),
              Text('Hediye!'),
            ],
          ),
          content: const Text(
            '3 deneme hakkını kullandın!\n\n+2 Shuffle hediyesi kazandın! Tekrar dene!',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  shuffleCount += 2;
                });
                _resetGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
      return;
    }

    _pendingLevelTransitionTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        unawaited(
          AnalyticsService.logLevelFailed(
            levelId: widget.levelId,
            movesUsed: _getInitialMoves() - movesRemaining,
            progress: collectedBees,
            target: targetBees,
          ),
        );
        context.go(
          AppRoutes.levelFailed,
          extra: {
            'levelId': widget.levelId,
            'currentProgress': collectedBees,
            'targetProgress': targetBees,
            'objectiveLabel': 'Collect Bees',
          },
        );
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_hasUndo) {
          _onUndoPressed();
        } else {
          context.go(AppRoutes.splash);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade100, AppColors.backgroundLight],
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
                    Expanded(child: Center(child: _buildGameGrid())),
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                const Icon(
                  Icons.flag_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${UserService.nickname} • Lv ${widget.levelId}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Score display
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                  const Icon(
                    Icons.star_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 2),
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
          const SizedBox(width: 6),
          // Undo button
          _buildHeaderButton(
            icon: Icons.undo_rounded,
            onTap: _onUndoPressed,
            tooltip: 'Geri Al',
            isDisabled: !_hasUndo,
          ),
          const SizedBox(width: 6),
          // Restart button
          _buildHeaderButton(
            icon: Icons.refresh_rounded,
            onTap: _showRestartDialog,
            tooltip: 'Yeniden Başlat',
          ),
          const SizedBox(width: 6),
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
    VoidCallback? onTap,
    required String tooltip,
    bool isDisabled = false,
  }) {
    return Opacity(
      opacity: isDisabled ? 0.4 : 1.0,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        elevation: 2,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: AppColors.textPrimary, size: 20),
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
          addRepaintBoundaries:
              false, // We're using RepaintBoundary in GameTile
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
              isHinted: _hintTiles.contains('$x,$y'),
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
          _buildToolButton(
            Icons.construction_rounded,
            'Smash',
            smashCount,
            _onSmash,
            isActive: isSmashMode,
            isHinted: _currentHintTool == ToolHintTarget.smash,
          ),
          _buildToolButton(
            Icons.shuffle_rounded,
            'Shuffle',
            shuffleCount,
            _onShuffle,
            isHinted: _currentHintTool == ToolHintTarget.shuffle,
          ),
          _buildToolButton(
            Icons.rocket_launch_rounded,
            'Blast',
            blastCount,
            _onBlast,
            isHinted: _currentHintTool == ToolHintTarget.blast,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(
    IconData icon,
    String label,
    int? count,
    VoidCallback onTap, {
    bool isActive = false,
    bool isHinted = false,
  }) {
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
                    color: isActive || isHinted
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isHinted
                          ? AppColors.hintGlow
                          : isActive
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      width: isHinted || isActive ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isActive
                        ? AppColors.primary
                        : isDisabled
                        ? Colors.grey
                        : AppColors.textSecondary,
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
