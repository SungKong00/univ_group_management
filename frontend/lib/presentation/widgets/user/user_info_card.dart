import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/theme/theme.dart';
import '../../providers/auth_provider.dart';

class UserInfoCard extends ConsumerStatefulWidget {
  final UserInfo user;
  final bool isCompact;

  const UserInfoCard({
    super.key,
    required this.user,
    this.isCompact = false,
  });

  @override
  ConsumerState<UserInfoCard> createState() => _UserInfoCardState();
}

class _UserInfoCardState extends ConsumerState<UserInfoCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _logoutAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();

    // 메인 애니메이션 컨트롤러 (진입)
    _animationController = AnimationController(
      duration: AppMotion.standard,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: AppMotion.easing,
    ));

    // 로그아웃 애니메이션 컨트롤러 (퇴장)
    _logoutAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoutAnimationController,
      curve: Curves.easeInBack,
    ));
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _logoutAnimationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _logoutAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _slideAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(widget.isCompact ? AppSpacing.xs : AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: const Border(
                    top: BorderSide(color: AppColors.outline, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neutral900.withValues(alpha: 0.04),
                      offset: const Offset(0, -2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildProfileSection(),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: _buildUserInfo()),
                    if (!widget.isCompact) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _buildLogoutButton(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSection() {
    return Container(
      width: widget.isCompact ? 32 : 40,
      height: widget.isCompact ? 32 : 40,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(widget.isCompact ? 16 : 20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: widget.user.profileImageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(widget.isCompact ? 15 : 19),
              child: Image.network(
                widget.user.profileImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildFallbackAvatar(),
              ),
            )
          : _buildFallbackAvatar(),
    );
  }

  Widget _buildFallbackAvatar() {
    final initials = _getInitials(widget.user.name);
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          fontSize: widget.isCompact ? 12 : 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.user.nickname ?? widget.user.name,
          style: TextStyle(
            fontSize: widget.isCompact ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: AppColors.neutral900,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (!widget.isCompact) ...[
          const SizedBox(height: 2),
          Text(
            widget.user.email,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.neutral600,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.user.department != null) ...[
            const SizedBox(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.user.department!,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: AppColors.neutral700,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildLogoutButton() {
    return AnimatedContainer(
      duration: AppMotion.standard,
      curve: AppMotion.easing,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoggingOut ? null : _handleLogout,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxs,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _isLoggingOut
                    ? AppColors.neutral300
                    : AppColors.neutral400,
                width: 1,
              ),
            ),
            child: _isLoggingOut
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.neutral500,
                    ),
                  )
                : const Icon(
                    Icons.logout,
                    size: 14,
                    color: AppColors.neutral600,
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    // 로그아웃 확인 다이얼로그 표시
    final confirmed = await _showLogoutConfirmDialog();
    if (!confirmed) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      // 로그아웃 슬라이드 아웃 애니메이션 시작
      _logoutAnimationController.forward();

      await ref.read(authProvider.notifier).logout();

      if (mounted) {
        // 추가 페이드 아웃 애니메이션
        await _animationController.reverse();

        // GoRouter의 refreshListenable이 자동으로 redirect를 트리거하여
        // 로그인 페이지로 이동합니다 (추가 네비게이션 코드 불필요)
      }
    } catch (e) {
      if (mounted) {
        // 애니메이션 롤백
        _logoutAnimationController.reverse();

        setState(() {
          _isLoggingOut = false;
        });

        // 에러 스낵바 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 로그아웃 확인 다이얼로그 표시
  Future<bool> _showLogoutConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            '로그아웃',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral900,
              height: 1.3,
            ),
          ),
          content: Text(
            '정말 로그아웃하시겠습니까?\n현재 작업 중인 내용이 저장되지 않을 수 있습니다.',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.neutral700,
              height: 1.5,
            ),
          ),
          actions: [
            // 취소 버튼
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.neutral600,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '취소',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 로그아웃 버튼
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '로그아웃',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return (words[0].substring(0, 1) + words[1].substring(0, 1))
          .toUpperCase();
    }
  }
}