# 컴포넌트 가이드 (Component Guide)

## 기본 컴포넌트

### 버튼 (Button)

#### Primary Button
```jsx
// React 구현 예시
function PrimaryButton({ children, onClick, disabled, loading }) {
  return (
    <button
      className={`btn-primary ${disabled ? 'disabled' : ''} ${loading ? 'loading' : ''}`}
      onClick={onClick}
      disabled={disabled || loading}
    >
      {loading ? <Spinner size="sm" /> : children}
    </button>
  );
}

// Flutter 구현 예시
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;

  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: loading
          ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator())
          : Text(text),
    );
  }
}
```

#### 사용 가이드
- **Primary**: 페이지당 1개, 주요 액션
- **Secondary**: 보조 액션, 취소 버튼
- **Danger**: 삭제, 경고 액션

### 입력 필드 (Input Field)

#### 기본 입력 필드
```jsx
function InputField({
  label,
  value,
  onChange,
  error,
  placeholder,
  type = 'text'
}) {
  return (
    <div className="form-group">
      {label && <label className="form-label">{label}</label>}
      <input
        type={type}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        className={`form-input ${error ? 'error' : ''}`}
      />
      {error && <span className="error-message">{error}</span>}
    </div>
  );
}
```

#### 검색 입력 필드
```jsx
function SearchInput({ value, onChange, placeholder, onClear }) {
  return (
    <div className="search-input-container">
      <SearchIcon className="search-icon" />
      <input
        type="text"
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        className="search-input"
      />
      {value && (
        <button onClick={onClear} className="clear-button">
          <XIcon />
        </button>
      )}
    </div>
  );
}
```

### 카드 (Card)

#### 그룹 카드
```jsx
function GroupCard({ group, onJoin, onView }) {
  return (
    <div className="group-card">
      <div className="card-header">
        <h3 className="group-name">{group.name}</h3>
        <span className="member-count">{group.memberCount}명</span>
      </div>
      <p className="group-description">{group.description}</p>
      <div className="card-footer">
        <div className="group-tags">
          {group.tags?.map(tag => (
            <span key={tag} className="tag">{tag}</span>
          ))}
        </div>
        <div className="card-actions">
          <SecondaryButton onClick={() => onView(group.id)}>
            보기
          </SecondaryButton>
          <PrimaryButton onClick={() => onJoin(group.id)}>
            가입
          </PrimaryButton>
        </div>
      </div>
    </div>
  );
}
```

#### 알림 카드
```jsx
function NotificationCard({ notification, onRead, onAction }) {
  return (
    <div className={`notification-card ${notification.read ? 'read' : 'unread'}`}>
      <div className="notification-icon">
        {getNotificationIcon(notification.type)}
      </div>
      <div className="notification-content">
        <h4 className="notification-title">{notification.title}</h4>
        <p className="notification-message">{notification.message}</p>
        <span className="notification-time">
          {formatTimeAgo(notification.createdAt)}
        </span>
      </div>
      {notification.actionRequired && (
        <div className="notification-actions">
          <SecondaryButton onClick={() => onAction('reject')}>
            거부
          </SecondaryButton>
          <PrimaryButton onClick={() => onAction('approve')}>
            승인
          </PrimaryButton>
        </div>
      )}
    </div>
  );
}
```

## 네비게이션 컴포넌트

### 글로벌 사이드바 (Desktop)
```jsx
function GlobalSidebar({ currentPath }) {
  const navItems = [
    { path: '/home', icon: HomeIcon, label: '홈' },
    { path: '/groups', icon: GroupIcon, label: '내 그룹' },
    { path: '/explore', icon: SearchIcon, label: '탐색' },
    { path: '/profile', icon: UserIcon, label: '프로필' },
  ];

  return (
    <aside className="global-sidebar">
      <div className="sidebar-logo">
        <LogoIcon />
      </div>
      <nav className="sidebar-nav">
        {navItems.map(item => (
          <SidebarItem
            key={item.path}
            {...item}
            active={currentPath === item.path}
          />
        ))}
      </nav>
    </aside>
  );
}

function SidebarItem({ path, icon: Icon, label, active }) {
  return (
    <Link to={path} className={`sidebar-item ${active ? 'active' : ''}`}>
      <Icon className="sidebar-icon" />
      <Tooltip content={label} position="right" />
    </Link>
  );
}
```

