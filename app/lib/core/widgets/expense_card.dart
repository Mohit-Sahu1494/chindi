import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../../data/models/expense_model.dart';
import 'monogram_avatar.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final String? currentUserId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.currentUserId,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = currentUserId != null && expense.paidBy.id == currentUserId;
    final payerName = isMe ? 'Aap' : expense.paidBy.name;
    final sharePaise = expense.individualSharePaise;
    final participantCount = expense.participants.length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isMe ? AppColors.gold.withValues(alpha: 0.35) : AppColors.hairline,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Payer avatar, name & time, more options if payer
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              children: [
                MonogramAvatar(name: expense.paidBy.name, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$payerName ne diya',
                        style: TextStyle(
                          color: isMe ? AppColors.gold : AppColors.textIvory,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormatter.formatRelativeOrDate(expense.createdAt),
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isMe && (onEdit != null || onDelete != null))
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                    color: AppColors.surfaceLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      side: const BorderSide(color: AppColors.hairline),
                    ),
                    onSelected: (val) {
                      if (val == 'edit' && onEdit != null) onEdit!();
                      if (val == 'delete' && onDelete != null) onDelete!();
                    },
                    itemBuilder: (ctx) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16, color: AppColors.gold),
                              SizedBox(width: 10),
                              Text('Badlein (Edit)', style: TextStyle(color: AppColors.textIvory, fontSize: 13)),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 16, color: AppColors.negative),
                              SizedBox(width: 10),
                              Text('Hatayein (Delete)', style: TextStyle(color: AppColors.negative, fontSize: 13)),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1, thickness: 0.6, color: AppColors.hairline),

          // Body: Amount and Description
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                // Big Amount in Playfair Display
                Text(
                  CurrencyFormatter.formatPaise(expense.amountPaise),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    expense.description,
                    style: const TextStyle(
                      color: AppColors.textIvory,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Footer info: per-person share & excluded members
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppRadii.md),
                bottomRight: Radius.circular(AppRadii.md),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pie_chart_outline, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      'Hisaab: ${CurrencyFormatter.formatPaise(sharePaise)} / vyakti ($participantCount log)',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (expense.excludedMembers.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.block_outlined, size: 12, color: AppColors.negative),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Bahar: ${expense.excludedMembers.map((u) => u.name).join(', ')}',
                          style: const TextStyle(
                            color: AppColors.negative,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
