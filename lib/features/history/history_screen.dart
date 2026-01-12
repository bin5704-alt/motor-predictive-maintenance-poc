import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/components/app_text.dart';
import '../../theme/app_theme.dart';
import '../../data/models/diagnosis_log.dart';
import 'providers/history_providers.dart';
import 'report_detail_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All'; // All, Normal, Caution, Danger

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(diagnosisHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            Expanded(
              child: historyAsync.when(
                data: (logs) {
                  final filteredLogs = logs.where((log) {
                    final matchesSearch =
                        log.id.toString().contains(_searchQuery) ||
                        (log.status).toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        );
                    final matchesFilter =
                        _statusFilter == 'All' || log.status == _statusFilter;
                    return matchesSearch && matchesFilter;
                  }).toList();

                  if (filteredLogs.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async =>
                          ref.refresh(diagnosisHistoryProvider),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 100),
                          Center(
                            child: AppText('No history found.', isMuted: true),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.refresh(diagnosisHistoryProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        return _HistoryCard(log: filteredLogs[index]);
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: AppText('Error: $err', color: AppTheme.statusRed),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.history, color: AppTheme.accentNeonBlue, size: 28),
          const SizedBox(width: 12),
          const AppText(
            'Diagnosis History',
            size: AppTextSize.xl,
            weight: FontWeight.bold,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => ref.refresh(diagnosisHistoryProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search ID or Status...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.white38),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(height: 12),
          // Status Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'Normal', 'Caution', 'Danger'].map((status) {
                final isSelected = _statusFilter == status;
                Color chipColor;
                if (status == 'Normal')
                  chipColor = AppTheme.statusGreen;
                else if (status == 'Caution')
                  chipColor = AppTheme.statusAmber;
                else if (status == 'Danger')
                  chipColor = AppTheme.statusRed;
                else
                  chipColor = AppTheme.accentNeonBlue;

                return GestureDetector(
                  onTap: () => setState(() => _statusFilter = status),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? chipColor.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? chipColor : Colors.white12,
                        width: 1,
                      ),
                    ),
                    child: AppText(
                      status,
                      color: isSelected ? chipColor : Colors.white54,
                      size: AppTextSize.sm,
                      weight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final DiagnosisLog log;

  const _HistoryCard({required this.log});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    switch (log.status) {
      case 'Normal':
        statusColor = AppTheme.statusGreen;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'Caution':
        statusColor = AppTheme.statusAmber;
        statusIcon = Icons.warning_amber_rounded;
        break;
      case 'Danger':
        statusColor = AppTheme.statusRed;
        statusIcon = Icons.error_outline;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReportDetailScreen(diagnosisId: log.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    'Diagnosis #${log.id}',
                    size: AppTextSize.md,
                    weight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    log.status.toUpperCase(),
                    color: statusColor,
                    size: AppTextSize.xs,
                    weight: FontWeight.bold,
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    DateFormat('yyyy-MM-dd HH:mm').format(log.createdAt),
                    color: Colors.white54,
                    size: AppTextSize.xs,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppText(
                  '${log.score.toStringAsFixed(0)}',
                  size: AppTextSize.xl,
                  weight: FontWeight.bold,
                  color: statusColor,
                ),
                const AppText('Score', size: AppTextSize.xs, isMuted: true),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
