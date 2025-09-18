-- =====================================================================
-- data.sql: 애플리케이션 시작 시 실행되어 초기 데이터를 삽입합니다.
-- 엔티티 스키마(JPA)와 컬럼명을 정확히 맞추도록 수정됨
-- =====================================================================

-- 1) 사용자 (Users)
INSERT INTO users (id, email, name, password_hash, global_role, profile_completed, created_at, updated_at, is_active, email_verified, nickname, department, student_no)
VALUES (1, 'castlekong1019@gmail.com', 'Castlekong', '', 'STUDENT', true, NOW(), NOW(), true, true, 'castlekong', 'AI/SW계열', '20250001');

-- 2) 최상위 그룹: 대학교 (University)
INSERT INTO groups (id, name, owner_id, university, group_type, visibility, is_recruiting, default_channels_created, created_at, updated_at)
VALUES (1, '한신대학교', 1, '한신대학교', 'UNIVERSITY', 'PUBLIC', false, false, NOW(), NOW());

-- 3) 단과대학/계열 (College Level)
INSERT INTO groups (id, name, owner_id, parent_id, university, college, group_type, visibility, is_recruiting, default_channels_created, created_at, updated_at)
VALUES (2, 'AI/SW계열', 1, 1, '한신대학교', 'AI/SW계열', 'COLLEGE', 'PUBLIC', false, false, NOW(), NOW());

INSERT INTO groups (id, name, owner_id, parent_id, university, college, group_type, visibility, is_recruiting, default_channels_created, created_at, updated_at)
VALUES (3, '경영/미디어계열', 1, 1, '한신대학교', '경영/미디어계열', 'COLLEGE', 'PUBLIC', false, false, NOW(), NOW());

-- 4) 학과 (Department)
INSERT INTO groups (id, name, owner_id, parent_id, university, college, department, group_type, visibility, is_recruiting, default_channels_created, created_at, updated_at)
VALUES (11, 'AI시스템반도체학과', 1, 2, '한신대학교', 'AI/SW계열', 'AI시스템반도체학과', 'DEPARTMENT', 'PUBLIC', false, false, NOW(), NOW());

INSERT INTO groups (id, name, owner_id, parent_id, university, college, department, group_type, visibility, is_recruiting, default_channels_created, created_at, updated_at)
VALUES (12, '미디어영상광고홍보학과', 1, 3, '한신대학교', '경영/미디어계열', '미디어영상광고홍보학과', 'DEPARTMENT', 'PUBLIC', false, false, NOW(), NOW());

INSERT INTO groups (id, name, owner_id, parent_id, university, college, department, group_type, visibility, is_recruiting, default_channels_created, created_at, updated_at)
VALUES (13, 'AI/SW학과', 1, 2, '한신대학교', 'AI/SW계열', 'AI/SW학과', 'DEPARTMENT', 'PUBLIC', false, false, NOW(), NOW());

-- 5) 기본 역할 (GroupRole) - 각 그룹별로 OWNER, ADVISOR, MEMBER 역할 생성
-- GroupRole 엔티티 스키마: id, group_id, name, is_system_role, role_type, priority
-- 그룹 1 (한신대학교)
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (1, 1, 'OWNER', true, 'OPERATIONAL', 100);
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (2, 1, 'ADVISOR', true, 'OPERATIONAL', 99);
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (3, 1, 'MEMBER', true, 'OPERATIONAL', 1);

-- 그룹 2 (AI/SW계열)
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (4, 2, 'OWNER', true, 'OPERATIONAL', 100);
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (5, 2, 'ADVISOR', true, 'OPERATIONAL', 99);
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (6, 2, 'MEMBER', true, 'OPERATIONAL', 1);

-- 그룹 3 (경영/미디어계열)
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (7, 3, 'OWNER', true, 'OPERATIONAL', 100);
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (8, 3, 'ADVISOR', true, 'OPERATIONAL', 99);
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (9, 3, 'MEMBER', true, 'OPERATIONAL', 1);

-- 그룹 11 (AI시스템반도체학과)
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (10, 11, 'OWNER', true, 'OPERATIONAL', 100);
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (11, 11, 'ADVISOR', true, 'OPERATIONAL', 99);
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (12, 11, 'MEMBER', true, 'OPERATIONAL', 1);

