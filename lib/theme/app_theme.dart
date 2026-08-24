import 'package:flutter/material.dart';

/// Brand palette sampled directly from the Ellora Cosmetics logo
/// (the pink "T/C" monogram on a blush-pink background).
///
/// NOTE ON FONTS: Montserrat is bundled locally as an asset (see
/// pubspec.yaml and assets/fonts/) and referenced everywhere via
/// `TextStyle(fontFamily: 'Montserrat', ...)` — no network request to
/// Google's font CDN, no fallback-font flash, first paint already has
/// the real Montserrat look (matching the logo's clean geometric
/// wordmark/tagline style).
class AppColors {
  AppColors._();

  // Deep rose tones — sampled from the darker end of the monogram's
  // shading. Field names kept as `espresso*` so every screen/widget that
  // already reads AppColors.espresso* just gets the new pink tone for free.
  static const Color espresso = Color(0xFFB4507A); // deep rose
  static const Color espressoDark = Color(0xFF8A3660); // darker rose
  static const Color espressoDeep = Color(0xFF5C1E42); // deepest plum-rose (hero/dark backdrop)

  // Sampled from the bold monogram / accent text.
  static const Color wheatGold = Color(0xFFEE7793); // primary Ellora pink
  static const Color wheatGoldLight = Color(0xFFF9A9C0); // light pink accent
  static const Color wheatGoldDark = Color(0xFFD65D82); // deeper pink accent (buttons/hover)

  // Sampled from the wordmark / page background.
  static const Color cream = Color(0xFFFFFBF5); // near-white, warmed toward Vanilla Ice
  static const Color pureWhite = Color(0xFFFFFFFF);

  static const List<Color> heroGradient = [espressoDeep, espresso, espressoDark];
  static const List<Color> goldGradient = [wheatGoldLight, wheatGold, wheatGoldDark];

  // ---------------------------------------------------------------------
  // Pantone pastel palette (client-supplied swatch board). Brand pink
  // (espresso*/wheatGold* above) is untouched — these pastels are used
  // only for neutral surfaces/backgrounds/borders and small accent
  // moments, so the brand pink still reads as *the* accent color against
  // a softer, more editorial backdrop.
  // ---------------------------------------------------------------------
  static const Color pantoneVanillaIce = Color(0xFFF9F1DE); // 11-0104 TCX
  static const Color pantoneButtercream = Color(0xFFEBDCC0); // 11-0110 TCX
  static const Color pantoneCoconutMilk = Color(0xFFEFE9DC); // 11-0608 TCX
  static const Color pantoneSnowWhite = Color(0xFFF3F2EF); // 11-0602 TCX
  static const Color pantoneHeavenlyPink = Color(0xFFF6DEE1); // 12-1305 TCX
  static const Color pantoneShrinkingViolet = Color(0xFFF7DDE2); // 11-2511 TCX
  static const Color pantone9285C = Color(0xFFF2EBE7); // 9285 C
  static const Color pantoneOrchidIce = Color(0xFFDDCCD6); // 13-3406 TCX
  static const Color pantoneWhispyBlue = Color(0xFFBFD1E0); // 13-4014 TSX
  static const Color pantoneDiaphonous = Color(0xFFE6F0EF); // 11-4607 TCX
  static const Color pantoneSylvanGreen = Color(0xFFDEE7CD); // 9581 C

  /// Small accent set (non-pink pastels from the swatch board) used for
  /// bits of variety — e.g. category chips — so the storefront doesn't
  /// read as one flat pink block. The brand pink is always used for the
  /// *selected/active* state, these only ever sit in an unselected/idle
  /// state.
  static const List<Color> pastelAccents = [
    pantoneWhispyBlue,
    pantoneDiaphonous,
    pantoneSylvanGreen,
    pantoneOrchidIce,
    pantoneButtercream,
  ];

  // Soft, warm alternative to heroGradient used for the page backdrop in
  // "light mood" — the hero banner itself always stays deep rose (it's the
  // brand's fixed masthead), but everything below it can switch to this
  // brighter, pastel-toned backdrop instead.
  static const List<Color> lightPageGradient = [pantoneVanillaIce, surfaceCream, pantoneHeavenlyPink];

  // Unified surface tones so every section reads as one family, not
  // separate blocks of color. Now sampled from the Pantone board (a soft
  // blush-neutral, close to "9285 C") instead of a flat pink tint.
  static const Color surfaceCream = pantone9285C;
  static const Color cardBorder = Color(0x33EE7793); // wheatGold(pink) @ 20%
  static const Color textOnCream = espressoDark;
}

