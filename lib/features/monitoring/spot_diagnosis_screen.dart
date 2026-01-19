import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'widgets/health_gauge.dart';
import 'widgets/oscilloscope_chart.dart';
import 'widgets/spectrum_chart.dart';
import '../../core/components/app_card.dart';
import '../../core/components/app_button.dart';
import '../../core/components/app_text.dart';
import '../../theme/app_theme.dart';
import 'providers/monitoring_providers.dart';
import '../../data/models/diagnosis_log.dart';
import '../history/providers/history_providers.dart';
import '../../core/components/app_notification.dart';
import '../diagnosis/services/diagnosis_engine.dart';
import '../diagnosis/services/diagnosis_service.dart';
import '../maintenance/ui/repair_shop_list_screen.dart';
import '../../data/models/asset.dart';
import '../../data/repositories/asset_repository.dart';
import '../../core/utils/signal_processing.dart';

enum DiagnosisPhase { idle, measuring, analyzing, completed }

class SpotDiagnosisScreen extends ConsumerStatefulWidget {
  const SpotDiagnosisScreen({super.key});

  @override
  ConsumerState<SpotDiagnosisScreen> createState() =>
      _SpotDiagnosisScreenState();
}

class _SpotDiagnosisScreenState extends ConsumerState<SpotDiagnosisScreen>
    with SingleTickerProviderStateMixin {
  DiagnosisPhase _phase = DiagnosisPhase.idle;
  int _countdown = 10;
  double? _lastScore;
  Map<String, dynamic>? _lastMetrics;
  String? _prescriptionTitle;
  String? _prescriptionDesc;
  String? _statusMessage;
  Asset? _selectedAsset; // Contextual Diagnosis

  // Tab controller for the 3 modes
  late TabController _tabController;
  final List<double> _liveBuffer = [];
  List<double> _timeData = [];
  List<double> _freqData = [];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startDiagnosis() async {
    if (_selectedAsset == null) {
      showAppNotification(
        context,
        'Please select a target equipment first',
        type: NotificationType.warning,
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      showAppNotification(
        context,
        'Authentication required.',
        type: NotificationType.error,
      );
      return;
    }

    setState(() {
      _phase = DiagnosisPhase.measuring;
      _countdown = 10;
      _lastScore = null;
      _lastMetrics = null;
      _prescriptionTitle = null;
      _prescriptionDesc = null;
      _statusMessage = 'Collecting sensor data...';
    });

    // Run 10s Timer strictly for "Collection" phase
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            timer.cancel();
            _startAIAnalysis(user.id);
          }
        });
      }
    });
  }

  Future<void> _startAIAnalysis(String userId) async {
    debugPrint('--- _startAIAnalysis Called ---');
    setState(() {
      _phase = DiagnosisPhase.analyzing;
      _statusMessage = 'AI Model Analyzing...';
    });

    try {
      // 1. Trigger Backend Diagnosis AFTER 10s collection
      final service = DiagnosisService();
      final success = await service.triggerDiagnosis(userId);

      if (!success) {
        throw 'AI Server Connection Failed. Check if server is running at http://localhost:8000';
      }

      // 2. Fetch Results on Success
      await _fetchDiagnosisResults();
    } catch (e) {
      debugPrint('Diagnosis Error: $e');
      if (mounted) {
        setState(() {
          _phase = DiagnosisPhase.idle;
          _statusMessage = 'Error: $e';
        });
        showAppNotification(
          context,
          'Diagnosis Error: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _fetchDiagnosisResults() async {
    debugPrint('--- _fetchDiagnosisResults Called ---');
    if (!mounted) return;

    setState(() {
      _statusMessage = 'Retrieving results...';
    });

    try {
      debugPrint('Fetching data from Supabase...');
      // Fetch latest data from Supabase
      // Add a small delay to ensure DB write is committed if latency is high
      await Future.delayed(const Duration(milliseconds: 500));

      final response = await Supabase.instance.client
          .from('ai_feature_vectors')
          .select()
          .order('id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        throw 'No analysis data found. Please ensure data ingestion is running.';
      }
      debugPrint(
        'Data fetched: ${response['id']} (timestamp: ${response['created_at']})',
      );
      debugPrint('Available keys: ${response.keys.toList()}');
      debugPrint(
        'Raw FFT Magnitude Type: ${response['fft_magnitude'].runtimeType}',
      );
      debugPrint(
        'Raw FFT Magnitude Preview: ${response['fft_magnitude'].toString().substring(0, min(100, response['fft_magnitude'].toString().length))}...',
      );

      // Safe Parsing Helper
      List<double> parseList(dynamic input) {
        if (input == null) return [];
        try {
          if (input is List) {
            return input.map((e) => (e as num).toDouble()).toList();
          }
          if (input is String) {
            // Try Standard JSON
            try {
              final decoded = jsonDecode(input);
              if (decoded is List) {
                return decoded.map((e) => (e as num).toDouble()).toList();
              }
            } catch (_) {
              // Ignore JSON error and try manual parsing
            }

            // Fallback: Manual Parsing for "{1,2,3}" (Postgres) or "[1 2 3]" (Numpy)
            String cleaned = input.replaceAll(RegExp(r'[\[\]\{\}]'), '');
            // Split by comma or multiple spaces
            final parts = cleaned.split(RegExp(r'[,\s]+'));

            return parts
                .where((s) => s.trim().isNotEmpty)
                .map((s) => double.tryParse(s.trim()))
                .whereType<double>()
                .toList();
          }
        } catch (e) {
          debugPrint('Error parsing list: $e');
        }
        return [];
      }

      final rawData = parseList(response['raw_data']);
      List<double> fftData = parseList(response['fft_magnitude']);

      // [Fallback] Calculate FFT locally if backend data is missing
      if (fftData.isEmpty && rawData.isNotEmpty) {
        debugPrint(
          'FFT Data missing (null/empty). Calculating locally using fftea...',
        );
        try {
          // 1. DC Removal (Zero-Centering) - Match Backend Spec
          double mean = 0.0;
          if (rawData.isNotEmpty) {
            mean = rawData.reduce((a, b) => a + b) / rawData.length;
          }
          final zeroCentered = rawData.map((e) => e - mean).toList();

          // 2. Apply Window (Hann)
          // 2. Apply Window (Hann)
          // Manual Hann Window implementation locally to avoid library dependency
          final windowedData = List<double>.filled(zeroCentered.length, 0.0);
          for (int i = 0; i < zeroCentered.length; i++) {
            // Hann Window: 0.5 * (1 - cos(2*pi*n / (N-1)))
            final mult =
                0.5 * (1 - cos(2 * pi * i / (zeroCentered.length - 1)));
            windowedData[i] = zeroCentered[i] * mult;
          }

          // 2. Perform Custom FFT (Web Compatible, Zero-Padding)
          // Pad to next power of 2 for Radix-2 FFT
          final n = windowedData.length;
          final p = (log(n) / log(2)).ceil();
          final paddedSize = pow(2, p).toInt();

          final paddedData = List<double>.filled(paddedSize, 0.0);
          for (int i = 0; i < n; i++) {
            paddedData[i] = windowedData[i];
          }

          final spectrum = SignalProcessor.computeFFT(paddedData);

          // 3. Extract Magnitude
          // Just take the first half (0 to Nyquist)
          // Resolution change: Fs / paddedSize ~ 0.3Hz
          fftData = spectrum.sublist(0, paddedSize ~/ 2);

          // 4. Normalize (Relative Amplitude)
          final maxMag = fftData.isEmpty ? 0.0 : fftData.reduce(max);
          if (maxMag > 0) {
            fftData = fftData.map((e) => e / maxMag).toList();
          }
          debugPrint(
            'Local FFT Success (Custom). Generated ${fftData.length} bins.',
          );
        } catch (e, stack) {
          debugPrint('Local FFT Failed: $e\n$stack');
        }
      }

      debugPrint(
        'Resulting FFT Data Size: ${fftData.length}, First 5: ${fftData.take(5).toList()}',
      );

      final dbScore = (response['anomaly_score'] as num?)?.toDouble() ?? 0.0;
      final dbStatus = response['status'] as String? ?? 'Normal';

      // Calculate Metrics Locally (since backend doesn't provide them)
      double calcRms = 0.0;
      double calcPeak = 0.0;
      double calcFreq = 0.0;

      if (rawData.isNotEmpty) {
        final sumSquare = rawData.fold(0.0, (sum, val) => sum + (val * val));
        calcRms = sqrt(sumSquare / rawData.length);
        calcPeak = rawData.fold(0.0, (prev, val) => max(prev, val.abs()));
      }

      if (fftData.isNotEmpty) {
        // Find index of max magnitude
        int maxIdx = 0;
        double maxVal = 0.0;
        for (int i = 0; i < fftData.length; i++) {
          if (fftData[i] > maxVal) {
            maxVal = fftData[i];
            maxIdx = i;
          }
        }
        // Rough approximation: Index * Scale (Assuming ~50Hz per bin for now or just index)
        calcFreq = maxIdx * 10.0;
      }

      // Generate Prescription Locally
      String pTitle = 'Optimal Operation';
      String pDesc = 'Equipment is running within normal parameters.';

      if (dbStatus == 'Danger') {
        pTitle = 'Critical Failure Detected';
        pDesc =
            'High probability of bearing fault. Immediate inspection required.';
      } else if (dbStatus == 'Caution') {
        pTitle = 'Maintenance Specifics';
        pDesc = 'Early signs of wear detected. Schedule maintenance soon.';
      }

      debugPrint('Parsed Score: $dbScore, Status: $dbStatus');

      if (mounted) {
        setState(() {
          _timeData = rawData;
          _freqData = fftData;

          _lastScore = ((1.0 - dbScore) * 100).clamp(
            0.0,
            100.0,
          ); // Convert Anomaly (0-1) to Health (100-0)
          _statusMessage = 'Diagnosis Complete: $dbStatus';

          _lastMetrics = {'rms': calcRms, 'peak': calcPeak, 'freq': calcFreq};

          _prescriptionTitle = pTitle;
          _prescriptionDesc = pDesc;

          _phase = DiagnosisPhase.completed;
        });

        // Switch to results tab
        _tabController.animateTo(0);

        // Save to Supabase (Async)
        await _saveLog(
          ((1.0 - dbScore) * 100).clamp(0.0, 100.0),
          dbStatus,
          calcRms,
          calcPeak,
          calcFreq,
        );

        if (dbStatus == 'Danger') {
          _showDangerDialog();
        }
      }
    } catch (e) {
      debugPrint('Error fetching diagnosis data: $e');
      if (mounted) {
        setState(() {
          _statusMessage = 'Analysis Failed: $e'; // Show error in UI
          _phase = DiagnosisPhase.idle;
        });

        showAppNotification(
          context,
          'Analysis Failed: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  Future<void> _saveLog(
    double score,
    String status,
    double rms,
    double peak,
    double freq,
  ) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('User not logged in, cannot save log');
        return;
      }

      debugPrint('Current User ID: ${user.id}');

      final log = DiagnosisLog(
        id: 0, // Generated by DB
        userId: user.id,
        equipmentId: _selectedAsset?.id, // Contextual Linkage
        score: score,
        status: status,
        metrics: {
          'rms': rms,
          'peak': peak,
          'freq': freq,
          'record_duration_sec': 10,
        },
        prescription: {
          'title': _prescriptionTitle,
          'description': _prescriptionDesc,
        },
        createdAt: DateTime.now(),
      );

      final repo = ref.read(diagnosisRepositoryProvider);
      await repo.createLog(log);

      // Refresh History UI
      ref.invalidate(diagnosisHistoryProvider);
    } catch (e) {
      debugPrint('Error saving log: $e');
      if (mounted) {
        showAppNotification(
          context,
          'Failed to save diagnosis: $e',
          type: NotificationType.error,
        );
      }
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
            ),
            const SizedBox(height: 8),
            AppText(_prescriptionTitle ?? 'Unknown Issue'),
            const SizedBox(height: 4),
            AppText(
              _prescriptionDesc ?? 'Immediate inspection recommended.',
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the real-time stream properly
    ref.listen(sensorDataStreamProvider, (prev, next) {
      next.whenData((chunk) {
        if (chunk.isNotEmpty) {
          setState(() {
            if (_liveBuffer.length > 2048) {
              _liveBuffer.removeRange(0, chunk.length);
            }
            _liveBuffer.addAll(chunk);
          });
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const AppText(
          'Spot Diagnosis',
          size: AppTextSize.xl,
          weight: FontWeight.bold,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          // Demo Mode Toggle
          Consumer(
            builder: (context, ref, _) {
              final isDemo = ref.watch(isDemoModeProvider);
              return Row(
                children: [
                  AppText(
                    'Demo',
                    size: AppTextSize.xs,
                    color: isDemo ? Colors.green : Colors.grey,
                  ),
                  Switch(
                    value: isDemo,
                    onChanged: (val) =>
                        ref.read(isDemoModeProvider.notifier).set(val),
                    activeThumbColor: Colors.green,
                  ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Diagnosis'),
            Tab(text: 'Time-Domain'),
            Tab(text: 'Frequency'),
          ],
        ),
      ),
      backgroundColor: const Color(0xFF0F172A),
      body: TabBarView(
        controller: _tabController,
        physics:
            const NeverScrollableScrollPhysics(), // Prevent swipe to avoid conflict with chart gestures
        children: [
          // TAB 1: Diagnosis Result (Legacy + Enhanced)
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPhaseController(),
                const SizedBox(height: 24),
                if (_phase == DiagnosisPhase.completed) _buildResultSection(),
              ],
            ),
          ),

          // TAB 2: Time Domain (Oscilloscope)
          _buildChartTab(
            title: 'Real-time Oscilloscope',
            child: (_timeData.isNotEmpty || _liveBuffer.isNotEmpty)
                ? OscilloscopeChart(
                    data: _timeData.isNotEmpty ? _timeData : _liveBuffer,
                  )
                : const Center(
                    child: Text(
                      'Waiting for data...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
          ),

          // TAB 3: Frequency Domain (Spectrum)
          _buildChartTab(
            title: 'Frequency Spectrum (FFT)',
            child: (_freqData.isNotEmpty || _liveBuffer.isNotEmpty)
                ? SpectrumChart(
                    data: _freqData.isNotEmpty ? _freqData : _liveBuffer,
                    samplingRate: 1000,
                  )
                : const Center(
                    child: Text(
                      'Waiting for data...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseController() {
    return Column(
      children: [
        SizedBox(height: 220, child: Center(child: _buildMainDisplay(context))),
        const SizedBox(height: 32),
        _buildAssetSelector(), // Dropdown added here
        const SizedBox(height: 24),
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

        if (_statusMessage != null && _phase != DiagnosisPhase.completed) ...[
          const SizedBox(height: 16),
          AppText(
            _statusMessage!,
            isMuted: true,
            color: _phase == DiagnosisPhase.analyzing
                ? AppTheme.accentNeonBlue
                : null,
          ),
        ],
      ],
    );
  }

  Widget _buildAssetSelector() {
    // Only show selector if idle to prevent changing during diagnosis
    if (_phase != DiagnosisPhase.idle && _phase != DiagnosisPhase.completed) {
      if (_selectedAsset != null) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.box, size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              AppText('Target: ${_selectedAsset!.name}', isMuted: true),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }

    final assetsAsync = ref.watch(assetListProvider);

    return assetsAsync.when(
      data: (assets) {
        if (assets.isEmpty) {
          return const AppText(
            'No registered equipment found. Please register asset first.',
            color: AppTheme.statusAmber,
            size: AppTextSize.sm,
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedAsset == null
                  ? AppTheme.accentNeonBlue
                  : Colors.white24,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Asset>(
              value: _selectedAsset,
              hint: const AppText('Select Target Equipment', isMuted: true),
              dropdownColor: AppTheme.surfaceDark,
              isExpanded: true,
              style: const TextStyle(color: Colors.white),
              items: assets.map((asset) {
                return DropdownMenuItem<Asset>(
                  value: asset,
                  child: Row(
                    children: [
                      Icon(
                        asset.type == 'Pump'
                            ? LucideIcons.droplets
                            : LucideIcons.fan, // Simplified icons
                        size: 16,
                        color: AppTheme.accentNeonBlue,
                      ),
                      const SizedBox(width: 12),
                      Text(asset.name),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedAsset = val);
              },
            ),
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (e, _) => AppText(
        'Error loading assets',
        color: AppTheme.statusRed,
        size: AppTextSize.xs,
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

  Widget _buildResultSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'RMS',
                value: '${(_lastMetrics?['rms'] ?? 0).toStringAsFixed(2)} g',
                icon: LucideIcons.activity,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                label: 'Peak',
                value: '${(_lastMetrics?['peak'] ?? 0).toStringAsFixed(2)} g',
                icon: Icons.bar_chart,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                label: 'Freq',
                value: '${(_lastMetrics?['freq'] ?? 0).toStringAsFixed(0)} Hz',
                icon: LucideIcons.zap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _PrescriptionCard(
          title: _prescriptionTitle ?? 'Analysis Result',
          description: _prescriptionDesc ?? 'No specific action required.',
          score: _lastScore ?? 0,
        ),
        const SizedBox(height: 24),
        if (_lastScore != null && _lastScore! < 80)
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Find Trusted Repair Shop',
              variant: AppButtonVariant.primary,
              icon: const Icon(LucideIcons.wrench),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RepairShopListScreen(
                      diagnosisContext: _prescriptionTitle,
                      initialQuery: '', // Show all shops by default
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildChartTab({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                const SizedBox(width: 4),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
    );
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
          AppText(label, size: AppTextSize.xs, isMuted: true),
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
    Color color = score < 40
        ? AppTheme.statusRed
        : (score < 80 ? AppTheme.statusAmber : AppTheme.statusGreen);
    IconData icon = score < 40
        ? Icons.warning_amber_rounded
        : (score < 80 ? Icons.error_outline : Icons.check_circle_outline);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  'AI Prescription',
                  color: color,
                  size: AppTextSize.xs,
                  weight: FontWeight.bold,
                ),
                const SizedBox(height: 4),
                AppText(
                  description,
                  color: Colors.white70,
                  size: AppTextSize.sm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
