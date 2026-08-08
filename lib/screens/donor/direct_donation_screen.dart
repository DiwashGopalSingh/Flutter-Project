import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';

class DirectDonationScreen extends StatefulWidget {
  const DirectDonationScreen({super.key});

  @override
  State<DirectDonationScreen> createState() => _DirectDonationScreenState();
}

class _DirectDonationScreenState extends State<DirectDonationScreen> {
  String? selectedHospital;
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

  // Mock list of hospitals
  final List<Map<String, String>> hospitals = [
    {'id': 'h1', 'name': 'City General Hospital', 'distance': '2.4 km'},
    {'id': 'h2', 'name': 'Metro Care Hospital', 'distance': '4.1 km'},
    {'id': 'h3', 'name': 'Sunrise Medical Center', 'distance': '5.8 km'},
  ];

  void _scheduleDonation() async {
    if (selectedHospital == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a hospital')),
      );
      return;
    }

    final donorProvider = context.read<DonorProvider>();
    final donorId = context.read<AuthProvider>().currentUser?.id;

    if (donorId != null) {
      // Record donation
      await donorProvider.recordDonation(donorId);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.backgroundCard,
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Text('Scheduled!'),
              ],
            ),
            content: const Text('Your direct donation has been successfully scheduled. Thank you for saving lives!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Direct Donation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Donate to a Nearby Hospital', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Select a hospital to schedule a direct blood donation.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text('Available Hospitals', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            ...hospitals.map((hospital) {
              final isSelected = selectedHospital == hospital['id'];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(Icons.local_hospital, color: Colors.white),
                  ),
                  title: Text(hospital['name']!, style: AppTextStyles.labelLarge),
                  subtitle: Text(hospital['distance']!, style: AppTextStyles.caption),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedHospital = hospital['id'];
                    });
                  },
                ),
              );
            }),
            const SizedBox(height: 24),
            Text('Donation Date', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.primary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null) {
                  setState(() => selectedDate = date);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _scheduleDonation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text('Confirm Donation', style: AppTextStyles.buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
