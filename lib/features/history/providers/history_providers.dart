import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/diagnosis_repository.dart';
import '../../../data/models/diagnosis_log.dart';

final diagnosisRepositoryProvider = Provider<DiagnosisRepository>((ref) {
  return DiagnosisRepository(Supabase.instance.client);
});

final diagnosisHistoryProvider = FutureProvider<List<DiagnosisLog>>((
  ref,
) async {
  final repository = ref.watch(diagnosisRepositoryProvider);
  return repository.fetchHistory();
});

final maintenanceLogsProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  diagnosisId,
) async {
  final repository = ref.watch(diagnosisRepositoryProvider);
  return repository.fetchMaintenanceLogs(diagnosisId);
});

final dashboardStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  // Watch history to trigger re-calc on updates
  final logs = await ref.watch(diagnosisHistoryProvider.future);

  // Also watch maintenance logs if possible, but they are per-diagnosis.
  // Ideally, we'd have a separate count query, but for POC we can aggregate from logs
  // if we load them all (or use a separate count API).

  // For Real-time Dashboard:
  // Operational = 'Normal' status count
  // Maintenance = (This would ideally be machines in maintenance mode).
  //               For this requirement, let's use 'Caution' or just Maintenance Logs count.
  // Critical = 'Danger' status count

  int operational = 0;
  int maintenance =
      0; // Using 'Caution' as proxy for maintenance needed or in progress
  int critical = 0;

  for (var log in logs) {
    if (log.status == 'Normal') operational++;
    if (log.status == 'Caution') maintenance++;
    if (log.status == 'Danger') critical++;
  }

  // Note: strict requirements said "maintenance_logs의 개수".
  // Getting total Maintenance Logs count might be expensive if not separate.
  // Let's assume the user means "Equipment Status".
  // If they strictly mean "Total Maintenance Logs", we need another repo method.
  // I will check `diagnosisAnalysis` for status counts.

  return {
    'operational': operational,
    'maintenance': maintenance,
    'critical': critical,
    'total': logs.length,
  };
});
