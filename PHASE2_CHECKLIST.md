# SectionCard Phase 2 적용 체크리스트

작성일: 2025-10-25
관련 문서: [PHASE2_STRATEGY.md](./PHASE2_STRATEGY.md)

## 📋 사전 준비 체크리스트

### 환경 확인
- [ ] Flutter 개발 서버 실행 중 (port 5173)
- [ ] 백엔드 서버 실행 중
- [ ] 브랜치 확인: `palce_callendar`
- [ ] 최신 커밋과 동기화됨

### 문서 리뷰
- [ ] PHASE2_STRATEGY.md 읽음
- [ ] Phase 1 완료 현황 확인 (MEMO_component_analysis.md)
- [ ] SectionCard 소스 코드 이해
- [ ] Row/Column 레이아웃 체크리스트 숙지

## 🎯 Step 1: Category A 적용 (2-3시간)

### 1.1 대상 파일 식별 (30분)
- [ ] 79개 파일 중 Category A 분류 (30개 예상)
- [ ] 각 파일의 Container + BoxDecoration 패턴 위치 파악
- [ ] 적용 우선순위 결정 (높은 ROI 우선)

#### 분류 기준
**Category A (바로 적용 가능)**:
- ✅ 흰색 또는 단색 배경
- ✅ 기본 패딩 (AppSpacing.md 또는 커스터마이징)
- ✅ 기본 그림자 (있거나 없거나)
- ✅ InkWell/GestureDetector 없음
- ✅ border가 없거나 단순함

**Category B (확장 필요)**:
- ⚠️ InkWell/GestureDetector와 조합
- ⚠️ onTap 필요
- ⚠️ 복잡한 border (색상/두께 커스터마이징)

**Category C (제외)**:
- ❌ 아이콘 컨테이너 (40x40 이하)
- ❌ 뱃지/칩 (작은 라벨)
- ❌ 이미 전용 컴포넌트 (ActionCard, PlaceCard)
- ❌ 특수 UI (캘린더, 피커)

### 1.2 샘플 3개 파일 적용 (30분)
**목적**: Proof of Concept, 문제 조기 발견

선정 기준:
- [ ] 서로 다른 페이지 (다양한 컨텍스트)
- [ ] 간단한 패턴 (확실한 성공)
- [ ] 중요도 중간 (리스크 최소화)

**샘플 1**: `group_explore_page.dart` (에러 배너)
- [ ] 코드 리뷰 (L64-89)
- [ ] SectionCard로 변경
- [ ] 로컬 빌드 테스트
- [ ] 에러 배너 표시 확인

**샘플 2**: `recruitment_detail_page.dart` (에러 배너)
- [ ] 코드 리뷰
- [ ] SectionCard로 변경
- [ ] 로컬 빌드 테스트
- [ ] UI 정상 작동 확인

**샘플 3**: `demo_member_filter_page.dart` (섹션 컨테이너)
- [ ] 코드 리뷰
- [ ] SectionCard로 변경
- [ ] 로컬 빌드 테스트
- [ ] 필터 패널 작동 확인

### 1.3 샘플 테스트 (15분)
- [ ] `flutter run -d chrome --web-hostname localhost --web-port 5173`
- [ ] 각 페이지 수동 탐색
- [ ] 레이아웃 깨짐 없음
- [ ] 색상/스타일 일관성 확인
- [ ] 콘솔 에러 없음

### 1.4 나머지 27개 파일 적용 (1.5-2시간)
**전략**: 페이지별로 그룹화하여 적용

#### 그룹 1: 관리 페이지 (Admin/Member Management)
- [ ] `member_list_section.dart`
- [ ] `role_management_section.dart`
- [ ] `join_request_section.dart`
- [ ] `recruitment_application_section.dart`
- [ ] `subgroup_request_section.dart`
- [ ] `channel_list_section.dart` (아이콘 제외)

#### 그룹 2: 홈/탐색 페이지
- [ ] `home_page.dart` (섹션 컨테이너)
- [ ] `group_explore_content_widget.dart`
- [ ] `group_tree_node_widget.dart` (InkWell 없는 부분)

#### 그룹 3: 다이얼로그/시트
- [ ] `create_channel_dialog.dart`
- [ ] `edit_group_dialog.dart`
- [ ] `create_subgroup_dialog.dart`
- [ ] `event_detail_sheet.dart`
- [ ] `schedule_detail_sheet.dart`

#### 그룹 4: 위젯/컴포넌트
- [ ] `user_info_card.dart`
- [ ] `post_composer.dart`
- [ ] `comment_composer.dart`
- [ ] `post_preview_widget.dart`

#### 적용 중 체크포인트 (파일 5개마다)
- [ ] 빌드 테스트
- [ ] 콘솔 에러 확인
- [ ] 변경 사항 스테이징 (`git add`)

