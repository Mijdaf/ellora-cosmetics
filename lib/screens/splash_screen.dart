import 'package:flutter/material.dart';
import '../services/supabase_config.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_backdrop.dart';
import 'admin_gate_screen.dart';
import 'home_screen.dart';

/// First thing shoppers see: the Ellora Cosmetics logo on a branded deep
/// rose background, held on screen for a fixed duration before the
/// storefront fades in underneath it.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  static const Duration _splashDuration = Duration(seconds: 2);

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

    // Check for an active admin session as early as possible, in parallel
    // with the entrance animation — don't wait for the full shopper-facing
    // splash duration to find out. If the browser tab gets reloaded (OS
    // discarding a backgrounded tab to save memory/battery, or a bookmark
    // that points at the bare domain instead of '#/admin') while the admin
    // is on the dashboard, this is what sends them straight back to the
    // dashboard instead of forcing them through the public storefront —
    // which is what looked like "the dashboard kicks me out to the site".
    _decideDestination();
  }

  Future<void> _decideDestination() async {
    await SupabaseConfig.ready;
    if (!mounted) return;
    final isAdminSession = SupabaseConfig.isLoggedIn;

    if (isAdminSession) {
      // Just enough time for the entrance animation to feel intentional,
      // not the full 2s public splash — an admin bouncing back from a
      // reload should land back on their dashboard almost immediately.
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const AdminGateScreen(),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
      return;
    }

    await Future.delayed(_splashDuration);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppMood.isDark,
      builder: (context, isDark, _) {
        // Same background tone the home screen uses, so there's no visual
        // "flash" or mismatch when the splash hands off to the storefront.
        final bgColor = isDark ? AppColors.espressoDark : AppColors.surfaceCream;

        return Scaffold(
          body: AnimatedBackdrop(
            baseColor: bgColor,
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 320,
                        height: 320,
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.espressoDeep,
                            alignment: Alignment.center,
                            child: const Icon(Icons.spa, color: AppColors.wheatGold, size: 80),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Spans the full screen width (instead of a tight
                      // cluster right under the logo) and each dot is a
                      // little bigger, per request.
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: _LoadingDots(controller: _dotsController),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Three dots that rise and glow in a staggered wave — a warmer, more
/// "alive" stand-in for a plain spinner while the splash holds on screen.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.controller});

  final AnimationController controller;

  static const int _dotCount = 4;
  static const double _dotSize = 13; // was 10 — a bit bigger, per request
  static const double _travel = 10; // how far each dot rises, in pixels

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Row(
          // spaceEvenly instead of the previous tight/packed row — now
          // that this Row is stretched to the full screen width by the
          // SizedBox in SplashScreen, this spreads the dots out across
          // that width instead of leaving them bunched on one side.
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
