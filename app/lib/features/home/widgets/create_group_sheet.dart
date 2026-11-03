import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../data/api/api_client.dart';
import '../home_provider.dart';

class CreateGroupSheet extends ConsumerStatefulWidget {
  const CreateGroupSheet({super.key});

  @override
  ConsumerState<CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<CreateGroupSheet> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final group = await ref.read(groupActionProvider.notifier).createGroup(_nameController.text.trim());

    if (mounted) {
      setState(() => _isLoading = false);
      if (group != null) {
        Navigator.pop(context, group);
      } else {
        final err = ref.read(groupActionProvider).error;
        final message = err != null ? (err is ApiException ? err.message : err.toString()) : 'Group banana asafal raha. Dobara try karein.';
        setState(() => _errorMessage = message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
              'NAYA GROUP BANAYEIN',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 6),
            Text(
              'Group ka naam darj karein',
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
              controller: _nameController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textIvory, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'e.g. Flat 302, Goa Trip, Office Lunch',
                prefixIcon: Icon(Icons.group_add_outlined, color: AppColors.gold, size: 22),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Group naam kam se kam 2 akshar ka hona chahiye' : null,
            ),
            const SizedBox(height: 28),

            GoldButton(
              label: 'GROUP BANAYEIN',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
