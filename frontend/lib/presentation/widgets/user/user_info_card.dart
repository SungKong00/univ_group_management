import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../dialogs/logout_dialog.dart';

/// UserInfoCard v2
/// 목표:
/// 1) 높이/비율 깨짐 없는 안정적 레이아웃 (heightFactor / SizeTransition 제거)
/// 2) 단일 AnimationController 로 진입/퇴장(Fade + Slide) 처리
/// 3) 내부 상태(로그아웃 진행 중)만 관리, 제거 애니메이션은 부모 AnimatedSwitcher/AnimatedSize 활용
/// 4) 뷰 계층 명확 분리: Avatar / Info / Actions
/// 5) 재사용성: isCompact / onLogoutRequested 확장 고려
class UserInfoCard extends ConsumerStatefulWidget {
  final UserInfo user;
  final bool isCompact;
  final VoidCallback? onLogoutRequested;
  final bool showLogout;
  final bool slowReveal; // 하단 전용 느린 리빌

  const UserInfoCard({
    super.key,
    required this.user,
    this.isCompact = false,
    this.onLogoutRequested,
    this.showLogout = true,
    this.slowReveal = false,
  });

  @override
  ConsumerState<UserInfoCard> createState() => _UserInfoCardState();
}

class _UserInfoCardState extends ConsumerState<UserInfoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller; // 확장/축소 애니메이션 (0=확장, 1=축소)
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240), // 사이드바와 동일한 타이밍
    );
    // 초기 상태 설정
    _controller.value = widget.isCompact ? 1.0 : 0.0;
  }

  @override
  void didUpdateWidget(UserInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // isCompact 상태 변경 감지 시 애니메이션 트리거
    if (widget.isCompact != oldWidget.isCompact) {
      if (widget.isCompact) {
        _controller.forward(); // 축소: 0 → 1
      } else {
        _controller.reverse(); // 확장: 1 → 0
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value; // 0=확장, 1=축소

        // 콘텐츠 표시 여부 결정 (지연된 조건부 렌더링)
        // 축소 시: t가 0.4 넘으면 제거 (텍스트 먼저 사라짐, 공간 부족 전에 제거)
        // 확장 시: t가 0.4 이하일 때 표시 (사이드바 너비 확보 후 추가)
        final shouldShowContent = t < 0.4;

        // 페이드 진행도 계산
        // 확장: t 1.0→0.4에서 opacity 0→1
        // 축소: t 0.0→0.4에서 opacity 1→0
        final contentOpacity = shouldShowContent
            ? (1 - (t / 0.4)).clamp(0.0, 1.0)
            : 0.0;

        // 아바타 중앙 이동 애니메이션
        // 축소 시: 왼쪽(0) → 중앙(8px)으로 이동
        // 확장 시: 중앙(8px) → 왼쪽(0)으로 이동
        final avatarDx = Curves.easeInOutCubic.transform(t) * 8.0;

        return _buildSurface(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start, // 항상 왼쪽 정렬 유지
            children: [
              // Avatar: Transform으로 위치 애니메이션
              Transform.translate(
                offset: Offset(avatarDx, 0),
                child: _AvatarSection(
                  user: widget.user,
                  isCompact: widget.isCompact,
                ),
              ),

              // 확장 상태 콘텐츠 (지연 렌더링)
              if (shouldShowContent) ...[
                const SizedBox(width: AppSpacing.xs),
                // Info Section (닉네임 + 이메일/학과)
                Expanded(
                  child: Opacity(
                    opacity: contentOpacity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primary (닉네임/이름)
                        Text(
                          widget.user.nickname ?? widget.user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.neutral900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Secondary (email)
                        Text(
                          widget.user.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.neutral600,
                            height: 1.2,
                          ),
                        ),
                        if (widget.user.department != null) ...[
                          const SizedBox(height: 2),
                          _Tag(widget.user.department!),
                        ],
                      ],
                    ),
                  ),
                ),

                // Actions (로그아웃)
                if (widget.showLogout) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Opacity(
                    opacity: contentOpacity,
                    child: _ActionsSection(
                      isLoading: _isLoggingOut,
                      onLogoutTap: _isLoggingOut ? null : _handleLogout,
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSurface({required Widget child}) {
    return RepaintBoundary(
      child: Material(
        color: AppColors.surface,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeInOutCubic,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? AppSpacing.xs : AppSpacing.sm,
            vertical: widget.isCompact ? 6 : 10,
          ),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.outline, width: 1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    // 1) 확인 다이얼로그
    final confirmed = await showLogoutDialog(context);
    if (!confirmed) return;

    setState(() => _isLoggingOut = true);

    try {
      await ref.read(authProvider.notifier).logout();
      widget.onLogoutRequested?.call();
      // provider 가 currentUser null 로 만들면 부모 AnimatedSwitcher 가 제거 애니메이션 수행
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoggingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로그아웃 실패: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ================= Sub Components =================

class _AvatarSection extends StatelessWidget {
  final UserInfo user;
  final bool isCompact;
  const _AvatarSection({required this.user, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    final size = isCompact ? 32.0 : 40.0;
    final radius = size / 2;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.brandContainerLight,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.18), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildImageOrInitials(size),
    );
  }

  Widget _buildImageOrInitials(double size) {
    if (user.profileImageUrl != null) {
      return Image.network(
        user.profileImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _Initials(user: user, isCompact: isCompact),
      );
    }
    return _Initials(user: user, isCompact: isCompact);
  }
}

class _Initials extends StatelessWidget {
  final UserInfo user;
  final bool isCompact;
  const _Initials({required this.user, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    final initials = _computeInitials(user.name);
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: isCompact ? 12 : 14,
          fontWeight: FontWeight.w600,
          color: AppColors.brand,
          height: 1.0,
        ),
      ),
    );
  }

  String _computeInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}

class _PrimaryName extends StatelessWidget {
  final UserInfo user;
  final bool isCompact;
  const _PrimaryName({required this.user, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Text(
      user.nickname ?? user.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: isCompact ? 12 : 14,
        fontWeight: FontWeight.w600,
        color: AppColors.neutral900,
        height: 1.2,
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final UserInfo user;
  final bool isCompact;
  const _InfoSection({required this.user, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.nickname ?? user.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isCompact ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral900,
            height: 1.2,
          ),
        ),
        if (!isCompact) ...[
          const SizedBox(height: 2),
          Text(
            user.email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.neutral600,
              height: 1.2,
            ),
          ),
          if (user.department != null) ...[
            const SizedBox(height: 2),
            _Tag(user.department!),
          ],
        ],
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w500,
          color: AppColors.neutral700,
          height: 1.0,
        ),
      ),
    );
  }
}

class _ActionsSection extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onLogoutTap;
  const _ActionsSection({required this.isLoading, required this.onLogoutTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.standard,
      switchInCurve: AppMotion.easing,
      switchOutCurve: Curves.easeInCubic,
      child: isLoading
          ? const SizedBox(
              key: ValueKey('progress'),
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.neutral500,
              ),
            )
          : _LogoutButton(key: const ValueKey('btn'), onTap: onLogoutTap),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _LogoutButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.neutral400, width: 1),
          ),
          child: const Icon(Icons.logout, size: 14, color: AppColors.neutral600),
        ),
      ),
    );
  }
}
