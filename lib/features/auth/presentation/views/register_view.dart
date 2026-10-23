import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../../core/validation.dart';
import '../../../../design_system/app_colors.dart';
import '../../../../design_system/app_text_styles.dart';
import '../../../../design_system/components/app_button.dart';
import '../../../../design_system/components/app_text_field.dart';
import '../../../../design_system/components/docked_cta.dart';
import '../../../../design_system/components/section_header.dart';
import '../providers/auth_providers.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _organizationController = TextEditingController();

  String _selectedRole = 'donor'; // 'donor' or 'receiver'
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = "Passwords do not match.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final organization = _organizationController.text.trim();

    final repository = ref.read(authRepositoryProvider);
    final result = await repository.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: _selectedRole,
      organizationName: organization,
    );

    if (!mounted) return;

    result.fold(
      (userModel) {
        ref.invalidate(authStateProvider);
        ref.invalidate(userProfileProvider);
        context.go(AppRoutes.allSet, extra: userModel);
      },
      (error) {
        setState(() {
          _isLoading = false;
          _errorMessage = error;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.login);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8.0,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create your account',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontSize: 26.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        'Join Surplus to donate or rescue surplus food.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24.0),

                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.error,
                                size: 20.0,
                              ),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.onErrorContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16.0),
                      ],

                      // 1. Role Selection (Compact, Cohesive Stitch Cards)
                      const SectionHeader(title: 'I am a'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleCard(
                              roleId: 'donor',
                              title: 'Food Donor',
                              subtitle: 'Restaurant, canteen, or caterer',
                              icon: Icons.storefront_outlined,
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: _buildRoleCard(
                              roleId: 'receiver',
                              title: 'Food Receiver',
                              subtitle: 'NGO, shelter, or community group',
                              icon: Icons.volunteer_activism_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),

                      // 2. Your Details Section
                      const SectionHeader(title: 'Your details'),
                      AppTextField(
                        label: 'Full name',
                        hintText: 'e.g. Maria Santos',
                        controller: _nameController,
                        validator: AppValidators.validateName,
                      ),
                      const SizedBox(height: 16.0),
                      AppTextField(
                        label: 'Phone number',
                        hintText: 'e.g. +91 98765 43210',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        validator: AppValidators.validatePhone,
                      ),
                      const SizedBox(height: 20.0),

                      // 3. Organization Section
                      const SectionHeader(title: 'Organization'),
                      AppTextField(
                        label: 'Organization name',
                        hintText: _selectedRole == 'donor'
                            ? 'Restaurant or kitchen name'
                            : 'NGO or shelter name',
                        controller: _organizationController,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Organization name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20.0),

                      // 4. Account & Password Section
                      const SectionHeader(title: 'Account security'),
                      AppTextField(
                        label: 'Email address',
                        hintText: 'name@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: AppValidators.validateEmail,
                      ),
                      const SizedBox(height: 16.0),
                      AppTextField(
                        label: 'Password',
                        hintText: 'At least 6 characters',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: AppValidators.validatePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      AppTextField(
                        label: 'Confirm password',
                        hintText: 'Re-enter your password',
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please confirm your password.';
                          }
                          if (val != _passwordController.text) {
                            return "Passwords don't match.";
                          }
                          return null;
                        },
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 28.0),
                    ],
                  ),
                ),
              ),
            ),

            // Docked CTA Footer
            DockedCTA(
              child: AppButton(
                text: 'Create account',
                isLoading: _isLoading,
                onPressed: _handleRegister,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String roleId,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == roleId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = roleId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryContainer
              : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 6.0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 22.0,
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 18.0,
                  ),
              ],
            ),
            const SizedBox(height: 10.0),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.onPrimaryContainer
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? AppColors.onPrimaryContainer.withValues(alpha: 0.8)
                    : AppColors.textSecondary,
                fontSize: 11.0,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