## 🧪 Step 2: 중간 빌드 테스트 (30분)

### 2.1 빌드 및 실행
- [ ] `flutter clean` (필요 시)
- [ ] `flutter run -d chrome --web-hostname localhost --web-port 5173`
- [ ] 빌드 에러 없음
- [ ] 경고(warning) 확인 및 수정

### 2.2 기능 테스트 (각 그룹별)
**그룹 1: 관리 페이지**
- [ ] 그룹 관리 페이지 접근
- [ ] 멤버 목록 표시 확인
- [ ] 역할 관리 탭 전환
- [ ] 가입 신청 섹션 작동
- [ ] 채널 목록 표시

**그룹 2: 홈/탐색**
- [ ] 홈 페이지 로드
- [ ] 그룹 탐색 탭 전환
- [ ] 그룹 트리 뷰 확장/축소

**그룹 3: 다이얼로그**
- [ ] 채널 생성 다이얼로그 열기
- [ ] 그룹 편집 다이얼로그 열기
- [ ] 서브그룹 생성 다이얼로그 열기

**그룹 4: 위젯**
- [ ] 게시글 작성 컴포저
- [ ] 댓글 작성 컴포저
- [ ] 사용자 정보 카드

### 2.3 레이아웃 확인
- [ ] 데스크톱 (900px+) 레이아웃 정상
- [ ] 모바일 (900px-) 레이아웃 정상
- [ ] 반응형 전환 부드러움
- [ ] 스크롤 정상 작동

### 2.4 접근성 확인
- [ ] 커스텀 배경색 명암 대비 확인
- [ ] 텍스트 가독성 확인
- [ ] 에러 배너 색상 대비 (WCAG 4.5:1)

### 2.5 에러 확인
- [ ] 브라우저 콘솔 에러 없음
- [ ] Flutter DevTools 에러 없음
- [ ] Row/Column 제약 에러 없음
- [ ] Overflow 에러 없음

## 🔧 Step 3: SectionCard 확장 검토 (1시간)

### 3.1 Category B 재평가
- [ ] Category B 파일 25개 재확인
- [ ] 각 파일의 InkWell/onTap 사용 패턴 분석
- [ ] border 커스터마이징 필요성 분석

### 3.2 확장 필요성 결정
**확장 진행 조건** (모두 충족 시):
- [ ] Category B 파일이 15개 이상
- [ ] onTap 패턴이 반복적으로 사용됨
- [ ] border 커스터마이징이 5개 이상 파일에서 필요
- [ ] ROI가 40줄 이상 절약 예상

**확장 보류 조건** (하나라도 해당 시):
- [ ] Category B 파일이 10개 미만
- [ ] 각 파일이 너무 특수함 (패턴 없음)
- [ ] 기존 SectionCard 복잡도 우려
- [ ] 시간 제약 (추가 3시간 부담)

### 3.3 확장 설계 (진행 시)
**추가할 Props**:
```dart
class SectionCard extends StatelessWidget {
  // 기존 props
  final Widget child;
  final EdgeInsets? padding;
  final bool showShadow;
  final Color? backgroundColor;
  final double? borderRadius;

  // 🆕 추가 props
  final VoidCallback? onTap;           // InkWell 통합
  final Color? borderColor;            // 테두리 색상
  final double? borderWidth;           // 테두리 두께
}
```

- [ ] Props 설계 완료
- [ ] 기본값 설정 (기존 동작 유지)
- [ ] 문서화 (dartdoc 주석)

### 3.4 기존 사용처 영향 분석
- [ ] Phase 1 적용 파일 8개 리뷰
- [ ] 새 props가 옵셔널이므로 영향 없음 확인
- [ ] 빌드 테스트로 검증

## 🚀 Step 4: Category B 적용 (2-3시간, 선택사항)

### 4.1 SectionCard 확장 구현 (30분)
- [ ] `section_card.dart` 수정
- [ ] onTap → InkWell 래핑
- [ ] borderColor, borderWidth → BoxDecoration 반영
- [ ] 기본값 설정
- [ ] dartdoc 주석 업데이트

### 4.2 확장 테스트 (15분)
- [ ] 빌드 테스트
- [ ] Phase 1 파일 (8개) 정상 작동 확인
- [ ] 샘플 Category B 파일 1개로 테스트

### 4.3 Category B 파일 적용 (1.5-2시간)
**우선순위**:
1. [ ] InkWell 패턴 파일 (15개)
2. [ ] border 커스터마이징 파일 (10개)

**적용 중 체크포인트** (파일 5개마다):
- [ ] 빌드 테스트
- [ ] onTap 동작 확인
- [ ] InkWell ripple 효과 확인
- [ ] 콘솔 에러 확인

