import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Objective progress bar widget (based on design spec)
class ObjectiveProgress extends StatelessWidget {
  const ObjectiveProgress({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    this.icon,
  });

  final String label;
  final int current;
  final int target;
  final String? icon;

  double get progress => (current / target).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.1),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Text(icon!, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '$current/$target',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _AnimatedProgressBar(progress: progress),
        ],
      ),
    );
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  const _AnimatedProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: constraints.maxWidth * progress,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Animated stripe pattern
              if (progress > 0)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: _StripePattern(progress: progress),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StripePattern extends StatefulWidget {
  const _StripePattern({required this.progress});

  final double progress;

  @override
  State<_StripePattern> createState() => _StripePatternState();
}

class _StripePatternState extends State<_StripePattern>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FractionallySizedBox(
          widthFactor: widget.progress,
          alignment: Alignment.centerLeft,
          child: CustomPaint(
            painter: _StripePainter(
              offset: _controller.value * 20,
            ),
          ),
        );
      },
    );
  }
}

class _StripePainter extends CustomPainter {
  _StripePainter({required this.offset});

  final double offset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    for (double x = -size.height + offset; x < size.width + size.height; x += 20) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) => oldDelegate.offset != offset;
}
