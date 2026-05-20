import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../core/router/app_router.dart';

/// Level failed screen with rewarded ad offer (based on design spec)
class LevelFailedScreen extends StatefulWidget {
  const LevelFailedScreen({
    super.key,
    required this.levelId,
    required this.currentProgress,
    required this.targetProgress,
    required this.objectiveLabel,
  });

  final int levelId;
  final int currentProgress;
  final int targetProgress;
  final String objectiveLabel;

  @override
  State<LevelFailedScreen> createState() => _LevelFailedScreenState();
}

class _LevelFailedScreenState extends State<LevelFailedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  double get _progress => widget.currentProgress / widget.targetProgress;
  int get _progressPercent => (_progress * 100).round();

  void _onWatchAd() {
    // Simulate watching ad and getting extra moves
    // In real implementation, this would show rewarded ad
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '+${GameConstants.extraMovesReward} moves granted! (Ad simulation)',
        ),
        backgroundColor: AppColors.success,
      ),
    );
    // Return to game with extra moves
    context.go(AppRoutes.game, extra: widget.levelId);
  }

  void _onTryAgain() {
    context.go(AppRoutes.game, extra: widget.levelId);
  }

  void _onClose() {
    context.go(AppRoutes.splash);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade200,
              Colors.grey.shade100,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with lives and close
              _buildHeader(),
              const Spacer(),
              // Main content card
              _buildContentCard(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            elevation: 2,
            child: InkWell(
              onTap: _onClose,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),
          ),
          // Lives counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: Colors.red.shade400,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  '0 Lives',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.15),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top gradient decoration
          Container(
            height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.5),
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Sad mascot
                _buildSadMascot(),
                const SizedBox(height: 24),
                // Title
                const Text(
                  'Out of Moves!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  "Don't give up! You're so close to clearing the level.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                // Progress section
                _buildProgressSection(),
                const SizedBox(height: 24),
                // Buttons
                _buildButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSadMascot() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Mascot container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.beeColor.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.shade300,
              width: 3,
            ),
          ),
          child: const Center(
            child: Text(
              '🐝',
              style: TextStyle(fontSize: 50),
            ),
          ),
        ),
        // Broken heart indicator
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Text('💔', style: TextStyle(fontSize: 20)),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Goal status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/images/sprite/bee.png',
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.objectiveLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                '${widget.currentProgress}/${widget.targetProgress}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar with shine effect
          _buildShinyProgressBar(),
          const SizedBox(height: 8),
          // Percentage
          Text(
            '$_progressPercent% Complete',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShinyProgressBar() {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Progress fill
          FractionallySizedBox(
            widthFactor: _progress,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Shine effect
          if (_progress > 0)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: FractionallySizedBox(
                widthFactor: _progress,
                child: _ShineEffect(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        // Primary: Watch Ad
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: child,
            );
          },
          child: _WatchAdButton(onPressed: _onWatchAd),
        ),
        const SizedBox(height: 12),
        // Secondary: Try Again
        TextButton.icon(
          onPressed: _onTryAgain,
          icon: const Icon(Icons.replay_rounded, size: 20),
          label: const Text('Try Again'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }
}

/// Watch ad button with shimmer effect
class _WatchAdButton extends StatefulWidget {
  const _WatchAdButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_WatchAdButton> createState() => _WatchAdButtonState();
}

class _WatchAdButtonState extends State<_WatchAdButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryLight, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark,
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
            BoxShadow(
              color: AppColors.shadowColor,
              offset: const Offset(0, 6),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Shimmer overlay
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ShimmerPainter(
                        progress: _shimmerController.value,
                      ),
                    );
                  },
                ),
              ),
            ),
            // Content
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.videocam_rounded,
                  color: AppColors.textOnPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'WATCH AD - Get +5 Moves',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shine effect for progress bar
class _ShineEffect extends StatefulWidget {
  @override
  State<_ShineEffect> createState() => _ShineEffectState();
}

class _ShineEffectState extends State<_ShineEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
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
        return CustomPaint(
          painter: _ShinePainter(progress: _controller.value),
        );
      },
    );
  }
}

class _ShinePainter extends CustomPainter {
  _ShinePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final shineWidth = size.width * 0.3;
    final x = -shineWidth + (size.width + shineWidth * 2) * progress;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.4),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(x, 0, shineWidth, size.height));

    canvas.drawRect(
      Rect.fromLTWH(x, 0, shineWidth, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final shineWidth = size.width * 0.4;
    final x = -shineWidth + (size.width + shineWidth * 2) * progress;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(x, 0, shineWidth, size.height));

    canvas.drawRect(
      Rect.fromLTWH(x, 0, shineWidth, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
