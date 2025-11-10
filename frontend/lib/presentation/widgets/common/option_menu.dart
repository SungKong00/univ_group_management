import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 옵션 메뉴 아이템 모델
class OptionMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const OptionMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });
}

/// 3-dot 옵션 메뉴 위젯
///
/// 게시글, 댓글 등에서 수정/삭제/신고 등의 액션을 제공하는 팝업 메뉴
class OptionMenu extends StatelessWidget {
  final List<OptionMenuItem> items;
  final EdgeInsetsGeometry? padding;

  const OptionMenu({super.key, required this.items, this.padding});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      icon: Icon(Icons.more_vert, size: 20, color: AppColors.neutral600),
      padding: padding ?? EdgeInsets.zero,
      offset: const Offset(0, 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      itemBuilder: (context) {
        return items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return PopupMenuItem<int>(
            value: index,
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 18,
                  color: item.isDestructive
                      ? AppColors.error
                      : AppColors.neutral700,
                ),
                const SizedBox(width: 8), // xxs spacing
                Text(
                  item.label,
                  style: TextStyle(
                    color: item.isDestructive
                        ? AppColors.error
                        : AppColors.neutral900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (index) {
        items[index].onTap();
      },
    );
  }
}
