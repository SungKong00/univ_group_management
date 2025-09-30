# Web Application Color System Guide (학교 공식 색상 반영 · 표 안정화 버전)

**[우선순위] 라이트 모드(Light Mode)를 먼저 구현합니다.**  
이 문서는 학교 **공식 보라색(Pantone 2597 CVC / Hex #5C068C)**을 기준으로 웹 애플리케이션의 컬러 시스템을 정의합니다.

---

## 🎨 라이트 모드 (Light Mode)

### 1) 컨셉
창의성 · 활기 · 동기 부여. 밝고 경쾌한 경험을 제공합니다.

### 2) 팔레트 및 역할

#### 브랜드 컬러
primary:     #5C068C   // 메인 브랜드 컬러 (학교 공식: Pantone 2597 CVC)
brandStrong: #4B0672   // Hover/Active 등 진한 보라(톤 다운)
brandLight:  #F2E8FA   // 톤 컨테이너/칩/강조 배경(연보라 틴트)

#### 중성 컬러
neutral900: #0F172A   // 제목, 가장 중요한 텍스트
neutral800: #1E293B   // 섹션 타이틀
neutral700: #334155   // 본문 텍스트
neutral600: #64748B   // 보조 텍스트/아이콘
neutral500: #94A3B8   // 서브 아이콘, 비활성 텍스트
neutral400: #CBD5E1   // 얕은 보더/디바이더
neutral300: #E2E8F0   // 카드 보더/섹션 분리
neutral200: #EEF2F6   // 카드/패널 표면 구분
neutral100: #F8FAFC   // 페이지 베이스 배경

#### 시스템 컬러
// 액션(행동) — 버튼/링크/선택 상태는 블루로 통일
actionPrimary:  #1D4ED8   // 주요 CTA/링크
actionHover:    #0F3CC9   // Hover/포커스 시
actionTonalBg:  #EAF2FF   // 선택 배경/하이라이트 표면

// 상태(의미 고정)
success:        #10B981   // 성공/활성
warning:        #F59E0B   // 경고
error:          #E63946   // 오류/위험(가독성 좋은 레드)

// 접근성
focusRing:      rgba(92, 6, 140, 0.45)  // 브랜드 보라 Focus Ring(2px 권장)

### 3) 인터랙션
- Hover: 액션 색상은 명도만 소폭 상승. 예) #1E6FFF → #3B87FF  
- Disabled: 배경 #E9ECEF, 텍스트 #ADB5BD

### 4) 상세 가이드
- 메인 퍼플은 **절제된 사용**: 포커스 링, 핵심 버튼, 주요 링크에 제한적으로 적용  
- 액션(블루), 피드백(민트/레드)은 **채도 낮춤**으로 보라와 조화 유지  
- 대비(명도비) AA 이상 확보

---

## 🌙 다크 모드 (Dark Mode)

### 1) 컨셉
몰입감 · 안정감 · 신뢰. 깊은 배경과 선명한 포인트를 제공합니다.

### 2) 팔레트 및 역할

#### 브랜드 컬러
primary:     #5C068C   // 메인 브랜드 컬러 (Pantone 2597 CVC)
brandStrong: #D6B8F2   // 다크 배경에서 밝게 띄우는 보라 포인트
brandLight:  #521A77   // 보라 톤 컨테이너/칩/토글 배경

#### 중성컬러
neutralSurface:        #121212   // 기본 배경
neutralSurfaceElevated:#1A1A1A   // 카드/패널 표면
neutralBorder:         #2B3440   // 경계선/디바이더

neutral900: #FFFFFF    // 제목/주요 텍스트
neutral800: #E5E7EB    // 부제목/서브 타이틀
neutral700: #CBD5E1    // 본문 텍스트
neutral600: #94A3B8    // 보조 텍스트/아이콘
neutral500: #64748B    // 비활성 텍스트
neutral400: #475569    // 진한 보더/구분선

#### 시스템 컬러
actionPrimary:   #3B82F6              // 주요 CTA/링크
actionHover:     #60A5FA              // Hover/Focus 시
actionTonalBg:   rgba(59,130,246,0.16)// 선택 배경/하이라이트

success:         #10B981              // 성공/활성
successTonalBg:  rgba(16,185,129,0.16)

warning:         #F59E0B              // 경고
warningTonalBg:  rgba(245,158,11,0.16)

error:           #E63946              // 오류/위험
errorTonalBg:    rgba(230,57,70,0.16)

focusRing:       rgba(92,6,140,0.55)  // 브랜드 보라 포커스 링

### 3) 인터랙션
- Hover: 액션 색상은 명도만 소폭 상승. 예) #1E6FFF → #3B87FF  
- Disabled: 배경 #343A40, 텍스트 #6C757D

### 4) 상세 가이드
- 다크 배경 대비를 위해 텍스트는 **화이트 100%** 유지  
- 보라는 **강조 요소** 위주, 대면적 배경에는 사용 지양  
- 카드/패널은 배경 대비 **약간 밝은 서피스** 사용(#1A1A1A)

---

## ✅ 접근성 원칙
- 텍스트/배경 명도 대비 **WCAG 2.1 AA(4.5:1 이상)** 충족  
- 포커스 링은 충분한 가시성 확보(예: #5C068C 2px)  
- 색상만으로 정보를 전달하지 않고, 아이콘/문구 병행

---

## 🧱 개발 적용 원칙
- 모든 색상은 **디자인 토큰**으로 관리(하드코딩 금지)  
- 라이트/다크 **각 팔레트 1:1 매핑** 유지  
- 토큰 예시: `color.brand.primary = #5C068C`, `color.text.primary.light = #121212`

