import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/theme.dart';
import '../utils/snack_bar_helper.dart';
import 'app_form_field.dart';
import 'app_info_banner.dart';

/// 컴포넌트 쇼케이스 페이지
///
/// AppFormField와 AppInfoBanner의 모든 상태를 시각적으로 테스트하기 위한 페이지입니다.
/// 개발 중에만 사용하며, 프로덕션에서는 제거됩니다.
class ComponentShowcasePage extends StatefulWidget {
  const ComponentShowcasePage({super.key});

  @override
  State<ComponentShowcasePage> createState() => _ComponentShowcasePageState();
}

class _ComponentShowcasePageState extends State<ComponentShowcasePage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _disabledController = TextEditingController(text: '비활성화된 필드');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _descriptionController.dispose();
    _disabledController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('컴포넌트 쇼케이스'),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== AppFormField 쇼케이스 ==========
            _buildSectionTitle('AppFormField'),
            const SizedBox(height: AppSpacing.sm),

            // 기본 텍스트 필드
            AppFormField(
              label: '이메일',
              controller: _emailController,
              hintText: '이메일을 입력하세요',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이메일을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // 비밀번호 필드
            AppFormField(
              label: '비밀번호',
              controller: _passwordController,
              hintText: '비밀번호를 입력하세요',
              obscureText: true,
            ),
            const SizedBox(height: AppSpacing.md),

            // 여러 줄 텍스트
            AppFormField(
              label: '설명',
              controller: _descriptionController,
              hintText: '상세 설명을 입력하세요',
              maxLines: 4,
            ),
            const SizedBox(height: AppSpacing.md),

            // 비활성화 상태
            AppFormField(
              label: '비활성화된 필드',
              controller: _disabledController,
              enabled: false,
            ),
            const SizedBox(height: AppSpacing.md),

            // 에러 상태
            AppFormField(
              label: '에러 상태 필드',
              hintText: '입력하세요',
              errorText: '필수 입력 항목입니다',
            ),
            const SizedBox(height: AppSpacing.md),

            // 아이콘이 있는 필드
            AppFormField(
              label: '검색',
              hintText: '검색어를 입력하세요',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: const Icon(Icons.clear),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ========== AppInfoBanner 쇼케이스 ==========
            _buildSectionTitle('AppInfoBanner'),
            const SizedBox(height: AppSpacing.sm),

            // 기본 정보 배너
            const AppInfoBanner(
              message: '기본 정보 메시지입니다. 이 작업에 대한 안내를 제공합니다.',
            ),
            const SizedBox(height: AppSpacing.md),

            // 경고 배너
            AppInfoBanner.warning(
              message: '주의가 필요합니다. 이 작업을 수행하기 전에 확인해주세요.',
            ),
            const SizedBox(height: AppSpacing.md),

            // 에러 배너
            AppInfoBanner.error(
              message: '오류가 발생했습니다. 입력 내용을 확인하고 다시 시도해주세요.',
            ),
            const SizedBox(height: AppSpacing.md),

            // 성공 배너
            AppInfoBanner.success(
              message: '성공적으로 완료되었습니다!',
            ),
            const SizedBox(height: AppSpacing.md),

            // 닫기 버튼이 있는 배너
            AppInfoBanner.warning(
              message: '닫기 버튼이 있는 경고 메시지입니다.',
              showCloseButton: true,
              onClose: () {
                AppSnackBar.info(context, '배너가 닫혔습니다');
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // 커스텀 아이콘
            const AppInfoBanner(
              message: '커스텀 아이콘을 사용하는 정보 배너입니다.',
              icon: Icons.lightbulb_outline,
            ),
            const SizedBox(height: AppSpacing.md),

            // 액션 버튼이 있는 배너
            AppInfoBanner.warning(
              message: '이 작업은 되돌릴 수 없습니다.',
              action: TextButton(
                onPressed: () {
                  AppSnackBar.info(context, '액션 버튼이 클릭되었습니다');
                },
                child: const Text('자세히 보기'),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ========== 통합 예시 ==========
            _buildSectionTitle('통합 예시 (로그인 폼)'),
            const SizedBox(height: AppSpacing.sm),

            // 에러 배너
            AppInfoBanner.error(
              message: '로그인에 실패했습니다. 이메일과 비밀번호를 확인해주세요.',
            ),
            const SizedBox(height: AppSpacing.md),

            // 폼 필드들
            AppFormField(
              label: '이메일',
              hintText: 'example@university.edu',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            const SizedBox(height: AppSpacing.md),

            AppFormField(
              label: '비밀번호',
              hintText: '비밀번호를 입력하세요',
              obscureText: true,
              prefixIcon: const Icon(Icons.lock_outline),
            ),
            const SizedBox(height: AppSpacing.md),

            // 정보 배너
            const AppInfoBanner(
              message: '대학 이메일로만 로그인할 수 있습니다.',
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.brand,
          ),
    );
  }
}
