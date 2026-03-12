import 'package:flutter/material.dart';
import '../../../../core/theme/extensions/app_color_extension.dart';
import '../../../../core/theme/extensions/app_spacing_extension.dart';
import '../../../../core/theme/border_tokens.dart';
import '../../../../core/theme/enums.dart';
import '../../../../core/widgets/app_collapsible.dart';
import '../../../../core/widgets/app_timeline.dart';
import '../../../../core/widgets/app_calendar.dart';
import '../../../../core/widgets/app_image_gallery.dart';
import '../../../../core/widgets/app_rating.dart';
import '../../../../core/widgets/app_code_block.dart';
import '../../../../core/widgets/app_resizable.dart';
import '../../../../core/widgets/app_chart.dart';
import '../../../../core/widgets/app_rich_text_editor.dart';
import '../../../../core/widgets/app_kanban_board.dart';
import '../../../../core/widgets/app_carousel.dart';
import '../../../../core/widgets/app_card.dart';

/// Phase 7: 특수 컴포넌트 쇼케이스 페이지
class SpecialComponentsPage extends StatefulWidget {
  const SpecialComponentsPage({super.key});

  @override
  State<SpecialComponentsPage> createState() => _SpecialComponentsPageState();
}

class _SpecialComponentsPageState extends State<SpecialComponentsPage> {
  late RichTextEditorController _readOnlyController;

  @override
  void initState() {
    super.initState();
    _readOnlyController = RichTextEditorController(
      initialText: '이것은 읽기 전용 에디터입니다. 내용을 수정할 수 없습니다.',
    );
  }

