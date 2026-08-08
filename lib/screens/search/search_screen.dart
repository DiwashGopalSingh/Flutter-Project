import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/donor_model.dart';
import '../../providers/donor_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../widgets/blood_group_badge.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedBloodGroup;
  bool _availableOnly = false;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DonorProvider>().loadDonors();
      context.read<InventoryProvider>().loadInventory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(text: 'Donors'),
            Tab(text: 'Blood Stock'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search + filter bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Blood group filter
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _bloodGroupFilterChip('All', null),
                      ...AppConstants.bloodGroups
                          .map((bg) => _bloodGroupFilterChip(bg, bg)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Available only toggle (donors tab)
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    return _tabController.index == 0
                        ? Row(
                            children: [
                              Switch(
                                value: _availableOnly,
                                onChanged: (val) =>
                                    setState(() => _availableOnly = val),
                                activeThumbColor: AppColors.primary,
                              ),
                              Text('Available donors only',
                                  style: AppTextStyles.bodySmall),
                            ],
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDonorsTab(),
                _buildBloodStockTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloodGroupFilterChip(String label, String? value) {
    final isSelected = _selectedBloodGroup == value;
    final color = value != null
        ? (AppColors.bloodGroupColors[value] ?? AppColors.primary)
        : AppColors.textSecondary;
    return GestureDetector(
      onTap: () => setState(() => _selectedBloodGroup = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? color : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDonorsTab() {
    return Consumer<DonorProvider>(
      builder: (context, donorProvider, _) {
        if (donorProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final donors = donorProvider.filterDonors(
          bloodGroup: _selectedBloodGroup,
          availableOnly: _availableOnly,
        );

        if (donors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_search_rounded,
                    color: AppColors.textHint, size: 56),
                const SizedBox(height: 12),
                Text('No donors found', style: AppTextStyles.bodyMedium),
                Text('Try changing your filters',
                    style: AppTextStyles.bodySmall),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: donors.length,
          itemBuilder: (context, i) => _donorCard(donors[i]),
        );
      },
    );
  }

  Widget _donorCard(DonorModel donor) {
    final color =
        AppColors.bloodGroupColors[donor.bloodGroup] ?? AppColors.primary;
    final canDonate = donor.isAvailable && donor.isEligible;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                donor.bloodGroup,
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(donor.name, style: AppTextStyles.bodyLarge),
                Text(donor.address ?? 'Location not provided',
                    style: AppTextStyles.caption,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      canDonate ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      size: 12,
                      color: canDonate ? AppColors.success : AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      canDonate ? 'Available to donate' : 'Not available',
                      style: AppTextStyles.caption.copyWith(
                        color: canDonate ? AppColors.success : AppColors.textHint,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.favorite_rounded, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('${donor.totalDonations} donations',
                        style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.phone_rounded,
                color: AppColors.primary, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBloodStockTab() {
    return Consumer<InventoryProvider>(
      builder: (context, inv, _) {
        if (inv.isLoading) return const Center(child: CircularProgressIndicator());

        final summary = _selectedBloodGroup != null
            ? {_selectedBloodGroup!: inv.stockSummary[_selectedBloodGroup] ?? 0}
            : inv.stockSummary;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: summary.entries.map((e) {
            final color = AppColors.bloodGroupColors[e.key] ?? AppColors.primary;
            final qty = e.value;
            final isLow = qty <= AppConstants.lowStockThreshold;
            final isCritical = qty <= AppConstants.criticalStockThreshold;
            Color statusColor =
                isCritical ? AppColors.error : isLow ? AppColors.warning : AppColors.success;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isCritical ? AppColors.error.withValues(alpha: 0.4) : AppColors.border,
                  width: isCritical ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  BloodGroupBadge(bloodGroup: e.key, size: 52, showLabel: false),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Blood Type ${e.key}',
                            style: AppTextStyles.headlineSmall),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isCritical
                                  ? 'Critical Stock'
                                  : isLow
                                      ? 'Low Stock'
                                      : 'Adequate Stock',
                              style: AppTextStyles.bodySmall.copyWith(color: statusColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$qty',
                          style: AppTextStyles.statNumber.copyWith(
                            fontSize: 28,
                            color: color,
                          )),
                      Text('units', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
