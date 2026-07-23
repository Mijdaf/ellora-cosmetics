import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/app_language.dart';
import '../theme/app_theme.dart';
import 'fly_to_cart.dart';

/// A floating "glass capsule" nav bar.
///
/// Creative direction:
/// - The bar detaches from the very top edge and floats as a rounded pill,
///   like a chip of glass resting over the page.
/// - Behind the nav links sits a soft gold "magnetic" pill that glides to
///   whichever link is hovered — instead of a static underline.
/// - The logo sits inside a slowly rotating gradient ring with a tiny gold
///   "seed" dot orbiting it, echoing the wheat-stalk motif.
/// - The menu and cart icons are small, centered, tappable circles sized to
///   the icon itself (no oversized default IconButton padding), and both
///   actually do something: the cart opens a live mini-summary dropdown,
///   the hamburger morphs into an X and opens a dropdown menu.
/// - The whole capsule blurs + condenses (more opaque, tighter shadow) once
///   the page scrolls, so it always stays legible over any content.
class NavBar extends StatelessWidget implements PreferredSizeWidget {
  final int cartCount;
  final List<CartItem> cartItems;
  final double scrollProgress; // 0 = top of page, 1 = scrolled down
  final int activeNavIndex; // -1 = none, matches ['Menu', 'About'] order
  final VoidCallback? onMenuTap;
  final List<VoidCallback>? onNavLinkTap; // matches ['Menu', 'About']
  final VoidCallback? onCartBrowseMenu;
  final VoidCallback? onViewCart;

  const NavBar({
    super.key,
    this.cartCount = 0,
    this.cartItems = const [],
    this.scrollProgress = 0,
    this.activeNavIndex = -1,
    this.onMenuTap,
    this.onNavLinkTap,
    this.onCartBrowseMenu,
    this.onViewCart,
  });

  @override
  Size get preferredSize => const Size.fromHeight(96);

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 700;
    final t = scrollProgress.clamp(0.0, 1.0);

    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isArabic,
      builder: (context, isArabic, _) => Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: _buildBar(context, isNarrow, t, isArabic),
      ),
    );
  }

  Widget _buildBar(BuildContext context, bool isNarrow, double t, bool isArabic) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isNarrow ? 12 : 24, 14, isNarrow ? 12 : 24, 0),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: IntrinsicWidth(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: AppColors.wheatGold.withOpacity(0.14 + 0.1 * t),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18 + 0.12 * t),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    // Was 0.55 → 0.94. On Flutter web, BackdropFilter blur
                    // doesn't render on every renderer/browser combo, so at
                    // low opacity the pill let hero text show straight
                    // through it once scrolled — reading as a broken
                    // overlap instead of a floating glass bar. Raising the
                    // floor to 0.88 keeps the pill legible on its own even
                    // when the blur happens to no-op.
                    color: Color.lerp(
                      AppColors.espressoDeep.withOpacity(0.88),
                      AppColors.espressoDeep.withOpacity(0.97),
                      t,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: isNarrow ? 14 : 20),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const _OrbitingLogoBadge(),
                          const SizedBox(width: 10),
                          Text('Nafas', style: AppTheme.brandWordmark(isArabic: isArabic).copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
                          if (!isNarrow) ...[
                            const SizedBox(width: 14),
                            _MagneticNavLinks(onTap: onNavLinkTap, isArabic: isArabic, activeIndex: activeNavIndex),
                          ],
                          const SizedBox(width: 12),
                          if (isNarrow) ...[
                            _MorphingMenuButton(onTap: onMenuTap, onNavLinkTap: onNavLinkTap, isArabic: isArabic),
                            const SizedBox(width: 10),
                          ],
                          const _MoodToggleButton(),
                          const SizedBox(width: 8),
                          const _LanguageToggleButton(),
                          const SizedBox(width: 8),
                          _CartButton(
                            count: cartCount,
                            items: cartItems,
                            onBrowseMenu: onCartBrowseMenu,
                            onViewCart: onViewCart,
                            isArabic: isArabic,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo ring with a slow-spinning gradient border and a tiny gold "seed"
/// dot that orbits around it — a small, playful signature touch.
class _OrbitingLogoBadge extends StatefulWidget {
  const _OrbitingLogoBadge();

  @override
  State<_OrbitingLogoBadge> createState() => _OrbitingLogoBadgeState();
}

class _OrbitingLogoBadgeState extends State<_OrbitingLogoBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spin,
      builder: (context, child) {
        final angle = _spin.value * 2 * math.pi;
        return SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: angle,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        AppColors.wheatGold,
                        AppColors.wheatGoldLight,
                        Colors.transparent,
                        Colors.transparent,
                        AppColors.wheatGold,
                      ],
                    ),
                  ),
                ),
              ),
              // Orbiting seed dot
              Transform.translate(
                offset: Offset(math.cos(angle) * 24, math.sin(angle) * 24),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.wheatGoldLight,
                    boxShadow: [BoxShadow(color: AppColors.wheatGold.withOpacity(0.8), blurRadius: 6)],
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.espressoDeep),
        padding: const EdgeInsets.all(1.5),
        child: ClipOval(
          child: Image.asset(
            'assets/images/logo.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: AppColors.wheatGold, size: 18),
          ),
        ),
      ),
    );
  }
}

