import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
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
    this.isHinted = false,
  });

  final AnimalType? animal;
  final bool isSelected;
  final bool isMatched;
  final bool isSpecialMatch;
  final VoidCallback onTap;
  final Function(String direction)? onSwipe;
  final bool isHinted;

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
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isHinted)
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.hintGlow.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              AnimatedScale(
                scale: isSelected ? 1.02 : isSpecialMatch ? 1.06 : 1.0,
                duration: Duration(milliseconds: isSpecialMatch ? 400 : 150),
                child: Image.asset(
                  animalType.assetPath,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => Text(
                    animalType.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
