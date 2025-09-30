# 개발 워크플로우 (Development Flow)

## Claude 기반 개발 프로세스

### 기본 원칙
- **컨텍스트 우선**: 개발 전 관련 문서 참조
- **단계별 진행**: 계획 → 구현 → 테스트 → 검증
- **문서 동기화**: 구현과 동시에 문서 업데이트

### 작업 시작 전 체크리스트
```
□ CLAUDE.md에서 관련 컨텍스트 확인
□ 관련 concept 문서 검토
□ API/DB 설계 문서 확인
□ 기존 코드 패턴 파악
```

## 백엔드 개발 워크플로우

### 1. API 개발 프로세스
```
계획 → 엔티티 설계 → 서비스 로직 → 컨트롤러 → 테스트 → 문서화
```

#### Step 1: 요구사항 분석
```markdown
1. [concepts/domain-overview.md](../concepts/domain-overview.md) 확인
2. [concepts/permission-system.md](../concepts/permission-system.md) 권한 요구사항 확인
3. API 명세 초안 작성
```

#### Step 2: 데이터 모델 설계
```kotlin
// 1. 엔티티 설계
@Entity
data class NewEntity(
    @Id @GeneratedValue
    val id: Long? = null,
    // 필드 정의
)

// 2. Repository 인터페이스
interface NewEntityRepository : JpaRepository<NewEntity, Long> {
    // 커스텀 쿼리 메서드
}
```

#### Step 3: 비즈니스 로직 구현
```kotlin
@Service
@Transactional
class NewEntityService(
    private val repository: NewEntityRepository
) {
    // 비즈니스 로직 구현
    // 권한 검증 포함
}
```

#### Step 4: 컨트롤러 구현
```kotlin
@RestController
@RequestMapping("/api/new-entities")
class NewEntityController(
    private val service: NewEntityService
) {
    @PreAuthorize("@security.hasPermission(...)")
    fun createEntity(@Valid @RequestBody request: CreateRequest): ApiResponse<EntityDto>
}
```

### 2. 권한 시스템 통합
```kotlin
// 모든 보호된 엔드포인트에 권한 체크 필수
@PreAuthorize("@security.hasGroupPerm(#groupId, 'REQUIRED_PERMISSION')")

// 권한 체크 실패 시 403 Forbidden 자동 반환
// GlobalExceptionHandler에서 일관된 에러 응답 처리
```

## 프론트엔드 개발 워크플로우

### 1. 개발 전 문서 리뷰 단계
```
요구사항 분석 → 디자인 시스템 확인 → 아키텍처 검토 → 개발 계획 수립
```

#### Step 1: 컨텍스트 문서 검토
```markdown
1. CLAUDE.md에서 관련 컨텍스트 링크 확인
2. [ui-ux/concepts/design-system.md](../ui-ux/concepts/design-system.md) 디자인 원칙 숙지
3. [ui-ux/concepts/color-guide.md](../ui-ux/concepts/color-guide.md) 컬러 시스템 확인
4. [ui-ux/concepts/form-and-interaction-components.md](../ui-ux/concepts/form-and-interaction-components.md) 컴포넌트 요구사항 파악
5. [implementation/frontend-guide.md](../implementation/frontend-guide.md) 현재 아키텍처 패턴 확인
```

#### Step 2: 개발 범위 및 우선순위 결정
```markdown
원칙: 한 번에 많은 기능보다 집중 가능한 범위로 분할
1. 기본 디자인 시스템 컴포넌트 (버튼, 입력, 카드, 모달)
2. 권한 기반 UI 컴포넌트 (조건부 렌더링)
3. 핵심 화면 레이아웃 (워크스페이스, 채널 등)
4. 상호작용 컴포넌트 (좋아요, 멘션, 파일업로드)
```

### 2. 컴포넌트 개발 프로세스
```
아키텍처 설계 → 컴포넌트 구조 → 상태 관리 → API 연동 → 스타일링 → 품질 검증
```

#### Step 1: 파일 구조 설계
```markdown
프레임워크와 관계없이 다음 구조를 권장:
- components/common/    # 디자인 시스템 기본 컴포넌트
- components/forms/     # 폼 관련 컴포넌트
- components/workspace/ # 도메인별 컴포넌트
- providers/           # 상태 관리
- services/            # API 통신
- utils/               # 유틸리티 함수
```

#### Step 2: 상태 관리 패턴 적용
```markdown
현재 기술 스택에 맞는 상태 관리 패턴 사용:
- 전역 상태: 인증, 사용자 정보, 권한
- 지역 상태: 폼 입력, UI 상태
- 서버 상태: API 데이터, 캐싱
```

#### Step 3: 권한 기반 UI 패턴 구현
```markdown
모든 보호된 컴포넌트는 권한 체크 로직 포함:
- 권한 확인 후 조건부 렌더링
- 권한 없음 시 대체 UI 또는 숨김 처리
- 로딩 상태 및 에러 처리
```

### 3. 반응형 및 접근성 고려사항
```markdown
모바일 우선 설계:
- 기본: 모바일 레이아웃
- 확장: 태블릿/데스크톱 적응
- 터치 친화적 인터페이스
- 키보드 네비게이션 지원

접근성 기준:
- WCAG 2.1 AA 준수
- 색상 대비 4.5:1 이상
- 스크린 리더 지원
- 키보드 접근성
```

