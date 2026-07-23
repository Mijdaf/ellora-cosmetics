import 'package:flutter/material.dart';

/// Fades + slides its child up into place the first time it scrolls into
/// the viewport, then stays.
///
/// Implementation note: this listens directly to the ambient [Scrollable]'s
/// [ScrollPosition] (via `Scrollable.maybeOf(context)`), not to bubbling
/// [ScrollNotification]s. A `NotificationListener` placed *inside* the
/// scrolled content can never see notifications dispatched by the
/// Scrollable that contains it (notifications only bubble upward to
/// ancestors), so that approach silently never re-checks after the first
/// frame — which is why content below the fold (e.g. a footer) could stay
/// invisible forever. Listening on the ScrollPosition directly is reliable
/// regardless of where in the tree this widget sits.
class ScrollReveal extends StatefulWidget {
  final Widget child;
  final double offsetY;
  final Duration duration;

  const ScrollReveal({
    super.key,
    required this.child,
    this.offsetY = 40,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _revealed = false;
  ScrollPosition? _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
  }

  void _attach() {
    if (!mounted) return;
    // Find the nearest ancestor Scrollable (e.g. the page's
    // SingleChildScrollView) and listen to it directly.
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _position) {
      _position?.removeListener(_check);
      _position = position;
      _position?.addListener(_check);
    }
    _check();
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    if (_revealed || !mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return;
    final position = box.localToGlobal(Offset.zero);
    final viewportHeight = MediaQuery.of(context).size.height;
    if (position.dy < viewportHeight * 0.88) {
      _revealed = true;
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-attach if we've moved to a different Scrollable ancestor
    // (e.g. after a hot reload / rebuild of the tree above us).
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * widget.offsetY), child: child),
        );
      },
      child: widget.child,
    );
  }
}
