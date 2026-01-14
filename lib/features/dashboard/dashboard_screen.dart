import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/history/providers/history_providers.dart';
import '../../data/models/asset.dart'; // Import Asset model
import 'data/equipment_model.dart';

import '../../core/components/app_card.dart';
import '../../core/components/app_text.dart';
import '../../core/components/app_button.dart';
import '../../features/assets/asset_form_screen.dart';

import '../../data/repositories/asset_repository.dart';
import 'widgets/equipment_card.dart';
import 'widgets/live_repair_tracker.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Phase 4: Use Asset List instead of Mock Equipment
    final assetsAsync = ref.watch(assetListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          // Phase 7: Live Repair Tracker
          const LiveRepairTracker(),
          const SizedBox(height: 24),
          assetsAsync.when(
            data: (assets) {
              // Map Assets to UI Equipment Model for compatibility
              final equipmentList = assets.map((asset) {
                return Equipment(
                  id: asset.id,
                  name: asset.name,
                  status: 'Operational', // Default for now
                  efficiency: 98.0, // Default for now
                  lastUpdated: asset.createdAt,
                );
              }).toList();

              return Column(
                children: [
                  _buildStatsGrid(context, equipmentList, ref),
                  const SizedBox(height: 24),
                  _buildMainSection(context, assets), // Pass assets directly
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              'Equipment Overview',
              size: AppTextSize.xl,
              weight: FontWeight.w600,
            ),
            AppText(
              'Real-time monitoring status (Supabase Connected)',
              isMuted: true,
            ),
          ],
        ),
        AppButton(
          label: 'Export Report',
          variant: AppButtonVariant.outline,
          icon: const Icon(LucideIcons.download, size: 16),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    List<Equipment> items,
    WidgetRef ref,
  ) {
    // Watch real-time stats from diagnosis history
    final statsAsync = ref.watch(dashboardStatsProvider);

    final isMobile = MediaQuery.of(context).size.width < 600;

    // Default values if loading or error
    var total = items.length;
    var operational = items.where((e) => e.status == 'Operational').length;
    var maintenance = items.where((e) => e.status == 'Maintenance').length;
    var critical = items.where((e) => e.status == 'Critical').length;
    var uptime = '0';

    // Override with real stats if available
    if (statsAsync.hasValue) {
      final stats = statsAsync.value!;
      operational = stats['operational'] ?? 0;
      maintenance = stats['maintenance'] ?? 0;
      critical = stats['critical'] ?? 0;

      final totalLogs = stats['total'] ?? 0;
      if (totalLogs > 0) {
        uptime = ((operational / totalLogs) * 100).toStringAsFixed(0);
      }
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children:
          [
                _buildStatCard(
                  'Total Units',
                  '$total',
                  'Registered Assets',
                  LucideIcons.server,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Operational',
                  '$operational',
                  'Normal Status Logs',
                  LucideIcons.activity,
                  Colors.green,
                  onTap: () => _navigateToHistory(ref, 'Normal'),
                ),
                _buildStatCard(
                  'Maintenance',
                  '$maintenance',
                  'Caution / Maint. Logs',
                  LucideIcons.wrench,
                  Colors.orange,
                  onTap: () => _navigateToHistory(ref, 'Caution'),
                ),
                _buildStatCard(
                  'Critical',
                  '$critical',
                  'Danger Status Logs',
                  LucideIcons.triangle_alert,
                  Colors.red,
                  onTap: () => _navigateToHistory(ref, 'Danger'),
                ),
                _buildStatCard(
                  'Uptime',
                  '$uptime%',
                  'Operational Efficiency',
                  LucideIcons.timer,
                  Colors.blue,
                ),
              ]
              .map(
                (widget) => SizedBox(
                  width: isMobile ? double.infinity : 280,
                  child: widget,
                ),
              )
              .toList(),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtext,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Padding moved inside InkWell
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(title, isMuted: true, size: AppTextSize.sm),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppText(value, size: AppTextSize.xxl, weight: FontWeight.bold),
              const SizedBox(height: 4),
              AppText(subtext, size: AppTextSize.xs, color: color),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToHistory(WidgetRef ref, String filter) {
    // 1. Set the filter
    ref.read(diagnosisFilterProvider.notifier).setFilter(filter);

    // 2. Switch to History Tab (Index 2)
    ref.read(appNavigationProvider.notifier).setIndex(2);
  }

  Widget _buildMainSection(BuildContext context, List<Asset> assets) {
    // Changed to List<Asset>
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppText(
              'Registered Equipment',
              size: AppTextSize.lg,
              weight: FontWeight.w600,
            ),
            AppButton(
              label: 'Add New',
              variant: AppButtonVariant.ghost,
              icon: const Icon(LucideIcons.plus, size: 16),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AssetFormScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (assets.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Column(
                children: [
                  const Icon(LucideIcons.box, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  AppText('No equipment registered', isMuted: true),
                ],
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 1200
                  ? 3
                  : (MediaQuery.of(context).size.width > 800 ? 2 : 1),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.8,
            ),
            itemCount: assets.length,
            itemBuilder: (context, index) {
              final asset = assets[index];
              // Map to Equipment for UI
              final equipment = Equipment(
                id: asset.id,
                name: asset.name,
                status: 'Operational', // Default
                efficiency: 98.0, // Default
                lastUpdated: asset.createdAt,
              );

              return EquipmentCard(
                equipment: equipment,
                onTap: () {
                  // Navigate to Edit Screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AssetFormScreen(asset: asset),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
