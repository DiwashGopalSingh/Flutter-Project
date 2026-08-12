import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../models/blood_request_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hospitalCtrl = TextEditingController();
  final _patientCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');

  String? _selectedBloodGroup;
  String _selectedUrgency = AppConstants.urgencyNormal;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _hospitalCtrl.text = user?.hospitalName ?? user?.name ?? '';
    _phoneCtrl.text = user?.phone ?? '';
  }

  @override
  void dispose() {
    _hospitalCtrl.dispose();
    _patientCtrl.dispose();
    _notesCtrl.dispose();
    _phoneCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user?.role == UserRole.donor || user?.role.name == 'donor') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donors cannot create blood requests. Requests can be submitted by Hospitals and Administrators.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select blood group needed')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final userVal = user!;

    final request = BloodRequestModel(
      id: '',
      requestedBy: userVal.id,
      requesterName: userVal.name,
      hospitalName: _hospitalCtrl.text.trim(),
      bloodGroup: _selectedBloodGroup!,
      quantity: int.tryParse(_quantityCtrl.text) ?? 1,
      urgency: _selectedUrgency,
      status: AppConstants.statusPending,
      patientName: _patientCtrl.text.isNotEmpty ? _patientCtrl.text.trim() : null,
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text.trim() : null,
      requestDate: DateTime.now(),
      contactPhone: _phoneCtrl.text.trim(),
    );

    final success = await context.read<RequestProvider>().createRequest(request);
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Blood request created successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isDonor = user?.role == UserRole.donor;

    if (isDonor) {
      return Scaffold(
        appBar: AppBar(title: const Text('New Blood Request')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block_rounded, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Action Not Allowed', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  'Donors are not permitted to create blood requests. As a donor, you can view existing requests and donate blood to save lives.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'View Blood Requests',
                  width: 220,
                  icon: Icons.bloodtype_rounded,
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.bloodRequests);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('New Blood Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Urgency selector
              Text('Urgency Level', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),
              Row(
                children: AppConstants.urgencyLevels.map((u) {
                  Color urgencyColor;
                  IconData urgencyIcon;
                  switch (u) {
                    case AppConstants.urgencyEmergency:
                      urgencyColor = AppColors.error;
                      urgencyIcon = Icons.emergency_rounded;
                      break;
                    case AppConstants.urgencyUrgent:
                      urgencyColor = AppColors.warning;
                      urgencyIcon = Icons.priority_high_rounded;
                      break;
                    default:
                      urgencyColor = AppColors.info;
                      urgencyIcon = Icons.info_outline_rounded;
                  }
                  final isSelected = _selectedUrgency == u;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedUrgency = u),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(
                            right: u != AppConstants.urgencyEmergency ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? urgencyColor.withValues(alpha: 0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? urgencyColor : AppColors.border,
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(urgencyIcon,
                                color: isSelected ? urgencyColor : AppColors.textHint,
                                size: 20),
                            const SizedBox(height: 4),
                            Text(u,
                                style: AppTextStyles.caption.copyWith(
                                  color: isSelected ? urgencyColor : AppColors.textHint,
                                  fontWeight: isSelected ? FontWeight.w600 : null,
                                )),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Blood group
              Text('Blood Group Needed', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppConstants.bloodGroups.map((bg) {
                  final color = AppColors.bloodGroupColors[bg] ?? AppColors.primary;
                  final isSelected = _selectedBloodGroup == bg;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedBloodGroup = bg),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected ? color : color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : color.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 0.5,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10)]
                            : null,
                      ),
                      child: Center(
                        child: Text(bg,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: isSelected ? Colors.white : color,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Form fields
              CustomTextField(
                label: 'Hospital / Facility Name',
                hint: 'Name of the requesting hospital',
                controller: _hospitalCtrl,
                prefixIcon: Icons.local_hospital_rounded,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Hospital name is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Quantity (units)',
                hint: 'Number of units required',
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.format_list_numbered_rounded,
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Quantity is required';
                  if (int.tryParse(val) == null || int.parse(val) <= 0) {
                    return 'Enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Contact Phone',
                hint: 'Emergency contact number',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_rounded,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Contact phone is required' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Patient Name (Optional)',
                hint: 'Patient requiring blood',
                controller: _patientCtrl,
                prefixIcon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Additional Notes (Optional)',
                hint: 'Describe the situation or any relevant details',
                controller: _notesCtrl,
                maxLines: 3,
                prefixIcon: Icons.notes_rounded,
              ),
              const SizedBox(height: 32),

              // Emergency warning
              if (_selectedUrgency == AppConstants.urgencyEmergency)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Emergency request will be broadcast to all nearby donors immediately.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),

              CustomButton(
                label: _selectedUrgency == AppConstants.urgencyEmergency
                    ? 'Send Emergency Request'
                    : 'Submit Request',
                onPressed: _submit,
                isLoading: _isLoading,
                gradient: _selectedUrgency == AppConstants.urgencyEmergency
                    ? AppColors.emergencyGradient
                    : AppColors.primaryGradient,
                icon: _selectedUrgency == AppConstants.urgencyEmergency
                    ? Icons.emergency_rounded
                    : Icons.send_rounded,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
