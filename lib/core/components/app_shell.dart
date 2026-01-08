import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../ui/m_design_system.dart';

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

class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(_navigationIndexProvider);
    // Breakpoint standard: 800px for Tablet/Desktop split
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
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
              groupAlignment: -0.9, // Align to top
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
                  icon: Icon(LucideIcons.settings),
                  selectedIcon: Icon(LucideIcons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
          if (isDesktop)
            const VerticalDivider(
              thickness: 1,
              width: 1,
              color: AppColors.border,
            ),

          Expanded(
            child: Column(
              children: [
                // Future: TopHeader() could go here
                Expanded(child: child),
              ],
            ),
          ),
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
                  icon: Icon(LucideIcons.settings),
                  label: 'Settings',
                ),
              ],
            ),
    );
  }
}
