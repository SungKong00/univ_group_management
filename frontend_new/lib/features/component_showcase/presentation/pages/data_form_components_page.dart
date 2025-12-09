import 'package:flutter/material.dart';
import '../../../../core/theme/extensions/app_color_extension.dart';
import '../../../../core/theme/extensions/app_spacing_extension.dart';
import '../../../../core/theme/responsive_tokens.dart';
import '../../../../core/widgets/app_section.dart';
import '../../../../core/widgets/app_switch.dart';
import '../../../../core/widgets/app_radio_group.dart';
import '../../../../core/widgets/app_checkbox_group.dart';
import '../../../../core/widgets/app_search_input.dart';
import '../../../../core/widgets/app_slider.dart';
import '../../../../core/widgets/app_textarea.dart';
import '../../../../core/widgets/app_otp_input.dart';
import '../../../../core/widgets/app_color_picker.dart';
import '../../../../core/widgets/app_file_upload.dart';
import '../../../../core/widgets/app_data_table.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/theme/enums.dart';

/// Phase 5: 데이터 & 폼 확장 컴포넌트 쇼케이스
class DataFormComponentsPage extends StatefulWidget {
  const DataFormComponentsPage({super.key});

  @override
  State<DataFormComponentsPage> createState() => _DataFormComponentsPageState();
}

class _DataFormComponentsPageState extends State<DataFormComponentsPage> {
  // Switch states
  bool _switchValue1 = false;
  bool _switchValue2 = true;
  bool _switchValue3 = false;
  bool _switchValue4 = true;
  bool _switchValue5 = false;
  bool _switchLoading = false;

  // Switch group states
  bool _notifications = true;
  bool _sound = true;
  bool _vibration = false;
  bool _darkMode = false;

  // Radio group states
  String? _selectedPayment = 'card';
  String? _selectedNotification = 'all';
  String? _selectedSize = 'medium';
  String? _selectedSizeSmall = 'a';
  String? _selectedSizeLarge = 'a';
  String? _selectedDisabled = 'a';

  // Checkbox group states
  List<String> _selectedInterests = ['tech'];
  List<String> _selectedColors = [];
  bool _agreeTerms = false;
  List<String> _selectedNotificationTypes = ['email'];

  // Search input states
  final TextEditingController _searchController = TextEditingController();
  List<String> _suggestions = [];
  List<String> _searchHistory = ['Flutter', 'Dart', 'Widget'];
  final List<String> _allSuggestions = [
    'Flutter',
    'Flutter Widget',
    'Flutter State',
    'Dart',
    'Dart Async',
    'Design Pattern',
    'Clean Architecture',
  ];

  // Slider states
  double _volume = 50;
  double _brightness = 75;
  double _rating = 3;
  RangeValues _priceRange = const RangeValues(100, 500);
  double _sliderSizeSmall = 50;
  double _sliderSizeLarge = 50;
  RangeValues _percentRange = const RangeValues(20, 80);

  // Textarea states
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  // OTP states
  bool _otpSuccess = false;
  String? _otpError;

  // Color picker states
  Color? _selectedColor;
  Color? _labelColor;

  // File upload states
  List<UploadedFile> _uploadedFiles = [];

  // Data table states
  String? _sortColumnId;
  AppDataTableSortDirection _sortDirection =
      AppDataTableSortDirection.ascending;
  Set<_SampleUser> _selectedUsers = {};

