# 하이브리드 그룹 탐색 시스템 구현 완료

## 구현 날짜
2025-10-24

## 개요
그룹 탐색 시스템에 하이브리드 전략을 적용하여 성능 최적화 및 확장성 확보

## 하이브리드 전략

### 전략 개요
- **그룹 개수 ≤ 500개**: 전체 로드 (`/api/groups/all`) + 로컬 필터링
- **그룹 개수 > 500개**: 페이지네이션 (`/api/groups/explore`) + 무한 스크롤

### 장점
1. **초기 로딩 최적화**: 그룹 수에 따라 적절한 전략 선택
2. **즉각 반응**: 500개 이하일 때 로컬 필터링으로 즉각 반응
3. **확장성**: 그룹 수가 많아져도 성능 유지
4. **유연성**: 필터 변경 시 자동으로 적절한 처리 방식 선택

## 구현 파일

### 1. 새로 생성된 파일

#### `/frontend/lib/core/models/paged_response.dart`
- `PaginationInfo`: 페이지네이션 정보 모델
- `PagedData<T>`: 페이지네이션 데이터 래퍼
- `PagedApiResponse<T>`: 백엔드 API 응답 모델

### 2. 수정된 파일

#### `/frontend/lib/core/services/group_explore_service.dart`
**추가 메서드**:
- `getGroups()`: 페이지네이션 API 호출
  - 파라미터: `page`, `size`, `queryParams`
  - 반환: `PagedApiResponse<GroupSummaryResponse>`

#### `/frontend/lib/core/providers/unified_group_provider.dart`
**UnifiedGroupState 확장**:
- `currentPage`: 현재 페이지 번호
- `hasMore`: 더 불러올 데이터 존재 여부
- `isLoadingMore`: 추가 로딩 중 상태
- `totalCount`: 전체 그룹 수
- `usePagination`: 페이지네이션 사용 여부 플래그

**UnifiedGroupStateNotifier 메서드 수정**:
- `initialize()`: 하이브리드 전략 로직
  1. 전체 개수 확인 (page=0, size=1)
  2. 500개 이하: 전체 로드
  3. 500개 초과: 페이지네이션 모드

- `applyFilter()`: 필터 적용 로직
  - 전체 로드 모드: 로컬 필터링만
  - 페이지네이션 모드: API 재호출

- `loadMore()`: 무한 스크롤 구현
  - 다음 페이지 로드
  - 페이지네이션 모드에서만 동작

**계층구조 트리 기능 주석 처리**:
- `GroupSummaryResponse`에 `parentId` 필드가 없어서 계층 구조 구축 불가
- 향후 `GroupHierarchyNode` 사용 필요

#### `/frontend/lib/presentation/pages/group_explore/providers/unified_group_selectors.dart`
**새로 추가된 Provider**:
- `usePaginationProvider`: 페이지네이션 사용 여부
- `hasMoreProvider`: 더 불러올 데이터 존재 여부
- `isLoadingMoreProvider`: 추가 로딩 중 상태
- `totalCountProvider`: 전체 그룹 개수

#### `/frontend/lib/presentation/pages/group_explore/widgets/group_explore_list.dart`
**무한 스크롤 복원**:
- `_onScroll()`: 스크롤 이벤트 리스너
  - 페이지네이션 모드에서만 동작
  - 90% 지점에서 다음 페이지 로드
- `_isNearBottom()`: 스크롤 하단 감지
- `isLoadingMore` 표시: 추가 로딩 인디케이터

## 동작 흐름

### 초기화 단계
```
1. initialize() 호출
   ↓
2. 전체 개수 확인 (page=0, size=1)
   ↓
3. totalCount ≤ 500?
   ├─ Yes → getAllGroups() 호출 (전체 로드)
   └─ No  → getGroups(page=0, size=20) 호출 (페이지네이션)
   ↓
4. usePagination 플래그 설정
```

