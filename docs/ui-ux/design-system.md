# 디자인 시스템 (Design System)

## 컬러 팔레트

### Primary Colors
```css
--primary-50: #E3F2FD   /* 배경용 */
--primary-100: #BBDEFB  /* 보조 배경 */
--primary-200: #90CAF9  /* 비활성화 상태 */
--primary-500: #2196F3  /* 메인 액션 */
--primary-600: #1E88E5  /* 호버 상태 */
--primary-700: #1976D2  /* 활성 상태 */
--primary-900: #0D47A1  /* 강조 텍스트 */
```

### Semantic Colors
```css
--success-light: #E8F5E8
--success: #4CAF50
--success-dark: #388E3C

--warning-light: #FFF8E1
--warning: #FF9800
--warning-dark: #F57C00

--error-light: #FFEBEE
--error: #F44336
--error-dark: #D32F2F

--info-light: #E1F5FE
--info: #03A9F4
--info-dark: #0288D1
```

### Neutral Colors
```css
--gray-50: #FAFAFA    /* 배경 */
--gray-100: #F5F5F5   /* 카드 배경 */
--gray-200: #EEEEEE   /* 구분선 */
--gray-300: #E0E0E0   /* 비활성화 */
--gray-500: #9E9E9E   /* 보조 텍스트 */
--gray-700: #616161   /* 일반 텍스트 */
--gray-900: #212121   /* 제목 텍스트 */
```

## 타이포그래피

### 폰트 패밀리
```css
/* 한글 + 영문 */
--font-family: 'Pretendard', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;

/* 모노스페이스 (코드용) */
--font-family-mono: 'JetBrains Mono', 'Fira Code', monospace;
```

### 폰트 크기 (Type Scale)
```css
--text-xs: 0.75rem;    /* 12px - 캡션, 라벨 */
--text-sm: 0.875rem;   /* 14px - 보조 텍스트 */
--text-base: 1rem;     /* 16px - 기본 본문 */
--text-lg: 1.125rem;   /* 18px - 부제목 */
--text-xl: 1.25rem;    /* 20px - 제목 */
--text-2xl: 1.5rem;    /* 24px - 큰 제목 */
--text-3xl: 1.875rem;  /* 30px - 페이지 제목 */
```

### 폰트 두께
```css
--font-light: 300;
--font-normal: 400;
--font-medium: 500;
--font-semibold: 600;
--font-bold: 700;
```

## 간격 시스템 (Spacing)

### 기본 단위 (4px 기반)
```css
--space-1: 0.25rem;   /* 4px */
--space-2: 0.5rem;    /* 8px */
--space-3: 0.75rem;   /* 12px */
--space-4: 1rem;      /* 16px */
--space-5: 1.25rem;   /* 20px */
--space-6: 1.5rem;    /* 24px */
--space-8: 2rem;      /* 32px */
--space-10: 2.5rem;   /* 40px */
--space-12: 3rem;     /* 48px */
--space-16: 4rem;     /* 64px */
```

### 레이아웃 간격
```css
--layout-xs: var(--space-4);   /* 컴포넌트 내부 */
--layout-sm: var(--space-6);   /* 컴포넌트 간 */
--layout-md: var(--space-8);   /* 섹션 간 */
--layout-lg: var(--space-12);  /* 페이지 간 */
--layout-xl: var(--space-16);  /* 큰 섹션 간 */
```

## 반응형 브레이크포인트

### 디바이스 기준
```css
--breakpoint-mobile: 0px;      /* 모바일 */
--breakpoint-tablet: 768px;    /* 태블릿 */
--breakpoint-desktop: 900px;   /* 데스크톱 (핵심 기준점) */
--breakpoint-wide: 1200px;     /* 와이드 화면 */
```

### 미디어 쿼리
```css
@media (max-width: 899px) {
  /* 모바일 스타일 */
}

@media (min-width: 900px) {
  /* 데스크톱 스타일 */
}
```

## 그림자 (Shadows)

### 레벨별 그림자
```css
--shadow-xs: 0 1px 2px rgba(0, 0, 0, 0.05);
--shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.1), 0 1px 2px rgba(0, 0, 0, 0.06);
--shadow-md: 0 4px 6px rgba(0, 0, 0, 0.07), 0 2px 4px rgba(0, 0, 0, 0.06);
--shadow-lg: 0 10px 15px rgba(0, 0, 0, 0.1), 0 4px 6px rgba(0, 0, 0, 0.05);
--shadow-xl: 0 20px 25px rgba(0, 0, 0, 0.1), 0 10px 10px rgba(0, 0, 0, 0.04);
```

