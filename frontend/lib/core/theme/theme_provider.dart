import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 테마 모드 상태 관리 Provider
///
/// 앱 전체의 라이트/다크 모드 전환을 관리합니다.
/// 현재는 라이트 모드만 사용하지만, 향후 다크모드 활성화 시
/// 이 Provider를 통해 전환할 수 있습니다.
///
/// 사용법:
/// ```dart
/// // 현재 테마 모드 가져오기
/// final themeMode = ref.watch(themeModeProvider);
///
/// // 다크모드 토글
/// ref.read(themeModeProvider.notifier).toggleTheme();
/// ```
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadSavedTheme();
  }

  /// 저장된 테마 불러오기 (향후 SharedPreferences 연동)
  Future<void> _loadSavedTheme() async {
    // TODO: SharedPreferences에서 저장된 테마 모드 불러오기
    // final prefs = await SharedPreferences.getInstance();
    // final savedTheme = prefs.getString('theme_mode');
    // if (savedTheme == 'dark') {
    //   state = ThemeMode.dark;
    // } else if (savedTheme == 'system') {
    //   state = ThemeMode.system;
    // }
  }

  /// 테마 저장하기 (향후 SharedPreferences 연동)
  Future<void> _saveTheme(ThemeMode mode) async {
    // TODO: SharedPreferences에 테마 모드 저장
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('theme_mode', mode.name);
  }

  /// 라이트/다크 모드 토글
  /// 현재가 라이트면 다크로, 다크면 라이트로 전환
  void toggleTheme() {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newMode;
    _saveTheme(newMode);
  }

  /// 시스템 설정 따르기
  /// 사용자 기기의 다크모드 설정을 따라감
  void useSystemTheme() {
    state = ThemeMode.system;
    _saveTheme(ThemeMode.system);
  }

  /// 라이트 모드 강제 설정
  void useLightTheme() {
    state = ThemeMode.light;
    _saveTheme(ThemeMode.light);
  }

  /// 다크 모드 강제 설정
  void useDarkTheme() {
    state = ThemeMode.dark;
    _saveTheme(ThemeMode.dark);
  }

  /// 현재 테마가 다크 모드인지 확인
  /// (시스템 모드일 경우 실제 기기 설정 확인 필요)
  bool get isDarkMode => state == ThemeMode.dark;

  /// 현재 테마가 라이트 모드인지 확인
  bool get isLightMode => state == ThemeMode.light;

  /// 현재 테마가 시스템 설정을 따르는지 확인
  bool get isSystemMode => state == ThemeMode.system;
}