-- 그룹 12 (미디어영상광고홍보학과)
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (13, 12, 'OWNER', true, 'OPERATIONAL', 100);
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (14, 12, 'ADVISOR', true, 'OPERATIONAL', 99);
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (15, 12, 'MEMBER', true, 'OPERATIONAL', 1);

-- 그룹 13 (AI/SW학과)
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (16, 13, 'OWNER', true, 'OPERATIONAL', 100);
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (17, 13, 'ADVISOR', true, 'OPERATIONAL', 99);
INSERT INTO group_roles (id, group_id, name, is_system_role, role_type, priority)
VALUES (18, 13, 'MEMBER', true, 'OPERATIONAL', 1);

-- 6) 그룹 멤버십 (GroupMember) - 그룹 소유자를 OWNER 역할로 추가
-- GroupMember 엔티티 스키마: id, group_id, user_id, role_id, joined_at
INSERT INTO group_members (id, group_id, user_id, role_id, joined_at)
VALUES (1, 1, 1, 1, NOW());
INSERT INTO group_members (id, group_id, user_id, role_id, joined_at)
VALUES (2, 2, 1, 4, NOW());
INSERT INTO group_members (id, group_id, user_id, role_id, joined_at)
VALUES (3, 3, 1, 7, NOW());
INSERT INTO group_members (id, group_id, user_id, role_id, joined_at)
VALUES (4, 11, 1, 10, NOW());
INSERT INTO group_members (id, group_id, user_id, role_id, joined_at)
VALUES (5, 12, 1, 13, NOW());
INSERT INTO group_members (id, group_id, user_id, role_id, joined_at)
VALUES (6, 13, 1, 16, NOW());

-- 7) 기본 채널 (Channel) - 각 그룹별로 공지사항, 자유게시판 채널 생성
-- Channel 엔티티 스키마: id, group_id, workspace_id?, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at
-- 그룹 1 (한신대학교)
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (1, 1, '공지사항', '그룹 공지사항 채널', 'ANNOUNCEMENT', false, false, 0, 1, NOW(), NOW());
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (2, 1, '자유게시판', '자유롭게 대화하는 채널', 'TEXT', false, false, 1, 1, NOW(), NOW());

-- 그룹 2 (AI/SW계열)
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (3, 2, '공지사항', '그룹 공지사항 채널', 'ANNOUNCEMENT', false, false, 0, 1, NOW(), NOW());
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (4, 2, '자유게시판', '자유롭게 대화하는 채널', 'TEXT', false, false, 1, 1, NOW(), NOW());

-- 그룹 3 (경영/미디어계열)
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (5, 3, '공지사항', '그룹 공지사항 채널', 'ANNOUNCEMENT', false, false, 0, 1, NOW(), NOW());
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (6, 3, '자유게시판', '자유롭게 대화하는 채널', 'TEXT', false, false, 1, 1, NOW(), NOW());

-- 그룹 11 (AI시스템반도체학과)
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (7, 11, '공지사항', '그룹 공지사항 채널', 'ANNOUNCEMENT', false, false, 0, 1, NOW(), NOW());
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (8, 11, '자유게시판', '자유롭게 대화하는 채널', 'TEXT', false, false, 1, 1, NOW(), NOW());

-- 그룹 12 (미디어영상광고홍보학과)
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (9, 12, '공지사항', '그룹 공지사항 채널', 'ANNOUNCEMENT', false, false, 0, 1, NOW(), NOW());
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (10, 12, '자유게시판', '자유롭게 대화하는 채널', 'TEXT', false, false, 1, 1, NOW(), NOW());

-- 그룹 13 (AI/SW학과)
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (11, 13, '공지사항', '그룹 공지사항 채널', 'ANNOUNCEMENT', false, false, 0, 1, NOW(), NOW());
INSERT INTO channels (id, group_id, name, description, type, is_private, is_public, display_order, created_by, created_at, updated_at)
VALUES (12, 13, '자유게시판', '자유롭게 대화하는 채널', 'TEXT', false, false, 1, 1, NOW(), NOW());

