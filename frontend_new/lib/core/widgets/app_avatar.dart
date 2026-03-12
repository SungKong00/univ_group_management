import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/colors/avatar_colors.dart';
import '../theme/enums.dart';
import '../theme/border_tokens.dart';
import '../theme/animation_tokens.dart';

// Export enums for convenience
export '../theme/enums.dart' show AppAvatarSize, AppAvatarStatus;

/// 사용자 프로필 이미지를 표시하는 Avatar 컴포넌트
///
/// **용도**: 프로필 이미지, 사용자 식별, 온라인 상태 표시
/// **접근성**: 스크린 리더에 사용자 이름 제공
///
/// ```dart
/// // 이미지 아바타
/// AppAvatar(
///   imageUrl: 'https://example.com/profile.jpg',
///   name: '홍길동',
///   size: AppAvatarSize.md,
/// )
///
/// // 이니셜 아바타 (이미지 없을 때)
/// AppAvatar(
///   name: '홍길동',
///   size: AppAvatarSize.lg,
/// )
///
/// // 온라인 상태 표시
/// AppAvatar(
///   imageUrl: 'https://example.com/profile.jpg',
///   name: '홍길동',
///   showStatus: true,
///   status: AppAvatarStatus.online,
/// )
/// ```
class AppAvatar extends StatelessWidget {
  /// 프로필 이미지 URL
  final String? imageUrl;

  /// 사용자 이름 (이니셜 생성용, 접근성용)
  final String? name;

  /// 아바타 크기
  final AppAvatarSize size;

  /// 커스텀 배경색 (이니셜용, null이면 이름 기반 자동 할당)
  final Color? backgroundColor;

  /// 온라인 상태 표시 여부
  final bool showStatus;

  /// 온라인 상태
  final AppAvatarStatus status;

  /// 탭 콜백
  final VoidCallback? onTap;

  /// 테두리 표시 여부
  final bool showBorder;

