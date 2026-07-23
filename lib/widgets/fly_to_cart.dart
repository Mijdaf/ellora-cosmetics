import 'package:flutter/material.dart';

/// Holds the [GlobalKey] attached to the real cart icon in [NavBar] so any
/// widget in the tree (e.g. a product card's "add" button) can find its
/// current on-screen position without needing to be passed a callback
/// chain all the way down. `nav_bar.dart` attaches this key once to the
/// small icon `SizedBox`; nothing else needs to set it.
class CartIconAnchor {
  CartIconAnchor._();
  static final GlobalKey key = GlobalKey();
}

/// Fires a short "flying" animation of [flyingChild] from wherever
/// [fromContext] is on screen to the cart icon (tracked by
/// [CartIconAnchor.key]), arcing upward like a thrown ball before shrinking
/// and fading out just before it lands. Purely visual — call this in
/// addition to whatever already updates the cart state.
class FlyToCart {
  FlyToCart._();

  static void animate({
    required BuildContext fromContext,
    required Widget flyingChild,
    double size = 40,
    Duration duration = const Duration(milliseconds: 650),
  }) {
    final overlayState = Overlay.of(fromContext);
    final fromBox = fromContext.findRenderObject() as RenderBox?;
    final toBox = CartIconAnchor.key.currentContext?.findRenderObject() as RenderBox?;
    if (fromBox == null || toBox == null || !fromBox.attached || !toBox.attached) {
      return; // Best-effort: if either side isn't laid out yet, just skip the flourish.
    }

    final from = fromBox.localToGlobal(fromBox.size.center(Offset.zero));
    final to = toBox.localToGlobal(toBox.size.center(Offset.zero));

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _FlyingToken(
        from: from,
        to: to,
        size: size,
        duration: duration,
        onDone: () => entry.remove(),
        child: flyingChild,
      ),
    );
    overlayState.insert(entry);
  }
}

class _FlyingToken extends StatefulWidget {
  final Offset from;
  final Offset to;
  final double size;
  final Duration duration;
  final VoidCallback onDone;
  final Widget child;

  const _FlyingToken({
    required this.from,
    required this.to,
    required this.size,
    required this.duration,
    required this.onDone,
    required this.child,
  });

  @override
  State<_FlyingToken> createState() => _FlyingTokenState();
}

class _FlyingTokenState extends State<_FlyingToken> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onDone();
      })
      ..forward();
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
      builder: (context, _) {
        final t = Curves.easeInCubic.transform(_controller.value);
        final dx = widget.from.dx + (widget.to.dx - widget.from.dx) * t;
        // A parabolic lift peaking mid-flight, on top of the straight-line
        // descent/ascent to the target — reads like a small toss rather
        // than a flat slide.
        final straightY = widget.from.dy + (widget.to.dy - widget.from.dy) * t;
        final arc = -110 * (4 * t * (1 - t));
        final dy = straightY + arc;

        final scale = 1 - 0.7 * t;
        final fadeStart = 0.78;
        final opacity = t < fadeStart ? 1.0 : 1.0 - ((t - fadeStart) / (1 - fadeStart));

        return Positioned(
          left: dx - widget.size / 2,
          top: dy - widget.size / 2,
          width: widget.size,
          height: widget.size,
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(scale: scale, child: widget.child),
            ),
          ),
        );
      },
    );
  }
}
