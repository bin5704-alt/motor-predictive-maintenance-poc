import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/components/app_card.dart';
import '../../core/components/app_text.dart';
import '../../core/components/app_button.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStatsGrid(context),
          const SizedBox(height: 24),
          _buildMainSection(context),
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
            AppText('Equipment Overview', size: AppTextSize.xl, weight: FontWeight.w600),
            AppText('Real-time monitoring status', isMuted: true),
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

  Widget _buildStatsGrid(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    // In a real app, use LayoutBuilder or a GridView with maxCrossAxisExtent
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard('Total Units', '124', 'All systems active', LucideIcons.server, Colors.blue),
        _buildStatCard('Operational', '118', '95% uptime', LucideIcons.activity, Colors.green),
        _buildStatCard('Maintenance', '4', 'Scheduled checkup', LucideIcons.wrench, Colors.orange),
        _buildStatCard('Critical', '2', 'Action required', LucideIcons.triangle_alert, Colors.red),
      ].map((widget) => SizedBox(
        width: isMobile ? double.infinity : 280, // Responsive width
        child: widget
      )).toList(),
    );
  }

  Widget _buildStatCard(String title, String value, String subtext, IconData icon, Color color) {
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

  Widget _buildMainSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: AppCard(
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText('Efficiency Trends', size: AppTextSize.lg, weight: FontWeight.w600),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: AppText('Chart Placeholder (ApexCharts/FlChart would go here)', isMuted: true),
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
                  const AppText('Recent Alerts', size: AppTextSize.lg, weight: FontWeight.w600),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: 5,
                      separatorBuilder: (_, _) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        return Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: index == 0 ? Colors.red : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText('Unit #${1024 + index} overheating', size: AppTextSize.sm, weight: FontWeight.w500),
                                  AppText('2 mins ago', size: AppTextSize.xs, isMuted: true),
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
    );
  }
}
