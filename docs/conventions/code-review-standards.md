# 코드 리뷰 기준 (Code Review Standards)

## 리뷰 목표

### 주요 목적
- **코드 품질** 향상
- **버그 방지** 및 조기 발견
- **지식 공유** 및 팀 학습
- **일관성** 있는 코드베이스 유지
- **보안 취약점** 예방

### 리뷰 관점
- 기능적 정확성
- 코드 가독성
- 성능 최적화
- 보안 고려사항
- 테스트 커버리지
- 문서화 적절성

## 리뷰어 가이드라인

### 리뷰 시점
- **24시간 이내** 첫 리뷰 완료
- **긴급 수정**: 4시간 이내
- **복잡한 PR**: 48시간 이내
- **작은 수정**: 즉시 리뷰

### 리뷰 순서
1. **PR 설명** 이해
2. **전체 구조** 파악
3. **주요 로직** 검토
4. **세부 구현** 확인
5. **테스트 코드** 검토
6. **문서 업데이트** 확인

### 리뷰 깊이
- **Critical**: 보안, 성능, 핵심 로직
- **Important**: 코드 품질, 가독성
- **Nice to have**: 스타일, 최적화

## 체크리스트

### 기능성 (Functionality)
- [ ] 요구사항을 올바르게 구현했는가?
- [ ] 엣지 케이스를 적절히 처리하는가?
- [ ] 에러 시나리오를 고려했는가?
- [ ] 입력 validation이 충분한가?

### 코드 품질 (Code Quality)
- [ ] 코드가 읽기 쉽고 이해하기 쉬운가?
- [ ] 함수/클래스 크기가 적절한가?
- [ ] 변수명이 의미를 잘 나타내는가?
- [ ] 주석이 필요한 곳에 적절히 작성되었는가?
- [ ] 중복 코드가 제거되었는가?

### 성능 (Performance)
- [ ] 불필요한 계산이나 반복이 없는가?
- [ ] 메모리 사용량이 적절한가?
- [ ] 데이터베이스 쿼리가 최적화되었는가?
- [ ] 큰 데이터 처리 시 페이징이 고려되었는가?

### 보안 (Security)
- [ ] 입력 데이터 검증이 충분한가?
- [ ] SQL 인젝션 취약점이 없는가?
- [ ] 권한 체크가 적절히 구현되었는가?
- [ ] 민감한 정보가 노출되지 않는가?
- [ ] 로깅에 개인정보가 포함되지 않는가?

### 테스트 (Testing)
- [ ] 새로운 기능에 대한 테스트가 있는가?
- [ ] 테스트 커버리지가 충분한가?
- [ ] 실패 시나리오에 대한 테스트가 있는가?
- [ ] 테스트가 실제로 의미 있는 검증을 하는가?

### 문서화 (Documentation)
- [ ] API 변경사항이 문서에 반영되었는가?
- [ ] 복잡한 로직에 적절한 설명이 있는가?
- [ ] README나 설치 가이드가 업데이트되었는가?
- [ ] 컨텍스트 파일 동기화가 필요한가?

## 언어별 세부 기준

### Kotlin (백엔드)

#### 코드 스타일
```kotlin
// 좋은 예시
class UserService(
    private val userRepository: UserRepository,
    private val permissionService: PermissionService
) {
    fun createUser(request: CreateUserRequest): User {
        validateRequest(request)
        return userRepository.save(User.from(request))
    }

    private fun validateRequest(request: CreateUserRequest) {
        require(request.email.isNotBlank()) { "Email cannot be blank" }
        require(request.email.contains("@")) { "Invalid email format" }
    }
}

// 나쁜 예시
class UserService(private val ur: UserRepository, private val ps: PermissionService) {
    fun createUser(r: CreateUserRequest): User {
        // validation 없음
        return ur.save(User.from(r))
    }
}
```

#### 권한 체크
```kotlin
// 좋은 예시
@PreAuthorize("@security.hasGroupPermission(#groupId, 'GROUP_MANAGE')")
fun updateGroup(@PathVariable groupId: Long, @RequestBody request: UpdateGroupRequest): GroupDto {
    return groupService.updateGroup(groupId, request)
}

// 나쁜 예시 - 권한 체크 없음
fun updateGroup(@PathVariable groupId: Long, @RequestBody request: UpdateGroupRequest): GroupDto {
    return groupService.updateGroup(groupId, request)
}
```

### Dart/Flutter (프론트엔드)

#### 위젯 구조
```dart
// 좋은 예시
class UserProfileWidget extends StatelessWidget {
  const UserProfileWidget({
    Key? key,
    required this.user,
    this.onEditPressed,
  }) : super(key: key);

  final User user;
  final VoidCallback? onEditPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          _buildHeader(),
          _buildContent(),
          if (onEditPressed != null) _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() => // 구현
  Widget _buildContent() => // 구현
  Widget _buildActions() => // 구현
}

// 나쁜 예시 - 너무 큰 build 메서드
class UserProfileWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(child: Column(children: [
      // 100줄 이상의 중첩된 위젯들...
    ]));
  }
}
```

