import 'package:flutter/material.dart';
import '../theme/extensions/app_color_extension.dart';
import '../theme/responsive_tokens.dart';

/// Pricing Comparison Table - 40+ 행의 비교 테이블
class PricingComparisonTable extends StatelessWidget {
  final Map<String, dynamic> data;

  const PricingComparisonTable({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final columns = data['columns'] as int? ?? 4;
    final columnHeaders =
        (data['columnHeaders'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final sections =
        (data['sections'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Container(
      decoration: BoxDecoration(
        color: colorExt.surfacePrimary,
        border: Border.all(color: colorExt.borderPrimary),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
          ),
          child: Table(
            columnWidths: _buildColumnWidths(columns),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(
                  color: colorExt.surfaceSecondary,
                  border: Border(
                    bottom: BorderSide(color: colorExt.borderPrimary),
                  ),
                ),
                children: [
                  const SizedBox.shrink(), // Empty top-left cell
                  ...columnHeaders.map(
                    (header) => _buildHeaderCell(
                      context,
                      header['text'] as String? ?? '',
                    ),
                  ),
                ],
              ),

              // Sections
              ...sections.expand(
                (section) => _buildSectionRows(context, section),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Column widths 계산
  Map<int, TableColumnWidth> _buildColumnWidths(int columns) {
    return {
      0: const FlexColumnWidth(2.0), // Feature name column
      for (int i = 1; i < columns + 1; i++) i: const FlexColumnWidth(1.0),
    };
  }

  /// Header cell
  Widget _buildHeaderCell(BuildContext context, String text) {
    final colorExt = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveTokens.cardGap(width),
        vertical: ResponsiveTokens.cardGap(width),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: textTheme.bodyMedium!.copyWith(
          color: colorExt.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Section rows 빌드
  List<TableRow> _buildSectionRows(
    BuildContext context,
    Map<String, dynamic> section,
  ) {
    final colorExt = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final sectionName = section['name'] as String? ?? '';
    final rows = (section['rows'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return [
      // Section Header
      TableRow(
        decoration: BoxDecoration(
          color: colorExt.surfaceTertiary,
          border: Border(bottom: BorderSide(color: colorExt.borderPrimary)),
        ),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Text(
              sectionName,
              style: textTheme.bodySmall!.copyWith(
                color: colorExt.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Empty cells for other columns
          ...List.generate(
            rows.isNotEmpty ? ((rows.first['cells'] as List?)?.length ?? 0) : 0,
            (_) => const SizedBox.shrink(),
          ),
        ],
      ),

      // Feature Rows
      ...rows.map((row) => _buildFeatureRow(context, row)),
    ];
  }

  /// Feature row
  TableRow _buildFeatureRow(BuildContext context, Map<String, dynamic> row) {
    final colorExt = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final feature = row['feature'] as String? ?? '';
    final cells = (row['cells'] as List?)?.cast<String>() ?? [];

    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorExt.borderPrimary.withValues(alpha: 0.3),
          ),
        ),
      ),
      children: [
        // Feature name
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 16.0,
          ),
          child: Text(
            feature,
            style: textTheme.bodyMedium!.copyWith(color: colorExt.textPrimary),
          ),
        ),

        // Cells
        ...cells.map((cell) => _buildCell(context, cell)),
      ],
    );
  }

  /// Individual cell
  Widget _buildCell(BuildContext context, String value) {
    final colorExt = context.appColors;
    final textTheme = Theme.of(context).textTheme;

    // Checkmark for "✓"
    if (value == '✓') {
      return Center(
        child: Icon(Icons.check, size: 20, color: colorExt.stateSuccessText),
      );
    }

    // Empty for "✗" or empty string
    if (value == '✗' || value.isEmpty) {
      return const Center(child: Text('—'));
    }

    // Regular text
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 16.0,
      ),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: textTheme.bodySmall!.copyWith(color: colorExt.textSecondary),
      ),
    );
  }
}
