import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/models/repair_shop.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/models/repair_status.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/data/repair_request_repository.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/models/repair_request.dart';

class ActiveRepairState {
  final RepairShop? shop;
  final RepairStatus status;
  final DateTime? lastUpdated;

  const ActiveRepairState({
    this.shop,
    this.status = RepairStatus.pending,
    this.lastUpdated,
  });

  ActiveRepairState copyWith({
    RepairShop? shop,
    RepairStatus? status,
    DateTime? lastUpdated,
  }) {
    return ActiveRepairState(
      shop: shop ?? this.shop,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class ActiveRepairNotifier extends AsyncNotifier<ActiveRepairState> {
  @override
  Future<ActiveRepairState> build() async {
    // Load from Supabase (or fallback)
    final repo = ref.read(repairRequestRepositoryProvider);
    try {
      final request = await repo.fetchActiveRequest();

      if (request != null) {
        // Reconstruct shop from stored data
        final shop = RepairShop(
          id: int.tryParse(request.shopId) ?? 0,
          name: request.shopName,
          imageUrl: request.shopImageUrl,
          // Default data for UI
          location: '',
          distanceKm: 0,
          rating: 0,
          reviewCount: 0,
          specializations: [],
          equipment: [],
          reviews: [],
          isPremium: false,
        );

        return ActiveRepairState(
          shop: shop,
          status: request.status,
          lastUpdated: request.updatedAt,
        );
      }
    } catch (e) {
      // If error in provider build, we return empty state rather than crashing UI
      // But repo handles error catching mostly.
      debugPrint('ActiveRepairProvider Error: $e');
    }

    return const ActiveRepairState();
  }

  Future<void> createRequest(RepairShop shop) async {
    state = const AsyncValue.loading();

    try {
      final repo = ref.read(repairRequestRepositoryProvider);

      final newRequest = RepairRequest(
        id: '', // DB generic
        userId: '', // Repo handles this
        shopId: shop.id.toString(),
        shopName: shop.name,
        shopImageUrl: shop.imageUrl,
        status: RepairStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.createRequest(newRequest);

      state = AsyncValue.data(
        ActiveRepairState(
          shop: shop,
          status: RepairStatus.pending,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> clear() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(repairRequestRepositoryProvider);
      await repo.deleteActiveRequest();
      state = const AsyncValue.data(ActiveRepairState());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final activeRepairProvider =
    AsyncNotifierProvider<ActiveRepairNotifier, ActiveRepairState>(() {
      return ActiveRepairNotifier();
    });
