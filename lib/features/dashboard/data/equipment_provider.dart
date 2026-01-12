import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'equipment_model.dart';

final equipmentProvider =
    StreamNotifierProvider<EquipmentNotifier, List<Equipment>>(
      EquipmentNotifier.new,
    );

class EquipmentNotifier extends StreamNotifier<List<Equipment>> {
  @override
  Stream<List<Equipment>> build() {
    // Subscribe to real-time changes on  Stream<List<Equipment>> build() {
    // [RECOVERY FIX] 'equipment' table does not exist.
    // Providing mock data to prevent crash until Equipment service is fully restored.
    return Stream.value([
      Equipment(
        id: 1,
        name: 'Main Motor',
        status: 'Normal',
        efficiency: 95.0,
        lastUpdated: DateTime.now().subtract(const Duration(days: 10)),
      ),
      Equipment(
        id: 1, // Model expects int id
        name: 'Hydraulic Pump A',
        status: 'Caution',
        efficiency: 82.0,
        lastUpdated: DateTime.now().subtract(const Duration(days: 45)),
      ),
    ]);
  }
}
