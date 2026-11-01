import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../data/models/user_model.dart';
import 'monogram_avatar.dart';

class ChipSelector extends StatelessWidget {
  final List<UserModel> members;
  final Set<String> excludedMemberIds;
  final ValueChanged<String> onToggleMember;
  final String? currentUserId;

  const ChipSelector({
    super.key,
    required this.members,
    required this.excludedMemberIds,
    required this.onToggleMember,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person_remove_outlined, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              'BAHAR RAKHEIN (EXCLUDE)',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const Spacer(),
            if (excludedMemberIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.negative.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: AppColors.negative.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${excludedMemberIds.length} bahar',
                  style: const TextStyle(
                    color: AppColors.negative,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: members.map((member) {
            final isExcluded = excludedMemberIds.contains(member.id);
            final isMe = currentUserId != null && member.id == currentUserId;
            final displayName = isMe ? '${member.name} (Aap)' : member.name;

            return FilterChip(
              avatar: MonogramAvatar(
                name: member.name,
                size: 20,
                borderWidth: 0.8,
                textStyle: const TextStyle(fontSize: 9, color: AppColors.gold),
              ),
              label: Text(
                displayName,
                style: TextStyle(
                  color: isExcluded ? AppColors.negative : AppColors.textIvory,
                  fontSize: 12,
                  decoration: isExcluded ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.negative,
                ),
              ),
              selected: isExcluded,
              onSelected: (_) => onToggleMember(member.id),
              backgroundColor: AppColors.surfaceElevated,
              selectedColor: AppColors.negative.withValues(alpha: 0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.full),
                side: BorderSide(
                  color: isExcluded
                      ? AppColors.negative
                      : AppColors.hairline,
                  width: isExcluded ? 1.2 : 0.8,
                ),
              ),
              showCheckmark: true,
              checkmarkColor: AppColors.negative,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            );
          }).toList(),
        ),
      ],
    );
  }
}
