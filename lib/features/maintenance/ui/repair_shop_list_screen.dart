import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:ai_poc_monitoring_app/core/components/app_text.dart';

import 'package:ai_poc_monitoring_app/theme/app_theme.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/data/repair_repository.dart';
import 'package:ai_poc_monitoring_app/features/maintenance/models/repair_shop.dart';
import 'widgets/repair_shop_card.dart';
import 'widgets/repair_shop_detail_sheet.dart';

// Create a FutureProvider for fetching shops
final repairShopsProvider = FutureProvider<List<RepairShop>>((ref) async {
  final repository = ref.watch(repairRepositoryProvider);
  return repository.fetchRepairShops();
});

class RepairShopListScreen extends ConsumerStatefulWidget {
  final String? initialQuery; // Pre-filled search text (filtering)
  final String?
  diagnosisContext; // Context for weighting (ranking), e.g., "Inner race spalling"

  const RepairShopListScreen({
    super.key,
    this.initialQuery,
    this.diagnosisContext,
  });

  @override
  ConsumerState<RepairShopListScreen> createState() =>
      _RepairShopListScreenState();
}

class _RepairShopListScreenState extends ConsumerState<RepairShopListScreen> {
  String _selectedSort = 'Distance'; // Best Match, Distance, Rating
  bool _isPremiumOnly = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchQuery = widget.initialQuery!;
    }
    // If we have diagnosis context, default to Best Match to show recommended shops first.
    if (widget.diagnosisContext != null &&
        widget.diagnosisContext!.isNotEmpty) {
      _selectedSort = 'Best Match';
    } else if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _selectedSort = 'Best Match';
    }
  }

  // Keyword mapping for strict relevance
  final Map<String, List<String>> _keywordMap = {
    'bearing': ['bearing', 'spalling', 'inner race', 'outer race', 'ball pass'],
    'alignment': ['alignment', 'misalignment', 'coupling', 'shaft'],
    'unbalance': ['unbalance', 'balance', 'vibration'],
    'motor': ['motor', 'winding', 'stator', 'rotor'],
  };

  double _calculateScore(RepairShop shop) {
    double score = 0;

    // 1. Diagnosis Context Matching (Highest Priority: +500)
    if (widget.diagnosisContext != null &&
        widget.diagnosisContext!.isNotEmpty) {
      final contextLower = widget.diagnosisContext!.toLowerCase();

      for (var entry in _keywordMap.entries) {
        // If diagnosis contains any keyword from values (e.g. 'spalling')
        bool contextMatches = entry.value.any((k) => contextLower.contains(k));

        if (contextMatches) {
          // Check if shop has the key tag (e.g. 'Bearing')
          // We check if any shop specialization contains the key.
          bool shopHasTag = shop.specializations.any(
            (s) => s.toLowerCase().contains(entry.key),
          );

          if (shopHasTag) {
            score += 500; // Massive boost to override distance
          }
        }
      }
    }

    // 2. Search Query Matching (+50)
    // Only if using search bar text
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      if (shop.specializations.any(
        (t) => t.toLowerCase().contains(queryLower),
      )) {
        score += 50;
      }
      if (shop.name.toLowerCase().contains(queryLower)) {
        score += 20;
      }
    }

    // 3. Premium Quality
    if (shop.isPremium) score += 10;

    // 4. Rating
    score += (shop.rating * 5);

    // 5. Distance Penalty
    score -= shop.distanceKm;

    return score;
  }

  String? _getMatchReason(RepairShop shop) {
    if (widget.diagnosisContext == null || widget.diagnosisContext!.isEmpty) {
      return null;
    }

    final contextLower = widget.diagnosisContext!.toLowerCase();
    for (var entry in _keywordMap.entries) {
      if (entry.value.any((k) => contextLower.contains(k))) {
        if (shop.specializations.any(
          (s) => s.toLowerCase().contains(entry.key),
        )) {
          // Capitalize first letter
          final tag = entry.key[0].toUpperCase() + entry.key.substring(1);
          return 'Best Match For: $tag';
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(repairShopsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const AppText(
          'Find Repair Service',
          size: AppTextSize.lg,
          weight: FontWeight.bold,
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          // Filters & Search
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search by specialty (e.g., Bearings)',
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  controller: TextEditingController(text: _searchQuery)
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: _searchQuery.length),
                    ),
                  onChanged: (v) {
                    _searchQuery = v;
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip('Best Match', LucideIcons.sparkles),
                      const SizedBox(width: 8),
                      _buildSortChip('Distance', LucideIcons.map_pin),
                      const SizedBox(width: 8),
                      // ... rest of chips
                      _buildSortChip('Rating', Icons.star),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Premium Only'),
                        selected: _isPremiumOnly,
                        onSelected: (val) =>
                            setState(() => _isPremiumOnly = val),
                        backgroundColor: AppTheme.surfaceDark,
                        selectedColor: AppTheme.accentNeonBlue.withValues(
                          alpha: 0.2,
                        ),
                        checkmarkColor: AppTheme.accentNeonBlue,
                        labelStyle: TextStyle(
                          color: _isPremiumOnly
                              ? AppTheme.accentNeonBlue
                              : Colors.white60,
                        ),
                        side: BorderSide(
                          color: _isPremiumOnly
                              ? AppTheme.accentNeonBlue
                              : Colors.white10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: shopsAsync.when(
              data: (shops) {
                // Filter & Sort Logic
                var filtered = shops.where((s) {
                  final queryLower = _searchQuery.toLowerCase();
                  // Strict filtering ONLY determines visibility if user typed something.
                  // If diagnosisContext is active but search query is empty, allow all (recommending top).

                  final matchesQuery =
                      _searchQuery.isEmpty ||
                      s.name.toLowerCase().contains(queryLower) ||
                      s.specializations.any(
                        (tag) => tag.toLowerCase().contains(queryLower),
                      );
                  final matchesPremium = !_isPremiumOnly || s.isPremium;
                  return matchesQuery && matchesPremium;
                }).toList();

                // Sort
                if (_selectedSort == 'Best Match') {
                  filtered.sort(
                    (a, b) => _calculateScore(b).compareTo(_calculateScore(a)),
                  );
                } else if (_selectedSort == 'Rating') {
                  filtered.sort((a, b) => b.rating.compareTo(a.rating));
                } else {
                  filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
                }

                if (filtered.isEmpty) {
                  return const Center(
                    child: AppText('No repair shops found.', isMuted: true),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final shop = filtered[index];
                    // Recommendation Logic
                    final reason = _getMatchReason(shop);
                    // Only show badge if it's a high score match (reason not null) AND it's top of list?
                    // Or show for all matches? User asked for 1st place badge.
                    // Let's show for top.
                    final isTop = index == 0;
                    final showBadge =
                        isTop &&
                        reason != null &&
                        _selectedSort == 'Best Match';

                    return RepairShopCard(
                      shop: shop,
                      matchReason: showBadge
                          ? reason
                          : null, // Pass string instead of bool
                      onTap: () {
                        _showShopDetails(context, shop);
                      },
                    );
                  },
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
    );
  }

  Widget _buildSortChip(String label, IconData icon) {
    final isSelected = _selectedSort == label;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.white : Colors.white60,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedSort = label);
      },
      selectedColor: AppTheme.accentNeonBlue,
      backgroundColor: AppTheme.surfaceDark,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white60),
      side: BorderSide(
        color: isSelected ? AppTheme.accentNeonBlue : Colors.white10,
      ),
    );
  }

  void _showShopDetails(BuildContext context, RepairShop shop) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors
          .transparent, // Transparent to show rounded corners of the sheet
      isScrollControlled: true,
      builder: (context) => RepairShopDetailSheet(shop: shop),
    );
  }
}
