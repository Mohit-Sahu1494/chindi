import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/balance_model.dart';
import '../../data/models/cycle_model.dart';
import '../../data/repositories/cycle_repository.dart';
import '../auth/auth_provider.dart';
import '../home/home_provider.dart';

final cycleRepositoryProvider = Provider<CycleRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return CycleRepository(client);
});

final currentCycleReportProvider =
    FutureProvider.autoDispose.family<GroupLiveBalanceModel, String>((ref, groupId) async {
  final repo = ref.watch(cycleRepositoryProvider);
  return await repo.getCurrentCycle(groupId);
});

final pastCyclesHistoryProvider =
    FutureProvider.autoDispose.family<List<CycleModel>, String>((ref, groupId) async {
  final repo = ref.watch(cycleRepositoryProvider);
  return await repo.getGroupCyclesHistory(groupId);
});

final pastCycleDetailProvider =
    FutureProvider.autoDispose.family<CycleModel, String>((ref, cycleId) async {
  final repo = ref.watch(cycleRepositoryProvider);
  return await repo.getCycleById(cycleId);
});

class CycleActionNotifier extends StateNotifier<AsyncValue<void>> {
  final CycleRepository _repository;
  final Ref _ref;

  CycleActionNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> closeCycleEarly(String groupId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.closeCycleEarly(groupId);
      state = const AsyncValue.data(null);
      _ref.invalidate(currentCycleReportProvider(groupId));
      _ref.invalidate(pastCyclesHistoryProvider(groupId));
      _ref.invalidate(homeSummaryProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final cycleActionProvider = StateNotifierProvider<CycleActionNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(cycleRepositoryProvider);
  return CycleActionNotifier(repo, ref);
});
