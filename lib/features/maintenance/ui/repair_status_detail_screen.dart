import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:ai_poc_monitoring_app/theme/app_theme.dart';
import 'package:ai_poc_monitoring_app/core/components/app_text.dart';
import 'package:ai_poc_monitoring_app/core/components/app_card.dart';
import 'package:ai_poc_monitoring_app/core/components/app_button.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/providers/active_repair_provider.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/models/repair_status.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/models/repair_request.dart';

class RepairStatusDetailScreen extends ConsumerWidget {
  final RepairRequest request;

  const RepairStatusDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Repair Request Status'),
        backgroundColor: AppTheme.backgroundBlack,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Summary Card
            AppCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(request.shopImageUrl),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          request.shopName,
                          size: AppTextSize.lg,
                          weight: FontWeight.bold,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.phone,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            const AppText(
                              '0507-1234-5678', // Placeholder
                              size: AppTextSize.sm,
                              isMuted: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.phone_call,
                      color: AppTheme.statusGreen,
                    ),
                    onPressed: () {
                      // Call functionality placeholder
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const AppText(
              'Status Timeline',
              size: AppTextSize.xl,
              weight: FontWeight.bold,
            ),
            const SizedBox(height: 16),

            // Vertical Timeline
            _buildTimelineItem(
              context,
              RepairStatus.pending,
              request.status,
              title: 'Request Received',
              time: '10:30 AM',
              desc: 'Request sent to shop.',
              isFirst: true,
            ),
            _buildTimelineItem(
              context,
              RepairStatus.quoted,
              request.status,
              title: 'Quote Sent',
              time: '11:15 AM',
              desc: 'Est. Cost: ₩80,000\nVisit Fee: Included',
            ),
            _buildTimelineItem(
              context,
              RepairStatus.scheduled,
              request.status,
              title: 'Technician Scheduled',
              time: 'Pending',
              desc: 'Visit scheduled for 14:00 Today',
            ),
            _buildTimelineItem(
              context,
              RepairStatus.completed,
              request.status,
              title: 'Work Completed',
              time: '-',
              desc: 'Repair finished & verified.',
              isLast: true,
            ),

            const SizedBox(height: 48),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: AppButton(
                label: 'Cancel Request',
                variant: AppButtonVariant.outline,
                icon: const Icon(
                  LucideIcons.trash_2,
                  size: 18,
                  color: AppTheme.statusRed,
                ),
                textColor: AppTheme.statusRed,
                borderColor: AppTheme.statusRed,
                onPressed: () => _showCancelDialog(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    RepairStatus step,
    RepairStatus current, {
    required String title,
    required String time,
    required String desc,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isCompleted = step.index <= current.index;
    final color = isCompleted ? AppTheme.accentNeonBlue : Colors.white24;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Line & Dot
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(child: Container(width: 2, color: color)),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.accentNeonBlue
                        : AppTheme.backgroundBlack,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? AppTheme.accentNeonBlue
                          : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: isCompleted && step.index < current.index
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted && step.index < current.index
                          ? AppTheme.accentNeonBlue
                          : Colors.white24,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        title,
                        weight: FontWeight.bold,
                        color: isCompleted ? Colors.white : Colors.white54,
                      ),
                      AppText(time, size: AppTextSize.xs, isMuted: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    desc,
                    size: AppTextSize.sm,
                    color: isCompleted ? Colors.white70 : Colors.white24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const AppText(
          'Cancel Request?',
          size: AppTextSize.lg,
          weight: FontWeight.bold,
        ),
        content: const AppText(
          'Are you sure you want to cancel this repair request? This action cannot be undone.',
          color: Colors.white70,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const AppText('Keep Request'),
          ),
          TextButton(
            onPressed: () {
              ref.read(activeRepairProvider.notifier).cancelRequest(request.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close detail screen
            },
            child: const AppText(
              'Yes, Cancel',
              color: AppTheme.statusRed,
              weight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
