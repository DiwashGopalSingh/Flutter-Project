import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/campaign_provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/blood_group_badge.dart';
import '../../widgets/request_card.dart';

class DonorHomeScreen extends StatefulWidget {
  const DonorHomeScreen({super.key});

  @override
  State<DonorHomeScreen> createState() => _DonorHomeScreenState();
}

class _DonorHomeScreenState extends State<DonorHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        context.read<DonorProvider>().loadDonorProfile(authProvider.currentUser!.id);
        context.read<RequestProvider>().loadAllRequests();
        context.read<CampaignProvider>().loadCampaigns();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _DonorHomeTab(),
          _SearchTab(),
          _DonorProfileTab(),
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
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _DonorHomeTab extends StatelessWidget {
  const _DonorHomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildEligibilityCard(context),
            _buildQuickActions(context),
            _buildUpcomingDrives(context),
            _buildEmergencyRequests(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final firstName = user?.name.split(' ').first ?? 'Donor';
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, $firstName 👋', style: AppTextStyles.displaySmall),
                const SizedBox(height: 4),
                Text('Your donations save lives', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          if (user?.bloodGroup != null)
            BloodGroupBadge(bloodGroup: user!.bloodGroup!, size: 52, showLabel: false),
        ],
      ),
    );
  }

  Widget _buildEligibilityCard(BuildContext context) {
    return Consumer<DonorProvider>(
      builder: (context, donorProvider, _) {
        final donor = donorProvider.currentDonorProfile;
        final canDonate = donor?.canDonateNow ?? true;
        final daysLeft = donor?.daysUntilEligible ?? 0;
        final totalDonations = donor?.totalDonations ?? 0;

        return Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: canDonate ? AppColors.primaryGradient : AppColors.cardGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (canDonate ? AppColors.primary : Colors.black).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    canDonate ? Icons.check_circle_rounded : Icons.timer_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    canDonate ? 'You Can Donate Today!' : 'Next Donation In',
                    style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
                  ),
                ],
              ),
              if (!canDonate) ...[
                const SizedBox(height: 8),
                Text(
                  '$daysLeft days',
                  style: AppTextStyles.statNumber.copyWith(color: Colors.white),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  _statPill('❤️ $totalDonations', 'Donations'),
                  const SizedBox(width: 12),
                  if (canDonate)
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Schedule Donation',
                          style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statPill(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 14),
          Row(
            children: [
              _actionCard(
                context,
                'History',
                Icons.history_rounded,
                AppColors.info,
                () => Navigator.pushNamed(context, AppRoutes.donationHistory),
              ),
              const SizedBox(width: 12),
              _actionCard(
                context,
                'Requests',
                Icons.bloodtype_rounded,
                AppColors.primary,
                () => Navigator.pushNamed(context, AppRoutes.bloodRequests),
              ),
              const SizedBox(width: 12),
              _actionCard(
                context,
                'Search',
                Icons.search_rounded,
                AppColors.warning,
                () => Navigator.pushNamed(context, AppRoutes.search),
              ),
              const SizedBox(width: 12),
              _actionCard(
                context,
                'Drives',
                Icons.event_available_rounded,
                AppColors.success,
                () => Navigator.pushNamed(context, AppRoutes.campaigns),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionCard(BuildContext context, String label, IconData icon, Color color,
      VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(label, style: AppTextStyles.caption.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyRequests(BuildContext context) {
    return Consumer<RequestProvider>(
      builder: (context, reqProvider, _) {
        final emergency = reqProvider.emergencyRequests;
        if (emergency.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 6),
                  Text('Emergency Requests',
                      style: AppTextStyles.headlineSmall.copyWith(color: AppColors.error)),
                ],
              ),
              const SizedBox(height: 12),
              ...emergency.take(3).map((req) => RequestCard(request: req)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpcomingDrives(BuildContext context) {
    return Consumer<CampaignProvider>(
      builder: (context, campaignProvider, _) {
        final campaigns = campaignProvider.campaigns;
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Upcoming Blood Drives', style: AppTextStyles.headlineSmall),
                  if (campaigns.isNotEmpty)
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.campaigns),
                      child: Text('View All',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.primaryLight)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (campaigns.isEmpty)
                _buildDirectDonationCard(context)
              else
                ...campaigns.take(2).map((campaign) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.event_available_rounded, color: AppColors.success),
                    ),
                    title: Text(campaign.title, style: AppTextStyles.labelLarge),
                    subtitle: Text('${campaign.location} • ${DateFormat('MMM dd').format(campaign.date)}', style: AppTextStyles.caption),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
                    onTap: () => Navigator.pushNamed(context, AppRoutes.campaigns),
                  ),
                )),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDirectDonationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No active blood drives right now.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 8),
          Text('However, your blood is still needed! You can schedule a direct donation at a nearby hospital.', style: AppTextStyles.caption),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/direct-donation');
              },
              icon: const Icon(Icons.local_hospital_rounded, size: 18),
              label: const Text('Donate to Hospital'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchTab extends StatelessWidget {
  const _SearchTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Search'));
  }
}

class _DonorProfileTab extends StatelessWidget {
  const _DonorProfileTab();

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamed(context, AppRoutes.profile);
    });
    return const SizedBox.shrink();
  }
}
