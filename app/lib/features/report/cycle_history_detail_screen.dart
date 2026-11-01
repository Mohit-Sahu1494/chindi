import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/hairline_divider.dart';
import '../../core/widgets/monogram_avatar.dart';
import '../../core/widgets/state_views.dart';
import 'cycle_provider.dart';

class CycleHistoryDetailScreen extends ConsumerWidget {
  final String cycleId;

  const CycleHistoryDetailScreen({super.key, required this.cycleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycleAsync = ref.watch(pastCycleDetailProvider(cycleId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Past Cycle Record'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
      ),
      body: cycleAsync.when(
        loading: () => const LoadingView(message: 'Record load ho raha hai...'),
        error: (err, _) => ErrorRetryView(
          message: err.toString(),
          onRetry: () => ref.refresh(pastCycleDetailProvider(cycleId)),
        ),
        data: (cycle) {
          final snapshot = cycle.snapshot;
          final totalPaise = snapshot?.totalPaise ?? 0;
          final perUser = snapshot?.perUser ?? [];
          final settlements = snapshot?.settlements ?? [];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CYCLE #${cycle.cycleNumber} (CLOSED)',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        if (cycle.closedAt != null)
                          Text(
                            'Closed: ${DateFormatter.formatDate(cycle.closedAt!)}',
                            style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Total Group Spend', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.formatPaise(totalPaise),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${DateFormatter.formatDate(cycle.startDate)} se ${DateFormatter.formatDate(cycle.endDate)} tak',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Per-user breakdown
              Text('PER-USER HISAAAB', style: Theme.of(context).textTheme.labelSmall),
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
                  itemCount: perUser.length,
                  separatorBuilder: (_, _) => const HairlineDivider(indent: 56),
                  itemBuilder: (ctx, idx) {
                    final item = perUser[idx];
                    final net = item.netPaise;
                    final isLena = net > 0;
                    final isDena = net < 0;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: MonogramAvatar(name: item.user.name, size: 36),
                      title: Text(
                        item.user.name,
                        style: const TextStyle(color: AppColors.textIvory, fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Diya: ${CurrencyFormatter.formatPaise(item.paidPaise)} • Share: ${CurrencyFormatter.formatPaise(item.sharePaise)}',
                        style: const TextStyle(color: AppColors.textDim, fontSize: 11),
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
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            isLena ? 'Lena tha' : isDena ? 'Dena tha' : 'Barabar',
                            style: TextStyle(
                              color: isLena ? AppColors.positive : isDena ? AppColors.negative : AppColors.textDim,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Settlements
              Text('SETTLEMENTS LIST', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 10),
              if (settlements.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: const Center(
                    child: Text('Koi transactions nahi the.', style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              else
                ...settlements.map((s) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${s.from.name} -> ${s.to.name}',
                            style: const TextStyle(color: AppColors.textIvory, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatPaise(s.amountPaise),
                          style: const TextStyle(color: AppColors.goldLight, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
