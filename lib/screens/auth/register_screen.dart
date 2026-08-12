import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/routes/app_routes.dart';
import '../../models/donor_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/donor_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String? _selectedBloodGroup;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your blood group')),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      phone: _phoneCtrl.text.trim(),
      role: AppConstants.roleDonor,
      bloodGroup: _selectedBloodGroup,
    );

    if (!mounted) return;
    if (success && authProvider.currentUser != null) {
      final donorProvider = context.read<DonorProvider>();
      await donorProvider.createDonorProfile(
        DonorModel(
          id: '',
          userId: authProvider.currentUser!.id,
          name: authProvider.currentUser!.name,
          bloodGroup: authProvider.currentUser!.bloodGroup!,
          phone: authProvider.currentUser!.phone,
          address: authProvider.currentUser!.address,
        ),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.donorHome);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.splashGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_rounded),
                    ),
                    Text('Create Donor Account', style: AppTextStyles.headlineMedium),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            // Common fields
                            CustomTextField(
                              label: 'Full Name',
                              hint: 'Your full name',
                              controller: _nameCtrl,
                              prefixIcon: Icons.person_outline_rounded,
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Name is required' : null,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Email',
                              hint: 'Enter your email',
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.email_outlined,
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Email is required';
                                if (!val.contains('@')) return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Phone Number',
                              hint: '+1-555-0000',
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_outlined,
                              validator: (val) =>
                                  val == null || val.isEmpty ? 'Phone is required' : null,
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              label: 'Password',
                              hint: 'Create a strong password',
                              controller: _passwordCtrl,
                              obscureText: true,
                              prefixIcon: Icons.lock_outline_rounded,
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Password is required';
                                if (val.length < 6) return 'Minimum 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Donor blood group picker
                            Text('Blood Group', style: AppTextStyles.labelMedium),
                            const SizedBox(height: 10),
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
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: isSelected ? color : color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected ? color : color.withValues(alpha: 0.3),
                                          width: isSelected ? 2 : 1,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: color.withValues(alpha: 0.4),
                                                  blurRadius: 12,
                                                  spreadRadius: 1,
                                                )
                                              ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          bg,
                                          style: AppTextStyles.labelLarge.copyWith(
                                            color: isSelected ? Colors.white : color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 20),

                            // Error message
                            if (auth.errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.errorBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                                ),
                                child: Text(auth.errorMessage!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.error)),
                              ),
                              const SizedBox(height: 16),
                            ],

                            CustomButton(
                              label: 'Create Account',
                              onPressed: _register,
                              isLoading: auth.isLoading,
                              icon: Icons.person_add_rounded,
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Already have an account? ',
                                      style: AppTextStyles.bodyMedium),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Text('Sign In',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.primaryLight,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
