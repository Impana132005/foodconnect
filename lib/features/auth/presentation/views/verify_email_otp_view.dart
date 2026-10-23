import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/app_colors.dart';
import '../../../../design_system/app_text_styles.dart';
import '../../../../design_system/components/app_button.dart';
import '../../../../design_system/components/otp_field.dart';
import '../../../../core/validation.dart';
import '../providers/auth_providers.dart';

class VerifyEmailOtpView extends ConsumerStatefulWidget {
  final String email;
  final String name;
  final String phone;
  final String password;
  final String role;
  final String? initialOtp;

  const VerifyEmailOtpView({
    super.key,
    required this.email,
    required this.name,
    required this.phone,
    required this.password,
    required this.role,
    this.initialOtp,
  });

  @override
  ConsumerState<VerifyEmailOtpView> createState() => _VerifyEmailOtpViewState();
}

class _VerifyEmailOtpViewState extends ConsumerState<VerifyEmailOtpView> {
  String _enteredOtp = '';
  String? _devOtp;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCooldown = 60;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _devOtp = widget.initialOtp;
    _startCooldownTimer();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer() {
    _resendCooldown = 60;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCooldown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendCooldown--;
        });
      }
    });
  }

  Future<void> _handleResendOtp() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.sendEmailOtp(widget.email);

    if (!mounted) return;

    setState(() {
      _isResending = false;
    });

    result.fold(
      (otpMsg) {
        setState(() {
          _devOtp = otpMsg;
        });
        _startCooldownTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A new 6-digit OTP code has been sent to your email.',
            ),
          ),
        );
      },
      (error) {
        setState(() {
          _errorMessage = error;
        });
      },
    );
  }

  Future<void> _handleVerifyAndRegister() async {
    if (_isLoading) return;
    final otpError = AppValidators.validateOtp(_enteredOtp);
    if (otpError != null) {
      setState(() {
        _errorMessage = otpError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.verifyEmailOtp(
      email: widget.email,
      otp: _enteredOtp,
      name: widget.name,
      phone: widget.phone,
      password: widget.password,
      role: widget.role,
    );

    if (!mounted) return;

    result.fold(
      (userModel) {
        // Successful verification and registration!
        // RouterNotifier will automatically route the user to their dashboard via GoRouter.
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify Email', style: AppTextStyles.displayLarge),
              const SizedBox(height: 8.0),
              Text(
                'We sent a 6-digit OTP code to:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                widget.email,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24.0),

              // Dev OTP Hint Callout Banner
              if (_devOtp != null && RegExp(r'^\d{6}$').hasMatch(_devOtp!)) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mark_email_read_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email Verification OTP Code:',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _devOtp!,
                              style: AppTextStyles.titleLarge.copyWith(
                                color: AppColors.primary,
                                letterSpacing: 4.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),
              ],

              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: AppColors.error, width: 1.0),
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
                const SizedBox(height: 20.0),
              ],

              Text(
                'Enter 6-Digit OTP Code',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12.0),

              OtpField(
                length: 6,
                onChanged: (val) {
                  setState(() {
                    _enteredOtp = val;
                  });
                },
                onCompleted: (val) {
                  _enteredOtp = val;
                  _handleVerifyAndRegister();
                },
              ),
              const SizedBox(height: 32.0),

              AppButton(
                text: 'Verify & Create Account',
                isLoading: _isLoading,
                onPressed: _handleVerifyAndRegister,
              ),
              const SizedBox(height: 24.0),

              Center(
                child: TextButton(
                  onPressed: _resendCooldown == 0 && !_isResending
                      ? _handleResendOtp
                      : null,
                  child: Text(
                    _resendCooldown > 0
                        ? 'Resend OTP code in ${_resendCooldown}s'
                        : (_isResending ? 'Sending...' : 'Resend OTP Code'),
                    style: AppTextStyles.labelLarge.copyWith(
                      color: _resendCooldown == 0
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
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
