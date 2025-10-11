import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/recruitment_explore_state_provider.dart';

/// Recruitment Search Bar Widget
///
/// Search bar for recruitment announcements
class RecruitmentSearchBar extends ConsumerStatefulWidget {
  const RecruitmentSearchBar({super.key});

  @override
  ConsumerState<RecruitmentSearchBar> createState() =>
      _RecruitmentSearchBarState();
}

class _RecruitmentSearchBarState extends ConsumerState<RecruitmentSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controller with current search query
    final currentQuery = ref.read(exploreRecruitmentSearchQueryProvider);
    _controller.text = currentQuery;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final query = _controller.text.trim();
    ref.read(recruitmentExploreStateProvider.notifier).search(query);
  }

  void _handleClear() {
    _controller.clear();
    ref.read(recruitmentExploreStateProvider.notifier).search('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: '모집 공고 검색...',
        hintStyle: AppTheme.bodyMediumTheme(context).copyWith(
          color: AppColors.neutral500,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: AppColors.neutral600,
        ),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: AppColors.neutral600,
                ),
                onPressed: _handleClear,
                tooltip: '검색어 지우기',
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: AppColors.neutral300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: AppColors.brand, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _handleSearch(),
      onChanged: (value) {
        setState(() {}); // Update UI to show/hide clear button
      },
    );
  }
}
