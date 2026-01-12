import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/monitoring/spot_diagnosis_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/profile/my_page_screen.dart';

// Simple state for navigation index - in a real app this might be connected to GoRouter
final _navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(
  NavigationIndexNotifier.new,
);

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

// ... (keep Notifier)

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // Reset navigation to Dashboard (index 0) whenever AppShell is mounted (Login success)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_navigationIndexProvider.notifier).setIndex(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final navIndex = ref.watch(_navigationIndexProvider);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    final pages = [
      const DashboardScreen(),
      const SpotDiagnosisScreen(),
      const HistoryScreen(),
      const MyPageScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quantum Leap'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Online',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              selectedIndex: navIndex,
              onDestinationSelected: (index) {
                ref.read(_navigationIndexProvider.notifier).setIndex(index);
              },
              extended: MediaQuery.of(context).size.width > 1200,
              minExtendedWidth: 200,
              groupAlignment: -0.9,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(LucideIcons.layout_dashboard),
                  selectedIcon: Icon(LucideIcons.layout_dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(LucideIcons.activity),
                  selectedIcon: Icon(LucideIcons.activity),
                  label: Text('Monitoring'),
                ),
                NavigationRailDestination(
                  icon: Icon(LucideIcons.history),
                  selectedIcon: Icon(LucideIcons.history),
                  label: Text('History'),
                ),
                NavigationRailDestination(
                  icon: Icon(LucideIcons.user),
                  selectedIcon: Icon(LucideIcons.user),
                  label: Text('My Page'),
                ),
              ],
            ),
          if (isDesktop)
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: Theme.of(context).dividerColor,
            ),

          Expanded(child: pages[navIndex]),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: navIndex,
              onDestinationSelected: (index) {
                ref.read(_navigationIndexProvider.notifier).setIndex(index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(LucideIcons.layout_dashboard),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(LucideIcons.activity),
                  label: 'Monitoring',
                ),
                NavigationDestination(
                  icon: Icon(LucideIcons.history),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(LucideIcons.user),
                  label: 'My Page',
                ),
              ],
            ),
    );
  }
}
