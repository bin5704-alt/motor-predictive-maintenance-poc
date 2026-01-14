import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/components/app_text.dart';
import '../../../theme/app_theme.dart';
import '../../../data/models/diagnosis_log.dart';

class DiagnosisHistoryCard extends StatelessWidget {
  final DiagnosisLog log;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const DiagnosisHistoryCard({
    super.key,
    required this.log,
    this.isSelected = false,
    this.isSelectionMode = false,
    required this.onTap,
    this.onLongPress,
  });

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
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentNeonBlue.withValues(alpha: 0.1)
              : AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.accentNeonBlue : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
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
                    log.equipmentName != null
                        ? '[${log.equipmentName}] #${log.localIndex ?? log.id}'
                        : 'Diagnosis #${log.id}',
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
                  log.score.toStringAsFixed(0),
                  size: AppTextSize.xl,
                  weight: FontWeight.bold,
                  color: statusColor,
                ),
                const AppText('Score', size: AppTextSize.xs, isMuted: true),
              ],
            ),
            const SizedBox(width: 8),
            if (isSelectionMode)
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? AppTheme.accentNeonBlue : Colors.white24,
                size: 24,
              )
            else
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
