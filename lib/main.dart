import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/app_language.dart';
import 'screens/splash_screen.dart';
import 'screens/admin_gate_screen.dart';
import 'services/supabase_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Deliberately NOT calling usePathUrlStrategy() here. That makes a plain
  // yoursite.com/admin (no '#') work locally, but on a static host with no
  // server-side rewrites — GitHub Pages, in particular — a direct request
  // to /admin has no matching file on the server and 404s before Flutter
  // ever loads. Hash-based routing (the default) always works everywhere
  // with zero server config, because the '#/admin' part never gets sent
  // to the server at all — the server only ever sees a request for '/'.
  // Montserrat (English) and Cairo (Arabic) are both bundled locally
  // (assets/fonts/) and referenced via fontFamily everywhere, so first
  // paint never waits on a font network request at all.
  // Don't block the very first paint on a network round-trip: kick off
  // Supabase init in the background while the splash screen renders
  // immediately. Screens that actually need Supabase (admin, product
  // loads) await SupabaseConfig.ready internally.
  SupabaseConfig.init();
  runApp(const ElloraApp());
}

class ElloraApp extends StatelessWidget {
  const ElloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The whole app's theme swaps between Montserrat (English) and Cairo
    // (Arabic) based on the storefront's language notifier, so headline,
    // body, and label styles pulled from Theme.of(context).textTheme pick
    // up the right typeface automatically. The admin route pins its own
    // fixed Montserrat/English Theme regardless (see AdminGateScreen).
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isArabic,
      builder: (context, isArabic, _) => MaterialApp(
        title: 'Ellora Cosmetics',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeFor(isArabic),
        // Read the URL the browser was actually pointed at instead of
        // always hardcoding '/' here. With a hardcoded '/', opening
        // yoursite.com/#/admin still booted the splash screen every time —
        // and the splash's own fixed-duration timer then unconditionally
        // pushes HomeScreen next, silently swapping the dashboard out for
        // the public storefront a few seconds later. That's what looked
        // like "the dashboard kicks me back to the site" — it wasn't a
        // redirect on top of /admin, it was /admin never actually loading.
        initialRoute: WidgetsBinding.instance.platformDispatcher.defaultRouteName,
        // The admin dashboard has no link in the storefront's nav bar on
        // purpose — shoppers shouldn't stumble into it. It's reached
        // directly by URL instead: yoursite.com/#/admin (the '#' is
        // required — see the note in main() above).
        routes: {
          '/': (context) => const SplashScreen(),
          '/admin': (context) => const AdminGateScreen(),
        },
      ),
    );
  }
}
