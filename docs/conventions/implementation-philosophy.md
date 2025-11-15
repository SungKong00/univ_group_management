# 기능 구현 철학 및 코드 구조 설계

## 핵심 원칙

새로운 기능을 구현할 때는 **단순히 기능을 추가하는 것이 목표가 아닙니다.**

요청받은 기능과 기존 코드베이스를 함께 분석하여, 관련 기능들과 함께 고려한 코드 구조를 먼저 설계하고, 컴포넌트를 적절히 분리하며, 관심사를 명확히 하고 재사용성을 극대화해야 합니다.

---

## 구현 프로세스

### 1️⃣ 기존 코드베이스 분석 (필수)

새 기능 구현 전에:
- 요청받은 기능과 관련된 기존 기능들을 먼저 파악
- 유사한 패턴이나 로직이 이미 구현되어 있는지 확인
- 다른 페이지/컴포넌트에서 재사용할 수 있는 구조인지 검토

**예시**:
```
공지 관리 기능 요청
  ↓
기존 코드 검토:
  - "채널 목록" 페이지는 어떻게 구현됨?
  - "게시글 목록" 페이지는 어떤 구조?
  - "리스트 로딩" 상태는 어디서 처리?
  - "그룹별 섹션" UI는 어디 있음?
```

### 2️⃣ 코드 구조 설계 (구현 전)

새 기능만 추가하는 것이 아니라, 전체 구조를 먼저 설계:
- 요청받은 기능과 관련된 기존 기능들을 함께 고려
- 일관성 있는 구조 계획
- 기존 코드와의 통합 방식 검토

**설계 체크리스트**:
```
☐ 기존과 비슷한 패턴이 있나?
☐ 새 컴포넌트는 기존 컴포넌트와 어떻게 맞물릴 것인가?
☐ 데이터 흐름은 일관성 있는가?
☐ 상태 관리 방식은 기존과 동일한가?
```

### 3️⃣ 컴포넌트 분리

묶을 수 있는 기능과 메서드들을 찾아서 컴포넌트 단위로 분리:
- 같은 목적의 로직을 그룹화
- 반복되는 패턴을 추출
- 공통 UI 요소를 재사용 가능하도록 만들기

**원칙**:
- 각 컴포넌트는 **하나의 책임만** 가져야 함 (SRP: Single Responsibility Principle)
- 너무 크거나 복잡한 컴포넌트는 더 작은 단위로 분리
- 파일 크기 기준: 한 파일이 100줄을 넘으면 분리 검토

**예시**:
```dart
// ❌ 나쁜 예: 모든 로직을 한 파일에
announcement_management_page.dart (400줄)
  - 목록 조회 로직
  - UI 렌더링
  - 다이얼로그 처리
  - 폼 유효성 검증
  - API 통신

// ✅ 좋은 예: 책임별로 분리
announcement_management_page.dart (100줄) - 메인 페이지
announcement_card.dart (50줄) - 카드 컴포넌트 (재사용 가능)
announcement_group_section.dart (60줄) - 섹션 컴포넌트
create_announcement_dialog.dart (80줄) - 다이얼로그 관리
announcement_form.dart (70줄) - 폼 로직 (재사용 가능)
announcement_provider.dart (60줄) - 상태 관리
announcement_repository.dart (50줄) - 데이터 접근
```

### 4️⃣ 관심사 분리 (Separation of Concerns)

코드의 각 부분이 명확한 책임을 가져야 함:

**3-Layer Architecture 준수**:
```
Presentation Layer (UI)
  ↓ (의존)
Domain Layer (비즈니스 로직, 모델)
  ↓ (의존)
Data Layer (API 통신, 저장소)
```

