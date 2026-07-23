import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A soft light-sweep that travels left→right across whatever [child] it
/// wraps, using a `ShaderMask` so it works over any shape/color underneath
/// (no need to know the exact layout it's covering).
class _ShimmerSweep extends StatefulWidget {
  final Widget child;
  const _ShimmerSweep({required this.child});

  @override
  State<_ShimmerSweep> createState() => _ShimmerSweepState();
}

class _ShimmerSweepState extends State<_ShimmerSweep> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

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
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            // Slide the gradient's stop window from just off the left edge
            // to just off the right edge as the controller repeats.
            final t = _controller.value;
            final start = -1.0 + 2.6 * t;
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.wheatGold.withOpacity(0.10),
                AppColors.wheatGold.withOpacity(0.28),
                AppColors.wheatGold.withOpacity(0.10),
              ],
              stops: [
                (start - 0.3).clamp(0.0, 1.0),
                start.clamp(0.0, 1.0),
                (start + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single placeholder bar/block, base color only (the moving highlight
/// comes from the shared [_ShimmerSweep] wrapped around the whole card).
class _ShimmerBlock extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const _ShimmerBlock({this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.wheatGold.withOpacity(0.14),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton placeholder shaped like [ProductCard3D] (image block, tag pill,
/// title bar, description bar, price/button row) — shown in the menu grid
/// while the real catalog is still loading from Supabase, so the page
/// looks alive from the first frame instead of blank.
class ShimmerProductCard extends StatelessWidget {
  const ShimmerProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerSweep(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCream,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: Center(child: _ShimmerBlock(width: 96, height: 96, radius: 14))),
            const SizedBox(height: 10),
            const _ShimmerBlock(width: 60, height: 16, radius: 20),
            const SizedBox(height: 10),
            _ShimmerBlock(width: double.infinity, height: 16),
            const SizedBox(height: 6),
            const _ShimmerBlock(width: double.infinity, height: 13),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _ShimmerBlock(width: 50, height: 18),
                _ShimmerBlock(width: 32, height: 32, radius: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Lays out [count] [ShimmerProductCard]s in the exact same grid shape the
/// real menu grid uses, so swapping shimmer → real cards doesn't cause any
/// layout jump.
class ShimmerProductGrid extends StatelessWidget {
  final int crossAxisCount;
  final int count;
  const ShimmerProductGrid({super.key, required this.crossAxisCount, this.count = 8});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, i) => const ShimmerProductCard(),
    );
  }
}
