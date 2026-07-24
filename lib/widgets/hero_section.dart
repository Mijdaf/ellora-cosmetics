import 'package:flutter/material.dart';
import '../services/app_language.dart';
import '../theme/app_theme.dart';
import 'wheat_logo_3d.dart';

/// Hero section content only — background color, gradient and the floating
/// pastry-emoji field are painted once for the whole page (see
/// `_PageBackdrop` in home_screen.dart) so every section shares exactly the
/// same backdrop instead of each section owning its own.
class HeroSection extends StatefulWidget {
  final VoidCallback onExplore;
  final bool isDark;
  final bool isArabic;
  const HeroSection({super.key, required this.onExplore, required this.isDark, required this.isArabic});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> with TickerProviderStateMixin {
  late final AnimationController _entrance; // page-load reveal
  late final AnimationController _pulse; // CTA button breathing glow

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 900;
    final isDark = widget.isDark;
    final isArabic = widget.isArabic;
    // In light mood the hero backdrop turns light/cream, so text that used
    // to always be cream/white needs to flip to a dark espresso tone here —
    // otherwise it's white text on a near-white background and unreadable.
    final headlineColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    final wordmarkColor = isDark ? AppColors.cream : AppColors.espressoDeep;
    final bodyColor = isDark ? AppColors.cream.withOpacity(0.85) : AppColors.espressoDark.withOpacity(0.85);
    // Gold, not cream/espresso — this matches the outlined "Pastries /
    // Cakes / Bread / Coffee" filter pills further down the page, so the
    // secondary-button language stays the same everywhere instead of
    // switching between a white outline in the hero and a gold outline
    // in the menu section.
    final visitUsColor = AppColors.wheatGold;

    // Built once, then arranged differently depending on layout: side by
    // side (text left, logo right) on wide screens, or stacked — logo
    // first, then the wordmark/subtitle/buttons column — on narrow ones,
    // so the phone view leads with the mark before the copy.
    final textColumn = Expanded(
      flex: isNarrow ? 0 : 6,
      child: AnimatedBuilder(
        animation: _entrance,
        builder: (context, child) {
          final t = Curves.easeOutCubic.transform(_entrance.value);
          return Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, (1 - t) * 30), child: child),
          );
        },
        child: Column(
          crossAxisAlignment: isNarrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _LetterReveal(
              text: 'Nafas',
              style: AppTheme.brandWordmark(isArabic: isArabic).copyWith(fontSize: isNarrow ? 60 : 76, color: wordmarkColor),
              controller: _entrance,
              startInterval: 0.0,
              endInterval: 0.55,
            ),
            const SizedBox(height: 6),
            Text(
              S.t('hero_eyebrow', isArabic),
              style: AppTheme.eyebrow(isArabic: isArabic).copyWith(color: isDark ? AppColors.wheatGold : AppColors.wheatGoldDark),
            ),
            const SizedBox(height: 26),
            Text(
              S.t('hero_headline', isArabic),
              textAlign: isNarrow ? TextAlign.center : TextAlign.start,
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(fontSize: isNarrow ? 34 : 50, color: headlineColor),
            ),
            const SizedBox(height: 18),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isNarrow ? 500 : 480),
              child: Text(
                S.t('hero_body', isArabic),
                textAlign: isNarrow ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: bodyColor,
                  fontSize: 16,
                  height: 1.6,
                  fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                ),
              ),
            ),
            const SizedBox(height: 34),
            Wrap(
              alignment: isNarrow ? WrapAlignment.center : WrapAlignment.start,
              spacing: 16,
              runSpacing: 12,
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, child) {
                    final glow = 0.25 + _pulse.value * 0.35;
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.wheatGold.withOpacity(glow),
                            blurRadius: 22,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: ElevatedButton(
                    onPressed: widget.onExplore,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(S.t('explore_menu', isArabic)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: visitUsColor,
                    side: BorderSide(color: visitUsColor.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    minimumSize: const Size(0, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                    textStyle: TextStyle(fontFamily: AppTheme.fontFor(isArabic), fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  child: Text(S.t('visit_us', isArabic)),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final logo = Expanded(
      flex: isNarrow ? 0 : 5,
      child: Padding(
        padding: EdgeInsets.only(top: isNarrow ? 0 : 0, bottom: isNarrow ? 30 : 0),
        child: const Center(child: WheatLogo3D(size: 220)),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isNarrow ? 24 : 80,
        isNarrow ? 110 : 140,
        isNarrow ? 24 : 80,
        isNarrow ? 60 : 100,
      ),
      child: Flex(
        direction: isNarrow ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.center,
        // Logo first on a phone (stacked layout), text first on wider
        // screens (side-by-side layout, text on the leading side).
        children: isNarrow
            ? [logo, textColumn]
            : [textColumn, const SizedBox(width: 40), logo],
      ),
    );
  }
}

/// Reveals a word letter-by-letter (fade + slide-up), staggered across a
/// slice of a shared entrance controller's timeline — gives the brand
/// wordmark a hand-set, typewriter-like arrival instead of popping in flat.
class _LetterReveal extends StatelessWidget {
  final String text;
  final TextStyle style;
  final AnimationController controller;
  final double startInterval;
  final double endInterval;

  const _LetterReveal({
    required this.text,
    required this.style,
    required this.controller,
    required this.startInterval,
    required this.endInterval,
  });

  @override
  Widget build(BuildContext context) {
    final letters = text.split('');
    // The brand wordmark is always the Latin word "Nafas", even on the
    // Arabic storefront — without this, the ambient RTL Directionality
    // (Arabic mode) lays these per-letter children out right-to-left and
    // the word visually reads backwards ("safaN").
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(letters.length, (i) {
          final segStart = startInterval + (endInterval - startInterval) * (i / letters.length);
          final segEnd = startInterval + (endInterval - startInterval) * ((i + 1) / letters.length);
          final animation = CurvedAnimation(
            parent: controller,
            curve: Interval(segStart.clamp(0, 1), segEnd.clamp(0, 1), curve: Curves.easeOutBack),
          );
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Opacity(
                opacity: animation.value.clamp(0, 1),
                child: Transform.translate(
                  offset: Offset(0, (1 - animation.value.clamp(0, 1)) * 18),
                  child: child,
                ),
              );
            },
            child: Text(letters[i], style: style),
          );
        }),
      ),
    );
  }
}
