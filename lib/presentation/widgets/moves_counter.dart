import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Circular moves counter widget (based on design spec)
class MovesCounter extends StatelessWidget {
  const MovesCounter({
    super.key,
    required this.movesRemaining,
    this.size = 64,
  });

  final int movesRemaining;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark,
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
          BoxShadow(
            color: AppColors.shadowColor,
            offset: const Offset(0, 4),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$movesRemaining',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnPrimary,
              height: 1,
            ),
          ),
          Text(
            'Moves',
            style: TextStyle(
              fontSize: size * 0.15,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
