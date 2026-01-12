import 'dart:async';
import 'dart:math';

class SimulationService {
  final int samplingRate;
  final int chunkSize;
  Timer? _timer;
  final _dataController = StreamController<List<double>>.broadcast();

  Stream<List<double>> get dataStream => _dataController.stream;

  SimulationService({
    this.samplingRate = 1000, // 1000 Hz
    this.chunkSize = 100, // Emit 100 samples at a time (every 100ms)
  });

  void startSimulation() {
    stopSimulation(); // Ensure previous timer is cancelled

    double t = 0;
    final interval =
        1000000 ~/ (samplingRate / chunkSize); // Microseconds per chunk

    // Using periodic timer for simplicity, but could drift.
    // For high precision, could consider isolated loops, but this suffices for UI demo.
    _timer = Timer.periodic(Duration(microseconds: interval), (_) {
      final chunk = <double>[];
      for (int i = 0; i < chunkSize; i++) {
        // Generate comprised signal:
        // 1. Fundamental frequency 60Hz (Main motor speed)
        // 2. Harmonic 120Hz
        // 3. Random noise

        double signal =
            10.0 * sin(2 * pi * 60 * t) +
            5.0 * sin(2 * pi * 120 * t) +
            (Random().nextDouble() - 0.5) * 5.0; // Noise

        chunk.add(signal);
        t += 1.0 / samplingRate;
      }
      _dataController.add(chunk);
    });
  }

  void stopSimulation() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _timer?.cancel();
    _dataController.close();
  }
}
