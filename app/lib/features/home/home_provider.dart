import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/balance_model.dart';
import '../../data/models/group_model.dart';
import '../../data/repositories/group_repository.dart';
import '../auth/auth_provider.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return GroupRepository(client);
});

final homeSummaryProvider = FutureProvider.autoDispose<GlobalSummaryModel>((ref) async {
  final repo = ref.watch(groupRepositoryProvider);
  return await repo.getGroupsSummary();
});

// Active group selection provider for quick switching across tabs
final activeGroupIdProvider = StateProvider<String?>((ref) => null);

class GroupActionNotifier extends StateNotifier<AsyncValue<void>> {
  final GroupRepository _repository;
  final Ref _ref;

  GroupActionNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<GroupModel?> createGroup(String name) async {
    state = const AsyncValue.loading();
    try {
      final group = await _repository.createGroup(name);
      state = const AsyncValue.data(null);
      _ref.invalidate(homeSummaryProvider);
      return group;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<GroupModel?> joinGroup(String inviteCode) async {
    state = const AsyncValue.loading();
    try {
      final group = await _repository.joinGroup(inviteCode);
      state = const AsyncValue.data(null);
      _ref.invalidate(homeSummaryProvider);
      return group;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> leaveGroup(String groupId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.leaveGroup(groupId);
      state = const AsyncValue.data(null);
      _ref.invalidate(homeSummaryProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final groupActionProvider = StateNotifierProvider<GroupActionNotifier, AsyncValue<void>>((ref) {
  final repo = ref.watch(groupRepositoryProvider);
  return GroupActionNotifier(repo, ref);
});
