# 화면 구조 템플릿 (Screen Structure Template)

## 목적
모든 화면(Feature)이 동일한 구조를 따르도록 하여 AI agent가 새로운 화면을 만날 때도 즉시 구조를 파악할 수 있게 함.

## 현재 문제
- 화면마다 폴더 구조가 다름
- 어디서 데이터를 가져오는지 불명확
- Provider가 분산되어 있음
- 새 기능 추가 시 기존 코드를 이해하는데 시간이 걸림

## 원칙
### 1. 표준 Feature 폴더 구조
```
📁 features/{feature_name}/
├── 📄 {FEATURE}_STRUCTURE.md        ← 이 파일이 가이드! (가장 먼저 읽기)
├── presentation/
│   ├── pages/
│   │   ├── {feature}_page.dart      ← 단순 UI만
│   │   ├── {feature}_detail_page.dart
│   │   └── ...
│   ├── widgets/
│   │   ├── {feature}_card.dart      ← 순수 UI 컴포넌트
│   │   ├── {feature}_list.dart
│   │   └── ...
│   └── providers/
│       ├── {feature}_list_provider.dart    ← AsyncNotifier (데이터)
│       ├── {feature}_detail_provider.dart
│       ├── {feature}_notifier.dart        ← StateNotifier (상태 변경)
│       └── {feature}_providers.dart       ← Export (UI는 이것만 import!)
├── domain/
│   ├── entities/
│   │   └── {feature}.dart           ← 불변 비즈니스 모델
│   └── usecases/
│       ├── get_{feature}s_usecase.dart
│       ├── create_{feature}_usecase.dart
│       └── ...
├── data/
│   ├── datasources/
│   │   ├── {feature}_remote_datasource.dart
│   │   └── {feature}_local_datasource.dart
│   ├── models/
│   │   └── {feature}_dto.dart       ← API 응답 모델
│   └── repositories/
│       └── {feature}_repository.dart
└── README.md                         ← 개발 가이드 (선택)
```

### 2. {FEATURE}_STRUCTURE.md 작성 규칙
```markdown
# {Feature Name} 구조 가이드

## 데이터 흐름 (가장 먼저 읽기!)

\`\`\`
API Response (JSON)
    ↓
{Feature}Dto (data/models)
    ↓
{Feature} Entity (domain/entities)
    ↓
{Feature}State (presentation/providers)
    ↓
{Feature}Page Widget (presentation/pages)
\`\`\`

## 각 계층 역할 및 파일

| 계층 | 책임 | 파일 |
|------|------|------|
| API 응답 | JSON을 DTO로 파싱 | `data/models/{feature}_dto.dart` |
| Repository | DTO를 Entity로 변환, 저장소 추상화 | `data/repositories/{feature}_repository.dart` |
| UseCase | 비즈니스 로직 실행 | `domain/usecases/get_{feature}s_usecase.dart` |
| Provider | AsyncNotifier로 상태 관리 | `presentation/providers/{feature}_list_provider.dart` |
| Widget | 데이터를 UI로 렌더링 | `presentation/widgets/{feature}_card.dart` |

## Provider 정의 위치

**중요**: UI에서는 다음만 import!
\`\`\`dart
import 'presentation/providers/{feature}_providers.dart';
\`\`\`

### 데이터 조회 Provider (AsyncNotifier)
- `{feature}_list_provider.dart` - 목록 조회
- `{feature}_detail_provider.dart` - 상세 조회

### 상태 변경 Provider (StateNotifier)
- `{feature}_notifier.dart` - 생성/수정/삭제

### Export (진입점)
- `{feature}_providers.dart` - 모든 Provider export

## 상태 흐름

\`\`\`dart
{Feature}ListNotifier (AsyncNotifier<{Feature}ListState>)
├── build() - 초기 데이터 로드
├── append{Feature}s() - 더보기
├── delete{Feature}() - 삭제
└── refresh{Feature}s() - 새로고침
\`\`\`

## 데이터 모델 (어떤 것을 언제 사용?)

- **{Feature} (Entity)** - UI에서만 사용, 불변
- **{Feature}Dto (DTO)** - API 응답 파싱만 (UI로 보내지 말 것)
- **{Feature}State** - Provider 상태 (UI 상태 포함)

## 권한 정보

API 응답 ({feature}_dto)에는 항상 권한 플래그 포함:
\`\`\`dart
class {Feature}Dto {
  final String id;
  final String title;
  final bool canDelete;    // UI에서 삭제 버튼 표시?
  final bool canEdit;      // UI에서 수정 버튼 표시?
  final bool canView;      // UI에서 내용 표시?
}
\`\`\`

## 추가 정보
- API 명세: [API Reference](../../docs/implementation/api-reference.md)
- 권한 시스템: [Permission System](../../docs/concepts/permission-system.md)
```

