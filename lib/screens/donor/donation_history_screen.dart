import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../widgets/blood_group_badge.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  // Sample donation history entries
  final List<Map<String, dynamic>> _history = [
    {
      'date': DateTime.now().subtract(const Duration(days: 70)),
      'bloodGroup': 'O+',
      'location': 'Main Blood Bank',
      'quantity': 1,
      'status': 'Completed',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 130)),
      'bloodGroup': 'O+',
      'location': 'North Branch',
      'quantity': 1,
      'status': 'Completed',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 200)),
      'bloodGroup': 'O+',
      'location': 'Main Blood Bank',
      'quantity': 1,
      'status': 'Completed',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 268)),
      'bloodGroup': 'O+',
      'location': 'South Clinic',
      'quantity': 1,
      'status': 'Completed',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<DonorProvider>().loadDonorProfile(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donation History')),
      body: Consumer2<AuthProvider, DonorProvider>(
        builder: (context, auth, donorProvider, _) {
          final user = auth.currentUser;
          final donor = donorProvider.currentDonorProfile;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (user?.bloodGroup != null)
                        BloodGroupBadge(
                          bloodGroup: user!.bloodGroup!,
                          size: 64,
                          showLabel: false,
                        ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${donor?.totalDonations ?? _history.length} Donations',
                              style: AppTextStyles.displaySmall
                                  .copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getLifeSavingsText(donor?.totalDonations ?? _history.length),
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white70),
                            ),
                            if (donor?.canDonateNow == true) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded,
                                        color: Colors.white, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Eligible to donate now!',
                                      style: AppTextStyles.caption
                                          .copyWith(color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Achievement badges
                Text('Achievements', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 14),
                _buildAchievements(donor?.totalDonations ?? _history.length),
                const SizedBox(height: 24),

                // Timeline
                Text('Donation Timeline', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                if (_history.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.history_rounded,
                            color: AppColors.textHint, size: 48),
                        const SizedBox(height: 12),
                        Text('No donations yet', style: AppTextStyles.bodyMedium),
                        Text('Your donations will appear here',
                            style: AppTextStyles.bodySmall),
                      ],
                    ),
                  )
                else
                  ..._history.asMap().entries.map((entry) =>
                      _timelineItem(entry.value, entry.key, _history.length)),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getLifeSavingsText(int donations) {
    final lives = donations * 3;
    return 'Potentially saved up to $lives lives';
  }

  Widget _buildAchievements(int totalDonations) {
    final achievements = [
      {'title': 'First Drop', 'icon': '🩸', 'req': 1, 'desc': 'First donation'},
      {'title': 'Life Saver', 'icon': '💖', 'req': 3, 'desc': '3 donations'},
      {'title': 'Hero', 'icon': '🦸', 'req': 5, 'desc': '5 donations'},
      {'title': 'Champion', 'icon': '🏆', 'req': 10, 'desc': '10 donations'},
      {'title': 'Legend', 'icon': '⭐', 'req': 20, 'desc': '20 donations'},
    ];

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        itemBuilder: (context, i) {
          final ach = achievements[i];
          final unlocked = totalDonations >= (ach['req'] as int);
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: unlocked
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: unlocked
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ach['icon'] as String,
                  style: TextStyle(
                    fontSize: 28,
                    color: unlocked ? null : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ach['title'] as String,
                  style: AppTextStyles.caption.copyWith(
                    color: unlocked ? AppColors.primary : AppColors.textHint,
                    fontWeight: unlocked ? FontWeight.w600 : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _timelineItem(Map<String, dynamic> donation, int index, int total) {
    final isLast = index == total - 1;
    final date = donation['date'] as DateTime;
    final color = AppColors.bloodGroupColors[donation['bloodGroup']] ?? AppColors.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1),
                ],
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 80,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${donation['bloodGroup']} Donation',
                      style: AppTextStyles.bodyLarge,
                    ),
                    const Spacer(),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        donation['status'] as String,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.success),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(donation['location'] as String,
                        style: AppTextStyles.caption),
                    const SizedBox(width: 12),
                    const Icon(Icons.calendar_today_rounded,
                        size: 13, color: AppColors.textHint),
                    const SizedBox(width: 4),
                    Text(_formatDate(date), style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
