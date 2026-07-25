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
  final bool isDark;
  final VoidCallback? onAddToCart;

  /// Called with a quantity (1+) when the shopper adds from the detail
  /// view's stepper. Defaults to calling [onAddToCart] once per unit so
  /// existing call sites keep working untouched.
  final void Function(int quantity)? onAddQuantity;

  const ProductCard3D({
    super.key,
    required this.product,
    required this.isArabic,
    this.isDark = true,
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
    final cardColor = widget.isDark ? AppColors.espresso : AppColors.surfaceCream;
    final titleColor = widget.isDark ? AppColors.cream : AppColors.espressoDeep;
    final priceColor = widget.isDark ? AppColors.wheatGoldLight : AppColors.espressoDeep;

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
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hovering ? AppColors.wheatGold.withOpacity(0.55) : AppColors.cardBorder,
                width: _hovering ? 1.4 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espressoDeep.withOpacity(_hovering ? 0.28 : 0.16),
                  blurRadius: _hovering ? 22 : 14,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: EdgeInsets.zero,
            child: ClipRRect(
              // Slightly less than the card's own radius so the border ring still shows through.
              borderRadius: BorderRadius.circular(19),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image fills the card edge-to-edge, no padding/border around it.
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        (widget.product.imageUrl != null || widget.product.imageBytes != null)
                            ? SizedBox(
                                width: double.infinity,
                                height: double.infinity,
                                child: widget.product.imageUrl != null
                                    ? Image.network(
                                        widget.product.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _ImagePlaceholder(emoji: widget.product.emoji),
                                      )
                                    : Image.memory(
                                        widget.product.imageBytes!,
                                        fit: BoxFit.cover,
                                      ),
                              )
                            : _ImagePlaceholder(emoji: widget.product.emoji),
                        if (widget.product.tags.isNotEmpty)
                          PositionedDirectional(
                            top: 10,
                            start: 10,
                            child: _TagRibbon(text: widget.product.tags.first),
                          ),
                      ],
                    ),
                  ),
                  // Everything else keeps its own padding, separate from the image.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (widget.product.category.isNotEmpty)
                          Text(
                            widget.product.category.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.wheatGoldDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 10.5,
                              letterSpacing: 0.6,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          widget.product.name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: titleColor, fontSize: 17),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _AddButton(onTap: widget.onAddToCart, product: widget.product),
                            const SizedBox(width: 10),
                            Text(
                              formatEGP(widget.product.price),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                                color: priceColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

/// Small badge shown over the top corner of the product image (e.g. for a
/// featured/seasonal tag), mirroring the little ribbon-style label used on
/// featured product cards elsewhere.
class _TagRibbon extends StatelessWidget {
  final String text;
  const _TagRibbon({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.wheatGold,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.espressoDeep,
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

/// Shown in place of the product photo when there isn't one (or it failed
/// to load). Uses a wheat-gold tint distinct from the card's own
/// background, so the image block always reads as a deliberate visual
/// element instead of blending invisibly into the card — which is what
/// happened before when this used the same color as the card itself.
class _ImagePlaceholder extends StatelessWidget {
  final String emoji;
  const _ImagePlaceholder({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.wheatGold.withOpacity(0.14),
      alignment: Alignment.center,
      child: emoji.trim().isEmpty
          ? Icon(Icons.bakery_dining_outlined, size: 40, color: AppColors.wheatGoldDark.withOpacity(0.6))
          : Text(emoji, style: const TextStyle(fontSize: 56)),
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