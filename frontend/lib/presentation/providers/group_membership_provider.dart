import 'package:flutter/foundation.dart';
import '../../domain/repositories/group_repository.dart';

class GroupMembershipProvider extends ChangeNotifier {
  final GroupRepository _repo;

  GroupMembershipProvider(this._repo);

  final Set<int> _myGroupIds = <int>{};
  Set<int> get myGroupIds => _myGroupIds;

  bool isMemberOf(int groupId) => _myGroupIds.contains(groupId);

  Future<void> loadMembershipForGroups(List<int> groupIds) async {
    _myGroupIds.clear();

    try {
      final response = await _repo.checkBatchGroupMembership(groupIds);
      if (response.isSuccess && response.data != null) {
        for (final entry in response.data!.entries) {
          if (entry.value) {
            _myGroupIds.add(entry.key);
          }
        }
      }
    } catch (_) {
      // Fallback to sequential calls if batch fails
      for (final id in groupIds) {
        try {
          final response = await _repo.checkGroupMembership(id);
          if (response.isSuccess && response.data == true) {
            _myGroupIds.add(id);
          }
        } catch (_) {
          // Silently fail for individual membership checks
        }
      }
    }

    notifyListeners();
  }

  Future<bool> checkGroupMembership(int groupId) async {
    try {
      final response = await _repo.checkGroupMembership(groupId);
      final isMember = response.isSuccess && response.data == true;

      if (isMember) {
        _myGroupIds.add(groupId);
      } else {
        _myGroupIds.remove(groupId);
      }

      notifyListeners();
      return isMember;
    } catch (e) {
      return false;
    }
  }

  void addMembership(int groupId) {
    _myGroupIds.add(groupId);
    notifyListeners();
  }

  void removeMembership(int groupId) {
    _myGroupIds.remove(groupId);
    notifyListeners();
  }

  void clearMemberships() {
    _myGroupIds.clear();
    notifyListeners();
  }
}