import 'user_model.dart';

class ExpenseShareModel {
  final UserModel user;
  final int amountPaise;

  const ExpenseShareModel({
    required this.user,
    required this.amountPaise,
  });

  factory ExpenseShareModel.fromJson(Map<String, dynamic> json) {
    UserModel userModel;
    if (json['user'] is Map<String, dynamic>) {
      userModel = UserModel.fromJson(json['user']);
    } else {
      userModel = UserModel(
        id: json['user']?.toString() ?? '',
        name: 'Member',
        emailOrMobile: '',
      );
    }
    return ExpenseShareModel(
      user: userModel,
      amountPaise: json['amountPaise'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'amountPaise': amountPaise,
    };
  }
}

class ExpenseModel {
  final String id;
  final String group;
  final String cycle;
  final UserModel paidBy;
  final int amountPaise;
  final String description;
  final List<UserModel> excludedMembers;
  final List<UserModel> participants;
  final List<ExpenseShareModel> shares;
  final bool isDeleted;
  final DateTime createdAt;

  const ExpenseModel({
    required this.id,
    required this.group,
    required this.cycle,
    required this.paidBy,
    required this.amountPaise,
    required this.description,
    required this.excludedMembers,
    required this.participants,
    required this.shares,
    required this.isDeleted,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    UserModel parseUser(dynamic userObj) {
      if (userObj is Map<String, dynamic>) {
        return UserModel.fromJson(userObj);
      }
      return UserModel(
        id: userObj?.toString() ?? '',
        name: 'Member',
        emailOrMobile: '',
      );
    }

    final excludedList = <UserModel>[];
    if (json['excludedMembers'] is List) {
      for (final item in json['excludedMembers']) {
        excludedList.add(parseUser(item));
      }
    }

    final participantsList = <UserModel>[];
    if (json['participants'] is List) {
      for (final item in json['participants']) {
        participantsList.add(parseUser(item));
      }
    }

    final sharesList = <ExpenseShareModel>[];
    if (json['shares'] is List) {
      for (final item in json['shares']) {
        if (item is Map<String, dynamic>) {
          sharesList.add(ExpenseShareModel.fromJson(item));
        }
      }
    }

    return ExpenseModel(
      id: json['_id'] ?? json['id'] ?? '',
      group: json['group']?.toString() ?? '',
      cycle: json['cycle']?.toString() ?? '',
      paidBy: parseUser(json['paidBy']),
      amountPaise: json['amountPaise'] ?? 0,
      description: json['description'] ?? '',
      excludedMembers: excludedList,
      participants: participantsList,
      shares: sharesList,
      isDeleted: json['isDeleted'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'group': group,
      'cycle': cycle,
      'paidBy': paidBy.toJson(),
      'amountPaise': amountPaise,
      'description': description,
      'excludedMembers': excludedMembers.map((u) => u.toJson()).toList(),
      'participants': participants.map((u) => u.toJson()).toList(),
      'shares': shares.map((s) => s.toJson()).toList(),
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Helper to get individual share for a participant in paise
  int get individualSharePaise {
    if (shares.isEmpty) return 0;
    return shares.first.amountPaise;
  }
}
