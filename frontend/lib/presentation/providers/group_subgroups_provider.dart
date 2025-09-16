import 'package:flutter/foundation.dart';
import '../../data/models/group_model.dart';
import '../../domain/repositories/group_repository.dart';

class GroupSubgroupsProvider extends ChangeNotifier {
  final GroupRepository _repo;

  GroupSubgroupsProvider(this._repo);

  final Map<int, bool> _subGroupLoadingStates = {};
  final Map<int, String?> _subGroupErrors = {};
  final Map<int, List<GroupSummaryModel>> _subGroupCache = {};

  bool isSubGroupsLoading(int groupId) => _subGroupLoadingStates[groupId] ?? false;
  String? subGroupsError(int groupId) => _subGroupErrors[groupId];
  List<GroupSummaryModel>? getSubGroupsCached(int groupId) => _subGroupCache[groupId];

  Future<void> loadSubGroups(int groupId) async {
    if (_subGroupLoadingStates[groupId] == true) return;
    _subGroupLoadingStates[groupId] = true;
    _subGroupErrors[groupId] = null;
    notifyListeners();

    try {
      final response = await _repo.getSubGroups(groupId);
      if (response.isSuccess && response.data != null) {
        _subGroupCache[groupId] = response.data!;
      } else {
        _subGroupErrors[groupId] =
            response.error?.message ?? '하위 그룹을 불러오는데 실패했습니다.';
        _subGroupCache[groupId] = [];
      }
    } catch (e) {
      _subGroupErrors[groupId] = '하위 그룹을 불러오는 중 오류가 발생했습니다: ${e.toString()}';
      _subGroupCache[groupId] = [];
    }

    _subGroupLoadingStates[groupId] = false;
    notifyListeners();
  }

  void clearSubGroupsCache(int groupId) {
    _subGroupLoadingStates.remove(groupId);
    _subGroupErrors.remove(groupId);
    _subGroupCache.remove(groupId);
    notifyListeners();
  }

  void clearAllCache() {
    _subGroupLoadingStates.clear();
    _subGroupErrors.clear();
    _subGroupCache.clear();
    notifyListeners();
  }
}