# 레이아웃 가이드 (Layout Guide)

## 반응형 레이아웃 전략

### 브레이크포인트 기반 설계
```
Mobile (< 900px)           Desktop (≥ 900px)
┌─────────────────────┐    ┌─────────────────────────────────────┐
│ Header              │    │Global │ Content Area              │
├─────────────────────┤    │Sidebar│                           │
│                     │    │(60px) │                           │
│ Main Content        │    │       │                           │
│                     │    │       │                           │
├─────────────────────┤    │       │                           │
│ Bottom Navigation   │    │       │                           │
└─────────────────────┘    └─────────────────────────────────────┘
```

## 데스크톱 레이아웃 (≥ 900px)

### 전체 구조
```
┌─────────────────────────────────────────────────────────┐
│ Global Sidebar │        Main Content Area               │
│    (60px)      │                                        │
│                │  ┌──────────────────────────────────┐  │
│ [🏠] Home      │  │ Page Header                      │  │
│ [📁] Groups    │  ├──────────────────────────────────┤  │
│ [🔍] Explore   │  │                                  │  │
│ [👤] Profile   │  │ Page Content                     │  │
│                │  │                                  │  │
│                │  │                                  │  │
│                │  └──────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Global Sidebar 상세
```css
.global-sidebar {
  width: 60px;
  height: 100vh;
  position: fixed;
  left: 0;
  top: 0;
  background: var(--gray-900);
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: var(--space-4) 0;
  z-index: 100;
}

.sidebar-item {
  width: 40px;
  height: 40px;
  border-radius: var(--radius-md);
  margin-bottom: var(--space-3);
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--gray-300);
  cursor: pointer;
  transition: all var(--transition-normal);
}

.sidebar-item.active {
  background: var(--primary-500);
  color: white;
}
```

### 워크스페이스 레이아웃 (3단 구조)
```
┌──────┬─────────────┬─────────────────────────────────────┐
│Global│ Workspace   │ Channel Content                     │
│Sidebar│ Sidebar     │                                     │
│(60px)│ (250px)     │ ┌─────────────────────────────────┐ │
│      │             │ │ Channel Header                  │ │
│[🏠]  │ 📢 공지사항  │ ├─────────────────────────────────┤ │
│[📁]  │ 💬 일반대화  │ │ Messages/Posts                  │ │
│[🔍]  │ 💬 자유게시판│ │                                 │ │
│[👤]  │ 💬 운영진전용│ │                                 │ │
│      │             │ │                                 │ │
│      │             │ ├─────────────────────────────────┤ │
│      │             │ │ Input Area                      │ │
│      │             │ └─────────────────────────────────┘ │
└──────┴─────────────┴─────────────────────────────────────┘
```

## 모바일 레이아웃 (< 900px)

### 전체 구조
```
┌─────────────────────────────────────┐
│ Header (고정)                        │
├─────────────────────────────────────┤
│                                     │
│                                     │
│ Main Content (스크롤 가능)           │
│                                     │
│                                     │
├─────────────────────────────────────┤
│ Bottom Navigation (고정)            │
│ [🏠] [📁] [🔍] [👤]                │
└─────────────────────────────────────┘
```

### Bottom Navigation
```css
.bottom-navigation {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 60px;
  background: white;
  border-top: 1px solid var(--gray-200);
  display: flex;
  justify-content: space-around;
  align-items: center;
  z-index: 100;
}

.nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: var(--space-1);
  padding: var(--space-2);
  color: var(--gray-500);
  text-decoration: none;
  font-size: var(--text-xs);
}

.nav-item.active {
  color: var(--primary-500);
}
```

### 모바일 워크스페이스
```
┌─────────────────────────────────────┐
│ ← AI 학회           [⚙️] [👥]        │ Header
├─────────────────────────────────────┤
│ 📢 공지사항                          │ Channel List
│ 💬 일반대화 (5)                      │ (Collapsible)
│ 💬 자유게시판                        │
├─────────────────────────────────────┤
│                                     │
│ Messages/Posts                      │ Content
│ (Full height)                       │
│                                     │
├─────────────────────────────────────┤
│ [메시지 입력...]            [전송]   │ Input
└─────────────────────────────────────┘
```

## 컴포넌트별 레이아웃

### 카드 그리드
```css
.card-grid {
  display: grid;
  gap: var(--space-6);
}

/* 반응형 그리드 */
@media (min-width: 640px) {
  .card-grid { grid-template-columns: repeat(2, 1fr); }
}

@media (min-width: 900px) {
  .card-grid { grid-template-columns: repeat(3, 1fr); }
}