**분리 예시**:
```dart
// ❌ 혼합된 코드
class AnnouncementPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // UI 로직
    return Scaffold(
      body: FutureBuilder(
        future: http.get('/api/announcements'),  // 데이터 접근이 여기?
        builder: (context, snapshot) {
          final data = jsonDecode(snapshot.data.body);  // 비즈니스 로직?
          return ListView(...);
        }
      )
    );
  }
}

// ✅ 분리된 코드
// UI Layer (presentation)
class AnnouncementPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcements = ref.watch(announcementsProvider);
    return announcements.when(
      data: (data) => AnnouncementListView(announcements: data),
      loading: () => LoadingWidget(),
      error: (err, stack) => ErrorWidget(error: err),
    );
  }
}

// Domain Layer (비즈니스 로직)
class Announcement {
  final int id;
  final String title;
  // ... 모델만 정의
}

// Data Layer (데이터 접근)
class AnnouncementRepository {
  Future<List<Announcement>> getAnnouncements() async {
    final response = await http.get('/api/announcements');
    return _parseAnnouncements(response);
  }
}

// State Management
final announcementsProvider = FutureProvider((ref) {
  final repo = ref.watch(announcementRepositoryProvider);
  return repo.getAnnouncements();
});
```

**계층별 책임**:
- **Presentation**: UI 렌더링, 사용자 입력 처리, Provider 사용
- **Domain**: 비즈니스 로직, 데이터 모델, 유효성 검증
- **Data**: API 통신, 로컬 저장소, 데이터 변환

### 5️⃣ 재사용성 극대화

구현한 컴포넌트/함수가 다른 곳에서도 쓸 수 있는지 검토:

**체크리스트**:
```
☐ 너무 특수하지 않은 범용적 설계인가?
☐ Props/Parameters로 유연하게 설정 가능한가?
☐ 다른 페이지에서도 사용 가능한가?
☐ 조합으로 새로운 기능을 만들 수 있는가?
```

**예시**:
```dart
// ❌ 특수한 컴포넌트 (재사용 불가)
class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Text(announcement.title),  // 고정된 형태
          Text(announcement.authorName),
          IconButton(
            onPressed: () => context.go('/announcements/${announcement.id}'),  // 특정 라우트로 고정
          ),
        ],
      ),
    );
  }
}

// ✅ 재사용 가능한 컴포넌트
class ListItemCard<T> extends StatelessWidget {
  final T item;
  final Widget Function(T) titleBuilder;
  final Widget Function(T)? subtitleBuilder;
  final Widget Function(T)? trailingBuilder;
  final VoidCallback? onTap;
  final VoidCallback? onHover;

  const ListItemCard({
    required this.item,
    required this.titleBuilder,
    this.subtitleBuilder,
    this.trailingBuilder,
    this.onTap,
    this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: titleBuilder(item),
        subtitle: subtitleBuilder?.call(item),
        trailing: trailingBuilder?.call(item),
        onTap: onTap,
        onHover: (_) => onHover?.call(),
      ),
    );
  }
}

// 사용처 1: 공지 목록
ListItemCard(
  item: announcement,
  titleBuilder: (a) => Text(a.title),
  subtitleBuilder: (a) => Text(a.authorName),
  onTap: () => context.go('/announcements/${a.id}'),
)

// 사용처 2: 게시글 목록
ListItemCard(
  item: post,
  titleBuilder: (p) => Text(p.title),
  subtitleBuilder: (p) => Text(p.authorName),
  onTap: () => context.go('/posts/${p.id}'),
)

// 사용처 3: 그룹 목록
ListItemCard(
  item: group,
  titleBuilder: (g) => Text(g.name),
  subtitleBuilder: (g) => Text('${g.memberCount}명'),
  onTap: () => ref.read(selectedGroupProvider.notifier).state = group,
)
```

---

## 실전 예시: 공지 관리 기능

### ❌ 잘못된 접근

```
요청: "공지 관리 페이지 만들어"
↓
단순히 AnnouncementManagementPage.dart 생성
↓
모든 로직을 한 파일에 구현
  - UI 렌더링
  - API 호출
  - 상태 관리
  - 비즈니스 로직
  - 유효성 검증
↓
결과:
  - 파일 크기 > 500줄
  - UI와 로직이 섞임
  - 다른 페이지에서 재사용 불가능
  - 수정이 어려움
  - 테스트 작성 어려움
```

### ✅ 올바른 접근

#### Phase 1: 기존 코드 분석
```
1. "채널 목록" 페이지 구현 방식 확인
2. "게시글 목록" 페이지의 구조 학습
3. "그룹별 섹션" UI가 어디서 사용 중인지 확인
4. "로딩" 상태 처리 패턴 학습
5. "에러" 처리 방식 확인
```

