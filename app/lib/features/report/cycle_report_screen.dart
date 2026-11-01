import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/gold_button.dart';
import '../../core/widgets/hairline_divider.dart';
import '../../core/widgets/monogram_avatar.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_provider.dart';
import '../groups/group_detail_screen.dart';
import 'cycle_provider.dart';

class CycleReportScreen extends ConsumerWidget {
  final String groupId;

  const CycleReportScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(currentCycleReportProvider(groupId));
    final groupAsync = ref.watch(groupDetailProvider(groupId));
    final currentUserId = ref.watch(authStateProvider).user?.id;
    final isAdmin = groupAsync.asData?.value.group.admin?.id == currentUserId;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('30-Din Hisaab'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.gold),
            tooltip: 'Purani History',
            onPressed: () {
              context.push('/report/$groupId/history');
            },
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const LoadingView(message: 'Hisaab report taiyar ho rahi hai...'),
        error: (err, _) => ErrorRetryView(
          message: err.toString(),
          onRetry: () => ref.refresh(currentCycleReportProvider(groupId)),
        ),
        data: (live) {
          final progress = (live.currentDay / 30.0).clamp(0.0, 1.0);

          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: () async {
              ref.invalidate(currentCycleReportProvider(groupId));
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Hero Card: Total Spend
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.lg),
                    border: Border.all(color: AppColors.hairline),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CURRENT 30-DAY CYCLE',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.5),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                              border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              'Cycle #${live.cycle?.cycleNumber ?? 1}',
                              style: const TextStyle(
                                color: AppColors.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Total Group Spend',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatPaise(live.totalPaise),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: AppColors.goldLight,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 20),

                      // Cycle Progress Bar: "Din X / 30"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Din ${live.currentDay} / 30',
                            style: const TextStyle(
                              color: AppColors.textIvory,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${live.daysLeft} din baaki',
                            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                        ),
                      ),
                      if (live.cycle != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          '${DateFormatter.formatShortDate(live.cycle!.startDate)} se ${DateFormatter.formatDate(live.cycle!.endDate)} tak',
                          style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Per-user balances section
                Text(
                  'SADASYA HISAAAB (PER USER BREAKDOWN)',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
                ),
                const SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: live.perUser.length,
                    separatorBuilder: (_, _) => const HairlineDivider(indent: 56),
                    itemBuilder: (ctx, idx) {
                      final item = live.perUser[idx];
                      final isMe = currentUserId != null && item.user.id == currentUserId;
                      final net = item.netPaise;
                      final isLena = net > 0;
                      final isDena = net < 0;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: MonogramAvatar(name: item.user.name, size: 38),
                        title: Text(
                          isMe ? '${item.user.name} (Aap)' : item.user.name,
                          style: TextStyle(
                            color: isMe ? AppColors.goldLight : AppColors.textIvory,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Diya: ${CurrencyFormatter.formatPaise(item.paidPaise)} • Share: ${CurrencyFormatter.formatPaise(item.sharePaise)}',
                            style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                          ),
                        ),
                        trailing: Column(
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
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              isLena
                                  ? 'Lena hai'
                                  : isDena
                                      ? 'Dena hai'
                                      : 'Barabar',
                              style: TextStyle(
                                color: isLena ? AppColors.positive : isDena ? AppColors.negative : AppColors.textDim,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Simplified Settlements section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SUGGESTED SETTLEMENTS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
                    ),
                    Text(
                      '${live.settlements.length} transactions',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (live.settlements.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: const Center(
                      child: Text(
                        'Koi lena-dena baaki nahi hai! Saara hisaab barabar hai.',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...live.settlements.map((settlement) {
                    final isFromMe = currentUserId != null && settlement.from.id == currentUserId;
                    final isToMe = currentUserId != null && settlement.to.id == currentUserId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: (isFromMe || isToMe)
                              ? AppColors.gold.withValues(alpha: 0.35)
                              : AppColors.hairline,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  isFromMe ? 'Aap' : settlement.from.name,
                                  style: TextStyle(
                                    color: isFromMe ? AppColors.negative : AppColors.textIvory,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Icon(Icons.arrow_forward, size: 14, color: AppColors.gold),
                                ),
                                Text(
                                  isToMe ? 'Aap' : settlement.to.name,
                                  style: TextStyle(
                                    color: isToMe ? AppColors.positive : AppColors.textIvory,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatPaise(settlement.amountPaise),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.goldLight,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 28),

                // Button: Purani History Dekhein
                OutlinedButton.icon(
                  icon: const Icon(Icons.history, color: AppColors.gold, size: 18),
                  label: const Text(
                    'Purani history dekhein (Past Cycles)',
                    style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.hairlineActive),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
                  ),
                  onPressed: () {
                    context.push('/report/$groupId/history');
                  },
                ),
                const SizedBox(height: 16),

                // Admin Close Cycle Early Button
                if (isAdmin)
                  GoldButton(
                    label: 'CYCLE SAMAPT KAREIN (CLOSE CYCLE)',
                    icon: Icons.lock_clock_outlined,
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            side: const BorderSide(color: AppColors.hairline),
                          ),
                          title: const Text('Cycle band karein?', style: TextStyle(color: AppColors.textIvory)),
                          content: const Text(
                            'Cycle band karne par vartaman hisaab ka pakka snapshot save ho jayega, aur 0 balance ke saath agla 30-din cycle shuru ho jayega.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Haan, Band karein', style: TextStyle(color: AppColors.gold)),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && context.mounted) {
                        final success = await ref.read(cycleActionProvider.notifier).closeCycleEarly(groupId);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cycle band ho gaya! Naya cycle shuru hua.'),
                            ),
                          );
                        } else if (context.mounted) {
                          final err = ref.read(cycleActionProvider).error;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(err?.toString() ?? 'Cycle band karne mein samasya aayi'),
                              backgroundColor: AppColors.negative,
                            ),
                          );
                        }
                      }
                    },
                  ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