#### 상태 관리
```dart
// 좋은 예시
class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> login(String token) async {
    _setLoading(true);
    _clearError();

    try {
      _user = await _authService.login(token);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
```

## 피드백 제공 방법

### 피드백 분류

#### 💡 제안 (Suggestion)
```markdown
💡 **제안**: 여기서 Optional을 사용하면 null 체크를 더 명확하게 할 수 있을 것 같습니다.

```kotlin
// 현재
if (user.email != null) {
    sendEmail(user.email)
}

// 제안
user.email?.let { sendEmail(it) }
```
```

#### ❓ 질문 (Question)
```markdown
❓ **질문**: 이 경우 timeout 값을 5초로 설정한 특별한 이유가 있나요?
네트워크 상황에 따라 더 길게 설정하는 것이 좋을 수도 있을 것 같습니다.
```

#### ⚠️ 문제 (Issue)
```markdown
⚠️ **문제**: 여기서 사용자 입력을 바로 SQL 쿼리에 사용하면 SQL 인젝션 위험이 있습니다.
PreparedStatement나 ORM의 파라미터 바인딩을 사용해야 합니다.
```

#### 🔧 수정 필요 (Must Fix)
```markdown
🔧 **수정 필요**: 이 메서드는 null을 반환할 수 있는데 호출하는 쪽에서 null 체크를 하지 않고 있습니다.
NullPointerException이 발생할 수 있습니다.
```

### 긍정적 피드백
```markdown
👍 **좋습니다**: 에러 처리 로직이 매우 깔끔하고 이해하기 쉽네요!

🎯 **명확합니다**: 함수명과 변수명이 의도를 정확히 나타내고 있어서 읽기 쉽습니다.

📚 **학습했습니다**: 이런 패턴은 처음 보는데, 좋은 방법인 것 같습니다. 다른 곳에도 적용해보겠습니다.
```

### 건설적 피드백
```markdown
💭 **고려사항**: 현재 방식도 좋지만, 이런 방법도 고려해볼 수 있을 것 같습니다:
[대안 코드 제시]

각각의 장단점:
- 현재 방식: 간단하고 직관적
- 제안 방식: 더 확장 가능하고 재사용성이 높음

어떻게 생각하시나요?
```

## 일반적인 리뷰 포인트

### 백엔드 리뷰 포인트

#### API 설계
- RESTful 원칙 준수
- 적절한 HTTP 상태 코드 사용
- 일관된 응답 형식
- API 버전 관리

#### 데이터베이스
- 인덱스 최적화
- N+1 쿼리 문제
- 트랜잭션 범위
- 데이터 일관성

#### 보안
- 인증/인가 구현
- 입력값 검증
- SQL 인젝션 방지
- XSS 방지

### 프론트엔드 리뷰 포인트

#### UI/UX
- 반응형 디자인
- 접근성 (a11y)
- 사용자 경험
- 로딩 상태 처리

#### 성능
- 불필요한 리렌더링
- 메모리 누수
- 번들 크기 최적화
- 이미지 최적화

#### 상태 관리
- 전역 vs 지역 상태
- 상태 변경 추적
- 사이드 이펙트 관리

## 자동화된 검사

### 정적 분석 도구
- **백엔드**: Detekt, SonarQube
- **프론트엔드**: ESLint, Dart Analysis

### CI/CD 통합
- 빌드 성공 확인
- 테스트 통과 확인
- 코드 커버리지 측정
- 보안 스캔 실행

### 코드 품질 메트릭
- 순환 복잡도
- 코드 중복도
- 테스트 커버리지
- 기술 부채 측정

## 리뷰 문화

### Do's (해야 할 것)
- 📝 **구체적이고 실행 가능한** 피드백 제공
- 🤝 **존중하고 건설적인** 어조 유지
- 💡 **대안 제시** 및 설명
- 🎯 **중요도 구분** (Critical vs Nice-to-have)
- 📚 **학습 기회** 공유

### Don'ts (하지 말아야 할 것)
- ❌ 개인 공격이나 비판적 어조
- ❌ 모호하거나 추상적인 피드백
- ❌ 스타일만을 위한 nitpicking
- ❌ 리뷰 없이 승인
- ❌ 과도한 완벽주의

### 리뷰 받는 사람의 자세
- 💬 **적극적으로 질문**하고 토론
- 🙏 **피드백에 감사** 표현
- 💭 **다른 관점** 수용
- 🔄 **빠른 응답** 및 수정
- 📖 **리뷰 내용 학습** 및 적용

## 관련 문서

- **Git 전략**: [git-strategy.md](git-strategy.md)
- **커밋 컨벤션**: [commit-conventions.md](commit-conventions.md)
- **PR 가이드라인**: [pr-guidelines.md](pr-guidelines.md)
- **개발 워크플로우**: [../workflows/development-flow.md](../workflows/development-flow.md)