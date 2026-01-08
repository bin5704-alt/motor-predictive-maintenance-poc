import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'equipment_model.dart';

final equipmentProvider =
    StreamNotifierProvider<EquipmentNotifier, List<Equipment>>(
      EquipmentNotifier.new,
    );

class EquipmentNotifier extends StreamNotifier<List<Equipment>> {
  @override
  Stream<List<Equipment>> build() {
    final supabase = Supabase.instance.client;

    // Subscribe to real-time changes on the 'equipment' table
    return supabase
        .from('equipment')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => Equipment.fromJson(json)).toList());
  }
}