#### Phase 2: 구조 설계
```
설계 결정:
  ☐ 공지 카드 형태 → 기존 게시글 카드와 다른 점?
  ☐ 섹션 구조 → 워크스페이스 섹션과 유사?
  ☐ 다이얼로그 → 기존 생성 다이얼로그와 공통 부분?
  ☐ 상태 관리 → Riverpod 패턴 일관성?
```

#### Phase 3: 컴포넌트 분리
```
announcement_card.dart (50줄)
  → 공지 카드 (다른 목록에서도 재사용 가능)

announcement_group_section.dart (60줄)
  → 그룹별 섹션 (다른 그룹화 UI에서 재사용 가능)

create_announcement_dialog.dart (100줄)
  → 다이얼로그 관리 (Step 1, 2 분리)

announcement_form.dart (70줄)
  → 폼 로직 (공지 수정, 미리보기에서도 재사용)

announcement_management_page.dart (80줄)
  → 메인 페이지 (조각들 조합)
```

#### Phase 4: 로직 분리
```
announcement_provider.dart (60줄)
  → Riverpod Provider들 (상태 관리)

announcement_repository.dart (50줄)
  → Repository 인터페이스 (도메인 계층)

announcement_repository_impl.dart (60줄)
  → Repository 구현 (데이터 계층)

announcement_remote_datasource.dart (40줄)
  → API 통신 (데이터 계층)
```

#### Phase 5: 재사용성 확보
```
공지 카드 컴포넌트:
  ├─ 공지 목록에서 사용 ✓
  ├─ 검색 결과 목록에서 재사용 ✓
  ├─ 공지함 통합 뷰에서 재사용 ✓
  └─ 공지 상세보기 페이지에서도 사용 가능 ✓

폼 로직 컴포넌트:
  ├─ 공지 작성 (새로 만들 때) ✓
  ├─ 공지 수정 (Phase 2) ✓
  ├─ 공지 미리보기 (Phase 2) ✓
  └─ 공지 임시 저장 (Phase 3) ✓

섹션 컴포넌트:
  ├─ 공지 목록 (그룹별) ✓
  ├─ 채널 목록 (워크스페이스별) ✓
  ├─ 멤버 목록 (역할별) (Phase 2) ✓
  └─ 기타 그룹화 UI ✓
```

---

## 체크리스트

### 구현 전 확인

```
코드베이스 분석:
☐ 기존 코드에서 유사한 기능을 찾았는가?
☐ 기존 패턴을 이해했는가?
☐ 기존과 다른 점이 무엇인가?

설계 단계:
☐ 컴포넌트 분리 계획을 수립했는가?
☐ 각 컴포넌트의 책임이 명확한가?
☐ 3-Layer Architecture를 따르는가?
☐ 기존 구조와 일관성이 있는가?

재사용성:
☐ 이 컴포넌트를 다른 곳에서도 쓸 수 있나?
☐ Props/Parameters가 충분히 설정 가능한가?
☐ 너무 특수하지 않은가?
```

### 구현 중 확인

```
파일 구조:
☐ 파일이 100줄을 넘지는 않나?
☐ 같은 목적의 파일들이 한 폴더에 있나?
☐ 계층별 파일 구조가 명확한가?

코드 품질:
☐ UI와 로직이 분리되어 있나?
☐ 중복 코드가 없나?
☐ 함수/메서드가 한 가지 일만 하나? (SRP)
☐ 기존 컴포넌트를 재사용했나?

상태 관리:
☐ Riverpod Provider 사용이 일관적인가?
☐ 불필요한 상태 관리는 없나?
☐ 상태 변경 흐름이 명확한가?

테스트 용이성:
☐ 로직이 UI로부터 분리되어 있는가?
☐ 테스트 작성이 가능한가?
☐ Mock 객체 생성이 가능한가?
```

### 구현 후 확인

