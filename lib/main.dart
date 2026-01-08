import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/ui/m_design_system.dart';
import 'core/components/app_shell.dart';
import 'features/dashboard/dashboard_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ycwthostrbqajtjawbqp.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inljd3Rob3N0cmJxYWp0amF3YnFwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4Njg5NDUsImV4cCI6MjA4MzQ0NDk0NX0.KuwPMkcp3xa-tyxLX3Df-8rsL9zMeIO15neqtOfUYP8',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enterprise Equipment Monitoring',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Use AppShell to wrap the DashboardScreen
      home: const AppShell(child: DashboardScreen()),
    );
  }
}