/// Global "page mood" switch — dark (deep rose, default) or light (blush).
/// A single ValueNotifier is enough here (no extra state-management
/// package): any widget can react to it with a ValueListenableBuilder,
/// and toggling it only costs a rebuild of the small subtree that
/// actually listens, not the whole app.
class AppMood {
  AppMood._();
  static final ValueNotifier<bool> isDark = ValueNotifier<bool>(true);
  static void toggle() => isDark.value = !isDark.value;
}

/// Font: **Montserrat** for English copy, **Cairo** (a clean, modern
/// Arabic typeface — also bundled locally under assets/fonts/) for Arabic
/// copy. Use [AppTheme.fontFor] anywhere a `TextStyle` is built directly
/// with a hardcoded `fontFamily: 'Montserrat'` so it swaps to Cairo when
/// the storefront is in Arabic mode.
class AppTheme {
  AppTheme._();

  /// Pick the right typeface for the current storefront language.
  static String fontFor(bool isArabic) => isArabic ? 'Cairo' : 'Montserrat';

  static TextStyle _display(bool isArabic) =>
      TextStyle(fontFamily: fontFor(isArabic), fontWeight: FontWeight.w600);
  static TextStyle _displayUpright(bool isArabic) =>
      TextStyle(fontFamily: fontFor(isArabic), fontWeight: FontWeight.w600);
  static TextStyle _body(bool isArabic) => TextStyle(fontFamily: fontFor(isArabic));

  static TextTheme _textTheme(bool isArabic) => TextTheme(
        displayLarge: _display(isArabic).copyWith(
          fontSize: 58,
          fontWeight: FontWeight.w600,
          color: AppColors.cream,
          letterSpacing: -0.5,
          height: 1.05,
        ),
        displayMedium: _display(isArabic).copyWith(
          fontSize: 38,
          fontWeight: FontWeight.w600,
          color: AppColors.cream,
        ),
        headlineMedium: _displayUpright(isArabic).copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w600,
          color: AppColors.espressoDeep,
        ),
        titleLarge: _displayUpright(isArabic).copyWith(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          color: AppColors.espressoDeep,
        ),
        bodyLarge: _body(isArabic).copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.espressoDark,
          height: 1.6,
        ),
        bodyMedium: _body(isArabic).copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.espressoDark.withOpacity(0.75),
          height: 1.5,
        ),
        labelLarge: _body(isArabic).copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      );

  /// Large italic-serif brand wordmark ("Ellora") for hero/nav/footer moments.
  /// Pass `isArabic: true` when the wordmark sits next to Arabic copy so it
  /// picks up Cairo instead of Montserrat.
  static TextStyle brandWordmark({bool isArabic = false}) => _display(isArabic).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.cream,
        letterSpacing: 0.5,
      );

  /// Small pink caption/eyebrow text — used under the wordmark and above
  /// section titles for a boutique, editorial feel. The wide letter-spacing
  /// is an English-uppercase effect only: Arabic letters connect to their
  /// neighbors, so spacing them out breaks the connections and makes the
  /// (perfectly fine) Cairo font look broken/disjointed — so Arabic gets 0.
  static TextStyle eyebrow({bool isArabic = false}) => _body(isArabic).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.wheatGold,
        letterSpacing: isArabic ? 0 : 3,
        fontSize: 12,
      );

  /// Build the app's ThemeData for the given storefront language — English
  /// (Montserrat) or Arabic (Cairo). The admin dashboard always passes
  /// `false` so it stays in Montserrat/English no matter what a shopper has
  /// picked on the public site.
  static ThemeData themeFor(bool isArabic) => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.surfaceCream,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.wheatGold,
          primary: AppColors.wheatGold,
          secondary: AppColors.espresso,
          surface: AppColors.cream,
        ),
        textTheme: _textTheme(isArabic),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.wheatGold,
            foregroundColor: AppColors.pureWhite,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            minimumSize: const Size(0, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
            textStyle: TextStyle(fontFamily: fontFor(isArabic), fontWeight: FontWeight.w600, fontSize: 15),
            elevation: 0,
          ),
        ),
      );

  /// English/Montserrat theme — used by the admin dashboard, and as the
  /// storefront's default before `AppLanguage.isArabic` is read.
  static ThemeData get light => themeFor(false);
}
