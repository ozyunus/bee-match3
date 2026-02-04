import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../core/router/app_router.dart';
import '../widgets/primary_button.dart';

/// Splash screen with idle bee animation (based on design spec)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _beeController;
  late AnimationController _glowController;
  late Animation<double> _beeFloatAnimation;
  late Animation<double> _beeRotateAnimation;
  late Animation<double> _glowAnimation;

  Timer? _autoNavigateTimer;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAutoNavigateTimer();
  }

  void _initAnimations() {
    // Bee floating animation
    _beeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _beeFloatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _beeController, curve: Curves.easeInOut),
    );

    _beeRotateAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _beeController, curve: Curves.easeInOut),
    );

    // Glow pulse animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  void _startAutoNavigateTimer() {
    _autoNavigateTimer = Timer(
      const Duration(milliseconds: GameConstants.maxSplashDuration),
      _navigateToGame,
    );
  }

  void _navigateToGame() {
    _autoNavigateTimer?.cancel();
    if (mounted) {
      context.go(AppRoutes.game, extra: 1);
    }
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    _beeController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _navigateToGame,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade200,
                Colors.green.shade100,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),
                // Logo
                _buildLogo(),
                const SizedBox(height: 40),
                // Animated Bee
                _buildAnimatedBee(),
                const Spacer(flex: 2),
                // Start Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: PrimaryButton(
                    text: 'TAP TO START',
                    icon: Icons.play_arrow_rounded,
                    onPressed: _navigateToGame,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(height: 24),
                // Version info
                _buildVersionInfo(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              fontFamily: 'SplineSans',
            ),
            children: [
              const TextSpan(
                text: 'Idle Bee ',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              TextSpan(
                text: 'Match',
                style: TextStyle(
                  color: AppColors.primary,
                  shadows: [
                    Shadow(
                      color: AppColors.primaryDark,
                      offset: const Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedBee() {
    return AnimatedBuilder(
      animation: Listenable.merge([_beeController, _glowController]),
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: _glowAnimation.value,
                    ),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
            // Bee character (placeholder with emoji)
            Transform.translate(
              offset: Offset(0, _beeFloatAnimation.value),
              child: Transform.rotate(
                angle: _beeRotateAnimation.value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.beeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowColor,
                        offset: const Offset(0, 8),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '🐝',
                      style: TextStyle(fontSize: 80),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'v1.0.0',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
