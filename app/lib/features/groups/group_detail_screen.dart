import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gold_button.dart';
import '../../core/widgets/hairline_divider.dart';
import '../../core/widgets/monogram_avatar.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/group_model.dart';
import '../../data/models/balance_model.dart';
import '../auth/auth_provider.dart';
import '../home/home_provider.dart';

final groupDetailProvider =
    FutureProvider.autoDispose.family<({GroupModel group, GroupLiveBalanceModel balances}), String>(
        (ref, groupId) async {
  final repo = ref.watch(groupRepositoryProvider);
  return await repo.getGroupDetails(groupId);
});

class GroupDetailScreen extends ConsumerWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(groupDetailProvider(groupId));
    final currentUserId = ref.watch(authStateProvider).user?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Group Jankari'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
      ),
      body: detailAsync.when(
        loading: () => const LoadingView(message: 'Group jankari load ho rahi hai...'),
        error: (err, _) => ErrorRetryView(
          message: err.toString(),
          onRetry: () => ref.refresh(groupDetailProvider(groupId)),
        ),
        data: (data) {
          final group = data.group;
          final isAdmin = group.admin?.id == currentUserId;

          return ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  children: [
                    MonogramAvatar(name: group.name, size: 64, borderWidth: 2),
                    const SizedBox(height: 14),
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Admin: ${group.admin?.name ?? 'Admin'}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 18),

                    // Invite code container
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppColors.hairlineActive),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'INVITE CODE',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                group.inviteCode,
                                style: const TextStyle(
                                  color: AppColors.goldLight,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 3.0,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: AppColors.gold, size: 20),
                            tooltip: 'Code copy karein',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: group.inviteCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Invite code copy ho gaya!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action button to open chat
              GoldButton(
                label: 'CHAT MEIN JAYEIN',
                icon: Icons.chat_bubble_outline,
                onPressed: () {
                  ref.read(activeGroupIdProvider.notifier).state = group.id;
                  context.push('/chat/${group.id}');
                },
              ),
              const SizedBox(height: 28),

              // Members list section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GROUP MEMBERS (${group.members.length})',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
                  ),
                  if (isAdmin)
                    const Text(
                      'Aap Admin hain',
                      style: TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: group.members.length,
                  separatorBuilder: (_, _) => const HairlineDivider(indent: 56),
                  itemBuilder: (ctx, idx) {
                    final member = group.members[idx];
                    final isMemberAdmin = member.id == group.admin?.id;
                    final isCurrent = member.id == currentUserId;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: MonogramAvatar(name: member.name, size: 36),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isCurrent ? '${member.name} (Aap)' : member.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isCurrent ? AppColors.goldLight : AppColors.textIvory,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (isMemberAdmin)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                                border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'ADMIN',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        member.emailOrMobile,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Leave Group Button
              OutlinedButton.icon(
                icon: const Icon(Icons.exit_to_app, color: AppColors.negative, size: 18),
                label: const Text(
                  'Group se bahar niklein (Leave Group)',
                  style: TextStyle(color: AppColors.negative, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.negative.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        side: const BorderSide(color: AppColors.hairline),
                      ),
                      title: const Text('Group chodna chahte hain?', style: TextStyle(color: AppColors.textIvory)),
                      content: const Text(
                        'Kya aap sach mein is group se nikalna chahte hain? Aapka hisaab records mein rahega.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Nahi', style: TextStyle(color: AppColors.textMuted)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Haan, Chod dein', style: TextStyle(color: AppColors.negative)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    final success = await ref.read(groupActionProvider.notifier).leaveGroup(group.id);
                    if (success && context.mounted) {
                      context.go('/');
                    } else if (context.mounted) {
                      final err = ref.read(groupActionProvider).error;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(err?.toString() ?? 'Group chhodne mein samasya aayi'),
                          backgroundColor: AppColors.negative,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
