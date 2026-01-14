import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/diagnosis_log.dart';
import '../models/maintenance_log.dart';
import 'package:flutter/foundation.dart';

class DiagnosisRepository {
  final SupabaseClient _client;

  DiagnosisRepository(this._client);

  // --- Diagnosis Logs ---

  Future<List<DiagnosisLog>> fetchHistory() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('fetchHistory: User ID is null');
        return [];
      }

      final response = await _client
          .from('diagnosis_logs')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => DiagnosisLog.fromJson(e)).toList();
    } catch (e) {
      debugPrint('fetchHistory Error: $e');
      rethrow; // Pass to Provider to handle error state
    }
  }

  Future<DiagnosisLog?> createLog(DiagnosisLog log) async {
    debugPrint('Starting createLog...');
    debugPrint('Log Data to Insert: ${log.toJson()}');

    try {
      final response = await _client
          .from('diagnosis_logs')
          .insert(log.toJson())
          .select()
          .single();

      debugPrint('Insert Success. Response: $response');
      return DiagnosisLog.fromJson(response);
    } catch (e) {
      debugPrint('Insert Failed. Error: $e');
      rethrow;
    }
  }

  Future<void> deleteLog(int id) async {
    await _client.from('diagnosis_logs').delete().eq('id', id);
  }

  // --- Maintenance Logs ---

  Future<List<MaintenanceLog>> fetchMaintenanceLogs(int diagnosisId) async {
    final response = await _client
        .from('maintenance_logs')
        .select()
        .eq('diagnosis_id', diagnosisId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => MaintenanceLog.fromJson(e)).toList();
  }

  Future<MaintenanceLog> createMaintenanceLog(MaintenanceLog log) async {
    final response = await _client
        .from('maintenance_logs')
        .insert(log.toJson())
        .select()
        .single();

    return MaintenanceLog.fromJson(response);
  }

  Future<void> updateMaintenanceLog(
    int id,
    Map<String, dynamic> updates,
  ) async {
    await _client.from('maintenance_logs').update(updates).eq('id', id);
  }

  // --- Raw Data Linkage ---

  Future<dynamic> fetchRawDataSample(int rawDataId) async {
    final response = await _client
        .from('raw_sensor_data')
        .select('samples, sampling_rate')
        .eq('id', rawDataId)
        .single();

    return response;
  }
}
