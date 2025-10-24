import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_colors.dart';

/// 범용 상태 관리 위젯
///
/// AsyncValue의 4가지 상태(loading, error, empty, data)를 통합 처리합니다.
/// WorkspaceStateView 스타일을 확장하여 전체 앱에서 일관된 UX를 제공합니다.
///
/// **사용 예시**:
/// ```dart
/// final usersAsync = ref.watch(usersProvider);
///
/// return StateView<List<User>>(
///   value: usersAsync,
///   emptyChecker: (users) => users.isEmpty,
///   emptyIcon: Icons.person_off,
///   emptyTitle: '사용자가 없습니다',
///   emptyDescription: '아직 등록된 사용자가 없습니다',
///   builder: (context, users) => UserList(users: users),
/// );
/// ```
class StateView<T> extends StatelessWidget {
  /// AsyncValue 데이터
  final AsyncValue<T> value;

  /// 데이터가 있을 때 렌더링할 위젯
  final Widget Function(BuildContext context, T data) builder;

  /// 빈 상태 체크 함수 (예: list.isEmpty)
  final bool Function(T data)? emptyChecker;

  /// 빈 상태 아이콘
  final IconData? emptyIcon;

  /// 빈 상태 제목
  final String? emptyTitle;

  /// 빈 상태 설명
  final String? emptyDescription;

  /// 빈 상태 액션 버튼 라벨
  final String? emptyActionLabel;

  /// 빈 상태 액션 버튼 콜백
  final VoidCallback? onEmptyAction;

  /// 로딩 메시지
  final String? loadingMessage;

  /// 에러 발생 시 재시도 콜백
  final VoidCallback? onRetry;

  /// 커스텀 에러 메시지 추출 함수
  final String Function(Object error)? errorMessageExtractor;

  const StateView({
    super.key,
    required this.value,
    required this.builder,
    this.emptyChecker,
    this.emptyIcon,
    this.emptyTitle,
    this.emptyDescription,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.loadingMessage,
    this.onRetry,
    this.errorMessageExtractor,
  });

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (data) {
        // Empty 상태 체크
        if (emptyChecker != null && emptyChecker!(data)) {
          return _buildEmptyState(context);
        }
        // 정상 데이터 렌더링
        return builder(context, data);
      },
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  /// 로딩 상태
  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand),
          ),
          if (loadingMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              loadingMessage!,
              style: AppTheme.bodyMediumTheme(context).copyWith(
                color: AppColors.neutral700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 에러 상태
  Widget _buildErrorState(BuildContext context, Object error) {
    final displayMessage = errorMessageExtractor != null
        ? errorMessageExtractor!(error)
        : error.toString();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              displayMessage,
              style: AppTheme.headlineSmallTheme(context).copyWith(
                color: AppColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '문제가 지속되면 관리자에게 문의하세요',
              style: AppTheme.bodyMediumTheme(context).copyWith(
                color: AppColors.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.action,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: Text(
                  '다시 시도',
                  style: AppTheme.titleMediumTheme(context).copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 빈 상태
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon ?? Icons.inbox_outlined,
              size: 64,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              emptyTitle ?? '데이터가 없습니다',
              style: AppTheme.headlineSmallTheme(context).copyWith(
                color: AppColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            if (emptyDescription != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                emptyDescription!,
                style: AppTheme.bodyMediumTheme(context).copyWith(
                  color: AppColors.neutral600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onEmptyAction != null && emptyActionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: onEmptyAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.action,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(160, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: Text(
                  emptyActionLabel!,
                  style: AppTheme.titleMediumTheme(context).copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// AsyncValue를 간편하게 렌더링하는 Extension
///
/// **사용 예시**:
/// ```dart
/// usersAsync.buildWith(
///   context: context,
///   builder: (users) => UserList(users: users),
///   emptyChecker: (users) => users.isEmpty,
/// )
/// ```
extension AsyncValueStateView<T> on AsyncValue<T> {
  Widget buildWith({
    required BuildContext context,
    required Widget Function(T data) builder,
    bool Function(T data)? emptyChecker,
    IconData? emptyIcon,
    String? emptyTitle,
    String? emptyDescription,
    String? emptyActionLabel,
    VoidCallback? onEmptyAction,
    String? loadingMessage,
    VoidCallback? onRetry,
    String Function(Object error)? errorMessageExtractor,
  }) {
    return StateView<T>(
      value: this,
      builder: (ctx, data) => builder(data),
      emptyChecker: emptyChecker,
      emptyIcon: emptyIcon,
      emptyTitle: emptyTitle,
      emptyDescription: emptyDescription,
      emptyActionLabel: emptyActionLabel,
      onEmptyAction: onEmptyAction,
      loadingMessage: loadingMessage,
      onRetry: onRetry,
      errorMessageExtractor: errorMessageExtractor,
    );
  }
}
