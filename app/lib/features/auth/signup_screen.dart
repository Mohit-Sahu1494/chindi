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
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await ref.read(authStateProvider.notifier).signup(
          _nameController.text.trim(),
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
                        context.pop();
                      },
                    ),
                  ),
                ),

                // Main Form Content
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 8.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Center(
                              child: ChindiLogo(size: 64),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'NAYA ACCOUNT',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chindi shuru karein',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textIvory,
                                  ),
                            ),
                            const SizedBox(height: 24),

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

                            Text('APNA NAAM', style: Theme.of(context).textTheme.labelSmall),
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: AppColors.textIvory, fontSize: 15),
                              onChanged: (_) {
                                if (ref.read(authStateProvider).error != null) {
                                  ref.read(authStateProvider.notifier).clearError();
                                }
                              },
                              decoration: const InputDecoration(
                                hintText: 'e.g. Ramesh Kumar',
                                prefixIcon: Icon(Icons.badge_outlined, size: 20, color: AppColors.gold),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().length < 2) ? 'Kripya apna poora naam darj karein' : null,
                            ),
                            const SizedBox(height: 20),

                            Text('EMAIL YA MOBILE NUMBER', style: Theme.of(context).textTheme.labelSmall),
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
                                prefixIcon: Icon(Icons.mail_outline, size: 20, color: AppColors.gold),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().length < 3) ? 'Kripya email ya mobile darj karein' : null,
                            ),
                            const SizedBox(height: 20),

                            Text('PASSWORD', style: Theme.of(context).textTheme.labelSmall),
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
                              validator: (v) =>
                                  (v == null || v.length < 6) ? 'Password kam se kam 6 aksharon ka hona chahiye' : null,
                            ),
                            const SizedBox(height: 36),

                            GoldButton(
                              label: 'CHINDI SIGNUP',
                              isLoading: authState.isLoading,
                              onPressed: _submit,
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
}
