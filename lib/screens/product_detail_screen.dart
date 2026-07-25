import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/app_language.dart';
import '../theme/app_theme.dart';
import '../utils/text_dir.dart';
import '../widgets/animated_background.dart';

/// Full-page product detail screen — pushed as its own route instead of a
/// modal dialog, so the product showcase gets a lot more room to breathe:
/// a full-height gallery panel on wide screens, and a tall hero card on
/// narrow ones, both noticeably bigger than the old dialog's fixed card.
class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final bool isArabic;
  final void Function(int quantity) onAddToCart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.isArabic,
    required this.onAddToCart,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  bool _justAdded = false;

  void _bump(int delta) => setState(() => _qty = (_qty + delta).clamp(1, 12));

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

    return ValueListenableBuilder<bool>(
      valueListenable: AppMood.isDark,
      builder: (context, isDark, _) {
        final bg = isDark ? AppColors.espressoDark : AppColors.surfaceCream;

        return Directionality(
          textDirection: widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
          backgroundColor: bg,
          body: Stack(
            children: [
              Positioned.fill(child: AnimatedBackground(isDark: isDark)),
              SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 860;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 72, vertical: 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TopBar(isDark: isDark),
                          const SizedBox(height: 28),
                          isNarrow
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _Gallery(product: p, isNarrow: isNarrow),
                                    const SizedBox(height: 32),
                                    _Details(
                                      product: p,
                                      qty: _qty,
                                      justAdded: _justAdded,
                                      isDark: isDark,
                                      isArabic: widget.isArabic,
                                      onBump: _bump,
                                      onAdd: _handleAdd,
                                    ),
                                  ],
                                )
                              : Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: _Gallery(product: p, isNarrow: isNarrow),
                                    ),
                                    const SizedBox(width: 56),
                                    Expanded(
                                      flex: 5,
                                      child: _Details(
                                        product: p,
                                        qty: _qty,
                                        justAdded: _justAdded,
                                        isDark: isDark,
                                        isArabic: widget.isArabic,
                                        onBump: _bump,
                                        onAdd: _handleAdd,
                                      ),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
            ],
          ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool isDark;
  const _TopBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    return Row(
      children: [
        Material(
          color: (isDark ? Colors.white : AppColors.espressoDeep).withOpacity(0.08),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).maybePop(),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(Icons.arrow_back_rounded, size: 20, color: iconColor),
            ),
          ),
        ),
      ],
    );
  }
}

