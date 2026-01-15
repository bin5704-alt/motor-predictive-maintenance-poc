import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/services/data_upload_service.dart';
import '../../../data/services/simulation_service.dart';

// 1. Simulation Service Provider
final simulationServiceProvider = Provider<SimulationService>((ref) {
  final service = SimulationService(
    samplingRate: 1000,
    chunkSize: 50,
  ); // 50 samples per 50ms = 20fps updates
  ref.onDispose(() => service.dispose());
  return service;
});

// 2. Data Upload Service Provider
final dataUploadServiceProvider = Provider<DataUploadService>((ref) {
  // Assuming Supabase is initialized in main.dart
  return DataUploadService(Supabase.instance.client);
});

// 3. Real-time Data Stream Provider
final sensorDataStreamProvider = StreamProvider.autoDispose<List<double>>((
  ref,
) {
  // Listen to the 'ai_feature_vectors' table in Supabase
  // Fetching the latest record sorted by creation time
  return Supabase.instance.client
      .from('ai_feature_vectors')
      .stream(primaryKey: ['id'])
      .order('id', ascending: false)
      .limit(1)
      .map((rows) {
        debugPrint('Incoming rows: $rows'); // Debug print for incoming rows
        if (rows.isEmpty) {
          return <double>[];
        }
        final row = rows.first;
        final fftData = row['fft_magnitude'];
        if (fftData is List) {
          final data = fftData.map((e) => (e as num).toDouble()).toList();
          debugPrint(
            'FFT data length: ${data.length}',
          ); // Debug print for data length
          return data;
        }
        return <double>[];
      });
});
