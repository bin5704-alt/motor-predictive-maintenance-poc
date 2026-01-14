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

  /// Fetches all active requests.
  Future<List<RepairRequest>> fetchActiveRequests() async {
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
          .neq('status', RepairStatus.completed.name);

      if ((response as List).isEmpty) {
        return [];
      }

      debugPrint('Supabase fetch successful: ${response.length} items');
      return (response).map((e) => RepairRequest.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Supabase fetch failed (using local fallback): $e');
      return await _fetchLocal();
    }
  }

  Future<List<RepairRequest>> _fetchLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_localKey);
      if (jsonString == null) return [];

      // Handle legacy single object vs new list
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return decoded.map((e) => RepairRequest.fromJson(e)).toList();
      } else {
        // Legacy single object
        return [RepairRequest.fromJson(decoded)];
      }
    } catch (e) {
      debugPrint('Local fetch failed: $e');
      return [];
    }
  }

  /// Saves request.
  Future<void> createRequest(RepairRequest request) async {
    // 1. Save Local (Robustness) - Append to list
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await _fetchLocal();
      currentList.add(request);
      // Clean duplicates if needed, but for now simple append
      await prefs.setString(
        _localKey,
        jsonEncode(currentList.map((e) => e.toJson()).toList()),
      );
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

      await _client.from('repair_requests').insert({
        ...request.toJson(),
        'user_id': userId,
      });
      debugPrint('Supabase insert successful.');
    } catch (e) {
      debugPrint('Supabase save failed (ignored, using local): $e');
    }
  }

  Future<void> deleteRequest(String id) async {
    // 1. Delete Local
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await _fetchLocal();
      currentList.removeWhere(
        (r) => r.id == id,
      ); // ID might be empty for local-only?
      // If ID comes from DB it's fine. If local-only, we might need logic.
      // For now assume ID matches.
      await prefs.setString(
        _localKey,
        jsonEncode(currentList.map((e) => e.toJson()).toList()),
      );
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
          .eq('id', id) // Delete strictly by ID
          .eq('user_id', userId);

      debugPrint('Supabase delete successful.');
    } catch (e) {
      debugPrint('Supabase delete failed: $e');
    }
  }
}
