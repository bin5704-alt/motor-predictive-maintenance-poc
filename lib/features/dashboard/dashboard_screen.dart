import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/equipment_provider.dart';
import 'data/equipment_model.dart';
import '../../core/components/app_card.dart';
import '../../core/components/app_text.dart';
import '../../core/components/app_button.dart';
import '../equipment/add_equipment_screen.dart';
import 'widgets/equipment_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentAsync = ref.watch(equipmentProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          equipmentAsync.when(
            data: (equipmentList) => _buildStatsGrid(context, equipmentList),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
          const SizedBox(height: 24),
          _buildMainSection(context, equipmentAsync.asData?.value ?? []),
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

  Widget _buildStatsGrid(BuildContext context, List<Equipment> items) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final total = items.length;
    final operational = items.where((e) => e.status == 'Operational').length;
    final maintenance = items.where((e) => e.status == 'Maintenance').length;
    final critical = items.where((e) => e.status == 'Critical').length;

    // Calculate uptime percentage (mock calculation based on operational count)
    final uptime = total > 0
        ? ((operational / total) * 100).toStringAsFixed(0)
        : '0';

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children:
          [
                _buildStatCard(
                  'Total Units',
                  '$total',
                  'All systems active',
                  LucideIcons.server,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Operational',
                  '$operational',
                  '$uptime% uptime',
                  LucideIcons.activity,
                  Colors.green,
                ),
                _buildStatCard(
                  'Maintenance',
                  '$maintenance',
                  'Scheduled checkup',
                  LucideIcons.wrench,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Critical',
                  '$critical',
                  'Action required',
                  LucideIcons.triangle_alert,
                  Colors.red,
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
    Color color,
  ) {
    return AppCard(
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
    );
  }

  Widget _buildMainSection(BuildContext context, List<Equipment> items) {
    // Show only active alerts (Critical status)
    final criticalItems = items.where((e) => e.status == 'Critical').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Registered Equipment Section
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
                    builder: (context) => const AddEquipmentScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
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
              childAspectRatio: 1.8, // Adjust based on card content
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return EquipmentCard(
                equipment: items[index],
                onTap: () {
                  // Navigate to details
                },
              );
            },
          ),

        const SizedBox(height: 32),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: AppCard(
                height: 400,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      'Efficiency Trends',
                      size: AppTextSize.lg,
                      weight: FontWeight.w600,
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Center(
                        child: AppText(
                          'Chart Placeholder (ApexCharts/FlChart)',
                          isMuted: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (MediaQuery.of(context).size.width > 900) ...[
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: AppCard(
                  height: 400,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText(
                        'Recent Alerts',
                        size: AppTextSize.lg,
                        weight: FontWeight.w600,
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: criticalItems.isEmpty
                            ? Center(
                                child: AppText(
                                  'No critical alerts',
                                  isMuted: true,
                                ),
                              )
                            : ListView.separated(
                                itemCount: criticalItems.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 24),
                                itemBuilder: (context, index) {
                                  final item = criticalItems[index];
                                  return Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            AppText(
                                              '${item.name} status is ${item.status}',
                                              size: AppTextSize.sm,
                                              weight: FontWeight.w500,
                                            ),
                                            AppText(
                                              'Efficiency: ${item.efficiency}%',
                                              size: AppTextSize.xs,
                                              isMuted: true,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
