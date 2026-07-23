import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_config.dart';
import '../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'admin_login_screen.dart';

/// Entry point for `/admin`. Shows the login form until there's an
/// active Supabase session, then swaps in the real dashboard — and
/// swaps back to the login form the moment the admin signs out.
class AdminGateScreen extends StatefulWidget {
  const AdminGateScreen({super.key});

  @override
  State<AdminGateScreen> createState() => _AdminGateScreenState();
}

class _AdminGateScreenState extends State<AdminGateScreen> {
  Stream<AuthState>? _authStream;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    SupabaseConfig.ready.then((_) {
      if (!mounted) return;
      setState(() {
        _authStream = SupabaseConfig.client.auth.onAuthStateChange;
        _ready = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // The admin dashboard always stays in English/Poppins for the owner,
    // no matter what language a shopper has picked on the public storefront
    // (the app-level theme swaps to Cairo for Arabic, so this route
    // pins its own Theme back to the fixed English one).
    return Theme(
      data: AppTheme.light,
      child: StreamBuilder<AuthState>(
        stream: _authStream,
        builder: (context, snapshot) {
          final loggedIn = SupabaseConfig.isLoggedIn;
          if (!loggedIn) {
            return AdminLoginScreen(onLoggedIn: () => setState(() {}));
          }
          return const AdminDashboardScreen();
        },
      ),
    );
  }
}
