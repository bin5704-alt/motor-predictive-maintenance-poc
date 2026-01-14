import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/models/repair_shop.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/models/repair_status.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/data/repair_request_repository.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/models/repair_request.dart';

// Now holds a LIST of active requests
class ActiveRepairState {
  final List<RepairRequest> requests;

  const ActiveRepairState({this.requests = const []});
}

class ActiveRepairNotifier extends AsyncNotifier<ActiveRepairState> {
  @override
  Future<ActiveRepairState> build() async {
    final repo = ref.read(repairRequestRepositoryProvider);
    try {
      final requests = await repo.fetchActiveRequests();
      return ActiveRepairState(requests: requests);
    } catch (e) {
      debugPrint('ActiveRepairProvider Error: $e');
    }
    return const ActiveRepairState();
  }

  Future<void> createRequest(RepairShop shop) async {
    // Optimistic update or reload? Reload is safer for ID sync.
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

      // Refresh to get the real ID from DB
      ref.invalidateSelf();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> cancelRequest(String id) async {
    // state = const AsyncValue.loading(); // Don't block UI entirely if possible
    try {
      final repo = ref.read(repairRequestRepositoryProvider);
      await repo.deleteRequest(id);

      // Optimistic removal
      if (state.hasValue) {
        final current = state.value!.requests;
        final updated = current.where((r) => r.id != id).toList();
        state = AsyncValue.data(ActiveRepairState(requests: updated));
      } else {
        ref.invalidateSelf();
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final activeRepairProvider =
    AsyncNotifierProvider<ActiveRepairNotifier, ActiveRepairState>(() {
      return ActiveRepairNotifier();
    });
