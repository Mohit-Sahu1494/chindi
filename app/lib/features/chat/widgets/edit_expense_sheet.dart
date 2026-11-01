import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/chip_selector.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/user_model.dart';

class EditExpenseSheet extends StatefulWidget {
  final ExpenseModel expense;
  final List<UserModel> members;
  final String? currentUserId;
  final Future<bool> Function({
    required int amountPaise,
    required String description,
    required List<String> excludedMembers,
  }) onUpdate;

  const EditExpenseSheet({
    super.key,
    required this.expense,
    required this.members,
    this.currentUserId,
    required this.onUpdate,
  });

  @override
  State<EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends State<EditExpenseSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final Set<String> _excludedMemberIds;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: (widget.expense.amountPaise / 100.0).toStringAsFixed(2),
    );
    _descriptionController = TextEditingController(text: widget.expense.description);
    _excludedMemberIds = Set<String>.from(widget.expense.excludedMembers.map((u) => u.id));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleMember(String memberId) {
    setState(() {
      if (_excludedMemberIds.contains(memberId)) {
        _excludedMemberIds.remove(memberId);
      } else {
        if (_excludedMemberIds.length < widget.members.length - 1) {
          _excludedMemberIds.add(memberId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kam se kam ek member hisaab mein hona chahiye!')),
          );
        }
      }
    });
  }

  void _submit() async {
    final amountPaise = CurrencyFormatter.parseRupeesToPaise(_amountController.text);
    final description = _descriptionController.text.trim();

    if (amountPaise <= 0 || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kripya sahi amount aur description darj karein')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await widget.onUpdate(
      amountPaise: amountPaise,
      description: description,
      excludedMembers: _excludedMemberIds.toList(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairlineActive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('KHARCHA BADLEIN (EDIT)', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 6),
          Text(
            'Hisaab Update Karein',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          // Fields
          Row(
            children: [
              SizedBox(
                width: 120,
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.goldLight, fontSize: 18, fontWeight: FontWeight.w700),
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    labelText: 'AMOUNT',
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: AppColors.textIvory, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'DESCRIPTION',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Chip Selector
          ChipSelector(
            members: widget.members,
            excludedMemberIds: _excludedMemberIds,
            onToggleMember: _toggleMember,
            currentUserId: widget.currentUserId,
          ),
          const SizedBox(height: 24),

          GoldButton(
            label: 'BADLAV SAVE KAREIN',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