### 3. {feature}_providers.dart (Export 파일)
```dart
// 📌 UI는 이 파일만 import!

export '{feature}_list_provider.dart';
export '{feature}_detail_provider.dart';
export '{feature}_notifier.dart';

// 선택사항: 자주 사용되는 조합
final {feature}WithDetailsProvider = FutureProvider.family<
  ({Feature} feature, List<RelatedData> details),
  String
>((ref, id) async {
  final feature = await ref.watch({feature}DetailProvider(id).future);
  final details = await ref.watch(related{Feature}DetailsProvider(id).future);
  return (feature, details);
});
```

## 구현 패턴

### Example: Post Feature
```
📁 features/post/
├── POST_STRUCTURE.md
├── presentation/
│   ├── pages/
│   │   ├── post_list_page.dart      ← 게시글 목록 화면
│   │   └── post_detail_page.dart    ← 게시글 상세 화면
│   ├── widgets/
│   │   ├── post_card.dart           ← 게시글 카드
│   │   └── post_action_buttons.dart ← 삭제/수정 버튼
│   └── providers/
│       ├── post_list_provider.dart      ← 목록 조회
│       ├── post_detail_provider.dart    ← 상세 조회
│       ├── post_notifier.dart           ← 생성/수정/삭제
│       └── post_providers.dart          ← Export
├── domain/
│   ├── entities/
│   │   └── post.dart
│   └── usecases/
│       ├── get_posts_usecase.dart
│       ├── create_post_usecase.dart
│       ├── update_post_usecase.dart
│       └── delete_post_usecase.dart
├── data/
│   ├── datasources/
│   │   ├── post_remote_datasource.dart
│   │   └── post_local_datasource.dart
│   ├── models/
│   │   └── post_dto.dart
│   └── repositories/
│       └── post_repository.dart
└── README.md

// 데이터 흐름
Post API Response (JSON)
    ↓
PostDto (data/models)
    ↓
Post Entity (domain/entities)
    ↓
PostListState (presentation/providers)
    ↓
PostCard Widget (presentation/widgets)
```

### Example: {FEATURE}_STRUCTURE.md 예시
```markdown
# Post 구조 가이드

## 데이터 흐름

\`\`\`
API Response { "id": "123", "title": "...", "canDelete": true }
    ↓
PostDto(id, title, canDelete)
    ↓
Post(id, title)
    ↓
PostListState(posts: [Post, ...], isLoading: false)
    ↓
PostCard(post: Post) → "삭제" 버튼 표시 (post.canDelete)
\`\`\`

## 파일 구조

| 파일 | 책임 |
|------|------|
| `data/models/post_dto.dart` | API JSON → PostDto 파싱 |
| `data/repositories/post_repository.dart` | PostDto → Post 변환 |
| `domain/entities/post.dart` | Post Entity (불변) |
| `presentation/providers/post_list_provider.dart` | 목록 조회 로직 |
| `presentation/widgets/post_card.dart` | UI 렌더링 |

## 새 Post 추가하기

1. UI에서 `CreatePostDialog` 열기
2. `CreatePostRequest` 작성
3. `ref.read(createPostUseCaseProvider(request))`
4. PostListProvider 새로고침: `ref.refresh(postListProvider(channelId))`
5. 새 Post가 목록에 추가됨
\`\`\`

## 검증 방법

### 체크리스트
- [ ] Feature 폴더에 {FEATURE}_STRUCTURE.md가 있는가?
- [ ] 모든 데이터 계층이 있는가? (data/domain/presentation)
- [ ] providers.dart (export 파일)가 있는가?
- [ ] 데이터 흐름이 단방향인가?
- [ ] API 응답에 권한 플래그가 있는가?

### 구체적 검증
```bash
# 1. STRUCTURE.md 확인
find lib/features -name "*_STRUCTURE.md"
# → 모든 feature에서 발견되어야 함

# 2. 계층 구조 확인
ls lib/features/*/presentation/providers/ lib/features/*/domain/ lib/features/*/data/
# → presentation, domain, data 폴더 모두 있어야 함

# 3. Export 파일 확인
grep -r "export.*provider" lib/features/*/presentation/providers/
# → {feature}_providers.dart에서 모든 provider export
```

## 관련 문서
- [Provider 의존성 맵](provider-dependency.md) - 화면별 Provider 의존성
- [API 응답 매핑](api-response-mapping.md) - DTO 파싱 규칙
- [상태 머신](state-machine.md) - 화면 상태 정의