  @override
  void dispose() {
    _readOnlyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 7: 특수 컴포넌트'),
        backgroundColor: colorExt.surfaceSecondary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacingExt.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(context, 'AppCollapsible'),
            _buildCollapsibleSection(context),
            SizedBox(height: spacingExt.xl),
            _buildSectionTitle(context, 'AppTimeline'),
            _buildTimelineSection(context),
            SizedBox(height: spacingExt.xl),
            _buildSectionTitle(context, 'AppCalendar'),
            _buildCalendarSection(context),
            SizedBox(height: spacingExt.xl),
            _buildSectionTitle(context, 'AppImageGallery'),
            _buildImageGallerySection(context),
            SizedBox(height: spacingExt.xl),
            _buildSectionTitle(context, 'AppRating'),
            _buildRatingSection(context),
            SizedBox(height: spacingExt.xl),
            _buildSectionTitle(context, 'AppCodeBlock'),
            _buildCodeBlockSection(context),
            SizedBox(height: spacingExt.xl),
            _buildSectionTitle(context, 'AppResizable'),
            _buildResizableSection(context),
            SizedBox(height: spacingExt.xl),
            _buildSectionTitle(context, 'AppChart'),
            _buildChartSection(context),
            SizedBox(height: spacingExt.xl),
            _buildSectionTitle(context, 'AppRichTextEditor'),
            _buildRichTextEditorSection(context),
            SizedBox(height: spacingExt.xl),
            _buildSectionTitle(context, 'AppKanbanBoard'),
            _buildKanbanBoardSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;

    return Padding(
      padding: EdgeInsets.only(bottom: spacingExt.medium),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: colorExt.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Plain 스타일
        Text('Plain 스타일:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        AppCollapsible(
          title: '더 보기',
          subtitle: '클릭하여 내용 확인',
          child: const Text('숨겨진 콘텐츠가 여기에 표시됩니다.'),
        ),
        SizedBox(height: spacingExt.medium),

        // Bordered 스타일
        Text('Bordered 스타일:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        AppCollapsible(
          title: '섹션 제목',
          style: AppCollapsibleStyle.bordered,
          initiallyExpanded: true,
          child: const Text('테두리가 있는 접기/펼치기 컴포넌트입니다.'),
        ),
        SizedBox(height: spacingExt.medium),

        // Card 스타일
        Text('Card 스타일:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        AppCollapsible(
          title: '카드 스타일',
          leading: const Icon(Icons.info_outline),
          style: AppCollapsibleStyle.card,
          child: const Text('카드 형태의 접기/펼치기 컴포넌트입니다.'),
        ),
        SizedBox(height: spacingExt.medium),

        // 그룹
        Text('Collapsible 그룹:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        AppCollapsibleGroup(
          style: AppCollapsibleStyle.bordered,
          items: [
            AppCollapsibleItem(
              title: '질문 1: Flutter란?',
              child: const Text('Flutter는 Google이 개발한 UI 툴킷입니다.'),
            ),
            AppCollapsibleItem(
              title: '질문 2: Dart란?',
              child: const Text('Dart는 Flutter에서 사용하는 프로그래밍 언어입니다.'),
            ),
            AppCollapsibleItem(
              title: '질문 3: 위젯이란?',
              child: const Text('위젯은 Flutter UI의 기본 구성 요소입니다.'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineSection(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 세로 타임라인
        Text('세로 타임라인:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        AppTimeline(
          items: [
            AppTimelineItem(
              title: '주문 접수',
              description: '주문이 성공적으로 접수되었습니다.',
              timestamp: DateTime.now().subtract(const Duration(hours: 2)),
              icon: Icons.check_circle,
              status: AppTimelineItemStatus.completed,
            ),
            AppTimelineItem(
              title: '결제 완료',
              description: '결제가 승인되었습니다.',
              timestamp: DateTime.now().subtract(const Duration(hours: 1)),
              icon: Icons.payment,
              status: AppTimelineItemStatus.completed,
            ),
            AppTimelineItem(
              title: '배송 준비 중',
              description: '상품을 포장하고 있습니다.',
              icon: Icons.inventory_2,
              status: AppTimelineItemStatus.active,
            ),
            AppTimelineItem(
              title: '배송 중',
              icon: Icons.local_shipping,
              status: AppTimelineItemStatus.pending,
            ),
            AppTimelineItem(
              title: '배송 완료',
              icon: Icons.home,
              status: AppTimelineItemStatus.pending,
            ),
          ],
        ),
        SizedBox(height: spacingExt.large),

        // 가로 타임라인
        Text('가로 타임라인:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        SizedBox(
          height: 120,
          child: AppTimeline(
            orientation: AppTimelineOrientation.horizontal,
            items: [
              AppTimelineItem(
                title: 'Step 1',
                icon: Icons.edit,
                status: AppTimelineItemStatus.completed,
              ),
              AppTimelineItem(
                title: 'Step 2',
                icon: Icons.preview,
                status: AppTimelineItemStatus.completed,
              ),
              AppTimelineItem(
                title: 'Step 3',
                icon: Icons.check,
                status: AppTimelineItemStatus.active,
              ),
              AppTimelineItem(
                title: 'Step 4',
                icon: Icons.send,
                status: AppTimelineItemStatus.pending,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarSection(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('기본 캘린더:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        SizedBox(width: 350, child: _CalendarDemo()),
        SizedBox(height: spacingExt.medium),

        Text('컴팩트 캘린더:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        SizedBox(
          width: 280,
          child: AppCalendar(
            style: AppCalendarStyle.compact,
            selectedDate: DateTime.now(),
            events: {
              DateTime(DateTime.now().year, DateTime.now().month, 10): [
                'Event 1',
              ],
              DateTime(DateTime.now().year, DateTime.now().month, 15): [
                'Event 2',
              ],
              DateTime(DateTime.now().year, DateTime.now().month, 20): [
                'Event 3',
                'Event 4',
              ],
            },
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallerySection(BuildContext context) {
    final spacingExt = context.appSpacing;

    // 샘플 이미지 URL (placeholder)
    final sampleImages = [
      AppGalleryImage(
        url: 'https://picsum.photos/seed/1/400/300',
        caption: '샘플 이미지 1',
      ),
      AppGalleryImage(
        url: 'https://picsum.photos/seed/2/400/300',
        caption: '샘플 이미지 2',
      ),
      AppGalleryImage(
        url: 'https://picsum.photos/seed/3/400/300',
        caption: '샘플 이미지 3',
      ),
      AppGalleryImage(
        url: 'https://picsum.photos/seed/4/400/300',
        caption: '샘플 이미지 4',
      ),
      AppGalleryImage(
        url: 'https://picsum.photos/seed/5/400/300',
        caption: '샘플 이미지 5',
      ),
      AppGalleryImage(
        url: 'https://picsum.photos/seed/6/400/300',
        caption: '샘플 이미지 6',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('그리드 갤러리:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        AppImageGallery(images: sampleImages, crossAxisCount: 3, spacing: 8),
        SizedBox(height: spacingExt.large),

        Text('풀 와이드 이미지 캐러셀:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        // 전체 너비를 사용하는 큰 이미지 캐러셀
        _buildFullWidthImageCarousel(context, sampleImages),
      ],
    );
  }

  /// 전체 너비를 사용하는 이미지 캐러셀
  Widget _buildFullWidthImageCarousel(
    BuildContext context,
    List<AppGalleryImage> images,
  ) {
    final colorExt = context.appColors;
    final spacingExt = context.appSpacing;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 전체 너비에서 패딩 제외한 크기
        final fullWidth = constraints.maxWidth;
        // 카드 내부 패딩(AppCard 기본 패딩 16px * 2)을 고려한 이미지 너비
        final cardPadding = 32.0;
        final imageWidth = fullWidth - 48 - cardPadding;
        // 16:9 비율로 이미지 높이 계산
        final imageHeight = imageWidth * 9 / 16;

        return AppCarousel(
          items: images.asMap().entries.map((entry) {
            final index = entry.key;
            final image = entry.value;

            return AppCard(
              elevation: AppCardElevation.low,
              onTap: () {
                debugPrint('Full width image ${index + 1} tapped');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 큰 이미지 영역 (16:9 비율)
                  Container(
                    height: imageHeight,
                    decoration: BoxDecoration(
                      color: colorExt.surfaceQuaternary,
                      borderRadius: BorderRadius.circular(
                        BorderTokens.radiusSmall,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      image.url,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            size: 80,
                            color: colorExt.textTertiary,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: spacingExt.large),
                  // 제목
                  Text(
                    image.caption ?? 'Image ${index + 1}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorExt.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: spacingExt.small),
                  // 설명
                  Text(
                    '고해상도 이미지 샘플입니다. 전체 너비를 활용한 대형 캐러셀로, 갤러리나 포트폴리오 등에 적합합니다.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorExt.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: spacingExt.medium),
                  // 메타 정보
                  Row(
                    children: [
                      Icon(
                        Icons.photo_size_select_actual,
                        size: 16,
                        color: colorExt.textTertiary,
                      ),
                      SizedBox(width: spacingExt.xs),
                      Text(
                        '1920 x 1080',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorExt.textTertiary,
                        ),
                      ),
                      SizedBox(width: spacingExt.large),
                      Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: colorExt.textTertiary,
                      ),
                      SizedBox(width: spacingExt.xs),
                      Text(
                        '${(index + 1) * 234}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorExt.textTertiary,
                        ),
                      ),
                      SizedBox(width: spacingExt.large),
                      Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: colorExt.textTertiary,
                      ),
                      SizedBox(width: spacingExt.xs),
                      Text(
                        '${(index + 1) * 42}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorExt.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
          // 전체 너비에서 약간의 여백만 남기고 사용
          itemWidth: fullWidth - 48,
          gap: 24,
          showNavigation: true,
          padding: EdgeInsets.symmetric(horizontal: 24),
        );
      },
    );
  }

  Widget _buildRatingSection(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('별점 스타일:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        _RatingDemo(),
        SizedBox(height: spacingExt.medium),

        Text('하트 스타일:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        AppRating(
          value: 4,
          style: AppRatingStyle.heart,
          readOnly: true,
          showValue: true,
          auxiliaryText: '(128개의 리뷰)',
        ),
        SizedBox(height: spacingExt.medium),

        Text('숫자 스타일:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        AppRating(
          value: 4.5,
          style: AppRatingStyle.numeric,
          auxiliaryText: '(256개의 평가)',
        ),
        SizedBox(height: spacingExt.medium),

        Text('크기 비교:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        Wrap(
          spacing: spacingExt.medium,
          runSpacing: spacingExt.small,
          children: [
            AppRating(value: 3.5, size: AppRatingSize.small, readOnly: true),
            AppRating(value: 3.5, size: AppRatingSize.medium, readOnly: true),
            AppRating(value: 3.5, size: AppRatingSize.large, readOnly: true),
          ],
        ),
      ],
    );
  }

  Widget _buildCodeBlockSection(BuildContext context) {
    final spacingExt = context.appSpacing;

    const dartCode = '''
void main() {
  final greeting = 'Hello, World!';
  print(greeting);

  for (var i = 0; i < 5; i++) {
    print('Count: \$i');
  }
}
''';

    const jsonCode = '''
{
  "name": "Flutter App",
  "version": "1.0.0",
  "dependencies": {
    "flutter": "^3.0.0"
  }
}
''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dart 코드:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        AppCodeBlock(
          code: dartCode,
          language: AppCodeBlockLanguage.dart,
          filename: 'main.dart',
          showLineNumbers: true,
        ),
        SizedBox(height: spacingExt.medium),

        Text('JSON 코드:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        AppCodeBlock(
          code: jsonCode,
          language: AppCodeBlockLanguage.json,
          theme: AppCodeBlockTheme.dark,
        ),
        SizedBox(height: spacingExt.medium),

        Text('인라인 코드:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const Text('다음 명령어를 실행하세요: '),
            const AppInlineCode(code: 'flutter run'),
            const Text(' 또는 '),
            const AppInlineCode(code: 'flutter build'),
          ],
        ),
      ],
    );
  }

  Widget _buildResizableSection(BuildContext context) {
    final spacingExt = context.appSpacing;
    final colorExt = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('가로 리사이즈:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        SizedBox(
          height: 150,
          child: Row(
            children: [
              AppResizable(
                direction: AppResizeDirection.horizontal,
                initialSize: 200,
                minSize: 100,
                maxSize: 400,
                child: Container(
                  color: colorExt.surfaceSecondary,
                  alignment: Alignment.center,
                  child: const Text('리사이즈 가능한 패널'),
                ),
              ),
              Expanded(
                child: Container(
                  color: colorExt.surfaceTertiary,
                  alignment: Alignment.center,
                  child: const Text('나머지 영역'),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacingExt.large),

        Text('분할 패널:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        SizedBox(
          height: 200,
          child: AppSplitPanel(
            direction: AppResizeDirection.horizontal,
            initialRatio: 0.4,
            firstChild: Container(
              color: colorExt.surfaceSecondary,
              alignment: Alignment.center,
              child: const Text('첫 번째 패널'),
            ),
            secondChild: Container(
              color: colorExt.surfaceTertiary,
              alignment: Alignment.center,
              child: const Text('두 번째 패널'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('라인 차트:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        SizedBox(
          height: 300,
          child: AppChart(
            type: AppChartType.line,
            data: [
              ChartSeries(name: '매출', values: [120, 180, 150, 200, 250, 220]),
              ChartSeries(name: '비용', values: [80, 100, 90, 130, 150, 140]),
            ],
            labels: ['1월', '2월', '3월', '4월', '5월', '6월'],
            showLegend: true,
          ),
        ),
        SizedBox(height: spacingExt.large),

        Text('바 차트:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        SizedBox(
          height: 300,
          child: AppChart(
            type: AppChartType.bar,
            data: [
              ChartSeries(name: '2023', values: [30, 50, 40]),
              ChartSeries(name: '2024', values: [45, 60, 55]),
            ],
            labels: ['Q1', 'Q2', 'Q3'],
            showLegend: true,
            showValues: true,
          ),
        ),
        SizedBox(height: spacingExt.large),

        Text('파이 차트:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        Wrap(
          spacing: spacingExt.large,
          runSpacing: spacingExt.large,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: AppChart(
                type: AppChartType.pie,
                data: [
                  ChartSeries(name: '카테고리', values: [40, 30, 20, 10]),
                ],
                labels: ['A', 'B', 'C', 'D'],
                showValues: true,
              ),
            ),
            SizedBox(
              width: 300,
              height: 300,
              child: AppChart(
                type: AppChartType.doughnut,
                data: [
                  ChartSeries(name: '카테고리', values: [35, 25, 25, 15]),
                ],
                labels: ['제품 A', '제품 B', '제품 C', '제품 D'],
                showValues: true,
              ),
            ),
          ],
        ),
        SizedBox(height: spacingExt.large),

        Text('영역 차트:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        SizedBox(
          height: 300,
          child: AppChart(
            type: AppChartType.area,
            data: [
              ChartSeries(
                name: '트래픽',
                values: [100, 150, 130, 180, 200, 170, 220],
              ),
            ],
            labels: ['월', '화', '수', '목', '금', '토', '일'],
          ),
        ),
      ],
    );
  }

  Widget _buildRichTextEditorSection(BuildContext context) {
    final spacingExt = context.appSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('기본 에디터:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        _RichTextEditorDemo(),
        SizedBox(height: spacingExt.large),

        Text('읽기 전용:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        AppRichTextEditor(
          controller: _readOnlyController,
          readOnly: true,
          showToolbar: false,
          minHeight: 80,
        ),
        SizedBox(height: spacingExt.large),

        Text('제한된 포맷:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        AppRichTextEditor(
          placeholder: '굵게, 기울임, 링크만 사용 가능합니다...',
          enabledFormats: [
            RichTextFormat.bold,
            RichTextFormat.italic,
            RichTextFormat.link,
          ],
          minHeight: 100,
        ),
      ],
    );
  }

  Widget _buildKanbanBoardSection(BuildContext context) {
    final spacingExt = context.appSpacing;
    final colorExt = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('기본 칸반 보드:', style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: spacingExt.small),
        SizedBox(
          height: 500,
          child: AppKanbanBoard(
            columns: [
              KanbanColumn(
                id: 'todo',
                title: 'To Do',
                cards: [
                  KanbanCard(
                    id: '1',
                    title: '사용자 인증 구현',
                    description: 'OAuth 2.0 기반 로그인 시스템 개발',
                    labels: [
                      KanbanLabel(text: '기능', color: colorExt.stateInfoBg),
                      KanbanLabel(
                        text: '우선순위 높음',
                        color: colorExt.stateErrorBg,
                      ),
                    ],
                    dueDate: DateTime.now().add(const Duration(days: 3)),
                    commentCount: 5,
                    attachmentCount: 2,
                  ),
                  KanbanCard(
                    id: '2',
                    title: 'API 문서 작성',
                    labels: [
                      KanbanLabel(text: '문서', color: colorExt.stateWarningBg),
                    ],
                    dueDate: DateTime.now().add(const Duration(days: 7)),
                  ),
                ],
              ),
              KanbanColumn(
                id: 'in_progress',
                title: 'In Progress',
                cards: [
                  KanbanCard(
                    id: '3',
                    title: '대시보드 UI 디자인',
                    description: '관리자 대시보드 화면 설계',
                    labels: [
                      KanbanLabel(text: '디자인', color: colorExt.brandPrimary),
                    ],
                    dueDate: DateTime.now().add(const Duration(days: 1)),
                    commentCount: 12,
                  ),
                ],
              ),
              KanbanColumn(
                id: 'review',
                title: 'Review',
                cards: [
                  KanbanCard(
                    id: '4',
                    title: '코드 리뷰 요청',
                    labels: [
                      KanbanLabel(text: '리뷰', color: colorExt.stateSuccessBg),
                    ],
                  ),
                ],
              ),
              KanbanColumn(
                id: 'done',
                title: 'Done',
                cards: [
                  KanbanCard(
                    id: '5',
                    title: '프로젝트 초기 설정',
                    labels: [
                      KanbanLabel(text: '설정', color: colorExt.textTertiary),
                    ],
                  ),
                  KanbanCard(id: '6', title: '개발 환경 구축'),
                ],
              ),
            ],
            onCardMoved: (card, from, to, index) {
              // 카드 이동 처리
            },
            onCardTap: (card) {
              // 카드 클릭 처리
            },
            showAddCard: true,
          ),
        ),
      ],
    );
  }
}

/// 리치 텍스트 에디터 데모 (상태 관리)
class _RichTextEditorDemo extends StatefulWidget {
  @override
  State<_RichTextEditorDemo> createState() => _RichTextEditorDemoState();
}

class _RichTextEditorDemoState extends State<_RichTextEditorDemo> {
  late RichTextEditorController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RichTextEditorController(
      initialText: '여기에 텍스트를 입력하세요.\n\n툴바의 버튼을 사용하여 서식을 적용할 수 있습니다.',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppRichTextEditor(
      controller: _controller,
      placeholder: '내용을 입력하세요...',
      minHeight: 200,
      onChanged: (text) {
        // 텍스트 변경 처리
      },
    );
  }
}

/// 캘린더 데모 (상태 관리)
class _CalendarDemo extends StatefulWidget {
  @override
  State<_CalendarDemo> createState() => _CalendarDemoState();
}

class _CalendarDemoState extends State<_CalendarDemo> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCalendar(
          selectedDate: _selectedDate,
          onDateSelected: (date) {
            setState(() => _selectedDate = date);
          },
          events: {
            DateTime(DateTime.now().year, DateTime.now().month, 10): ['이벤트 1'],
            DateTime(DateTime.now().year, DateTime.now().month, 15): ['이벤트 2'],
            DateTime(DateTime.now().year, DateTime.now().month, 20): ['이벤트 3'],
          },
        ),
        if (_selectedDate != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '선택된 날짜: ${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
}

/// 별점 데모 (상태 관리)
class _RatingDemo extends StatefulWidget {
  @override
  State<_RatingDemo> createState() => _RatingDemoState();
}

class _RatingDemoState extends State<_RatingDemo> {
  double _rating = 3.5;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppRating(
          value: _rating,
          onChanged: (value) {
            setState(() => _rating = value);
          },
          showValue: true,
        ),
        const SizedBox(width: 16),
        Text('(드래그하여 변경)'),
      ],
    );
  }
}