### 4.4 Category B 테스트 (30분)
- [ ] 전체 빌드
- [ ] 클릭 가능한 카드 작동 확인
- [ ] ripple 효과 정상
- [ ] 레이아웃 확인

## ✅ Step 5: 최종 테스트 (30분)

### 5.1 전체 빌드 및 실행
- [ ] `flutter clean`
- [ ] `flutter run -d chrome --web-hostname localhost --web-port 5173`
- [ ] 빌드 에러/경고 없음

### 5.2 회귀 테스트 (Regression Test)
**핵심 플로우**:
- [ ] 로그인 플로우
- [ ] 그룹 탐색 → 그룹 선택
- [ ] 워크스페이스 → 채널 이동
- [ ] 게시글 작성/읽기
- [ ] 댓글 작성/읽기
- [ ] 그룹 관리 → 멤버 관리
- [ ] 모집 공고 작성/지원

**UI/UX**:
- [ ] 모든 카드 컨테이너 정상 표시
- [ ] 간격/패딩 일관성
- [ ] 색상/스타일 일관성
- [ ] 반응형 레이아웃 정상

### 5.3 성능 확인
- [ ] 페이지 로드 시간 (이전과 동일)
- [ ] 스크롤 성능 (부드러움)
- [ ] 메모리 사용량 (이전과 유사)

### 5.4 접근성 재확인
- [ ] 키보드 네비게이션
- [ ] 스크린 리더 호환성
- [ ] 명암 대비 (WCAG AA)

## 📝 Step 6: 문서화 및 커밋 (30분)

### 6.1 코드 정리
- [ ] 사용하지 않는 import 제거
- [ ] 포맷팅 (`flutter format .`)
- [ ] lint 경고 수정 (`flutter analyze`)

### 6.2 문서 업데이트
- [ ] `MEMO_component_analysis.md` 업데이트:
  - Phase 2 완료 현황 반영
  - 적용 파일 수 업데이트
  - 코드 감소 줄 수 추가
- [ ] `PHASE2_STRATEGY.md` 완료 표시
- [ ] `PHASE2_CHECKLIST.md` 완료 표시

### 6.3 커밋 준비
- [ ] `git status` 확인
- [ ] 변경된 파일 리뷰
- [ ] `git add .` (SectionCard 관련 파일만)

### 6.4 커밋
```bash
git commit -m "feat(frontend): SectionCard Phase 2 적용

- Category A 30개 파일에 SectionCard 적용
- [선택] Category B 25개 파일 추가 적용 (확장 후)
- 코드 감소: 100-150줄
- 카드 컨테이너 스타일 일관성 개선

영향 범위:
- 관리 페이지 (멤버, 역할, 채널)
- 홈/탐색 페이지
- 다이얼로그/시트
- 위젯/컴포넌트

테스트:
- 빌드 테스트 통과
- 회귀 테스트 통과
- 접근성 확인 완료

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 6.5 푸시 (사용자 승인 후)
- [ ] `git push origin palce_callendar`

## 🎉 완료 기준

### 필수 (Minimum Viable Phase 2)
- ✅ Category A 30개 파일 적용 완료
- ✅ 빌드 테스트 통과
- ✅ 회귀 테스트 통과
- ✅ 문서 업데이트 완료
- ✅ 커밋 완료

### 선택 (Full Phase 2)
- ✅ SectionCard 확장 완료
- ✅ Category B 25개 파일 적용 완료
- ✅ 모든 테스트 통과

## 🚨 중단 조건 (Stop Conditions)

다음 상황 발생 시 작업 중단 및 롤백:
- ⛔ 빌드 에러가 30분 이상 해결되지 않음
- ⛔ Row/Column 제약 에러가 5개 이상 발생
- ⛔ 회귀 테스트 실패 (핵심 플로우 깨짐)
- ⛔ 성능 저하 (페이지 로드 20% 이상 증가)
- ⛔ 예상 시간 초과 (8시간 이상 소요)

## 📊 진행 상황 트래킹

### Category A 진행률
- [ ] 샘플 3개 완료 (10%)
- [ ] 그룹 1 완료 (30%)
- [ ] 그룹 2 완료 (50%)
- [ ] 그룹 3 완료 (70%)
- [ ] 그룹 4 완료 (100%)

### 전체 Phase 2 진행률
- [ ] Step 1 완료 (40%)
- [ ] Step 2 완료 (50%)
- [ ] Step 3 완료 (60%)
- [ ] Step 4 완료 (85%, 선택)
- [ ] Step 5 완료 (95%)
- [ ] Step 6 완료 (100%)

---

**사용 방법**: 각 항목을 완료하면 `- [ ]`를 `- [x]`로 변경하여 진행 상황 추적
