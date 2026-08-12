import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../widgets/blood_group_badge.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _nameCtrl.text = user.name;
      _phoneCtrl.text = user.phone;
      _addressCtrl.text = user.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    await auth.updateProfile(user.copyWith(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
    ));
    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Logout', style: AppTextStyles.headlineSmall),
        content: Text('Are you sure you want to logout?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.currentUser;
        if (user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: Icon(
                  _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () => setState(() => _isEditing = !_isEditing),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar section
                _buildAvatar(user),
                const SizedBox(height: 28),

                // Profile form
                _buildProfileCard(user),
                const SizedBox(height: 20),

                // Donor stats (if donor)
                if (user.role == UserRole.donor) _buildDonorStats(),

                // Account section
                _buildAccountSection(user),
                const SizedBox(height: 24),

                // Logout
                CustomButton(
                  label: 'Logout',
                  onPressed: _logout,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF424242), Color(0xFF212121)],
                  ),
                  icon: Icons.logout_rounded,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(UserModel user) {
    final roleColors = {
      UserRole.admin: AppColors.warning,
      UserRole.hospital: AppColors.info,
      UserRole.donor: AppColors.primary,
    };
    final roleIcons = {
      UserRole.admin: Icons.admin_panel_settings_rounded,
      UserRole.hospital: Icons.local_hospital_rounded,
      UserRole.donor: Icons.favorite_rounded,
    };

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 36,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: roleColors[user.role] ?? AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 2),
              ),
              child: Icon(roleIcons[user.role], color: Colors.white, size: 14),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(user.name, style: AppTextStyles.headlineLarge),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: (roleColors[user.role] ?? AppColors.primary).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            user.role.displayName,
            style: AppTextStyles.caption.copyWith(
              color: roleColors[user.role] ?? AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (user.bloodGroup != null) ...[
          const SizedBox(height: 12),
          BloodGroupBadge(bloodGroup: user.bloodGroup!, size: 48, showLabel: true),
        ],
      ],
    );
  }

  Widget _buildProfileCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('Personal Information', style: AppTextStyles.headlineSmall),
            ],
          ),
          const Divider(height: 24),
          if (_isEditing) ...[
            CustomTextField(
              label: 'Full Name',
              controller: _nameCtrl,
              prefixIcon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Phone Number',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 14),
            CustomTextField(
              label: 'Address',
              controller: _addressCtrl,
              maxLines: 2,
              prefixIcon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 20),
            CustomButton(
              label: 'Save Changes',
              onPressed: _saveProfile,
              isLoading: _isSaving,
              height: 46,
              icon: Icons.check_rounded,
            ),
          ] else ...[
            _infoRow(Icons.email_outlined, 'Email', user.email),
            _infoRow(Icons.phone_outlined, 'Phone', user.phone),
            if (user.address != null && user.address!.isNotEmpty)
              _infoRow(Icons.location_on_outlined, 'Address', user.address!),
            if (user.hospitalName != null)
              _infoRow(Icons.business_rounded, 'Hospital', user.hospitalName!),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption),
                Text(value, style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorStats() {
    return Consumer<DonorProvider>(
      builder: (context, donorProvider, _) {
        final donor = donorProvider.currentDonorProfile;
        if (donor == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.volunteer_activism_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Donation Stats',
                      style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statColumn('${donor.totalDonations}', 'Total Donations'),
                  _statColumn(
                    donor.canDonateNow ? 'Ready!' : '${donor.daysUntilEligible}d',
                    donor.canDonateNow ? 'Status' : 'Until Eligible',
                  ),
                  _statColumn(
                    donor.lastDonationDate != null
                        ? '${DateTime.now().difference(donor.lastDonationDate!).inDays}d'
                        : 'Never',
                    'Last Donation',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statColumn(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.headlineLarge.copyWith(color: Colors.white)),
          Text(label,
              style: AppTextStyles.caption.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildAccountSection(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          _menuItem(
            icon: Icons.history_rounded,
            label: 'Donation History',
            onTap: () => Navigator.pushNamed(context, AppRoutes.donationHistory),
            show: user.role == UserRole.donor,
          ),
          _menuItem(
            icon: Icons.search_rounded,
            label: 'Find Donors',
            onTap: () => Navigator.pushNamed(context, AppRoutes.search),
          ),
          _menuItem(
            icon: Icons.bloodtype_rounded,
            label: 'Blood Requests',
            onTap: () => Navigator.pushNamed(context, AppRoutes.bloodRequests),
          ),
          if (user.role == UserRole.admin)
            _menuItem(
              icon: Icons.inventory_2_rounded,
              label: 'Manage Inventory',
              onTap: () => Navigator.pushNamed(context, AppRoutes.inventory),
            ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool show = true,
  }) {
    if (!show) return const SizedBox.shrink();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 14),
            Text(label, style: AppTextStyles.bodyLarge),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
