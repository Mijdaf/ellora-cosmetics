import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/app_language.dart';
import 'screens/splash_screen.dart';
import 'screens/admin_gate_screen.dart';
import 'services/supabase_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Poppins (English) and Cairo (Arabic) are both bundled locally
  // (assets/fonts/) and referenced via fontFamily everywhere, so first
  // paint never waits on a font network request at all.
  // Don't block the very first paint on a network round-trip: kick off
  // Supabase init in the background while the splash screen renders
  // immediately. Screens that actually need Supabase (admin, product
  // loads) await SupabaseConfig.ready internally.
  SupabaseConfig.init();
  runApp(const NafasApp());
}

class NafasApp extends StatelessWidget {
  const NafasApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The whole app's theme swaps between Poppins (English) and Cairo
    // (Arabic) based on the storefront's language notifier, so headline,
    // body, and label styles pulled from Theme.of(context).textTheme pick
    // up the right typeface automatically. The admin route pins its own
    // fixed Poppins/English Theme regardless (see AdminGateScreen).
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isArabic,
      builder: (context, isArabic, _) => MaterialApp(
        title: 'Nafas Bakery',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeFor(isArabic),
        initialRoute: '/',
        // The admin dashboard has no link in the storefront's nav bar on
        // purpose — shoppers shouldn't stumble into it. It's reached
        // directly by URL instead: on Flutter web that's yoursite.com/#/admin
        // (or yoursite.com/admin if the app uses path-based URL strategy).
        routes: {
          '/': (context) => const SplashScreen(),
          '/admin': (context) => const AdminGateScreen(),
        },
      ),
    );
  }
}
