import 'user_model.dart';
import 'expense_model.dart';

class MessageModel {
  final String id;
  final String group;
  final UserModel sender;
  final String type; // 'text' | 'expense'
  final String? text;
  final ExpenseModel? expense;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.group,
    required this.sender,
    required this.type,
    this.text,
    this.expense,
    required this.createdAt,
  });

  bool get isExpense => type == 'expense';

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    UserModel senderModel;
    if (json['sender'] is Map<String, dynamic>) {
      senderModel = UserModel.fromJson(json['sender']);
    } else {
      senderModel = UserModel(
        id: json['sender']?.toString() ?? '',
        name: 'Member',
        emailOrMobile: '',
      );
    }

    ExpenseModel? expenseModel;
    if (json['expense'] is Map<String, dynamic>) {
      expenseModel = ExpenseModel.fromJson(json['expense']);
    }

    return MessageModel(
      id: json['_id'] ?? json['id'] ?? '',
      group: json['group']?.toString() ?? '',
      sender: senderModel,
      type: json['type'] ?? 'text',
      text: json['text'],
      expense: expenseModel,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'group': group,
      'sender': sender.toJson(),
      'type': type,
      'text': text,
      if (expense != null) 'expense': expense!.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
