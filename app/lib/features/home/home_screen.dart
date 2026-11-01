import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/chindi_logo.dart';
import '../../core/widgets/custom_bottom_nav.dart';
import '../../core/widgets/gold_button.dart';
import '../../core/widgets/hairline_divider.dart';
import '../../core/widgets/monogram_avatar.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/balance_model.dart';
import '../auth/auth_provider.dart';
import 'home_provider.dart';
import '../../core/services/app_update_service.dart';
import 'widgets/create_group_sheet.dart';
import 'widgets/join_group_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appUpdateServiceProvider).checkAndShowUpdatePopup(context);
    });
  }

  void _openCreateGroup(BuildContext context) async {
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
  }

  void _openJoinGroup(BuildContext context) async {
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
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final summaryAsync = ref.watch(homeSummaryProvider);
    final currentUser = authState.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.9),
            radius: 1.1,
            colors: [
              AppColors.gold.withValues(alpha: 0.12),
              AppColors.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header bar with Chindi Logo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Row(
                  children: [
                    const ChindiLogo(size: 38),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'CHINDI',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2.0,
                                      color: AppColors.goldLight,
                                    ),
                              ),
                            ],
                          ),
                          Text(
                            currentUser != null ? 'Namaste, ${currentUser.name}' : 'Namaste, Sathi',
                            style: const TextStyle(
                              color: AppColors.textIvory,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, size: 20, color: AppColors.textMuted),
                      tooltip: 'Logout',
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              side: const BorderSide(color: AppColors.hairline),
                            ),
                            title: const Text('Logout karein?', style: TextStyle(color: AppColors.textIvory)),
                            content: const Text(
                              'Kya aap waqai Chindi app se logout karna chahte hain?',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Logout', style: TextStyle(color: AppColors.negative)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref.read(authStateProvider.notifier).logout();
                          if (context.mounted) context.go('/login');
                        }
                      },
                    ),
                  ],
                ),
              ),

              const HairlineDivider(),

              // Body with RefreshIndicator
              Expanded(
                child: summaryAsync.when(
                  loading: () => const LoadingView(message: 'Chindi hisaab load ho raha hai...'),
                  error: (err, _) => ErrorRetryView(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(homeSummaryProvider),
                  ),
                  data: (summary) {
                    final netOverall = summary.netOverallPaise;
                    final isPositive = netOverall > 0;
                    final isNegative = netOverall < 0;

                    return RefreshIndicator(
                      color: AppColors.gold,
                      backgroundColor: AppColors.surfaceElevated,
                      onRefresh: () async {
                        ref.invalidate(homeSummaryProvider);
                      },
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        children: [
                          // "Kul lena baaki" Hero Balance Card
                          Container(
                            padding: const EdgeInsets.all(22.0),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadii.lg),
                              border: Border.all(color: AppColors.hairline),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'KUL LENA BAAKI',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: AppColors.textMuted,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.5,
                                          ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isPositive
                                            ? AppColors.positive.withValues(alpha: 0.15)
                                            : isNegative
                                                ? AppColors.negative.withValues(alpha: 0.15)
                                                : AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(AppRadii.sm),
                                        border: Border.all(
                                          color: isPositive
                                              ? AppColors.positive.withValues(alpha: 0.4)
                                              : isNegative
                                                  ? AppColors.negative.withValues(alpha: 0.4)
                                                  : AppColors.hairline,
                                        ),
                                      ),
                                      child: Text(
                                        isPositive
                                            ? 'Aapko lena hai'
                                            : isNegative
                                                ? 'Aapko dena hai'
                                                : 'Barabar',
                                        style: TextStyle(
                                          color: isPositive
                                              ? AppColors.positive
                                              : isNegative
                                                  ? AppColors.negative
                                                  : AppColors.textMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Amount in Playfair Display
                                Text(
                                  CurrencyFormatter.formatPaise(netOverall.abs()),
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                        color: isPositive
                                            ? AppColors.positive
                                            : isNegative
                                                ? AppColors.negative
                                                : AppColors.goldLight,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    Text(
                                      'Kul Lena: ${CurrencyFormatter.formatPaise(summary.kulLenaBaakiPaise)}',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    ),
                                    const SizedBox(width: 16),
                                    Text(
                                      'Kul Dena: ${CurrencyFormatter.formatPaise(summary.kulDenaBaakiPaise)}',
                                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Quick Action Buttons: "+ Naya Group" & "Group Join"
                          Row(
                            children: [
                              Expanded(
                                child: GoldButton(
                                  label: '+ NAYA GROUP',
                                  icon: Icons.add,
                                  onPressed: () => _openCreateGroup(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GoldButton(
                                  label: 'GROUP JOIN',
                                  icon: Icons.login,
                                  isOutlined: true,
                                  onPressed: () => _openJoinGroup(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // Groups Section Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'AAPKE GROUPS',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.2),
                              ),
                              Text(
                                '${summary.groups.length} active',
                                style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (summary.groups.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(28.0),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(AppRadii.md),
                                border: Border.all(color: AppColors.hairline),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.people_outline, size: 40, color: AppColors.gold),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Abhi koi group nahi hai',
                                    style: TextStyle(
                                      color: AppColors.textIvory,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Upar button se naya group banayein ya invite code se join karein.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          else
                            ...summary.groups.map((groupSummary) {
                              return _GroupCard(
                                summary: groupSummary,
                                onTap: () {
                                  ref.read(activeGroupIdProvider.notifier).state = groupSummary.group.id;
                                  context.push('/chat/${groupSummary.group.id}');
                                },
                              );
                            }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) return;
          if (index == 1) context.push('/groups');
          if (index == 2) {
            final activeId = ref.read(activeGroupIdProvider);
            final groups = summaryAsync.asData?.value.groups ?? [];
            final targetId = activeId ?? (groups.isNotEmpty ? groups.first.group.id : null);
            if (targetId != null) {
              context.push('/chat/$targetId');
            } else {
              context.push('/groups');
            }
          }
          if (index == 3) {
            final activeId = ref.read(activeGroupIdProvider);
            final groups = summaryAsync.asData?.value.groups ?? [];
            final targetId = activeId ?? (groups.isNotEmpty ? groups.first.group.id : null);
            if (targetId != null) {
              context.push('/report/$targetId');
            } else {
              context.push('/groups');
            }
          }
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupSummaryItemModel summary;
  final VoidCallback onTap;

  const _GroupCard({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final net = summary.userNetPaise;
    final isLena = net > 0;
    final isDena = net < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                MonogramAvatar(name: summary.group.name, size: 44),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.group.name,
                        style: const TextStyle(
                          color: AppColors.textIvory,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Din ${summary.currentDay} / 30 • ${summary.daysLeft} din baaki',
                            style: const TextStyle(color: AppColors.textDim, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.formatPaise(net.abs()),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isLena
                                ? AppColors.positive
                                : isDena
                                    ? AppColors.negative
                                    : AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isLena
                          ? 'Aapko lena'
                          : isDena
                              ? 'Aapko dena'
                              : 'Hisaab barabar',
                      style: TextStyle(
                        fontSize: 11,
                        color: isLena
                            ? AppColors.positive
                            : isDena
                                ? AppColors.negative
                                : AppColors.textDim,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
