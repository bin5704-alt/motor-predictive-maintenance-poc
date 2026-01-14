import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:ai_poc_monitoring_app/core/components/app_text.dart';

import 'package:ai_poc_monitoring_app/theme/app_theme.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/models/repair_shop.dart';
import 'package:ai_poc_monitoring_app/core/components/app_notification.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/providers/active_repair_provider.dart';

class RepairShopDetailSheet extends StatelessWidget {
  final RepairShop shop;

  const RepairShopDetailSheet({super.key, required this.shop});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppTheme.backgroundBlack,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          // Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: 100,
            ), // Space for sticky button
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Image Section
                _buildHeroHeader(context),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. Info Grid
                      _buildInfoSection(),
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 24),

                      // 3. Expertise & Equipment
                      _buildExpertiseSection(),
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 24),

                      // 4. Recent Reviews (Technical)
                      _buildReviewsSection(),
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 24),

                      // 5. Estimated Cost (Critical)
                      _buildCostSection(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Close Button
          Positioned(
            top: 16,
            right: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 5. Sticky Bottom Action
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                border: const Border(top: BorderSide(color: Colors.white10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Consumer(
                  builder: (context, ref, child) {
                    final activeState = ref
                        .watch(activeRepairProvider)
                        .asData
                        ?.value;
                    final isAlreadyRequested =
                        activeState?.requests.any(
                          (r) => r.shopId == shop.id.toString(),
                        ) ??
                        false;

                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAlreadyRequested
                            ? AppTheme.surfaceDark
                            : AppTheme.accentNeonBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: isAlreadyRequested
                          ? null
                          : () {
                              // Trigger Active Repair State
                              ref
                                  .read(activeRepairProvider.notifier)
                                  .createRequest(shop);

                              Navigator.pop(context);
                              showAppNotification(
                                context,
                                'Quote request sent to ${shop.name}!',
                                type: NotificationType.success,
                              );
                            },
                      child: Text(
                        isAlreadyRequested ? 'Request Sent' : 'Request Quote',
                        style: TextStyle(
                          color: isAlreadyRequested
                              ? Colors.white38
                              : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 250,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(shop.imageUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.backgroundBlack.withValues(alpha: 0.8),
                  AppTheme.backgroundBlack,
                ],
                stops: const [0.0, 0.7, 1.0],
              ),
            ),
          ),
        ),
        // Shop Info Overlay
        Positioned(
          bottom: 0,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (shop.isPremium) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentNeonBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            LucideIcons.shield_check,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Icon(
                    Icons.star_rounded,
                    color: AppTheme.statusAmber,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  AppText(
                    '${shop.rating}',
                    weight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  AppText(
                    ' (${shop.reviewCount} reviews)',
                    isMuted: true,
                    size: AppTextSize.sm,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppText(
                shop.name,
                size: AppTextSize.xxl,
                weight: FontWeight.bold,
                color: Colors.white,
              ),
              const SizedBox(height: 24), // Spacing for gradient
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Column(
      children: [
        _buildInfoRow(
          LucideIcons.clock,
          '09:00 - 18:00 (Open Now)',
          highlight: true,
        ),
        const SizedBox(height: 16),
        _buildInfoRow(
          LucideIcons.map_pin,
          '${shop.location} (${shop.distanceKm}km away)',
        ),
        const SizedBox(height: 16),
        _buildInfoRow(LucideIcons.phone, '0507-1234-5678 (Safe Number)'),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool highlight = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: highlight ? AppTheme.statusGreen : Colors.white70,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AppText(
            text,
            size: AppTextSize.md,
            color: highlight ? Colors.white : Colors.white70,
            weight: highlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildExpertiseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          'Specialties & Equipment',
          size: AppTextSize.lg,
          weight: FontWeight.bold,
        ),
        const SizedBox(height: 16),
        // Specialization Tags
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: shop.specializations.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: AppText(tag, size: AppTextSize.sm, color: Colors.white),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Equipment List (Grid like)
        if (shop.equipment.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: shop.equipment
                  .map(
                    (eq) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.wrench,
                            size: 14,
                            color: AppTheme.accentNeonBlue,
                          ),
                          const SizedBox(width: 8),
                          AppText(
                            eq,
                            size: AppTextSize.sm,
                            color: Colors.white70,
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    if (shop.reviews.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const AppText(
              'Recent Reviews',
              size: AppTextSize.lg,
              weight: FontWeight.bold,
            ),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppTheme.statusAmber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                AppText('${shop.rating}', weight: FontWeight.bold),
                AppText(
                  ' (${shop.reviewCount})',
                  isMuted: true,
                  size: AppTextSize.sm,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...shop.reviews.map(
          (review) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.white24,
                            child: Text(
                              review.userName[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppText(review.userName, weight: FontWeight.w600),
                          if (review.role.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            AppText(
                              '| ${review.role}',
                              isMuted: true,
                              size: AppTextSize.xs,
                            ),
                          ],
                        ],
                      ),
                      AppText(review.date, isMuted: true, size: AppTextSize.xs),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < review.rating.floor()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppTheme.statusAmber,
                        size: 14, // Small stars
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  AppText(
                    review.comment,
                    size: AppTextSize.sm,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCostSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentNeonBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                LucideIcons.banknote,
                color: AppTheme.accentNeonBlue,
                size: 20,
              ),
              SizedBox(width: 8),
              AppText('Estimated Repair Cost', weight: FontWeight.bold),
            ],
          ),
          const SizedBox(height: 12),
          const AppText(
            '₩50,000 ~ ₩150,000',
            size: AppTextSize.xxl,
            weight: FontWeight.bold,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          const AppText(
            'Final cost may vary based on detailed diagnosis.',
            size: AppTextSize.xs,
            isMuted: true,
          ),
        ],
      ),
    );
  }
}
