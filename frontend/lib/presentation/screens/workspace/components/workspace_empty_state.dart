import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/workspace_provider.dart';

class WorkspaceEmptyState extends StatelessWidget {
  final int groupId;
  final VoidCallback? onBack;

  const WorkspaceEmptyState({
    super.key,
    required this.groupId,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkspaceProvider>(
      builder: (context, provider, child) {
        if (provider.isAccessDenied) {
          return _buildAccessDeniedState(context, provider);
        }

        if (provider.error != null) {
          return _buildErrorState(context, provider);
        }

        return const Center(
          child: Text('워크스페이스를 로드 중입니다...'),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, WorkspaceProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            '워크스페이스를 불러올 수 없습니다',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            provider.error!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final isDesktop = MediaQuery.of(context).size.width >= 900;
              provider.loadWorkspace(
                groupId,
                autoSelectFirstChannel: isDesktop,
                mobileNavigatorVisible: !isDesktop,
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final ok = await provider.requestJoin(groupId);
              if (!context.mounted) return;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('가입 신청이 접수되었습니다')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('가입 신청에 실패했습니다')),
                );
              }
            },
            icon: const Icon(Icons.login),
            label: const Text('가입 신청하기'),
          ),
          const SizedBox(height: 16),
          if (onBack != null)
            TextButton(
              onPressed: onBack,
              child: const Text('돌아가기'),
            ),
        ],
      ),
    );
  }

  Widget _buildAccessDeniedState(BuildContext context, WorkspaceProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '워크스페이스를 불러올 수 없습니다',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              provider.error ?? '이 그룹의 워크스페이스는 멤버만 접근할 수 있습니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final ok = await provider.requestJoin(groupId);
                if (!context.mounted) return;
                if (ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('가입 신청이 접수되었습니다')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('가입 신청에 실패했습니다')),
                  );
                }
              },
              icon: const Icon(Icons.login),
              label: const Text('가입 신청하기'),
            ),
            const SizedBox(height: 12),
            if (onBack != null)
              TextButton(
                onPressed: onBack,
                child: const Text('돌아가기'),
              ),
          ],
        ),
      ),
    );
  }
}