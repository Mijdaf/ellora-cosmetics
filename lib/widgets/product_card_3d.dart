import 'package:flutter/material.dart';
import '../models/product.dart';
import '../screens/product_detail_screen.dart';
import '../theme/app_theme.dart';
import 'fly_to_cart.dart';

/// A product card with a subtle hover highlight (border/shadow) and a
/// one-time entrance animation. Used to tilt toward the cursor on hover,
/// but that constantly nudged the "+" button around under the pointer and
/// made it hard to tap accurately — removed in favor of a stationary card.
class ProductCard3D extends StatefulWidget {
  final Product product;
  final bool isArabic;
  final VoidCallback? onAddToCart;

  /// Called with a quantity (1+) when the shopper adds from the detail
  /// view's stepper. Defaults to calling [onAddToCart] once per unit so
  /// existing call sites keep working untouched.
  final void Function(int quantity)? onAddQuantity;

  const ProductCard3D({
    super.key,
    required this.product,
    required this.isArabic,
    this.onAddToCart,
    this.onAddQuantity,
  });

  @override
  State<ProductCard3D> createState() => _ProductCard3DState();
}

class _ProductCard3DState extends State<ProductCard3D> with SingleTickerProviderStateMixin {
  bool _hovering = false;
  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return AnimatedBuilder(
        animation: _entrance,
        builder: (context, child) {
          final t = Curves.easeOutBack.transform(_entrance.value);
          return Opacity(
            opacity: _entrance.value.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 40),
              child: child,
            ),
          );
        },
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openDetails,
            child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: AppColors.surfaceCream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hovering ? AppColors.wheatGold.withOpacity(0.55) : AppColors.cardBorder,
                width: _hovering ? 1.4 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espressoDeep.withOpacity(_hovering ? 0.22 : 0.12),
                  blurRadius: _hovering ? 22 : 14,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: (widget.product.imageUrl != null || widget.product.imageBytes != null)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: widget.product.imageUrl != null
                                ? Image.network(
                                    widget.product.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(widget.product.emoji, style: const TextStyle(fontSize: 56)),
                                    ),
                                  )
                                : Image.memory(
                                    widget.product.imageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        )
                      : Center(
                          child: Text(widget.product.emoji, style: const TextStyle(fontSize: 56)),
                        ),
                ),
                const SizedBox(height: 10),
                if (widget.product.tags.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.wheatGold.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.product.tags.first,
                      style: const TextStyle(
                        color: AppColors.wheatGoldDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                Text(
                  widget.product.name,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.product.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatEGP(widget.product.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.espressoDeep,
                      ),
                    ),
                    _AddButton(onTap: widget.onAddToCart, product: widget.product),
                  ],
                ),
              ],
            ),
            ),
          ),
        ),
      );
    });
  }

  void _openDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          product: widget.product,
          isArabic: widget.isArabic,
          onAddToCart: (qty) {
            if (widget.onAddQuantity != null) {
              widget.onAddQuantity!(qty);
            } else if (widget.onAddToCart != null) {
              for (var i = 0; i < qty; i++) {
                widget.onAddToCart!();
              }
            }
          },
        ),
      ),
    );
  }
}

/// Small "+" button that pops with a spring-like scale animation and a
/// brief checkmark flash on tap, giving clear feedback when adding to cart.
class _AddButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Product product;
  const _AddButton({this.onTap, required this.product});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _justAdded = false;

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
    widget.onTap?.call();
    setState(() => _justAdded = true);
    _controller.forward(from: 0);
    FlyToCart.animate(
      fromContext: context,
      flyingChild: _flyingVisual(),
    );
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _justAdded = false);
    });
  }

  /// Small round visual thrown toward the cart icon: the product's real
  /// photo when it has one, its emoji token otherwise — either way capped
  /// to a compact circle so it reads as "one item flying" regardless of
  /// the source image's shape.
  Widget _flyingVisual() {
    final hasImage = widget.product.imageUrl != null || widget.product.imageBytes != null;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceCream,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.wheatGold, width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.espressoDeep.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      alignment: Alignment.center,
      child: hasImage
          ? ClipOval(
              child: widget.product.imageUrl != null
                  ? Image.network(widget.product.imageUrl!, width: 40, height: 40, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Text(widget.product.emoji, style: const TextStyle(fontSize: 20)))
                  : Image.memory(widget.product.imageBytes!, width: 40, height: 40, fit: BoxFit.cover),
            )
          : Text(widget.product.emoji, style: const TextStyle(fontSize: 20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bounce = Curves.elasticOut.transform(_controller.value);
        final double scale = 1.0 + (_controller.isAnimating ? bounce * 0.35 : 0.0);
        return Transform.scale(scale: scale, child: child);
      },
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppColors.wheatGold,
            shape: BoxShape.circle,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: Icon(
              _justAdded ? Icons.check : Icons.add,
              key: ValueKey(_justAdded),
              size: 18,
              color: AppColors.espressoDeep,
            ),
          ),
        ),
      ),
    );
  }
}