import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../services/user_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/star_rating.dart';

/// Level complete/success screen (based on design spec)
class LevelCompleteScreen extends StatefulWidget {
  const LevelCompleteScreen({
    super.key,
    required this.levelId,
    required this.score,
    required this.starsEarned,
    required this.movesUsed,
    required this.bestCombo,
  });

  final int levelId;
  final int score;
  final int starsEarned;
  final int movesUsed;
  final int bestCombo;

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _contentController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    // Save score and unlock next level
    UserService.saveLevelScore(widget.levelId, widget.score, widget.starsEarned);
    UserService.unlockNextLevel(widget.levelId);
  }

  void _initAnimations() {
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _contentController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onNextLevel() {
    context.go(AppRoutes.game, extra: widget.levelId + 1);
  }

  void _onReplay() {
    context.go(AppRoutes.game, extra: widget.levelId);
  }

  void _onHome() {
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
              Colors.purple.shade100,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Confetti
            _buildConfetti(),
            // Content
            SafeArea(
              child: AnimatedBuilder(
                animation: _contentController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(
            progress: _confettiController.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          // Title
          Text(
            'Level ${widget.levelId} Clear!',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 32),
          // Stars
          StarRating(starsEarned: widget.starsEarned, size: 70),
          const SizedBox(height: 32),
          // Mascot with celebration
          _buildMascot(),
          const SizedBox(height: 32),
          // Stats grid
          _buildStatsGrid(),
          const Spacer(),
          // Buttons
          _buildButtons(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMascot() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        // Mascot container
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.beeColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowColor,
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Image.asset(
                'assets/images/sprite/bee.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        // Celebration emoji
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(8),
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
            child: const Text('🎉', style: TextStyle(fontSize: 24)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          // Total score (full width)
          _buildStatCard(
            label: 'Total Score',
            value: _formatScore(widget.score),
            isLarge: true,
          ),
          const SizedBox(height: 12),
          // Other stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'Moves Used',
                  value: '${widget.movesUsed}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  label: 'Best Combo',
                  value: 'x${widget.bestCombo}',
                  valueColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    bool isLarge = false,
    Color? valueColor,
  }) {
    return Container(
      padding: EdgeInsets.all(isLarge ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 14 : 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 28 : 20,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        // Primary: Next Level
        PrimaryButton(
          text: 'NEXT LEVEL',
          icon: Icons.arrow_forward_rounded,
          onPressed: _onNextLevel,
          width: double.infinity,
        ),
        const SizedBox(height: 16),
        // Secondary buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CircleButton(
              icon: Icons.replay_rounded,
              onPressed: _onReplay,
            ),
            const SizedBox(width: 16),
            _CircleButton(
              icon: Icons.home_rounded,
              onPressed: _onHome,
            ),
            const SizedBox(width: 16),
            _CircleButton(
              icon: Icons.share_rounded,
              onPressed: () {
                // Share functionality
              },
            ),
          ],
        ),
      ],
    );
  }

  String _formatScore(int score) {
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(score % 1000 == 0 ? 0 : 1)}K';
    }
    return score.toString();
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: AppColors.textSecondary,
            size: 24,
          ),
        ),
      ),
    );
  }
}

/// Confetti painter for celebration effect
class ConfettiPainter extends CustomPainter {
  ConfettiPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.yellow,
      Colors.purple,
      Colors.green,
      Colors.pink,
      Colors.orange,
      Colors.teal,
    ];

    final random = _SeededRandom(42);

    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final startY = -50.0 + random.nextDouble() * 100;
      final y = startY + progress * (size.height + 100) * (0.5 + random.nextDouble() * 0.5);
      final color = colors[i % colors.length];
      final rectSize = 8.0 + random.nextDouble() * 8;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;

      if (i % 3 == 0) {
        canvas.drawCircle(Offset(x, y % (size.height + 50)), rectSize / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y % (size.height + 50)),
            width: rectSize,
            height: rectSize * 0.6,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Seeded random for consistent confetti positions
class _SeededRandom {
  _SeededRandom(this._seed);
  int _seed;

  double nextDouble() {
    _seed = (_seed * 1103515245 + 12345) & 0x7fffffff;
    return _seed / 0x7fffffff;
  }
}
