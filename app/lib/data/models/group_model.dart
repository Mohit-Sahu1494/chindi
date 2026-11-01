import 'user_model.dart';

class GroupModel {
  final String id;
  final String name;
  final String inviteCode;
  final UserModel? admin;
  final List<UserModel> members;
  final String? currentCycleId;
  final DateTime? createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    this.admin,
    required this.members,
    this.currentCycleId,
    this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    UserModel? adminUser;
    if (json['admin'] is Map<String, dynamic>) {
      adminUser = UserModel.fromJson(json['admin']);
    } else if (json['admin'] is String) {
      adminUser = UserModel(
        id: json['admin'],
        name: 'Admin',
        emailOrMobile: '',
      );
    }

    final membersList = <UserModel>[];
    if (json['members'] is List) {
      for (final m in json['members']) {
        if (m is Map<String, dynamic>) {
          membersList.add(UserModel.fromJson(m));
        } else if (m is String) {
          membersList.add(UserModel(id: m, name: 'Member', emailOrMobile: ''));
        }
      }
    }

    return GroupModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      inviteCode: json['inviteCode'] ?? '',
      admin: adminUser,
      members: membersList,
      currentCycleId: json['currentCycle'] is String
          ? json['currentCycle']
          : (json['currentCycle'] is Map ? json['currentCycle']['_id'] : null),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'inviteCode': inviteCode,
      'admin': admin?.toJson(),
      'members': members.map((m) => m.toJson()).toList(),
      if (currentCycleId != null) 'currentCycle': currentCycleId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
