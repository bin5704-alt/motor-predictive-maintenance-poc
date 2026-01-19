import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:ai_poc_monitoring_app/core/utils/signal_processing.dart';

void main() {
  test('Verify FFT implementation matches Python Ground Truth', () async {
    // 1. Load Input Data
    final inputJson = File('fft_golden_data.json').readAsStringSync();
    final inputData = jsonDecode(inputJson);
    final List<dynamic> rawSignalDyn = inputData['input']['raw_signal'];
    final List<double> rawSignal = rawSignalDyn
        .map((e) => (e as num).toDouble())
        .toList();

    // 2. Load Ground Truth
    final truthJson = File('fft_ground_truth_output.json').readAsStringSync();
    final truthData = jsonDecode(truthJson);
    final List<dynamic> expectedMagnitudeDyn =
        truthData['output']['fft_magnitude'];
    final List<double> expectedMagnitude = expectedMagnitudeDyn
        .map((e) => (e as num).toDouble())
        .toList();

    // 3. Perform Dart FFT (Replica of SpotDiagnosisScreen logic)

    // Step A: Mean Removal (Zero Centering)
    final double mean = rawSignal.reduce((a, b) => a + b) / rawSignal.length;
    final List<double> zeroCentered = rawSignal.map((e) => e - mean).toList();

    // Step B: Apply Window (Hann)
    // Manual Hann Calculation to match SpotDiagnosisScreen
    final windowedData = List<double>.filled(zeroCentered.length, 0.0);
    for (int i = 0; i < zeroCentered.length; i++) {
      final mult =
          0.5 * (1 - math.cos(2 * math.pi * i / (zeroCentered.length - 1)));
      windowedData[i] = zeroCentered[i] * mult;
    }

    // Step C: Pad to next power of 2
    final n = windowedData.length;
    final p = (math.log(n) / math.log(2)).ceil();
    final paddedSize = math.pow(2, p).toInt();

    final paddedData = List<double>.filled(paddedSize, 0.0);
    for (int i = 0; i < n; i++) {
      paddedData[i] = windowedData[i];
    }

    // Step D: Perform FFT using SignalProcessor
    final fullSpectrum = SignalProcessor.computeFFT(paddedData);

    // Step E: Extract Magnitude (First Half)
    final dartMagnitude = fullSpectrum.sublist(0, paddedSize ~/ 2);

    // 4. Compare
    // Since Python (rfft n/2+1) includes Nyquist and Dart (n/2) excludes it,
    // we take the common subset (first n/2 elements).
    final comparisonLength = math.min(
      dartMagnitude.length,
      expectedMagnitude.length,
    );
    final expectedTruncated = expectedMagnitude.sublist(0, comparisonLength);
    final dartTruncated = dartMagnitude.sublist(0, comparisonLength);

    // print('Comparison Length: $comparisonLength');

    // Check values with tolerance
    double maxError = 0.0;
    for (int i = 0; i < comparisonLength; i++) {
      final diff = (dartTruncated[i] - expectedTruncated[i]).abs();
      if (diff > maxError) maxError = diff;
    }
    // print('Max Absolute Error found: $maxError');

    expect(
      maxError,
      lessThan(1e-4),
      reason: "FFT values diverged significantly",
    );
  });
}
