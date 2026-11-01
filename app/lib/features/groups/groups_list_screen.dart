import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/custom_bottom_nav.dart';
import '../../core/widgets/monogram_avatar.dart';
import '../../core/widgets/state_views.dart';
import '../home/home_provider.dart';
import '../home/widgets/create_group_sheet.dart';
import '../home/widgets/join_group_sheet.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(homeSummaryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Aapke Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.gold),
            tooltip: 'Naya Group',
            onPressed: () async {
              final group = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
                ),
                builder: (ctx) => const CreateGroupSheet(),
              );
              if (group != null && context.mounted) {
                ref.read(activeGroupIdProvider.notifier).state = group.id;
                context.push('/chat/${group.id}');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.login, color: AppColors.gold),
            tooltip: 'Join Group',
            onPressed: () async {
              final group = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AppColors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
                ),
                builder: (ctx) => const JoinGroupSheet(),
              );
              if (group != null && context.mounted) {
                ref.read(activeGroupIdProvider.notifier).state = group.id;
                context.push('/chat/${group.id}');
              }
            },
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const LoadingView(message: 'Groups load ho rahe hain...'),
        error: (err, _) => ErrorRetryView(
          message: err.toString(),
          onRetry: () => ref.refresh(homeSummaryProvider),
        ),
        data: (summary) {
          if (summary.groups.isEmpty) {
            return EmptyStateView(
              icon: Icons.groups_outlined,
              title: 'Koi group nahi mila',
              subtitle: 'Naya group banayein ya doston ka invite code use karke join karein.',
              actionLabel: '+ NAYA GROUP',
              onAction: () async {
                final group = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.surface,
                  builder: (ctx) => const CreateGroupSheet(),
                );
                if (group != null && context.mounted) {
                  context.push('/chat/${group.id}');
                }
              },
            );
          }

          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: () async => ref.refresh(homeSummaryProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: summary.groups.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = summary.groups[index];
                final net = item.userNetPaise;
                final isLena = net > 0;
                final isDena = net < 0;

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: MonogramAvatar(name: item.group.name, size: 42),
                    title: Text(
                      item.group.name,
                      style: const TextStyle(
                        color: AppColors.textIvory,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Code: ${item.group.inviteCode} • ${item.daysLeft} din baaki',
                        style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              CurrencyFormatter.formatPaise(net.abs()),
                              style: TextStyle(
                                color: isLena
                                    ? AppColors.positive
                                    : isDena
                                        ? AppColors.negative
                                        : AppColors.textMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              isLena ? 'Lena' : isDena ? 'Dena' : 'Barabar',
                              style: TextStyle(
                                color: isLena ? AppColors.positive : isDena ? AppColors.negative : AppColors.textDim,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.info_outline, size: 20, color: AppColors.gold),
                          tooltip: 'Group Details',
                          onPressed: () {
                            context.push('/groups/${item.group.id}');
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      ref.read(activeGroupIdProvider.notifier).state = item.group.id;
                      context.push('/chat/${item.group.id}');
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) context.go('/');
          if (index == 1) return;
          if (index == 2) {
            final activeId = ref.read(activeGroupIdProvider);
            final groups = summaryAsync.asData?.value.groups ?? [];
            final targetId = activeId ?? (groups.isNotEmpty ? groups.first.group.id : null);
            if (targetId != null) {
              context.push('/chat/$targetId');
            }
          }
          if (index == 3) {
            final activeId = ref.read(activeGroupIdProvider);
            final groups = summaryAsync.asData?.value.groups ?? [];
            final targetId = activeId ?? (groups.isNotEmpty ? groups.first.group.id : null);
            if (targetId != null) {
              context.push('/report/$targetId');
            }
          }
        },
      ),
    );
  }
}
