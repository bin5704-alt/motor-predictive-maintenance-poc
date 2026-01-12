import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/maintenance_log.dart';

class AssetService {
  final SupabaseClient _client;

  AssetService(this._client);

  Future<void> logMaintenance(MaintenanceLog log) async {
    await _client.from('maintenance_logs').insert(log.toJson());
  }

  Future<List<MaintenanceLog>> getMaintenanceHistory(int diagnosisId) async {
    final response = await _client
        .from('maintenance_logs')
        .select()
        .eq('diagnosis_id', diagnosisId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => MaintenanceLog.fromJson(e)).toList();
  }

  Future<void> updateMaintenanceLog(
    int id,
    Map<String, dynamic> updates,
  ) async {
    await _client.from('maintenance_logs').update(updates).eq('id', id);
  }
}
