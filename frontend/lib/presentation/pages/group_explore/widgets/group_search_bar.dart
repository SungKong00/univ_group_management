import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/group_explore/group_explore_filter_provider.dart';

/// Group Search Bar
///
/// TextField with debouncing for searching groups.
/// Automatically triggers search 500ms after user stops typing.
class GroupSearchBar extends ConsumerStatefulWidget {
  const GroupSearchBar({super.key});

  @override
  ConsumerState<GroupSearchBar> createState() => _GroupSearchBarState();
}

class _GroupSearchBarState extends ConsumerState<GroupSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Cancel previous timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Start new timer (500ms delay)
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(groupExploreFilterProvider.notifier).setSearchQuery(query);
    });
  }

  void _onClear() {
    _controller.clear();
    ref.read(groupExploreFilterProvider.notifier).setSearchQuery('');
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '그룹 검색 입력창',
      child: TextField(
        controller: _controller,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: '그룹 이름을 검색하세요',
          hintStyle: AppTheme.bodyMediumTheme(context).copyWith(
            color: AppColors.neutral500,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.neutral600,
            size: 20,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: AppColors.neutral600,
                    size: 20,
                  ),
                  onPressed: _onClear,
                  tooltip: '검색어 지우기',
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide: BorderSide(color: AppColors.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide: BorderSide(color: AppColors.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            borderSide: BorderSide(color: AppColors.action, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
        ),
        style: AppTheme.bodyMediumTheme(context),
      ),
    );
  }
}
