import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/widgets/expense_card.dart';
import '../../core/widgets/monogram_avatar.dart';
import '../../core/widgets/state_views.dart';
import '../../data/models/expense_model.dart';
import '../auth/auth_provider.dart';
import 'chat_provider.dart';
import 'widgets/add_expense_bottom_bar.dart';
import 'widgets/edit_expense_sheet.dart';
import 'widgets/message_bubble.dart';

class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Scroll up pagination: when nearing top of scroll view
    if (_scrollController.position.pixels <= _scrollController.position.minScrollExtent + 80) {
      ref.read(chatProvider(widget.groupId).notifier).loadMoreMessages();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _openEditExpense(ExpenseModel expense, List members, String? currentUserId) async {
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) => EditExpenseSheet(
        expense: expense,
        members: members.cast(),
        currentUserId: currentUserId,
        onUpdate: ({
          required int amountPaise,
          required String description,
          required List<String> excludedMembers,
        }) async {
          return await ref.read(chatProvider(widget.groupId).notifier).updateExpense(
                expenseId: expense.id,
                amountPaise: amountPaise,
                description: description,
                excludedMembers: excludedMembers,
              );
        },
      ),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kharcha safaltapoorvak badal diya gaya!')),
      );
    }
  }

  void _confirmDeleteExpense(String expenseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          side: const BorderSide(color: AppColors.hairline),
        ),
        title: const Text('Kharcha hatayein?', style: TextStyle(color: AppColors.textIvory)),
        content: const Text(
          'Kya aap is kharche ko delete karna chahte hain? Hisaab dobara calculate hoga.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.negative)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ref.read(chatProvider(widget.groupId).notifier).deleteExpense(expenseId);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kharcha hata diya gaya')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.groupId));
    final currentUserId = ref.watch(authStateProvider).user?.id;

    final group = chatState.group;
    final balances = chatState.balances;
    final members = group?.members ?? [];

    // Trigger auto-scroll on new message and show error snackbar
    ref.listen(chatProvider(widget.groupId), (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.negative,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
        title: InkWell(
          onTap: () => context.push('/groups/${widget.groupId}'),
          child: Row(
            children: [
              MonogramAvatar(name: group?.name ?? 'Group', size: 36),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group?.name ?? 'Group Chat',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textIvory,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      balances != null
                          ? 'Din ${balances.currentDay} / 30 • Total: ${CurrencyFormatter.formatPaise(balances.totalPaise)}'
                          : '${members.length} members',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // 30-Day Hisaab Report Button
          IconButton(
            icon: const Icon(Icons.bar_chart, color: AppColors.gold),
            tooltip: '30-Din Hisaab (Report)',
            onPressed: () {
              context.push('/report/${widget.groupId}');
            },
          ),
          // Group Details
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.textMuted),
            tooltip: 'Group Details',
            onPressed: () {
              context.push('/groups/${widget.groupId}');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1, thickness: 0.8, color: AppColors.hairline),

          // Chat Messages area
          Expanded(
            child: chatState.isLoading
                ? const LoadingView(message: 'Chat shuru ho rahi hai...')
                : chatState.error != null && chatState.messages.isEmpty
                    ? ErrorRetryView(
                        message: chatState.error!,
                        onRetry: () => ref.read(chatProvider(widget.groupId).notifier).init(),
                      )
                    : chatState.messages.isEmpty
                        ? EmptyStateView(
                            icon: Icons.chat_bubble_outline,
                            title: 'Chat khali hai',
                            subtitle:
                                'Neeche "+ KHARCHA" dabakar pehla kharcha jodein ya message bhejein.',
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            itemCount: chatState.messages.length + (chatState.isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (chatState.isLoadingMore && index == 0) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                                    ),
                                  ),
                                );
                              }

                              final actualIndex = chatState.isLoadingMore ? index - 1 : index;
                              final msg = chatState.messages[actualIndex];
                              final isMe = currentUserId != null && msg.sender.id == currentUserId;

                              if (msg.isExpense && msg.expense != null) {
                                return ExpenseCard(
                                  expense: msg.expense!,
                                  currentUserId: currentUserId,
                                  onEdit: () => _openEditExpense(msg.expense!, members, currentUserId),
                                  onDelete: () => _confirmDeleteExpense(msg.expense!.id),
                                );
                              }

                              return MessageBubble(
                                message: msg,
                                isMe: isMe,
                              );
                            },
                          ),
          ),

          // Add Expense / Text Message input bar
          AddExpenseBottomBar(
            members: members,
            currentUserId: currentUserId,
            onAddExpense: ({
              required int amountPaise,
              required String description,
              required List<String> excludedMembers,
            }) async {
              return await ref.read(chatProvider(widget.groupId).notifier).addExpense(
                    amountPaise: amountPaise,
                    description: description,
                    excludedMembers: excludedMembers,
                  );
            },
            onSendText: (text) async {
              return await ref.read(chatProvider(widget.groupId).notifier).sendTextMessage(text);
            },
          ),
        ],
      ),
    );
  }
}
