import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/request_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/request_card.dart';
import '../campaigns/campaigns_screen.dart';


class HospitalHomeScreen extends StatefulWidget {
  const HospitalHomeScreen({super.key});

  @override
  State<HospitalHomeScreen> createState() => _HospitalHomeScreenState();
}

class _HospitalHomeScreenState extends State<HospitalHomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      context.read<InventoryProvider>().loadInventory();
      context.read<CampaignProvider>().loadCampaigns();
      if (user != null) {
        context.read<RequestProvider>().loadUserRequests(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _HospitalHomeTab(),
          _HospitalRequestsTab(),
          CampaignsScreen(),
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
            BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'My Requests'),
            BottomNavigationBarItem(icon: Icon(Icons.event_available_rounded), label: 'Drives'),
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

class _HospitalHomeTab extends StatelessWidget {
  const _HospitalHomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildSOSCard(context),
            _buildBloodAvailability(context),
            _buildMyRequests(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = context.read<AuthProvider>().currentUser;
    final name = user?.hospitalName ?? user?.name ?? 'Hospital';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: AppTextStyles.headlineLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text('Blood Request Management', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: AppColors.primary, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSOSCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.emergencyGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emergency SOS',
                    style: AppTextStyles.headlineMedium.copyWith(color: Colors.white)),
                const SizedBox(height: 2),
                Text('Broadcast urgent blood request',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.createRequest),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              ),
              child: Text('SOS',
                  style: AppTextStyles.buttonText.copyWith(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodAvailability(BuildContext context) {
    return Consumer<InventoryProvider>(
      builder: (context, inv, _) {
        final summary = inv.stockSummary;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Blood Availability', style: AppTextStyles.headlineSmall),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.search),
                    child: Text('See All',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryLight)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),
                itemCount: summary.keys.length,
                itemBuilder: (context, i) {
                  final bg = summary.keys.elementAt(i);
                  final qty = summary[bg] ?? 0;
                  final color = AppColors.bloodGroupColors[bg] ?? AppColors.primary;
                  final isLow = qty <= 3;
                  return Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLow ? color.withValues(alpha: 0.6) : color.withValues(alpha: 0.2),
                        width: isLow ? 1.5 : 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(bg,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            )),
                        const SizedBox(height: 4),
                        Text('$qty units',
                            style: AppTextStyles.caption.copyWith(color: color.withValues(alpha: 0.8))),
                        if (isLow)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(Icons.warning_amber_rounded,
                                size: 10, color: color),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyRequests(BuildContext context) {
    return Consumer<RequestProvider>(
      builder: (context, reqProvider, _) {
        final pending = reqProvider.pendingRequests.take(3).toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Active Requests', style: AppTextStyles.headlineSmall),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.bloodRequests),
                    child: Text('View All',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryLight)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (pending.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inbox_rounded,
                            color: AppColors.textHint, size: 36),
                        const SizedBox(height: 8),
                        Text('No active requests', style: AppTextStyles.bodyMedium),
                        const SizedBox(height: 12),
                        CustomButton(
                          label: 'Create Request',
                          onPressed: () =>
                              Navigator.pushNamed(context, AppRoutes.createRequest),
                          width: 160,
                          height: 42,
                          icon: Icons.add_rounded,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...pending.map((req) => RequestCard(request: req)),
            ],
          ),
        );
      },
    );
  }
}

class _HospitalRequestsTab extends StatelessWidget {
  const _HospitalRequestsTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              children: [
                Text('My Requests', style: AppTextStyles.headlineLarge),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.createRequest),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  ),
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bloodtype_outlined,
                            color: AppColors.textHint, size: 56),
                        const SizedBox(height: 12),
                        Text('No requests yet', style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: req.requests.length,
                  itemBuilder: (context, i) => RequestCard(
                    request: req.requests[i],
                    onTap: () {},
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
