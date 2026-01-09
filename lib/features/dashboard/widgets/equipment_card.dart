import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../core/components/app_card.dart';
import '../../../../core/components/app_text.dart';
import '../data/equipment_model.dart';

class EquipmentCard extends StatelessWidget {
  final Equipment equipment;
  final VoidCallback? onTap;

  const EquipmentCard({super.key, required this.equipment, this.onTap});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'operational':
        return Colors.green;
      case 'maintenance':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(equipment.status);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.zap, // Or dynamic icon based on type
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        equipment.name,
                        weight: FontWeight.bold,
                        size: AppTextSize.md,
                      ),
                      AppText(
                        equipment.status,
                        color: statusColor,
                        size: AppTextSize.xs,
                        weight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText(
                      '${equipment.efficiency.toInt()}%',
                      size: AppTextSize.xl,
                      weight: FontWeight.bold,
                    ),
                    const AppText(
                      'Efficiency',
                      size: AppTextSize.xs,
                      isMuted: true,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress Bar for Efficiency
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: equipment.efficiency / 100,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