/// Nav links that share one "magnetic" gold pill which glides beneath
/// whichever link is currently hovered, rather than each link owning its
/// own static underline.
class _MagneticNavLinks extends StatefulWidget {
  final List<VoidCallback>? onTap;
  final bool isArabic;
  final int activeIndex;
  const _MagneticNavLinks({this.onTap, required this.isArabic, this.activeIndex = -1});

  @override
  State<_MagneticNavLinks> createState() => _MagneticNavLinksState();
}

class _MagneticNavLinksState extends State<_MagneticNavLinks> {
  int? _hovered;

  // One icon per link, in the same order as the labels below — shown
  // outlined when inactive and filled gold when active (hovered).
  static const _icons = [Icons.restaurant_menu, Icons.favorite_border];
  static const _iconsActive = [Icons.restaurant_menu, Icons.favorite];

  @override
  Widget build(BuildContext context) {
    final labels = [
      S.t('nav_menu', widget.isArabic),
      S.t('nav_about', widget.isArabic),
    ];
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(labels.length, (i) {
          final isCurrent = widget.activeIndex == i;
          final isHovered = _hovered == i;
          final isActive = isHovered || isCurrent;
          return MouseRegion(
            onEnter: (_) => setState(() => _hovered = i),
            onExit: (_) => setState(() => _hovered = null),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => widget.onTap != null && i < widget.onTap!.length ? widget.onTap![i]() : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                        child: Icon(
                          isActive ? _iconsActive[i] : _icons[i],
                          key: ValueKey(isActive),
                          color: isActive ? AppColors.wheatGoldLight : AppColors.cream.withOpacity(0.7),
                          size: isActive ? 20 : 17,
                        ),
                      ),
                      const SizedBox(width: 7),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 150),
                        style: TextStyle(fontFamily: AppTheme.fontFor(widget.isArabic), 
                          color: isActive ? AppColors.wheatGoldLight : AppColors.cream.withOpacity(0.85),
                          fontWeight: FontWeight.w700,
                          fontSize: isActive ? 19 : 17,
                          decoration: isActive ? TextDecoration.underline : TextDecoration.none,
                          decorationColor: AppColors.wheatGoldLight,
                          decorationThickness: 2,
                        ),
                        child: Text(labels[i]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// A small round icon button, centered, sized to fit the icon itself
/// (fixed compact box, no default 48px IconButton padding) rather than a
/// generic Material tap target — this keeps nav-bar icons tight and
/// visually centered instead of floating in oversized invisible boxes.
class _CompactIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double size;
  const _CompactIconButton({required this.child, required this.onTap, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Shared plumbing for a nav icon that opens a small floating dropdown
/// panel anchored right below it — used by both the cart button and the
/// mobile hamburger menu, so both are genuinely functional rather than
/// decorative.
class _AnchoredDropdown extends StatefulWidget {
  final Widget Function(BuildContext context, VoidCallback close) panelBuilder;
  final Widget Function(BuildContext context, bool isOpen, VoidCallback toggle) iconBuilder;
  const _AnchoredDropdown({required this.panelBuilder, required this.iconBuilder});

  @override
  State<_AnchoredDropdown> createState() => _AnchoredDropdownState();
}

class _AnchoredDropdownState extends State<_AnchoredDropdown> {
  final LayerLink _link = LayerLink();
  final OverlayPortalController _controller = OverlayPortalController();

  void _toggle() => _controller.toggle();
  void _close() => _controller.hide();

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (context) {
          return Stack(
            children: [
              // Full-screen tap-catcher so tapping anywhere outside the
              // panel closes it.
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _close,
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomRight,
                followerAnchor: Alignment.topRight,
                offset: const Offset(0, 10),
                child: widget.panelBuilder(context, _close),
              ),
            ],
          );
        },
        child: widget.iconBuilder(context, _controller.isShowing, _toggle),
      ),
    );
  }
}

/// A small floating panel styled to match the glass-capsule nav bar.
class _DropdownPanel extends StatelessWidget {
  final Widget child;
  final double width;
  const _DropdownPanel({required this.child, this.width = 220});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: AppColors.espressoDeep.withOpacity(0.98),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.wheatGold.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 10)),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: child,
      ),
    );
  }
}