  /// 기본 아이콘 (이미지/이름 없을 때)
  final IconData fallbackIcon;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AppAvatarSize.md,
    this.backgroundColor,
    this.showStatus = false,
    this.status = AppAvatarStatus.offline,
    this.onTap,
    this.showBorder = false,
    this.fallbackIcon = Icons.person_outline,
  });

  /// 이니셜 아바타 팩토리
  factory AppAvatar.initials({
    Key? key,
    required String name,
    AppAvatarSize size = AppAvatarSize.md,
    Color? backgroundColor,
    bool showStatus = false,
    AppAvatarStatus status = AppAvatarStatus.offline,
    VoidCallback? onTap,
  }) {
    return AppAvatar(
      key: key,
      name: name,
      size: size,
      backgroundColor: backgroundColor,
      showStatus: showStatus,
      status: status,
      onTap: onTap,
    );
  }

  /// 그룹 아바타 팩토리
  factory AppAvatar.group({
    Key? key,
    String? imageUrl,
    String? name,
    AppAvatarSize size = AppAvatarSize.md,
    VoidCallback? onTap,
  }) {
    return AppAvatar(
      key: key,
      imageUrl: imageUrl,
      name: name,
      size: size,
      onTap: onTap,
      fallbackIcon: Icons.group_outlined,
    );
  }

  /// 크기별 픽셀 값
  double get _sizeValue => switch (size) {
    AppAvatarSize.xs => 24.0,
    AppAvatarSize.sm => 32.0,
    AppAvatarSize.md => 40.0,
    AppAvatarSize.lg => 48.0,
    AppAvatarSize.xl => 64.0,
    AppAvatarSize.xxl => 96.0,
  };

  /// 크기별 폰트 크기
  double get _fontSize => switch (size) {
    AppAvatarSize.xs => 10.0,
    AppAvatarSize.sm => 12.0,
    AppAvatarSize.md => 14.0,
    AppAvatarSize.lg => 16.0,
    AppAvatarSize.xl => 20.0,
    AppAvatarSize.xxl => 28.0,
  };

  /// 크기별 상태 표시기 크기
  double get _statusSize => switch (size) {
    AppAvatarSize.xs => 6.0,
    AppAvatarSize.sm => 8.0,
    AppAvatarSize.md => 10.0,
    AppAvatarSize.lg => 12.0,
    AppAvatarSize.xl => 14.0,
    AppAvatarSize.xxl => 18.0,
  };

  /// 크기별 아이콘 크기
  double get _iconSize => switch (size) {
    AppAvatarSize.xs => 14.0,
    AppAvatarSize.sm => 18.0,
    AppAvatarSize.md => 22.0,
    AppAvatarSize.lg => 26.0,
    AppAvatarSize.xl => 34.0,
    AppAvatarSize.xxl => 50.0,
  };

  /// 이니셜 생성
  String _getInitials() {
    if (name == null || name!.isEmpty) return '';

    final parts = name!.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name![0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final colors = AvatarColors.standard(colorExt);

    final effectiveBackgroundColor =
        backgroundColor ??
        (name != null
            ? AvatarColors.backgroundForName(colorExt, name!)
            : colors.background);

    final textColor = name != null
        ? AvatarColors.textForName(colorExt, name!)
        : colors.text;

    return Semantics(
      label: name ?? '프로필',
      image: imageUrl != null,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            // 메인 아바타
            AnimatedContainer(
              duration: AnimationTokens.durationQuick,
              width: _sizeValue,
              height: _sizeValue,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: imageUrl != null ? null : effectiveBackgroundColor,
                border: showBorder
                    ? Border.all(
                        color: colors.border,
                        width: BorderTokens.widthThin,
                      )
                    : null,
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {},
                      )
                    : null,
              ),
              child: imageUrl != null
                  ? null
                  : Center(
                      child: name != null && name!.isNotEmpty
                          ? Text(
                              _getInitials(),
                              style: TextStyle(
                                color: textColor,
                                fontSize: _fontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : Icon(
                              fallbackIcon,
                              size: _iconSize,
                              color: colors.text,
                            ),
                    ),
            ),

            // 온라인 상태 표시기
            if (showStatus)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: _statusSize,
                  height: _statusSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AvatarColors.statusColor(colorExt, status),
                    border: Border.all(
                      color: colorExt.surfacePrimary,
                      width: BorderTokens.widthThin,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 여러 아바타를 겹쳐서 표시하는 AvatarGroup 컴포넌트
///
/// ```dart
/// AppAvatarGroup(
///   avatars: [
///     AvatarData(imageUrl: 'url1', name: 'User 1'),
///     AvatarData(imageUrl: 'url2', name: 'User 2'),
///     AvatarData(name: 'User 3'),
///   ],
///   maxDisplay: 3,
///   size: AppAvatarSize.sm,
/// )
/// ```
class AppAvatarGroup extends StatelessWidget {
  /// 아바타 데이터 목록
  final List<AvatarData> avatars;

  /// 최대 표시 개수
  final int maxDisplay;

  /// 아바타 크기
  final AppAvatarSize size;

  /// 겹침 정도 (0.0 ~ 1.0, 높을수록 많이 겹침)
  final double overlap;

  /// 탭 콜백 (나머지 개수 표시 버튼용)
  final VoidCallback? onMoreTap;

  const AppAvatarGroup({
    super.key,
    required this.avatars,
    this.maxDisplay = 4,
    this.size = AppAvatarSize.sm,
    this.overlap = 0.3,
    this.onMoreTap,
  });

  double get _sizeValue => switch (size) {
    AppAvatarSize.xs => 24.0,
    AppAvatarSize.sm => 32.0,
    AppAvatarSize.md => 40.0,
    AppAvatarSize.lg => 48.0,
    AppAvatarSize.xl => 64.0,
    AppAvatarSize.xxl => 96.0,
  };

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final displayCount = avatars.length > maxDisplay
        ? maxDisplay
        : avatars.length;
    final remaining = avatars.length - maxDisplay;
    final offsetAmount = _sizeValue * (1 - overlap);

    return SizedBox(
      width:
          offsetAmount * displayCount +
          (remaining > 0 ? offsetAmount : 0) +
          _sizeValue * overlap,
      height: _sizeValue,
      child: Stack(
        children: [
          // 표시할 아바타들
          for (int i = 0; i < displayCount; i++)
            Positioned(
              left: i * offsetAmount,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorExt.surfacePrimary,
                    width: BorderTokens.widthThin * 2,
                  ),
                ),
                child: AppAvatar(
                  imageUrl: avatars[i].imageUrl,
                  name: avatars[i].name,
                  size: size,
                ),
              ),
            ),

          // 나머지 개수 표시
          if (remaining > 0)
            Positioned(
              left: displayCount * offsetAmount,
              child: GestureDetector(
                onTap: onMoreTap,
                child: Container(
                  width: _sizeValue,
                  height: _sizeValue,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorExt.surfaceTertiary,
                    border: Border.all(
                      color: colorExt.surfacePrimary,
                      width: BorderTokens.widthThin * 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '+$remaining',
                      style: TextStyle(
                        color: colorExt.textSecondary,
                        fontSize: _sizeValue * 0.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 아바타 데이터 모델
class AvatarData {
  /// 프로필 이미지 URL
  final String? imageUrl;

  /// 사용자 이름
  final String? name;

  /// 온라인 상태
  final AppAvatarStatus? status;

  const AvatarData({this.imageUrl, this.name, this.status});
}
