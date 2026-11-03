import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/chip_selector.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../data/models/user_model.dart';

class AddExpenseBottomBar extends StatefulWidget {
  final List<UserModel> members;
  final String? currentUserId;
  final Future<bool> Function({
    required int amountPaise,
    required String description,
    required List<String> excludedMembers,
  }) onAddExpense;
  final Future<bool> Function(String text) onSendText;

  const AddExpenseBottomBar({
    super.key,
    required this.members,
    this.currentUserId,
    required this.onAddExpense,
    required this.onSendText,
  });

  @override
  State<AddExpenseBottomBar> createState() => _AddExpenseBottomBarState();
}

class _AddExpenseBottomBarState extends State<AddExpenseBottomBar> {
  bool _isExpenseMode = false;
  final _textController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _excludedMemberIds = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleMember(String memberId) {
    setState(() {
      if (_excludedMemberIds.contains(memberId)) {
        _excludedMemberIds.remove(memberId);
      } else {
        // Ensure at least one member remains
        if (_excludedMemberIds.length < widget.members.length - 1) {
          _excludedMemberIds.add(memberId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kam se kam ek member hisaab mein hona chahiye!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  void _submitExpense() async {
    final amountPaise = CurrencyFormatter.parseRupeesToPaise(_amountController.text);
    final description = _descriptionController.text.trim();

    if (amountPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kripya sahi raqam (amount) darj karein')),
      );
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kripya kharche ka description likhein')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await widget.onAddExpense(
      amountPaise: amountPaise,
      description: description,
      excludedMembers: _excludedMemberIds.toList(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        _amountController.clear();
        _descriptionController.clear();
        setState(() {
          _excludedMemberIds.clear();
          _isExpenseMode = false;
        });
        FocusScope.of(context).unfocus();
      }
    }
  }

  void _submitText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    await widget.onSendText(text);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.hairline, width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 14,
        right: 14,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: SafeArea(
        top: false,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          child: _isExpenseMode ? _buildExpenseForm() : _buildTextBar(),
        ),
      ),
    );
  }

  Widget _buildTextBar() {
    return Row(
      children: [
        // Button to toggle expense mode
        InkWell(
          onTap: () {
            setState(() => _isExpenseMode = true);
          },
          borderRadius: BorderRadius.circular(AppRadii.full),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(AppRadii.full),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 16, color: AppColors.textDark),
                SizedBox(width: 4),
                Text(
                  'KHARCHA',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Text input field
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadii.full),
              border: Border.all(color: AppColors.hairline),
            ),
            child: TextField(
              controller: _textController,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: AppColors.textIvory, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Message likhein...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (_) => _submitText(),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Send text button
        IconButton(
          icon: const Icon(Icons.send_rounded, color: AppColors.gold, size: 22),
          onPressed: _submitText,
        ),
      ],
    );
  }

  Widget _buildExpenseForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header with close button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.gold),
                const SizedBox(width: 6),
                Text(
                  'NAYA KHARCHA JODEIN',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => setState(() => _isExpenseMode = false),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Amount & Description fields
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount
            SizedBox(
              width: 105,
              child: TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                  color: AppColors.goldLight,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w700),
                  hintText: '0.00',
                  labelText: 'AMOUNT',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Description
            Expanded(
              child: TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(color: AppColors.textIvory, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'e.g. Chai, Dinner, Cab',
                  labelText: 'KHARCHE KA VIVARAN',
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // "Bahar rakhein" chips selector
        ChipSelector(
          members: widget.members,
          excludedMemberIds: _excludedMemberIds,
          onToggleMember: _toggleMember,
          currentUserId: widget.currentUserId,
        ),
        const SizedBox(height: 16),

        // Action Buttons: Send & Cancel
        Row(
          children: [
            Expanded(
              child: GoldButton(
                label: 'HISAAB JODEIN',
                icon: Icons.check,
                isLoading: _isSubmitting,
                onPressed: _submitExpense,
                height: 42,
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () => setState(() => _isExpenseMode = false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
      ],
    );
  }
}
