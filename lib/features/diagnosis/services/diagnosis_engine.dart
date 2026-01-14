import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Provider ---
// --- Provider ---
class IsDemoModeNotifier extends Notifier<bool> {
  @override
  bool build() => true; // Default to Demo Mode

  void set(bool value) => state = value;
}

final isDemoModeProvider = NotifierProvider<IsDemoModeNotifier, bool>(
  IsDemoModeNotifier.new,
);

final diagnosisEngineProvider = Provider<DiagnosisEngine>((ref) {
  final isDemo = ref.watch(isDemoModeProvider);
  return isDemo ? MockDiagnosisEngine() : SpectralDiagnosisEngine();
});

// --- Models ---
class DiagnosisResult {
  final double score;
  final String status;
  final String prescriptionTitle;
  final String prescriptionDesc;
  final Map<String, dynamic> metrics; // rms, peak, freq

  DiagnosisResult({
    required this.score,
    required this.status,
    required this.prescriptionTitle,
    required this.prescriptionDesc,
    required this.metrics,
  });
}

// --- Interface ---
abstract class DiagnosisEngine {
  Future<DiagnosisResult> analyze(List<double> data, {int samplingRate = 1000});
}

// --- Mock Implementation (Demo Scenarios) ---
class MockDiagnosisEngine implements DiagnosisEngine {
  @override
  Future<DiagnosisResult> analyze(
    List<double> data, {
    int samplingRate = 1000,
  }) async {
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    final random = Random();
    final scenario = random.nextDouble();

    if (scenario < 0.2) {
      // Danger: Bearing Fault
      return DiagnosisResult(
        score: 35.0,
        status: 'Danger',
        prescriptionTitle: 'Critical Bearing Fault',
        prescriptionDesc:
            'High frequency harmonics detected at 4x RPM. Inner race spalling likely. Immediate replacement required.',
        metrics: {'rms': 2.8, 'peak': 5.2, 'freq': 120.0},
      );
    } else if (scenario < 0.4) {
      // Danger: Misalignment
      return DiagnosisResult(
        score: 42.0,
        status: 'Danger',
        prescriptionTitle: 'Severe Misalignment',
        prescriptionDesc:
            'strong 2x line frequency peak. Coupling inspection and laser alignment needed.',
        metrics: {'rms': 2.1, 'peak': 4.5, 'freq': 60.0},
      );
    } else if (scenario < 0.7) {
      // Caution: Lubrication
      return DiagnosisResult(
        score: 65.0,
        status: 'Caution',
        prescriptionTitle: 'Lubrication Deficit',
        prescriptionDesc:
            'Elevated friction floor. Grease replenishing recommended within 48h.',
        metrics: {'rms': 1.2, 'peak': 2.5, 'freq': 850.0},
      );
    } else {
      // Normal
      return DiagnosisResult(
        score: 92.0,
        status: 'Normal',
        prescriptionTitle: 'Optimal Operation',
        prescriptionDesc:
            'All vibration parameters within ISO 10816 Class I zone A.',
        metrics: {'rms': 0.4, 'peak': 0.9, 'freq': 60.0},
      );
    }
  }
}

// --- Real Implementation (Placeholder) ---
class SpectralDiagnosisEngine implements DiagnosisEngine {
  @override
  Future<DiagnosisResult> analyze(
    List<double> data, {
    int samplingRate = 1000,
  }) async {
    // TODO: Implement actual FFT and Harmonic logic here
    await Future.delayed(const Duration(seconds: 1));

    // Fallback for now since no sensor
    return DiagnosisResult(
      score: 88.0,
      status: 'Normal',
      prescriptionTitle: 'Real-time Analysis (Beta)',
      prescriptionDesc:
          'Signal analysis module active. Waiting for sensor stream.',
      metrics: {'rms': 0.0, 'peak': 0.0, 'freq': 0.0},
    );
  }
}
