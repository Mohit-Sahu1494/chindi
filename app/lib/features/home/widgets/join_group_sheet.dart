import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../data/api/api_client.dart';
import '../home_provider.dart';

class JoinGroupSheet extends ConsumerStatefulWidget {
  const JoinGroupSheet({super.key});

  @override
  ConsumerState<JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends ConsumerState<JoinGroupSheet> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final group = await ref
        .read(groupActionProvider.notifier)
        .joinGroup(_codeController.text.trim().toUpperCase());

    if (mounted) {
      setState(() => _isLoading = false);
      if (group != null) {
        Navigator.pop(context, group);
      } else {
        final err = ref.read(groupActionProvider).error;
        final message = err != null ? (err is ApiException ? err.message : err.toString()) : 'Galat invite code ya group nahi mila';
        setState(() => _errorMessage = message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.hairlineActive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'GROUP MEIN SHAMIL HOVEIN',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 6),
            Text(
              '6-Akshar Invite Code darj karein',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.negative, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: _codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(
                color: AppColors.goldLight,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 4.0,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'FLAT02',
                counterText: '',
                prefixIcon: Icon(Icons.vpn_key_outlined, color: AppColors.gold, size: 22),
              ),
              validator: (v) =>
                  (v == null || v.trim().length != 6) ? 'Invite code theek 6 akshar ka hona chahiye' : null,
            ),
            const SizedBox(height: 28),

            GoldButton(
              label: 'GROUP JOIN KAREIN',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
