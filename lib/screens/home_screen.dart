import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/category.dart';
import '../models/home_banner.dart';
import '../models/product.dart';
import '../services/app_language.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/hero_section.dart';
import '../widgets/home_banner_slideshow.dart';
import '../widgets/nafas_drawer.dart';
import '../widgets/nav_bar.dart';
import '../widgets/product_card_3d.dart';
import '../widgets/scroll_reveal.dart';
import '../widgets/shimmer_card.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _locationsKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();
  final List<CartItem> _cartItems = [];
  String? _filter;
  String _searchQuery = '';
  double _scrollProgress = 0;
  // -1 = neither section in view (e.g. still on the hero); 0 = Menu, 1 =
  // About — drives the nav bar's real "active" link, not just hover.
  int _activeNavIndex = -1;
  bool _isDrawerOpen = false;

  int get _cartCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  void _addToCart(Product product, [int quantity = 1]) {
    setState(() {
      final idx = _cartItems.indexWhere((c) => c.product.name == product.name);
      if (idx >= 0) {
        _cartItems[idx].quantity += quantity;
      } else {
        _cartItems.add(CartItem(product: product, quantity: quantity));
      }
    });
  }

  void _setQuantity(Product product, int quantity) {
    setState(() {
      final idx = _cartItems.indexWhere((c) => c.product.name == product.name);
      if (idx < 0) return;
      if (quantity <= 0) {
        _cartItems.removeAt(idx);
      } else {
        _cartItems[idx].quantity = quantity;
      }
    });
  }

  void _removeFromCart(Product product) {
    setState(() => _cartItems.removeWhere((c) => c.product.name == product.name));
  }

  void _clearCart() {
    setState(() => _cartItems.clear());
  }

  void _openCart() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StatefulBuilder(
          builder: (context, setLocalState) => ValueListenableBuilder<bool>(
            valueListenable: AppMood.isDark,
            builder: (context, isDark, _) => ValueListenableBuilder<bool>(
              valueListenable: AppLanguage.isArabic,
              builder: (context, isArabic, __) => Directionality(
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                child: CartScreen(
                  items: _cartItems,
                  isDark: isDark,
                  isArabic: isArabic,
                  onQuantityChanged: (product, quantity) {
                    _setQuantity(product, quantity);
                    setLocalState(() {});
                  },
                  onRemove: (product) {
                    _removeFromCart(product);
                    setLocalState(() {});
                  },
                  onContinueShopping: () => Navigator.of(context).pop(),
                  onOrderPlaced: () {
                    _clearCart();
                    setLocalState(() {});
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    ).then((_) => setState(() {})); // refresh badge count after returning
  }

  @override
  void initState() {
    super.initState();
    ProductStore.ensureLoaded();
    HomeBannerStore.ensureLoaded();
    CategoryStore.ensureLoaded();
    _scrollController.addListener(() {
      final p = (_scrollController.offset / 140).clamp(0.0, 1.0);
      if (p != _scrollProgress) setState(() => _scrollProgress = p);
      _updateActiveNavSection();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  // Finds the last section (Menu, then About) whose top edge has already
  // scrolled up past the floating nav bar, and marks that one active — so
  // the nav bar reflects where the user actually is on the page, not just
  // what they're hovering over.
  void _updateActiveNavSection() {
    const navBarClearance = 110.0;
    final sections = {0: _menuKey, 1: _aboutKey};
    int active = -1;
    double bestDy = double.negativeInfinity;
    sections.forEach((idx, key) {
      final ctx = key.currentContext;
      final box = ctx?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) return;
      final dy = box.localToGlobal(Offset.zero).dy;
      if (dy <= navBarClearance && dy > bestDy) {
        bestDy = dy;
        active = idx;
      }
    });
    if (active != _activeNavIndex) setState(() => _activeNavIndex = active);
  }

  void _scrollToMenu() => _scrollToKey(_menuKey);
  void _scrollToAbout() => _scrollToKey(_aboutKey);
  void _scrollToLocations() => _scrollToKey(_locationsKey);

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 900;

    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isArabic,
      builder: (context, isArabic, ____) {
        return ValueListenableBuilder<bool>(
          valueListenable: AppMood.isDark,
          builder: (context, isDark, _) {
            return ValueListenableBuilder<List<Product>>(
              // Listens to the live catalog so products added/edited/removed
              // from the admin dashboard appear on the storefront immediately.
              valueListenable: ProductStore.products,
              builder: (context, allProducts, __) {
                return ValueListenableBuilder<List<Category>>(
                  // Listens to the live category list so the filter chips
                  // reflect whatever the owner has added/removed, immediately.
                  valueListenable: CategoryStore.categories,
                  builder: (context, allCategories, ___) {
                    final query = _searchQuery.trim().toLowerCase();
                    final products = allProducts.where((p) {
                      final matchesCategory = _filter == null || p.category == _filter;
                      final matchesSearch = query.isEmpty ||
                          p.name.toLowerCase().contains(query) ||
                          p.description.toLowerCase().contains(query);
                      return matchesCategory && matchesSearch;
                    }).toList();
                    return Directionality(
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      child: _buildScaffold(context, isDark, isArabic, isNarrow, products, allCategories),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    bool isDark,
    bool isArabic,
    bool isNarrow,
    List<Product> products,
    List<Category> categories,
  ) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.espressoDark : AppColors.surfaceCream,
          extendBodyBehindAppBar: true,
          appBar: NavBar(
            cartCount: _cartCount,
            cartItems: _cartItems,
            scrollProgress: _scrollProgress,
            activeNavIndex: _activeNavIndex,
            isDrawerOpen: _isDrawerOpen,
            onNavLinkTap: [_scrollToMenu, _scrollToAbout],
            onCartBrowseMenu: _scrollToMenu,
            onViewCart: _openCart,
          ),
          // Phone navigation drawer — the hamburger in NavBar opens this
          // (Scaffold.of(context).openDrawer()) instead of a small
          // dropdown once the screen is narrow.
          drawer: NafasDrawer(
            cartCount: _cartCount,
            activeNavIndex: _activeNavIndex,
            isDark: isDark,
            onNavLinkTap: [_scrollToMenu, _scrollToAbout],
            onBrowseMenu: _scrollToMenu,
            onViewCart: _openCart,
          ),
          // Fires on every close path (swipe, tap-outside, back button, or
          // a link tap inside the drawer that calls Navigator.pop), so the
          // hamburger icon's morph-to-X state always stays accurate.
          onDrawerChanged: (isOpen) => setState(() => _isDrawerOpen = isOpen),
          body: SingleChildScrollView(
            controller: _scrollController,
            child: Stack(
              children: [
                // Ambient decorative layers (floating pastry tokens + the
                // aurora glow) must be painted FIRST here so Stack renders
                // them behind the real content below — Stack paints later
                // children on top, and these were previously listed after
                // the content Column, which put translucent color washes
                // over every bit of text on the page. Barely noticeable in
                // dark mode (busy espresso backdrop already), but glaring
                // in light mode where the marquee's cream-on-cream strip
                // has almost no contrast margin to spare.
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: PageFloatingTokens(isNarrow: isNarrow),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 1200,
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: AuroraGlow(isDark: isDark),
                    ),
                  ),
                ),
                // The 3-stop gradient used to be painted behind the *whole*
                // page (hero through footer) in one Container. Since that
                // stretched the same 3 color stops across the entire, very
                // tall scroll height, the darkest stop (espressoDeep) sat
                // almost flat for the whole first screen or two — the hero
                // read noticeably darker than everything below it, which
                // only reached the lighter stops much further down.
                // Bounding the gradient to just the hero's own (intrinsic)
                // height instead means the dark→light transition resolves
                // by the time the hero ends, landing on the same flat tone
                // (AppColors.espressoDark / surfaceCream) as the Scaffold's
                // own backgroundColor everywhere below — one consistent
                // tone top to bottom instead of a long dark dip up top.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark ? AppColors.heroGradient : AppColors.lightPageGradient,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: HeroSection(onExplore: _scrollToMenu, isDark: isDark, isArabic: isArabic),
                    ),
                    const _PromoBanners(),
                      _CategoryMarquee(
                        categories: categories,
                        isDark: isDark,
                        isArabic: isArabic,
                        onSelect: (name) {
                          setState(() => _filter = name);
                          _scrollToMenu();
                        },
                      ),
                      Padding(
                        key: _menuKey,
                        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 80, vertical: 70),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ScrollReveal(
                              offsetY: 18,
                              child: Column(
                                children: [
                                  Text(
                                    S.t('baked_fresh_every_day', isArabic),
                                    style: AppTheme.eyebrow(isArabic: isArabic).copyWith(
                                      color: isDark ? AppColors.wheatGold : AppColors.wheatGoldDark,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    S.t('our_fresh_menu', isArabic),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontSize: isNarrow ? 32 : 42,
                                          color: isDark ? AppColors.cream : AppColors.espressoDeep,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: 60,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: AppColors.goldGradient),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            _ProductSearchField(
                              isDark: isDark,
                              isArabic: isArabic,
                              value: _searchQuery,
                              onChanged: (q) => setState(() => _searchQuery = q),
                            ),
                            const SizedBox(height: 24),
                            _CategoryFilters(
                              categories: categories,
                              selected: _filter,
                              isArabic: isArabic,
                              onChanged: (c) => setState(() => _filter = c),
                            ),
                            const SizedBox(height: 40),
                            LayoutBuilder(builder: (context, constraints) {
                              final cols = constraints.maxWidth > 1100
                                  ? 4
                                  : constraints.maxWidth > 800
                                      ? 3
                                      : constraints.maxWidth > 520
                                          ? 2
                                          : 1;
                              return ValueListenableBuilder<bool>(
                                valueListenable: ProductStore.isLoading,
                                builder: (context, isLoading, __) {
                                  if (isLoading && products.isEmpty) {
                                    return ShimmerProductGrid(crossAxisCount: cols);
                                  }
                                  if (products.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 40),
                                      child: Text(
                                        S.t('no_products_found', isArabic),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFor(isArabic),
                                          fontSize: 15,
                                          color: (isDark ? AppColors.cream : AppColors.espressoDeep).withOpacity(0.6),
                                        ),
                                      ),
                                    );
                                  }
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: products.length,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      crossAxisSpacing: 24,
                                      mainAxisSpacing: 24,
                                      childAspectRatio: 0.72,
                                    ),
                                    itemBuilder: (context, i) => _StaggeredEntrance(
                                      index: i,
                                      child: ProductCard3D(
                                        product: products[i],
                                        isArabic: isArabic,
                                        onAddToCart: () => _addToCart(products[i]),
                                        onAddQuantity: (qty) => _addToCart(products[i], qty),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                      ),
                      KeyedSubtree(
                        key: _aboutKey,
                        child: _StoryBanner(isNarrow: isNarrow, isDark: isDark, isArabic: isArabic),
                      ),
                      KeyedSubtree(
                        key: _locationsKey,
                        child: _Footer(
                          isNarrow: isNarrow,
                          isDark: isDark,
                          isArabic: isArabic,
                          onMenuTap: _scrollToMenu,
                          onAboutTap: _scrollToAbout,
                          onLocationsTap: _scrollToLocations,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
  }
}

/// The promotional banner strip right under the hero — owner-uploaded
/// photos (seasonal offers, new drops, announcements) that auto-advance
/// every 5 seconds. Listens live to `HomeBannerStore`, same pattern as the
/// product grid listening to `ProductStore`, so banners added/reordered/
/// removed from the admin dashboard show up immediately. Renders nothing
/// at all until the owner has added at least one banner.
class _PromoBanners extends StatefulWidget {
  const _PromoBanners();

  @override
  State<_PromoBanners> createState() => _PromoBannersState();
}

class _PromoBannersState extends State<_PromoBanners> {
  // Drives the dot row directly under the slideshow — the slideshow
  // itself doesn't draw dots over the photo here (showDots: false),
  // so this is the only thing tracking which slide is active.
  int _bannerPage = 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<HomeBanner>>(
      valueListenable: HomeBannerStore.banners,
      builder: (context, banners, __) {
        if (banners.isEmpty) return const SizedBox.shrink();

        final isMobile = MediaQuery.of(context).size.width < 900;
        final screenWidth = MediaQuery.of(context).size.width;
        // Edge-to-edge on mobile like a native app hero; desktop keeps an
        // inset frame. One fixed 16:9 aspect ratio at every screen size so
        // a photo crops the same way everywhere — only the overall size
        // scales with the available width.
        final horizontalPadding = isMobile ? 0.0 : 60.0;
        final availableWidth = screenWidth - horizontalPadding * 2;
        const bannerAspectRatio = 16 / 9;
        final bannerHeight = (availableWidth / bannerAspectRatio).clamp(200.0, 560.0);

        return Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, isMobile ? 0 : 20, horizontalPadding, 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isMobile ? 0 : 24),
            child: Column(
              children: [
                HomeBannerSlideshow(
                  banners: banners,
                  height: bannerHeight.toDouble(),
                  showDots: false,
                  onPageChanged: (i) => setState(() => _bannerPage = i),
                ),
                if (banners.length > 1) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(banners.length, (i) {
                      final active = i == _bannerPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? AppColors.wheatGold : AppColors.espressoDeep.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// An auto-scrolling ticker of the owner's categories, sitting right under
/// the promo banners — a quick, low-effort way to preview the whole menu
/// structure before the shopper even reaches the grid. Tapping a name jumps
/// straight to that category further down the page. Fully owner-driven:
/// there's nothing hardcoded here, so it renders nothing at all until the
/// owner has added at least one category, and it re-measures itself
/// whenever the category list changes.
class _CategoryMarquee extends StatefulWidget {
  final List<Category> categories;
  final bool isDark;
  final bool isArabic;
  final ValueChanged<String> onSelect;
  const _CategoryMarquee({required this.categories, required this.isDark, required this.isArabic, required this.onSelect});

  @override
  State<_CategoryMarquee> createState() => _CategoryMarqueeState();
}

class _CategoryMarqueeState extends State<_CategoryMarquee> with SingleTickerProviderStateMixin {
  static const double _speed = 34; // pixels per second
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _unitKey = GlobalKey();
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _offset = 0;
  double _unitWidth = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant _CategoryMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.categories.map((c) => c.id).join(',');
    final newIds = widget.categories.map((c) => c.id).join(',');
    if (oldIds != newIds) {
      _unitWidth = 0;
      _offset = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  void _measure() {
    final box = _unitKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final width = box.size.width;
    if (width > 0 && mounted) setState(() => _unitWidth = width);
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    if (_unitWidth <= 0 || !_scrollController.hasClients) return;
    _offset += _speed * dt;
    if (_offset >= _unitWidth) _offset -= _unitWidth;
    _scrollController.jumpTo(_offset);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildSet(Color textColor) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final c in widget.categories) ...[
            GestureDetector(
              onTap: () => widget.onSelect(c.name),
              child: Text(
                widget.isArabic ? categoryDisplayName(c.name, true) : c.name.toUpperCase(),
                style: TextStyle(
                  fontFamily: AppTheme.fontFor(widget.isArabic),
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: widget.isArabic ? 0 : 1.6,
                  color: textColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Icon(Icons.circle, size: 7, color: AppColors.wheatGold.withOpacity(0.7)),
            ),
          ],
        ],
      );

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) return const SizedBox.shrink();

    // However many categories the owner has, repeat the set enough times
    // that the scrollable strip always comfortably out-spans even a very
    // wide desktop window, so there's never a gap while it loops.
    final repeatCount = (30 / widget.categories.length).ceil().clamp(3, 20);
    final textColor = widget.isDark ? AppColors.cream : AppColors.espressoDeep;
    final bg = widget.isDark ? Colors.white.withOpacity(0.05) : AppColors.cream;

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
          stops: [0, 0.04, 0.96, 1],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < repeatCount; i++)
                i == 0 ? KeyedSubtree(key: _unitKey, child: _buildSet(textColor)) : _buildSet(textColor),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fades + slides each grid item in with a small delay based on its index,
/// so the menu grid "cascades" into view instead of popping in all at once.
class _StaggeredEntrance extends StatefulWidget {
  final int index;
  final Widget child;
  const _StaggeredEntrance({required this.index, required this.child});

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    Future.delayed(Duration(milliseconds: 80 * (widget.index % 8)), () {
      if (mounted) _controller.forward();
    });
  }

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
        final t = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, (1 - t) * 24), child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// A rounded search field sitting above the category filters, letting
/// shoppers narrow the menu grid by product name/description as they type.
/// Fully controlled from the parent (`_HomeScreenState._searchQuery`) so it
/// composes cleanly with the existing category filter instead of fighting
/// it — both narrow the same `products` list together.
class _ProductSearchField extends StatefulWidget {
  final bool isDark;
  final bool isArabic;
  final String value;
  final ValueChanged<String> onChanged;
  const _ProductSearchField({
    required this.isDark,
    required this.isArabic,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends State<_ProductSearchField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void didUpdateWidget(covariant _ProductSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync if something external ever clears the query
    // (e.g. a future "clear filters" action) without fighting user typing.
    if (widget.value != _controller.text && widget.value.isEmpty) {
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? AppColors.cream : AppColors.espressoDeep;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Focus(
          onFocusChange: (f) => setState(() => _focused = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: isDark ? Colors.white.withOpacity(0.04) : Colors.white.withOpacity(0.55),
              border: Border.all(
                color: AppColors.wheatGold.withOpacity(_focused ? 0.7 : 0.28),
                width: 1.3,
              ),
              boxShadow: _focused
                  ? [BoxShadow(color: AppColors.wheatGold.withOpacity(0.22), blurRadius: 16, offset: const Offset(0, 4))]
                  : [],
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(fontFamily: AppTheme.fontFor(widget.isArabic), color: textColor, fontSize: 14.5),
              cursorColor: AppColors.wheatGold,
              decoration: InputDecoration(
                isDense: true,
                hintText: S.t('search_products', widget.isArabic),
                hintStyle: TextStyle(fontFamily: AppTheme.fontFor(widget.isArabic), color: textColor.withOpacity(0.45), fontSize: 14.5),
                prefixIcon: Icon(Icons.search, size: 20, color: AppColors.wheatGold.withOpacity(0.85)),
                suffixIcon: widget.value.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close, size: 18, color: textColor.withOpacity(0.6)),
                        onPressed: () {
                          _controller.clear();
                          widget.onChanged('');
                        },
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilters extends StatelessWidget {
  final List<Category> categories;
  final String? selected;
  final bool isArabic;
  final ValueChanged<String?> onChanged;
  const _CategoryFilters({
    required this.categories,
    required this.selected,
    required this.isArabic,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    final entries = <(String, String?)>[
      (S.t('all', isArabic), null),
      for (final c in categories) (categoryDisplayName(c.name, isArabic), c.name),
    ];
    return Wrap(
      spacing: 10,
      alignment: WrapAlignment.center,
      children: entries.map((e) {
        final isSelected = selected == e.$2;
        return _HoverLiftChip(
          isSelected: isSelected,
          label: e.$1,
          isArabic: isArabic,
          onTap: () => onChanged(e.$2),
        );
      }).toList(),
    );
  }
}

/// A filter chip that lifts slightly and gains a stronger glow on hover,
/// on top of its existing selected/unselected states.
class _HoverLiftChip extends StatefulWidget {
  final bool isSelected;
  final String label;
  final bool isArabic;
  final VoidCallback onTap;
  const _HoverLiftChip({required this.isSelected, required this.label, required this.isArabic, required this.onTap});

  @override
  State<_HoverLiftChip> createState() => _HoverLiftChipState();
}

class _HoverLiftChipState extends State<_HoverLiftChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    // IntrinsicWidth forces this whole pill to hug its label's width instead
    // of stretching to fill the Wrap's available width (which is what was
    // making every filter pill span edge to edge).
    return IntrinsicWidth(
      child: MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.wheatGold : Colors.transparent,
          border: Border.all(color: AppColors.wheatGold, width: 1.3),
          borderRadius: BorderRadius.circular(23),
          boxShadow: isSelected || _hover
              ? [
                  BoxShadow(
                    color: AppColors.wheatGold.withOpacity(isSelected ? 0.4 : 0.25),
                    blurRadius: isSelected ? 12 : 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(23),
          onTap: widget.onTap,
          child: SizedBox(
            // A bit bigger than the very compact pass, still more compact
            // than the original oversized hero-button-sized pill — width
            // still shrink-wraps to the label — a Container with
            // `alignment` set expands to fill the Wrap's bounded width
            // instead of hugging its content, which is what made every
            // pill stretch edge to edge. SizedBox only constrains the
            // axis you give it.
            height: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(fontFamily: AppTheme.fontFor(widget.isArabic), 
                    color: isSelected ? AppColors.espressoDeep : AppColors.wheatGoldDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                  // Force a single line: IntrinsicWidth sizes this pill to
                  // the label's measured width, but if that measurement
                  // ever falls a hair short (e.g. right after the Poppins
                  // web font swaps in for the fallback font), a wrapping
                  // Text will break mid-word ("Pastrie" / "s"). softWrap:
                  // false + maxLines: 1 guarantees the label always stays
                  // on one line, matching the pill it sits inside.
                  child: Text(
                    widget.label,
                    softWrap: false,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
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

class _StoryBanner extends StatelessWidget {
  final bool isNarrow;
  final bool isDark;
  final bool isArabic;
  const _StoryBanner({required this.isNarrow, required this.isDark, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 24 : 80, vertical: 70),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: ScrollReveal(
            child: Flex(
              direction: isNarrow ? Axis.vertical : Axis.horizontal,
              crossAxisAlignment: isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: isNarrow ? 0 : 3,
                  child: Text(
                    S.t('story_quote', isArabic),
                    textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                    style: TextStyle(
                      color: isDark ? AppColors.cream : AppColors.espressoDeep,
                      fontSize: isNarrow ? 22 : 26,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      fontFamily: AppTheme.fontFor(isArabic),
                    ),
                  ),
                ),
                if (!isNarrow) const SizedBox(width: 48),
                if (isNarrow) const SizedBox(height: 24),
                ElevatedButton(onPressed: () {}, child: Text(S.t('our_story', isArabic))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Footer redesign:
/// - A shimmering gold hairline sweeps across the top edge on a loop.
/// - Two soft glowing orbs drift slowly behind everything (subtle depth,
///   no busy texture).
/// - Content splits into three columns (brand / quick links / newsletter)
///   that stagger-reveal as the footer scrolls into view.
/// - The logo gently "breathes" (scale pulse) instead of sitting static.
/// - Social icons lift + glow gold on hover.
/// - A tiny animated wheat-ear icon ticks beside the copyright line.
/// Footer text/icons read a bit washed-out in light mood at their old low
/// opacities (espressoDeep is a dark brown, but faded down to 35-75% alpha
/// it reads pale on the cream backdrop). Dark mood (cream on espresso)
/// already reads fine, so only light mood gets a boost toward solid black.
double _footerOpacity(bool isDark, double base) => isDark ? base : (base + 0.3).clamp(0.0, 1.0);

class _Footer extends StatefulWidget {
  final bool isNarrow;
  final bool isDark;
  final bool isArabic;
  final VoidCallback? onMenuTap;
  final VoidCallback? onAboutTap;
  final VoidCallback? onLocationsTap;
  const _Footer({
    required this.isNarrow,
    required this.isDark,
    required this.isArabic,
    this.onMenuTap,
    this.onAboutTap,
    this.onLocationsTap,
  });

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> with TickerProviderStateMixin {
  late final AnimationController _shimmer =
      AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat(reverse: true);
  late final AnimationController _breathe =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

  @override
  void dispose() {
    _shimmer.dispose();
    _drift.dispose();
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = widget.isNarrow;
    final isDark = widget.isDark;
    final isArabic = widget.isArabic;
    final mutedText = isDark ? AppColors.cream : AppColors.espressoDeep;
    return Container(
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 2,
            child: AnimatedBuilder(
              animation: _shimmer,
              builder: (context, _) => CustomPaint(
                painter: _ShimmerLinePainter(progress: _shimmer.value),
                size: const Size(double.infinity, 2),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _drift,
              builder: (context, _) {
                final d = _drift.value;
                return Stack(
                  children: [
                    Positioned(
                      left: -80 + d * 40,
                      top: -60,
                      child: _glowOrb(220, AppColors.wheatGold.withOpacity(0.10)),
                    ),
                    Positioned(
                      right: -60 - d * 30,
                      bottom: -80,
                      child: _glowOrb(260, AppColors.wheatGoldDark.withOpacity(0.08)),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(isNarrow ? 24 : 80, 64, isNarrow ? 24 : 80, 28),
            child: ScrollReveal(
              offsetY: 24,
              child: Column(
                children: [
                  Flex(
                    direction: isNarrow ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isNarrow ? 0 : 4,
                        child: _StaggeredEntrance(
                          index: 0,
                          child: Column(
                            crossAxisAlignment: isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                            children: [
                              isNarrow
                                  ? Column(
                                      children: [
                                        Center(
                                          child: AnimatedBuilder(
                                            animation: _breathe,
                                            builder: (context, child) {
                                              final s = 1 + _breathe.value * 0.05;
                                              return Transform.scale(scale: s, child: child);
                                            },
                                            child: Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(color: AppColors.wheatGold.withOpacity(0.5), width: 1.4),
                                                boxShadow: [
                                                  BoxShadow(color: AppColors.wheatGold.withOpacity(0.18), blurRadius: 16),
                                                ],
                                              ),
                                              padding: const EdgeInsets.all(2),
                                              child: ClipOval(
                                                child: Image.asset(
                                                  'assets/images/logo.jpg',
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(Icons.eco, color: AppColors.wheatGold, size: 26),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text('Nafas', style: AppTheme.brandWordmark(isArabic: isArabic).copyWith(fontSize: 28, color: isDark ? AppColors.cream : AppColors.espressoDeep)),
                                      ],
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        AnimatedBuilder(
                                          animation: _breathe,
                                          builder: (context, child) {
                                            final s = 1 + _breathe.value * 0.05;
                                            return Transform.scale(scale: s, child: child);
                                          },
                                          child: Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(color: AppColors.wheatGold.withOpacity(0.5), width: 1.4),
                                              boxShadow: [
                                                BoxShadow(color: AppColors.wheatGold.withOpacity(0.18), blurRadius: 16),
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(2),
                                            child: ClipOval(
                                              child: Image.asset(
                                                'assets/images/logo.jpg',
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(Icons.eco, color: AppColors.wheatGold, size: 26),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Text('Nafas', style: AppTheme.brandWordmark(isArabic: isArabic).copyWith(fontSize: 28, color: isDark ? AppColors.cream : AppColors.espressoDeep)),
                                      ],
                                    ),
                              const SizedBox(height: 10),
                              Text(S.t('baked_with_love', isArabic), style: AppTheme.eyebrow(isArabic: isArabic)),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: isNarrow ? double.infinity : 260,
                                child: Text(
                                  S.t('footer_tagline', isArabic),
                                  textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontFor(isArabic),
                                    color: mutedText.withOpacity(_footerOpacity(isDark, 0.6)),
                                    fontSize: 13.5,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _SocialIcon.svg(
                                    'assets/icons/instagram.svg',
                                    isDark: isDark,
                                    onTap: () => _openUrl(
                                      'https://www.instagram.com/n_afas204?igsh=MXFzb2QyMGZ2c2Y3eA%3D%3D&utm_source=qr',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _SocialIcon(Icons.facebook, isDark: isDark),
                                  const SizedBox(width: 10),
                                  _SocialIcon(Icons.alternate_email, isDark: isDark),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isNarrow ? 40 : 0, width: isNarrow ? 0 : 32),
                      Expanded(
                        flex: isNarrow ? 0 : 3,
                        child: _StaggeredEntrance(
                          index: 1,
                          child: Column(
                            crossAxisAlignment: isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                            children: [
                              Text(S.t('quick_links', isArabic), style: AppTheme.eyebrow(isArabic: isArabic).copyWith(fontSize: 11)),
                              const SizedBox(height: 16),
                              _FooterLink(S.t('nav_menu', isArabic), isDark: isDark, isArabic: isArabic, onTap: widget.onMenuTap),
                              _FooterLink(S.t('about_us', isArabic), isDark: isDark, isArabic: isArabic, onTap: widget.onAboutTap),
                              _FooterLink(S.t('nav_locations', isArabic), isDark: isDark, isArabic: isArabic, onTap: widget.onLocationsTap),
                              _FooterLink(S.t('contact', isArabic), isDark: isDark, isArabic: isArabic),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Container(height: 1, color: AppColors.wheatGold.withOpacity(0.12)),
                  const SizedBox(height: 22),
                  Flex(
                    direction: isNarrow ? Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const _TickingWheatIcon(),
                          const SizedBox(width: 8),
                          Text(S.t('copyright', isArabic),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFor(isArabic),
                                color: mutedText.withOpacity(_footerOpacity(isDark, 0.5)),
                                fontSize: 12,
                              )),
                        ],
                      ),
                      if (isNarrow) const SizedBox(height: 14),
                      Text(S.t('made_with_care', isArabic),
                          style: TextStyle(
                            fontFamily: AppTheme.fontFor(isArabic),
                            color: mutedText.withOpacity(_footerOpacity(isDark, 0.35)),
                            fontSize: 12,
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
        ),
      );

  Future<void> _openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // Non-fatal — never blocks the page if the link can't be opened.
    }
  }
}

class _ShimmerLinePainter extends CustomPainter {
  final double progress;
  _ShimmerLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = AppColors.wheatGold.withOpacity(0.10);
    canvas.drawRect(Offset.zero & size, base);

    final sweepCenter = size.width * progress;
    final sweepWidth = size.width * 0.35;
    final gradient = LinearGradient(
      colors: [Colors.transparent, AppColors.wheatGoldLight.withOpacity(0.9), Colors.transparent],
    );
    final rect = Rect.fromLTWH(sweepCenter - sweepWidth / 2, 0, sweepWidth, size.height);
    final sweepPaint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerLinePainter oldDelegate) => oldDelegate.progress != progress;
}

/// A footer nav link that lifts slightly and turns gold on hover.
class _FooterLink extends StatefulWidget {
  final String label;
  final bool isDark;
  final bool isArabic;
  final VoidCallback? onTap;
  const _FooterLink(this.label, {required this.isDark, required this.isArabic, this.onTap});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark ? AppColors.cream : AppColors.espressoDeep;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
            child: AnimatedSlide(
              duration: const Duration(milliseconds: 180),
              offset: _hover ? const Offset(0.04, 0) : Offset.zero,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  fontFamily: AppTheme.fontFor(widget.isArabic),
                  color: _hover ? AppColors.wheatGoldLight : baseColor.withOpacity(_footerOpacity(widget.isDark, 0.7)),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                child: Text(widget.label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular social icon that lifts up + glows gold on hover. Optionally
/// opens a link (e.g. Instagram) when tapped.
///
/// Pass either [icon] (a Material glyph, e.g. Facebook) or [svgAsset] (a
/// bundled brand SVG, e.g. the real Instagram glyph at
/// assets/icons/instagram.svg) — whichever is set is what renders.
class _SocialIcon extends StatefulWidget {
  final IconData? icon;
  final String? svgAsset;
  final bool isDark;
  final VoidCallback? onTap;
  const _SocialIcon(this.icon, {required this.isDark, this.onTap}) : svgAsset = null;
  const _SocialIcon.svg(this.svgAsset, {required this.isDark, this.onTap}) : icon = null;

  @override
  State<_SocialIcon> createState() => _SocialIconState();
}

class _SocialIconState extends State<_SocialIcon> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark ? AppColors.cream : AppColors.espressoDeep;
    final tint = _hover ? AppColors.wheatGoldLight : baseColor.withOpacity(_footerOpacity(widget.isDark, 0.75));
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hover
                ? AppColors.wheatGold.withOpacity(0.16)
                : (widget.isDark ? Colors.white.withOpacity(0.04) : AppColors.espressoDeep.withOpacity(0.05)),
            border: Border.all(color: AppColors.wheatGold.withOpacity(_hover ? 0.6 : 0.3)),
            boxShadow: _hover ? [BoxShadow(color: AppColors.wheatGold.withOpacity(0.3), blurRadius: 12)] : [],
          ),
          child: Center(
            child: widget.svgAsset != null
                ? SvgPicture.asset(
                    widget.svgAsset!,
                    width: 17,
                    height: 17,
                    colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
                  )
                : Icon(widget.icon, size: 17, color: tint),
          ),
        ),
      ),
    );
  }
}

/// Tiny wheat-ear glyph beside the copyright line that gives a slow,
/// almost imperceptible sway — a small heartbeat for the page.
class _TickingWheatIcon extends StatefulWidget {
  const _TickingWheatIcon();

  @override
  State<_TickingWheatIcon> createState() => _TickingWheatIconState();
}

class _TickingWheatIconState extends State<_TickingWheatIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

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
        final angle = (_controller.value - 0.5) * 0.35;
        return Transform.rotate(angle: angle, child: child);
      },
      child: const Icon(Icons.eco, size: 14, color: AppColors.wheatGold),
    );
  }
}
