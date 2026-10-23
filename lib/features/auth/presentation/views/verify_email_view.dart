import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/app_colors.dart';
import '../../../../design_system/app_text_styles.dart';
import '../../../../design_system/components/app_button.dart';
import '../../../../design_system/components/docked_cta.dart';
import '../providers/auth_providers.dart';

class VerifyEmailView extends ConsumerStatefulWidget {
  const VerifyEmailView({super.key});

  @override
  ConsumerState<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends ConsumerState<VerifyEmailView> {
  bool _isResending = false;
  bool _isChecking = false;
  String? _message;
  String? _errorMessage;
  int _resendCooldown = 60;
  Timer? _cooldownTimer;
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
    _startAutoCheckTimer();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _autoCheckTimer?.cancel();
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

  void _startAutoCheckTimer() {
    _autoCheckTimer?.cancel();
    _autoCheckTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!mounted || _isChecking) return;
      await _checkVerificationStatus(isManual: false);
    });
  }

  Future<void> _checkVerificationStatus({bool isManual = true}) async {
    if (_isChecking) return;

    _isChecking = true;
    if (isManual && mounted) {
      setState(() {
        _errorMessage = null;
        _message = null;
      });
    }

    final repo = ref.read(authRepositoryProvider);
    final user = await repo.reloadUser();

    if (!mounted) return;

    _isChecking = false;
    if (isManual && mounted) {
      setState(() {});
    }

    if (user != null && user.emailVerified) {
      _autoCheckTimer?.cancel();
      ref.read(emailVerifiedProvider.notifier).state = true;
    } else if (isManual && mounted) {
      setState(() {
        _errorMessage =
            'Email is not verified yet. Please check your inbox and click the verification link.';
      });
    }
  }

  Future<void> _handleResendVerification() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _message = null;
    });

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.sendEmailVerification();

    if (!mounted) return;

    setState(() {
      _isResending = false;
    });

    result.fold(
      (_) {
        setState(() {
          _message = 'Verification email sent! Please check your inbox.';
        });
        _startCooldownTimer();
      },
      (error) {
        setState(() {
          _errorMessage = error;
        });
      },
    );
  }

  Future<void> _handleLogout() async {
    _autoCheckTimer?.cancel();
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authStateProvider).value;
    final userEmail = authUser?.email ?? 'your email';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_outlined,
              color: AppColors.textPrimary,
            ),
            tooltip: 'Sign out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16.0),
                    Container(
                      width: 64.0,
                      height: 64.0,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 32.0,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    Text(
                      'Verify your email',
                      style: AppTextStyles.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12.0),

                    Text(
                      'We sent a verification link to:',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      userEmail,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),

                    Text(
                      'Please click on the link in that email to activate your account and access Surplus.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24.0),

                    if (_message != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: AppColors.primary,
                              size: 20.0,
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Text(
                                _message!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],

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
                  ],
                ),
              ),
            ),

            // Docked CTA
            DockedCTA(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    text: "I've verified my email",
                    isLoading: _isChecking,
                    onPressed: () => _checkVerificationStatus(isManual: true),
                  ),
                  const SizedBox(height: 8.0),
                  GhostButton(
                    text: _resendCooldown > 0
                        ? 'Resend email in ${_resendCooldown}s'
                        : (_isResending
                              ? 'Sending...'
                              : 'Resend verification email'),
                    onPressed: _resendCooldown == 0 && !_isResending
                        ? _handleResendVerification
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
