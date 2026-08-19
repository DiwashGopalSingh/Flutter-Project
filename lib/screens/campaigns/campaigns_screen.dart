import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/donor_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../models/campaign_model.dart';
import '../../models/blood_unit_model.dart';
import '../../models/user_model.dart';
import '../../core/constants/app_constants.dart';
import 'package:intl/intl.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key});

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignProvider>().loadCampaigns();
    });
  }

  void _showAddCampaignDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final unitsCtrl = TextEditingController(text: '50');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    List<String> selectedBloodGroups = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.backgroundCard,
              title: Text('Create Blood Drive', style: AppTextStyles.headlineMedium),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationCtrl,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: unitsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Target Quantity Needed (units)',
                        hintText: 'e.g. 50',
                        prefixIcon: Icon(Icons.format_list_numbered_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}', style: AppTextStyles.bodyMedium),
                      trailing: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('Target Blood Groups (Select multiple)', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        FilterChip(
                          label: const Text('ALL GROUPS', style: TextStyle(fontWeight: FontWeight.bold)),
                          selected: selectedBloodGroups.length == AppConstants.bloodGroups.length,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedBloodGroups = List.from(AppConstants.bloodGroups);
                              } else {
                                selectedBloodGroups.clear();
                              }
                            });
                          },
                        ),
                        ...AppConstants.bloodGroups.map((bg) {
                          final isSelected = selectedBloodGroups.contains(bg);
                          return FilterChip(
                            label: Text(bg, style: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold)),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surface,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  selectedBloodGroups.add(bg);
                                } else {
                                  selectedBloodGroups.remove(bg);
                                }
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final auth = context.read<AuthProvider>();
                    final campaignProvider = context.read<CampaignProvider>();
                    
                    if (titleCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a campaign title'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      return;
                    }

                    if (locationCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a campaign location'),
                          backgroundColor: AppColors.warning,
                        ),
                      );
                      return;
                    }
                    
                    final success = await campaignProvider.createCampaign(
                      CampaignModel(
                        id: '', // Will be generated by service
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        location: locationCtrl.text.trim(),
                        date: selectedDate,
                        organizerId: auth.currentUser?.id ?? 'admin-001',
                        organizerName: auth.currentUser?.name ?? 'City General Hospital',
                        targetBloodGroups: selectedBloodGroups,
                        targetUnits: int.tryParse(unitsCtrl.text) ?? 50,
                      )
                    );
                    
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Blood Drive Campaign started successfully!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to start campaign. Please try again.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Start Drive'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isAdminOrHospital = auth.currentUser?.role == UserRole.admin ||
        auth.currentUser?.role == UserRole.hospital ||
        auth.currentUser?.role.name == 'admin' ||
        auth.currentUser?.role.name == 'hospital';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Drives'),
        actions: [
          if (isAdminOrHospital)
            IconButton(
              icon: const Icon(Icons.add_location_alt_rounded),
              tooltip: 'Start Drive Campaign',
              onPressed: _showAddCampaignDialog,
            )
        ],
      ),
      floatingActionButton: isAdminOrHospital
          ? FloatingActionButton.extended(
              onPressed: _showAddCampaignDialog,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Start Drive Campaign'),
            )
          : null,
      body: Consumer<CampaignProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.campaigns.isEmpty) {
            return Center(
              child: Text('No upcoming blood drives.', style: AppTextStyles.bodyMedium),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.campaigns.length,
            itemBuilder: (context, index) {
              final campaign = provider.campaigns[index];
              final isRegistered = campaign.registeredUserIds.contains(auth.currentUser?.id);
              final hasDonated = campaign.donatedUserIds.contains(auth.currentUser?.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(campaign.title, style: AppTextStyles.headlineSmall),
                                const SizedBox(height: 8),
                                Text(campaign.description, style: AppTextStyles.bodySmall),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_rounded, color: AppColors.primaryLight),
                            tooltip: 'Invite others to donate',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Invite link copied to clipboard! Share it with friends to save lives.')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Expanded(child: Text(campaign.location, style: AppTextStyles.caption)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(DateFormat('MMM dd, yyyy').format(campaign.date), style: AppTextStyles.caption),
                        ],
                      ),
                      if (campaign.targetBloodGroups.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.bloodtype_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text('Requested Groups: ', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: campaign.targetBloodGroups.map((bg) {
                                  final bgColor = AppColors.bloodGroupColors[bg] ?? AppColors.primary;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: bgColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: bgColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      bg,
                                      style: AppTextStyles.caption.copyWith(
                                        color: bgColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      // Quantity Goal Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Goal Progress: ${campaign.donatedUserIds.length} / ${campaign.targetUnits} units collected',
                                style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${((campaign.donatedUserIds.length / (campaign.targetUnits > 0 ? campaign.targetUnits : 1)) * 100).clamp(0, 100).toStringAsFixed(0)}%',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (campaign.donatedUserIds.length / (campaign.targetUnits > 0 ? campaign.targetUnits : 1)).clamp(0.0, 1.0),
                              backgroundColor: AppColors.surface,
                              color: AppColors.primary,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (auth.currentUser?.role.name == 'donor')
                        SizedBox(
                          width: double.infinity,
                          child: hasDonated 
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.successBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.success),
                                ),
                                child: Center(
                                  child: Text('Donation Completed', style: AppTextStyles.buttonText.copyWith(color: AppColors.success)),
                                ),
                              )
                            : isRegistered 
                              ? ElevatedButton(
                                  onPressed: () async {
                                    final donorProvider = context.read<DonorProvider>();
                                    final donorProfile = donorProvider.currentDonorProfile;
                                    if (donorProfile != null && !donorProfile.canDonateNow) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('You must wait ${donorProfile.daysUntilEligible} more days before your next donation.'),
                                          backgroundColor: AppColors.warning,
                                        ),
                                      );
                                      return;
                                    }

                                    final success = await provider.startDonation(campaign.id, auth.currentUser!.id);
                                    if (success && context.mounted) {
                                      if (donorProvider.currentDonorProfile != null) {
                                        await donorProvider.recordDonation(donorProvider.currentDonorProfile!.id);
                                        
                                        // Automatically add to inventory
                                        if (!context.mounted) return;
                                        final inventoryProvider = context.read<InventoryProvider>();
                                        await inventoryProvider.addUnit(
                                          BloodUnitModel(
                                            id: '',
                                            bloodGroup: donorProvider.currentDonorProfile!.bloodGroup,
                                            quantity: 1,
                                            collectionDate: DateTime.now(),
                                            expiryDate: DateTime.now().add(const Duration(days: 35)),
                                            status: 'Available',
                                            donorId: donorProvider.currentDonorProfile!.id,
                                            donorName: donorProvider.currentDonorProfile!.name,
                                            location: campaign.location,
                                          )
                                        );
                                      }
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Thank you for donating!')),
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                  ),
                                  child: const Text('Start Donation'),
                                )
                              : ElevatedButton(
                                  onPressed: () {
                                    provider.registerForCampaign(campaign.id, auth.currentUser!.id);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryDark,
                                  ),
                                  child: const Text('Register Now'),
                                ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
