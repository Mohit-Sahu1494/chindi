import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/chindi_logo.dart';
import '../../core/widgets/gold_button.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await ref.read(authStateProvider.notifier).login(
          _identifierController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Premium Chindi Logo
                    const Center(
                      child: ChindiLogo(size: 86),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'CHINDI',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            letterSpacing: 5.0,
                            fontWeight: FontWeight.w800,
                            color: AppColors.goldLight,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Doston ke beech har sikke ka saaf hisaab',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                            letterSpacing: 0.3,
                          ),
                    ),
                    const SizedBox(height: 36),

                    // Error message alert
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

                    // Underline inputs
                    Text(
                      'EMAIL YA MOBILE NUMBER',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    TextFormField(
                      controller: _identifierController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.textIvory, fontSize: 15),
                      onChanged: (_) {
                        if (ref.read(authStateProvider).error != null) {
                          ref.read(authStateProvider.notifier).clearError();
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'e.g. ramesh@hisaab.app ya 9876543210',
                        prefixIcon: Icon(Icons.person_outline, size: 20, color: AppColors.gold),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Kripya email ya mobile darj karein';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'PASSWORD',
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
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kripya password darj karein';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 36),

                    // Primary Button
                    GoldButton(
                      label: 'CHINDI MEIN LOGIN KAREIN',
                      isLoading: authState.isLoading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 20),

                    // Switch to Signup
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Naya account banana hai? ',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                        InkWell(
                          onTap: () {
                            ref.read(authStateProvider.notifier).clearError();
                            context.push('/signup');
                          },
                          child: const Text(
                            'Signup karein',
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
