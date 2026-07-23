import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

/// Opens the product detail view as a soft scale+fade dialog. Kept as a
/// single lightweight transition (no blur, no extra shader work) so it
/// stays smooth even on lower-powered devices.
Future<void> showProductDetail(
  BuildContext context, {
  required Product product,
  required void Function(int quantity) onAddToCart,
}) {
  return showGeneralDialog(
    context: context,
    barrierLabel: product.name,
    barrierDismissible: true,
    barrierColor: AppColors.espressoDeep.withOpacity(0.55),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, anim, secondaryAnim) {
      return _ProductDetailDialog(product: product, onAddToCart: onAddToCart);
    },
    transitionBuilder: (context, anim, secondaryAnim, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return Opacity(
        opacity: curved.value,
        child: Transform.scale(
          scale: 0.94 + curved.value * 0.06,
          child: child,
        ),
      );
    },
  );
}

class _ProductDetailDialog extends StatefulWidget {
  final Product product;
  final void Function(int quantity) onAddToCart;
  const _ProductDetailDialog({required this.product, required this.onAddToCart});

  @override
  State<_ProductDetailDialog> createState() => _ProductDetailDialogState();
}

class _ProductDetailDialogState extends State<_ProductDetailDialog> {
  int _qty = 1;
  bool _justAdded = false;

  void _bump(int delta) {
    setState(() => _qty = (_qty + delta).clamp(1, 12));
  }

  void _handleAdd() {
    widget.onAddToCart(_qty);
    setState(() => _justAdded = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _justAdded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final size = MediaQuery.of(context).size;
    final isNarrow = size.width < 640;
    final maxHeight = size.height * 0.92;
    final maxWidth = isNarrow ? size.width - 32 : 760.0;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          ),
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceCream,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espressoDeep.withOpacity(0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroBanner(product: p),
                  Padding(
                    padding: EdgeInsets.fromLTRB(isNarrow ? 22 : 42, 30, isNarrow ? 22 : 42, 34),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                p.name,
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 34),
                              ),
                            ),
                            Text(
                              formatEGP(p.price),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                                color: AppColors.wheatGoldDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(p.description, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 16.5)),
                        if (p.highlights.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          ...p.highlights.map((h) => _HighlightRow(text: h)),
                        ],
                        if (p.ingredients.isNotEmpty) ...[
                          const SizedBox(height: 22),
                          _SectionLabel('INGREDIENTS'),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: p.ingredients.map((i) => _Chip(i)).toList(),
                          ),
                        ],
                        const SizedBox(height: 28),
                        Row(
                          children: [
                            _QuantityStepper(qty: _qty, onChanged: _bump),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _AddToCartButton(
                                justAdded: _justAdded,
                                total: p.price * _qty,
                                onTap: _handleAdd,
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
  }
}

/// Top banner: same espresso gradient + lined texture language as the rest
/// of the site, with the product's emoji as a large centerpiece and a
/// close button. Purely decorative — no animation controllers needed here,
/// so opening the dialog stays cheap.
class _HeroBanner extends StatelessWidget {
  final Product product;
  const _HeroBanner({required this.product});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 360,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: AppColors.heroGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [AppColors.wheatGold.withOpacity(0.35), Colors.transparent],
                  ),
                ),
              ),
              if (product.imageUrl != null || product.imageBytes != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: product.imageUrl != null
                      ? Image.network(
                          product.imageUrl!,
                          width: 260,
                          height: 260,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Text(product.emoji, style: const TextStyle(fontSize: 190)),
                        )
                      : Image.memory(
                          product.imageBytes!,
                          width: 260,
                          height: 260,
                          fit: BoxFit.cover,
                        ),
                )
              else
                Text(product.emoji, style: const TextStyle(fontSize: 190)),
            ],
          ),
        ),
        if (product.tags.isNotEmpty)
          Positioned(
            left: 20,
            top: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.wheatGold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                product.tags.first,
                style: const TextStyle(
                  color: AppColors.espressoDeep,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ),
          ),
        Positioned(
          right: 14,
          top: 14,
          child: _CloseButton(onTap: () => Navigator.of(context).maybePop()),
        ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.28),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(7),
          child: Icon(Icons.close_rounded, size: 18, color: AppColors.cream),
        ),
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final String text;
  const _HighlightRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.wheatGoldDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.wheatGoldDark,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        fontSize: 11,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.wheatGold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.wheatGold.withOpacity(0.35)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.espressoDeep)),
    );
  }
}

/// Small +/- stepper for quantity. A single StatelessWidget driven by the
/// parent's state — no extra AnimationController needed.
class _QuantityStepper extends StatelessWidget {
  final int qty;
  final void Function(int delta) onChanged;
  const _QuantityStepper({required this.qty, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove_rounded, onTap: () => onChanged(-1)),
          SizedBox(
            width: 34,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.espressoDeep),
            ),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: () => onChanged(1)),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Icon(icon, size: 18, color: AppColors.espressoDeep),
        ),
      ),
    );
  }
}

/// Big add-to-cart button that mirrors the card's tap feedback (a quick
/// checkmark flash) using AnimatedSwitcher only — no continuous ticker,
/// so it costs nothing while idle.
class _AddToCartButton extends StatelessWidget {
  final bool justAdded;
  final double total;
  final VoidCallback onTap;
  const _AddToCartButton({required this.justAdded, required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.wheatGold,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 17),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: justAdded
                ? const Row(
                    key: ValueKey('added'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, size: 20, color: AppColors.espressoDeep),
                      SizedBox(width: 8),
                      Text('Added to cart', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppColors.espressoDeep)),
                    ],
                  )
                : Row(
                    key: const ValueKey('add'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_bag_outlined, size: 19, color: AppColors.espressoDeep),
                      const SizedBox(width: 8),
                      Text(
                        'Add · ${formatEGP(total)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppColors.espressoDeep),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
