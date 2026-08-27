import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/app_language.dart';
import 'screens/splash_screen.dart';
import 'screens/admin_gate_screen.dart';
import 'services/supabase_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SupabaseConfig.init();
  runApp(const ElloraApp());
}

class ElloraApp extends StatelessWidget {
  const ElloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppLanguage.isArabic,
      builder: (context, isArabic, _) => MaterialApp(
        title: 'Ellora Cosmetics',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeFor(isArabic),
        initialRoute: WidgetsBinding.instance.platformDispatcher.defaultRouteName,
        routes: {
          '/': (context) => const SplashScreen(),
          '/admin': (context) => const AdminGateScreen(),
        },
      ),
    );
  }
}
