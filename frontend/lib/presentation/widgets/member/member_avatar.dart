import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 멤버 아바타 위젯
///
/// 프로필 이미지가 있으면 표시하고, 없으면 이니셜을 보여줍니다.
class MemberAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool showBadge;
  final Color? badgeColor;

  const MemberAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 40,
    this.showBadge = false,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 아바타 원형
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neutral200,
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null
              ? Center(
                  child: Text(
                    _getInitials(name),
                    style: TextStyle(
                      color: AppColors.neutral700,
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
        // 상태 배지 (옵션)
        if (showBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor ?? AppColors.success,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 이름에서 이니셜 추출 (최대 2글자)
  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      // 두 단어 이상: 첫 글자씩
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      // 한 단어: 처음 두 글자 (또는 한 글자)
      return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name[0].toUpperCase();
    }
  }
}

/// 멤버 아바타 + 이름 조합 위젯
class MemberAvatarWithName extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final String? subtitle;
  final double avatarSize;

  const MemberAvatarWithName({
    super.key,
    required this.name,
    this.imageUrl,
    this.subtitle,
    this.avatarSize = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MemberAvatar(
          name: name,
          imageUrl: imageUrl,
          size: avatarSize,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.neutral900,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
