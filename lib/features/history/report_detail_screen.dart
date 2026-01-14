import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/components/app_notification.dart';
import '../../core/components/app_text.dart';
import '../../theme/app_theme.dart';
import '../../data/models/diagnosis_log.dart';
import 'providers/history_providers.dart';
import '../maintenance/maintenance_form_screen.dart';
import '../maintenance/ui/repair_shop_list_screen.dart';
import '../monitoring/widgets/spectrum_chart.dart';

class ReportDetailScreen extends ConsumerStatefulWidget {
  final int diagnosisId;

  const ReportDetailScreen({super.key, required this.diagnosisId});

  @override
  ConsumerState<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends ConsumerState<ReportDetailScreen> {
  final GlobalKey _captureKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareReport(int id) async {
    if (_isSharing) return;

    try {
      setState(() => _isSharing = true);

      // --- SAFETY DELAY & PRE-CHECKS ---
      // 1. Wait for UI to stabilize
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // 2. Validate RepaintBoundary
      RenderRepaintBoundary? boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null || boundary.debugNeedsPaint) {
        // Retry once
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        boundary =
            _captureKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;

        if (boundary == null) {
          throw Exception("UI Render Error: Report content not fully loaded.");
        }
      }

      // 3. High Quality Image Capture
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) throw Exception("Image encoding failed.");

      Uint8List pngBytes = byteData.buffer.asUint8List();

      final fileName =
          'AntiGravity_Diagnosis_${id}_${DateTime.now().millisecondsSinceEpoch}.png';

      if (kIsWeb) {
        // --- WEB: Direct Share ---
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(pngBytes, mimeType: 'image/png', name: fileName),
            ],
            text: 'AntiGravity Diagnosis Report #$id',
          ),
        );
      } else {
        // --- NATIVE: File Save & Share ---
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(pngBytes);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'AntiGravity Diagnosis Report #$id',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Export Error: $e';
        NotificationType type = NotificationType.error;

        if (e.toString().contains('MissingPluginException')) {
          errorMessage = 'APP RESTART REQUIRED: Native dependencies updated.';
        }

        showAppNotification(
          context,
          errorMessage,
          type: type,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ideally we fetch the specific log. For now, we find it in the history list.
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
          _isSharing
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(LucideIcons.share_2, color: Colors.white70),
                  onPressed: () => _shareReport(widget.diagnosisId),
                  tooltip: 'Share Report',
                ),
        ],
      ),
      body: historyAsync.when(
        data: (logs) {
          final log = logs.firstWhere(
            (element) => element.id == widget.diagnosisId,
            orElse: () => logs.first,
          );

          return RepaintBoundary(
            key: _captureKey,
            child: Container(
              color: AppTheme.backgroundBlack, // Ensure background is captured
              child: SingleChildScrollView(
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
                    _buildMaintenanceSection(context, widget.diagnosisId, ref),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentNeonBlue,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RepairShopListScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          LucideIcons.search,
                          color: Colors.black,
                        ),
                        label: const AppText(
                          'Find Repair Shop',
                          color: Colors.black,
                          weight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 48), // Bottom padding
                    const Center(
                      child: AppText(
                        'Generated by MotorMonitor AI',
                        isMuted: true,
                        size: AppTextSize.xs,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
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
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
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
                  color: statusColor.withValues(alpha: 0.2),
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
              ), // Mock data
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
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log = logs[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
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
