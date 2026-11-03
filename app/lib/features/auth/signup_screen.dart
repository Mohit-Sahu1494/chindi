import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/chindi_logo.dart';
import '../../core/widgets/gold_button.dart';
import 'auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _isOtpSent = false;

  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
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
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final success = await ref.read(authStateProvider.notifier).sendSignupOtp(email);

    if (success && mounted) {
      setState(() {
        _isOtpSent = true;
      });
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP aapke email ($email) par bhej diya gaya hai.'),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
    }
  }

  void _resendOtp() async {
    if (_resendCountdown > 0) return;
    final email = _emailController.text.trim();
    final success = await ref.read(authStateProvider.notifier).sendSignupOtp(email);

    if (success && mounted) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Naya OTP bhej diya gaya hai.')),
      );
    }
  }

  void _verifyAndSignup() async {
    if (!_otpFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await ref.read(authStateProvider.notifier).signup(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          otp: _otpController.text.trim(),
        );

    if (success && mounted) {
      context.go('/');
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

                // Main Form Content
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
                            _isOtpSent ? 'EMAIL VERIFICATION' : 'NAYA ACCOUNT',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 2),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isOtpSent ? 'OTP darj karein' : 'Chindi shuru karein',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textIvory,
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

                          if (!_isOtpSent) _buildDetailsForm(authState) else _buildOtpVerificationForm(authState),
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

  // STEP 1: Name, Email, and Password Input
  Widget _buildDetailsForm(AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('APNA NAAM', style: Theme.of(context).textTheme.labelSmall),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: AppColors.textIvory, fontSize: 15),
            onChanged: (_) {
              if (authState.error != null) ref.read(authStateProvider.notifier).clearError();
            },
            decoration: const InputDecoration(
              hintText: 'e.g. Ramesh Kumar',
              prefixIcon: Icon(Icons.badge_outlined, size: 20, color: AppColors.gold),
            ),
            validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Kripya apna poora naam darj karein' : null,
          ),
          const SizedBox(height: 20),

          Text('EMAIL ADDRESS', style: Theme.of(context).textTheme.labelSmall),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textIvory, fontSize: 15),
            onChanged: (_) {
              if (authState.error != null) ref.read(authStateProvider.notifier).clearError();
            },
            decoration: const InputDecoration(
              hintText: 'e.g. yourname@gmail.com',
              prefixIcon: Icon(Icons.mail_outline, size: 20, color: AppColors.gold),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Kripya apna email address darj karein';
              }
              if (!_isValidEmail(v)) {
                return 'Kripya valid Gmail ya email format darj karein';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          Text('PASSWORD', style: Theme.of(context).textTheme.labelSmall),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(color: AppColors.textIvory, fontSize: 15),
            onChanged: (_) {
              if (authState.error != null) ref.read(authStateProvider.notifier).clearError();
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
            validator: (v) =>
                (v == null || v.length < 6) ? 'Password kam se kam 6 aksharon ka hona chahiye' : null,
          ),
          const SizedBox(height: 36),

          GoldButton(
            label: 'OTP BHEJEIN (VERIFY EMAIL)',
            icon: Icons.send_rounded,
            isLoading: authState.isLoading,
            onPressed: _sendOtp,
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Pehle se account hai? ', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              InkWell(
                onTap: () {
                  ref.read(authStateProvider.notifier).clearError();
                  context.pop();
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
        ],
      ),
    );
  }

  // STEP 2: Enter 6-digit OTP sent via Brevo
  Widget _buildOtpVerificationForm(AuthState authState) {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(color: AppColors.hairlineActive),
            ),
            child: Column(
              children: [
                const Icon(Icons.mark_email_read_outlined, size: 36, color: AppColors.gold),
                const SizedBox(height: 10),
                Text(
                  'Humne ${_emailController.text.trim()} par 6-akshar ka verification OTP bheja hai.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    ref.read(authStateProvider.notifier).clearError();
                    setState(() => _isOtpSent = false);
                  },
                  child: const Text(
                    'Email badlein (Change email)',
                    style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            '6-DIGIT OTP ENTER KAREIN',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            style: const TextStyle(
              color: AppColors.goldLight,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: 8.0,
            ),
            decoration: const InputDecoration(
              hintText: '------',
              hintStyle: TextStyle(color: AppColors.textDim, letterSpacing: 8.0),
              alignLabelWithHint: true,
            ),
            validator: (v) =>
                (v == null || v.trim().length != 6) ? 'Kripya theek 6-digit OTP darj karein' : null,
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('OTP nahi mila? ', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              if (_resendCountdown > 0)
                Text(
                  '(${_resendCountdown}s me dobara bhejein)',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 13),
                )
              else
                InkWell(
                  onTap: _resendOtp,
                  child: const Text(
                    'Dobara bhejein',
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
          const SizedBox(height: 28),

          GoldButton(
            label: 'VERIFY & CREATE ACCOUNT',
            icon: Icons.check_circle_outline,
            isLoading: authState.isLoading,
            onPressed: _verifyAndSignup,
          ),
          const SizedBox(height: 16),

          TextButton(
            onPressed: () {
              ref.read(authStateProvider.notifier).clearError();
              setState(() => _isOtpSent = false);
            },
            child: const Text(
              'Pichhe jayein (Back to details)',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
