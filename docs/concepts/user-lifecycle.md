# 사용자 라이프사이클 (User Lifecycle)

## 사용자 상태 다이어그램

```
신규 사용자 → Google OAuth → 프로필 미완성
    ↓
프로필 설정 → 학과 선택 → 프로필 완성
    ↓
자동 학과 가입 → 일반 사용자 (STUDENT)
    ↓
[선택적] 교수 역할 신청 → 승인 대기 (PENDING) → 승인/거부
    ↓                      ↓
그룹 활동 시작          교수 계정 (PROFESSOR)
```

## 사용자 상태

### 1. 신규 사용자 (New User)
```typescript
{
  email: "user@gmail.com",        // Google OAuth 제공
  name: "김철수",                  // Google 프로필 정보
  profileCompleted: false,        // 프로필 미완성
  globalRole: null,              // 역할 미설정
  department: null               // 학과 미선택
}
```

### 2. 프로필 미완성 (Incomplete Profile)
- **제한된 접근**: 프로필 설정 페이지만 접근 가능
- **자동 리다이렉트**: 다른 페이지 접근 시 프로필 설정으로 이동
- **필수 입력**: 닉네임, 학과, 학번, 역할

### 3. 일반 사용자 (Active Student)
```typescript
{
  profileCompleted: true,
  globalRole: "STUDENT",
  department: "AI/SW 학부",
  studentNo: "20241234",
  professorStatus: null
}
```

### 4. 교수 승인 대기 (Professor Pending)
```typescript
{
  profileCompleted: true,
  globalRole: "STUDENT",           // 승인 전까지 학생 권한
  professorStatus: "PENDING",      // 승인 대기 상태
  department: "AI/SW 학부"
}
```

### 5. 승인된 교수 (Approved Professor)
```typescript
{
  globalRole: "PROFESSOR",
  professorStatus: "APPROVED",
  department: "AI/SW 학부"
}
```

## 프로필 설정 플로우

### 1. Google OAuth 인증
```typescript
// Google ID Token 검증 후 사용자 생성/조회
POST /api/auth/google/callback
{
  "id_token": "google_oauth_id_token"
}

Response: {
  "access_token": "jwt_token",
  "user": {
    "email": "user@gmail.com",
    "name": "김철수",
    "profileCompleted": false
  }
}
```

### 2. 프로필 완성
```typescript
POST /api/users/profile
{
  "nickname": "철수짱",
  "department": "AI/SW 학부",
  "studentNo": "20241234",
  "globalRole": "STUDENT"
}
```

### 3. 자동 학과 가입
```kotlin
// 프로필 완성 후 자동 실행
fun completeProfile(userId: Long, request: ProfileRequest) {
    // 1. 프로필 업데이트
    updateUserProfile(userId, request)

    // 2. 학과 그룹 찾기 또는 생성
    val departmentGroup = findOrCreateDepartmentGroup(request.department)

    // 3. 자동 가입
    joinGroup(userId, departmentGroup, role = "MEMBER")

    // 4. 프로필 완성 플래그 설정
    markProfileCompleted(userId)
}
```

## 교수 승인 프로세스

### 1. 교수 역할 신청
```typescript
PATCH /api/users/request-professor
{
  "reason": "AI/SW 학부 교수로 재직 중입니다."
}
```

### 2. 관리자 승인/거부
```typescript
PATCH /api/admin/professor-requests/{userId}
{
  "action": "APPROVE" | "REJECT",
  "note": "승인 사유 또는 거부 사유"
}
```

### 3. 상태 변경 알림
```kotlin
// 승인 시
fun approveProfessor(userId: Long) {
    updateUserRole(userId, "PROFESSOR")
    updateProfessorStatus(userId, "APPROVED")
    sendNotification(userId, "교수 계정이 승인되었습니다.")

    // 해당 학과의 관리자 권한 부여
    grantDepartmentAdminRole(userId)
}
```

