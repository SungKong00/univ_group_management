-- =====================================================================
-- data.sql: Simplified initialization data
--
-- Only includes users and group basic information.
-- Roles, channels, and channel role bindings are automatically created
-- by GroupInitializationRunner on server startup.
-- =====================================================================

-- 1) Users
INSERT INTO users (id, email, name, password_hash, global_role, profile_completed, created_at, updated_at, is_active,
                   email_verified, nickname, department, student_no)
VALUES (1, 'castlekong1019@gmail.com', 'Castlekong', '', 'STUDENT', true, NOW(), NOW(), true, true, 'castlekong',
        'AI/SW계열', '20250001');

-- 2) Groups - University Level
INSERT INTO groups (id, name, owner_id, university, group_type, is_recruiting, default_channels_created,
                    created_at, updated_at)
VALUES (1, '한신대학교', 1, '한신대학교', 'UNIVERSITY', false, false, NOW(), NOW());

-- 3) Groups - College Level
INSERT INTO groups (id, name, owner_id, parent_id, university, college, group_type, is_recruiting,
                    default_channels_created, created_at, updated_at)
VALUES (2, 'AI/SW계열', 1, 1, '한신대학교', 'AI/SW계열', 'COLLEGE', false, false, NOW(), NOW());

INSERT INTO groups (id, name, owner_id, parent_id, university, college, group_type, is_recruiting,
                    default_channels_created, created_at, updated_at)
VALUES (3, '경영/미디어계열', 1, 1, '한신대학교', '경영/미디어계열', 'COLLEGE', false, false, NOW(), NOW());

-- 4) Groups - Department Level
INSERT INTO groups (id, name, owner_id, parent_id, university, college, department, group_type,
                    is_recruiting, default_channels_created, created_at, updated_at)
VALUES (11, 'AI시스템반도체학과', 1, 2, '한신대학교', 'AI/SW계열', 'AI시스템반도체학과', 'DEPARTMENT', false, false, NOW(), NOW());

INSERT INTO groups (id, name, owner_id, parent_id, university, college, department, group_type,
                    is_recruiting, default_channels_created, created_at, updated_at)
VALUES (12, '미디어영상광고홍보학과', 1, 3, '한신대학교', '경영/미디어계열', '미디어영상광고홍보학과', 'DEPARTMENT', false, false, NOW(),
        NOW());

INSERT INTO groups (id, name, owner_id, parent_id, university, college, department, group_type,
                    is_recruiting, default_channels_created, created_at, updated_at)
VALUES (13, 'AI/SW학과', 1, 2, '한신대학교', 'AI/SW계열', 'AI/SW학과', 'DEPARTMENT', false, false, NOW(), NOW());

-- =====================================================================
-- Automatic Initialization by GroupInitializationRunner:
--
-- For each group with defaultChannelsCreated = false:
--   1. GroupRoleInitializationService creates 3 default roles:
--      - 그룹장: All permissions (priority 100)
--      - 교수: All permissions (priority 99)
--      - 멤버: No group-level permissions (priority 1)
--   1.5. Add group.owner as 그룹장 role member (GroupMember)
--   2. ChannelInitializationService creates 2 default channels:
--      - ANNOUNCEMENT channel (공지사항)
--      - TEXT channel (자유게시판)
--   3. ChannelRoleBinding: All roles bound to all channels
--   4. Group.defaultChannelsCreated = true
-- =====================================================================

-- Note: Test posts removed to avoid foreign key constraint violations.
-- Channels are created by GroupInitializationRunner after data.sql execution.
-- To add test posts, use the REST API or create a separate initialization runner.