  @override
  void dispose() {
    _searchController.dispose();
    _bioController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _filterSuggestions(String query) {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    setState(() {
      _suggestions = _allSuggestions
          .where((s) => s.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorExt = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phase 5: 데이터 & 폼 컴포넌트'),
        backgroundColor: colorExt.surfaceSecondary,
      ),
      body: ResponsiveBuilder(
        builder: (context, screenSize, width) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveTokens.pagePadding(width)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSwitchSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.3,
                ),
                _buildSwitchSizesSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.3,
                ),
                _buildSwitchStatesSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.3,
                ),
                _buildSwitchGroupSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.3,
                ),
                _buildSwitchCustomColorsSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.5,
                ),
                // Radio Group Sections
                _buildRadioGroupSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.3,
                ),
                _buildRadioGroupVariantsSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.5,
                ),
                // Checkbox Group Sections
                _buildCheckboxGroupSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.3,
                ),
                _buildCheckboxVariantsSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.5,
                ),
                // Search Input Sections
                _buildSearchInputSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.5,
                ),
                // Slider Sections
                _buildSliderSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.3,
                ),
                _buildRangeSliderSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.5,
                ),
                // Textarea Sections
                _buildTextareaSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.5,
                ),
                // OTP Input Sections
                _buildOtpInputSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.5,
                ),
                // Color Picker Sections
                _buildColorPickerSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.5,
                ),
                // File Upload Sections
                _buildFileUploadSection(width),
                SizedBox(
                  height: ResponsiveTokens.sectionVerticalGap(width) * 0.5,
                ),
                // Data Table Sections
                _buildDataTableSection(width),
              ],
            ),
          );
        },
      ),
    );
  }

  // ========================================================
  // Section 1: 기본 Switch
  // ========================================================
  Widget _buildSwitchSection(double width) {
    return AppSection(
      title: 'AppSwitch - 기본',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기본 토글 스위치',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.medium,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppSwitch(
                value: _switchValue1,
                onChanged: (value) => setState(() => _switchValue1 = value),
              ),
              Text(
                _switchValue1 ? 'ON' : 'OFF',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _switchValue1
                      ? context.appColors.stateSuccessText
                      : context.appColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Text(
            '라벨 포함',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 0.5),
          AppSwitch(
            value: _switchValue2,
            onChanged: (value) => setState(() => _switchValue2 = value),
            label: '알림 받기',
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Text(
            '라벨 + 설명 포함',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 0.5),
          AppSwitch(
            value: _switchValue3,
            onChanged: (value) => setState(() => _switchValue3 = value),
            label: '마케팅 수신 동의',
            description: '이벤트, 할인 정보 등을 이메일로 받습니다',
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 2: Switch 크기
  // ========================================================
  Widget _buildSwitchSizesSection(double width) {
    return AppSection(
      title: 'AppSwitch - 크기별',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.large,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Small (36x20)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  AppSwitch(
                    value: _switchValue4,
                    onChanged: (value) => setState(() => _switchValue4 = value),
                    size: AppSwitchSize.small,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Medium (48x26) - 기본',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  AppSwitch(
                    value: _switchValue4,
                    onChanged: (value) => setState(() => _switchValue4 = value),
                    size: AppSwitchSize.medium,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Large (60x32)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  AppSwitch(
                    value: _switchValue4,
                    onChanged: (value) => setState(() => _switchValue4 = value),
                    size: AppSwitchSize.large,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 3: Switch 상태
  // ========================================================
  Widget _buildSwitchStatesSection(double width) {
    return AppSection(
      title: 'AppSwitch - 상태별',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.large,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '비활성화 (OFF)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  const AppSwitch(
                    value: false,
                    isDisabled: true,
                    label: '편집 불가',
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '비활성화 (ON)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  const AppSwitch(
                    value: true,
                    isDisabled: true,
                    label: '항상 활성',
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '로딩 중',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  AppSwitch(
                    value: _switchLoading,
                    onChanged: (value) async {
                      setState(() => _switchLoading = value);
                    },
                    isLoading: true,
                    label: '저장 중...',
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'onChanged 없음',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  const AppSwitch(value: false, label: '읽기 전용'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 4: Switch 그룹
  // ========================================================
  Widget _buildSwitchGroupSection(double width) {
    return AppSection(
      title: 'AppSwitchGroup - 설정 그룹',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '알림 설정',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppSwitchGroup(
            items: [
              AppSwitchItem(
                value: _notifications,
                label: '푸시 알림',
                description: '새로운 메시지가 오면 알림을 받습니다',
                onChanged: (v) => setState(() => _notifications = v),
              ),
              AppSwitchItem(
                value: _sound,
                label: '알림 소리',
                description: '알림 시 소리를 재생합니다',
                onChanged: (v) => setState(() => _sound = v),
              ),
              AppSwitchItem(
                value: _vibration,
                label: '진동',
                description: '알림 시 진동을 사용합니다',
                onChanged: (v) => setState(() => _vibration = v),
              ),
            ],
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '앱 설정',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppSwitchGroup(
            size: AppSwitchSize.small,
            items: [
              AppSwitchItem(
                value: _darkMode,
                label: '다크 모드',
                onChanged: (v) => setState(() => _darkMode = v),
              ),
              const AppSwitchItem(
                value: true,
                label: '자동 업데이트',
                isDisabled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 5: 커스텀 색상
  // ========================================================
  Widget _buildSwitchCustomColorsSection(double width) {
    return AppSection(
      title: 'AppSwitch - 커스텀 색상',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.large,
            children: [
              AppSwitch(
                value: _switchValue5,
                onChanged: (value) => setState(() => _switchValue5 = value),
                label: '성공 (Green)',
                activeColor: context.appColors.stateSuccessBg,
              ),
              AppSwitch(
                value: _switchValue5,
                onChanged: (value) => setState(() => _switchValue5 = value),
                label: '정보 (Blue)',
                activeColor: context.appColors.stateInfoBg,
              ),
              AppSwitch(
                value: _switchValue5,
                onChanged: (value) => setState(() => _switchValue5 = value),
                label: '경고 (Orange)',
                activeColor: context.appColors.stateWarningBg,
              ),
              AppSwitch(
                value: _switchValue5,
                onChanged: (value) => setState(() => _switchValue5 = value),
                label: '에러 (Red)',
                activeColor: context.appColors.stateErrorBg,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 6: Radio Group 기본
  // ========================================================
  Widget _buildRadioGroupSection(double width) {
    return AppSection(
      title: 'AppRadioGroup - 기본',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '결제 방법 선택',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppRadioGroup<String>(
            label: '결제 방법',
            items: const [
              AppRadioItem(value: 'card', label: '신용카드'),
              AppRadioItem(value: 'bank', label: '계좌이체'),
              AppRadioItem(value: 'mobile', label: '휴대폰 결제'),
            ],
            value: _selectedPayment,
            onChanged: (value) => setState(() => _selectedPayment = value),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '설명 포함 옵션',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppRadioGroup<String>(
            label: '알림 설정',
            items: const [
              AppRadioItem(
                value: 'all',
                label: '모든 알림',
                description: '모든 활동에 대해 알림을 받습니다',
              ),
              AppRadioItem(
                value: 'mentions',
                label: '멘션만',
                description: '나를 언급한 경우에만 알림을 받습니다',
              ),
              AppRadioItem(
                value: 'none',
                label: '알림 끄기',
                description: '알림을 받지 않습니다',
              ),
            ],
            value: _selectedNotification,
            onChanged: (value) => setState(() => _selectedNotification = value),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 7: Radio Group 변형
  // ========================================================
  Widget _buildRadioGroupVariantsSection(double width) {
    return AppSection(
      title: 'AppRadioGroup - 변형',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '가로 배치',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppRadioGroup<String>(
            orientation: AppRadioOrientation.horizontal,
            items: const [
              AppRadioItem(value: 'small', label: 'Small'),
              AppRadioItem(value: 'medium', label: 'Medium'),
              AppRadioItem(value: 'large', label: 'Large'),
            ],
            value: _selectedSize,
            onChanged: (value) => setState(() => _selectedSize = value),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.large,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '크기: Small',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  AppRadioGroup<String>(
                    size: AppRadioSize.small,
                    items: const [
                      AppRadioItem(value: 'a', label: '옵션 A'),
                      AppRadioItem(value: 'b', label: '옵션 B'),
                    ],
                    value: _selectedSizeSmall,
                    onChanged: (value) =>
                        setState(() => _selectedSizeSmall = value),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '크기: Large',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  AppRadioGroup<String>(
                    size: AppRadioSize.large,
                    items: const [
                      AppRadioItem(value: 'a', label: '옵션 A'),
                      AppRadioItem(value: 'b', label: '옵션 B'),
                    ],
                    value: _selectedSizeLarge,
                    onChanged: (value) =>
                        setState(() => _selectedSizeLarge = value),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '비활성화',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  AppRadioGroup<String>(
                    isDisabled: true,
                    items: const [
                      AppRadioItem(value: 'a', label: '옵션 A'),
                      AppRadioItem(value: 'b', label: '옵션 B'),
                    ],
                    value: _selectedDisabled,
                    onChanged: (value) =>
                        setState(() => _selectedDisabled = value),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 8: Checkbox Group 기본
  // ========================================================
  Widget _buildCheckboxGroupSection(double width) {
    return AppSection(
      title: 'AppCheckboxGroup - 기본',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '관심 분야 선택 (다중 선택)',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppCheckboxGroup<String>(
            label: '관심 분야',
            items: const [
              AppCheckboxItem(value: 'tech', label: '기술'),
              AppCheckboxItem(value: 'design', label: '디자인'),
              AppCheckboxItem(value: 'business', label: '비즈니스'),
              AppCheckboxItem(value: 'marketing', label: '마케팅'),
            ],
            values: _selectedInterests,
            onChanged: (values) => setState(() => _selectedInterests = values),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '최대 선택 제한 (2개)',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppCheckboxGroup<String>(
            label: '좋아하는 색상 (최대 2개)',
            maxSelections: 2,
            items: const [
              AppCheckboxItem(value: 'red', label: '빨강'),
              AppCheckboxItem(value: 'blue', label: '파랑'),
              AppCheckboxItem(value: 'green', label: '초록'),
              AppCheckboxItem(value: 'yellow', label: '노랑'),
            ],
            values: _selectedColors,
            onChanged: (values) => setState(() => _selectedColors = values),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 9: Checkbox 변형
  // ========================================================
  Widget _buildCheckboxVariantsSection(double width) {
    return AppSection(
      title: 'AppCheckbox - 변형',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '단일 체크박스',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppCheckbox(
            value: _agreeTerms,
            onChanged: (value) => setState(() => _agreeTerms = value),
            label: '이용약관에 동의합니다',
            description: '서비스 이용을 위해 필수로 동의해야 합니다',
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '가로 배치',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppCheckboxGroup<String>(
            orientation: AppCheckboxOrientation.horizontal,
            items: const [
              AppCheckboxItem(value: 'email', label: '이메일'),
              AppCheckboxItem(value: 'sms', label: 'SMS'),
              AppCheckboxItem(value: 'push', label: '푸시'),
            ],
            values: _selectedNotificationTypes,
            onChanged: (values) =>
                setState(() => _selectedNotificationTypes = values),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.large,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '크기: Small',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  const AppCheckbox(
                    value: true,
                    size: AppCheckboxSize.small,
                    label: '작은 체크박스',
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '크기: Large',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  const AppCheckbox(
                    value: true,
                    size: AppCheckboxSize.large,
                    label: '큰 체크박스',
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '비활성화',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  const AppCheckbox(
                    value: true,
                    isDisabled: true,
                    label: '비활성화 체크박스',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 10: Search Input
  // ========================================================
  Widget _buildSearchInputSection(double width) {
    return AppSection(
      title: 'AppSearchInput - 검색 입력',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기본 검색',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppSearchInput(placeholder: '검색어를 입력하세요', onSubmitted: (value) {}),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '자동완성 서제스천',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppSearchInput(
            controller: _searchController,
            placeholder: 'Flutter 관련 검색',
            suggestions: _suggestions,
            onChanged: _filterSuggestions,
            onSuggestionSelected: (suggestion) {
              _searchController.text = suggestion;
              setState(() => _suggestions = []);
            },
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '검색 히스토리',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppSearchInput(
            placeholder: '검색 기록 보기 (포커스)',
            history: _searchHistory,
            onHistorySelected: (item) {},
            onHistoryClear: () => setState(() => _searchHistory = []),
            onHistoryRemove: (item) {
              setState(() => _searchHistory.remove(item));
            },
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.large,
            children: [
              SizedBox(
                width: 200,
                child: AppSearchInput(
                  placeholder: '로딩 중...',
                  isLoading: true,
                  onSubmitted: (value) {},
                ),
              ),
              SizedBox(
                width: 200,
                child: AppSearchInput(
                  placeholder: '비활성화',
                  isDisabled: true,
                  onSubmitted: (value) {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 11: Slider 기본
  // ========================================================
  Widget _buildSliderSection(double width) {
    return AppSection(
      title: 'AppSlider - 슬라이더',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기본 슬라이더',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppSlider(
            value: _volume,
            onChanged: (value) => setState(() => _volume = value),
            min: 0,
            max: 100,
            label: '볼륨',
            showValue: true,
            valueFormatter: (value) => '${value.toInt()}%',
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          AppSlider(
            value: _brightness,
            onChanged: (value) => setState(() => _brightness = value),
            min: 0,
            max: 100,
            label: '밝기',
            showValue: true,
            valueFormatter: (value) => '${value.toInt()}',
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '단계별 슬라이더 (분할)',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppSlider(
            value: _rating,
            onChanged: (value) => setState(() => _rating = value),
            min: 1,
            max: 5,
            divisions: 4,
            label: '평점',
            showValue: true,
            style: AppSliderStyle.stepped,
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.large,
            children: [
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '크기: Small',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appColors.textTertiary,
                      ),
                    ),
                    SizedBox(height: context.appSpacing.small),
                    AppSlider(
                      value: _sliderSizeSmall,
                      onChanged: (value) =>
                          setState(() => _sliderSizeSmall = value),
                      size: AppSliderSize.small,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '크기: Large',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appColors.textTertiary,
                      ),
                    ),
                    SizedBox(height: context.appSpacing.small),
                    AppSlider(
                      value: _sliderSizeLarge,
                      onChanged: (value) =>
                          setState(() => _sliderSizeLarge = value),
                      size: AppSliderSize.large,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '비활성화',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appColors.textTertiary,
                      ),
                    ),
                    SizedBox(height: context.appSpacing.small),
                    const AppSlider(value: 50, isDisabled: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 12: Range Slider
  // ========================================================
  Widget _buildRangeSliderSection(double width) {
    return AppSection(
      title: 'AppRangeSlider - 범위 슬라이더',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRangeSlider(
            values: _priceRange,
            onChanged: (values) => setState(() => _priceRange = values),
            min: 0,
            max: 1000,
            label: '가격 범위',
            showValue: true,
            valueFormatter: (value) => '${value.toInt()}원',
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          AppRangeSlider(
            values: _percentRange,
            onChanged: (values) => setState(() => _percentRange = values),
            min: 0,
            max: 100,
            divisions: 10,
            label: '퍼센트 범위 (분할)',
            showValue: true,
            valueFormatter: (value) => '${value.toInt()}%',
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 13: Textarea
  // ========================================================
  Widget _buildTextareaSection(double width) {
    return AppSection(
      title: 'AppTextarea - 텍스트 영역',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기본 텍스트 영역',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppTextarea(
            controller: _bioController,
            label: '자기소개',
            placeholder: '자신에 대해 소개해 주세요',
            helperText: '최대 200자까지 입력 가능합니다',
            maxLength: 200,
            showCharacterCount: true,
            onChanged: (value) {},
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '자동 높이 조절',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppTextarea(
            controller: _noteController,
            label: '메모',
            placeholder: '메모를 입력하세요 (자동 확장)',
            minLines: 2,
            autoResize: true,
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.large,
            children: [
              SizedBox(
                width: 300,
                child: AppTextarea(
                  label: '에러 상태',
                  placeholder: '에러 메시지 표시',
                  errorText: '필수 입력 항목입니다',
                  minLines: 2,
                ),
              ),
              SizedBox(
                width: 300,
                child: AppTextarea(
                  label: '비활성화',
                  placeholder: '비활성화 상태',
                  isDisabled: true,
                  minLines: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 14: OTP Input
  // ========================================================
  Widget _buildOtpInputSection(double width) {
    return AppSection(
      title: 'AppOtpInput - OTP 입력',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '6자리 인증 코드',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppOtpInput(
            length: 6,
            label: '인증 코드',
            onCompleted: (code) {
              setState(() {
                if (code == '123456') {
                  _otpSuccess = true;
                  _otpError = null;
                } else {
                  _otpSuccess = false;
                  _otpError = '잘못된 인증 코드입니다';
                }
              });
            },
            isSuccess: _otpSuccess,
            successText: '인증되었습니다',
            errorText: _otpError,
          ),
          SizedBox(height: context.appSpacing.small),
          Text(
            '테스트: 123456 입력 시 성공',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.appColors.textTertiary,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '4자리 코드',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppOtpInput(length: 4, onCompleted: (code) {}),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Wrap(
            spacing: context.appSpacing.xl,
            runSpacing: context.appSpacing.large,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '비밀번호 마스킹',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  AppOtpInput(
                    length: 4,
                    obscureText: true,
                    onCompleted: (code) {},
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '비활성화',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  AppOtpInput(
                    length: 4,
                    isDisabled: true,
                    onCompleted: (code) {},
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 15: Color Picker
  // ========================================================
  Widget _buildColorPickerSection(double width) {
    return AppSection(
      title: 'AppColorPicker - 색상 선택',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기본 팔레트',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppColorPicker(
            value: _selectedColor,
            onChanged: (color) => setState(() => _selectedColor = color),
            label: '테마 색상',
            showPreview: true,
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            'HEX 입력 모드',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppColorPicker(
            value: _labelColor,
            onChanged: (color) => setState(() => _labelColor = color),
            mode: AppColorPickerMode.hex,
            label: '라벨 색상',
            showPreview: true,
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '커스텀 팔레트',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppColorPicker(
            value: null,
            onChanged: (color) {},
            palette: const [
              Color(0xFFFF6B6B),
              Color(0xFF4ECDC4),
              Color(0xFF45B7D1),
              Color(0xFFFFA07A),
              Color(0xFF98D8C8),
              Color(0xFFF7DC6F),
            ],
            cellSize: 40,
            cellSpacing: 12,
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '비활성화',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppColorPicker(
            value: const Color(0xFF3B82F6),
            isDisabled: true,
            onChanged: (color) {},
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 16: File Upload
  // ========================================================
  Widget _buildFileUploadSection(double width) {
    return AppSection(
      title: 'AppFileUpload - 파일 업로드',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '드래그 앤 드롭 영역',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppFileUpload(
            type: AppFileUploadType.dropzone,
            allowedExtensions: const ['jpg', 'png', 'pdf'],
            maxFileSize: 5 * 1024 * 1024, // 5MB
            maxFiles: 5,
            selectedFiles: _uploadedFiles,
            onFilesSelected: (files) {
              setState(() {
                _uploadedFiles = [..._uploadedFiles, ...files];
              });
            },
            onFileRemoved: (file) {
              setState(() {
                _uploadedFiles.remove(file);
              });
            },
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '크기별 비교',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Wrap(
            spacing: context.appSpacing.large,
            runSpacing: context.appSpacing.large,
            children: [
              SizedBox(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Small',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appColors.textTertiary,
                      ),
                    ),
                    SizedBox(height: context.appSpacing.small),
                    AppFileUpload(
                      size: AppFileUploadSize.small,
                      onFilesSelected: (_) {},
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medium (기본)',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appColors.textTertiary,
                      ),
                    ),
                    SizedBox(height: context.appSpacing.small),
                    AppFileUpload(
                      size: AppFileUploadSize.medium,
                      onFilesSelected: (_) {},
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Large',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appColors.textTertiary,
                      ),
                    ),
                    SizedBox(height: context.appSpacing.small),
                    AppFileUpload(
                      size: AppFileUploadSize.large,
                      onFilesSelected: (_) {},
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '상태별',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Wrap(
            spacing: context.appSpacing.large,
            runSpacing: context.appSpacing.large,
            children: [
              SizedBox(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '비활성화',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appColors.textTertiary,
                      ),
                    ),
                    SizedBox(height: context.appSpacing.small),
                    AppFileUpload(isDisabled: true, onFilesSelected: (_) {}),
                  ],
                ),
              ),
              SizedBox(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '에러 상태',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appColors.textTertiary,
                      ),
                    ),
                    SizedBox(height: context.appSpacing.small),
                    AppFileUpload(
                      errorText: '파일 형식이 올바르지 않습니다',
                      onFilesSelected: (_) {},
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '업로드 진행 예시',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          AppFileUpload(
            selectedFiles: const [
              UploadedFile(
                name: 'document.pdf',
                size: 2048576,
                mimeType: 'application/pdf',
                status: AppFileUploadStatus.completed,
                progress: 1.0,
              ),
              UploadedFile(
                name: 'image.jpg',
                size: 1024000,
                mimeType: 'image/jpeg',
                status: AppFileUploadStatus.uploading,
                progress: 0.65,
              ),
              UploadedFile(
                name: 'video.mp4',
                size: 5242880,
                mimeType: 'video/mp4',
                status: AppFileUploadStatus.error,
                errorMessage: '파일 크기 초과',
              ),
            ],
            onFilesSelected: (_) {},
            onFileRemoved: (_) {},
          ),
        ],
      ),
    );
  }

  // ========================================================
  // Section 17: Data Table
  // ========================================================
  Widget _buildDataTableSection(double width) {
    final sampleData = _getSampleUsers();

    return AppSection(
      title: 'AppDataTable - 데이터 테이블',
      variant: SectionVariant.compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기본 테이블',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          SizedBox(
            width: width,
            child: AppDataTable<_SampleUser>(
              columns: [
                AppTableColumn(
                  id: 'name',
                  label: '이름',
                  width: 150,
                  cellBuilder: (user, _) => Text(user.name),
                ),
                AppTableColumn(
                  id: 'email',
                  label: '이메일',
                  width: 200,
                  cellBuilder: (user, _) => Text(user.email),
                ),
                AppTableColumn(
                  id: 'role',
                  label: '역할',
                  width: 100,
                  cellBuilder: (user, _) => Text(user.role),
                ),
                AppTableColumn(
                  id: 'status',
                  label: '상태',
                  width: 100,
                  cellBuilder: (user, _) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: user.isActive
                          ? context.appColors.stateSuccessBg.withValues(
                              alpha: 0.2,
                            )
                          : context.appColors.stateErrorBg.withValues(
                              alpha: 0.2,
                            ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.isActive ? '활성' : '비활성',
                      style: TextStyle(
                        color: user.isActive
                            ? context.appColors.stateSuccessText
                            : context.appColors.stateErrorText,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
              data: sampleData,
              showBorder: true,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '정렬 및 선택 가능',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          SizedBox(
            width: width,
            child: AppDataTable<_SampleUser>(
              columns: [
                AppTableColumn(
                  id: 'name',
                  label: '이름',
                  width: 150,
                  cellBuilder: (user, _) => Text(user.name),
                ),
                AppTableColumn(
                  id: 'email',
                  label: '이메일',
                  width: 200,
                  cellBuilder: (user, _) => Text(user.email),
                ),
                AppTableColumn(
                  id: 'role',
                  label: '역할',
                  width: 100,
                  cellBuilder: (user, _) => Text(user.role),
                ),
              ],
              data: sampleData,
              selectionMode: AppDataTableSelectionMode.multiple,
              selectedRows: _selectedUsers,
              onSelectionChanged: (selected) {
                setState(() => _selectedUsers = selected);
              },
              sortColumnId: _sortColumnId,
              sortDirection: _sortDirection,
              onSort: (columnId, direction) {
                setState(() {
                  _sortColumnId = columnId;
                  _sortDirection = direction;
                });
              },
              showStripes: true,
            ),
          ),
          if (_selectedUsers.isNotEmpty) ...[
            SizedBox(height: context.appSpacing.small),
            Text(
              '${_selectedUsers.length}명 선택됨',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.appColors.brandPrimary,
              ),
            ),
          ],
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '밀도 비교',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Wrap(
            spacing: context.appSpacing.large,
            runSpacing: context.appSpacing.large,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compact',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  SizedBox(
                    width: 400,
                    child: AppDataTable<_SampleUser>(
                      columns: _getSimpleColumns(),
                      data: sampleData.take(3).toList(),
                      density: AppDataTableDensity.compact,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comfortable',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  SizedBox(
                    width: 400,
                    child: AppDataTable<_SampleUser>(
                      columns: _getSimpleColumns(),
                      data: sampleData.take(3).toList(),
                      density: AppDataTableDensity.comfortable,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap * 2),
          Text(
            '빈 상태 / 로딩 상태',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: context.appColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveTokens.sectionContentGap),
          Wrap(
            spacing: context.appSpacing.large,
            runSpacing: context.appSpacing.large,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '빈 상태',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  SizedBox(
                    width: 350,
                    child: AppDataTable<_SampleUser>(
                      columns: _getSimpleColumns(),
                      data: const [],
                      emptyMessage: '검색 결과가 없습니다',
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '로딩 상태',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.appColors.textTertiary,
                    ),
                  ),
                  SizedBox(height: context.appSpacing.small),
                  SizedBox(
                    width: 350,
                    child: AppDataTable<_SampleUser>(
                      columns: _getSimpleColumns(),
                      data: const [],
                      isLoading: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<AppTableColumn<_SampleUser>> _getSimpleColumns() {
    return [
      AppTableColumn(
        id: 'name',
        label: '이름',
        width: 120,
        isSortable: false,
        cellBuilder: (user, _) => Text(user.name),
      ),
      AppTableColumn(
        id: 'email',
        label: '이메일',
        width: 180,
        isSortable: false,
        cellBuilder: (user, _) => Text(user.email),
      ),
    ];
  }

  List<_SampleUser> _getSampleUsers() {
    return const [
      _SampleUser(
        name: '김철수',
        email: 'chulsoo@example.com',
        role: '관리자',
        isActive: true,
      ),
      _SampleUser(
        name: '이영희',
        email: 'younghee@example.com',
        role: '멤버',
        isActive: true,
      ),
      _SampleUser(
        name: '박지민',
        email: 'jimin@example.com',
        role: '멤버',
        isActive: false,
      ),
      _SampleUser(
        name: '최민수',
        email: 'minsu@example.com',
        role: '편집자',
        isActive: true,
      ),
      _SampleUser(
        name: '정다희',
        email: 'dahee@example.com',
        role: '뷰어',
        isActive: true,
      ),
    ];
  }
}

/// 샘플 사용자 데이터 클래스
class _SampleUser {
  final String name;
  final String email;
  final String role;
  final bool isActive;

  const _SampleUser({
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
  });
}
