import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/member_models.dart';
import '../../core/providers/member/member_list_provider.dart';
import '../providers/my_groups_provider.dart';
import '../../core/theme/app_colors.dart';
import 'member_management/widgets/member_filter_panel.dart';

/// 멤버 필터 데모 페이지
///
/// "한신대학교" 그룹의 멤버 필터링 기능을 테스트하기 위한 독립 데모 페이지
class DemoMemberFilterPage extends ConsumerStatefulWidget {
  const DemoMemberFilterPage({super.key});

  @override
  ConsumerState<DemoMemberFilterPage> createState() =>
      _DemoMemberFilterPageState();
}

class _DemoMemberFilterPageState extends ConsumerState<DemoMemberFilterPage> {
  int? _hanshinGroupId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHanshinGroup();
  }

  /// 한신대학교 그룹 ID 조회
  Future<void> _loadHanshinGroup() async {
    try {
      final myGroups = await ref.read(myGroupsProvider.future);
      final hanshin = myGroups.firstWhere(
        (g) => g.name == '한신대학교',
        orElse: () => throw Exception('한신대학교 그룹을 찾을 수 없습니다'),
      );

      if (mounted) {
        setState(() {
          _hanshinGroupId = hanshin.id;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('멤버 필터 데모'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              '에러 발생',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadHanshinGroup();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final membersAsync =
        ref.watch(filteredGroupMembersProvider(_hanshinGroupId!));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        if (isDesktop) {
          // 데스크톱 레이아웃: Row(필터 패널 + 멤버 테이블)
          return Row(
            children: [
              SizedBox(
                width: 300,
                child: Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    child: MemberFilterPanel(groupId: _hanshinGroupId!),
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _buildMemberList(membersAsync, isDesktop: true),
              ),
            ],
          );
        } else {
          // 모바일 레이아웃: Column(필터 버튼 + 멤버 카드)
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showFilterBottomSheet,
                    icon: const Icon(Icons.filter_list),
                    label: const Text('필터'),
                  ),
                ),
              ),
              Expanded(
                child: _buildMemberList(membersAsync, isDesktop: false),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildMemberList(
    AsyncValue<List<GroupMember>> membersAsync, {
    required bool isDesktop,
  }) {
    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48, color: AppColors.neutral400),
                SizedBox(height: 16),
                Text('필터 조건에 맞는 멤버가 없습니다'),
              ],
            ),
          );
        }

        // 데스크톱/모바일 모두 리스트 타일로 표시
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(member.userName[0]),
                ),
                title: Text(member.userName),
                subtitle: Text('${member.roleName} • ${member.email}'),
                trailing: member.academicYear != null
                    ? Chip(label: Text('${member.academicYear}학년'))
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            const Text('멤버 목록 조회 실패'),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 모바일 필터 바텀 시트 표시
  void _showFilterBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '필터',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 필터 패널
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: MemberFilterPanel(groupId: _hanshinGroupId!),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
