import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../core/constants/app_colors.dart';

/// Star rating display widget (based on design spec)
class StarRating extends StatefulWidget {
  const StarRating({
    super.key,
    required this.starsEarned,
    this.size = 60,
    this.animated = true,
  });

  final int starsEarned;
  final double size;
  final bool animated;

  @override
  State<StarRating> createState() => _StarRatingState();
}

class _StarRatingState extends State<StarRating>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _starAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _starAnimations = List.generate(3, (index) {
      final start = index * 0.2;
      final end = start + 0.4;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.elasticOut),
        ),
      );
    });

    if (widget.animated) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isEarned = index < widget.starsEarned;
        final isMiddle = index == 1;

        return AnimatedBuilder(
          animation: _starAnimations[index],
          builder: (context, child) {
            final scale = _starAnimations[index].value;
            final rotation = isMiddle ? 0.0 : (index == 0 ? -0.1 : 0.1);

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..scaleByVector3(Vector3(scale, scale, scale))
                ..rotateZ(rotation),
              child: _StarIcon(
                isEarned: isEarned,
                size: isMiddle ? widget.size * 1.2 : widget.size,
                elevated: isMiddle,
              ),
            );
          },
        );
      }),
    );
  }
}

class _StarIcon extends StatelessWidget {
  const _StarIcon({
    required this.isEarned,
    required this.size,
    this.elevated = false,
  });

  final bool isEarned;
  final double size;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: elevated ? 10 : 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shadow
          if (isEarned)
            Icon(
              Icons.star,
              size: size,
              color: AppColors.primaryDark.withValues(alpha: 0.5),
            ),
          // Star
          Transform.translate(
            offset: isEarned ? const Offset(0, -2) : Offset.zero,
            child: Icon(
              Icons.star,
              size: size,
              color: isEarned ? AppColors.primary : Colors.grey.shade300,
              shadows: isEarned
                  ? [
                      Shadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 20,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
