import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_backdrop.dart';
import 'home_screen.dart';

/// First thing shoppers see: the Nafas logo on a branded espresso
/// background, held on screen for a fixed duration before the storefront
/// fades in underneath it.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const Duration _splashDuration = Duration(seconds: 5);

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    // Drives the three-dot "breathing" loop below the logo — repeats for
    // as long as the splash is on screen.
    _dotsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

    Future.delayed(_splashDuration, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackdrop(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppColors.espresso, AppColors.espressoDeep],
                      ),
                      border: Border.all(color: AppColors.wheatGold.withOpacity(0.55), width: 2),
                      boxShadow: [
                        BoxShadow(color: AppColors.wheatGold.withOpacity(0.4), blurRadius: 70, spreadRadius: 6),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.espressoDeep,
                          alignment: Alignment.center,
                          child: const Icon(Icons.eco, color: AppColors.wheatGold, size: 80),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Tagline under the logo, echoing the wordmark's own
                  // caption so the brand name reads even before the
                  // storefront loads.
                  Text(
                    'مخبوز بحب',
                    style: AppTheme.eyebrow(isArabic: true).copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 36),
                  _LoadingDots(controller: _dotsController),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three dots that rise and glow in a staggered wave — a warmer, more
/// "alive" stand-in for a plain spinner while the splash holds on screen.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.controller});

  final AnimationController controller;

  static const int _dotCount = 4;
  static const double _dotSize = 10;
  static const double _travel = 10; // how far each dot rises, in pixels

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_dotCount, (i) {
            // Each dot's wave is offset from the next by a fixed phase, so
            // they rise one after another instead of all bouncing in sync.
            final phase = i / _dotCount;
            final t = (controller.value + phase) % 1.0;
            // 0 -> 1 -> 0 triangle wave, eased, drives both lift and glow.
            final wave = Curves.easeInOut.transform(1 - (2 * t - 1).abs());

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: _dotSize * 0.45),
              child: Transform.translate(
                offset: Offset(0, -_travel * wave),
                child: Container(
                  width: _dotSize,
                  height: _dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(
                      AppColors.wheatGold.withOpacity(0.35),
                      AppColors.wheatGoldLight,
                      wave,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.wheatGold.withOpacity(0.45 * wave),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