### 워크스페이스 사이드바
```jsx
function WorkspaceSidebar({ workspace, channels, currentChannelId }) {
  const [collapsed, setCollapsed] = useState(false);

  return (
    <aside className={`workspace-sidebar ${collapsed ? 'collapsed' : ''}`}>
      <div className="workspace-header">
        <h2 className="workspace-name">{workspace.name}</h2>
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="collapse-button"
        >
          {collapsed ? <ChevronRightIcon /> : <ChevronLeftIcon />}
        </button>
      </div>

      {!collapsed && (
        <nav className="channel-nav">
          {channels.map(channel => (
            <ChannelItem
              key={channel.id}
              channel={channel}
              active={channel.id === currentChannelId}
            />
          ))}
        </nav>
      )}
    </aside>
  );
}
```

## 워크스페이스 컴포넌트

### 메시지/게시글 아이템
```jsx
function MessageItem({ message, currentUserId, onReply, onReact }) {
  const isOwn = message.author.id === currentUserId;

  return (
    <div className={`message-item ${isOwn ? 'own' : ''}`}>
      <div className="message-avatar">
        <Avatar user={message.author} size="sm" />
      </div>
      <div className="message-content">
        <div className="message-header">
          <span className="author-name">{message.author.nickname}</span>
          <span className="message-time">
            {formatTime(message.createdAt)}
          </span>
        </div>
        <div className="message-body">
          {message.content}
        </div>
        <div className="message-actions">
          <MessageReactions reactions={message.reactions} onReact={onReact} />
          <button onClick={() => onReply(message)} className="reply-button">
            답글
          </button>
        </div>
      </div>
    </div>
  );
}
```

### 메시지 입력창
```jsx
function MessageInput({ onSend, placeholder = "메시지 입력..." }) {
  const [content, setContent] = useState('');
  const [uploading, setUploading] = useState(false);

  const handleSend = () => {
    if (!content.trim()) return;
    onSend(content);
    setContent('');
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  return (
    <div className="message-input-container">
      <div className="input-toolbar">
        <FileUploadButton onUpload={handleFileUpload} />
        <EmojiButton onSelect={handleEmojiSelect} />
      </div>
      <div className="input-area">
        <textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          onKeyPress={handleKeyPress}
          placeholder={placeholder}
          className="message-textarea"
        />
        <button
          onClick={handleSend}
          disabled={!content.trim() || uploading}
          className="send-button"
        >
          <SendIcon />
        </button>
      </div>
    </div>
  );
}
```

## 권한 기반 컴포넌트

### 권한 가드
```jsx
function PermissionGuard({
  permission,
  groupId,
  children,
  fallback = null
}) {
  const { hasPermission, loading } = usePermission(groupId, permission);

  if (loading) return <Skeleton />;
  if (!hasPermission) return fallback;

  return children;
}

// 사용 예시
<PermissionGuard permission="MEMBER_KICK" groupId={groupId}>
  <KickMemberButton userId={userId} />
</PermissionGuard>
```

### 역할 배지
```jsx
function RoleBadge({ role, size = 'sm' }) {
  const getVariant = (role) => {
    switch (role) {
      case 'Owner': return 'primary';
      case 'Admin': return 'warning';
      case 'Moderator': return 'info';
      default: return 'secondary';
    }
  };

  return (
    <span className={`role-badge ${getVariant(role)} ${size}`}>
      {role}
    </span>
  );
}
```

## 모달 및 오버레이

### 확인 모달
```jsx
function ConfirmModal({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmText = '확인',
  cancelText = '취소',
  variant = 'default' // 'danger' for destructive actions
}) {
  if (!isOpen) return null;

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <h3 className="modal-title">{title}</h3>
          <button onClick={onClose} className="modal-close">
            <XIcon />
          </button>
        </div>
        <div className="modal-body">
          <p>{message}</p>
        </div>
        <div className="modal-footer">
          <SecondaryButton onClick={onClose}>
            {cancelText}
          </SecondaryButton>
          <PrimaryButton
            onClick={onConfirm}
            variant={variant}
          >
            {confirmText}
          </PrimaryButton>
        </div>
      </div>
    </div>
  );
}
```

