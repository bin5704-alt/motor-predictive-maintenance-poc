import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/components/app_text.dart';
import '../../core/components/app_notification.dart'; // Import AppNotification
import '../../theme/app_theme.dart';
import '../../data/models/diagnosis_log.dart';
import 'providers/history_providers.dart';
import 'report_detail_screen.dart';
import 'comparison_screen.dart';
import 'widgets/diagnosis_history_card.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  final String? initialFilter;
  const HistoryScreen({super.key, this.initialFilter});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  // Removed local _statusFilter
  final Set<int> _selectedIds = {};
  late AnimationController _refreshController;

  @override
  void initState() {
    super.initState();
    // Filter is now managed by provider
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    _refreshController.repeat();
    try {
      ref.invalidate(diagnosisHistoryProvider);
      await ref.read(diagnosisHistoryProvider.future);
      // Ensure at least 1 second spin for UX consistency
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        showAppNotification(
          context,
          'History refreshed successfully',
          type: NotificationType.success,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint('Refresh Error: $e');
    } finally {
      _refreshController.stop();
      _refreshController.reset();
    }
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        if (_selectedIds.length < 2) {
          _selectedIds.add(id);
        } else {
          // Show top app notification instead of SnackBar
          showAppNotification(
            context,
            'Select exactly 2 items to compare',
            type: NotificationType.warning,
            duration: const Duration(seconds: 3),
          );
        }
      }
    });
  }

  void _startComparison(List<DiagnosisLog> allLogs) {
    if (_selectedIds.length != 2) return;
    final selectedLogs = allLogs
        .where((l) => _selectedIds.contains(l.id))
        .toList();
    // Sort by date: Oldest (Before) -> Newest (After)
    selectedLogs.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComparisonScreen(
          beforeLog: selectedLogs[0],
          afterLog: selectedLogs[1],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(diagnosisHistoryProvider);
    final statusFilter = ref.watch(diagnosisFilterProvider);
    final isSelectionMode = _selectedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      floatingActionButton: isSelectionMode && _selectedIds.length == 2
          ? FloatingActionButton.extended(
              onPressed: () =>
                  historyAsync.whenData((logs) => _startComparison(logs)),
              label: const Text('Compare (2)'),
              icon: const Icon(LucideIcons.git_compare),
              backgroundColor: AppTheme.accentNeonBlue,
              foregroundColor: Colors.white,
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isSelectionMode),
            _buildFilters(),
            Expanded(
              child: historyAsync.when(
                data: (logs) {
                  final filteredLogs = logs.where((log) {
                    final matchesSearch =
                        log.id.toString().contains(_searchQuery) ||
                        (log.status).toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        (log.equipmentName ?? '').toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        );
                    final matchesFilter =
                        statusFilter == 'All' ||
                        (log.status).trim().toLowerCase() ==
                            statusFilter.toLowerCase();
                    return matchesSearch && matchesFilter;
                  }).toList();

                  if (filteredLogs.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _handleRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 100),
                          Center(
                            child: AppText(
                              'No $statusFilter history found.',
                              isMuted: true,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        final isSelected = _selectedIds.contains(log.id);
                        return DiagnosisHistoryCard(
                          log: log,
                          isSelected: isSelected,
                          isSelectionMode: isSelectionMode,
                          onTap: () {
                            if (isSelectionMode) {
                              _toggleSelection(log.id);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ReportDetailScreen(diagnosisId: log.id),
                                ),
                              );
                            }
                          },
                          onLongPress: () => _toggleSelection(log.id),
                        );
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

  Widget _buildHeader(bool isSelectionMode) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            isSelectionMode ? Icons.check_circle : Icons.history,
            color: AppTheme.accentNeonBlue,
            size: 28,
          ),
          const SizedBox(width: 12),
          AppText(
            isSelectionMode ? 'Select 2 Items' : 'Diagnosis History',
            size: AppTextSize.xl,
            weight: FontWeight.bold,
          ),
          const Spacer(),
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: () => setState(() => _selectedIds.clear()),
            )
          else
            AnimatedBuilder(
              animation: _refreshController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _refreshController.value * 2 * 3.14159,
                  child: IconButton(
                    icon: const Icon(
                      LucideIcons.refresh_cw,
                      color: Colors.white70,
                    ), // Use Lucide icon
                    onPressed: _handleRefresh,
                  ),
                );
              },
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
                final statusFilter = ref.watch(diagnosisFilterProvider);
                final isSelected = statusFilter == status;
                Color chipColor;
                if (status == 'Normal') {
                  chipColor = AppTheme.statusGreen;
                } else if (status == 'Caution') {
                  chipColor = AppTheme.statusAmber;
                } else if (status == 'Danger') {
                  chipColor = AppTheme.statusRed;
                } else {
                  chipColor = AppTheme.accentNeonBlue;
                }

                return GestureDetector(
                  onTap: () => ref
                      .read(diagnosisFilterProvider.notifier)
                      .setFilter(status),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? chipColor.withValues(alpha: 0.2)
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

// Removed _HistoryCard class
