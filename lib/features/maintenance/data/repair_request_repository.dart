import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/repair_request.dart';
import '../models/repair_status.dart';

final repairRequestRepositoryProvider = Provider((ref) {
  return RepairRequestRepository(Supabase.instance.client);
});

class RepairRequestRepository {
  final SupabaseClient _client;
  static const String _localKey = 'active_repair_request';

  RepairRequestRepository(this._client);

  /// Fetches the single active request.
  /// Tries Supabase first, falls back to Local Storage if table missing/error.
  Future<RepairRequest?> fetchActiveRequest() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint(
          'Supabase fetch skipped: No user logged in. Checking local.',
        );
        return await _fetchLocal();
      }

      final response = await _client
          .from('repair_requests')
          .select()
          .eq('user_id', userId)
          .neq('status', RepairStatus.completed.name)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        // If nothing in Supabase, we might still check local as a failsafe
        // or just return null. Usually if DB is empty, it's empty.
        // But for "Offline Fallback", if we can't reach DB, we hit catch block.
        // If we reach DB and it's null, it implies no request.
        // However, checking local might be confusing if local is stale.
        // Strategy: Trust DB if successful.
        return null;
      }

      debugPrint('Supabase fetch successful: ${response['id']}');
      return RepairRequest.fromJson(response);
    } catch (e) {
      debugPrint('Supabase fetch failed (using local fallback): $e');
      return await _fetchLocal();
    }
  }

  Future<RepairRequest?> _fetchLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_localKey);
      if (jsonString == null) return null;

      debugPrint('Restored from Local Storage.');
      return RepairRequest.fromJson(jsonDecode(jsonString));
    } catch (e) {
      debugPrint('Local fetch failed: $e');
      return null;
    }
  }

  /// Saves request.
  /// Tries Supabase, but ALWAYS saves to local as backup/primary if DB fails.
  Future<void> createRequest(RepairRequest request) async {
    // 1. Save Local (Robustness)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localKey, jsonEncode(request.toJson()));
      debugPrint('Local save successful.');
    } catch (e) {
      debugPrint('Local save failed: $e');
    }

    // 2. Try Supabase
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('Supabase save skipped: No user logged in.');
        return;
      }

      // Note: We use the existing request object. 'id' is empty, but Supabase will generate it.
      await _client.from('repair_requests').insert({
        ...request.toJson(),
        'user_id': userId,
      });
      debugPrint('Supabase insert successful.');
    } catch (e) {
      debugPrint('Supabase save failed (ignored, using local): $e');
      // Do not rethrow, as we want the app to continue using local state
    }
  }

  Future<void> deleteActiveRequest() async {
    // 1. Delete Local
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localKey);
      debugPrint('Local delete successful.');
    } catch (e) {
      debugPrint('Local delete failed: $e');
    }

    // 2. Try Supabase
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client
          .from('repair_requests')
          .delete()
          .eq('user_id', userId)
          .neq('status', RepairStatus.completed.name);

      debugPrint('Supabase delete successful.');
    } catch (e) {
      debugPrint('Supabase delete failed: $e');
    }
  }
}