### 드롭다운 메뉴
```jsx
function DropdownMenu({ trigger, items, position = 'bottom-right' }) {
  const [isOpen, setIsOpen] = useState(false);
  const menuRef = useRef();

  useClickOutside(menuRef, () => setIsOpen(false));

  return (
    <div className="dropdown" ref={menuRef}>
      <div onClick={() => setIsOpen(!isOpen)}>
        {trigger}
      </div>
      {isOpen && (
        <div className={`dropdown-menu ${position}`}>
          {items.map((item, index) => (
            <button
              key={index}
              onClick={() => {
                item.onClick();
                setIsOpen(false);
              }}
              className={`dropdown-item ${item.variant || ''}`}
            >
              {item.icon && <item.icon className="item-icon" />}
              {item.label}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
```

## 상태 표시 컴포넌트

### 로딩 스피너
```jsx
function LoadingSpinner({ size = 'md', variant = 'primary' }) {
  return (
    <div className={`spinner spinner-${size} spinner-${variant}`}>
      <div className="spinner-circle"></div>
    </div>
  );
}

function SkeletonLoader({ width, height, count = 1 }) {
  return (
    <div className="skeleton-container">
      {Array.from({ length: count }).map((_, i) => (
        <div
          key={i}
          className="skeleton"
          style={{ width, height }}
        />
      ))}
    </div>
  );
}
```

### 토스트 알림
```jsx
function Toast({ message, type = 'info', onClose, autoClose = 5000 }) {
  useEffect(() => {
    if (autoClose) {
      const timer = setTimeout(onClose, autoClose);
      return () => clearTimeout(timer);
    }
  }, [autoClose, onClose]);

  return (
    <div className={`toast toast-${type}`}>
      <div className="toast-icon">
        {getToastIcon(type)}
      </div>
      <span className="toast-message">{message}</span>
      <button onClick={onClose} className="toast-close">
        <XIcon />
      </button>
    </div>
  );
}
```

## 폼 컴포넌트

### 폼 그룹
```jsx
function FormSection({ title, description, children }) {
  return (
    <div className="form-section">
      <div className="section-header">
        <h3 className="section-title">{title}</h3>
        {description && (
          <p className="section-description">{description}</p>
        )}
      </div>
      <div className="section-content">
        {children}
      </div>
    </div>
  );
}

function FormActions({ children, align = 'right' }) {
  return (
    <div className={`form-actions form-actions-${align}`}>
      {children}
    </div>
  );
}
```

### 선택 컴포넌트
```jsx
function Select({ options, value, onChange, placeholder, error }) {
  return (
    <div className="select-container">
      <select
        value={value}
        onChange={onChange}
        className={`select ${error ? 'error' : ''}`}
      >
        {placeholder && (
          <option value="" disabled>{placeholder}</option>
        )}
        {options.map(option => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
      {error && <span className="error-message">{error}</span>}
    </div>
  );
}
```

## 반응형 고려사항

### 모바일 우선 컴포넌트
```jsx
function ResponsiveCard({ children, fullWidthOnMobile = true }) {
  return (
    <div className={`card ${fullWidthOnMobile ? 'mobile-full-width' : ''}`}>
      {children}
    </div>
  );
}

function AdaptiveButton({ children, ...props }) {
  const isMobile = useIsMobile();

  return (
    <button
      {...props}
      className={`btn ${isMobile ? 'btn-mobile' : 'btn-desktop'}`}
    >
      {children}
    </button>
  );
}
```

## 관련 문서

### 디자인 시스템
- **디자인 토큰**: [design-system.md](design-system.md)
- **레이아웃 가이드**: [layout-guide.md](layout-guide.md)

### 구현 참조
- **프론트엔드 가이드**: [../implementation/frontend-guide.md](../implementation/frontend-guide.md)

### 개념 참조
- **권한 시스템**: [../concepts/permission-system.md](../concepts/permission-system.md)
- **워크스페이스 구조**: [../concepts/workspace-channel.md](../concepts/workspace-channel.md)