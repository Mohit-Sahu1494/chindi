import '../api/api_client.dart';
import '../models/cycle_model.dart';
import '../models/balance_model.dart';

class CycleRepository {
  final ApiClient _apiClient;

  CycleRepository(this._apiClient);

  Future<GroupLiveBalanceModel> getCurrentCycle(String groupId) async {
    final res = await _apiClient.get('/groups/$groupId/cycle/current');
    return GroupLiveBalanceModel.fromJson(res);
  }

  Future<List<CycleModel>> getGroupCyclesHistory(String groupId) async {
    final res = await _apiClient.get('/groups/$groupId/cycles');
    final list = res as List? ?? [];
    return list.map((c) => CycleModel.fromJson(c)).toList();
  }

  Future<CycleModel> getCycleById(String cycleId) async {
    final res = await _apiClient.get('/cycles/$cycleId');
    return CycleModel.fromJson(res);
  }

  Future<void> closeCycleEarly(String groupId) async {
    await _apiClient.post('/groups/$groupId/cycle/close');
  }
}
