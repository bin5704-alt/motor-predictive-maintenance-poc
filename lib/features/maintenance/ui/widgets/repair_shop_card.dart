import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:ai_poc_monitoring_app/core/components/app_card.dart';
import 'package:ai_poc_monitoring_app/core/components/app_text.dart';
import 'package:ai_poc_monitoring_app/theme/app_theme.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/models/repair_shop.dart';

class RepairShopCard extends StatelessWidget {
  final RepairShop shop;
  final VoidCallback onTap;
  final String? matchReason;

  const RepairShopCard({
    super.key,
    required this.shop,
    required this.onTap,
    this.matchReason,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      withBorder: matchReason != null,
      // If recommended, we want a custom border.
      // But AppCard takes `withBorder`.
      // Let's wrap AppCard or customize it?
      // AppCard doesn't support custom border color easily via param (it uses theme divider).
      // I'll stick to inner decoration or just use the badge for now.
      // Actually, let's use the Badge.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image & Badge Area
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  border: matchReason != null
                      ? Border.all(color: AppTheme.accentNeonBlue, width: 2)
                      : null, // Highlight border on image area? No, card needs border.
                  // Let's just put the Badge.
                  image: DecorationImage(
                    image: NetworkImage(shop.imageUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.4),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
              if (matchReason != null)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.statusGreen,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.sparkles,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        AppText(
                          matchReason!,
                          size: AppTextSize.xs,
                          weight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              if (shop.isPremium)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accentNeonBlue,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentNeonBlue.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          LucideIcons.shield_check,
                          size: 14,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        AppText(
                          'Premium Partner',
                          size: AppTextSize.xs,
                          weight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                bottom: 12,
                left: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      shop.name,
                      size: AppTextSize.lg,
                      weight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.map_pin,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        AppText(
                          '${shop.location} • ${shop.distanceKm}km away',
                          size: AppTextSize.sm,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Details Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating Row
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppTheme.statusAmber,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    AppText(shop.rating.toString(), weight: FontWeight.bold),
                    const SizedBox(width: 4),
                    AppText(
                      '(${shop.reviewCount} reviews)',
                      isMuted: true,
                      size: AppTextSize.sm,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: shop.specializations.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: AppText(
                        tag,
                        size: AppTextSize.xs,
                        color: Colors.white70,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                // Equipment List (Mini)
                if (shop.equipment.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.wrench,
                        size: 14,
                        color: AppTheme.accentNeonBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppText(
                          'Equipped: ${shop.equipment.join(", ")}',
                          size: AppTextSize.xs,
                          color: Colors.white60,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
