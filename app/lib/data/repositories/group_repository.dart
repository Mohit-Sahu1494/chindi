import '../api/api_client.dart';
import '../models/group_model.dart';
import '../models/balance_model.dart';

class GroupRepository {
  final ApiClient _apiClient;

  GroupRepository(this._apiClient);

  Future<GroupModel> createGroup(String name) async {
    final res = await _apiClient.post('/groups', data: {'name': name});
    return GroupModel.fromJson(res);
  }

  Future<GroupModel> joinGroup(String inviteCode) async {
    final res = await _apiClient.post('/groups/join', data: {'inviteCode': inviteCode});
    return GroupModel.fromJson(res);
  }

  Future<GlobalSummaryModel> getGroupsSummary() async {
    final res = await _apiClient.get('/groups');
    return GlobalSummaryModel.fromJson(res);
  }

  Future<({GroupModel group, GroupLiveBalanceModel balances})> getGroupDetails(String groupId) async {
    final res = await _apiClient.get('/groups/$groupId');
    return (
      group: GroupModel.fromJson(res['group']),
      balances: GroupLiveBalanceModel.fromJson(res['balances']),
    );
  }

  Future<void> leaveGroup(String groupId) async {
    await _apiClient.post('/groups/$groupId/leave');
  }
}
