import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/group_model.dart';
import '../../data/models/message_model.dart';
import '../../data/models/balance_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/services/socket_service.dart';
import '../../data/services/notification_service.dart';
import '../auth/auth_provider.dart';
import '../home/home_provider.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ChatRepository(client);
});

class ChatState {
  final String groupId;
  final GroupModel? group;
  final GroupLiveBalanceModel? balances;
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String? error;

  const ChatState({
    required this.groupId,
    this.group,
    this.balances,
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  ChatState copyWith({
    GroupModel? group,
    GroupLiveBalanceModel? balances,
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      groupId: groupId,
      group: group ?? this.group,
      balances: balances ?? this.balances,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final String groupId;
  final ChatRepository _chatRepo;
  final GroupRepository _groupRepo;
  final SocketService _socketService;
  final Ref _ref;

  StreamSubscription? _msgSub;
  StreamSubscription? _expAddedSub;
  StreamSubscription? _expUpdatedSub;
  StreamSubscription? _cycleClosedSub;

  ChatNotifier(
    this.groupId,
    this._chatRepo,
    this._groupRepo,
    this._socketService,
    this._ref,
  ) : super(ChatState(groupId: groupId)) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // 1. Fetch group details & live balances
      final details = await _groupRepo.getGroupDetails(groupId);

      // 2. Fetch initial messages
      final messagesData = await _chatRepo.getMessages(groupId, page: 1, limit: 30);

      state = state.copyWith(
        group: details.group,
        balances: details.balances,
        messages: messagesData.messages,
        hasMore: messagesData.hasMore,
        page: 1,
        isLoading: false,
      );

      // 3. Join Socket room
      _socketService.joinGroupRoom(groupId);

      // 4. Listen to real-time events
      _setupSocketSubscriptions();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _setupSocketSubscriptions() {
    _msgSub?.cancel();
    _msgSub = _socketService.onMessage.listen((newMsg) {
      if (newMsg.group == groupId) {
        // Prevent duplicate messages
        if (!state.messages.any((m) => m.id == newMsg.id)) {
          state = state.copyWith(messages: [...state.messages, newMsg]);

          // Show local heads-up notification if message is from someone else
          final currentUserId = _ref.read(authStateProvider).user?.id;
          if (currentUserId != null && newMsg.sender.id != currentUserId) {
            final groupName = state.group?.name ?? 'Chindi';
            final text = newMsg.isExpense
                ? '${newMsg.sender.name} ne naya kharcha joda: ${newMsg.text ?? ""}'
                : '${newMsg.sender.name}: ${newMsg.text ?? ""}';
            NotificationService().showLocalNotification(
              id: newMsg.id.hashCode,
              title: groupName,
              body: text,
              payload: jsonEncode({'groupId': groupId}),
            );
          }
        }
      }
    });

    _expAddedSub?.cancel();
    _expAddedSub = _socketService.onExpenseAdded.listen((data) {
      _refreshBalances();
    });

    _expUpdatedSub?.cancel();
    _expUpdatedSub = _socketService.onExpenseUpdated.listen((data) {
      _refreshBalances();
      _reloadMessages();
    });

    _cycleClosedSub?.cancel();
    _cycleClosedSub = _socketService.onCycleClosed.listen((data) {
      _refreshBalances();
      _reloadMessages();
    });
  }

  Future<void> _refreshBalances() async {
    try {
      final details = await _groupRepo.getGroupDetails(groupId);
      state = state.copyWith(group: details.group, balances: details.balances);
      _ref.invalidate(homeSummaryProvider);
    } catch (e) {
      debugPrint('[Chat] Error refreshing balances: $e');
    }
  }

  Future<void> _reloadMessages() async {
    try {
      final messagesData = await _chatRepo.getMessages(groupId, page: 1, limit: 30);
      state = state.copyWith(
        messages: messagesData.messages,
        hasMore: messagesData.hasMore,
        page: 1,
      );
    } catch (_) {}
  }

  Future<void> loadMoreMessages() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final messagesData = await _chatRepo.getMessages(groupId, page: nextPage, limit: 30);

      // Prepend older messages
      final existingIds = Set<String>.from(state.messages.map((m) => m.id));
      final newOlderMessages = messagesData.messages.where((m) => !existingIds.contains(m.id)).toList();

      state = state.copyWith(
        messages: [...newOlderMessages, ...state.messages],
        page: nextPage,
        hasMore: messagesData.hasMore,
        isLoadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<bool> sendTextMessage(String text) async {
    if (text.trim().isEmpty) return false;
    try {
      final message = await _chatRepo.sendTextMessage(groupId, text);
      if (!state.messages.any((m) => m.id == message.id)) {
        state = state.copyWith(messages: [...state.messages, message]);
      }
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> addExpense({
    required int amountPaise,
    required String description,
    List<String> excludedMembers = const [],
  }) async {
    try {
      final result = await _chatRepo.createExpense(
        groupId: groupId,
        amountPaise: amountPaise,
        description: description,
        excludedMembers: excludedMembers,
      );

      if (!state.messages.any((m) => m.id == result.message.id)) {
        state = state.copyWith(messages: [...state.messages, result.message]);
      }
      await _refreshBalances();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateExpense({
    required String expenseId,
    required int amountPaise,
    required String description,
    List<String> excludedMembers = const [],
  }) async {
    try {
      await _chatRepo.updateExpense(
        expenseId: expenseId,
        amountPaise: amountPaise,
        description: description,
        excludedMembers: excludedMembers,
      );
      await _reloadMessages();
      await _refreshBalances();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    try {
      await _chatRepo.deleteExpense(expenseId);
      await _reloadMessages();
      await _refreshBalances();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _socketService.leaveGroupRoom(groupId);
    _msgSub?.cancel();
    _expAddedSub?.cancel();
    _expUpdatedSub?.cancel();
    _cycleClosedSub?.cancel();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider.autoDispose.family<ChatNotifier, ChatState, String>(
  (ref, groupId) {
    final chatRepo = ref.watch(chatRepositoryProvider);
    final groupRepo = ref.watch(groupRepositoryProvider);
    final socketService = ref.watch(socketServiceProvider);
    return ChatNotifier(
      groupId,
      chatRepo,
      groupRepo,
      socketService,
      ref,
    );
  },
);