### 사용 가이드
- **shadow-xs**: 입력 필드, 테두리
- **shadow-sm**: 버튼, 작은 카드
- **shadow-md**: 일반 카드, 드롭다운
- **shadow-lg**: 모달, 큰 카드
- **shadow-xl**: 페이지 오버레이

## 둥근 모서리 (Border Radius)

```css
--radius-xs: 0.125rem;  /* 2px - 작은 요소 */
--radius-sm: 0.25rem;   /* 4px - 입력 필드 */
--radius-md: 0.375rem;  /* 6px - 버튼 */
--radius-lg: 0.5rem;    /* 8px - 카드 */
--radius-xl: 0.75rem;   /* 12px - 큰 카드 */
--radius-full: 9999px;  /* 완전한 원형 */
```

## 컴포넌트별 스타일 가이드

### 버튼
```css
/* Primary Button */
.btn-primary {
  background: var(--primary-500);
  color: white;
  padding: var(--space-3) var(--space-6);
  border-radius: var(--radius-md);
  font-weight: var(--font-medium);
  box-shadow: var(--shadow-sm);
}

.btn-primary:hover {
  background: var(--primary-600);
  box-shadow: var(--shadow-md);
}

/* Secondary Button */
.btn-secondary {
  background: transparent;
  color: var(--primary-600);
  border: 1px solid var(--primary-200);
  padding: var(--space-3) var(--space-6);
  border-radius: var(--radius-md);
}
```

### 카드
```css
.card {
  background: white;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
  padding: var(--space-6);
  border: 1px solid var(--gray-200);
}

.card:hover {
  box-shadow: var(--shadow-md);
  border-color: var(--gray-300);
}
```

### 입력 필드
```css
.input {
  border: 1px solid var(--gray-300);
  border-radius: var(--radius-sm);
  padding: var(--space-3) var(--space-4);
  font-size: var(--text-base);
  background: white;
}

.input:focus {
  border-color: var(--primary-500);
  box-shadow: 0 0 0 3px rgba(33, 150, 243, 0.1);
  outline: none;
}
```

## 상태별 스타일

### 로딩 상태
```css
.loading {
  opacity: 0.6;
  pointer-events: none;
  position: relative;
}

.loading::after {
  content: '';
  position: absolute;
  top: 50%;
  left: 50%;
  width: 20px;
  height: 20px;
  border: 2px solid var(--gray-300);
  border-top: 2px solid var(--primary-500);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}
```

### 비활성화 상태
```css
.disabled {
  opacity: 0.5;
  pointer-events: none;
  cursor: not-allowed;
}
```

### 에러 상태
```css
.error {
  border-color: var(--error);
  color: var(--error-dark);
}

.error-message {
  color: var(--error);
  font-size: var(--text-sm);
  margin-top: var(--space-2);
}
```

## 다크 모드 (향후 확장)

```css
@media (prefers-color-scheme: dark) {
  :root {
    --bg-primary: #121212;
    --bg-secondary: #1E1E1E;
    --text-primary: #FFFFFF;
    --text-secondary: #B3B3B3;
    --border-color: #333333;
  }
}
```

## 애니메이션

### 전환 효과
```css
--transition-fast: 150ms ease;
--transition-normal: 250ms ease;
--transition-slow: 350ms ease;

/* 사용 예시 */
.btn {
  transition: all var(--transition-normal);
}
```

### 키프레임
```css
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
```

## 아이콘 시스템

### 아이콘 크기
```css
--icon-xs: 12px;    /* 작은 인라인 아이콘 */
--icon-sm: 16px;    /* 버튼 내 아이콘 */
--icon-md: 20px;    /* 일반 아이콘 */
--icon-lg: 24px;    /* 강조 아이콘 */
--icon-xl: 32px;    /* 큰 아이콘 */
```

### 아이콘 스타일
```css
.icon {
  display: inline-block;
  width: var(--icon-md);
  height: var(--icon-md);
  fill: currentColor;
  vertical-align: middle;
}
```

## 관련 문서

### 레이아웃 구현
- **레이아웃 가이드**: [layout-guide.md](layout-guide.md)
- **컴포넌트 가이드**: [component-guide.md](component-guide.md)

### 프론트엔드 구현
- **프론트엔드 가이드**: [../implementation/frontend-guide.md](../implementation/frontend-guide.md)

### 개념 참조
- **워크스페이스 구조**: [../concepts/workspace-channel.md](../concepts/workspace-channel.md)