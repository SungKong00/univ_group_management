import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/extensions/app_spacing_extension.dart';
import '../theme/colors/top_bar_colors.dart';
import '../theme/animation_tokens.dart';
import '../theme/border_tokens.dart';
import '../theme/component_size_tokens.dart';

/// 상단 바 컴포넌트
///
/// 상단 네비게이션 바를 표시합니다.
/// 뒤로가기 버튼, 브레드크럼/제목, 우측 액션 영역을 포함합니다.
///
/// **기능**:
/// - 뒤로가기 버튼 (활성/비활성)
/// - 브레드크럼 또는 제목 표시
/// - 우측 액션 영역 (프로필 아바타, 버튼 등)
///
/// ```dart
/// AppTopBar(
///   canGoBack: true,
///   onBack: () => Navigator.pop(context),
///   title: Text('페이지 제목'),
///   trailing: IconButton(
///     icon: Icon(Icons.account_circle),
///     onPressed: () {},
///   ),
/// )
/// ```
class AppTopBar extends StatelessWidget {
  /// 뒤로가기 가능 여부
  final bool canGoBack;

  /// 뒤로가기 콜백
  final VoidCallback? onBack;

  /// 중앙 콘텐츠 (브레드크럼 또는 제목)
  final Widget? title;

  /// 우측 액션 위젯
  final Widget? trailing;

  /// 높이
  final double height;

  /// 모바일 모드 (컴팩트 레이아웃)
  final bool isMobile;

  const AppTopBar({
    super.key,
    this.canGoBack = false,
    this.onBack,
    this.title,
    this.trailing,
    this.height = 56,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;
    final colors = TopBarColors.from(colorExt);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(
          bottom: BorderSide(
            color: colors.border,
            width: BorderTokens.widthThin,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacingExt.medium),
        child: Row(
          children: [
            _BackButton(canGoBack: canGoBack, onBack: onBack, colors: colors),
            if (title != null) ...[
              SizedBox(width: spacingExt.small),
              Expanded(child: title!),
            ] else
              const Spacer(),
            if (trailing != null) ...[
              SizedBox(width: spacingExt.small),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 뒤로가기 버튼
class _BackButton extends StatefulWidget {
  final bool canGoBack;
  final VoidCallback? onBack;
  final TopBarColors colors;

  const _BackButton({
    required this.canGoBack,
    required this.onBack,
    required this.colors,
  });

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.canGoBack && widget.onBack != null;

    return Semantics(
      label: '뒤로가기',
      button: true,
      enabled: isEnabled,
      child: MouseRegion(
        cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: isEnabled ? widget.onBack : null,
          child: AnimatedContainer(
            duration: AnimationTokens.durationQuick,
            width: ComponentSizeTokens.boxSmall,
            height: ComponentSizeTokens.boxSmall,
            decoration: BoxDecoration(
              color: _isHovered && isEnabled
                  ? widget.colors.backHover
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
            ),
            child: Icon(
              Icons.arrow_back,
              size: ComponentSizeTokens.iconSmall,
              color: isEnabled
                  ? widget.colors.backIcon
                  : widget.colors.backDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

/// 사용자 아바타 버튼
///
/// 상단 바 우측에 표시되는 프로필 아바타 버튼입니다.
///
/// ```dart
/// AppTopBar(
///   trailing: AppUserAvatar(
///     imageUrl: user.avatarUrl,
///     name: user.name,
///     onTap: () => showProfileMenu(),
///   ),
/// )
/// ```
class AppUserAvatar extends StatefulWidget {
  /// 프로필 이미지 URL
  final String? imageUrl;

  /// 사용자 이름 (이미지 없을 때 이니셜 표시용)
  final String? name;

  /// 클릭 콜백
  final VoidCallback? onTap;

  /// 크기
  final double size;

  const AppUserAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.onTap,
    this.size = 32,
  });

  @override
  State<AppUserAvatar> createState() => _AppUserAvatarState();
}

class _AppUserAvatarState extends State<AppUserAvatar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final colors = TopBarColors.from(colorExt);

    return Semantics(
      label: widget.name ?? '사용자 프로필',
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AnimationTokens.durationQuick,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: colors.avatarBackground,
              shape: BoxShape.circle,
              border: Border.all(
                color: _isHovered ? colorExt.brandPrimary : Colors.transparent,
                width: BorderTokens.widthFocus,
              ),
            ),
            child: ClipOval(
              child: widget.imageUrl != null
                  ? Image.network(
                      widget.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          _buildInitials(colors),
                    )
                  : _buildInitials(colors),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitials(TopBarColors colors) {
    final initial = widget.name?.isNotEmpty == true
        ? widget.name!.substring(0, 1).toUpperCase()
        : '?';

    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: colors.avatarText,
          fontSize: widget.size * 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
