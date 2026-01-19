import 'dart:math';

class SignalProcessor {
  /// Custom FFT Implementation (Radix-2 Recursive)
  /// Input: Real-valued signal (must be padded to power of 2)
  /// Output: Magnitude spectrum
  static List<double> computeFFT(List<double> input) {
    // 1. Convert to Complex (Interleaved Real, Imag)
    final complex = List<double>.filled(input.length * 2, 0.0);
    for (int i = 0; i < input.length; i++) {
      complex[2 * i] = input[i]; // Real
      complex[2 * i + 1] = 0.0; // Imag
    }

    // 2. Perform FFT
    _fft(complex);

    // 3. Compute Magnitudes
    final magnitudes = <double>[];
    for (int i = 0; i < input.length; i++) {
      final re = complex[2 * i];
      final im = complex[2 * i + 1];
      magnitudes.add(sqrt(re * re + im * im));
    }
    return magnitudes;
  }

  static void _fft(List<double> buffer) {
    final n = buffer.length ~/ 2;
    if (n <= 1) return;

    final half = n ~/ 2;
    final even = List<double>.filled(half * 2, 0.0);
    final odd = List<double>.filled(half * 2, 0.0);

    for (int i = 0; i < half; i++) {
      // Even
      even[2 * i] = buffer[4 * i];
      even[2 * i + 1] = buffer[4 * i + 1];
      // Odd
      odd[2 * i] = buffer[4 * i + 2];
      odd[2 * i + 1] = buffer[4 * i + 3];
    }

    _fft(even);
    _fft(odd);

    for (int k = 0; k < half; k++) {
      final double tRe = cos(-2 * pi * k / n);
      final double tIm = sin(-2 * pi * k / n);

      final double oddRe = odd[2 * k];
      final double oddIm = odd[2 * k + 1];

      // Complex Multiply: T * Odd
      final double expRe = tRe * oddRe - tIm * oddIm;
      final double expIm = tRe * oddIm + tIm * oddRe;

      final double evenRe = even[2 * k];
      final double evenIm = even[2 * k + 1];

      // Buffer[k] = Even[k] + T*Odd[k]
      buffer[2 * k] = evenRe + expRe;
      buffer[2 * k + 1] = evenIm + expIm;

      // Buffer[k + n/2] = Even[k] - T*Odd[k]
      buffer[2 * (k + half)] = evenRe - expRe;
      buffer[2 * (k + half) + 1] = evenIm - expIm;
    }
  }
}
