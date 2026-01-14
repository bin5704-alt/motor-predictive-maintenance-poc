import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:ai_poc_monitoring_app/core/components/app_text.dart';
import 'package:ai_poc_monitoring_app/core/components/app_card.dart';
import 'package:ai_poc_monitoring_app/theme/app_theme.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/models/repair_status.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/providers/active_repair_provider.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/ui/repair_status_detail_screen.dart';

class LiveRepairTracker extends ConsumerWidget {
  const LiveRepairTracker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeStateAsync = ref.watch(activeRepairProvider);

    return activeStateAsync.when(
      data: (activeState) {
        // If no active repair, hide widget
        if (activeState.shop == null) {
          return const SizedBox.shrink();
        }

        final shop = activeState.shop!;
        final status = activeState.status;

        return AppCard(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RepairStatusDetailScreen(),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.statusGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.statusGreen.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const AppText(
                            'Active Repair Request',
                            size: AppTextSize.xs,
                            isMuted: true,
                            weight: FontWeight.w600,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        shop.name,
                        size: AppTextSize.lg,
                        weight: FontWeight.bold,
                      ),
                    ],
                  ),
                  const Icon(LucideIcons.activity, color: AppTheme.statusGreen),
                ],
              ),

              const SizedBox(height: 20),

              // Stepper
              Row(
                children: [
                  _buildStep(
                    context,
                    RepairStatus.pending,
                    status,
                    isFirst: true,
                  ),
                  _buildConnector(context, RepairStatus.pending, status),
                  _buildStep(context, RepairStatus.quoted, status),
                  _buildConnector(context, RepairStatus.quoted, status),
                  _buildStep(context, RepairStatus.scheduled, status),
                  _buildConnector(context, RepairStatus.scheduled, status),
                  _buildStep(
                    context,
                    RepairStatus.completed,
                    status,
                    isLast: true,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Dynamic Status Message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundBlack,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.info,
                      size: 16,
                      color: AppTheme.accentNeonBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText(
                        _getStatusMessage(status, shop.name),
                        size: AppTextSize.sm,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildStep(
    BuildContext context,
    RepairStatus step,
    RepairStatus current, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isCompleted = step.index <= current.index;
    final isCurrent = step == current;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppTheme.accentNeonBlue
                  : AppTheme.surfaceDark,
              shape: BoxShape.circle,
              border: isCurrent
                  ? Border.all(color: Colors.white, width: 2)
                  : Border.all(color: Colors.white10),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: AppTheme.accentNeonBlue.withValues(alpha: 0.5),
                        blurRadius: 8,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      '${step.index + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white54,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          AppText(
            step.label,
            size: AppTextSize.xs,
            color: isCompleted ? Colors.white : Colors.white24,
            weight: isCurrent ? FontWeight.bold : FontWeight.normal,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConnector(
    BuildContext context,
    RepairStatus step,
    RepairStatus current,
  ) {
    final isCompleted = step.index < current.index;
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? AppTheme.accentNeonBlue : Colors.white10,
        margin: const EdgeInsets.only(bottom: 14), // Align with circle center
      ),
    );
  }

  String _getStatusMessage(RepairStatus status, String shopName) {
    switch (status) {
      case RepairStatus.pending:
        return 'Waiting for a quote from $shopName...';
      case RepairStatus.quoted:
        return 'Quote received! Review the estimate.';
      case RepairStatus.scheduled:
        return 'Technician scheduled to visit soon.';
      case RepairStatus.completed:
        return 'Repair completed. Verify operation.';
    }
  }
}