## 권한 변화

### 학생 → 교수 승인 시
```
권한 변화:
- 학과 그룹 관리 권한 획득
- 하위 그룹 생성 승인 권한
- 교수 전용 기능 접근 가능
- 학생 역할 관련 제약 제거
```

### 그룹 오너 양도
```kotlin
// 그룹 오너가 탈퇴하거나 역할 변경 시
fun transferGroupOwnership(groupId: Long, newOwnerId: Long) {
    val currentOwner = findGroupOwner(groupId)
    val newOwner = findUser(newOwnerId)

    // 1. 기존 오너의 역할을 일반 멤버로 변경
    updateGroupMemberRole(groupId, currentOwner.id, "MEMBER")

    // 2. 새 오너 설정
    updateGroupOwner(groupId, newOwnerId)
    updateGroupMemberRole(groupId, newOwnerId, "OWNER")

    // 3. 알림 발송
    sendOwnershipTransferNotification(groupId, currentOwner, newOwner)
}
```

## 계정 비활성화/삭제

### 일시 비활성화
```typescript
PATCH /api/users/deactivate
{
  "reason": "휴학",
  "expectedReturnDate": "2024-09-01"
}
```

### 계정 삭제
```kotlin
fun deleteUserAccount(userId: Long) {
    // 1. 그룹 오너십 확인 및 양도
    transferAllOwnerships(userId)

    // 2. 그룹 멤버십 정리
    leaveAllGroups(userId)

    // 3. 컨텐츠 익명화
    anonymizeUserContent(userId, "(탈퇴한 사용자)")

    // 4. 계정 삭제
    deleteUser(userId)
}
```

## 자동 가입 정책

### 기본 학과 설정
```kotlin
// 학과 미선택 시 기본값
val DEFAULT_DEPARTMENT = "AI/SW 학부"

fun getOrCreateDepartmentGroup(department: String?): Group {
    val targetDepartment = department ?: DEFAULT_DEPARTMENT

    return findDepartmentGroup(targetDepartment)
        ?: createDepartmentHierarchy(targetDepartment)
}

fun createDepartmentHierarchy(department: String): Group {
    // 한신대학교 → AI/SW 대학 → AI/SW 학부 자동 생성
    val university = findOrCreateUniversity("한신대학교")
    val college = findOrCreateCollege(university, "AI/SW 대학")
    val dept = createDepartment(college, department)

    return dept
}
```

## 상태별 UI 제어

### 프로필 미완성 사용자
```dart
// Flutter - 모든 페이지에서 프로필 완성 확인
Widget build(BuildContext context) {
  return Consumer<AuthProvider>(
    builder: (context, auth, child) {
      if (!auth.user.profileCompleted) {
        return ProfileSetupScreen(); // 강제 리다이렉트
      }
      return MainScreen();
    },
  );
}
```

### 교수 승인 대기
```dart
// 프로필 화면에 승인 대기 배너 표시
if (user.professorStatus == "PENDING") {
  return Container(
    color: Colors.orange,
    child: Text("교수 계정 승인 대기 중입니다."),
  );
}
```

## 관련 구현

### API 참조
- **사용자 관리**: [../implementation/api-reference.md#사용자관리](../implementation/api-reference.md#사용자관리)
- **인증/인가**: [../implementation/api-reference.md#인증인가](../implementation/api-reference.md#인증인가)

### 데이터베이스 설계
- **User 엔티티**: [../implementation/database-reference.md#User](../implementation/database-reference.md#User)
- **GroupMember 관계**: [../implementation/database-reference.md#GroupMember](../implementation/database-reference.md#GroupMember)

### 관련 개념
- **그룹 계층**: [group-hierarchy.md](group-hierarchy.md)
- **권한 시스템**: [permission-system.md](permission-system.md)

### 문제 해결
- **인증 에러**: [../troubleshooting/common-errors.md#인증](../troubleshooting/common-errors.md#인증)