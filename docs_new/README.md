# Architecture Map (아키텍처 맵)

**목적**: AI Agent가 코드를 올바른 위치에 넣고, 올바른 참조를 사용하도록 가이드
**버전**: 2.0 - Architecture-Driven

---

## 🗺️ 코드를 어디에 넣을까?

### Theme/색상 관련
- **색상 값**? → `frontend_new/lib/core/theme/extensions/app_color_extension.dart`
- **컴포넌트 색상 팔레트**? → `frontend_new/lib/core/theme/colors/{component}_colors.dart`
- **새 위젯 개발**? → `frontend_new/lib/core/widgets/{widget_name}.dart`
  - 참고: `lib/core/widgets/app_button.dart` (Component Alias 사용)
  - 참고: `lib/core/widgets/app_definition_list.dart` (직접 토큰 사용)

### State Management
- **단순 상태**? → `lib/features/{feature}/application/{feature}_provider.dart`
- **비동기 작업**? → `lib/features/{feature}/application/{feature}_notifier.dart` (AsyncNotifier 패턴)
  - 참고: `lib/features/post/application/`

### API/데이터
- **데이터 모델**? → `lib/features/{feature}/data/models/`
- **API 호출**? → `lib/features/{feature}/data/datasources/`
- **Repository**? → `lib/features/{feature}/data/repositories/`

### UI/화면
- **화면 (페이지)**? → `lib/features/{feature}/presentation/pages/`
- **기능별 위젯**? → `lib/features/{feature}/presentation/widgets/`
- **공용 위젯**? → `lib/core/widgets/`

---

## 📁 아키텍처 구조

```
frontend_new/lib/
├── core/                          # 전사 공통 (여러 feature에서 공유)
│   ├── theme/
│   │   ├── extensions/           # Layer 1: 기본 토큰
│   │   │   ├── app_color_extension.dart
│   │   │   ├── app_spacing_extension.dart
│   │   │   └── app_typography_extension.dart
│   │   ├── colors/               # Layer 2: 컴포넌트 팔레트
│   │   │   ├── button_colors.dart
│   │   │   ├── input_colors.dart
│   │   │   └── {component}_colors.dart
│   │   └── app_theme.dart
│   ├── widgets/                  # 공용 UI 컴포넌트
│   │   ├── app_button.dart
│   │   ├── app_input.dart
│   │   └── ...
│   ├── router/                   # 네비게이션
│   └── utils/                    # 유틸리티
│
├── features/                      # 기능별 모듈 (독립적)
│   ├── {feature}/
│   │   ├── data/                 # 데이터 레이어 (3-Layer 아키텍처)
│   │   │   ├── models/          # 데이터 모델
│   │   │   ├── datasources/      # API 호출, 원격/로컬 데이터 접근
│   │   │   └── repositories/     # 데이터 접근 로직, 데이터 변환
│   │   │
│   │   ├── application/          # 상태 관리 레이어
│   │   │   ├── {feature}_provider.dart      # Riverpod Provider
│   │   │   ├── {feature}_notifier.dart      # AsyncNotifier (비동기 로직)
│   │   │   └── {feature}_state.dart         # 상태 클래스
│   │   │
│   │   └── presentation/         # UI 레이어
│   │       ├── pages/           # 화면 (라우트 연결)
│   │       └── widgets/         # 재사용 가능한 UI 컴포넌트
│   │
│   ├── post/                     # 예시 feature
│   ├── group/
│   └── workspace/
│
└── app.dart                       # 앱 진입점
```

---

## 🎯 활용 방법 (AI Agent용)

### 1. 새 기능 추가할 때

**예**: "사용자 프로필 기능 추가"

```
Step 1: 데이터 구조 정의
→ lib/features/profile/data/models/user_profile.dart 생성

Step 2: API 연동
→ lib/features/profile/data/datasources/profile_datasource.dart
→ lib/features/profile/data/repositories/profile_repository.dart

Step 3: 상태 관리
→ lib/features/profile/application/profile_notifier.dart (AsyncNotifier)
→ lib/features/profile/application/profile_provider.dart

Step 4: UI 구현
→ lib/features/profile/presentation/pages/profile_page.dart
→ lib/features/profile/presentation/widgets/profile_header.dart
```

### 2. 기존 코드 참조할 때

**예**: "색상 어떻게 사용하지?"
→ `lib/core/widgets/app_button.dart` 또는 `app_definition_list.dart` 참고

**예**: "비동기 상태 관리는?"
→ `lib/features/post/application/post_notifier.dart` 참고

**예**: "API 호출은?"
→ `lib/features/post/data/datasources/` 참고

---

## ⚠️ 주의사항

### Architecture 규칙 (비협상)

1. **Data/Repository는 독립적**
   - Repository는 API/로컬 데이터를 모르게 → Datasource 추상화
   - 변경 시 Repository만 수정, Presentation 영향 없음

2. **Feature는 완전히 독립적**
   - Feature A에서 Feature B 코드 직접 참조 금지
   - 필요하면 공용 코드는 `core/` 로 이동

3. **Theme은 core에만**
   - 각 feature가 자신의 색상 정의하지 말 것
   - 모든 색상은 `core/theme/` 에서 가져오기

4. **공용 위젯은 core/widgets**
   - 여러 곳에서 쓸 위젯 → `core/widgets/`
   - 한 feature에서만 쓸 위젯 → `features/{feature}/presentation/widgets/`

### 파일 추가 시

- ✅ `lib/features/{feature}/data/models/` - 새 데이터 모델
- ✅ `lib/features/{feature}/data/repositories/` - 새 데이터 접근
- ✅ `lib/features/{feature}/application/` - 새 상태 관리
- ❌ Feature 외부에서 데이터 직접 접근
- ❌ Presentation에서 API 직접 호출
- ❌ Feature끼리 코드 공유

### 파일명 규칙

```
Feature: {feature_name} (snake_case)
Provider: {feature}_provider.dart
Notifier: {feature}_notifier.dart (또는 {feature}_{action}_notifier.dart)
State: {feature}_state.dart
Model: {model_name}.dart
Datasource: {feature}_datasource.dart (또는 {feature}_{remote/local}_datasource.dart)
Repository: {feature}_repository.dart
Page: {feature}_page.dart
Widget: {widget_name}_widget.dart
```

---

## 📊 Quick Reference

| 찾는 것 | 위치 |
|--------|------|
| 색상 정의 | `lib/core/theme/extensions/app_color_extension.dart` |
| 컴포넌트 색상 | `lib/core/theme/colors/{component}_colors.dart` |
| 공용 UI | `lib/core/widgets/` |
| 기능 데이터 모델 | `lib/features/{feature}/data/models/` |
| API 호출 | `lib/features/{feature}/data/datasources/` |
| 상태 관리 | `lib/features/{feature}/application/` |
| 화면/UI | `lib/features/{feature}/presentation/` |