/// Big showcase card — same espresso-gradient + glow language as the old
/// hero banner, but sized to fill a whole gallery column/tall hero block
/// instead of a fixed 360px strip, so the product "photo" (its emoji
/// centerpiece) reads as the star of the page.
class _Gallery extends StatefulWidget {
  final Product product;
  final bool isNarrow;
  const _Gallery({required this.product, required this.isNarrow});

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.015 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: AspectRatio(
          // Taller than the old 360px-fixed banner on every breakpoint —
          // this is the main lever for "bigger image" on both mobile and
          // desktop.
          aspectRatio: widget.isNarrow ? 0.88 : 0.8,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: AppColors.heroGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.espressoDeep.withOpacity(0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 440,
                  height: 440,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AppColors.wheatGold.withOpacity(0.35), Colors.transparent],
                    ),
                  ),
                ),
                if (p.imageUrl != null || p.imageBytes != null)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: p.imageUrl != null
                          ? Image.network(
                              p.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Center(child: Text(p.emoji, style: const TextStyle(fontSize: 260))),
                            )
                          : Image.memory(
                              p.imageBytes!,
                              fit: BoxFit.cover,
                            ),
                    ),
                  )
                else
                  Text(p.emoji, style: const TextStyle(fontSize: 260)),
                if (p.tags.isNotEmpty)
                  Positioned(
                    left: 22,
                    top: 22,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.wheatGold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        p.tags.first,
                        style: const TextStyle(
                          color: AppColors.espressoDeep,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  final Product product;
  final int qty;
  final bool justAdded;
  final bool isDark;
  final bool isArabic;
  final void Function(int delta) onBump;
  final VoidCallback onAdd;

  const _Details({
    required this.product,
    required this.qty,
    required this.justAdded,
    required this.isDark,
    required this.isArabic,
    required this.onBump,
    required this.onAdd,
  });

  String _categoryLabel(String c) => isArabic ? categoryDisplayName(c, true) : c.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final p = product;
    final textColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    final mutedColor = textColor.withOpacity(0.68);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _categoryLabel(p.category),
          style: AppTheme.eyebrow(isArabic: isArabic).copyWith(
            color: isDark ? AppColors.wheatGold : AppColors.wheatGoldDark,
            fontSize: 12.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          p.name,
          textDirection: autoTextDirection(p.name),
          textAlign: autoTextAlign(p.name),
          style: TextStyle(
            fontFamily: AppTheme.fontFor(isArabicText(p.name)),
            fontWeight: FontWeight.w600,
            fontSize: 38,
            height: 1.08,
            color: textColor,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 18, color: AppColors.wheatGold),
            const SizedBox(width: 4),
            Text('${p.rating}', style: TextStyle(color: mutedColor, fontWeight: FontWeight.w600, fontSize: 14)),
            if (p.reviewCount > 0) ...[
              const SizedBox(width: 4),
              Text('(${p.reviewCount})', style: TextStyle(color: mutedColor, fontSize: 13)),
            ],
          ],
        ),
        const SizedBox(height: 22),
        Text(
          formatEGP(p.price),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 30, color: AppColors.wheatGoldDark),
        ),
        const SizedBox(height: 22),
        Text(
          p.description,
          textDirection: autoTextDirection(p.description),
          textAlign: autoTextAlign(p.description),
          style: TextStyle(color: mutedColor, fontSize: 16, height: 1.6),
        ),
        if (p.story.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.wheatGold.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.wheatGold.withOpacity(0.25)),
            ),
            child: Text(
              p.story,
              textDirection: autoTextDirection(p.story),
              textAlign: autoTextAlign(p.story),
              style: TextStyle(
                color: textColor.withOpacity(0.85),
                fontSize: 13.5,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
          ),
        ],
        if (p.highlights.isNotEmpty) ...[
          const SizedBox(height: 26),
          ...p.highlights.map((h) => _HighlightRow(text: h, color: textColor)),
        ],
        if (p.ingredients.isNotEmpty) ...[
          const SizedBox(height: 22),
          _SectionLabel(S.t('ingredients', isArabic), color: isDark ? AppColors.wheatGold : AppColors.wheatGoldDark, isArabic: isArabic),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: p.ingredients.map((i) => _Chip(i, isDark: isDark)).toList(),
          ),
        ],
        const SizedBox(height: 32),
        Row(
          children: [
            _QuantityStepper(qty: qty, onChanged: onBump, isDark: isDark),
            const SizedBox(width: 14),
            Expanded(
              child: _AddToCartButton(
                justAdded: justAdded,
                total: p.price * qty,
                isArabic: isArabic,
                onTap: onAdd,
              ),
            ),
          ],
        ),
      ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final String text;
  final Color color;
  const _HighlightRow({required this.text, required this.color});

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
            child: Text(text, style: TextStyle(color: color.withOpacity(0.85), fontSize: 14, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  final bool isArabic;
  const _SectionLabel(this.text, {required this.color, this.isArabic = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.fontFor(isArabic),
        color: color,
        fontWeight: FontWeight.w700,
        letterSpacing: isArabic ? 0 : 1.6,
        fontSize: 11,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _Chip(this.label, {required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.wheatGold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.wheatGold.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.wheatGoldLight : AppColors.espressoDeep,
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int qty;
  final void Function(int delta) onChanged;
  final bool isDark;
  const _QuantityStepper({required this.qty, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.wheatGold.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(icon: Icons.remove_rounded, onTap: () => onChanged(-1), color: textColor),
          SizedBox(
            width: 34,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textColor),
            ),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: () => onChanged(1), color: textColor),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const _StepButton({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Icon(icon, size: 18, color: color),
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
  final bool isArabic;
  final VoidCallback onTap;
  const _AddToCartButton({required this.justAdded, required this.total, required this.isArabic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.wheatGold,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
            child: justAdded
                ? Row(
                    key: const ValueKey('added'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, size: 20, color: AppColors.espressoDeep),
                      const SizedBox(width: 8),
                      Text(S.t('added_to_cart', isArabic),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppColors.espressoDeep)),
                    ],
                  )
                : Text(
                    S.t('add_to_cart', isArabic),
                    key: const ValueKey('add'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5, color: AppColors.espressoDeep),
                  ),
          ),
        ),
      ),
    );
  }
}
