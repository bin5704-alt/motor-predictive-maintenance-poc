import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/health_gauge.dart';
import '../../core/components/app_card.dart';
import '../../core/components/app_button.dart';
import '../../core/components/app_text.dart';
import '../../theme/app_theme.dart';

enum DiagnosisPhase { idle, measuring, analyzing, completed }

class SpotDiagnosisScreen extends StatefulWidget {
  const SpotDiagnosisScreen({super.key});

  @override
  State<SpotDiagnosisScreen> createState() => _SpotDiagnosisScreenState();
}

class _SpotDiagnosisScreenState extends State<SpotDiagnosisScreen> {
  DiagnosisPhase _phase = DiagnosisPhase.idle;
  int _countdown = 10;
  double? _lastScore;
  Map<String, dynamic>? _lastMetrics;
  String? _prescriptionTitle;
  String? _prescriptionDesc;
  String? _statusMessage;

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startDiagnosis() async {
    setState(() {
      _phase = DiagnosisPhase.measuring;
      _countdown = 10;
      _lastScore = null;
      _lastMetrics = null;
      _prescriptionTitle = null;
      _prescriptionDesc = null;
      _statusMessage = 'Collecting sensor data...';
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            timer.cancel();
            _startAIAnalysis();
          }
        });
      }
    });
  }

  void _startAIAnalysis() {
    setState(() {
      _phase = DiagnosisPhase.analyzing;
      _statusMessage = 'AI Model Analyzing...';
    });

    // Simulate 2 seconds of "Heavy" processing
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _completeDiagnosis();
      }
    });
  }

  void _completeDiagnosis() async {
    final random = Random();
    // 30% chance of 'Issue' (Caution or Danger) for demo variety
    final issueType = random.nextDouble();

    double score;
    String status;
    String pTitle;
    String pDesc;

    if (issueType < 0.15) {
      // Danger (< 40)
      score = 20 + random.nextDouble() * 20;
      status = 'Danger';
      // Dynamic Prescription Logic (Mock)
      if (random.nextBool()) {
        pTitle = 'Suspected Bearing Failure';
        pDesc =
            'High frequency vibrations detected. Inner race damage likely. Inspect immediately.';
      } else {
        pTitle = 'Severe Misalignment';
        pDesc =
            'Harmonic peaks indicate shaft misalignment. Laser calibration required.';
      }
    } else if (issueType < 0.3) {
      // Caution (40 - 80)
      score = 40 + random.nextDouble() * 35;
      status = 'Caution';
      pTitle = 'Lubrication Issue';
      pDesc =
          'Friction levels elevated. Scheduled greasing recommended within 48 hours.';
    } else {
      // Normal (80 - 100)
      score = 75 + random.nextDouble() * 25;
      status = 'Normal';
      pTitle = 'Optimal Operation';
      pDesc =
          'Equipment running within standard parameters. No action required.';
    }

    final rms = 0.5 + (random.nextDouble() * (status == 'Danger' ? 2.5 : 0.5));
    final peak = 1.0 + (random.nextDouble() * (status == 'Danger' ? 5.0 : 1.0));
    final freq = 60.0 + (random.nextDouble() * 5);

    final metrics = {'rms': rms, 'peak': peak, 'freq': freq};

    setState(() {
      _phase = DiagnosisPhase.completed;
      _lastScore = score;
      _lastMetrics = metrics;
      _prescriptionTitle = pTitle;
      _prescriptionDesc = pDesc;
      _statusMessage = 'Diagnosis Complete';
    });

    // Save to Supabase (Best effort)
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('diagnosis_logs').insert({
          'user_id': user.id,
          'score': score,
          'status': status,
          'rms_value': rms,
          'peak_value': peak,
          'frequency_hertz': freq,
          'record_duration_sec': 10,
          // 'prescription': '$pTitle: $pDesc' // If we added this column
        });
      }
    } catch (e) {
      debugPrint('Error saving log: $e');
    }

    if (status == 'Danger' && mounted) {
      _showDangerDialog();
    }
  }

  void _showDangerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.statusRed, width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.statusRed),
            SizedBox(width: 12),
            AppText(
              'CRITICAL WARNING',
              color: AppTheme.statusRed,
              weight: FontWeight.bold,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText(
              'Abnormal patterns detected!',
              weight: FontWeight.bold,
              size: AppTextSize.lg,
            ),
            const SizedBox(height: 8),
            AppText(_prescriptionTitle ?? 'Unknown Issue'),
            const SizedBox(height: 4),
            AppText(
              _prescriptionDesc ?? ' Immediate inspection recommended.',
              isMuted: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AppText('Dismiss', isMuted: true),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusRed,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppText(
              'Spot Diagnosis',
              size: AppTextSize.xl,
              weight: FontWeight.bold,
            ),
            const AppText(
              'Real-time instant equipment health check',
              isMuted: true,
            ),
            const SizedBox(height: 32),

            // Main Display Area
            Center(
              child: SizedBox(
                height: 200,
                width: 250,
                child: _buildMainDisplay(context),
              ),
            ),

            const SizedBox(height: 32),

            // Metric Cards (Only show if completed)
            if (_phase == DiagnosisPhase.completed) ...[
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'RMS',
                      value: '${_lastMetrics!['rms'].toStringAsFixed(2)} g',
                      icon: LucideIcons.activity,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      label: 'Peak',
                      value: '${_lastMetrics!['peak'].toStringAsFixed(2)} g',
                      icon: Icons.bar_chart,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      label: 'Freq',
                      value: '${_lastMetrics!['freq'].toStringAsFixed(0)} Hz',
                      icon: LucideIcons.zap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Prescription Card
              _PrescriptionCard(
                title: _prescriptionTitle ?? 'Analysis Result',
                description:
                    _prescriptionDesc ?? 'No specific action required.',
                score: _lastScore ?? 0,
              ),
              const SizedBox(height: 32),
            ],

            // Controller
            if (_phase == DiagnosisPhase.measuring ||
                _phase == DiagnosisPhase.analyzing)
              AppButton(
                label: 'Stop Diagnosis',
                variant: AppButtonVariant.outline,
                icon: const Icon(LucideIcons.square),
                onPressed: () {
                  _timer?.cancel();
                  setState(() => _phase = DiagnosisPhase.idle);
                },
              )
            else
              AppButton(
                label: _phase == DiagnosisPhase.completed
                    ? 'Start New Diagnosis'
                    : 'Start Diagnosis',
                variant: AppButtonVariant.primary,
                icon: const Icon(LucideIcons.play),
                onPressed: _startDiagnosis,
              ),

            if (_statusMessage != null &&
                _phase != DiagnosisPhase.completed) ...[
              const SizedBox(height: 16),
              Center(
                child: AppText(
                  _statusMessage!,
                  isMuted: true,
                  color: _phase == DiagnosisPhase.analyzing
                      ? AppTheme.accentNeonBlue
                      : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainDisplay(BuildContext context) {
    switch (_phase) {
      case DiagnosisPhase.measuring:
        return Stack(
          alignment: Alignment.center,
          children: [
            const SizedBox(
              width: 180,
              height: 180,
              child: CircularProgressIndicator(
                strokeWidth: 8,
                color: AppTheme.primaryBlue,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Collecting...',
                  style: TextStyle(color: AppTheme.accentNeonBlue),
                ),
              ],
            ),
          ],
        );
      case DiagnosisPhase.analyzing:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 60,
              width: 60,
              child: CircularProgressIndicator(color: AppTheme.accentNeonBlue),
            ),
            SizedBox(height: 24),
            AppText(
              'AI Analyzing...',
              size: AppTextSize.lg,
              weight: FontWeight.w600,
            ),
          ],
        );
      case DiagnosisPhase.completed:
        return HealthGauge(score: _lastScore ?? 0, animate: true);
      case DiagnosisPhase.idle:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.stethoscope,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const AppText('Ready to Start', isMuted: true),
          ],
        );
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(height: 8),
          AppText(value, size: AppTextSize.lg, weight: FontWeight.bold),
          const SizedBox(height: 4),
          AppText(label, size: AppTextSize.sm, isMuted: true),
        ],
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final String title;
  final String description;
  final double score;

  const _PrescriptionCard({
    required this.title,
    required this.description,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    if (score < 40) {
      color = AppTheme.statusRed;
      icon = Icons.warning_amber_rounded;
    } else if (score < 80) {
      color = AppTheme.statusAmber;
      icon = Icons.error_outline;
    } else {
      color = AppTheme.statusGreen;
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'AI Prescription',
                  color: color,
                  size: AppTextSize.sm,
                  weight: FontWeight.bold,
                ),
                const SizedBox(height: 4),
                AppText(title, size: AppTextSize.lg, weight: FontWeight.bold),
                const SizedBox(height: 8),
                AppText(description, isMuted: true, size: AppTextSize.md),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
