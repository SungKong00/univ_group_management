/// FilterTab - Customer Filter Tabs의 탭 정보
class FilterTab {
  final String label;
  final String filter;

  const FilterTab({required this.label, required this.filter});

  /// Copy with
  FilterTab copyWith({String? label, String? filter}) {
    return FilterTab(label: label ?? this.label, filter: filter ?? this.filter);
  }
}
