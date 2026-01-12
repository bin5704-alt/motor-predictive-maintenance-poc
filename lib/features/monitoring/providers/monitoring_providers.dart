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
  final simulationService = ref.watch(simulationServiceProvider);
  final uploadService = ref.watch(dataUploadServiceProvider);

  simulationService.startSimulation();

  // Intercept stream to feed into upload service
  return simulationService.dataStream.map((data) {
    uploadService.addData(data, simulationService.samplingRate);
    return data;
  });
});
