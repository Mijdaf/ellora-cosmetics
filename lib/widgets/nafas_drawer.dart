import 'package:flutter/material.dart';
import '../services/app_language.dart';
import '../theme/app_theme.dart';

/// The phone-sized navigation drawer.
///
/// On narrow screens the hamburger button in [NavBar] now opens this real
/// `Drawer` (sliding in from the edge — left in LTR, right in RTL,
/// automatically, since it reads the ambient `Directionality`) instead of a
/// small floating dropdown. It carries everything the pill nav bar can't
/// fit on a phone: the nav links, a cart shortcut, and the mood/language
/// toggles — styled with the same espresso + gold palette so it reads as
/// part of the same brand rather than a generic Material drawer.
class NafasDrawer extends StatelessWidget {
  final int cartCount;
  final int activeNavIndex; // -1 = none, matches ['Menu', 'About'] order
  final List<VoidCallback>? onNavLinkTap; // matches ['Menu', 'About']
  final VoidCallback? onViewCart;
  final VoidCallback? onBrowseMenu;

  const NafasDrawer({
    super.key,
    this.cartCount = 0,
    this.activeNavIndex = -1,
    this.onNavLinkTap,
    this.onViewCart,
    this.onBrowseMenu,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isArabic,
      builder: (context, isArabic, _) => Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: _buildDrawer(context, isArabic),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, bool isArabic) {
    final labels = [S.t('nav_menu', isArabic), S.t('nav_about', isArabic)];
    const icons = [Icons.restaurant_menu, Icons.favorite_border];
    const iconsActive = [Icons.restaurant_menu, Icons.favorite];

    return Drawer(
      backgroundColor: AppColors.espressoDeep,
      width: 288,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: logo + wordmark + close button.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.espresso),
                    padding: const EdgeInsets.all(1.5),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.eco, color: AppColors.wheatGold, size: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Nafas',
                    style: AppTheme.brandWordmark(isArabic: isArabic).copyWith(fontSize: 21, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  _DrawerIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Divider(color: AppColors.wheatGold.withOpacity(0.15), height: 1, thickness: 1),
            const SizedBox(height: 10),
            // Nav links.
            ...List.generate(labels.length, (i) {
              final isActive = activeNavIndex == i;
              return _DrawerLinkTile(
                label: labels[i],
                icon: isActive ? iconsActive[i] : icons[i],
                isActive: isActive,
                isArabic: isArabic,
                onTap: () {
                  Navigator.of(context).maybePop();
                  if (onNavLinkTap != null && i < onNavLinkTap!.length) onNavLinkTap![i]();
                },
              );
            }),
            const Spacer(),
            Divider(color: AppColors.wheatGold.withOpacity(0.15), height: 1, thickness: 1),
            const SizedBox(height: 6),
            // Cart shortcut — same "browse vs view" logic as the nav bar's
            // cart dropdown, just as a single tappable row here.
            _DrawerLinkTile(
              label: cartCount == 0
                  ? S.t('browse_menu', isArabic)
                  : '${S.t('view_cart', isArabic)} ($cartCount)',
              icon: Icons.shopping_bag_outlined,
              isActive: false,
              isArabic: isArabic,
              onTap: () {
                Navigator.of(context).maybePop();
                cartCount == 0 ? onBrowseMenu?.call() : onViewCart?.call();
              },
            ),
            const SizedBox(height: 8),
            // Footer: mood + language toggles.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              child: Row(
                children: const [
                  _DrawerMoodToggle(),
                  SizedBox(width: 10),
                  _DrawerLanguageToggle(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single tappable row inside the drawer — icon, label, and a soft gold
/// highlight + left/start accent bar when active, echoing the nav bar's
/// gold-pill "active" treatment without needing the magnetic-hover logic
/// (there's no hover on a phone).
class _DrawerLinkTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isArabic;
  final VoidCallback onTap;

  const _DrawerLinkTile({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isActive ? AppColors.wheatGold.withOpacity(0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? AppColors.wheatGoldLight : AppColors.cream.withOpacity(0.75),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFor(isArabic),
                      color: isActive ? AppColors.wheatGoldLight : AppColors.cream.withOpacity(0.92),
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 15.5,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.wheatGoldLight),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small round icon button matching the nav bar's compact icon-button
/// styling, used for the drawer's own close button.
class _DrawerIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _DrawerIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(child: Icon(icon, color: AppColors.cream, size: 20)),
        ),
      ),
    );
  }
}

/// Mood (dark/light) toggle, restyled as a labeled pill for the drawer
/// footer instead of the nav bar's bare icon circle — reads and writes the
/// same global `AppMood.isDark` notifier.
class _DrawerMoodToggle extends StatelessWidget {
  const _DrawerMoodToggle();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppMood.isDark,
      builder: (context, isDark, _) {
        return Expanded(
          child: _DrawerPillButton(
            onTap: AppMood.toggle,
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              size: 18,
              color: isDark ? AppColors.cream : AppColors.wheatGoldLight,
            ),
          ),
        );
      },
    );
  }
}

/// Language (EN/AR) toggle, restyled as a labeled pill for the drawer
/// footer — reads and writes the same global `AppLanguage.isArabic`
/// notifier as the nav bar's version.
class _DrawerLanguageToggle extends StatelessWidget {
  const _DrawerLanguageToggle();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isArabic,
      builder: (context, isArabic, _) {
        return Expanded(
          child: _DrawerPillButton(
            onTap: AppLanguage.toggle,
            child: Text(
              isArabic ? 'EN' : 'AR',
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: AppColors.wheatGoldLight,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.3,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shared pill-shaped tappable container for the two footer toggles.
class _DrawerPillButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _DrawerPillButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Material(
        color: AppColors.wheatGold.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}
