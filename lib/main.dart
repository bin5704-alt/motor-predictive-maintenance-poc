import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'features/auth/auth_gate.dart';

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
      title: 'Quantum Leap | PDMS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // AuthGate handles the initial redirect based on session
      home: const AuthGate(),
    );
  }
}
