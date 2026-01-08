import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/ui/m_design_system.dart';
import 'core/components/app_shell.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() {
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
      home: const AppShell(
        child: DashboardScreen(),
      ),
    );
  }
}
