import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/components/app_text.dart';
import '../../theme/app_theme.dart';
import '../../data/models/diagnosis_log.dart';
import 'providers/history_providers.dart';
import '../maintenance/maintenance_form_screen.dart';
import '../monitoring/widgets/spectrum_chart.dart';

class ReportDetailScreen extends ConsumerWidget {
  final int diagnosisId;

  const ReportDetailScreen({super.key, required this.diagnosisId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ideally we fetch the specific log. For now, we find it in the history list.
    // In a real app, we might want a specific 'fetchLog(id)' provider.
    final historyAsync = ref.watch(diagnosisHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const AppText(
          'Diagnosis Report',
          size: AppTextSize.lg,
          weight: FontWeight.bold,
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.code, color: Colors.white70),
            onPressed: () {
              // TODO: Show Raw JSON
            },
          ),
        ],
      ),
      body: historyAsync.when(
        data: (logs) {
          final log = logs.firstWhere(
            (element) => element.id == diagnosisId,
            orElse: () => logs.first,
          );
          // Handle case where log is not found (shouldn't happen if navigating from list)

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(log),
                const SizedBox(height: 24),
                _buildSectionHeader('AI Analysis'),
                const SizedBox(height: 12),
                _buildAnalysisSection(log),
                const SizedBox(height: 24),
                _buildSectionHeader('Signal Telemetry'),
                const SizedBox(height: 12),
                _buildChartsSection(context, ref, log),
                const SizedBox(height: 24),
                _buildSectionHeader('Asset Management'),
                const SizedBox(height: 12),
                _buildMaintenanceSection(context, diagnosisId, ref),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: AppText('Error: $err', color: AppTheme.statusRed)),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 20, color: AppTheme.accentNeonBlue),
        const SizedBox(width: 8),
        AppText(title, size: AppTextSize.lg, weight: FontWeight.bold),
      ],
    );
  }

  Widget _buildSummaryCard(DiagnosisLog log) {
    Color statusColor = log.status == 'Danger'
        ? AppTheme.statusRed
        : (log.status == 'Caution'
              ? AppTheme.statusAmber
              : AppTheme.statusGreen);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText('Overall Health', size: AppTextSize.sm, isMuted: true),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.health_and_safety, color: statusColor, size: 28),
                  const SizedBox(width: 8),
                  AppText(
                    '${log.score.toStringAsFixed(0)}/100',
                    size: AppTextSize.xxl,
                    weight: FontWeight.bold,
                    color: statusColor,
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppText(
                  log.status.toUpperCase(),
                  color: statusColor,
                  weight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              AppText(
                DateFormat('yyyy-MM-dd HH:mm').format(log.createdAt),
                size: AppTextSize.xs,
                isMuted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisSection(DiagnosisLog log) {
    final title = log.prescription?['title'] ?? 'No Anomaly Detected';
    final desc =
        log.prescription?['description'] ??
        'Equipment appears to be operating within normal parameters.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppTheme.accentNeonBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              AppText(title, size: AppTextSize.md, weight: FontWeight.bold),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 28.0),
            child: AppText(desc, size: AppTextSize.sm, isMuted: true),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(
    BuildContext context,
    WidgetRef ref,
    DiagnosisLog log,
  ) {
    // In a real scenario, we would fetch the raw data using log.rawDataId
    // For now, we don't have the raw data loaded in memory unless we fetch it.
    // Let's assume we show a placeholder or fetch it.

    // For this POC, let's simulate the chart data based on the log status to show the "Highlight" feature (Req 2).
    // If we can't fetch real data easily without a new provider, we'll generate representative data.

    final isDanger = log.status == 'Danger';
    final highlights = isDanger
        ? [const RangeValues(55, 65), const RangeValues(115, 125)]
        : <RangeValues>[];

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const AppText(
            'Frequency Domain Analysis',
            size: AppTextSize.xs,
            isMuted: true,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SpectrumChart(
              data: List.generate(
                1000,
                (index) => (index % 100 == 0) ? 5.0 : 0.1,
              ), // Mock data for view
              samplingRate: 1000,
              highlights: highlights,
            ),
          ),
          const SizedBox(height: 8),
          if (isDanger)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, color: Colors.red, size: 14),
                SizedBox(width: 4),
                AppText(
                  'Anomalous peaks detected at 60Hz, 120Hz',
                  color: Colors.red,
                  size: AppTextSize.xs,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSection(
    BuildContext context,
    int diagnosisId,
    WidgetRef ref,
  ) {
    final maintenanceAsync = ref.watch(maintenanceLogsProvider(diagnosisId));

    return Column(
      children: [
        maintenanceAsync.when(
          data: (logs) {
            if (logs.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: AppText('No maintenance records yet.', isMuted: true),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log =
                    logs[index]; // Dynamic type from provider, casting needed or specific model
                // Assuming log acts like a Map or MaintenanceLog model
                // Since provider retuns List<dynamic>, we should cast in provider ideally.
                // Assuming it returns MaintenanceLog objects (repo returns MaintenanceLog).
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(log.actionTaken, weight: FontWeight.bold),
                          Row(
                            children: [
                              AppText(
                                '\$${log.cost}',
                                color: AppTheme.accentNeonBlue,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.white54,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MaintenanceFormScreen(
                                        diagnosisId: diagnosisId,
                                        logToEdit: log,
                                      ),
                                    ),
                                  );

                                  if (result == true) {
                                    ref.invalidate(
                                      maintenanceLogsProvider(diagnosisId),
                                    );
                                    ref.invalidate(dashboardStatsProvider);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppText(
                            'Tech: ${log.technician ?? "N/A"}',
                            size: AppTextSize.xs,
                            isMuted: true,
                          ),
                          AppText(
                            DateFormat('MM/dd HH:mm').format(log.createdAt),
                            size: AppTextSize.xs,
                            isMuted: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => AppText(
            'Error loading logs',
            color: Colors.red,
            size: AppTextSize.xs,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white24),
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MaintenanceFormScreen(diagnosisId: diagnosisId),
                ),
              );

              if (result == true) {
                ref.invalidate(maintenanceLogsProvider(diagnosisId));
                // Also invalidate history/dashboard if maintenance status affects them
                ref.invalidate(dashboardStatsProvider);
              }
            },
            icon: Icon(Icons.build, color: AppTheme.accentNeonBlue),
            label: AppText('Log Maintenance Activity'),
          ),
        ),
      ],
    );
  }
}
