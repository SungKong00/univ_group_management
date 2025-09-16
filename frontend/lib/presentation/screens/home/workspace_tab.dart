import 'package:flutter/material.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../data/services/group_service.dart';
import '../../../data/models/group_model.dart';
import '../workspace/workspace_desktop_skeleton.dart';

class WorkspaceTab extends StatefulWidget {
  const WorkspaceTab({super.key});

  @override
  State<WorkspaceTab> createState() => _WorkspaceTabState();
}

class _WorkspaceTabState extends State<WorkspaceTab> {
  late final GroupService _service;
  List<GroupSummaryModel> _myGroups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = GroupService(DioClient(SharedPrefsTokenStorage()));
    _loadMyGroups();
  }

  Future<void> _loadMyGroups() async {
    try {
      // TODO: 내가 속한 그룹 목록을 가져오는 API 호출
      // 현재는 모든 그룹을 가져옴 (임시)
      final res = await _service.explore(page: 0, size: 20);
      if (!mounted) return;
      if (res.isSuccess && res.data != null) {
        setState(() {
          _myGroups = res.data!.content;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myGroups.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspaces_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '아직 참여한 그룹이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '그룹 탐색에서 원하는 그룹을 찾아보세요',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final group = _myGroups[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: group.profileImageUrl != null
                ? NetworkImage(group.profileImageUrl!)
                : null,
            child: group.profileImageUrl == null
                ? const Icon(Icons.group_work)
                : null,
          ),
          title: Text(group.name),
          subtitle: Text(group.description ?? '${group.university ?? ''} ${group.department ?? ''}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (group.isRecruiting)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '모집중',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 10,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () {
            // 워크스페이스 화면으로 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WorkspaceDesktopSkeleton(),
              ),
            );
          },
        );
      },
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemCount: _myGroups.length,
    );
  }
}