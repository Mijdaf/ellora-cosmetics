import 'package:flutter/material.dart';

/// Brand palette sampled directly from the Nafas logo.
///
/// NOTE ON FONTS: Poppins is bundled locally as an asset (see pubspec.yaml
/// and assets/fonts/) and referenced everywhere via
/// `TextStyle(fontFamily: 'Poppins', ...)` — no network request to Google's
/// font CDN, no fallback-font flash, first paint already has the real
/// Poppins look.
class AppColors {
  AppColors._();

  // Sampled from logo background
  static const Color espresso = Color(0xFF693720);
  static const Color espressoDark = Color(0xFF4A2615);
  static const Color espressoDeep = Color(0xFF2E1810);

  // Sampled from the wheat stalk / accent text
  static const Color wheatGold = Color(0xFFF9AF18);
  static const Color wheatGoldLight = Color(0xFFFFC94D);
  static const Color wheatGoldDark = Color(0xFFD98F0A);

  // Sampled from the wordmark
  static const Color cream = Color(0xFFFFFDF7);
  static const Color pureWhite = Color(0xFFFFFFFF);

  static const List<Color> heroGradient = [espressoDeep, espresso, espressoDark];
  static const List<Color> goldGradient = [wheatGoldLight, wheatGold, wheatGoldDark];

  // Soft, warm alternative to heroGradient used for the page backdrop in
  // "light mood" — the hero banner itself always stays espresso (it's the
  // brand's fixed masthead), but everything below it can switch to this
  // brighter, cream-toned backdrop instead.
  static const List<Color> lightPageGradient = [Color(0xFFFFF3DC), surfaceCream, Color(0xFFFFF3DC)];

  // Unified surface tones so every section reads as one family, not
  // separate blocks of color.
  static const Color surfaceCream = Color(0xFFFFF9EC); // warmed cream, closer to gold
  static const Color cardBorder = Color(0x33F9AF18); // wheatGold @ 20%
  static const Color textOnCream = espressoDark;
}

/// Global "page mood" switch — dark (espresso, default) or light (cream).
/// A single ValueNotifier is enough here (no extra state-management
/// package): any widget can react to it with a ValueListenableBuilder,
/// and toggling it only costs a rebuild of the small subtree that
/// actually listens, not the whole app.
class AppMood {
  AppMood._();
  static final ValueNotifier<bool> isDark = ValueNotifier<bool>(true);
  static void toggle() => isDark.value = !isDark.value;
}

/// Font: **Poppins** for English copy, **Cairo** (a clean, modern
/// Arabic typeface — also bundled locally under assets/fonts/) for Arabic
/// copy. Use [AppTheme.fontFor] anywhere a `TextStyle` is built directly
/// with a hardcoded `fontFamily: 'Poppins'` so it swaps to Cairo when
/// the storefront is in Arabic mode.
class AppTheme {
  AppTheme._();

  /// Pick the right typeface for the current storefront language.
  static String fontFor(bool isArabic) => isArabic ? 'Cairo' : 'Poppins';

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

  /// Large italic-serif brand wordmark ("Nafas") for hero/nav/footer moments.
  /// Pass `isArabic: true` when the wordmark sits next to Arabic copy so it
  /// picks up Cairo instead of Poppins.
  static TextStyle brandWordmark({bool isArabic = false}) => _display(isArabic).copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.cream,
        letterSpacing: 0.5,
      );

  /// Small gold caption/eyebrow text — used under the wordmark and above
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
  /// (Poppins) or Arabic (Cairo). The admin dashboard always passes
  /// `false` so it stays in Poppins/English no matter what a shopper has
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
            foregroundColor: AppColors.espressoDeep,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            minimumSize: const Size(0, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
            textStyle: TextStyle(fontFamily: fontFor(isArabic), fontWeight: FontWeight.w600, fontSize: 15),
            elevation: 0,
          ),
        ),
      );

  /// English/Poppins theme — used by the admin dashboard, and as the
  /// storefront's default before `AppLanguage.isArabic` is read.
  static ThemeData get light => themeFor(false);
}
