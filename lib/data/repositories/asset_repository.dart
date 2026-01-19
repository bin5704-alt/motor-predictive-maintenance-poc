import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/asset.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final assetRepositoryProvider = Provider((ref) {
  return AssetRepository(Supabase.instance.client);
});

final assetListProvider = FutureProvider<List<Asset>>((ref) async {
  final repo = ref.watch(assetRepositoryProvider);
  return repo.fetchAssets();
});

class AssetRepository {
  final SupabaseClient _client;

  AssetRepository(this._client);

  Future<List<Asset>> fetchAssets() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('fetchAssets: User ID is null');
        return [];
      }

      final response = await _client
          .from('assets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Asset.fromJson(e)).toList();
    } catch (e) {
      debugPrint('fetchAssets Error: $e');
      rethrow;
    }
  }

  Future<Asset> createAsset(Asset asset) async {
    // Note: asset.id is ignored on insert as it is auto-generated
    try {
      final response = await _client
          .from('assets')
          .insert(asset.toJson())
          .select()
          .single();

      return Asset.fromJson(response);
    } catch (e) {
      debugPrint('createAsset Error: $e');
      rethrow;
    }
  }

  Future<void> deleteAsset(int id) async {
    try {
      // 1. Cascade Delete: Remove associated diagnosis logs first
      await _client.from('diagnosis_logs').delete().eq('equipment_id', id);

      // 2. Delete the asset itself
      await _client.from('assets').delete().eq('id', id);
    } catch (e) {
      debugPrint('deleteAsset Error: $e');
      rethrow;
    }
  }

  Future<void> updateAsset(int id, Map<String, dynamic> updates) async {
    try {
      await _client.from('assets').update(updates).eq('id', id);
    } catch (e) {
      debugPrint('updateAsset Error: $e');
      rethrow;
    }
  }
}
