# 그룹 계층 구조 (Group Hierarchy)

## 계층 구조 다이어그램

```
한신대학교 (UNIVERSITY) [대학 그룹]
├── 총학생회 (OFFICIAL_GROUP)
├── 교수회 (OFFICIAL_GROUP)
├── 전체 동아리연합 (AUTONOMOUS_GROUP)
├── AI/SW 대학 (COLLEGE) [대학 그룹]
│   ├── AI/SW대학 학생회 (OFFICIAL_GROUP)
│   ├── AI/SW대학 교수회 (OFFICIAL_GROUP)
│   ├── AI/SW대학 동아리연합 (AUTONOMOUS_GROUP)
│   └── AI/SW 학부 (DEPARTMENT) [대학 그룹]
│       ├── AI/SW학부 학생회 (OFFICIAL_GROUP)
│       ├── AI 학회 (OFFICIAL_GROUP)
│       │   ├── AI 스터디팀 A (AUTONOMOUS_GROUP)
│       │   └── AI 연구팀 (OFFICIAL_GROUP)
│       ├── 프로그래밍 동아리 (AUTONOMOUS_GROUP)
│       │   ├── 웹개발팀 (AUTONOMOUS_GROUP)
│       │   └── 앱개발팀 (AUTONOMOUS_GROUP)
│       ├── 알고리즘 스터디 (AUTONOMOUS_GROUP)
│       └── 졸업프로젝트팀 A (AUTONOMOUS_GROUP)
├── 공과대학 (COLLEGE) [대학 그룹]
│   ├── 컴퓨터공학과 (DEPARTMENT) [대학 그룹]
│   └── 전자공학과 (DEPARTMENT) [대학 그룹]
└── 경영대학 (COLLEGE) [대학 그룹]
    └── 경영학과 (DEPARTMENT) [대학 그룹]
        ├── 경영학회 (OFFICIAL_GROUP)
        └── 창업동아리 (AUTONOMOUS_GROUP)
```

## 계층별 특성

### 대학 그룹 (UNIVERSITY_GROUP)
#### 대학교 (UNIVERSITY)
- **최상위 조직**: 모든 그룹의 루트
- **시스템 관리**: ADMIN 권한자만 관리 가능
- **자동 생성**: 시스템 초기화 시 한신대학교 자동 생성
- **권한 상속**: 모든 하위 그룹에 권한 전파

#### 단과대학 (COLLEGE)
- **중간 계층**: 학과들을 그룹화하는 대학 그룹
- **관리 권한**: 대학 관리자 또는 시스템 관리자
- **예시**: AI/SW 대학, 공과대학, 경영대학

#### 학과/학부 (DEPARTMENT)
- **기본 소속**: 모든 사용자가 소속되는 기본 단위
- **자동 가입**: 프로필 설정 시 선택한 학과에 자동 가입
- **기본값**: AI/SW 학부 (학과 미선택 시)
- **교수 승인**: 교수 계정은 학과 관리자 승인 필요

### 공식 그룹 (OFFICIAL_GROUP)
- **공인된 조직**: 대학이나 학과에서 공식 인정한 그룹
- **생성 권한**: 상위 대학 그룹 관리자 승인 필요
- **관리 감독**: 상위 대학 그룹의 관리 감독을 받음
- **예시**: 학생회, 학회, 공식 동아리
- **하위 그룹**: 공식/자율 그룹 생성 가능

### 자율 그룹 (AUTONOMOUS_GROUP)
- **자율적 조직**: 사용자들이 자유롭게 만드는 그룹
- **생성 권한**: 학생도 생성 가능 (부모 그룹 승인 필요)
- **자율 관리**: 그룹 오너가 자율적으로 운영
- **모집 기능**: 공개 모집 게시 가능
- **예시**: 동아리, 스터디 그룹, 프로젝트 팀
- **하위 그룹**: 공식/자율 그룹 생성 가능

## 권한 상속 규칙

### 상속 메커니즘
사용자의 최종 권한은 소속된 그룹의 역할(Role)에 따라 결정됩니다. 또한, 상위 그룹에서 부여된 권한은 하위 그룹의 활동에 영향을 줄 수 있습니다. (예: 학교 관리자는 모든 그룹에 대한 관리 권한을 가짐)

현재 시스템은 역할 기반 권한만을 사용하며, 개인별 권한 재정의(override)는 구현되어 있지 않습니다.

