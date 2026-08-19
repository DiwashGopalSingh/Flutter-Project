import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../models/blood_request_model.dart';
import '../../models/blood_unit_model.dart';
import '../../models/donor_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/request_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/request_card.dart';

class BloodRequestScreen extends StatefulWidget {
  const BloodRequestScreen({super.key});

  @override
  State<BloodRequestScreen> createState() => _BloodRequestScreenState();
}

class _BloodRequestScreenState extends State<BloodRequestScreen> {
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final req = context.read<RequestProvider>();
      if (auth.currentUser?.role == UserRole.admin || auth.currentUser?.role == UserRole.donor) {
        req.loadAllRequests();
      } else if (auth.currentUser != null) {
        req.loadUserRequests(auth.currentUser!.id);
      }
    });
  }

  Future<void> _handleDonateToRequest(BuildContext context, BloodRequestModel request) async {
    final donorProvider = context.read<DonorProvider>();
    final authUser = context.read<AuthProvider>().currentUser;
    var donorProfile = donorProvider.currentDonorProfile;

    if (donorProfile == null && authUser != null) {
      await donorProvider.createDonorProfile(
        DonorModel(
          id: '',
          userId: authUser.id,
          name: authUser.name,
          bloodGroup: authUser.bloodGroup ?? 'A+',
          phone: authUser.phone,
          address: authUser.address,
        ),
      );
      donorProfile = donorProvider.currentDonorProfile;
    }

    if (!context.mounted) return;

    if (donorProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not verify donor profile. Please re-login.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!donorProfile.canDonateNow) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must wait ${donorProfile.daysUntilEligible} more days before your next donation.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (donorProfile.bloodGroup.trim().toUpperCase() != request.bloodGroup.trim().toUpperCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Blood group mismatch! Your blood group is ${donorProfile.bloodGroup}, but this request requires ${request.bloodGroup}.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await donorProvider.recordDonation(donorProfile.id);

    if (context.mounted) {
      final inventoryProvider = context.read<InventoryProvider>();
      await inventoryProvider.addUnit(
        BloodUnitModel(
          id: '',
          bloodGroup: request.bloodGroup,
          quantity: 1,
          collectionDate: DateTime.now(),
          expiryDate: DateTime.now().add(const Duration(days: 35)),
          status: 'Available',
          donorId: donorProfile.id,
          donorName: donorProfile.name,
          location: request.hospitalName,
        ),
      );
    }

    if (context.mounted) {
      final requestProvider = context.read<RequestProvider>();
      final updatedRequest = await requestProvider.recordUnitDonation(request.id, units: 1);
      await requestProvider.loadAllRequests();

      if (!context.mounted) return;

      final isFullyFulfilled = updatedRequest?.status == 'Fulfilled';
      final remaining = updatedRequest?.remainingQuantity ?? 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFullyFulfilled
                ? 'Thank you! Your donation was pledged to ${request.hospitalName}. Request is now FULLY FULFILLED!'
                : 'Thank you! Your donation was pledged to ${request.hospitalName}. $remaining more unit(s) still needed.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDonor = auth.currentUser?.role == UserRole.donor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Requests'),
        actions: [
          if (!isDonor)
            IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
              tooltip: 'New Blood Request',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.createRequest),
            ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Consumer<RequestProvider>(
            builder: (context, req, _) {
              final stats = req.stats;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _statBadge('Total', '${stats['total']}', AppColors.textSecondary),
                    _statBadge('Pending', '${stats['pending']}', AppColors.warning),
                    _statBadge('Processing', '${stats['processing']}', AppColors.info),
                    _statBadge('Fulfilled', '${stats['fulfilled']}', AppColors.success),
                  ],
                ),
              );
            },
          ),
          // Filter
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', 'Pending', 'Processing', 'Fulfilled', 'Cancelled']
                  .map((s) => _filterChip(s))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Requests
          Expanded(
            child: Consumer<RequestProvider>(
              builder: (context, req, _) {
                if (req.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final filtered = _filterStatus == 'All'
                    ? req.requests
                    : req.requests.where((r) => r.status == _filterStatus).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox_rounded,
                            color: AppColors.textHint, size: 56),
                        const SizedBox(height: 12),
                        Text('No $_filterStatus requests',
                            style: AppTextStyles.bodyMedium),
                        if (!isDonor) ...[
                          const SizedBox(height: 20),
                          CustomButton(
                            label: 'Create Request',
                            width: 180,
                            height: 44,
                            icon: Icons.add_rounded,
                            onPressed: () =>
                                Navigator.pushNamed(context, AppRoutes.createRequest),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => RequestCard(
                    request: filtered[i],
                    onDonate: isDonor ? () => _handleDonateToRequest(context, filtered[i]) : null,
                    onTap: () => _showRequestDetail(context, filtered[i].id, filtered[i].status),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.headlineMedium.copyWith(color: color)),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _filterChip(String status) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = status),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          status,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  void _showRequestDetail(BuildContext context, String id, String currentStatus) {
    final auth = context.read<AuthProvider>();
    if (auth.currentUser?.role != UserRole.admin) return;

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
              Text('Update Status', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              for (final s in ['Pending', 'Processing', 'Fulfilled', 'Cancelled'])
                if (s != currentStatus)
                  ListTile(
                    title: Text(s, style: AppTextStyles.bodyLarge),
                    onTap: () {
                      Navigator.pop(ctx);
                      context.read<RequestProvider>().updateStatus(id, s);
                    },
                  ),
            ],
          ),
        );
      },
    );
  }
}