@media (min-width: 1200px) {
  .card-grid { grid-template-columns: repeat(4, 1fr); }
}
```

### 폼 레이아웃
```css
.form-layout {
  max-width: 400px;
  margin: 0 auto;
  padding: var(--space-6);
}

.form-group {
  margin-bottom: var(--space-5);
}

.form-label {
  display: block;
  margin-bottom: var(--space-2);
  font-weight: var(--font-medium);
  color: var(--gray-700);
}

.form-input {
  width: 100%;
  padding: var(--space-3);
  border: 1px solid var(--gray-300);
  border-radius: var(--radius-sm);
}
```

### 리스트 레이아웃
```css
.list-container {
  background: white;
  border-radius: var(--radius-lg);
  overflow: hidden;
  box-shadow: var(--shadow-sm);
}

.list-item {
  padding: var(--space-4);
  border-bottom: 1px solid var(--gray-100);
  display: flex;
  align-items: center;
  gap: var(--space-3);
}

.list-item:last-child {
  border-bottom: none;
}

.list-item:hover {
  background: var(--gray-50);
}
```

## 페이지별 레이아웃

### 홈 페이지
```
Desktop                           Mobile
┌─────────────────────────────┐   ┌─────────────────────┐
│ Global │ Recent Activities  │   │ Header              │
│Sidebar │ ┌─────────────────┐ │   ├─────────────────────┤
│        │ │ Group Activity  │ │   │ Recent Activities   │
│        │ ├─────────────────┤ │   │ (Vertical Stack)    │
│        │ │ My Groups       │ │   │                     │
│        │ ├─────────────────┤ │   │                     │
│        │ │ Notifications   │ │   │                     │
│        │ └─────────────────┘ │   ├─────────────────────┤
└─────────────────────────────┘   │ Bottom Nav          │
                                  └─────────────────────┘
```

### 그룹 탐색 페이지
```css
.explore-layout {
  display: grid;
  grid-template-columns: 300px 1fr;
  gap: var(--space-8);
  max-width: 1200px;
  margin: 0 auto;
  padding: var(--space-6);
}

.filter-sidebar {
  background: white;
  padding: var(--space-6);
  border-radius: var(--radius-lg);
  height: fit-content;
  position: sticky;
  top: var(--space-6);
}

.results-area {
  min-height: 600px;
}

/* 모바일에서는 세로 스택 */
@media (max-width: 899px) {
  .explore-layout {
    grid-template-columns: 1fr;
    gap: var(--space-4);
  }

  .filter-sidebar {
    position: static;
  }
}
```

### 프로필 설정 페이지
```css
.profile-setup {
  max-width: 500px;
  margin: 10vh auto;
  padding: var(--space-8);
  background: white;
  border-radius: var(--radius-xl);
  box-shadow: var(--shadow-lg);
}

.step-indicator {
  display: flex;
  justify-content: center;
  margin-bottom: var(--space-8);
  gap: var(--space-2);
}

.step {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--gray-300);
}

.step.active {
  background: var(--primary-500);
}
```

## 스크롤 및 고정 요소

### Sticky Header
```css
.page-header {
  position: sticky;
  top: 0;
  background: white;
  border-bottom: 1px solid var(--gray-200);
  padding: var(--space-4) 0;
  z-index: 50;
}
```

### Floating Action Button
```css
.fab {
  position: fixed;
  bottom: 80px; /* Bottom nav 위에 */
  right: var(--space-6);
  width: 56px;
  height: 56px;
  background: var(--primary-500);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: var(--shadow-lg);
  z-index: 90;
}

@media (min-width: 900px) {
  .fab {
    bottom: var(--space-6); /* 데스크톱에서는 하단 기준 */
  }
}
```

## 로딩 및 에러 상태

### 스켈레톤 로딩
```css
.skeleton {
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: loading 1.5s infinite;
}

@keyframes loading {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}
```

### 빈 상태
```css
.empty-state {
  text-align: center;
  padding: var(--space-16) var(--space-6);
  color: var(--gray-500);
}

.empty-icon {
  width: 64px;
  height: 64px;
  margin: 0 auto var(--space-4);
  opacity: 0.5;
}
```

## 관련 문서

### 디자인 시스템
- **디자인 토큰**: [design-system.md](design-system.md)
- **컴포넌트 가이드**: [component-guide.md](component-guide.md)

### 구현 참조
- **프론트엔드 가이드**: [../implementation/frontend-guide.md](../implementation/frontend-guide.md)

### 개념 참조
- **워크스페이스 구조**: [../concepts/workspace-channel.md](../concepts/workspace-channel.md)