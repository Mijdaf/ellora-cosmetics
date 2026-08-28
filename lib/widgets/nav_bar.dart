import 'dart:math' as math;
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
  final int activeNavIndex; // -1 = none, matches ['Makeup', 'Accessories', 'About'] order
  final bool isDrawerOpen; // drives the mobile hamburger's morph-to-X state
  final VoidCallback? onMenuTap;
  final List<VoidCallback>? onNavLinkTap; // matches ['Makeup', 'Accessories', 'About']
  final VoidCallback? onCartBrowseMenu;
  final VoidCallback? onViewCart;

  const NavBar({
    super.key,
    this.cartCount = 0,
    this.cartItems = const [],
    this.scrollProgress = 0,
    this.activeNavIndex = -1,
    this.isDrawerOpen = false,
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
    if (isNarrow) return _buildMobileBar(context, t, isArabic);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
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
                child: Container(
                  // Was 0.55 → 0.94 → 0.88/0.97. This pill used to sit
                  // behind a BackdropFilter blur, but that blur re-samples
                  // and re-blurs everything scrolling underneath it on
                  // every single frame — and since this pill is pinned on
                  // screen for the whole page, that cost was paid
                  // continuously while scrolling (a classic Flutter jank
                  // source). At this opacity the blur was already a near
                  // no-op visually (see the old comment this replaced), so
                  // dropping it keeps the pill just as legible while
                  // removing that per-frame cost entirely.
                  color: Color.lerp(
                    AppColors.espressoDeep.withOpacity(0.88),
                    AppColors.espressoDeep.withOpacity(0.97),
                    t,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _SecretAdminTap(child: const _OrbitingLogoBadge()),
                        const SizedBox(width: 10),
                        Text('Ellora', style: AppTheme.brandWordmark(isArabic: isArabic).copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
                        const SizedBox(width: 14),
                        _MagneticNavLinks(onTap: onNavLinkTap, isArabic: isArabic, activeIndex: activeNavIndex),
                        const SizedBox(width: 12),
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
                          // Same RTL mirroring as the mobile bar: this is the
                          // last item in the Row, so under Arabic it lands on
                          // the capsule's left edge instead of the right —
                          // flip the hang direction so the panel still opens
                          // toward the middle of the screen instead of off
                          // its edge.
                          alignLeft: isArabic,
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
    );
  }

  /// Phone layout: a single full-width glass pill spanning almost the
  /// whole screen — bag icon, wordmark and a small round avatar clustered
  /// on the leading side, hamburger sitting alone on the trailing side.
  /// Mood/language toggles move into [ElloraDrawer]'s footer on phones, so
  /// this bar stays exactly four elements, matching a plain storefront
  /// header instead of the desktop capsule's full icon row.
  Widget _buildMobileBar(BuildContext context, double t, bool isArabic) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppMood.isDark,
      builder: (context, isDark, _) {
        // Icon/text colors need to flip too once the bar itself goes
        // transparent in light mood — cream on the light cream page
        // backdrop would be unreadable otherwise.
        final fgColor = isDark ? AppColors.cream : AppColors.espressoDeep;
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: SafeArea(
            bottom: false,
            // Left in English, right in Arabic — an absolute screen side,
            // not a directional start/end, per the request. IntrinsicWidth
            // still hugs the bar to its content either way.
            child: Align(
              alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
              child: IntrinsicWidth(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppColors.wheatGold.withOpacity(0.14 + 0.1 * t),
                      width: 1,
                    ),
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.18 + 0.12 * t),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : const [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      // No BackdropFilter here on purpose — this pill is pinned on
                      // screen for the whole page, so a live blur behind it has to
                      // re-sample everything scrolling underneath, every frame,
                      // for as long as the page is being scrolled. The backing
                      // color below is already 88-97% opaque, so a blur adds very
                      // little visually while costing a lot on scroll.
                      //
                      // In light mood the bar goes fully transparent instead —
                      // just the border/shape stay, no solid backing at all.
                      color: isDark
                          ? Color.lerp(
                              AppColors.espressoDeep.withOpacity(0.88),
                              AppColors.espressoDeep.withOpacity(0.97),
                              t,
                            )
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      // Wrapped in FittedBox (same as the desktop bar above) so
                      // the whole row scales down to fit narrow phone widths
                      // instead of overflowing.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Hamburger now leads the Row instead of trailing it,
                            // so it's the widget that ends up on the outer screen
                            // edge — left in English, right in Arabic — matching
                            // the pill's own left/right anchor above instead of
                            // sitting toward the middle of the bar.
                            _DrawerMenuButton(
                              isOpen: isDrawerOpen,
                              isArabic: isArabic,
                              onTap: onMenuTap,
                              barColor: fgColor,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Ellora',
                              style: AppTheme.brandWordmark(isArabic: isArabic)
                                  .copyWith(fontSize: 19, fontWeight: FontWeight.w700, color: fgColor),
                            ),
                            const SizedBox(width: 8),
                            _SecretAdminTap(child: _MobileAvatar(ringColor: fgColor)),
                            const SizedBox(width: 10),
                            _CartButton(
                              count: cartCount,
                              items: cartItems,
                              onBrowseMenu: onCartBrowseMenu,
                              onViewCart: onViewCart,
                              isArabic: isArabic,
                              iconColor: fgColor,
                              // Cart is now the trailing widget, so it lands on the
                              // inner/center-ish edge instead of the outer one —
                              // last in the Row means it appears on the right in
                              // English (LTR) and the left in Arabic (RTL, which
                              // mirrors the Row). Hang the dropdown the opposite
                              // way so it always opens back toward the middle of
                              // the screen instead of off the edge — same formula
                              // as the desktop bar's cart button above, which is
                              // last in its Row too.
                              alignLeft: isArabic,
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
        );
      },
    );
  }
}

/// Wraps the logo (desktop or mobile) so 5 taps within a short window
/// quietly open the admin login (`/admin`) — the only in-app way in, since
/// there's no address bar to type a URL into on a compiled mobile build.
/// Taps reset if the gap between two of them is too long, so ordinary
/// tapping/hovering by a shopper never trips it by accident.
class _SecretAdminTap extends StatefulWidget {
  final Widget child;
  const _SecretAdminTap({required this.child});

  @override
  State<_SecretAdminTap> createState() => _SecretAdminTapState();
}

class _SecretAdminTapState extends State<_SecretAdminTap> {
  static const _requiredTaps = 5;
  static const _resetWindow = Duration(milliseconds: 600);
  int _taps = 0;
  DateTime? _lastTap;

  void _onTap() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) > _resetWindow) {
      _taps = 0;
    }
    _lastTap = now;
    _taps++;
    if (_taps >= _requiredTaps) {
      _taps = 0;
      Navigator.of(context).pushNamed('/admin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTap,
      child: widget.child,
    );
  }
}

