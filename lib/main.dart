import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/api/api_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/mayor_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Realtime Client with publishableKey
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
    realtimeClientOptions: const RealtimeClientOptions(
      logLevel: RealtimeLogLevel.info,
    ),
  );

  runApp(
    const ProviderScope(
      child: MayorApp(),
    ),
  );
}

class MayorApp extends ConsumerWidget {
  const MayorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.value;

    return MaterialApp(
      title: 'EMapandan Mayor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: user != null ? const MayorDashboardScreen() : const LoginScreen(),
    );
  }
}