## 통합 테스트 워크플로우

### 1. 백엔드 테스트
```kotlin
@SpringBootTest
@Transactional
class NewFeatureIntegrationTest : DatabaseCleanup() {

    @Test
    fun `기능 테스트 시나리오`() {
        // Given: 테스트 데이터 준비
        // When: API 호출
        // Then: 결과 검증
    }
}
```

### 2. 권한 테스트
```kotlin
@Test
fun `권한 없는 사용자는 접근할 수 없다`() {
    // Given: 권한 없는 사용자
    val user = createUserWithoutPermission()

    // When: 보호된 API 호출
    val result = mockMvc.perform(post("/api/protected")
        .with(user(user)))

    // Then: 403 Forbidden
    result.andExpect(status().isForbidden)
}
```

### 3. 프론트엔드 E2E 테스트 (향후)
```typescript
// Playwright/Cypress 예시
test('그룹 생성 플로우', async ({ page }) => {
  await page.goto('/groups');
  await page.click('[data-testid="create-group-button"]');
  await page.fill('[data-testid="group-name"]', '테스트 그룹');
  await page.click('[data-testid="submit-button"]');

  await expect(page.locator('.success-message')).toBeVisible();
});
```

## 배포 워크플로우

### 1. 개발 환경
```bash
# 백엔드 실행
./gradlew bootRun

# 프론트엔드 실행 (Flutter)
flutter run -d chrome --web-hostname localhost --web-port 5173

# 데이터베이스
H2 in-memory (자동 초기화)
```

### 2. 프로덕션 준비
```bash
# 백엔드 빌드
./gradlew build

# 프론트엔드 빌드 (Flutter)
flutter build web

# 프론트엔드 빌드 (React - 향후)
npm run build
```

### 3. 환경별 설정
```yaml
# application-dev.yml
spring:
  datasource:
    url: jdbc:h2:mem:testdb

# application-prod.yml
spring:
  datasource:
    url: jdbc:mysql://rds-endpoint/database
```

## 코드 품질 관리

### 1. 코딩 컨벤션
```kotlin
// Kotlin 스타일 가이드 따름
class ServiceClass {
    fun methodName(parameterName: Type): ReturnType {
        // 구현
    }
}
```

### 2. 코드 리뷰 체크리스트
```markdown
□ 권한 체크 누락 없음
□ 에러 처리 적절함
□ 테스트 케이스 포함
□ 문서 업데이트 완료
□ API 응답 형식 일관성
□ 성능 고려사항 검토
```

### 3. 자동화 도구 (향후)
```bash
# 코드 포맷팅
./gradlew ktlintFormat

# 정적 분석
./gradlew detekt

# 테스트 커버리지
./gradlew jacocoTestReport
```

## 문서 동기화 워크플로우

### 1. 구현 완료 후 문서 업데이트
```markdown
1. API 변경 시: [api-reference.md](../implementation/api-reference.md) 업데이트
2. DB 스키마 변경 시: [database-reference.md](../implementation/database-reference.md) 업데이트
3. 새 개념 추가 시: concepts/ 폴더에 문서 추가
4. UI 변경 시: ui-ux/ 폴더 문서 업데이트
```

### 2. 문서 일관성 확인
```markdown
□ 모든 링크가 올바르게 작동함
□ 코드 예시가 실제 구현과 일치함
□ 새 기능이 CLAUDE.md에 반영됨
□ 관련 troubleshooting 섹션 업데이트
```

## 브랜치 전략 (Git)

### 1. 브랜치 네이밍
```
feature/그룹-생성-API
bugfix/권한-체크-오류
hotfix/로그인-문제
```

### 2. 커밋 메시지
```
feat: 그룹 생성 API 구현

- GroupController, GroupService 추가
- 권한 체크 로직 포함
- 통합 테스트 작성

Closes #123
```

### 3. PR 체크리스트
```markdown
□ 기능 정상 동작 확인
□ 테스트 통과
□ 문서 업데이트 완료
□ 코드 리뷰 완료
□ 충돌 해결 완료
```

## 디버깅 워크플로우

### 1. 백엔드 디버깅
```kotlin
// 로깅 활용
logger.debug("Processing request: {}", request)
logger.error("Error occurred", exception)

// 테스트를 통한 문제 재현
@Test
fun `문제 상황 재현`() {
    // 문제 상황 설정
    // 예상 동작 확인
}
```

### 2. 프론트엔드 디버깅
```dart
// Flutter 디버그 도구
print('Debug: $variable');
debugPrint('State: ${provider.state}');

// React DevTools
console.log('Debug:', state);
```

## 관련 문서

### 구현 가이드
- **백엔드 가이드**: [../implementation/backend-guide.md](../implementation/backend-guide.md)
- **프론트엔드 가이드**: [../implementation/frontend-guide.md](../implementation/frontend-guide.md)
- **API 참조**: [../implementation/api-reference.md](../implementation/api-reference.md)

### 테스트 전략
- **테스트 가이드**: [testing-strategy.md](testing-strategy.md)

### 문제 해결
- **일반적 에러**: [../troubleshooting/common-errors.md](../troubleshooting/common-errors.md)
- **권한 에러**: [../troubleshooting/permission-errors.md](../troubleshooting/permission-errors.md)