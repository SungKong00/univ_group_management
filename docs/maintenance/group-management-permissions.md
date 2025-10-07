# 그룹 관리 권한 유지보수 가이드

> **목적**: 새로운 그룹 관리 권한이 추가되거나 변경될 때, 시스템 전반에 걸쳐 누락 없이 반영하기 위한 체크리스트

## 📋 그룹 관리 권한 목록

현재 시스템에서 인식하는 그룹 관리 권한은 다음 4가지입니다:

| 권한 이름 | 설명 | 주요 기능 |
|---------|------|----------|
| `GROUP_MANAGE` | 그룹 정보 관리 | 그룹 정보 수정, 그룹 삭제, 소유권 이전, 지도교수 관리, 하위 그룹 생성 승인 |
| `ADMIN_MANAGE` | 멤버 및 역할 관리 | 멤버 역할 변경, 강제 탈퇴, 커스텀 역할 생성/수정/삭제, 가입 신청 승인/거절 |
| `CHANNEL_MANAGE` | 채널 관리 | 채널 생성, 삭제, 설정 수정, 채널 역할 바인딩 설정 |
| `RECRUITMENT_MANAGE` | 모집 관리 | 모집 공고 작성/수정/마감/삭제, 지원서 심사 |

## ⚠️ 새 권한 추가 시 수정 필요 파일

새로운 그룹 관리 권한이 추가되면, 다음 파일들을 **반드시** 업데이트해야 합니다:

### 1. 프론트엔드 (Flutter)

#### 필수 수정
- **`frontend/lib/core/utils/permission_utils.dart`**
  - 위치: `PermissionUtils.groupManagementPermissions` 상수 리스트
  - 작업: 새 권한 문자열 추가
  - 예시:
    ```dart
    static const List<String> groupManagementPermissions = [
      'GROUP_MANAGE',
      'ADMIN_MANAGE',
      'CHANNEL_MANAGE',
      'RECRUITMENT_MANAGE',
      'NEW_PERMISSION_HERE', // 👈 새 권한 추가
    ];
    ```

#### 권장 수정
- **`frontend/lib/presentation/widgets/workspace/channel_navigation.dart`**
  - 위치: 그룹 관리 버튼 표시 로직 (hasAnyGroupPermission 플래그 사용 부분)
  - 작업: 특정 권한에 대한 개별 버튼이 필요한 경우에만 수정

- **`frontend/lib/presentation/widgets/workspace/mobile_channel_list.dart`**
  - 위치: 모바일 버전 그룹 관리 버튼 표시 로직
  - 작업: 동일

### 2. 백엔드 (Spring Boot + Kotlin)

#### 필수 확인
- **`backend/src/main/kotlin/com/.../domain/permission/GroupPermission.kt`** (또는 유사 파일)
  - 위치: 권한 enum 또는 상수 정의
  - 작업: 새 권한이 백엔드 권한 시스템에 정의되어 있는지 확인

- **`backend/src/main/kotlin/com/.../service/PermissionService.kt`** (또는 유사 파일)
  - 위치: 권한 체크 로직
  - 작업: 새 권한에 대한 검증 로직 추가 (필요 시)

### 3. 문서

#### 필수 업데이트
- **`docs/concepts/permission-system.md`**
  - 위치: 그룹 권한 섹션
  - 작업: 새 권한 설명 추가

- **`docs/maintenance/group-management-permissions.md`** (본 문서)
  - 위치: "그룹 관리 권한 목록" 테이블
  - 작업: 새 권한 행 추가

#### 권장 업데이트
- **`docs/implementation/api-reference.md`**
  - 위치: 권한 관련 API 명세
  - 작업: 새 권한이 영향을 미치는 API 엔드포인트 문서화

## 🔄 권한 추가 워크플로우

새 그룹 관리 권한을 추가할 때는 다음 순서로 진행하세요:

### Phase 1: 백엔드 권한 정의
1. 백엔드 권한 enum/상수에 새 권한 추가
2. 권한 설명 및 메타데이터 정의
3. 백엔드 테스트 작성 및 실행

### Phase 2: 프론트엔드 권한 인식
1. **`permission_utils.dart`의 `groupManagementPermissions` 리스트에 추가** (필수)
2. 권한 체크가 필요한 UI 컴포넌트 업데이트 (선택)
3. 프론트엔드 테스트 작성 및 실행

### Phase 3: 문서화
1. **본 문서 (`group-management-permissions.md`)의 테이블 업데이트** (필수)
2. `permission-system.md`에 상세 설명 추가 (필수)
3. API 문서 업데이트 (권장)

### Phase 4: 검증
1. 새 권한을 가진 사용자로 테스트
2. 그룹 관리 페이지 접근 가능 여부 확인
3. 해당 권한이 필요한 기능 동작 확인

## 📝 체크리스트

새 그룹 관리 권한을 추가했을 때 다음 항목들을 확인하세요:

- [ ] 백엔드 권한 시스템에 새 권한 정의
- [ ] `permission_utils.dart`의 `groupManagementPermissions`에 추가
- [ ] 본 문서의 권한 목록 테이블 업데이트
- [ ] `permission-system.md`에 상세 설명 추가
- [ ] 그룹 관리 페이지 접근 테스트 (새 권한 보유자)
- [ ] 관련 API 문서 업데이트 (필요 시)
- [ ] 백엔드 테스트 작성 및 통과
- [ ] 프론트엔드 테스트 작성 및 통과 (필요 시)

## 🔗 관련 문서

- [권한 시스템 개념](../concepts/permission-system.md) - 전체 권한 시스템 설명
- [프론트엔드 가이드](../implementation/frontend-guide.md) - 프론트엔드 구현 가이드
- [백엔드 가이드](../implementation/backend-guide.md) - 백엔드 구현 가이드
- [API 참조](../implementation/api-reference.md) - API 명세

## 📌 중요 노트

- **그룹 관리 페이지**는 위 4개(또는 추가된) 권한 중 **어느 하나라도** 보유한 사용자가 접근할 수 있습니다.
- 단순히 "admin 역할"만을 위한 페이지가 아니므로, 네이밍이나 로직에서 이를 명확히 해야 합니다.
- `permission_utils.dart`를 수정하지 않으면 새 권한 보유자가 그룹 관리 페이지에 접근하지 못할 수 있으니 주의하세요.

## 🆕 최근 변경 이력

| 날짜 | 변경 내용 | 작성자 |
|------|----------|--------|
| 2025-10-07 | 최초 작성: 그룹 관리 권한 유지보수 가이드 문서 생성 | Claude Code |
