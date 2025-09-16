import '../../core/network/api_response.dart';
import '../../data/models/group_model.dart'; // Corrected import

abstract class GroupRepository {
  Future<ApiResponse<List<GroupHierarchyNode>>> getGroupHierarchy();
  Future<ApiResponse<List<GroupSummaryModel>>> getAllGroups();
  Future<ApiResponse<List<GroupSummaryModel>>> getSubGroups(int parentId);
  Future<ApiResponse<bool>> checkGroupMembership(int groupId);

  // Batch membership check - to be implemented
  Future<ApiResponse<Map<int, bool>>> checkBatchGroupMembership(List<int> groupIds);
}