### 상속 예시
```
대학교 [대학 그룹] (모든 권한)
├── 총학생회 [공식 그룹] (전체 학생 관련 권한)
├── 단과대학 [대학 그룹] (해당 대학 관련 권한)
│   ├── 단과대 학생회 [공식 그룹] (단과대 학생 관련 권한)
│   ├── 학과 [대학 그룹] (해당 학과 관련 권한)
│   │   ├── 학과 학생회 [공식 그룹] (학과 학생 관련 권한)
│   │   ├── AI 학회 [공식 그룹] (학회 관련 권한)
│   │   │   └── AI 스터디팀 [자율 그룹] (팀 내부 권한)
│   │   └── 프로그래밍 동아리 [자율 그룹] (동아리 내부 권한)
│   │       ├── 웹개발팀 [자율 그룹] (팀 내부 권한)
│   │       └── 앱개발팀 [자율 그룹] (팀 내부 권한)
```

## 그룹 생성 플로우

### 1. 생성 요청
```typescript
POST /api/groups
{
  "name": "AI 학회",
  "parentGroupId": 123, // AI/SW 학부 ID
  "visibility": "PUBLIC",
  "description": "AI 연구 및 스터디"
}
```

### 2. 승인 프로세스
1. **부모 그룹 관리자에게 알림**
2. **승인/거부 결정**
3. **승인 시 워크스페이스 자동 생성**
4. **생성자가 그룹 오너로 설정**

### 3. 자동 설정
- 기본 워크스페이스 생성
- 기본 채널 생성 (일반대화, 공지사항)
- 오너 권한 할당
- 멤버 역할 템플릿 적용

## 그룹 삭제 정책

### Soft Delete (30일 보관)
```sql
UPDATE groups
SET deleted_at = NOW()
WHERE id = ?
```

### 하위 그룹 처리
1. **재배치**: 조부모 그룹으로 이동
2. **연쇄 삭제**: 관리자 정책에 따라
3. **고아 방지**: 최상위로 이동 또는 삭제

### 복구 정책
- **30일 이내**: 완전 복구 가능
- **30일 이후**: 영구 삭제
- **하위 그룹**: 연쇄 복구 지원

## 자동 가입 정책

### 신입생 가입
```kotlin
// 프로필 설정 시 자동 실행
fun autoJoinDepartment(user: User, department: String) {
    val departmentGroup = findDepartmentGroup(department)
        ?: createDefaultDepartment("AI/SW 학부")

    joinGroup(user, departmentGroup, role = "MEMBER")
}
```

### 기본 학과 설정
- **미선택 시**: "AI/SW 학부" 자동 배정
- **계층 자동 생성**: 한신대학교 → AI/SW 대학 → AI/SW 학부
- **역할 할당**: 기본 "MEMBER" 역할

## 실제 사용 시나리오

### 시나리오 1: 동아리 생성
1. AI/SW 학부 학생이 "프로그래밍 동아리" 자율 그룹 생성 요청
2. AI/SW 학부 관리자(교수)가 승인
3. 동아리 워크스페이스 자동 생성
4. 생성자가 동아리 회장으로 설정
5. 신입 모집 게시글 작성
6. 동아리 내에서 "웹개발팀", "앱개발팀" 하위 자율 그룹 생성

### 시나리오 2: 학회 및 하위 팀 구성
1. 교수가 "AI 학회" 공식 그룹 생성
2. 학과 관리자가 승인
3. 학회장이 "AI 스터디팀" 자율 그룹을 학회 하위에 생성
4. 학회장이 "AI 연구팀" 공식 그룹을 학회 하위에 생성
5. 각 팀별로 독립적인 워크스페이스와 채널 운영

### 시나리오 3: 다층 구조 활용
1. "프로그래밍 동아리" [자율 그룹]
2. 동아리 내 "웹개발팀" [자율 그룹] 생성
3. 웹개발팀 내 "React 스터디" [자율 그룹] 생성
4. 각 계층마다 독립적인 관리와 권한 체계 유지

## 관련 구현

### API 엔드포인트
- **그룹 생성**: [../implementation/api-reference.md#그룹생성](../implementation/api-reference.md#그룹생성)
- **계층 조회**: [../implementation/api-reference.md#계층조회](../implementation/api-reference.md#계층조회)
- **권한 체크**: [../implementation/api-reference.md#권한체크](../implementation/api-reference.md#권한체크)

### 데이터베이스 설계
- **Group 엔티티**: [../implementation/database-reference.md#Group](../implementation/database-reference.md#Group)
- **GroupMember 테이블**: [../implementation/database-reference.md#GroupMember](../implementation/database-reference.md#GroupMember)

### 관련 개념
- **권한 시스템**: [permission-system.md](permission-system.md)
- **워크스페이스**: [workspace-channel.md](workspace-channel.md)
- **사용자 라이프사이클**: [user-lifecycle.md](user-lifecycle.md)
