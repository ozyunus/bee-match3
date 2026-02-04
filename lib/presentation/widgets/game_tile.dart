import 'package:flutter/material.dart';
import '../../data/models/animal_type.dart';

/// Optimized individual tile widget with RepaintBoundary
/// This ensures only changed tiles are repainted, not the entire grid
class GameTile extends StatelessWidget {
  const GameTile({
    super.key,
    required this.animal,
    required this.isSelected,
    required this.isMatched,
    required this.isSpecialMatch,
    required this.onTap,
    this.onSwipe,
  });

  final AnimalType? animal;
  final bool isSelected;
  final bool isMatched;
  final bool isSpecialMatch;
  final VoidCallback onTap;
  final Function(String direction)? onSwipe;

  @override
  Widget build(BuildContext context) {
    // Create local non-nullable variable
    final animalType = animal;
    if (animalType == null) {
      return const SizedBox.shrink();
    }

    // RepaintBoundary isolates this tile's repaints
    return RepaintBoundary(
      child: GestureDetector(
        onTapUp: (_) => onTap(),
        onPanEnd: onSwipe != null ? (details) {
          final velocity = details.velocity.pixelsPerSecond;
          if (velocity.dx.abs() > velocity.dy.abs()) {
            // Horizontal swipe
            onSwipe!(velocity.dx > 0 ? 'right' : 'left');
          } else {
            // Vertical swipe
            onSwipe!(velocity.dy > 0 ? 'down' : 'up');
          }
        } : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
        scale: isMatched ? 0.0 : 1.0,
        duration: Duration(milliseconds: isSpecialMatch ? 400 : 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: animalType.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Colors.white
                  : isSpecialMatch
                      ? Colors.yellow.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.3),
              width: isSelected ? 3 : isSpecialMatch ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.8)
                    : isSpecialMatch
                        ? Colors.yellow.withValues(alpha: 0.6)
                        : animalType.color.withValues(alpha: 0.4),
                offset: const Offset(0, 2),
                blurRadius: isSelected ? 8 : isSpecialMatch ? 12 : 4,
              ),
            ],
          ),
          child: Center(
            child: AnimatedScale(
              scale: isSelected ? 1.2 : isSpecialMatch ? 1.3 : 1.0,
              duration: Duration(milliseconds: isSpecialMatch ? 400 : 150),
              child: Text(
                animalType.emoji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
