import 'group_model.dart';
import 'cycle_model.dart';

class GroupLiveBalanceModel {
  final CycleModel? cycle;
  final int currentDay;
  final int daysTotal;
  final int daysLeft;
  final int totalPaise;
  final List<CycleUserSnapshot> perUser;
  final List<CycleSettlementSnapshot> settlements;

  const GroupLiveBalanceModel({
    this.cycle,
    required this.currentDay,
    required this.daysTotal,
    required this.daysLeft,
    required this.totalPaise,
    required this.perUser,
    required this.settlements,
  });

  factory GroupLiveBalanceModel.fromJson(Map<String, dynamic> json) {
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

    return GroupLiveBalanceModel(
      cycle: json['cycle'] is Map<String, dynamic>
          ? CycleModel.fromJson(json['cycle'])
          : null,
      currentDay: json['currentDay'] ?? 1,
      daysTotal: json['daysTotal'] ?? 30,
      daysLeft: json['daysLeft'] ?? 30,
      totalPaise: json['totalPaise'] ?? 0,
      perUser: perUserList,
      settlements: settlementsList,
    );
  }
}

class GroupSummaryItemModel {
  final GroupModel group;
  final CycleModel? cycle;
  final int daysLeft;
  final int currentDay;
  final int totalGroupSpendPaise;
  final int userNetPaise;
  final int userPaidPaise;
  final int userSharePaise;

  const GroupSummaryItemModel({
    required this.group,
    this.cycle,
    required this.daysLeft,
    required this.currentDay,
    required this.totalGroupSpendPaise,
    required this.userNetPaise,
    required this.userPaidPaise,
    required this.userSharePaise,
  });

  factory GroupSummaryItemModel.fromJson(Map<String, dynamic> json) {
    return GroupSummaryItemModel(
      group: GroupModel.fromJson(json['group'] ?? {}),
      cycle: json['cycle'] is Map<String, dynamic>
          ? CycleModel.fromJson(json['cycle'])
          : null,
      daysLeft: json['daysLeft'] ?? 30,
      currentDay: json['currentDay'] ?? 1,
      totalGroupSpendPaise: json['totalGroupSpendPaise'] ?? 0,
      userNetPaise: json['userNetPaise'] ?? 0,
      userPaidPaise: json['userPaidPaise'] ?? 0,
      userSharePaise: json['userSharePaise'] ?? 0,
    );
  }
}

class GlobalSummaryModel {
  final int kulLenaBaakiPaise;
  final int kulDenaBaakiPaise;
  final int netOverallPaise;
  final List<GroupSummaryItemModel> groups;

  const GlobalSummaryModel({
    required this.kulLenaBaakiPaise,
    required this.kulDenaBaakiPaise,
    required this.netOverallPaise,
    required this.groups,
  });

  factory GlobalSummaryModel.fromJson(Map<String, dynamic> json) {
    final groupsList = <GroupSummaryItemModel>[];
    if (json['groups'] is List) {
      for (final g in json['groups']) {
        if (g is Map<String, dynamic>) {
          groupsList.add(GroupSummaryItemModel.fromJson(g));
        }
      }
    }

    return GlobalSummaryModel(
      kulLenaBaakiPaise: json['kulLenaBaakiPaise'] ?? 0,
      kulDenaBaakiPaise: json['kulDenaBaakiPaise'] ?? 0,
      netOverallPaise: json['netOverallPaise'] ?? 0,
      groups: groupsList,
    );
  }
}
