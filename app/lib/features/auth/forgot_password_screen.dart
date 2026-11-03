import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/chindi_logo.dart';
import '../../core/widgets/gold_button.dart';
import 'auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isOtpSent = false;

  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email.trim());
  }

  void _sendOtp() async {
    if (!_emailFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final success = await ref.read(authStateProvider.notifier).sendForgotPasswordOtp(email);

    if (success && mounted) {
      setState(() {
        _isOtpSent = true;
      });
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verification OTP aapke email ($email) par bhej diya gaya hai.'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
  }

  void _resendOtp() async {
    if (_resendCountdown > 0) return;
    final email = _emailController.text.trim();
    final success = await ref.read(authStateProvider.notifier).sendForgotPasswordOtp(email);

    if (success && mounted) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Naya OTP bhej diya gaya hai.')),
      );
    }
  }

  void _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _passwordController.text;

    final success = await ref.read(authStateProvider.notifier).resetPassword(
          email: email,
          otp: otp,
          newPassword: newPassword,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password safaltapoorvak badal gaya! Naye password se login karein.'),
          backgroundColor: AppColors.positive,
        ),
      );
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.65),
              radius: 1.25,
              colors: [
                AppColors.gold.withValues(alpha: 0.12),
                AppColors.background,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top header bar with seamless back button
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 2.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.gold),
                      tooltip: 'Wapas jayein',
                      onPressed: () {
                        ref.read(authStateProvider.notifier).clearError();
                        if (_isOtpSent) {
                          setState(() => _isOtpSent = false);
                        } else {
                          context.pop();
                        }
                      },
                    ),
                  ),
                ),

                // Main Content
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                            child: ChindiLogo(size: 64),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isOtpSent ? 'PASSWORD RESET CODE' : 'FORGOT PASSWORD',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 2),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isOtpSent ? 'Naya password banayein' : 'Password Reset Karein',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textIvory,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isOtpSent
                                ? '${_emailController.text.trim()} par bheja gaya 6-digit OTP darj karein.'
                                : 'Apna registered email address darj karein. Hum aapko verification OTP bhejenge.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Global Error Display
                          if (authState.error != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.negative.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                                border: Border.all(color: AppColors.negative.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, size: 20, color: AppColors.negative),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      authState.error!,
                                      style: const TextStyle(
                                        color: AppColors.negative,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16, color: AppColors.negative),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Band karein',
                                    onPressed: () => ref.read(authStateProvider.notifier).clearError(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          if (!_isOtpSent) _buildEmailStep() else _buildResetStep(),

                          const SizedBox(height: 20),

                          // Switch to Login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Password yaad hai? ',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                              InkWell(
                                onTap: () {
                                  ref.read(authStateProvider.notifier).clearError();
                                  context.go('/login');
                                },
                                child: const Text(
                                  'Login karein',
                                  style: TextStyle(
                                    color: AppColors.gold,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.gold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    final authState = ref.watch(authStateProvider);

    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'REGISTERED EMAIL ADDRESS',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textIvory, fontSize: 15),
            onChanged: (_) {
              if (ref.read(authStateProvider).error != null) {
                ref.read(authStateProvider.notifier).clearError();
              }
            },
            decoration: const InputDecoration(
              hintText: 'e.g. yourname@gmail.com',
              prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.gold),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Kripya email address darj karein';
              }
              if (!_isValidEmail(value)) {
                return 'Kripya ek maanya email address darj karein (e.g. name@gmail.com)';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          GoldButton(
            label: 'OTP BHEJEIN (SEND OTP)',
            isLoading: authState.isLoading,
            onPressed: _sendOtp,
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    final authState = ref.watch(authStateProvider);

    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 6-digit OTP Input
          Text(
            '6-DIGIT VERIFICATION CODE',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 24,
              letterSpacing: 10,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              if (ref.read(authStateProvider).error != null) {
                ref.read(authStateProvider.notifier).clearError();
              }
            },
            decoration: const InputDecoration(
              counterText: '',
              hintText: '------',
              hintStyle: TextStyle(
                color: AppColors.textMuted,
                letterSpacing: 8,
                fontSize: 22,
              ),
              prefixIcon: Icon(Icons.mark_email_read_outlined, size: 20, color: AppColors.gold),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Kripya 6-digit OTP darj karein';
              }
              if (value.trim().length != 6) {
                return 'OTP pura 6-digit ka hona chahiye';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Resend OTP row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _resendCountdown > 0
                    ? 'Resend OTP ($_resendCountdown s)'
                    : 'OTP nahi mila?',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              if (_resendCountdown == 0)
                InkWell(
                  onTap: authState.isLoading ? null : _resendOtp,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: Text(
                      'Dobara Bhejein',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.gold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // New Password Input
          Text(
            'NAYA PASSWORD',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: AppColors.textIvory, fontSize: 15),
            onChanged: (_) {
              if (ref.read(authStateProvider).error != null) {
                ref.read(authStateProvider.notifier).clearError();
              }
            },
            decoration: InputDecoration(
              hintText: 'Kam se kam 6 akshar',
              prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.gold),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kripya naya password darj karein';
              }
              if (value.length < 6) {
                return 'Password kam se kam 6 aksharon ka hona chahiye';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Confirm New Password
          Text(
            'PASSWORD CONFIRM KAREIN',
            style: Theme.of(context).textTheme.labelSmall,
          ),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            style: const TextStyle(color: AppColors.textIvory, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Naya password dobara likhein',
              prefixIcon: const Icon(Icons.lock_reset, size: 20, color: AppColors.gold),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kripya password dobara likhein';
              }
              if (value != _passwordController.text) {
                return 'Dono password match nahi ho rahe hain';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),

          GoldButton(
            label: 'PASSWORD RESET KAREIN',
            isLoading: authState.isLoading,
            onPressed: _resetPassword,
          ),
        ],
      ),
    );
  }
}
