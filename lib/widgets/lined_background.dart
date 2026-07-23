import 'package:flutter/material.dart';

/// Style is kept only so call sites (home_screen.dart, hero_section.dart,
/// etc.) don't need to change — it no longer affects anything visually.
enum LineStyle { dark, light }

/// Previously drew an animated diagonal-line / wheat-arc texture behind
/// sections. That texture has been removed per request: this now simply
/// renders [child] with no background decoration, so section backgrounds
/// stay clean and flat while keeping the same widget API used throughout
/// the app (so no other file needs to change).
class LinedBackground extends StatelessWidget {
  final Widget child;
  final LineStyle style;
  final double opacity;
  const LinedBackground({
    super.key,
    required this.child,
    this.style = LineStyle.light,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) => child;
}