/// Hamburger that smoothly morphs into an X (rotation + translation of the
/// three bars) and opens a real dropdown with the nav links — functional
/// on narrow screens where the inline links are hidden.
class _MorphingMenuButton extends StatefulWidget {
  final VoidCallback? onTap;
  final List<VoidCallback>? onNavLinkTap;
  final bool isArabic;
  const _MorphingMenuButton({this.onTap, this.onNavLinkTap, required this.isArabic});

  @override
  State<_MorphingMenuButton> createState() => _MorphingMenuButtonState();
}

class _MorphingMenuButtonState extends State<_MorphingMenuButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 280));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      S.t('nav_menu', widget.isArabic),
      S.t('nav_about', widget.isArabic),
    ];
    return _AnchoredDropdown(
      iconBuilder: (context, isOpen, toggle) => _CompactIconButton(
        size: 34,
        onTap: () {
          isOpen ? _controller.reverse() : _controller.forward();
          toggle();
          widget.onTap?.call();
        },
        child: SizedBox(
          width: 20,
          height: 15,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final v = _controller.value;
              return Stack(
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..translate(0.0, v * 6.5)
                      ..rotateZ(v * math.pi / 4),
                    child: _bar(),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Opacity(opacity: 1 - v, child: _bar()),
                  ),
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..translate(0.0, -v * 6.5)
                      ..rotateZ(-v * math.pi / 4),
                    child: _bar(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      panelBuilder: (context, close) => _DropdownPanel(
        width: 180,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: labels
              .asMap()
              .entries
              .map(
                (entry) => Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      _controller.reverse();
                      close();
                      final callbacks = widget.onNavLinkTap;
                      if (callbacks != null && entry.key < callbacks.length) callbacks[entry.key]();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Text(
                        entry.value,
                        style: TextStyle(fontFamily: AppTheme.fontFor(widget.isArabic), color: AppColors.cream, fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _bar() => Align(
        alignment: Alignment.center,
        child: Container(
          width: 20,
          height: 2,
          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(2)),
        ),
      );
}

/// Small sun/moon pill that flips the whole site between "dark mood"
/// (espresso backdrop, default) and "light mood" (cream backdrop). Reads
/// and writes the global `AppMood.isDark` notifier directly, so it works
/// wherever it's dropped in without any prop-threading, and only this
/// small icon rebuilds on toggle — not the rest of the nav bar.
class _MoodToggleButton extends StatelessWidget {
  const _MoodToggleButton();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppMood.isDark,
      builder: (context, isDark, _) {
        return _CompactIconButton(
          onTap: AppMood.toggle,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, anim) => RotationTransition(
              turns: Tween<double>(begin: 0.75, end: 1).animate(anim),
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              key: ValueKey(isDark),
              size: 18,
              color: isDark ? AppColors.cream : AppColors.wheatGoldLight,
            ),
          ),
        );
      },
    );
  }
}

/// Small "EN / AR" pill that flips the storefront's language between
/// English (default) and Arabic — reads and writes the global
/// `AppLanguage.isArabic` notifier directly, same wiring as
/// `_MoodToggleButton`. Only the storefront listens to this; the admin
/// dashboard always stays in English for the owner.
class _LanguageToggleButton extends StatelessWidget {
  const _LanguageToggleButton();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isArabic,
      builder: (context, isArabic, _) {
        return SizedBox(
          width: 34,
          height: 34,
          child: Material(
            color: Colors.transparent,
            shape: CircleBorder(
              side: BorderSide(color: AppColors.wheatGold.withOpacity(0.45)),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: AppLanguage.toggle,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                  child: Text(
                    isArabic ? 'EN' : 'AR',
                    key: ValueKey(isArabic),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.wheatGoldLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
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

/// Cart icon: compact, centered, and functional — tapping it opens a small
/// live summary dropdown with the actual items in the cart, and "View cart"
/// opens the full cart screen.
class _CartButton extends StatefulWidget {
  final int count;
  final List<CartItem> items;
  final VoidCallback? onBrowseMenu;
  final VoidCallback? onViewCart;
  final bool isArabic;
  const _CartButton({
    required this.count,
    this.items = const [],
    this.onBrowseMenu,
    this.onViewCart,
    required this.isArabic,
  });

  @override
  State<_CartButton> createState() => _CartButtonState();
}

class _CartButtonState extends State<_CartButton> with SingleTickerProviderStateMixin {
  late final AnimationController _bounce;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _lastCount = widget.count;
    _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
  }

  @override
  void didUpdateWidget(covariant _CartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > _lastCount) {
      _bounce.forward(from: 0);
    }
    _lastCount = widget.count;
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.items.fold<double>(0, (sum, item) => sum + item.total);

    return _AnchoredDropdown(
      iconBuilder: (context, isOpen, toggle) => SizedBox(
        key: CartIconAnchor.key,
        width: 34,
        height: 34,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _CompactIconButton(
              onTap: toggle,
              child: const Icon(Icons.shopping_bag_outlined, color: AppColors.cream, size: 19),
            ),
            if (widget.count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _bounce,
                    builder: (context, child) {
                      final scale = 1 + (0.5 * (1 - (_bounce.value - 0.5).abs() * 2)).clamp(0.0, 0.5);
                      return Transform.scale(scale: _bounce.isAnimating ? scale : 1, child: child);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.wheatGold, shape: BoxShape.circle),
                      child: Text(
                        '${widget.count}',
                        style: TextStyle(fontFamily: AppTheme.fontFor(widget.isArabic), fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.espressoDeep),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      panelBuilder: (context, close) => _DropdownPanel(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, color: AppColors.wheatGold, size: 16),
                const SizedBox(width: 8),
                Text(
                  widget.count == 0
                      ? S.t('cart_empty', widget.isArabic)
                      : widget.count == 1
                          ? S.t('cart_items_one', widget.isArabic)
                          : S.t('cart_items_other', widget.isArabic).replaceAll('%d', '${widget.count}'),
                  style: TextStyle(fontFamily: AppTheme.fontFor(widget.isArabic), color: AppColors.cream, fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
              ],
            ),
            if (widget.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: Column(
                    children: widget.items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(item.product.emoji, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${item.quantity}× ${item.product.name}',
                                    style: TextStyle(fontFamily: AppTheme.fontFor(widget.isArabic), color: AppColors.cream.withOpacity(0.85), fontSize: 12.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  formatEGP(item.total),
                                  style: TextStyle(fontFamily: AppTheme.fontFor(widget.isArabic), color: AppColors.wheatGoldLight, fontWeight: FontWeight.w600, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(S.t('subtotal', widget.isArabic), style: TextStyle(fontFamily: AppTheme.fontFor(widget.isArabic), color: AppColors.cream.withOpacity(0.7), fontSize: 12.5)),
                  Text(
                    formatEGP(subtotal),
                    style: TextStyle(fontFamily: AppTheme.fontFor(widget.isArabic), color: AppColors.cream, fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.count == 0
                    ? () {
                        close();
                        widget.onBrowseMenu?.call();
                      }
                    : () {
                        close();
                        widget.onViewCart?.call();
                      },
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                child: Text(widget.count == 0 ? S.t('browse_menu', widget.isArabic) : S.t('view_cart', widget.isArabic)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