```
코드 리뷰:
☐ 다른 팀원이 이해하기 쉬운가?
☐ 주석이 필요한가?
☐ 네이밍이 명확한가?

확장성:
☐ 향후 기능 추가가 쉬운가?
☐ 수정이 쉬운가?
☐ 테스트 추가가 쉬운가?

성능:
☐ 불필요한 빌드가 없는가?
☐ 상태 관리가 효율적인가?
☐ 메모리 누수가 없는가?
```

---

## 코드 구조 패턴

### 좋은 패턴 예시

**1. 컴포넌트 분리**
```dart
// ✅ 작고 재사용 가능한 컴포넌트
class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback? onTap;
  final bool isHighlighted;

  const AnnouncementCard({
    required this.announcement,
    this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) { ... }
}

// ✅ Props를 통한 유연한 사용
AnnouncementCard(
  announcement: item,
  isHighlighted: item.id == selectedId,
  onTap: () => onSelect(item),
)
```

**2. 관심사 분리**
```dart
// ✅ 상태 관리와 UI 분리
final announcementsProvider = FutureProvider((ref) {
  return ref.watch(announcementRepositoryProvider)
    .getAnnouncements();
});

class AnnouncementPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 상태 관리는 Provider에게
    final announcements = ref.watch(announcementsProvider);

    // UI 렌더링만 책임
    return announcements.when(
      data: (list) => AnnouncementListView(items: list),
      loading: () => LoadingWidget(),
      error: (err, _) => ErrorWidget(error: err),
    );
  }
}
```

**3. 데이터 계층 추상화**
```dart
// ✅ Repository 패턴으로 데이터 접근 추상화
abstract class AnnouncementRepository {
  Future<List<Announcement>> getAnnouncements();
  Future<void> createAnnouncement(AnnouncementRequest request);
}

class AnnouncementRepositoryImpl implements AnnouncementRepository {
  final AnnouncementRemoteDataSource remoteDataSource;

  @override
  Future<List<Announcement>> getAnnouncements() async {
    try {
      final response = await remoteDataSource.fetchAnnouncements();
      return response.map((dto) => dto.toDomain()).toList();
    } catch (e) {
      // 에러 처리
      rethrow;
    }
  }
}
```

---

## 자주 하는 실수

### ❌ 실수 1: 모든 로직을 한 파일에
```dart
// 절대 금지!
announcement_page.dart (500줄)
  - 모든 UI
  - API 호출
  - 상태 관리
  - 비즈니스 로직
  - 유효성 검증
```

### ❌ 실수 2: UI와 로직의 혼합
```dart
FutureBuilder(
  future: http.get('/api/announcements'),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return LoadingWidget();

    final data = jsonDecode(snapshot.data.body);
    final filtered = data.where((item) =>
      item['authorId'] == currentUser.id &&
      DateTime.parse(item['createdAt']).isAfter(
        DateTime.now().subtract(Duration(days: 7))
      )
    ).toList();

    return ListView(
      children: filtered.map((item) => ListTile(
        title: Text(item['title']),
        subtitle: Text(item['content']),
      )).toList(),
    );
  },
)

// 여러 책임이 섞여있음:
// - UI 렌더링
// - 데이터 가져오기
// - 데이터 파싱
// - 필터링 로직
// - 에러 처리
```

### ❌ 실수 3: 재사용성 없는 특수한 컴포넌트
```dart
// 이 컴포넌트는 공지에만 사용 가능
class AnnouncementCardForManagementPage extends StatelessWidget {
  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        children: [
          Text(announcement.title),
          Text(announcement.authorName),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => context.go('/announcements/${announcement.id}/edit'),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteAnnouncement(announcement.id),
          ),
        ],
      ),
    );
  }
}

// 다른 곳에서 쓸 수 없음 (라우트, 삭제 로직이 고정됨)
```

---

## 요약

| 항목 | 좋은 예 | 나쁜 예 |
|------|--------|--------|
| **파일 크기** | < 100줄 | > 300줄 |
| **책임** | 하나 (SRP) | 여러 개 |
| **계층** | 3-Layer 준수 | 혼합됨 |
| **재사용** | 가능 | 특수함 |
| **테스트** | 쉬움 | 어려움 |
| **수정** | 영향 적음 | 영향 큼 |
| **유지보수** | 쉬움 | 어려움 |

