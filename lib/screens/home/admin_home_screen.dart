import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';

import '../../providers/donor_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/request_provider.dart';
import '../../widgets/request_card.dart';
import '../../widgets/stat_card.dart';
import '../inventory/inventory_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().loadInventory();
      context.read<RequestProvider>().loadAllRequests();
      context.read<DonorProvider>().loadDonors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _AdminDashboardTab(),
          _AdminRequestsTab(),
          _AdminInventoryTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_rounded), label: 'Requests'),
            BottomNavigationBarItem(
                icon: Icon(Icons.inventory_2_rounded), label: 'Inventory'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createRequest),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Request'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}

class _AdminDashboardTab extends StatelessWidget {
  const _AdminDashboardTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildStatCards(context),
            _buildBloodChart(context),
            _buildRecentRequests(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin Dashboard', style: AppTextStyles.displaySmall),
                Text('Blood Bank Overview', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(BuildContext context) {
    return Consumer3<InventoryProvider, RequestProvider, DonorProvider>(
      builder: (context, inv, req, donor, _) {
        final stats = req.stats;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Donors',
                      value: '${donor.totalDonors}',
                      icon: Icons.favorite_rounded,
                      iconColor: AppColors.primary,
                      subtitle: '${donor.availableDonors} available',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.search),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Blood Units',
                      value: '${inv.totalUnits}',
                      icon: Icons.opacity_rounded,
                      iconColor: AppColors.error,
                      subtitle: '${inv.expiringUnits.length} expiring soon',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.inventory),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Active Requests',
                      value: '${(stats['pending'] ?? 0) + (stats['processing'] ?? 0)}',
                      icon: Icons.pending_actions_rounded,
                      iconColor: AppColors.warning,
                      onTap: () => Navigator.pushNamed(context, AppRoutes.bloodRequests),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Fulfilled',
                      value: '${stats['fulfilled'] ?? 0}',
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.campaigns),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_location_alt_rounded, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Start Blood Drive Campaign',
                          style: AppTextStyles.buttonText,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBloodChart(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inv, _) {
        final summary = inv.stockSummary;
        final total = inv.totalUnits;
        if (total == 0) return const SizedBox.shrink();

        final sections = summary.entries
            .where((e) => e.value > 0)
            .map((e) {
              final color = AppColors.bloodGroupColors[e.key] ?? AppColors.primary;
              return PieChartSectionData(
                color: color,
                value: e.value.toDouble(),
                title: e.key,
                radius: 60,
                titleStyle: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            })
            .toList();

        return Container(
          margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Blood Stock Distribution', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 4),
              Text('$total total units available', style: AppTextStyles.bodySmall),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: summary.entries.map((e) {
                  final color = AppColors.bloodGroupColors[e.key] ?? AppColors.primary;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text('${e.key}: ${e.value}u', style: AppTextStyles.caption),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentRequests(BuildContext context) {
    return Consumer<RequestProvider>(
      builder: (context, req, _) {
        final recent = req.requests.take(3).toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Requests', style: AppTextStyles.headlineSmall),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.bloodRequests),
                    child: Text('View All',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primaryLight)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (recent.isEmpty)
                Center(
                  child: Text('No requests yet', style: AppTextStyles.bodyMedium),
                )
              else
                ...recent.map((req) => RequestCard(
                      request: req,
                      showActions: true,
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _AdminRequestsTab extends StatelessWidget {
  const _AdminRequestsTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Text('All Requests', style: AppTextStyles.headlineLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28),
                  tooltip: 'New Blood Request',
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.createRequest),
                ),
                const SizedBox(width: 8),
                Consumer<RequestProvider>(
                  builder: (context, req, _) {
                    final pending = req.stats['pending'] ?? 0;
                    return pending > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warningBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$pending pending',
                              style: AppTextStyles.caption.copyWith(color: AppColors.warning),
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<RequestProvider>(
              builder: (context, req, _) {
                if (req.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (req.requests.isEmpty) {
                  return Center(
                    child: Text('No requests', style: AppTextStyles.bodyMedium),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: req.requests.length,
                  itemBuilder: (context, i) {
                    final r = req.requests[i];
                    return RequestCard(
                      request: r,
                      showActions: true,
                      onTap: () => _showStatusDialog(context, r.id, r.status),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(BuildContext context, String id, String currentStatus) {
    final statuses = AppConstants.statusPending == currentStatus
        ? [AppConstants.statusProcessing, AppConstants.statusFulfilled, AppConstants.statusCancelled]
        : [AppConstants.statusFulfilled, AppConstants.statusCancelled];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update Request Status', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              ...statuses.map((s) => ListTile(
                    title: Text(s, style: AppTextStyles.bodyLarge),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.textHint),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.read<RequestProvider>().updateStatus(id, s);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _AdminInventoryTab extends StatelessWidget {
  const _AdminInventoryTab();

  @override
  Widget build(BuildContext context) {
    return const InventoryScreen();
  }
}
