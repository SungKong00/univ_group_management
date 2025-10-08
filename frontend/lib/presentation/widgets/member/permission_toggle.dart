import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// 권한 토글 스위치
///
/// Permission-Centric 권한 매트릭스에서 사용합니다.
/// 각 권한별로 역할을 활성화/비활성화합니다.
class PermissionToggle extends StatelessWidget {
  final String permissionName;
  final String permissionDescription;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;
  final bool disabled;

  const PermissionToggle({
    super.key,
    required this.permissionName,
    required this.permissionDescription,
    required this.isEnabled,
    required this.onChanged,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.neutral300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  permissionName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: disabled ? AppColors.neutral500 : AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  permissionDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: isEnabled,
            onChanged: disabled ? null : onChanged,
            activeTrackColor: AppColors.brand,
          ),
        ],
      ),
    );
  }
}

/// 권한 매트릭스 행 (역할 x 권한)
class PermissionMatrixRow extends StatelessWidget {
  final String permissionName;
  final String permissionKey;
  final Map<String, bool> rolePermissions; // roleId -> hasPermission
  final Function(String roleId, bool value) onToggle;
  final List<String> disabledRoles; // 수정 불가 역할 (시스템 역할 등)

  const PermissionMatrixRow({
    super.key,
    required this.permissionName,
    required this.permissionKey,
    required this.rolePermissions,
    required this.onToggle,
    this.disabledRoles = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            permissionName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: rolePermissions.entries.map((entry) {
              final roleId = entry.key;
              final hasPermission = entry.value;
              final isDisabled = disabledRoles.contains(roleId);

              return FilterChip(
                label: Text(
                  _getRoleName(roleId),
                  style: TextStyle(
                    fontSize: 12,
                    color: hasPermission
                        ? (isDisabled ? AppColors.neutral500 : AppColors.brand)
                        : AppColors.neutral700,
                  ),
                ),
                selected: hasPermission,
                onSelected: isDisabled
                    ? null
                    : (bool selected) {
                        onToggle(roleId, selected);
                      },
                backgroundColor: AppColors.neutral100,
                selectedColor: isDisabled
                    ? AppColors.neutral300
                    : AppColors.brand.withValues(alpha: 0.1),
                checkmarkColor: isDisabled ? AppColors.neutral500 : AppColors.brand,
                side: BorderSide(
                  color: hasPermission
                      ? (isDisabled ? AppColors.neutral400 : AppColors.brand)
                      : AppColors.neutral300,
                  width: 1,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getRoleName(String roleId) {
    // 간단한 역할 이름 매핑 (실제로는 Provider에서 가져와야 함)
    final roleNames = {
      'owner': '그룹장',
      'advisor': '교수',
      'member': '멤버',
    };
    return roleNames[roleId] ?? roleId;
  }
}