/// Small static circular avatar for the mobile bar — the logo image in a
/// thin gold ring, no spin (the desktop [_OrbitingLogoBadge]'s animation
/// would be too busy at this size, next to the cart icon and hamburger).
class _MobileAvatar extends StatelessWidget {
  final Color ringColor;
  const _MobileAvatar({this.ringColor = AppColors.wheatGold});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor.withOpacity(0.6), width: 1.5),
      ),
      padding: const EdgeInsets.all(1.5),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.spa, color: ringColor, size: 16),
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
            errorBuilder: (_, __, ___) => const Icon(Icons.spa, color: AppColors.wheatGold, size: 18),
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
  // outlined when inactive and filled gold when active (hovered). Order is
  // Makeup shop, Accessories shop, About.
  static const _icons = [Icons.brush_outlined, Icons.diamond_outlined, Icons.favorite_border];
  static const _iconsActive = [Icons.brush, Icons.diamond, Icons.favorite];

  @override
  Widget build(BuildContext context) {
    final labels = [
      S.t('nav_menu', widget.isArabic),
      S.t('nav_accessories', widget.isArabic),
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
  // When true, the panel hangs to the right of the icon (aligned to its
  // left edge) instead of the default hanging-left-from-the-right-edge —
  // needed when the icon sits near the screen's left edge (mobile bar),
  // where the default anchoring would push the panel off-screen.
  final bool alignLeft;
  const _AnchoredDropdown({required this.panelBuilder, required this.iconBuilder, this.alignLeft = false});

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
                targetAnchor: widget.alignLeft ? Alignment.bottomLeft : Alignment.bottomRight,
                followerAnchor: widget.alignLeft ? Alignment.topLeft : Alignment.topRight,
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
    final screenWidth = MediaQuery.of(context).size.width;
    // Leave a 20px margin on the narrow side so the panel never runs off
    // the edge of small phone screens, whichever way it's anchored.
    final safeWidth = width.clamp(0, screenWidth - 20).toDouble();
    return Material(
      color: Colors.transparent,
      child: Container(
        width: safeWidth,
        constraints: BoxConstraints(maxWidth: math.min(280, screenWidth - 20)),
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

/// Hamburger that opens the real phone [ElloraDrawer] (via
/// `Scaffold.of(context).openDrawer()`) instead of a floating dropdown —
/// shown on narrow screens where the inline links are hidden. Morphs into
/// an X while the drawer is open. [isOpen] is fed down from the Scaffold's
/// `onDrawerChanged` callback (see `home_screen.dart`), which fires no
/// matter how the drawer closes — tap-outside, swipe, back button, or a
/// link tap inside it — so the icon always stays in sync, not just when
/// this button itself is tapped.
class _DrawerMenuButton extends StatefulWidget {
  final bool isOpen;
  // Which Scaffold drawer to drive: in Arabic (RTL) the drawer that's
  // pinned to the physical left edge is `endDrawer`, not `drawer` — see
  // the comment in home_screen.dart's `_buildScaffold`.
  final bool isArabic;
  final VoidCallback? onTap;
  final Color barColor;
  const _DrawerMenuButton({required this.isOpen, required this.isArabic, this.onTap, this.barColor = AppColors.cream});

  @override
  State<_DrawerMenuButton> createState() => _DrawerMenuButtonState();
}

class _DrawerMenuButtonState extends State<_DrawerMenuButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 250));

  @override
  void didUpdateWidget(covariant _DrawerMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _controller.forward();
    } else if (!widget.isOpen && oldWidget.isOpen) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    final scaffold = Scaffold.of(context);
    if (widget.isArabic) {
      if (scaffold.isEndDrawerOpen) {
        scaffold.closeEndDrawer();
      } else {
        scaffold.openEndDrawer();
      }
    } else {
      if (scaffold.isDrawerOpen) {
        scaffold.closeDrawer();
      } else {
        scaffold.openDrawer();
      }
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return _CompactIconButton(
      size: 34,
      onTap: _handleTap,
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
                    ..translate(0.0, -6.5 * (1 - v))
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
                    ..translate(0.0, 6.5 * (1 - v))
                    ..rotateZ(-v * math.pi / 4),
                  child: _bar(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _bar() => Align(
        alignment: Alignment.center,
        child: Container(
          width: 20,
          height: 2,
          decoration: BoxDecoration(color: widget.barColor, borderRadius: BorderRadius.circular(2)),
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
                      fontFamily: 'Montserrat',
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
  final bool alignLeft;
  final Color iconColor;
  const _CartButton({
    required this.count,
    this.items = const [],
    this.onBrowseMenu,
    this.onViewCart,
    required this.isArabic,
    this.alignLeft = false,
    this.iconColor = AppColors.cream,
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
      alignLeft: widget.alignLeft,
      iconBuilder: (context, isOpen, toggle) => SizedBox(
        key: CartIconAnchor.key,
        width: 34,
        height: 34,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _CompactIconButton(
              onTap: toggle,
              child: Icon(Icons.shopping_bag_outlined, color: widget.iconColor, size: 19),
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
