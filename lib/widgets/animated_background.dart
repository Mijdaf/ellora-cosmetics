import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Three soft RadialGradient blobs that drift along slow Lissajous-style
/// paths and gently "breathe" (scale in and out) as they go — reads like a
/// slow aurora behind the page rather than a fixed spot light. Cheap: just
/// three circles re-placed/re-scaled each tick, no blur filters.
class AuroraGlow extends StatefulWidget {
  final bool isDark;
  const AuroraGlow({super.key, required this.isDark});

  @override
  State<AuroraGlow> createState() => _AuroraGlowState();
}

class _AuroraGlowState extends State<AuroraGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 30))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.wheatGold;
    final espresso = widget.isDark ? AppColors.wheatGoldLight : AppColors.espresso;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 2400.0;

        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value * 2 * math.pi;
            return Stack(
              children: [
                _blob(
                  cx: width * 0.22 + math.sin(t * 0.8) * width * 0.16,
                  cy: height * 0.14 + math.cos(t * 1.3) * height * 0.05,
                  size: width.clamp(360.0, 620.0) * (0.85 + math.sin(t) * 0.12),
                  color: gold,
                  opacity: widget.isDark ? 0.11 : 0.15,
                ),
                _blob(
                  cx: width * 0.8 + math.cos(t * 0.6) * width * 0.14,
                  cy: height * 0.42 + math.sin(t * 1.1) * height * 0.07,
                  size: width.clamp(300.0, 560.0) * (0.9 + math.cos(t * 1.4) * 0.14),
                  color: espresso,
                  opacity: widget.isDark ? 0.13 : 0.08,
                ),
                _blob(
                  cx: width * 0.35 + math.sin(t * 1.2) * width * 0.20,
                  cy: height * 0.78 + math.cos(t * 0.7) * height * 0.06,
                  size: width.clamp(320.0, 580.0) * (0.8 + math.sin(t * 0.9) * 0.16),
                  color: gold,
                  opacity: widget.isDark ? 0.08 : 0.12,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _blob({required double cx, required double cy, required double size, required Color color, required double opacity}) {
    return Positioned(
      left: cx - size / 2,
      top: cy - size / 2,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(opacity), color.withOpacity(0)],
          ),
        ),
      ),
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
