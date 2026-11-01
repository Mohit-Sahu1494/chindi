import '../api/api_client.dart';
import '../models/message_model.dart';
import '../models/expense_model.dart';

class ChatRepository {
  final ApiClient _apiClient;

  ChatRepository(this._apiClient);

  Future<({List<MessageModel> messages, bool hasMore, int totalCount})> getMessages(
    String groupId, {
    int page = 1,
    int limit = 30,
  }) async {
    final res = await _apiClient.get(
      '/groups/$groupId/messages',
      queryParameters: {'page': page, 'limit': limit},
    );

    final rawList = res['messages'] as List? ?? [];
    final messages = rawList.map((m) => MessageModel.fromJson(m)).toList();
    final pagination = res['pagination'] as Map<String, dynamic>? ?? {};
    final int count = (pagination['totalCount'] as num?)?.toInt() ?? 0;

    return (
      messages: messages,
      hasMore: pagination['hasMore'] == true,
      totalCount: count,
    );
  }

  Future<MessageModel> sendTextMessage(String groupId, String text) async {
    final res = await _apiClient.post(
      '/groups/$groupId/messages',
      data: {'text': text},
    );
    return MessageModel.fromJson(res);
  }

  Future<({ExpenseModel expense, MessageModel message})> createExpense({
    required String groupId,
    required int amountPaise,
    required String description,
    List<String> excludedMembers = const [],
  }) async {
    final res = await _apiClient.post(
      '/groups/$groupId/expenses',
      data: {
        'amountPaise': amountPaise,
        'description': description,
        'excludedMembers': excludedMembers,
      },
    );

    return (
      expense: ExpenseModel.fromJson(res['expense']),
      message: MessageModel.fromJson(res['message']),
    );
  }

  Future<ExpenseModel> updateExpense({
    required String expenseId,
    required int amountPaise,
    required String description,
    List<String> excludedMembers = const [],
  }) async {
    final res = await _apiClient.patch(
      '/expenses/$expenseId',
      data: {
        'amountPaise': amountPaise,
        'description': description,
        'excludedMembers': excludedMembers,
      },
    );
    return ExpenseModel.fromJson(res);
  }

  Future<void> deleteExpense(String expenseId) async {
    await _apiClient.delete('/expenses/$expenseId');
  }
}
