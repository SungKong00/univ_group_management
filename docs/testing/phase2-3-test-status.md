# Phase 2-3 장소 캘린더 테스트 진행 상황

> **마지막 업데이트**: 2025-10-14
> **상태**: 구현 완료, 테스트 진행 중 (6/14 완료)
> **관련 문서**: [place-calendar-specification.md](../features/place-calendar-specification.md) | [calendar-integration-roadmap.md](../features/calendar-integration-roadmap.md)

---

## 📊 전체 진행 상황

### 구현 완료
- ✅ **Phase 2**: 장소 관리 기본 기능 (CRUD, 운영시간 설정)
- ✅ **Phase 3**: 예약 권한 신청 시스템 (승인/거절/취소)

### 테스트 진행
- **완료**: 6개 시나리오 (1-2, 3-수정, 5-수정, 7-수정, 파싱 이슈)
- **남은 작업**: 8개 시나리오 (4, 6, 8-14)

---

## ✅ 테스트 완료 시나리오

### 성공 (2개)
1. ✅ **시나리오 1**: 장소 목록 조회 - 정상 동작
2. ✅ **시나리오 2**: 장소 생성 - 정상 동작

### 수정 완료 (4개)
3. ✅ **시나리오 3**: 운영시간 설정 무한 로딩
   - **원인**: `managingGroupName` 필드 누락으로 파싱 실패
   - **수정**: Place 모델에 필드 추가

5. ✅ **시나리오 5**: 장소 삭제 400 에러
   - **원인**: 204 No Content 응답을 에러로 처리
   - **수정**: PlaceService.deletePlace()에서 204 응답 명시적 처리

7. ✅ **시나리오 7**: 권한 없을 시 장소 미표시
   - **원인**: API 에러 시 빈 배열 반환하여 에러 상태 전달 안 됨
   - **수정**: getAllPlaces()에서 예외 rethrow

### 파싱 이슈 수정 (2개)
- ✅ **UsageStatus enum**: 소문자 → 대문자 통일 (PENDING, APPROVED, REJECTED)
- ✅ **PlaceUsageGroup**: `placeName` 필드 추가

---

## ⏳ 남은 테스트 시나리오

4. 장소 수정 (폼 pre-fill, API 연동)
6. 검색 기능 (건물명, 방 번호, 별칭)
8. 예약 권한 신청 (PlaceUsageRequestDialog)
9. 대기 중인 신청 승인 (PlaceUsageManagementTab)
10. 대기 중인 신청 거절 (거절 사유 입력)
11. 권한 취소 (경고 다이얼로그, 미래 예약 삭제)
12. 중복 신청 방지 (PENDING/APPROVED 상태 체크)
13. 거절 후 재신청 (REJECTED → PENDING 상태 전환)
14. 전체 플로우 E2E 테스트

---

## 🔍 추가 확인 필요 사항

### 1. UsageStatus enum 사용처 확인
다음 파일에서 `UsageStatus.pending` → `UsageStatus.PENDING` 변경 필요:
- `place_usage_request_dialog.dart`
- `place_usage_management_tab.dart`
- `place_service.dart`

### 2. 백엔드 데이터 확인
```bash
# 서버 재시작 (data.sql 로드)
cd backend
./gradlew bootRun

# 장소 API 테스트
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:8080/api/places
```
예상 결과: 8개 장소 반환 (공학관 3개, 중앙도서관 2개, 학생회관/체육관/본관 각 1개)

### 3. 프론트엔드 상태
- Flutter 재시작: `R` (대문자) 입력
- 브라우저 캐시 클리어: `Cmd + Shift + R`
- Network 탭에서 `/api/places` 응답 확인 (200 OK, 8개 데이터)

---

## 🚀 다음 세션 시작 가이드

### 1. 환경 준비
```bash
# 백엔드 실행
cd backend
./gradlew bootRun

# 프론트엔드 실행
cd frontend
flutter run -d chrome --web-hostname localhost --web-port 5173
```

### 2. JWT 토큰 생성
```bash
cd backend/scripts
./generate_jwt_token.sh castlekong1019@gmail.com
export TOKEN="[생성된 토큰]"
```

### 3. 테스트 시작
- 시나리오 4번부터 순차 진행
- 발견된 이슈는 이 문서에 기록

---

**태그**: #testing #place-calendar #phase2 #phase3
**서브 에이전트**: frontend-debugger, api-integrator, context-manager
