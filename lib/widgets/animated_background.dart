import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Blurred, drifting gold/espresso orbs plus a scatter of twinkling
/// particles — the same painting technique as the splash screen's aurora
/// (`AnimatedBackdrop`/`_BackdropPainter`): a `CustomPainter` drawing
/// `RadialGradient`-shaded circles through a Gaussian `MaskFilter` blur,
/// instead of plain un-blurred `Container` blobs. Kept as its own painter
/// (rather than reusing `AnimatedBackdrop` directly) because the home page
/// needs it to span the *whole scrollable content height* — not just one
/// fixed viewport — and to sit on top of the page's own mood gradient
/// instead of painting an opaque backdrop color of its own.
class AuroraGlow extends StatefulWidget {
  final bool isDark;
  const AuroraGlow({super.key, required this.isDark});

  @override
  State<AuroraGlow> createState() => _AuroraGlowState();
}

class _AuroraGlowState extends State<AuroraGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();
  final List<_AuroraParticle> _particles = List.generate(14, (i) => _AuroraParticle.random(i));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.wheatGold;
    final goldLight = AppColors.wheatGoldLight;
    final espresso = widget.isDark ? AppColors.wheatGoldLight : AppColors.espresso;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 2400.0;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: Size(constraints.maxWidth, height),
              painter: _AuroraPainter(
                t: _controller.value,
                isDark: widget.isDark,
                gold: gold,
                goldLight: goldLight,
                espresso: espresso,
                particles: _particles,
              ),
            );
          },
        );
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t; // 0..1 looping
  final bool isDark;
  final Color gold;
  final Color goldLight;
  final Color espresso;
  final List<_AuroraParticle> particles;

  _AuroraPainter({
    required this.t,
    required this.isDark,
    required this.gold,
    required this.goldLight,
    required this.espresso,
    required this.particles,
  });

  void _orb(Canvas canvas, Offset center, double radius, Color color, double opacity) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withOpacity(opacity), color.withOpacity(0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final angle = t * 2 * math.pi;

    _orb(
      canvas,
      Offset(
        width * 0.22 + math.sin(angle * 0.8) * width * 0.16,
        height * 0.14 + math.cos(angle * 1.3) * height * 0.05,
      ),
      width.clamp(360.0, 620.0) * (0.85 + math.sin(angle) * 0.12) / 2,
      gold,
      isDark ? 0.28 : 0.30,
    );

    _orb(
      canvas,
      Offset(
        width * 0.8 + math.cos(angle * 0.6) * width * 0.14,
        height * 0.42 + math.sin(angle * 1.1) * height * 0.07,
      ),
      width.clamp(300.0, 560.0) * (0.9 + math.cos(angle * 1.4) * 0.14) / 2,
      espresso,
      isDark ? 0.28 : 0.20,
    );

    _orb(
      canvas,
      Offset(
        width * 0.35 + math.sin(angle * 1.2) * width * 0.20,
        height * 0.78 + math.cos(angle * 0.7) * height * 0.06,
      ),
      width.clamp(320.0, 580.0) * (0.8 + math.sin(angle * 0.9) * 0.16) / 2,
      goldLight,
      isDark ? 0.22 : 0.26,
    );

    // Fourth orb — deep, slow pulse — same fourth-layer treatment the
    // splash screen's aurora has, absent from the old flat 3-blob version.
    final pulse = 0.85 + math.sin(angle * 1.6) * 0.15;
    _orb(
      canvas,
      Offset(
        width * 0.58 + math.cos(angle * 0.4 + 1.3) * width * 0.12,
        height * 0.60 + math.sin(angle * 0.55 + 0.7) * height * 0.08,
      ),
      width.clamp(320.0, 620.0) * 0.42 * pulse,
      gold,
      isDark ? 0.20 : 0.20,
    );

    // Twinkling particle scatter, spread across the full page height —
    // same twinkle formula as the splash screen's aurora, brightened to
    // match its more vivid look.
    for (final p in particles) {
      final dx = (p.xBase + math.sin(angle * p.speed + p.seed) * 0.04) % 1.0 * width;
      final dy = ((p.yBase - t * p.speed * 0.05 + p.seed) % 1.0) * height;
      final twinkle = 0.5 + 0.5 * math.sin(angle * (1.5 + p.speed) + p.seed * 3);
      final paint = Paint()
        ..color = (p.bright ? goldLight : gold).withOpacity((isDark ? 0.30 : 0.34) + 0.34 * twinkle);
      canvas.drawCircle(Offset(dx, dy), p.radius * (0.8 + 0.4 * twinkle), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter oldDelegate) => true;
}

class _AuroraParticle {
  final double seed;
  final double radius;
  final double speed;
  final double xBase;
  final double yBase;
  final bool bright;

  _AuroraParticle({
    required this.seed,
    required this.radius,
    required this.speed,
    required this.xBase,
    required this.yBase,
    required this.bright,
  });

  factory _AuroraParticle.random(int i) {
    final rnd = math.Random(i * 977);
    return _AuroraParticle(
      seed: rnd.nextDouble() * math.pi * 2,
      radius: 1.3 + rnd.nextDouble() * 2.4,
      speed: 0.4 + rnd.nextDouble() * 0.8,
      xBase: rnd.nextDouble(),
      yBase: rnd.nextDouble(),
      bright: rnd.nextBool(),
    );
  }
}

/// One shared field of faint floating pastry emoji, painted once behind a
/// whole scrollable (or fixed) page so the same motif repeats consistently
/// top to bottom, on any screen that uses it.
class PageFloatingTokens extends StatefulWidget {
  final bool isNarrow;
  const PageFloatingTokens({super.key, required this.isNarrow});

  @override
  State<PageFloatingTokens> createState() => _PageFloatingTokensState();
}

class _PageFloatingTokensState extends State<PageFloatingTokens> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();

  static const _tokens = ['🥐', '🍞', '🥖', '🥞', '🍰', '🧁', '🍩', '🥯', '🍪', '🥨'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 2400.0;
        final count = _tokens.length;
        final size = widget.isNarrow ? 32.0 : 46.0;
        // Each emoji appears exactly once, spread evenly down the whole
        // page height (top to bottom) rather than tiled/repeated — a
        // single fixed-size Stack of 10 items, cheap to animate.
        final colWidth = width / count;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final children = <Widget>[
              for (int i = 0; i < count; i++)
                Builder(builder: (context) {
                  final phase = _controller.value * 2 * math.pi + i * 1.05;
                  final zigzag = i.isOdd ? colWidth / 2 : 0.0;
                  final dx = (colWidth * i + colWidth / 2 - size / 2 + zigzag).clamp(0.0, width - size);
                  final dy = (height / count) * i + 40 + math.sin(phase) * 24;
                  return Positioned(
                    left: dx,
                    top: dy,
                    child: Opacity(
                      opacity: 0.13,
                      child: Transform.rotate(
                        angle: math.sin(phase) * 0.3,
                        child: Text(_tokens[i], style: TextStyle(fontSize: size)),
                      ),
                    ),
                  );
                }),
            ];
            return Stack(children: children);
          },
        );
      },
    );
  }
}

/// Convenience wrapper combining [PageFloatingTokens] + [AuroraGlow] behind
/// a screen's content, each wrapped in `IgnorePointer` (so touches pass
/// through to the real UI) and `RepaintBoundary` (so their per-frame
/// repaint never touches the rest of the page). Drop this once, full-size,
/// behind a `Stack` on any screen to match the Home Screen's animated
/// backdrop.
class AnimatedBackground extends StatelessWidget {
  final bool isDark;
  final bool isNarrow;
  const AnimatedBackground({super.key, required this.isDark, this.isNarrow = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: PageFloatingTokens(isNarrow: isNarrow),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: AuroraGlow(isDark: isDark),
            ),
          ),
        ),
      ],
    );
  }
}
