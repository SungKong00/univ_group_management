# 백엔드 기술 설계

시스템의 기술적 아키텍처, 설계 원칙, 핵심 모듈을 100줄 내외로 설명합니다.

**특징**: 각 문서는 개념과 코드 참조(경로/클래스명)만 포함하며, 상세한 구현은 코드에서 직접 확인합니다.

## 📚 문서 목록

### 핵심 설계
- **[도메인 모델](./domain-model.md)** - User, Group, Entity 관계 설계
- **[API 설계](./api-design.md)** - RESTful 아키텍처 및 표준화
- **[인증 시스템](./authentication.md)** - Google OAuth2 + JWT 플로우

### 기술 아키텍처
- **[3-Layer 아키텍처](../implementation/backend/architecture.md)** - Controller-Service-Repository 패턴
- **[권한 검증](../implementation/backend/permission-checking.md)** - @PreAuthorize 및 권한 캐싱

## 🔗 관련 문서

**상세 구현:**
- [API 엔드포인트](../implementation/api-reference.md)
- [DB 스키마](../implementation/database-reference.md)
- [구현 가이드](../implementation/backend/README.md)

**도메인 개념:**
- [권한 시스템](../concepts/permission-system.md)
- [그룹 계층](../concepts/group-hierarchy.md)
- [사용자 생명주기](../concepts/user-lifecycle.md)

## 📖 사용 방법

각 문서의 "코드 참조" 섹션에서 파일 경로와 클래스명을 확인하고,
해당 코드를 직접 열어 구현을 확인하세요.

**예시:**
- 문서: "GroupService 의 createGroup() 메서드 참조"
- 경로: `backend/src/main/kotlin/org/castlekong/backend/service/GroupService.kt`
- 동작: Read 도구로 위 파일을 열어 메서드 확인
