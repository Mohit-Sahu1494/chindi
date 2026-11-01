import 'user_model.dart';

class CycleUserSnapshot {
  final UserModel user;
  final int paidPaise;
  final int sharePaise;
  final int netPaise;

  const CycleUserSnapshot({
    required this.user,
    required this.paidPaise,
    required this.sharePaise,
    required this.netPaise,
  });

  factory CycleUserSnapshot.fromJson(Map<String, dynamic> json) {
    UserModel userModel;
    if (json['user'] is Map<String, dynamic>) {
      userModel = UserModel.fromJson(json['user']);
    } else {
      userModel = UserModel(
        id: json['user']?.toString() ?? '',
        name: 'User',
        emailOrMobile: '',
      );
    }

    return CycleUserSnapshot(
      user: userModel,
      paidPaise: json['paidPaise'] ?? 0,
      sharePaise: json['sharePaise'] ?? 0,
      netPaise: json['netPaise'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'paidPaise': paidPaise,
      'sharePaise': sharePaise,
      'netPaise': netPaise,
    };
  }
}

class CycleSettlementSnapshot {
  final UserModel from;
  final UserModel to;
  final int amountPaise;

  const CycleSettlementSnapshot({
    required this.from,
    required this.to,
    required this.amountPaise,
  });

  factory CycleSettlementSnapshot.fromJson(Map<String, dynamic> json) {
    UserModel fromUser;
    if (json['from'] is Map<String, dynamic>) {
      fromUser = UserModel.fromJson(json['from']);
    } else {
      fromUser = UserModel(
        id: json['from']?.toString() ?? '',
        name: 'User',
        emailOrMobile: '',
      );
    }

    UserModel toUser;
    if (json['to'] is Map<String, dynamic>) {
      toUser = UserModel.fromJson(json['to']);
    } else {
      toUser = UserModel(
        id: json['to']?.toString() ?? '',
        name: 'User',
        emailOrMobile: '',
      );
    }

    return CycleSettlementSnapshot(
      from: fromUser,
      to: toUser,
      amountPaise: json['amountPaise'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from.toJson(),
      'to': to.toJson(),
      'amountPaise': amountPaise,
    };
  }
}

class CycleSnapshotModel {
  final int totalPaise;
  final List<CycleUserSnapshot> perUser;
  final List<CycleSettlementSnapshot> settlements;

  const CycleSnapshotModel({
    required this.totalPaise,
    required this.perUser,
    required this.settlements,
  });

  factory CycleSnapshotModel.fromJson(Map<String, dynamic> json) {
    final perUserList = <CycleUserSnapshot>[];
    if (json['perUser'] is List) {
      for (final item in json['perUser']) {
        if (item is Map<String, dynamic>) {
          perUserList.add(CycleUserSnapshot.fromJson(item));
        }
      }
    }

    final settlementsList = <CycleSettlementSnapshot>[];
    if (json['settlements'] is List) {
      for (final item in json['settlements']) {
        if (item is Map<String, dynamic>) {
          settlementsList.add(CycleSettlementSnapshot.fromJson(item));
        }
      }
    }

    return CycleSnapshotModel(
      totalPaise: json['totalPaise'] ?? 0,
      perUser: perUserList,
      settlements: settlementsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalPaise': totalPaise,
      'perUser': perUser.map((u) => u.toJson()).toList(),
      'settlements': settlements.map((s) => s.toJson()).toList(),
    };
  }
}

class CycleModel {
  final String id;
  final String group;
  final int cycleNumber;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime? closedAt;
  final CycleSnapshotModel? snapshot;

  const CycleModel({
    required this.id,
    required this.group,
    required this.cycleNumber,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.closedAt,
    this.snapshot,
  });

  factory CycleModel.fromJson(Map<String, dynamic> json) {
    return CycleModel(
      id: json['_id'] ?? json['id'] ?? '',
      group: json['group']?.toString() ?? '',
      cycleNumber: json['cycleNumber'] ?? 1,
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ??
          DateTime.now().add(const Duration(days: 30)),
      status: json['status'] ?? 'open',
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'].toString())
          : null,
      snapshot: json['snapshot'] != null && json['snapshot'] is Map<String, dynamic>
          ? CycleSnapshotModel.fromJson(json['snapshot'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'group': group,
      'cycleNumber': cycleNumber,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      if (closedAt != null) 'closedAt': closedAt!.toIso8601String(),
      if (snapshot != null) 'snapshot': snapshot!.toJson(),
    };
  }
}