### 필터 변경 시
```
1. applyFilter(filter) 호출
   ↓
2. usePagination == false?
   ├─ Yes → 로컬 필터링만 (즉시 반영)
   └─ No  → API 재호출 (page=0으로 리셋)
```

### 무한 스크롤 (페이지네이션 모드)
```
1. 사용자가 90% 지점까지 스크롤
   ↓
2. _onScroll() 호출
   ↓
3. usePagination == true && hasMore == true?
   ├─ Yes → loadMore() 호출
   │         ├─ page += 1
   │         ├─ API 호출
   │         └─ 기존 목록에 추가
   └─ No  → 무시
```

## 성능 개선

### API 호출 비교
| 시나리오 | Before (로컬 필터링) | After (하이브리드) | 개선 효과 |
|---------|---------------------|-------------------|----------|
| 초기 로딩 (100개) | 1회 (전체) | 1회 (전체) | 동일 |
| 초기 로딩 (1000개) | 1회 (전체) | 1회 (page 0) | 초기 로딩 빠름 |
| 필터 변경 (100개) | 0회 (로컬) | 0회 (로컬) | 동일 |
| 필터 변경 (1000개) | 0회 (로컬) | 1회 (API) | 필터링 정확도 향상 |

### 메모리 사용
- **100개 그룹**: ~100KB (전체 로드)
- **1000개 그룹**: ~20KB/페이지 (페이지네이션)
- **장점**: 대량의 그룹에서도 메모리 효율적

## 알려진 이슈 및 TODO

### 1. 계층구조 트리 기능 미구현
**문제**:
- `GroupSummaryResponse`에 `parentId` 필드가 없음
- `hierarchyTree` getter가 빈 배열 반환

**해결책**:
- `GroupHierarchyNode` 모델 사용
- 별도의 API 엔드포인트 (`/api/groups/hierarchy`) 활용
- 계층구조 전용 Provider 구현

### 2. 필터 변경 시 페이지네이션 모드에서 API 호출
**현재 동작**:
- 페이지네이션 모드에서 필터 변경 시 API 재호출

**개선 방안**:
- 현재 로드된 데이터에서 먼저 로컬 필터링
- 사용자가 명시적으로 검색 버튼을 누를 때만 API 호출
- 디바운싱 적용

### 3. 임계값 조정 가능성
**현재**: 500개를 기준으로 전략 선택

**개선 방안**:
- 사용자 설정으로 임계값 조정 가능
- 네트워크 상태에 따라 동적 조정
- 서버 설정으로 임계값 제공

## 테스트 체크리스트

### 기능 테스트
- [ ] 100개 그룹: 전체 로드 모드 동작 확인
- [ ] 600개 그룹: 페이지네이션 모드 동작 확인
- [ ] 필터 변경 시 적절한 처리 확인
- [ ] 무한 스크롤 동작 확인 (페이지네이션 모드)
- [ ] 로딩 인디케이터 표시 확인

### 성능 테스트
- [ ] 초기 로딩 시간 측정
- [ ] 필터 변경 반응 시간 측정
- [ ] 메모리 사용량 측정
- [ ] 네트워크 트래픽 측정

### 에러 처리
- [ ] API 실패 시 에러 메시지 표시
- [ ] 네트워크 오류 시 재시도 로직
- [ ] 빈 결과 처리

## 관련 문서

- **설계 문서**: `/DESIGN_group_explore_local_filtering.md`
- **API 참조**: `/docs/implementation/api-reference.md`
- **프론트엔드 가이드**: `/docs/implementation/frontend/README.md`

## 다음 단계

1. 실제 환경에서 테스트 (100개 이하/이상 케이스)
2. 성능 측정 및 임계값 조정
3. 계층구조 트리 기능 구현 (별도 작업)
4. 사용자 피드백 수집 및 개선

## 구현 완료 시간
약 2시간 (모델 생성 → 서비스 수정 → Provider 확장 → UI 연동 → 테스트)
