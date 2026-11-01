import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/widgets/state_views.dart';
import 'cycle_provider.dart';

class PastCyclesScreen extends ConsumerWidget {
  final String groupId;

  const PastCyclesScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(pastCyclesHistoryProvider(groupId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Purani Cycles History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
      ),
      body: historyAsync.when(
        loading: () => const LoadingView(message: 'History load ho rahi hai...'),
        error: (err, _) => ErrorRetryView(
          message: err.toString(),
          onRetry: () => ref.refresh(pastCyclesHistoryProvider(groupId)),
        ),
        data: (cycles) {
          if (cycles.isEmpty) {
            return const EmptyStateView(
              icon: Icons.history,
              title: 'Purani cycle history nahi hai',
              subtitle: 'Jab vartaman 30 din cycle poori hogi, uski summary yahan dikhai degi.',
            );
          }

          return RefreshIndicator(
            color: AppColors.gold,
            onRefresh: () async => ref.refresh(pastCyclesHistoryProvider(groupId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: cycles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) {
                final cycle = cycles[idx];
                final totalPaise = cycle.snapshot?.totalPaise ?? 0;
                final settlementsCount = cycle.snapshot?.settlements.length ?? 0;

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cycle #${cycle.cycleNumber}',
                          style: const TextStyle(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatPaise(totalPaise),
                          style: const TextStyle(
                            color: AppColors.textIvory,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormatter.formatDate(cycle.startDate)} - ${DateFormatter.formatDate(cycle.endDate)}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$settlementsCount settlements recorded',
                            style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.gold, size: 20),
                    onTap: () {
                      context.push('/cycles/${cycle.id}');
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
