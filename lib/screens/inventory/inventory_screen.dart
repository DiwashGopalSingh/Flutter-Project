import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/inventory_provider.dart';
import '../../models/blood_unit_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _filterGroup;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadInventory();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Inventory'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          tabs: const [
            Tab(text: 'Stock Overview'),
            Tab(text: 'All Units'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
            onPressed: () => _showAddUnitSheet(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStockOverview(context),
          _buildAllUnits(context),
        ],
      ),
    );
  }

  Widget _buildStockOverview(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inv, _) {
        if (inv.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final summary = inv.stockSummary;
        final expiring = inv.expiringUnits;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Available', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                          Text('${inv.totalUnits} Units', style: AppTextStyles.displaySmall.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                    const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 40),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (expiring.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${expiring.length} unit${expiring.length > 1 ? 's' : ''} expiring within 7 days',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Text('Stock by Blood Group', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 14),
              ...summary.entries.map((e) {
                final color = AppColors.bloodGroupColors[e.key] ?? AppColors.primary;
                const maxQty = 20;
                final percentage = e.value > 0 ? (e.value / maxQty).clamp(0.0, 1.0) : 0.0;
                final isLow = e.value <= AppConstants.lowStockThreshold;
                final isCritical = e.value <= AppConstants.criticalStockThreshold;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCritical
                          ? AppColors.error.withValues(alpha: 0.4)
                          : isLow
                              ? AppColors.warning.withValues(alpha: 0.3)
                              : AppColors.border,
                      width: isCritical ? 1.5 : 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(e.key,
                                  style: AppTextStyles.labelMedium
                                      .copyWith(color: color, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${e.value} units available',
                                        style: AppTextStyles.bodySmall),
                                    if (isCritical)
                                      Text('CRITICAL',
                                          style: AppTextStyles.caption.copyWith(
                                              color: AppColors.error,
                                              fontWeight: FontWeight.bold))
                                    else if (isLow)
                                      Text('LOW',
                                          style: AppTextStyles.caption.copyWith(
                                              color: AppColors.warning,
                                              fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percentage.toDouble(),
                                    backgroundColor: color.withValues(alpha: 0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isCritical ? AppColors.error : isLow ? AppColors.warning : color,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllUnits(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inv, _) {
        if (inv.isLoading) return const Center(child: CircularProgressIndicator());

        final units = _filterGroup != null
            ? inv.filterByBloodGroup(_filterGroup!)
            : inv.units;

        return Column(
          children: [
            // Filter chips
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _filterChip('All', null),
                  ...AppConstants.bloodGroups.map((bg) => _filterChip(bg, bg)),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: units.length,
                itemBuilder: (context, i) => _unitCard(context, units[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _filterChip(String label, String? value) {
    final isSelected = _filterGroup == value;
    return GestureDetector(
      onTap: () => setState(() => _filterGroup = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _unitCard(BuildContext context, BloodUnitModel unit) {
    final color = AppColors.bloodGroupColors[unit.bloodGroup] ?? AppColors.primary;
    Color statusColor;
    if (unit.isExpired) {
      statusColor = AppColors.error;
    } else if (unit.isExpiringSoon) {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.success;
    }

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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(unit.bloodGroup,
                  style: AppTextStyles.labelMedium
                      .copyWith(color: color, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${unit.quantity} units · ${unit.location}',
                    style: AppTextStyles.bodySmall),
                Text('Donor: ${unit.donorName}', style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit.isExpired
                          ? 'Expired'
                          : unit.isExpiringSoon
                              ? 'Expires in ${unit.daysUntilExpiry}d'
                              : 'Expires in ${unit.daysUntilExpiry}d',
                      style: AppTextStyles.caption.copyWith(color: statusColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.surface,
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textHint, size: 18),
            onSelected: (val) {
              if (val == 'delete') {
                context.read<InventoryProvider>().deleteUnit(unit.id);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddUnitSheet(BuildContext context) {
    final quantityCtrl = TextEditingController();
    final donorNameCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Main Blood Bank');
    String? selectedGroup;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Blood Unit', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 20),
                Text('Blood Group', style: AppTextStyles.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppConstants.bloodGroups.map((bg) {
                    final color = AppColors.bloodGroupColors[bg] ?? AppColors.primary;
                    final isSelected = selectedGroup == bg;
                    return GestureDetector(
                      onTap: () => setModalState(() => selectedGroup = bg),
                      child: Container(
                        width: 52,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected ? color : color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color.withValues(alpha: 0.5)),
                        ),
                        child: Center(
                          child: Text(bg,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: isSelected ? Colors.white : color,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Quantity (units)',
                  hint: 'e.g., 5',
                  controller: quantityCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.format_list_numbered_rounded,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Donor Name',
                  hint: 'Donor full name',
                  controller: donorNameCtrl,
                  prefixIcon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Location',
                  controller: locationCtrl,
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 20),
                CustomButton(
                  label: 'Add Unit',
                  icon: Icons.add_rounded,
                  onPressed: () {
                    if (selectedGroup == null || quantityCtrl.text.isEmpty) return;
                    final now = DateTime.now();
                    context.read<InventoryProvider>().addUnit(BloodUnitModel(
                      id: '',
                      bloodGroup: selectedGroup!,
                      quantity: int.tryParse(quantityCtrl.text) ?? 1,
                      collectionDate: now,
                      expiryDate: now.add(const Duration(days: AppConstants.bloodShelfLifeDays)),
                      status: AppConstants.unitAvailable,
                      donorId: 'manual',
                      donorName: donorNameCtrl.text.isNotEmpty ? donorNameCtrl.text : 'Unknown',
                      location: locationCtrl.text,
                    ));
                    Navigator.pop(ctx);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