-- 8) 채널 권한 바인딩 (ChannelRoleBinding)
-- ChannelRoleBinding 엔티티 스키마: id, channel_id, group_role_id, created_at, updated_at (+ 별도 permissions 컬렉션 테이블)
-- 메인 바인딩 행 삽입
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (1, 1, 1, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (2, 1, 3, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (3, 2, 1, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (4, 2, 3, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (5, 3, 4, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (6, 3, 6, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (7, 4, 4, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (8, 4, 6, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (9, 5, 7, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (10, 5, 9, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (11, 6, 7, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (12, 6, 9, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (13, 7, 10, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (14, 7, 12, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (15, 8, 10, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (16, 8, 12, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (17, 9, 13, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (18, 9, 15, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (19, 10, 13, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (20, 10, 15, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (21, 11, 16, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (22, 11, 18, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (23, 12, 16, NOW(), NOW());
INSERT INTO channel_role_bindings (id, channel_id, group_role_id, created_at, updated_at) VALUES (24, 12, 18, NOW(), NOW());

-- 채널 권한 컬렉션 테이블에 권한 삽입
-- OWNER: CHANNEL_VIEW, POST_READ, POST_WRITE, COMMENT_WRITE, FILE_UPLOAD
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (1, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (1, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (1, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (1, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (1, 'FILE_UPLOAD');
-- MEMBER on announcement: CHANNEL_VIEW, POST_READ, COMMENT_WRITE
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (2, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (2, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (2, 'COMMENT_WRITE');
-- OWNER on free board: full
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (3, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (3, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (3, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (3, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (3, 'FILE_UPLOAD');
-- MEMBER on free board: no upload
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (4, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (4, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (4, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (4, 'COMMENT_WRITE');

-- 동일 패턴 반복 (그룹 2, 3, 11, 12, 13)
-- 그룹 2
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (5, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (5, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (5, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (5, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (5, 'FILE_UPLOAD');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (6, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (6, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (6, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (7, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (7, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (7, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (7, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (7, 'FILE_UPLOAD');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (8, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (8, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (8, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (8, 'COMMENT_WRITE');

-- 그룹 3
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (9, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (9, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (9, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (9, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (9, 'FILE_UPLOAD');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (10, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (10, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (10, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (11, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (11, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (11, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (11, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (11, 'FILE_UPLOAD');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (12, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (12, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (12, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (12, 'COMMENT_WRITE');

-- 그룹 11
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (13, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (13, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (13, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (13, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (13, 'FILE_UPLOAD');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (14, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (14, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (14, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (15, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (15, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (15, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (15, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (15, 'FILE_UPLOAD');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (16, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (16, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (16, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (16, 'COMMENT_WRITE');

-- 그룹 12
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (17, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (17, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (17, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (17, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (17, 'FILE_UPLOAD');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (18, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (18, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (18, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (19, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (19, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (19, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (19, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (19, 'FILE_UPLOAD');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (20, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (20, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (20, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (20, 'COMMENT_WRITE');

-- 그룹 13
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (21, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (21, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (21, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (21, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (21, 'FILE_UPLOAD');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (22, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (22, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (22, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (23, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (23, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (23, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (23, 'COMMENT_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (23, 'FILE_UPLOAD');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (24, 'CHANNEL_VIEW');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (24, 'POST_READ');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (24, 'POST_WRITE');
INSERT INTO channel_role_binding_permissions (binding_id, permission) VALUES (24, 'COMMENT_WRITE');

-- 9) 그룹의 default_channels_created 플래그 업데이트
UPDATE groups SET default_channels_created = true WHERE id IN (1, 2, 3, 11, 12, 13);

-- 10) H2 IDENTITY 시퀀스 재시작 (명시적 ID 삽입 후 자동 증가 키 충돌 방지)
ALTER TABLE users ALTER COLUMN id RESTART WITH 2;
ALTER TABLE groups ALTER COLUMN id RESTART WITH 14;
ALTER TABLE group_roles ALTER COLUMN id RESTART WITH 19;
ALTER TABLE group_members ALTER COLUMN id RESTART WITH 7;
ALTER TABLE channels ALTER COLUMN id RESTART WITH 13;
ALTER TABLE channel_role_bindings ALTER COLUMN id RESTART WITH 25;
