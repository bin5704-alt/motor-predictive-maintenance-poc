import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/components/app_notification.dart';
import '../../core/components/app_text.dart';
import '../../core/components/app_card.dart';
import '../../theme/app_theme.dart';
import '../../data/models/diagnosis_log.dart';
import '../monitoring/widgets/spectrum_chart.dart';

class ComparisonScreen extends ConsumerStatefulWidget {
  final DiagnosisLog beforeLog;
  final DiagnosisLog afterLog;

  const ComparisonScreen({
    super.key,
    required this.beforeLog,
    required this.afterLog,
  });

  @override
  ConsumerState<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends ConsumerState<ComparisonScreen> {
  final GlobalKey _captureKey = GlobalKey();
  bool _isSharing = false;

  // --- SHARE FUNCTION START ---
  Future<void> _shareReport() async {
    if (_isSharing) return;

    try {
      setState(() => _isSharing = true);

      // --- HOTFIX: Safety Delay & Race Condition Prevention ---
      // 1. Wait for UI to stabilize (critical for ensuring RepaintBoundary is ready)
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // 2. Validate RepaintBoundary
      RenderRepaintBoundary? boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null || boundary.debugNeedsPaint) {
        // Retry once more if boundary is not ready
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        boundary =
            _captureKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;

        if (boundary == null) {
          throw Exception(
            "UI Render Error: Comparison screen not fully loaded.",
          );
        }
      }

      // 3. High Quality Image Capture
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) throw Exception("Image encoding failed.");

      Uint8List pngBytes = byteData.buffer.asUint8List();

      if (kIsWeb) {
        // --- WEB: Share directly from memory (File system not accessible) ---
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                pngBytes,
                mimeType: 'image/png',
                name:
                    'AntiGravity_Report_${DateTime.now().millisecondsSinceEpoch}.png',
              ),
            ],
            text: 'AntiGravity Motor Diagnosis Report',
          ),
        );
      } else {
        // --- NATIVE: Save to Temp file for better native sharing support ---
        final directory = await getTemporaryDirectory();
        final file = File(
          '${directory.path}/AntiGravity_Report_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        await file.writeAsBytes(pngBytes);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'AntiGravity Motor Diagnosis Report',
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
  // --- SHARE FUNCTION END ---

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Metrics Safely
    final beforeRMS =
        (widget.beforeLog.metrics?['rms'] as num?)?.toDouble() ?? 0.0;
    final afterRMS =
        (widget.afterLog.metrics?['rms'] as num?)?.toDouble() ?? 0.0;

    double improvementValue = 0.0;
    if (beforeRMS > 0) {
      improvementValue = ((beforeRMS - afterRMS) / beforeRMS) * 100;
    }

    // final improvement = improvementValue
    //    .clamp(-999.0, 100.0)
    //    .toStringAsFixed(1); // Clamp to avoid crazy numbers
    final isImproved = improvementValue > 0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const AppText('Diagnosis Comparison', weight: FontWeight.bold),
        backgroundColor: Colors.transparent,
        actions: [
          _isSharing
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: _shareReport,
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: RepaintBoundary(
          // Wrap content to capture entire scrollable area
          key: _captureKey,
          child: Container(
            color: AppTheme.backgroundBlack, // Capture solid background
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Top Impact Card
                AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const AppText(
                        'Vibration Reduction Impact',
                        isMuted: true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isImproved
                                ? LucideIcons.trending_down
                                : LucideIcons.trending_up,
                            color: isImproved
                                ? AppTheme.statusGreen
                                : AppTheme.statusRed,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          AppText(
                            '${improvementValue.abs().toStringAsFixed(1)}%',
                            size: AppTextSize.xxl,
                            weight: FontWeight.bold,
                            color: isImproved
                                ? AppTheme.statusGreen
                                : AppTheme.statusRed,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      AppText(
                        isImproved
                            ? 'Significant improvement in stability.'
                            : 'Vibration levels increased.',
                        size: AppTextSize.sm,
                        color: isImproved
                            ? AppTheme.statusGreen
                            : AppTheme.statusRed,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Comparison Metrics Table
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildMetricRow(
                          'RMS (Acceleration)',
                          '${beforeRMS.toStringAsFixed(2)} g',
                          '${afterRMS.toStringAsFixed(2)} g',
                          isImproved,
                        ),
                        const Divider(color: Colors.white10),
                        _buildMetricRow(
                          'Peak Amplitude',
                          '${(widget.beforeLog.metrics?['peak'] as num?)?.toStringAsFixed(2) ?? "N/A"} g',
                          '${(widget.afterLog.metrics?['peak'] as num?)?.toStringAsFixed(2) ?? "N/A"} g',
                          true,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Charts Section
                const AppText(
                  'Spectral Analysis Comparison',
                  weight: FontWeight.bold,
                ),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    border: Border.all(color: Colors.white10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Using SpectrumChart with mock data for visualization
                      // In real app, we'd fetch waveforms from Log ID
                      SpectrumChart(
                        data: List.generate(
                          1000,
                          (i) => (i % 50 == 0) ? 2.5 : 0.1,
                        ),
                        samplingRate: 1000,
                      ),
                      const Positioned(
                        top: 0,
                        right: 0,
                        child: AppText(
                          "After Repair Signal",
                          size: AppTextSize.xs,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                const Center(
                  child: AppText(
                    "Generated by AntiGravity AI",
                    isMuted: true,
                    size: AppTextSize.xs,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String before, String after, bool good) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: AppText(label, isMuted: true)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                'Before: $before',
                size: AppTextSize.xs,
                isMuted: true,
                decoration: TextDecoration.lineThrough,
              ),
              AppText(
                'After: $after',
                weight: FontWeight.bold,
                color: good ? AppTheme.statusGreen : AppTheme.statusRed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
