import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/wishlist_store.dart';
import '../theme/app_theme.dart';

/// Small round heart toggle that adds/removes [product] from the
/// [WishlistStore]. Pops with a quick spring scale on tap, same feel as
/// the "+" add-to-cart button, so it reads as a sibling control rather
/// than a bolted-on afterthought.
class HeartButton extends StatefulWidget {
  final Product product;
  final double size;
  const HeartButton({super.key, required this.product, this.size = 34});

  @override
  State<HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<HeartButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    final nowWished = WishlistStore.toggle(widget.product);
    if (nowWished) _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: WishlistStore.wished,
      builder: (context, _, __) {
        final wished = WishlistStore.isWished(widget.product);
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final bounce = Curves.elasticOut.transform(_controller.value);
            final scale = 1.0 + (_controller.isAnimating ? bounce * 0.4 : 0.0);
            return Transform.scale(scale: scale, child: child);
          },
          child: Material(
            color: Colors.black.withOpacity(0.28),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _handleTap,
              child: Padding(
                padding: EdgeInsets.all(widget.size * 0.22),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    wished ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    key: ValueKey(wished),
                    size: widget.size * 0.5,
                    color: wished ? AppColors.wheatGold : Colors.white,
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
