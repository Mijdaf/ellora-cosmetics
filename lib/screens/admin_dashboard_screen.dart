import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category.dart';
import '../models/home_banner.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/store_settings.dart';
import '../services/supabase_config.dart';
import '../theme/app_theme.dart';
import '../utils/text_dir.dart';

/// Admin dashboard for managing the product catalog, home banners,
/// orders, and store settings. Every change writes straight through to
/// Supabase, then updates the local `ProductStore` / `HomeBannerStore` /
/// `OrderStore` / `StoreSettingsStore` — which the storefront (and this
/// screen) listen to directly.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Orders (and a fresh view of products/banners/settings) are only
    // visible once logged in, so fetch them the moment the dashboard mounts.
    ProductStore.loadAll();
    HomeBannerStore.loadAll();
    OrderStore.loadAll();
    CategoryStore.loadAll();
    StoreSettingsStore.loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppMood.isDark,
      builder: (context, isDark, _) {
        final bg = isDark ? AppColors.espressoDark : AppColors.surfaceCream;

        return ValueListenableBuilder<List<Product>>(
          // Listens to the live catalog so the product list below updates
          // immediately after an add/edit/delete.
          valueListenable: ProductStore.products,
          builder: (context, allProducts, __) {
            return ValueListenableBuilder<List<HomeBanner>>(
              // Listens to the live banner strip so the list below updates
              // immediately after an add/reorder/delete.
              valueListenable: HomeBannerStore.banners,
              builder: (context, allBanners, ___) {
                return ValueListenableBuilder<List<Order>>(
                  // Listens to the live order list so the Orders section
                  // below updates the instant a customer checks out or the
                  // owner marks/removes one.
                  valueListenable: OrderStore.orders,
                  builder: (context, allOrders, ____) {
                    return ValueListenableBuilder<List<Category>>(
                      // Listens to the live category list so the Categories
                      // section, and the category picker in the product
                      // form, update the instant the owner adds/removes one.
                      valueListenable: CategoryStore.categories,
                      builder: (context, allCategories, _____) {
                        return ValueListenableBuilder<StoreSettings>(
                          // Listens to the live store settings so the
                          // Settings tab reflects the saved values.
                          valueListenable: StoreSettingsStore.settings,
                          builder: (context, storeSettings, ______) {
                            return Scaffold(
                          backgroundColor: bg,
                          body: SafeArea(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 860;
                                return SingleChildScrollView(
                                  padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 72, vertical: 24),
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 1240),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _TopBar(isDark: isDark),
                                          const SizedBox(height: 28),
                                          _DashboardTabs(
                                            isDark: isDark,
                                            products: allProducts,
                                            banners: allBanners,
                                            orders: allOrders,
                                            categories: allCategories,
                                            settings: storeSettings,
                                          ),
                                          const SizedBox(height: 28),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                            );
                          },
                        );
                      },
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
}

// ---------------------------------------------------------------------------
// Dashboard tabs — icon switcher between Orders / Banners / Categories / Products
// ---------------------------------------------------------------------------

enum _DashboardSection { orders, banners, categories, products, settings }

/// The icon row at the top of the dashboard body that switches which
/// section is visible below — Orders, Banners, Categories, Products, or
/// Settings — so the owner sees one focused panel at a time instead of one
/// long page with everything stacked on top of each other.
class _DashboardTabs extends StatefulWidget {
  final bool isDark;
  final List<Product> products;
  final List<HomeBanner> banners;
  final List<Order> orders;
  final List<Category> categories;
  final StoreSettings settings;

  const _DashboardTabs({
    required this.isDark,
    required this.products,
    required this.banners,
    required this.orders,
    required this.categories,
    required this.settings,
  });

  @override
  State<_DashboardTabs> createState() => _DashboardTabsState();
}

class _DashboardTabsState extends State<_DashboardTabs> {
  _DashboardSection _selected = _DashboardSection.orders;

  @override
  Widget build(BuildContext context) {
    final pendingCount = widget.orders.where((o) => !o.isCompleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Wrapped in a horizontal scroller: on phones the 5 tabs (Orders,
        // Banners, Categories, Products, Settings) are wider than the
        // screen, so without this the last one or two got clipped off the
        // right edge with no way to reach them. Now the row just scrolls.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _TabIconButton(
                icon: Icons.receipt_long_rounded,
                label: 'Orders',
                badgeCount: pendingCount,
                isDark: widget.isDark,
                selected: _selected == _DashboardSection.orders,
                onTap: () => setState(() => _selected = _DashboardSection.orders),
              ),
              const SizedBox(width: 12),
              _TabIconButton(
                icon: Icons.view_carousel_rounded,
                label: 'Banners',
                badgeCount: 0,
                isDark: widget.isDark,
                selected: _selected == _DashboardSection.banners,
                onTap: () => setState(() => _selected = _DashboardSection.banners),
              ),
              const SizedBox(width: 12),
              _TabIconButton(
                icon: Icons.sell_outlined,
                label: 'Categories',
                badgeCount: 0,
                isDark: widget.isDark,
                selected: _selected == _DashboardSection.categories,
                onTap: () => setState(() => _selected = _DashboardSection.categories),
              ),
              const SizedBox(width: 12),
              _TabIconButton(
                icon: Icons.bakery_dining_rounded,
                label: 'Products',
                badgeCount: 0,
                isDark: widget.isDark,
                selected: _selected == _DashboardSection.products,
                onTap: () => setState(() => _selected = _DashboardSection.products),
              ),
              const SizedBox(width: 12),
              _TabIconButton(
                icon: Icons.settings_rounded,
                label: 'Settings',
                badgeCount: 0,
                isDark: widget.isDark,
                selected: _selected == _DashboardSection.settings,
                onTap: () => setState(() => _selected = _DashboardSection.settings),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        switch (_selected) {
          _DashboardSection.orders => _OrderManager(orders: widget.orders, isDark: widget.isDark),
          _DashboardSection.banners => _BannerManager(banners: widget.banners, isDark: widget.isDark),
          _DashboardSection.categories => _CategoryManager(categories: widget.categories, isDark: widget.isDark),
          _DashboardSection.products => _ProductManager(products: widget.products, categories: widget.categories, isDark: widget.isDark),
          _DashboardSection.settings => _SettingsManager(settings: widget.settings, isDark: widget.isDark),
        },
      ],
    );
  }
}

/// One icon tab: a circular icon tile with a label underneath, filled gold
/// when selected. Carries an optional small red count badge (used for
/// pending orders) in its top-right corner.
class _TabIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final bool isDark;
  final bool selected;
  final VoidCallback onTap;

  const _TabIconButton({
    required this.icon,
    required this.label,
    required this.badgeCount,
    required this.isDark,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.wheatGold : textColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selected ? Colors.transparent : AppColors.cardBorder),
                    ),
                    child: Icon(icon, size: 24, color: selected ? AppColors.espressoDeep : textColor.withOpacity(0.75)),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        constraints: const BoxConstraints(minWidth: 18),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          '$badgeCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.wheatGoldDark : textColor.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  final bool isDark;
  const _TopBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    final titleColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    return Row(
      children: [
        Material(
          color: (isDark ? Colors.white : AppColors.espressoDeep).withOpacity(0.08),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              // When the dashboard is opened directly via the '/admin' URL
              // (its normal entry point now that it's off the nav bar)
              // there's nothing to pop back to, so fall back to the store.
              final navigator = Navigator.of(context);
              if (navigator.canPop()) {
                navigator.pop();
              } else {
                navigator.pushReplacementNamed('/');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(Icons.arrow_back, color: iconColor, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('OVERVIEW', style: AppTheme.eyebrow()),
              const SizedBox(height: 2),
              // FittedBox + maxLines:1 shrinks the font just enough to keep
              // "Dashboard" on one line on narrow phones, instead of Text
              // wrapping it mid-word ("Dashboar" / "d") when the back
              // button + Sign out button squeeze this Expanded down.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'Dashboard',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ),
        Material(
          color: (isDark ? Colors.white : AppColors.espressoDeep).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              await SupabaseConfig.client.auth.signOut();
              if (context.mounted) Navigator.of(context).pushReplacementNamed('/admin');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.logout_rounded, size: 18, color: iconColor),
                  const SizedBox(width: 8),
                  Text('Sign out', style: TextStyle(color: iconColor, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Order management — view placed orders, mark done, remove
// ---------------------------------------------------------------------------

enum _OrderFilter { all, pending, completed }

/// Lets the admin see every order customers have placed at checkout,
/// newest first. Reads straight from `OrderStore` — no backend, so this is
/// the same in-memory, live-sync pattern as the product catalog and
/// banner strip. Lets the owner mark an order done once it's been
/// fulfilled, filter by that status, or remove one from the list.
class _OrderManager extends StatefulWidget {
  final List<Order> orders;
  final bool isDark;
  const _OrderManager({required this.orders, required this.isDark});

  @override
  State<_OrderManager> createState() => _OrderManagerState();
}

class _OrderManagerState extends State<_OrderManager> {
  _OrderFilter _filter = _OrderFilter.all;

  void _confirmDelete(Order order) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this order?'),
        content: Text('"${order.fullName.isEmpty ? 'This order' : order.fullName}" will be removed from the dashboard.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await OrderStore.removeById(order.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not remove order: $e')),
                  );
                }
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? AppColors.cream : AppColors.espressoDeep;
    final cardColor = widget.isDark ? Colors.white.withOpacity(0.06) : AppColors.cream;
    final orders = widget.orders;
    final pendingCount = orders.where((o) => !o.isCompleted).length;
    final visibleOrders = switch (_filter) {
      _OrderFilter.all => orders,
      _OrderFilter.pending => orders.where((o) => !o.isCompleted).toList(),
      _OrderFilter.completed => orders.where((o) => o.isCompleted).toList(),
    };

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Orders', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 14),
          Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: _filter == _OrderFilter.all,
                textColor: textColor,
                onTap: () => setState(() => _filter = _OrderFilter.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: pendingCount == 0 ? 'Pending' : 'Pending ($pendingCount)',
                selected: _filter == _OrderFilter.pending,
                textColor: textColor,
                onTap: () => setState(() => _filter = _OrderFilter.pending),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Completed',
                selected: _filter == _OrderFilter.completed,
                textColor: textColor,
                onTap: () => setState(() => _filter = _OrderFilter.completed),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (visibleOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  orders.isEmpty
                      ? 'No orders yet — they\'ll show up here as customers check out.'
                      : 'Nothing in this filter.',
                  style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13.5),
                ),
              ),
            )
          else
            ...visibleOrders.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrderTile(
                    key: ValueKey(o.id),
                    order: o,
                    textColor: textColor,
                    isDark: widget.isDark,
                    onToggleCompleted: () => OrderStore.setCompleted(o.id, !o.isCompleted),
                    onDelete: () => _confirmDelete(o),
                  ),
                )),
        ],
      ),
    );
  }
}

/// Small pill used for the All / Pending / Completed order filter.
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color textColor;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.textColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.wheatGold : textColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? Colors.transparent : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: selected ? AppColors.espressoDeep : textColor.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

/// One order in the list — a collapsed summary row that expands to show
/// the customer's phone/address/payment method and line items, plus the
/// "mark as done" and "remove" actions.
class _OrderTile extends StatefulWidget {
  final Order order;
  final Color textColor;
  final bool isDark;
  final VoidCallback onToggleCompleted;
  final VoidCallback onDelete;

  const _OrderTile({
    super.key,
    required this.order,
    required this.textColor,
    required this.isDark,
    required this.onToggleCompleted,
    required this.onDelete,
  });

  @override
  State<_OrderTile> createState() => _OrderTileState();
}

class _OrderTileState extends State<_OrderTile> {
  bool _expanded = false;

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} · $hour:$minute $ampm';
  }

  String _paymentLabel(String method) => switch (method) {
        'vodafone_cash' => 'Vodafone Cash',
        'instapay' => 'InstaPay',
        _ => 'Cash on delivery',
      };

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final textColor = widget.textColor;
    return Container(
      decoration: BoxDecoration(
        color: (widget.isDark ? Colors.white : AppColors.espressoDeep).withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: o.isCompleted ? Colors.green.withOpacity(0.35) : AppColors.cardBorder,
        ),
      ),
      child: Opacity(
        opacity: o.isCompleted ? 0.65 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  o.fullName.isEmpty ? 'Unnamed customer' : o.fullName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: textColor),
                                ),
                              ),
                              if (o.isCompleted) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.check_circle_rounded, size: 15, color: Colors.green),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(_formatDate(o.createdAt), style: TextStyle(fontSize: 11.5, color: textColor.withOpacity(0.6))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatEGP(o.total), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.wheatGoldDark)),
                        const SizedBox(height: 3),
                        Text('${o.items.length} item${o.items.length == 1 ? '' : 's'}', style: TextStyle(fontSize: 11.5, color: textColor.withOpacity(0.6))),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: textColor.withOpacity(0.6)),
                  ],
                ),
              ),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(color: AppColors.cardBorder, height: 1),
                    const SizedBox(height: 10),
                    Text('Phone', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.wheatGoldDark)),
                    const SizedBox(height: 3),
                    Text(o.phone, style: TextStyle(fontSize: 13, color: textColor)),
                    const SizedBox(height: 12),
                    Text('Payment', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.wheatGoldDark)),
                    const SizedBox(height: 3),
                    Text(_paymentLabel(o.paymentMethod), style: TextStyle(fontSize: 13, color: textColor)),
                    const SizedBox(height: 12),
                    Text('Delivery address', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.wheatGoldDark)),
                    const SizedBox(height: 3),
                    Text(o.address, style: TextStyle(fontSize: 13, color: textColor)),
                    const SizedBox(height: 12),
                    Text('Items', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.wheatGoldDark)),
                    const SizedBox(height: 6),
                    ...o.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('${item.quantity} × ${item.productName}', style: TextStyle(fontSize: 13, color: textColor)),
                              ),
                              Text(formatEGP(item.lineTotal), style: TextStyle(fontSize: 13, color: textColor.withOpacity(0.7))),
                            ],
                          ),
                        )),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onToggleCompleted,
                            child: Text(o.isCompleted ? 'Mark as pending' : 'Mark as done'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: widget.onDelete,
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                          tooltip: 'Remove',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Banner management — add, reorder, delete the Home page promo strip
// ---------------------------------------------------------------------------

/// Lets the admin manage the photos in the promotional banner strip near
/// the top of the Home page: add a new photo, drag to reorder, or remove
/// one. Writes go straight through `HomeBannerStore`, which is what the
/// storefront listens to — so changes here show up on the site the moment
/// they're saved, no refresh needed.
class _BannerManager extends StatefulWidget {
  final List<HomeBanner> banners;
  final bool isDark;
  const _BannerManager({required this.banners, required this.isDark});

  @override
  State<_BannerManager> createState() => _BannerManagerState();
}

class _BannerManagerState extends State<_BannerManager> {
  bool _uploading = false;

  Future<void> _addBanner() async {
    setState(() => _uploading = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        await HomeBannerStore.addFromBytes(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload banner: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _deleteBanner(HomeBanner banner) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove banner?'),
        content: const Text('It will disappear from the banner strip on the Home page.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await HomeBannerStore.removeById(banner.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not remove banner: $e')),
                  );
                }
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _reorder(int oldIndex, int newIndex) {
    final list = [...widget.banners];
    if (newIndex > oldIndex) newIndex -= 1;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    HomeBannerStore.reorder(list);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? AppColors.cream : AppColors.espressoDeep;
    final cardColor = widget.isDark ? Colors.white.withOpacity(0.06) : AppColors.cream;
    final banners = widget.banners;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Home Banners', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
              ElevatedButton.icon(
                onPressed: _uploading ? null : _addBanner,
                icon: _uploading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.espressoDeep),
                      )
                    : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('Add Banner'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'The photos that auto-advance in the strip near the top of the Home page, every 5 seconds. '
            'Drag to reorder. Keep the important part of the photo centered — a 16:9 photo (e.g. 1920×1080) '
            'works best.',
            style: TextStyle(fontSize: 12.5, color: textColor.withOpacity(0.6)),
          ),
          const SizedBox(height: 18),
          if (banners.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No banners yet — add your first one.',
                    style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13.5)),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // Flutter's ReorderableListView auto-adds its own drag handle
              // on the trailing edge on desktop/web — that clashes with our
              // delete button on the right, so it's turned off in favor of
              // our own left-side handle below.
              buildDefaultDragHandles: false,
              itemCount: banners.length,
              onReorder: _reorder,
              itemBuilder: (context, i) {
                final banner = banners[i];
                return Padding(
                  key: ValueKey(banner.id),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BannerRow(
                    index: i,
                    banner: banner,
                    textColor: textColor,
                    isDark: widget.isDark,
                    onDelete: () => _deleteBanner(banner),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// One row in the banner list: drag handle, thumbnail, delete button.
class _BannerRow extends StatelessWidget {
  final HomeBanner banner;
  final int index;
  final Color textColor;
  final bool isDark;
  final VoidCallback onDelete;

  const _BannerRow({
    required this.banner,
    required this.index,
    required this.textColor,
    required this.isDark,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : AppColors.espressoDeep).withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Icon(Icons.drag_handle_rounded, color: textColor.withOpacity(0.6)),
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(banner.imageUrl, width: 72, height: 40, fit: BoxFit.cover),
          ),
          const Spacer(),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category management — add/remove the categories products can be tagged with
// ---------------------------------------------------------------------------

/// Lets the owner add or remove product categories. These are the only
/// categories that exist anywhere in the app — the storefront filter chips
/// and the product form's category picker both read straight from this
/// list, so there's nothing hardcoded to fall back on.
class _CategoryManager extends StatefulWidget {
  final List<Category> categories;
  final bool isDark;
  const _CategoryManager({required this.categories, required this.isDark});

  @override
  State<_CategoryManager> createState() => _CategoryManagerState();
}

class _CategoryManagerState extends State<_CategoryManager> {
  bool _adding = false;

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    setState(() => _adding = true);
    try {
      await CategoryStore.add(name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add category: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _deleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove category?'),
        content: Text(
          '"${category.name}" will disappear from the storefront filters and the product form. '
          'Products already tagged with it keep that value until you edit them.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await CategoryStore.removeById(category.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not remove category: $e')),
                  );
                }
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? AppColors.cream : AppColors.espressoDeep;
    final cardColor = widget.isDark ? Colors.white.withOpacity(0.06) : AppColors.cream;
    final categories = widget.categories;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
              ElevatedButton.icon(
                onPressed: _adding ? null : _addCategory,
                icon: _adding
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.espressoDeep),
                      )
                    : const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Category'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'These are the categories shoppers can filter by on Home, and the choices offered when adding or '
            'editing a product. Nothing is hardcoded — add whatever fits the menu, and remove what you don\'t need.',
            style: TextStyle(fontSize: 12.5, color: textColor.withOpacity(0.6)),
          ),
          const SizedBox(height: 18),
          if (categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No categories yet — add your first one.',
                    style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13.5)),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((c) {
                return Container(
                  padding: const EdgeInsets.only(left: 14, right: 6, top: 6, bottom: 6),
                  decoration: BoxDecoration(
                    color: (widget.isDark ? Colors.white : AppColors.espressoDeep).withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.name, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textColor)),
                      const SizedBox(width: 2),
                      IconButton(
                        onPressed: () => _deleteCategory(c),
                        icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                        tooltip: 'Remove',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Product management — add, edit, delete catalog items
// ---------------------------------------------------------------------------

/// Lets the admin browse every product in the catalog and add, edit, or
/// remove one. Writes go straight through `ProductStore`, which is what
/// the storefront listens to — so changes here show up on the site the
/// moment they're saved, no refresh needed.
class _ProductManager extends StatelessWidget {
  final List<Product> products;
  final List<Category> categories;
  final bool isDark;
  const _ProductManager({required this.products, required this.categories, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    final cardColor = isDark ? Colors.white.withOpacity(0.06) : AppColors.cream;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Manage Products',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _openProductForm(context),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Product'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No products yet — add your first one.',
                    style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13.5)),
              ),
            )
          else
            ...List.generate(products.length, (i) {
              final p = products[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ProductRow(
                  product: p,
                  textColor: textColor,
                  isDark: isDark,
                  onEdit: () => _openProductForm(context, existing: p),
                  onDelete: () => _confirmDelete(context, product: p),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _openProductForm(BuildContext context, {Product? existing}) {
    showDialog(
      context: context,
      builder: (context) => _ProductFormDialog(existing: existing, categories: categories),
    );
  }

  void _confirmDelete(BuildContext context, {required Product product}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove product?'),
        content: Text('This will remove "${product.name}" from the catalog.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await ProductStore.removeById(product.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not remove product: $e')),
                  );
                }
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

/// One row in the product list: emoji, name/price/category, edit + delete.
class _ProductRow extends StatelessWidget {
  final Product product;
  final Color textColor;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductRow({
    required this.product,
    required this.textColor,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : AppColors.espressoDeep).withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.wheatGold.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: product.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      product.imageUrl!,
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.image_outlined, size: 18, color: textColor.withOpacity(0.4)),
                    ),
                  )
                : product.imageBytes != null
                    ? Image.memory(product.imageBytes!, width: 38, height: 38, fit: BoxFit.cover)
                    : (product.emoji.isNotEmpty
                        ? Text(product.emoji, style: const TextStyle(fontSize: 18))
                        : Icon(Icons.image_outlined, size: 18, color: textColor.withOpacity(0.4))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  textDirection: autoTextDirection(product.name),
                  textAlign: autoTextAlign(product.name),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.category.isEmpty ? 'Uncategorized' : product.category} · ${formatEGP(product.price)}',
                  style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit_rounded, size: 18, color: textColor.withOpacity(0.75)),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}

/// Add/edit form. When `existing` is null this creates a new product via
/// `ProductStore.add`; otherwise it saves changes via `ProductStore.update`.
class _ProductFormDialog extends StatefulWidget {
  final Product? existing;
  final List<Category> categories;
  const _ProductFormDialog({this.existing, required this.categories});

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _ingredients;
  late final TextEditingController _allergens;
  late final TextEditingController _prepMinutes;
  late final TextEditingController _rating;
  late final TextEditingController _reviewCount;
  late String? _category;

  Uint8List? _imageBytes; // newly picked photo, not yet uploaded
  String? _existingImageUrl; // photo already on the product, kept if untouched
  bool _imagePicking = false;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '');
    _ingredients = TextEditingController(text: p?.ingredients.join(', ') ?? '');
    _allergens = TextEditingController(text: p?.allergens.join(', ') ?? '');
    _prepMinutes = TextEditingController(text: p != null ? p.prepMinutes.toString() : '');
    _rating = TextEditingController(text: p != null ? p.rating.toString() : '4.8');
    _reviewCount = TextEditingController(text: p != null ? p.reviewCount.toString() : '0');
    final existingCategory = p?.category;
    final categoryStillExists =
        existingCategory != null && widget.categories.any((c) => c.name == existingCategory);
    _category = categoryStillExists ? existingCategory : null;
    if (_category == null && widget.categories.isNotEmpty) {
      _category = widget.categories.first.name;
    }
    _existingImageUrl = p?.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _ingredients.dispose();
    _allergens.dispose();
    _prepMinutes.dispose();
    _rating.dispose();
    _reviewCount.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _imagePicking = true);
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (mounted) setState(() => _imageBytes = bytes);
      }
    } finally {
      if (mounted) setState(() => _imagePicking = false);
    }
  }

  List<String> _splitCsv(String text) =>
      text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final existing = widget.existing;
      String? imageUrl = _existingImageUrl;
      if (_imageBytes != null) {
        // A new photo was picked — upload it and use the returned URL.
        imageUrl = await SupabaseConfig.uploadImage(
          bucket: 'product-images',
          bytes: _imageBytes!,
        );
      }

      final product = Product(
        id: existing?.id ?? '',
        name: _name.text.trim(),
        description: _description.text.trim(),
        price: double.tryParse(_price.text.trim()) ?? 0,
        category: _category ?? '',
        emoji: existing?.emoji ?? '',
        imageUrl: imageUrl,
        tags: existing?.tags ?? const [],
        story: existing?.story ?? '',
        highlights: existing?.highlights ?? const [],
        ingredients: _splitCsv(_ingredients.text),
        allergens: _splitCsv(_allergens.text),
        calories: existing?.calories ?? 0,
        prepMinutes: int.tryParse(_prepMinutes.text.trim()) ?? 0,
        rating: double.tryParse(_rating.text.trim()) ?? 4.8,
        reviewCount: int.tryParse(_reviewCount.text.trim()) ?? 0,
      );

      if (_isEditing) {
        await ProductStore.update(product);
      } else {
        await ProductStore.add(product);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Product' : 'Add Product',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _name,
                          builder: (context, value, __) => TextFormField(
                            controller: _name,
                            textDirection: autoTextDirection(value.text),
                            textAlign: autoTextAlign(value.text),
                            decoration: const InputDecoration(labelText: 'Name (English or Arabic)'),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ImageUploadField(
                          imageBytes: _imageBytes,
                          existingImageUrl: _imageBytes == null ? _existingImageUrl : null,
                          isLoading: _imagePicking,
                          onTap: _pickImage,
                          onClear: (_imageBytes == null && _existingImageUrl == null)
                              ? null
                              : () => setState(() {
                                    _imageBytes = null;
                                    _existingImageUrl = null;
                                  }),
                        ),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _description,
                          builder: (context, value, __) => TextFormField(
                            controller: _description,
                            textDirection: autoTextDirection(value.text),
                            textAlign: autoTextAlign(value.text),
                            decoration: const InputDecoration(labelText: 'Description (English or Arabic)'),
                            maxLines: 2,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _price,
                                decoration: const InputDecoration(labelText: 'Price (EGP)'),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Required';
                                  if (double.tryParse(v.trim()) == null) return 'Enter a number';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: widget.categories.isEmpty
                                  ? InputDecorator(
                                      decoration: const InputDecoration(labelText: 'Category'),
                                      child: Text(
                                        'Add a category first',
                                        style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
                                      ),
                                    )
                                  : DropdownButtonFormField<String>(
                                      value: _category,
                                      decoration: const InputDecoration(labelText: 'Category'),
                                      items: widget.categories
                                          .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                                          .toList(),
                                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                      onChanged: (c) => setState(() => _category = c ?? _category),
                                    ),
                            ),
                          ],
                        ),
                        TextFormField(
                          controller: _ingredients,
                          decoration: const InputDecoration(labelText: 'Ingredients (comma-separated)'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _allergens,
                          decoration: const InputDecoration(labelText: 'Allergens (comma-separated)'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _prepMinutes,
                          decoration: const InputDecoration(labelText: 'Prep (min)'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _rating,
                                decoration: const InputDecoration(labelText: 'Rating (0–5)'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _reviewCount,
                                decoration: const InputDecoration(labelText: 'Review count'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.espressoDeep),
                            )
                          : Text(_isEditing ? 'Save Changes' : 'Add Product'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tap-to-upload box for the product photo. Shows a preview once an image
/// is picked, with a small remove button; otherwise shows an upload prompt.
class _ImageUploadField extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? existingImageUrl;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _ImageUploadField({
    required this.imageBytes,
    this.existingImageUrl,
    required this.isLoading,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null || existingImageUrl != null;
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 140,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(14),
          color: AppColors.surfaceCream,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageBytes != null)
              Image.memory(imageBytes!, fit: BoxFit.cover)
            else if (existingImageUrl != null)
              Image.network(existingImageUrl!, fit: BoxFit.cover)
            else
              Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppColors.espressoDeep.withOpacity(0.55)),
                          const SizedBox(height: 6),
                          Text(
                            'Upload product image',
                            style: TextStyle(fontSize: 13, color: AppColors.espressoDeep.withOpacity(0.6)),
                          ),
                        ],
                      ),
              ),
            if (hasImage && onClear != null)
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.black.withOpacity(0.55),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onClear,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.close_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings — WhatsApp number, InstaPay link, Vodafone Cash number
// ---------------------------------------------------------------------------

/// Lets the owner edit the three checkout-facing contact/payment values
/// without touching code: the WhatsApp number new orders are sent to, the
/// InstaPay payment link, and the Vodafone Cash number. Saved straight to
/// the single `store_settings` row in Supabase; the storefront picks up
/// the change the next time it loads.
class _SettingsManager extends StatefulWidget {
  final StoreSettings settings;
  final bool isDark;
  const _SettingsManager({required this.settings, required this.isDark});

  @override
  State<_SettingsManager> createState() => _SettingsManagerState();
}

class _SettingsManagerState extends State<_SettingsManager> {
  late final TextEditingController _whatsappController;
  late final TextEditingController _instapayController;
  late final TextEditingController _vodafoneController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _whatsappController = TextEditingController(text: widget.settings.whatsappNumber);
    _instapayController = TextEditingController(text: widget.settings.instapayLink);
    _vodafoneController = TextEditingController(text: widget.settings.vodafoneCashNumber);
  }

  @override
  void didUpdateWidget(covariant _SettingsManager old) {
    super.didUpdateWidget(old);
    // Keep the fields in sync if settings were reloaded from elsewhere
    // (e.g. right after loadAll() on dashboard open), but don't stomp on
    // text the owner is actively editing.
    if (!_saving) {
      _whatsappController.text = widget.settings.whatsappNumber;
      _instapayController.text = widget.settings.instapayLink;
      _vodafoneController.text = widget.settings.vodafoneCashNumber;
    }
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    _instapayController.dispose();
    _vodafoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await StoreSettingsStore.update(StoreSettings(
        whatsappNumber: _whatsappController.text.trim(),
        instapayLink: _instapayController.text.trim(),
        vodafoneCashNumber: _vodafoneController.text.trim(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save settings: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? AppColors.cream : AppColors.espressoDeep;
    final cardColor = widget.isDark ? Colors.white.withOpacity(0.06) : AppColors.cream;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 6),
          Text(
            'These control what customers see at checkout — no code changes needed. '
            'Run the store_settings table SQL once from your Supabase project if this is the first save.',
            style: TextStyle(fontSize: 12.5, color: textColor.withOpacity(0.6)),
          ),
          const SizedBox(height: 20),
          _SettingsField(
            label: 'WhatsApp number',
            hint: 'Country code + number, digits only — e.g. 201001234567',
            controller: _whatsappController,
            textColor: textColor,
          ),
          const SizedBox(height: 14),
          _SettingsField(
            label: 'InstaPay payment link',
            hint: 'From the InstaPay app: Profile → Payment Link',
            controller: _instapayController,
            textColor: textColor,
          ),
          const SizedBox(height: 14),
          _SettingsField(
            label: 'Vodafone Cash number',
            hint: 'The wallet number customers send transfers to',
            controller: _vodafoneController,
            textColor: textColor,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.espressoDeep),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final Color textColor;
  const _SettingsField({required this.label, required this.hint, required this.controller, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: TextStyle(fontSize: 13.5, color: textColor),
          decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(fontSize: 12.5, color: textColor.withOpacity(0.4))),
        ),
      ],
    );
  }
}
