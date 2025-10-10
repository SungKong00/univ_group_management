import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme.dart';
import '../../../core/models/member_models.dart';

/// 역할 선택 드롭다운
///
/// 멤버의 역할을 변경할 때 사용합니다.
/// 시스템 역할은 수정 불가 표시를 합니다.
class RoleDropdown extends StatelessWidget {
  final int currentRoleId;
  final List<GroupRole> availableRoles;
  final Function(int roleId) onRoleChanged;
  final bool enabled;

  const RoleDropdown({
    super.key,
    required this.currentRoleId,
    required this.availableRoles,
    required this.onRoleChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: enabled ? AppColors.neutral100 : AppColors.neutral200,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.neutral300, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: currentRoleId,
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: enabled ? AppColors.neutral700 : AppColors.neutral500,
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: enabled ? AppColors.neutral900 : AppColors.neutral500,
          ),
          onChanged: enabled
              ? (int? newValue) {
                  if (newValue != null && newValue != currentRoleId) {
                    onRoleChanged(newValue);
                  }
                }
              : null,
          items: availableRoles.map<DropdownMenuItem<int>>((GroupRole role) {
            return DropdownMenuItem<int>(
              value: role.id,
              child: Row(
                children: [
                  Text(role.name),
                  if (role.isSystemRole) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neutral200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '시스템',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// 간단한 역할 배지
class RoleBadge extends StatelessWidget {
  final String roleName;
  final bool isSystemRole;
  final Color? backgroundColor;
  final Color? textColor;

  const RoleBadge({
    super.key,
    required this.roleName,
    this.isSystemRole = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = backgroundColor ?? AppColors.neutral200;
    Color txtColor = textColor ?? AppColors.neutral700;

    // 시스템 역할별 색상 매핑
    if (isSystemRole) {
      switch (roleName) {
        case '그룹장':
          bgColor = AppColors.brand.withValues(alpha: 0.1);
          txtColor = AppColors.brand;
          break;
        case '교수':
          bgColor = AppColors.action.withValues(alpha: 0.1);
          txtColor = AppColors.action;
          break;
        case '멤버':
          bgColor = AppColors.neutral200;
          txtColor = AppColors.neutral700;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        roleName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: txtColor,
        ),
      ),
    );
  }
}
