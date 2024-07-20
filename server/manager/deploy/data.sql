

DROP TABLE IF EXISTS `casbin_rule`;
CREATE TABLE `casbin_rule` (
                               `id` bigint(20) UNSIGNED NOT NULL,
                               `ptype` varchar(100) DEFAULT NULL,
                               `v0` varchar(100) DEFAULT NULL,
                               `v1` varchar(100) DEFAULT NULL,
                               `v2` varchar(100) DEFAULT NULL,
                               `v3` varchar(100) DEFAULT NULL,
                               `v4` varchar(100) DEFAULT NULL,
                               `v5` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- 表的结构 `department`
--

DROP TABLE IF EXISTS `department`;
CREATE TABLE `department` (
                              `id` bigint(20) UNSIGNED NOT NULL COMMENT '主键ID',
                              `parent_id` bigint(20) UNSIGNED NOT NULL COMMENT '父id',
                              `keyword` char(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '标识',
                              `name` varchar(64) NOT NULL COMMENT '名称',
                              `description` varchar(256) NOT NULL COMMENT '描述',
                              `created_at` bigint(20) UNSIGNED NOT NULL DEFAULT '0' COMMENT '创建时间',
                              `updated_at` bigint(20) UNSIGNED NOT NULL DEFAULT '0' COMMENT '修改时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='部门信息';

--
-- 转存表中的数据 `department`
--

INSERT INTO `department` (`id`, `parent_id`, `keyword`, `name`, `description`, `created_at`, `updated_at`) VALUES
    (1, 0, 'company', '贵州青橙科技有限公司', '开放合作，拥抱未来', 1713706137, 1713706137);

-- --------------------------------------------------------

--
-- 表的结构 `department_closure`
--

DROP TABLE IF EXISTS `department_closure`;
CREATE TABLE `department_closure` (
                                      `id` bigint(20) UNSIGNED NOT NULL COMMENT '主键ID',
                                      `parent` bigint(20) UNSIGNED NOT NULL COMMENT '部门id',
                                      `children` bigint(20) UNSIGNED NOT NULL COMMENT '部门id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='部门层级信息';

-- --------------------------------------------------------

--
-- 表的结构 `dictionary`
--

DROP TABLE IF EXISTS `dictionary`;
CREATE TABLE `dictionary` (
                              `id` bigint(20) UNSIGNED NOT NULL COMMENT '主键ID',
                              `keyword` char(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '关键字',
                              `name` varchar(64) NOT NULL COMMENT '名称',
                              `description` varchar(256) DEFAULT NULL COMMENT '描述',
                              `created_at` bigint(20) UNSIGNED NOT NULL DEFAULT '0' COMMENT '创建时间',
                              `updated_at` bigint(20) UNSIGNED NOT NULL DEFAULT '0' COMMENT '修改时间',
                              `deleted_at` bigint(20) UNSIGNED NOT NULL DEFAULT '0' COMMENT '删除时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='字典信息';

-- --------------------------------------------------------

--
-- 表的结构 `dictionary_value`
--

DROP TABLE IF EXISTS `dictionary_value`;
CREATE TABLE `dictionary_value` (
                                    `id` bigint(20) UNSIGNED NOT NULL COMMENT '主键ID',
                                    `dictionary_id` bigint(20) UNSIGNED NOT NULL COMMENT '字典id',
                                    `label` varchar(128) NOT NULL COMMENT '标签',
                                    `value` varchar(128) NOT NULL COMMENT '标识',
                                    `status` tinyint(1) DEFAULT '1' COMMENT '状态',
                                    `weight` int(10) UNSIGNED DEFAULT '0' COMMENT '权重',
                                    `type` char(32) DEFAULT NULL COMMENT '类型',
                                    `extra` varchar(512) DEFAULT NULL COMMENT '扩展信息',
                                    `description` varchar(256) DEFAULT NULL COMMENT '描述',
                                    `created_at` bigint(20) UNSIGNED NOT NULL DEFAULT '0' COMMENT '创建时间',
                                    `updated_at` bigint(20) UNSIGNED NOT NULL DEFAULT '0' COMMENT '修改时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='字典值信息';

-- --------------------------------------------------------

--
-- 表的结构 `gorm_init`
--

DROP TABLE IF EXISTS `gorm_init`;
CREATE TABLE `gorm_init` (
                             `id` int(10) UNSIGNED NOT NULL,
                             `init` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- 转存表中的数据 `gorm_init`
--

INSERT INTO `gorm_init` (`id`, `init`) VALUES
    (1, 1);

-- --------------------------------------------------------

--
-- 表的结构 `job`
--

DROP TABLE IF EXISTS `job`;
CREATE TABLE `job` (
                       `id` bigint(20) UNSIGNED NOT NULL COMMENT '主键ID',
                       `keyword` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '关键字',
                       `name` varchar(64) NOT NULL COMMENT '名称',
                       `weight` int(10) UNSIGNED DEFAULT NULL COMMENT '权重',
                       `description` varchar(256) NOT NULL COMMENT '描述',
                       `created_at` bigint(20) UNSIGNED NOT NULL DEFAULT '0' COMMENT '创建时间',
                       `updated_at` bigint(20) UNSIGNED NOT NULL DEFAULT '0' COMMENT '修改时间',
                       `deleted_at` bigint(20) UNSIGNED NOT NULL DEFAULT '0' COMMENT '删除时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='职位信息';

--
-- 转存表中的数据 `job`
--

INSERT INTO `job` (`id`, `keyword`, `name`, `weight`, `description`, `created_at`, `updated_at`, `deleted_at`) VALUES
    (1, 'chairman', '董事长', 0, '董事长', 1713706137, 1717211765, 0);

-- --------------------------------------------------------

--
-- 表的结构 `menu`
--

DROP TABLE IF EXISTS `menu`;
CREATE TABLE `menu` (
                        `id` bigint(20) UNSIGNED NOT NULL COMMENT '主键ID',
                        `parent_id` bigint(20) UNSIGNED NOT NULL COMMENT '父id',
                        `title` varchar(128) NOT NULL COMMENT '标题',
                        `type` char(32) NOT NULL COMMENT '类型',
                        `keyword` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT '关键词',
                        `icon` char(32) DEFAULT NULL COMMENT '图标',
                        `api` varchar(128) DEFAULT NULL COMMENT '接口',
                        `method` varchar(12) DEFAULT NULL COMMENT '接口方法',
                        `path` varchar(128) DEFAULT NULL COMMENT '路径',
                        `permission` varchar(128) DEFAULT NULL COMMENT '指令',
                        `component` varchar(128) DEFAULT NULL COMMENT '组件',
                        `redirect` varchar(128) DEFAULT NULL COMMENT '重定向地址',
                        `weight` int(10) UNSIGNED DEFAULT '0' COMMENT '权重',
                        `is_hidden` tinyint(1) DEFAULT NULL COMMENT '是否隐藏',
                        `is_cache` tinyint(1) DEFAULT NULL COMMENT '是否缓存',
                        `is_home` tinyint(1) DEFAULT NULL COMMENT '是否为首页',
                        `is_affix` tinyint(1) DEFAULT NULL COMMENT '是否为标签',
                        `created_at` bigint(20) UNSIGNED NOT NULL DEFAULT '0' COMMENT '创建时间',
                        `updated_at` bigint(20) UNSIGNED NOT NULL DEFAULT '0' COMMENT '修改时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='菜单信息';

--
-- 转存表中的数据 `menu`
--

INSERT INTO `menu` (`id`, `parent_id`, `title`, `type`, `keyword`, `icon`, `api`, `method`, `path`, `permission`, `component`, `redirect`, `weight`, `is_hidden`, `is_cache`, `is_home`, `is_affix`, `created_at`, `updated_at`) VALUES
                                                                                                                                                                                                                                     (2427, 0, '管理平台', 'R', 'SystemPlatform', 'apps', NULL, NULL, '/', NULL, 'Layout', NULL, 2, 0, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2428, 2427, '首页面板', 'M', 'Dashboard', 'dashboard', NULL, NULL, '/dashboard', NULL, '/dashboard/index', NULL, 0, 0, 1, 1, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2429, 2427, '管理中心', 'M', 'SystemPlatformManager', 'apps', NULL, NULL, '/manager', NULL, NULL, NULL, 0, 0, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2430, 2429, '基础接口', 'G', 'ManagerBaseApi', 'apps', NULL, NULL, NULL, NULL, NULL, NULL, 0, 1, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2431, 2430, '获取用户可见部门树', 'BA', NULL, NULL, '/manager/api/v1/departments', 'GET', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2432, 2430, '获取用户可见角色树', 'BA', NULL, NULL, '/manager/api/v1/roles', 'GET', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2433, 2430, '获取个人用户信息', 'BA', NULL, NULL, '/manager/api/v1/user/current', 'GET', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2434, 2430, '更新个人用户信息', 'BA', NULL, NULL, '/manager/api/v1/user/current/info', 'PUT', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2435, 2430, '更新个人用户密码', 'BA', NULL, NULL, '/manager/api/v1/user/current/password', 'PUT', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2436, 2430, '保存个人用户设置', 'BA', NULL, NULL, '/manager/api/v1/user/current/setting', 'PUT', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2437, 2430, '发送用户验证吗', 'BA', NULL, NULL, '/manager/api/v1/user/current/captcha', 'POST', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2438, 2430, '获取用户当前角色菜单', 'BA', NULL, NULL, '/manager/api/v1/menus/by/cur_role', 'GET', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2439, 2430, '退出登录', 'BA', NULL, NULL, '/manager/api/v1/user/logout', 'POST', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2440, 2430, '刷新token', 'BA', NULL, NULL, '/manager/api/v1/user/token/refresh', 'POST', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2441, 2430, '用户登录', 'BA', NULL, NULL, '/manager/api/v1/user/login', 'POST', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2442, 2430, '获取登录验证码', 'BA', NULL, NULL, '/manager/api/v1/user/login/captcha', 'POST', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2443, 2430, '获取系统基础设置', 'BA', NULL, NULL, '/manager/api/v1/system/setting', 'GET', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2444, 2430, '接口鉴权', 'BA', NULL, NULL, '/manager/api/v1/auth', 'POST', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2445, 2430, '切换用户角色', 'BA', NULL, NULL, '/manager/api/v1/user/current/role', 'POST', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2446, 2430, '分块上传文件', 'BA', NULL, NULL, '/resource/api/v1/upload', 'POST', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2447, 2430, '预上传文件', 'BA', NULL, NULL, '/resource/api/v1/prepare_upload', 'POST', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2448, 2430, '获取字段类型', 'BA', NULL, NULL, '/usercenter/api/v1/field/types', 'GET', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2449, 2429, '字典管理', 'M', 'ManagerDictionary', 'storage', NULL, NULL, '/manager/dictionary', NULL, '/manager/dictionary/index', NULL, 0, NULL, 1, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2450, 2449, '查询字典', 'A', NULL, NULL, '/manager/api/v1/dictionaries', 'GET', NULL, 'manager:dictionary:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2451, 2449, '新增字典', 'A', NULL, NULL, '/manager/api/v1/dictionary', 'POST', NULL, 'manager:dictionary:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2452, 2449, '修改字典', 'A', NULL, NULL, '/manager/api/v1/dictionary', 'PUT', NULL, 'manager:dictionary:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2453, 2449, '删除字典', 'A', NULL, NULL, '/manager/api/v1/dictionary', 'DELETE', NULL, 'manager:dictionary:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2454, 2449, '获取字典值', 'A', NULL, NULL, '/manager/api/v1/dictionary_values', 'GET', NULL, 'manager:dictionary:value:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2455, 2449, '新增字典值', 'A', NULL, NULL, '/manager/api/v1/dictionary_value', 'POST', NULL, 'manager:dictionary:value:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2456, 2449, '修改字典值', 'A', NULL, NULL, '/manager/api/v1/dictionary_value', 'PUT', NULL, 'manager:dictionary:value:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2457, 2449, '更新字典值目录状态', 'A', NULL, NULL, '/manager/api/v1/dictionary_value/status', 'PUT', NULL, 'manager:dictionary:value:status', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2458, 2449, '删除字典值', 'A', NULL, NULL, '/manager/api/v1/dictionary_value', 'DELETE', NULL, 'manager:dictionary:value:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2459, 2429, '菜单管理', 'M', 'ManagerMenu', 'menu', NULL, NULL, '/manager/menu', NULL, '/manager/menu/index', NULL, 0, 0, 1, 1, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2460, 2459, '查询菜单', 'A', NULL, NULL, '/manager/api/v1/menus', 'GET', NULL, 'manager:menu:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2461, 2459, '新增菜单', 'A', NULL, NULL, '/manager/api/v1/menu', 'POST', NULL, 'manager:menu:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2462, 2459, '修改菜单', 'A', NULL, NULL, '/manager/api/v1/menu', 'PUT', NULL, 'manager:menu:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2463, 2459, '删除菜单', 'A', NULL, NULL, '/manager/api/v1/menu', 'DELETE', NULL, 'manager:menu:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2464, 2429, '职位管理', 'M', 'ManagerJob', 'tag', NULL, NULL, '/manager/job', NULL, '/manager/job/index', NULL, 0, NULL, 1, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2465, 2464, '查询职位', 'A', NULL, NULL, '/manager/api/v1/jobs', 'GET', NULL, 'manager:job:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2466, 2464, '新增职位', 'A', NULL, NULL, '/manager/api/v1/job', 'POST', NULL, 'manager:job:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2467, 2464, '修改职位', 'A', NULL, NULL, '/manager/api/v1/job', 'PUT', NULL, 'manager:job:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2468, 2464, '删除职位', 'A', NULL, NULL, '/manager/api/v1/job', 'DELETE', NULL, 'manager:job:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2469, 2429, '部门管理', 'M', 'ManagerDepartment', 'user-group', NULL, NULL, '/manager/department', NULL, '/manager/department/index', NULL, 0, 0, 1, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2470, 2469, '新增部门', 'A', NULL, NULL, '/manager/api/v1/department', 'POST', NULL, 'manager:department:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2471, 2469, '修改部门', 'A', NULL, NULL, '/manager/api/v1/department', 'PUT', NULL, 'manager:department:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2472, 2469, '删除部门', 'A', NULL, NULL, '/manager/api/v1/department', 'DELETE', NULL, 'manager:department:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2473, 2429, '角色管理', 'M', 'ManagerRole', 'safe', NULL, NULL, '/manager/role', NULL, '/manager/role/index', NULL, 0, NULL, 0, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2474, 2473, '新增角色', 'A', NULL, NULL, '/manager/api/v1/role', 'POST', NULL, 'manager:role:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2475, 2473, '修改角色', 'A', NULL, NULL, '/manager/api/v1/role', 'PUT', NULL, 'manager:role:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2476, 2473, '修改角色状态', 'A', NULL, NULL, '/manager/api/v1/role/status', 'PUT', NULL, 'manager:role:update:status', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2477, 2473, '删除角色', 'A', NULL, NULL, '/manager/api/v1/role', 'DELETE', NULL, 'manager:role:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2478, 2473, '角色菜单管理', 'G', NULL, NULL, NULL, NULL, NULL, 'manager:role:menu', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2479, 2478, '查询角色菜单', 'A', NULL, NULL, '/manager/api/v1/role/menu_ids', 'GET', NULL, 'manager:role:menu:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2480, 2478, '修改角色菜单', 'A', NULL, NULL, '/manager/api/v1/role/menu', 'POST', NULL, 'manager:role:menu:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2481, 2429, '用户管理', 'M', 'ManagerUser', 'user', NULL, NULL, '/manager/user', NULL, '/manager/user/index', NULL, 0, NULL, 1, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2482, 2481, '查询用户列表', 'A', NULL, NULL, '/manager/api/v1/users', 'GET', NULL, 'manager:user:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2483, 2481, '新增用户', 'A', NULL, NULL, '/manager/api/v1/user', 'POST', NULL, 'manager:user:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2484, 2481, '修改用户', 'A', NULL, NULL, '/manager/api/v1/user', 'PUT', NULL, 'manager:user:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2485, 2481, '删除用户', 'A', NULL, NULL, '/manager/api/v1/user', 'DELETE', NULL, 'manager:user:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2486, 2481, '修改用户状态', 'A', NULL, NULL, '/manager/api/v1/user/status', 'PUT', NULL, 'manager:user:status', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2487, 2481, '重置账号密码', 'A', NULL, NULL, '/manager/api/v1/user/password/reset', 'POST', NULL, 'manager:user:reset:password', '', NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2488, 2427, '资源中心', 'M', 'SystemPlatformResource', 'file', NULL, NULL, '/resource', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2489, 2488, '文件管理', 'M', 'ResourceFile', 'file', NULL, NULL, '/resource/file', NULL, '/resource/file/index', NULL, 0, 0, 1, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2490, 2489, '目录管理', 'G', NULL, NULL, NULL, NULL, NULL, 'resource:directory:group', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2491, 2490, '查看目录', 'A', NULL, NULL, '/resource/api/v1/directories', 'GET', NULL, 'resource:directory:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2492, 2490, '新增目录', 'A', NULL, NULL, '/resource/api/v1/directory', 'POST', NULL, 'resource:directory:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2493, 2490, '修改目录', 'A', NULL, NULL, '/resource/api/v1/directory', 'PUT', NULL, 'resource:directory:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2494, 2490, '删除目录', 'A', NULL, NULL, '/resource/api/v1/directory', 'DELETE', NULL, 'resource:directory:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2495, 2489, '文件管理', 'G', NULL, NULL, NULL, NULL, NULL, 'resource:file:group', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2496, 2495, '查看文件', 'A', NULL, NULL, '/resource/api/v1/files', 'GET', NULL, 'resource:file:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2497, 2495, '修改文件', 'A', NULL, NULL, '/resource/api/v1/file', 'PUT', NULL, 'resource:file:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2498, 2495, '删除文件', 'A', NULL, NULL, '/resource/api/v1/file', 'DELETE', NULL, 'resource:file:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2499, 2488, '导出管理', 'M', 'ResourceExport', 'export', NULL, NULL, '/resource/export', NULL, '/resource/export/index', NULL, 0, 0, 1, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2500, 2499, '查看导出', 'A', NULL, NULL, '/resource/api/v1/exports', 'GET', NULL, 'resource:export:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2501, 2499, '新增导出', 'A', NULL, NULL, '/resource/api/v1/export', 'POST', NULL, 'resource:export:file', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2502, 2499, '删除导出', 'A', NULL, NULL, '/resource/api/v1/export', 'DELETE', NULL, 'resource:export:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2503, 2427, '用户中心', 'M', 'SystemPlatformUserCenter', 'user', NULL, NULL, '/usercenter', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2504, 2503, '授权渠道', 'M', 'UserCenterChannel', 'mind-mapping', NULL, NULL, '/usercenter/channel', NULL, '/usercenter/channel/index', NULL, 0, 0, 1, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2505, 2504, '查看渠道', 'A', NULL, NULL, '/usercenter/api/v1/channels', 'GET', NULL, 'uc:channel:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2506, 2504, '新增渠道', 'A', NULL, NULL, '/usercenter/api/v1/channel', 'POST', NULL, 'uc:channel:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2507, 2504, '修改渠道', 'A', NULL, NULL, '/usercenter/api/v1/channel', 'PUT', NULL, 'uc:channel:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2508, 2504, '修改渠道状态', 'A', NULL, NULL, '/usercenter/api/v1/channel/status', 'PUT', NULL, 'uc:channel:update:status', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2509, 2504, '删除渠道', 'A', NULL, NULL, '/usercenter/api/v1/channel', 'DELETE', NULL, 'uc:channel:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2510, 2503, '信息字段', 'M', 'UserCenterField', 'list', NULL, NULL, '/usercenter/field', NULL, '/usercenter/field/index', NULL, 0, 0, 1, 0, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2511, 2510, '查看字段列表', 'A', NULL, NULL, '/usercenter/api/v1/fields', 'GET', NULL, 'uc:field:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2512, 2510, '新增字段', 'A', NULL, NULL, '/usercenter/api/v1/field', 'POST', NULL, 'uc:field:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2513, 2510, '修改字段', 'A', NULL, NULL, '/usercenter/api/v1/field', 'PUT', NULL, 'uc:field:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2514, 2510, '修改字段状态', 'A', NULL, NULL, '/usercenter/api/v1/field/status', 'PUT', NULL, 'uc:field:update:status', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2515, 2510, '删除字段', 'A', NULL, NULL, '/usercenter/api/v1/field', 'DELETE', NULL, 'uc:field:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2516, 2503, '应用管理', 'M', 'UserCenterApp', 'apps', NULL, NULL, '/usercenter/app', NULL, '/usercenter/app/index', NULL, 0, 0, 1, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2517, 2516, '查看应用', 'A', NULL, NULL, '/usercenter/api/v1/apps', 'GET', NULL, 'uc:app:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2518, 2516, '新增应用', 'A', NULL, NULL, '/usercenter/api/v1/app', 'POST', NULL, 'uc:app:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2519, 2516, '修改应用', 'A', NULL, NULL, '/usercenter/api/v1/app', 'PUT', NULL, 'uc:app:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2520, 2516, '修改应用状态', 'A', NULL, NULL, '/usercenter/api/v1/app/status', 'PUT', NULL, 'uc:app:update:status', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2521, 2516, '删除应用', 'A', NULL, NULL, '/usercenter/api/v1/app', 'DELETE', NULL, 'uc:app:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2522, 2503, '用户管理', 'M', 'UserCenterUser', 'user', NULL, NULL, '/usercenter/user', NULL, '/usercenter/user/index', NULL, 0, 0, 1, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2523, 2522, '查看用户', 'A', NULL, NULL, '/usercenter/api/v1/users', 'GET', NULL, 'uc:user:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2524, 2522, '新增用户', 'A', NULL, NULL, '/usercenter/api/v1/user', 'POST', NULL, 'uc:user:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2525, 2522, '导入用户', 'A', NULL, NULL, '/usercenter/api/v1/users', 'POST', NULL, 'uc:user:import', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2526, 2522, '修改用户', 'A', NULL, NULL, '/usercenter/api/v1/user', 'PUT', NULL, 'uc:user:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2527, 2522, '修改用户状态', 'A', NULL, NULL, '/usercenter/api/v1/user/status', 'PUT', NULL, 'uc:user:update:status', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2528, 2522, '删除用户', 'A', NULL, NULL, '/usercenter/api/v1/user', 'DELETE', NULL, 'uc:user:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2529, 2522, '查看用户详细信息', 'G', NULL, NULL, NULL, NULL, NULL, 'uc:user:more', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2530, 2529, '获取用户应用信息', 'A', NULL, NULL, '/usercenter/api/v1/auths', 'GET', NULL, 'uc:auth:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2531, 2529, '创建用户应用信息', 'A', NULL, NULL, '/usercenter/api/v1/auth', 'POST', NULL, 'uc:auth:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2532, 2529, '修改用户应用状态信息', 'A', NULL, NULL, '/usercenter/api/v1/auth/status', 'PUT', NULL, 'uc:auth:update:status', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2533, 2529, '删除用户应用信息', 'A', NULL, NULL, '/usercenter/api/v1/auth', 'DELETE', NULL, 'uc:auth:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2534, 2529, '获取用户渠道信息', 'A', NULL, NULL, '/usercenter/api/v1/oauths', 'GET', NULL, 'uc:oauth:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2535, 2529, '删除用户渠道信息', 'A', NULL, NULL, '/usercenter/api/v1/oauth', 'DELETE', NULL, 'uc:oauth:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2536, 2529, '获取用户扩展信息', 'A', NULL, NULL, '/usercenter/api/v1/userinfos', 'GET', NULL, 'uc:userinfo:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2537, 2529, '创建用户扩展信息', 'A', NULL, NULL, '/usercenter/api/v1/userinfo', 'POST', NULL, 'uc:userinfo:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2538, 2529, '修改用户扩展信息', 'A', NULL, NULL, '/usercenter/api/v1/userinfo', 'PUT', NULL, 'uc:userinfo:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2539, 2529, '删除用户扩展信息', 'A', NULL, NULL, '/usercenter/api/v1/userinfo', 'DELETE', NULL, 'uc:userinfo:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2540, 2427, '配置中心', 'M', 'SystemPlatformConfigure', 'code-block', NULL, NULL, '/configure', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2541, 2540, '环境管理', 'M', 'ConfigureEnv', 'common', NULL, NULL, '/configure/env', NULL, '/configure/env/index', NULL, 0, NULL, 1, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2542, 2541, '查看环境', 'A', NULL, NULL, '/configure/api/v1/envs', 'GET', NULL, 'configure:env:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2543, 2541, '新增环境', 'A', NULL, NULL, '/configure/api/v1/env', 'POST', NULL, 'configure:env:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2544, 2541, '修改环境', 'A', NULL, NULL, '/configure/api/v1/env', 'PUT', NULL, 'configure:env:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2545, 2541, '修改环境状态', 'A', NULL, NULL, '/configure/api/v1/env/status', 'PUT', NULL, 'configure:env:update:status', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2546, 2541, '删除环境', 'A', NULL, NULL, '/configure/api/v1/env', 'DELETE', NULL, 'configure:env:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2547, 2541, '查看环境Token', 'A', NULL, NULL, '/configure/api/v1/env/token', 'GET', NULL, 'configure:env:token:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2548, 2541, '重置环境token', 'A', NULL, NULL, '/configure/api/v1/env/token', 'PUT', NULL, 'configure:env:token:reset', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2549, 2540, '服务管理', 'M', 'ConfigureServer', 'apps', NULL, NULL, '/configure/server', NULL, '/configure/server/index', NULL, 0, NULL, 1, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2550, 2549, '查询服务', 'A', NULL, NULL, '/configure/api/v1/servers', 'GET', NULL, 'configure:server:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2551, 2549, '新增服务', 'A', NULL, NULL, '/configure/api/v1/server', 'POST', NULL, 'configure:server:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2552, 2549, '修改服务', 'A', NULL, NULL, '/configure/api/v1/server', 'PUT', NULL, 'configure:server:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2553, 2549, '修改服务状态', 'A', NULL, NULL, '/configure/api/v1/server/status', 'PUT', NULL, 'configure:server:update:status', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2554, 2549, '删除服务', 'A', NULL, NULL, '/configure/api/v1/server', 'DELETE', NULL, 'configure:server:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2555, 2540, '业务变量', 'M', 'ConfigureBusiness', 'code', NULL, NULL, '/configure/business', NULL, '/configure/business/index', NULL, 0, NULL, 1, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2556, 2555, '查看业务变量', 'A', NULL, NULL, '/configure/api/v1/business', 'GET', NULL, 'configure:business:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2557, 2555, '新增业务变量', 'A', NULL, NULL, '/configure/api/v1/business', 'POST', NULL, 'configure:business:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2558, 2555, '修改业务变量', 'A', NULL, NULL, '/configure/api/v1/business', 'PUT', NULL, 'configure:business:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2559, 2555, '删除业务变量', 'A', NULL, NULL, '/configure/api/v1/business', 'DELETE', NULL, 'configure:business:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2560, 2555, '查看业务变量值', 'A', NULL, NULL, '/configure/business/values', 'get', NULL, 'configure:business:value:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2561, 2555, '设置业务变量值', 'A', NULL, NULL, '/configure/business/values', 'PUT', NULL, 'configure:business:value:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2562, 2540, '资源变量', 'M', 'ConfigureResource', 'unordered-list', NULL, NULL, '/configure/resource', NULL, '/configure/resource/index', NULL, 0, NULL, 1, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2563, 2562, '查看资源', 'A', NULL, NULL, '/configure/api/v1/resources', 'GET', NULL, 'configure:resource:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2564, 2562, '新增资源', 'A', NULL, NULL, '/configure/api/v1/resource', 'POST', NULL, 'configure:resource:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2565, 2562, '修改资源', 'A', NULL, NULL, '/configure/api/v1/resource', 'PUT', NULL, 'configure:resource:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2566, 2562, '删除资源', 'A', NULL, NULL, '/configure/api/v1/resource', 'DELETE', NULL, 'configure:resource:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2567, 2562, '查看业务变量值', 'A', NULL, NULL, '/configure/resource/values', 'get', NULL, 'configure:resource:value:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2568, 2562, '设置业务变量值', 'A', NULL, NULL, '/configure/resource/values', 'PUT', NULL, 'configure:resource:value:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2569, 2540, '配置模板', 'M', 'ConfgureTemplate', 'file', NULL, NULL, '/configure/template', NULL, '/configure/template/index', NULL, 0, NULL, 1, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2570, 2569, '模板管理', 'G', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2571, 2570, '查看模板历史版本', 'A', NULL, NULL, '/configure/api/v1/templates', 'GET', NULL, 'configure:template:history', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2572, 2570, '查看指定模板详细数据', 'A', NULL, NULL, '/configure/api/v1/template', 'GET', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2573, 2570, '查看当前正在使用的模板', 'A', NULL, NULL, '/configure/api/v1/template/current', 'GET', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2574, 2570, '提交模板', 'A', NULL, NULL, '/configure/api/v1/template', 'POST', NULL, 'configure:template:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2575, 2570, '模板对比', 'A', NULL, NULL, '/configure/api/v1/template/compare', 'POST', NULL, 'configure:template:compare', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2576, 2570, '切换模板', 'A', NULL, NULL, '/configure/api/v1/template/switch', 'POST', NULL, 'configure:template:switch', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2577, 2570, '模板预览', 'A', NULL, NULL, '/configure/api/v1/template/preview', 'POST', NULL, 'configure:template:preview', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2578, 2569, '配置管理', 'G', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2579, 2578, '配置对比', 'A', NULL, NULL, '/configure/api/v1/configure/compare', 'POST', NULL, 'configure:configure:compare', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2580, 2578, '同步配置', 'A', NULL, NULL, '/configure/api/v1/configure', 'PUT', NULL, 'configure:configure:sync', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2581, 2427, '定时任务', 'M', 'SystemPlatformCron', 'schedule', NULL, NULL, '/cron', NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2582, 2581, '节点管理', 'M', 'Worker', 'common', NULL, NULL, '/cron/worker', NULL, '/cron/worker/index', NULL, 0, 0, 1, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2583, 2582, '查看节点分组', 'A', NULL, NULL, '/cron/api/v1/worker_groups', 'GET', NULL, 'cron:worker:group:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2584, 2582, '新增节点分组', 'A', NULL, NULL, '/cron/api/v1/worker_group', 'POST', NULL, 'cron:worker:group:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2585, 2582, '修改节点分组', 'A', NULL, NULL, '/cron/api/v1/worker_group', 'PUT', NULL, 'cron:worker:group:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2586, 2582, '删除节点分组', 'A', NULL, NULL, '/cron/api/v1/worker_group', 'DELETE', NULL, 'cron:worker:group:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2587, 2582, '查看节点', 'A', NULL, NULL, '/cron/api/v1/workers', 'GET', NULL, 'cron:worker:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2588, 2582, '新增节点', 'A', NULL, NULL, '/cron/api/v1/worker', 'POST', NULL, 'cron:worker:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2589, 2582, '修改节点', 'A', NULL, NULL, '/cron/api/v1/worker', 'PUT', NULL, 'cron:worker:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2590, 2582, '删除节点', 'A', NULL, NULL, '/cron/api/v1/worker', 'DELETE', NULL, 'cron:worker:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2591, 2582, '更新节点状态', 'A', NULL, NULL, '/cron/api/v1/worker/status', 'PUT', NULL, 'cron:worker:update:status', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2592, 2581, '任务管理', 'M', 'Task', 'computer', NULL, NULL, '/cron/task', NULL, '/cron/task/index', NULL, 0, 0, 1, NULL, 1, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2593, 2592, '查看任务分组', 'A', NULL, NULL, '/cron/api/v1/task_groups', 'GET', NULL, 'cron:task:group:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2594, 2592, '新增任务分组', 'A', NULL, NULL, '/cron/api/v1/task_group', 'POST', NULL, 'cron:task:group:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2595, 2592, '修改任务分组', 'A', NULL, NULL, '/cron/api/v1/task_group', 'PUT', NULL, 'cron:task:group:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2596, 2592, '删除任务分组', 'A', NULL, NULL, '/cron/api/v1/task_group', 'DELETE', NULL, 'cron:task:group:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2597, 2592, '查看任务', 'A', NULL, NULL, '/cron/api/v1/tasks', 'GET', NULL, 'cron:task:query', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2598, 2592, '新增任务', 'A', NULL, NULL, '/cron/api/v1/task', 'POST', NULL, 'cron:task:add', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2599, 2592, '立即执行任务', 'A', NULL, NULL, '/cron/api/v1/task/exec', 'POST', NULL, 'cron:task:exec', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2600, 2592, '取消执行任务', 'A', NULL, NULL, '/cron/api/v1/task/cancel', 'POST', NULL, 'cron:task:cancel', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2601, 2592, '修改任务', 'A', NULL, NULL, '/cron/api/v1/task', 'PUT', NULL, 'cron:task:update', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2602, 2592, '删除任务', 'A', NULL, NULL, '/cron/api/v1/task', 'DELETE', NULL, 'cron:task:delete', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2603, 2592, '任务状态管理', 'A', NULL, NULL, '/cron/api/v1/task/status', 'PUT', NULL, 'cron:task:update:status', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2604, 2592, '任务日志', 'G', NULL, NULL, NULL, NULL, NULL, 'cron:task:log', NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2605, 2604, '获取任务日志分页', 'A', NULL, NULL, '/cron/api/v1/logs', 'GET', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487),
                                                                                                                                                                                                                                     (2606, 2604, '获取任务日志详情', 'A', NULL, NULL, '/cron/api/v1/log', 'GET', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL, NULL, 1719650487, 1719650487);

-- --------------------------------------------------------

--
-- 表的结构 `menu_closure`
--

DROP TABLE IF EXISTS `menu_closure`;
CREATE TABLE `menu_closure` (
                                `id` bigint(20) UNSIGNED NOT NULL COMMENT '主键ID',
                                `parent` bigint(20) UNSIGNED NOT NULL COMMENT '菜单id',
                                `children` bigint(20) UNSIGNED NOT NULL COMMENT '菜单id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='菜单层级信息';

--
-- 转存表中的数据 `menu_closure`
--

INSERT INTO `menu_closure` (`id`, `parent`, `children`) VALUES
                                                            (5483, 2427, 2431),
                                                            (5484, 2429, 2431),
                                                            (5485, 2430, 2431),
                                                            (5486, 2427, 2432),
                                                            (5487, 2429, 2432),
                                                            (5488, 2430, 2432),
                                                            (5489, 2427, 2433),
                                                            (5490, 2429, 2433),
                                                            (5491, 2430, 2433),
                                                            (5492, 2427, 2434),
                                                            (5493, 2429, 2434),
                                                            (5494, 2430, 2434),
                                                            (5495, 2427, 2435),
                                                            (5496, 2429, 2435),
                                                            (5497, 2430, 2435),
                                                            (5498, 2427, 2436),
                                                            (5499, 2429, 2436),
                                                            (5500, 2430, 2436),
                                                            (5501, 2427, 2437),
                                                            (5502, 2429, 2437),
                                                            (5503, 2430, 2437),
                                                            (5504, 2427, 2438),
                                                            (5505, 2429, 2438),
                                                            (5506, 2430, 2438),
                                                            (5507, 2427, 2439),
                                                            (5508, 2429, 2439),
                                                            (5509, 2430, 2439),
                                                            (5510, 2427, 2440),
                                                            (5511, 2429, 2440),
                                                            (5512, 2430, 2440),
                                                            (5513, 2427, 2441),
                                                            (5514, 2429, 2441),
                                                            (5515, 2430, 2441),
                                                            (5516, 2427, 2442),
                                                            (5517, 2429, 2442),
                                                            (5518, 2430, 2442),
                                                            (5519, 2427, 2443),
                                                            (5520, 2429, 2443),
                                                            (5521, 2430, 2443),
                                                            (5522, 2427, 2444),
                                                            (5523, 2429, 2444),
                                                            (5524, 2430, 2444),
                                                            (5525, 2427, 2445),
                                                            (5526, 2429, 2445),
                                                            (5527, 2430, 2445),
                                                            (5528, 2427, 2446),
                                                            (5529, 2429, 2446),
                                                            (5530, 2430, 2446),
                                                            (5531, 2427, 2447),
                                                            (5532, 2429, 2447),
                                                            (5533, 2430, 2447),
                                                            (5534, 2427, 2448),
                                                            (5535, 2429, 2448),
                                                            (5536, 2430, 2448),
                                                            (5537, 2427, 2450),
                                                            (5538, 2429, 2450),
                                                            (5539, 2449, 2450),
                                                            (5540, 2427, 2451),
                                                            (5541, 2429, 2451),
                                                            (5542, 2449, 2451),
                                                            (5543, 2427, 2452),
                                                            (5544, 2429, 2452),
                                                            (5545, 2449, 2452),
                                                            (5546, 2427, 2453),
                                                            (5547, 2429, 2453),
                                                            (5548, 2449, 2453),
                                                            (5549, 2427, 2454),
                                                            (5550, 2429, 2454),
                                                            (5551, 2449, 2454),
                                                            (5552, 2427, 2455),
                                                            (5553, 2429, 2455),
                                                            (5554, 2449, 2455),
                                                            (5555, 2427, 2456),
                                                            (5556, 2429, 2456),
                                                            (5557, 2449, 2456),
                                                            (5558, 2427, 2457),
                                                            (5559, 2429, 2457),
                                                            (5560, 2449, 2457),
                                                            (5561, 2427, 2458),
                                                            (5562, 2429, 2458),
                                                            (5563, 2449, 2458),
                                                            (5564, 2427, 2460),
                                                            (5565, 2429, 2460),
                                                            (5566, 2459, 2460),
                                                            (5567, 2427, 2461),
                                                            (5568, 2429, 2461),
                                                            (5569, 2459, 2461),
                                                            (5570, 2427, 2462),
                                                            (5571, 2429, 2462),
                                                            (5572, 2459, 2462),
                                                            (5573, 2427, 2463),
                                                            (5574, 2429, 2463),
                                                            (5575, 2459, 2463),
                                                            (5576, 2427, 2465),
                                                            (5577, 2429, 2465),
                                                            (5578, 2464, 2465),
                                                            (5579, 2427, 2466),
                                                            (5580, 2429, 2466),
                                                            (5581, 2464, 2466),
                                                            (5582, 2427, 2467),
                                                            (5583, 2429, 2467),
                                                            (5584, 2464, 2467),
                                                            (5585, 2427, 2468),
                                                            (5586, 2429, 2468),
                                                            (5587, 2464, 2468),
                                                            (5588, 2427, 2470),
                                                            (5589, 2429, 2470),
                                                            (5590, 2469, 2470),
                                                            (5591, 2427, 2471),
                                                            (5592, 2429, 2471),
                                                            (5593, 2469, 2471),
                                                            (5594, 2427, 2472),
                                                            (5595, 2429, 2472),
                                                            (5596, 2469, 2472),
                                                            (5597, 2427, 2479),
                                                            (5598, 2429, 2479),
                                                            (5599, 2473, 2479),
                                                            (5600, 2478, 2479),
                                                            (5601, 2427, 2480),
                                                            (5602, 2429, 2480),
                                                            (5603, 2473, 2480),
                                                            (5604, 2478, 2480),
                                                            (5605, 2427, 2474),
                                                            (5606, 2429, 2474),
                                                            (5607, 2473, 2474),
                                                            (5608, 2427, 2475),
                                                            (5609, 2429, 2475),
                                                            (5610, 2473, 2475),
                                                            (5611, 2427, 2476),
                                                            (5612, 2429, 2476),
                                                            (5613, 2473, 2476),
                                                            (5614, 2427, 2477),
                                                            (5615, 2429, 2477),
                                                            (5616, 2473, 2477),
                                                            (5617, 2427, 2478),
                                                            (5618, 2429, 2478),
                                                            (5619, 2473, 2478),
                                                            (5620, 2427, 2482),
                                                            (5621, 2429, 2482),
                                                            (5622, 2481, 2482),
                                                            (5623, 2427, 2483),
                                                            (5624, 2429, 2483),
                                                            (5625, 2481, 2483),
                                                            (5626, 2427, 2484),
                                                            (5627, 2429, 2484),
                                                            (5628, 2481, 2484),
                                                            (5629, 2427, 2485),
                                                            (5630, 2429, 2485),
                                                            (5631, 2481, 2485),
                                                            (5632, 2427, 2486),
                                                            (5633, 2429, 2486),
                                                            (5634, 2481, 2486),
                                                            (5635, 2427, 2487),
                                                            (5636, 2429, 2487),
                                                            (5637, 2481, 2487),
                                                            (5638, 2427, 2430),
                                                            (5639, 2429, 2430),
                                                            (5640, 2427, 2449),
                                                            (5641, 2429, 2449),
                                                            (5642, 2427, 2459),
                                                            (5643, 2429, 2459),
                                                            (5644, 2427, 2464),
                                                            (5645, 2429, 2464),
                                                            (5646, 2427, 2469),
                                                            (5647, 2429, 2469),
                                                            (5648, 2427, 2473),
                                                            (5649, 2429, 2473),
                                                            (5650, 2427, 2481),
                                                            (5651, 2429, 2481),
                                                            (5652, 2427, 2491),
                                                            (5653, 2488, 2491),
                                                            (5654, 2489, 2491),
                                                            (5655, 2490, 2491),
                                                            (5656, 2427, 2492),
                                                            (5657, 2488, 2492),
                                                            (5658, 2489, 2492),
                                                            (5659, 2490, 2492),
                                                            (5660, 2427, 2493),
                                                            (5661, 2488, 2493),
                                                            (5662, 2489, 2493),
                                                            (5663, 2490, 2493),
                                                            (5664, 2427, 2494),
                                                            (5665, 2488, 2494),
                                                            (5666, 2489, 2494),
                                                            (5667, 2490, 2494),
                                                            (5668, 2427, 2496),
                                                            (5669, 2488, 2496),
                                                            (5670, 2489, 2496),
                                                            (5671, 2495, 2496),
                                                            (5672, 2427, 2497),
                                                            (5673, 2488, 2497),
                                                            (5674, 2489, 2497),
                                                            (5675, 2495, 2497),
                                                            (5676, 2427, 2498),
                                                            (5677, 2488, 2498),
                                                            (5678, 2489, 2498),
                                                            (5679, 2495, 2498),
                                                            (5680, 2427, 2490),
                                                            (5681, 2488, 2490),
                                                            (5682, 2489, 2490),
                                                            (5683, 2427, 2495),
                                                            (5684, 2488, 2495),
                                                            (5685, 2489, 2495),
                                                            (5686, 2427, 2500),
                                                            (5687, 2488, 2500),
                                                            (5688, 2499, 2500),
                                                            (5689, 2427, 2501),
                                                            (5690, 2488, 2501),
                                                            (5691, 2499, 2501),
                                                            (5692, 2427, 2502),
                                                            (5693, 2488, 2502),
                                                            (5694, 2499, 2502),
                                                            (5695, 2427, 2489),
                                                            (5696, 2488, 2489),
                                                            (5697, 2427, 2499),
                                                            (5698, 2488, 2499),
                                                            (5699, 2427, 2505),
                                                            (5700, 2503, 2505),
                                                            (5701, 2504, 2505),
                                                            (5702, 2427, 2506),
                                                            (5703, 2503, 2506),
                                                            (5704, 2504, 2506),
                                                            (5705, 2427, 2507),
                                                            (5706, 2503, 2507),
                                                            (5707, 2504, 2507),
                                                            (5708, 2427, 2508),
                                                            (5709, 2503, 2508),
                                                            (5710, 2504, 2508),
                                                            (5711, 2427, 2509),
                                                            (5712, 2503, 2509),
                                                            (5713, 2504, 2509),
                                                            (5714, 2427, 2511),
                                                            (5715, 2503, 2511),
                                                            (5716, 2510, 2511),
                                                            (5717, 2427, 2512),
                                                            (5718, 2503, 2512),
                                                            (5719, 2510, 2512),
                                                            (5720, 2427, 2513),
                                                            (5721, 2503, 2513),
                                                            (5722, 2510, 2513),
                                                            (5723, 2427, 2514),
                                                            (5724, 2503, 2514),
                                                            (5725, 2510, 2514),
                                                            (5726, 2427, 2515),
                                                            (5727, 2503, 2515),
                                                            (5728, 2510, 2515),
                                                            (5729, 2427, 2517),
                                                            (5730, 2503, 2517),
                                                            (5731, 2516, 2517),
                                                            (5732, 2427, 2518),
                                                            (5733, 2503, 2518),
                                                            (5734, 2516, 2518),
                                                            (5735, 2427, 2519),
                                                            (5736, 2503, 2519),
                                                            (5737, 2516, 2519),
                                                            (5738, 2427, 2520),
                                                            (5739, 2503, 2520),
                                                            (5740, 2516, 2520),
                                                            (5741, 2427, 2521),
                                                            (5742, 2503, 2521),
                                                            (5743, 2516, 2521),
                                                            (5744, 2427, 2530),
                                                            (5745, 2503, 2530),
                                                            (5746, 2522, 2530),
                                                            (5747, 2529, 2530),
                                                            (5748, 2427, 2531),
                                                            (5749, 2503, 2531),
                                                            (5750, 2522, 2531),
                                                            (5751, 2529, 2531),
                                                            (5752, 2427, 2532),
                                                            (5753, 2503, 2532),
                                                            (5754, 2522, 2532),
                                                            (5755, 2529, 2532),
                                                            (5756, 2427, 2533),
                                                            (5757, 2503, 2533),
                                                            (5758, 2522, 2533),
                                                            (5759, 2529, 2533),
                                                            (5760, 2427, 2534),
                                                            (5761, 2503, 2534),
                                                            (5762, 2522, 2534),
                                                            (5763, 2529, 2534),
                                                            (5764, 2427, 2535),
                                                            (5765, 2503, 2535),
                                                            (5766, 2522, 2535),
                                                            (5767, 2529, 2535),
                                                            (5768, 2427, 2536),
                                                            (5769, 2503, 2536),
                                                            (5770, 2522, 2536),
                                                            (5771, 2529, 2536),
                                                            (5772, 2427, 2537),
                                                            (5773, 2503, 2537),
                                                            (5774, 2522, 2537),
                                                            (5775, 2529, 2537),
                                                            (5776, 2427, 2538),
                                                            (5777, 2503, 2538),
                                                            (5778, 2522, 2538),
                                                            (5779, 2529, 2538),
                                                            (5780, 2427, 2539),
                                                            (5781, 2503, 2539),
                                                            (5782, 2522, 2539),
                                                            (5783, 2529, 2539),
                                                            (5784, 2427, 2523),
                                                            (5785, 2503, 2523),
                                                            (5786, 2522, 2523),
                                                            (5787, 2427, 2524),
                                                            (5788, 2503, 2524),
                                                            (5789, 2522, 2524),
                                                            (5790, 2427, 2525),
                                                            (5791, 2503, 2525),
                                                            (5792, 2522, 2525),
                                                            (5793, 2427, 2526),
                                                            (5794, 2503, 2526),
                                                            (5795, 2522, 2526),
                                                            (5796, 2427, 2527),
                                                            (5797, 2503, 2527),
                                                            (5798, 2522, 2527),
                                                            (5799, 2427, 2528),
                                                            (5800, 2503, 2528),
                                                            (5801, 2522, 2528),
                                                            (5802, 2427, 2529),
                                                            (5803, 2503, 2529),
                                                            (5804, 2522, 2529),
                                                            (5805, 2427, 2504),
                                                            (5806, 2503, 2504),
                                                            (5807, 2427, 2510),
                                                            (5808, 2503, 2510),
                                                            (5809, 2427, 2516),
                                                            (5810, 2503, 2516),
                                                            (5811, 2427, 2522),
                                                            (5812, 2503, 2522),
                                                            (5813, 2427, 2542),
                                                            (5814, 2540, 2542),
                                                            (5815, 2541, 2542),
                                                            (5816, 2427, 2543),
                                                            (5817, 2540, 2543),
                                                            (5818, 2541, 2543),
                                                            (5819, 2427, 2544),
                                                            (5820, 2540, 2544),
                                                            (5821, 2541, 2544),
                                                            (5822, 2427, 2545),
                                                            (5823, 2540, 2545),
                                                            (5824, 2541, 2545),
                                                            (5825, 2427, 2546),
                                                            (5826, 2540, 2546),
                                                            (5827, 2541, 2546),
                                                            (5828, 2427, 2547),
                                                            (5829, 2540, 2547),
                                                            (5830, 2541, 2547),
                                                            (5831, 2427, 2548),
                                                            (5832, 2540, 2548),
                                                            (5833, 2541, 2548),
                                                            (5834, 2427, 2550),
                                                            (5835, 2540, 2550),
                                                            (5836, 2549, 2550),
                                                            (5837, 2427, 2551),
                                                            (5838, 2540, 2551),
                                                            (5839, 2549, 2551),
                                                            (5840, 2427, 2552),
                                                            (5841, 2540, 2552),
                                                            (5842, 2549, 2552),
                                                            (5843, 2427, 2553),
                                                            (5844, 2540, 2553),
                                                            (5845, 2549, 2553),
                                                            (5846, 2427, 2554),
                                                            (5847, 2540, 2554),
                                                            (5848, 2549, 2554),
                                                            (5849, 2427, 2556),
                                                            (5850, 2540, 2556),
                                                            (5851, 2555, 2556),
                                                            (5852, 2427, 2557),
                                                            (5853, 2540, 2557),
                                                            (5854, 2555, 2557),
                                                            (5855, 2427, 2558),
                                                            (5856, 2540, 2558),
                                                            (5857, 2555, 2558),
                                                            (5858, 2427, 2559),
                                                            (5859, 2540, 2559),
                                                            (5860, 2555, 2559),
                                                            (5861, 2427, 2560),
                                                            (5862, 2540, 2560),
                                                            (5863, 2555, 2560),
                                                            (5864, 2427, 2561),
                                                            (5865, 2540, 2561),
                                                            (5866, 2555, 2561),
                                                            (5867, 2427, 2563),
                                                            (5868, 2540, 2563),
                                                            (5869, 2562, 2563),
                                                            (5870, 2427, 2564),
                                                            (5871, 2540, 2564),
                                                            (5872, 2562, 2564),
                                                            (5873, 2427, 2565),
                                                            (5874, 2540, 2565),
                                                            (5875, 2562, 2565),
                                                            (5876, 2427, 2566),
                                                            (5877, 2540, 2566),
                                                            (5878, 2562, 2566),
                                                            (5879, 2427, 2567),
                                                            (5880, 2540, 2567),
                                                            (5881, 2562, 2567),
                                                            (5882, 2427, 2568),
                                                            (5883, 2540, 2568),
                                                            (5884, 2562, 2568),
                                                            (5885, 2427, 2571),
                                                            (5886, 2540, 2571),
                                                            (5887, 2569, 2571),
                                                            (5888, 2570, 2571),
                                                            (5889, 2427, 2572),
                                                            (5890, 2540, 2572),
                                                            (5891, 2569, 2572),
                                                            (5892, 2570, 2572),
                                                            (5893, 2427, 2573),
                                                            (5894, 2540, 2573),
                                                            (5895, 2569, 2573),
                                                            (5896, 2570, 2573),
                                                            (5897, 2427, 2574),
                                                            (5898, 2540, 2574),
                                                            (5899, 2569, 2574),
                                                            (5900, 2570, 2574),
                                                            (5901, 2427, 2575),
                                                            (5902, 2540, 2575),
                                                            (5903, 2569, 2575),
                                                            (5904, 2570, 2575),
                                                            (5905, 2427, 2576),
                                                            (5906, 2540, 2576),
                                                            (5907, 2569, 2576),
                                                            (5908, 2570, 2576),
                                                            (5909, 2427, 2577),
                                                            (5910, 2540, 2577),
                                                            (5911, 2569, 2577),
                                                            (5912, 2570, 2577),
                                                            (5913, 2427, 2579),
                                                            (5914, 2540, 2579),
                                                            (5915, 2569, 2579),
                                                            (5916, 2578, 2579),
                                                            (5917, 2427, 2580),
                                                            (5918, 2540, 2580),
                                                            (5919, 2569, 2580),
                                                            (5920, 2578, 2580),
                                                            (5921, 2427, 2570),
                                                            (5922, 2540, 2570),
                                                            (5923, 2569, 2570),
                                                            (5924, 2427, 2578),
                                                            (5925, 2540, 2578),
                                                            (5926, 2569, 2578),
                                                            (5927, 2427, 2541),
                                                            (5928, 2540, 2541),
                                                            (5929, 2427, 2549),
                                                            (5930, 2540, 2549),
                                                            (5931, 2427, 2555),
                                                            (5932, 2540, 2555),
                                                            (5933, 2427, 2562),
                                                            (5934, 2540, 2562),
                                                            (5935, 2427, 2569),
                                                            (5936, 2540, 2569),
                                                            (5937, 2427, 2583),
                                                            (5938, 2581, 2583),
                                                            (5939, 2582, 2583),
                                                            (5940, 2427, 2584),
                                                            (5941, 2581, 2584),
                                                            (5942, 2582, 2584),
                                                            (5943, 2427, 2585),
                                                            (5944, 2581, 2585),
                                                            (5945, 2582, 2585),
                                                            (5946, 2427, 2586),
                                                            (5947, 2581, 2586),
                                                            (5948, 2582, 2586),
                                                            (5949, 2427, 2587),
                                                            (5950, 2581, 2587),
                                                            (5951, 2582, 2587),
                                                            (5952, 2427, 2588),
                                                            (5953, 2581, 2588),
                                                            (5954, 2582, 2588),
                                                            (5955, 2427, 2589),
                                                            (5956, 2581, 2589),
                                                            (5957, 2582, 2589),
                                                            (5958, 2427, 2590),
                                                            (5959, 2581, 2590),
                                                            (5960, 2582, 2590),
                                                            (5961, 2427, 2591),
                                                            (5962, 2581, 2591),
                                                            (5963, 2582, 2591),
                                                            (5964, 2427, 2605),
                                                            (5965, 2581, 2605),
                                                            (5966, 2592, 2605),
                                                            (5967, 2604, 2605),
                                                            (5968, 2427, 2606),
                                                            (5969, 2581, 2606),
                                                            (5970, 2592, 2606),
                                                            (5971, 2604, 2606),
                                                            (5972, 2427, 2593),
                                                            (5973, 2581, 2593),
                                                            (5974, 2592, 2593),
                                                            (5975, 2427, 2594),
                                                            (5976, 2581, 2594),
                                                            (5977, 2592, 2594),
                                                            (5978, 2427, 2595),
                                                            (5979, 2581, 2595),
                                                            (5980, 2592, 2595),
                                                            (5981, 2427, 2596),
                                                            (5982, 2581, 2596),
                                                            (5983, 2592, 2596),
                                                            (5984, 2427, 2597),
                                                            (5985, 2581, 2597),
                                                            (5986, 2592, 2597),
                                                            (5987, 2427, 2598),
                                                            (5988, 2581, 2598),
                                                            (5989, 2592, 2598),
                                                            (5990, 2427, 2599),
                                                            (5991, 2581, 2599),
                                                            (5992, 2592, 2599),
                                                            (5993, 2427, 2600),
                                                            (5994, 2581, 2600),
                                                            (5995, 2592, 2600),
                                                            (5996, 2427, 2601),
                                                            (5997, 2581, 2601),
                                                            (5998, 2592, 2601),
                                                            (5999, 2427, 2602),
                                                            (6000, 2581, 2602),
                                                            (6001, 2592, 2602),
                                                            (6002, 2427, 2603),
                                                            (6003, 2581, 2603),
                                                            (6004, 2592, 2603),
                                                            (6005, 2427, 2604),
                                                            (6006, 2581, 2604),
                                                            (6007, 2592, 2604),
                                                            (6008, 2427, 2582),
                                                            (6009, 2581, 2582),
                                                            (6010, 2427, 2592),
                                                            (6011, 2581, 2592),
                                                            (6012, 2427, 2428),
                                                            (6013, 2427, 2429),
                                                            (6014, 2427, 2488),
                                                            (6015, 2427, 2503),
                                                            (6016, 2427, 2540),
                                                            (6017, 2427, 2581);

-- --------------------------------------------------------

--
-- 表的结构 `role`
--

DROP TABLE IF EXISTS `role`;
CREATE TABLE `role` (
                        `id` bigint(20) UNSIGNED NOT NULL COMMENT '主键ID',
                        `parent_id` bigint(20) UNSIGNED NOT NULL COMMENT '父id',
                        `name` varchar(64) NOT NULL COMMENT '名称',
                        `keyword` char(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '标识',
                        `status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '状态',
                        `description` varchar(128) NOT NULL COMMENT '描述',
                        `department_ids` tinytext COMMENT '自定义部门',
                        `data_scope` char(32) NOT NULL COMMENT '权限类型',
                        `created_at` bigint(20) UNSIGNED NOT NULL DEFAULT '0' COMMENT '创建时间',
                        `updated_at` bigint(20) UNSIGNED NOT NULL DEFAULT '0' COMMENT '修改时间',
                        `deleted_at` bigint(20) UNSIGNED NOT NULL DEFAULT '0' COMMENT '删除时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色信息';

--
-- 转存表中的数据 `role`
--

INSERT INTO `role` (`id`, `parent_id`, `name`, `keyword`, `status`, `description`, `department_ids`, `data_scope`, `created_at`, `updated_at`, `deleted_at`) VALUES
                                                                                                                                                                 (1, 0, '超级管理员', 'superAdmin', 1, '超级管理员  ', NULL, 'ALL', 1713706137, 1713706137, 0),
                                                                                                                                                                 (5, 1, '2', '3', 1, '4', NULL, 'ALL', 1719464519, 1719464562, 0);

-- --------------------------------------------------------

--
-- 表的结构 `role_closure`
--

DROP TABLE IF EXISTS `role_closure`;
CREATE TABLE `role_closure` (
                                `id` bigint(20) UNSIGNED NOT NULL COMMENT '主键ID',
                                `parent` bigint(20) UNSIGNED NOT NULL COMMENT '角色id',
                                `children` bigint(20) UNSIGNED NOT NULL COMMENT '角色id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色层级信息';

--
-- 转存表中的数据 `role_closure`
--

INSERT INTO `role_closure` (`id`, `parent`, `children`) VALUES
    (5, 1, 5);

-- --------------------------------------------------------

--
-- 表的结构 `role_menu`
--

DROP TABLE IF EXISTS `role_menu`;
CREATE TABLE `role_menu` (
                             `id` bigint(20) UNSIGNED NOT NULL COMMENT '主键ID',
                             `role_id` bigint(20) UNSIGNED NOT NULL COMMENT '角色id',
                             `menu_id` bigint(20) UNSIGNED NOT NULL COMMENT '菜单id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色菜单信息';

-- --------------------------------------------------------

--
-- 表的结构 `user`
--

DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
                        `id` bigint(20) UNSIGNED NOT NULL COMMENT '主键ID',
                        `department_id` bigint(20) UNSIGNED NOT NULL COMMENT '部门id',
                        `role_id` bigint(20) UNSIGNED NOT NULL COMMENT '角色id',
                        `name` char(32) NOT NULL COMMENT '名称',
                        `nickname` varchar(64) NOT NULL COMMENT '昵称',
                        `gender` char(32) NOT NULL COMMENT '性别',
                        `avatar` varchar(256) DEFAULT NULL COMMENT '头像',
                        `email` varchar(64) NOT NULL COMMENT '邮箱',
                        `phone` char(32) NOT NULL COMMENT '电话',
                        `password` varchar(256) NOT NULL COMMENT '密码',
                        `status` tinyint(1) DEFAULT '0' COMMENT '状态',
                        `setting` tinytext COMMENT '用户设置',
                        `token` varchar(512) DEFAULT NULL COMMENT '用户token',
                        `logged_at` bigint(20) NOT NULL DEFAULT '0' COMMENT '登陆时间',
                        `created_at` bigint(20) NOT NULL DEFAULT '0' COMMENT '创建时间',
                        `updated_at` bigint(20) NOT NULL DEFAULT '0' COMMENT '修改时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户信息';

--
-- 转存表中的数据 `user`
--

INSERT INTO `user` (`id`, `department_id`, `role_id`, `name`, `nickname`, `gender`, `avatar`, `email`, `phone`, `password`, `status`, `setting`, `token`, `logged_at`, `created_at`, `updated_at`) VALUES
    (1, 1, 1, '超级管理员', '超级管理员', 'F', '2a0786fe9127b8116bc30ed2ce9581e2', '1280291001@qq.com', '18888888888', '$2a$10$9qRJe9KQo6sEcU8ipKg.e.dkl2E7Wy64SigYlgraTAn.1paHFq6W.', 1, '{\"theme\":\"light\",\"themeColor\":\"#165DFF\",\"skin\":\"default\",\"tabBar\":true,\"menuWidth\":200,\"layout\":\"default\",\"language\":\"zh_CN\",\"animation\":\"gp-fade\"}', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJkZXBhcnRtZW50SWQiOjEsImRlcGFydG1lbnRLZXl3b3JkIjoiY29tcGFueSIsImV4cCI6MTcxOTc0NDMzMywiaWF0IjoxNzE5NzM3MTMyLCJuYmYiOjE3MTk3MzcxMzIsInJvbGVJZCI6MSwicm9sZUtleXdvcmQiOiJzdXBlckFkbWluIiwidXNlcklkIjoxfQ.jp5601dvstphhDNsmmHx1o4rhKvUVB3ioCO6b1IYaio', 1719737132, 1713706137, 1719737132);

-- --------------------------------------------------------

--
-- 表的结构 `user_job`
--

DROP TABLE IF EXISTS `user_job`;
CREATE TABLE `user_job` (
                            `id` bigint(20) UNSIGNED NOT NULL COMMENT '主键ID',
                            `job_id` bigint(20) UNSIGNED NOT NULL COMMENT '职位id',
                            `user_id` bigint(20) UNSIGNED NOT NULL COMMENT '用户id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户职位信息';

--
-- 转存表中的数据 `user_job`
--

INSERT INTO `user_job` (`id`, `job_id`, `user_id`) VALUES
    (1, 1, 1);

-- --------------------------------------------------------

--
-- 表的结构 `user_role`
--

DROP TABLE IF EXISTS `user_role`;
CREATE TABLE `user_role` (
                             `id` bigint(20) UNSIGNED NOT NULL COMMENT '主键ID',
                             `role_id` bigint(20) UNSIGNED NOT NULL COMMENT '角色id',
                             `user_id` bigint(20) UNSIGNED NOT NULL COMMENT '用户id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户角色信息';


CREATE TABLE `resource` (
                            `id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT '主键ID',
                            `keyword` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT '关键字',
                            `department_id` bigint unsigned NOT NULL COMMENT '部门id',
                            `resource_id` bigint unsigned NOT NULL COMMENT '资源id',
                            PRIMARY KEY (`id`),
                            UNIQUE `department_id` (`keyword`,`department_id`,`resource_id`),
                            FOREIGN KEY(department_id) REFERENCES department(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='资源权限信息';
--
-- 转存表中的数据 `user_role`
--

INSERT INTO `user_role` (`id`, `role_id`, `user_id`) VALUES
    (1, 1, 1);

--
-- 转储表的索引
--

--
-- 表的索引 `casbin_rule`
--
ALTER TABLE `casbin_rule`
    ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `idx_casbin_rule` (`ptype`,`v0`,`v1`,`v2`,`v3`,`v4`,`v5`);

--
-- 表的索引 `department`
--
ALTER TABLE `department`
    ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `keyword` (`keyword`),
  ADD KEY `idx_department_created_at` (`created_at`),
  ADD KEY `idx_department_updated_at` (`updated_at`);

--
-- 表的索引 `department_closure`
--
ALTER TABLE `department_closure`
    ADD PRIMARY KEY (`id`),
  ADD KEY `parent` (`parent`),
  ADD KEY `children` (`children`);

--
-- 表的索引 `dictionary`
--
ALTER TABLE `dictionary`
    ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `keyword` (`keyword`,`deleted_at`),
  ADD KEY `idx_dictionary_created_at` (`created_at`),
  ADD KEY `idx_dictionary_updated_at` (`updated_at`),
  ADD KEY `idx_dictionary_deleted_at` (`deleted_at`);

--
-- 表的索引 `dictionary_value`
--
ALTER TABLE `dictionary_value`
    ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `value` (`dictionary_id`,`value`),
  ADD KEY `idx_dictionary_value_created_at` (`created_at`),
  ADD KEY `idx_dictionary_value_updated_at` (`updated_at`),
  ADD KEY `idx_dictionary_value_weight` (`weight`);

--
-- 表的索引 `gorm_init`
--
ALTER TABLE `gorm_init`
    ADD PRIMARY KEY (`id`);

--
-- 表的索引 `job`
--
ALTER TABLE `job`
    ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `keyword` (`keyword`,`deleted_at`),
  ADD KEY `idx_job_weight` (`weight`),
  ADD KEY `idx_job_updated_at` (`updated_at`),
  ADD KEY `idx_job_created_at` (`created_at`),
  ADD KEY `idx_job_deleted_at` (`deleted_at`);

--
-- 表的索引 `menu`
--
ALTER TABLE `menu`
    ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `keyword` (`keyword`),
  ADD UNIQUE KEY `path` (`path`),
  ADD UNIQUE KEY `api_method` (`api`,`method`),
  ADD KEY `idx_menu_created_at` (`created_at`),
  ADD KEY `idx_menu_updated_at` (`updated_at`),
  ADD KEY `idx_menu_weight` (`weight`);

--
-- 表的索引 `menu_closure`
--
ALTER TABLE `menu_closure`
    ADD PRIMARY KEY (`id`),
  ADD KEY `parent` (`parent`),
  ADD KEY `children` (`children`);

--
-- 表的索引 `role`
--
ALTER TABLE `role`
    ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `keyword` (`keyword`,`deleted_at`),
  ADD KEY `idx_role_created_at` (`created_at`),
  ADD KEY `idx_role_updated_at` (`updated_at`),
  ADD KEY `idx_role_deleted_at` (`deleted_at`);

--
-- 表的索引 `role_closure`
--
ALTER TABLE `role_closure`
    ADD PRIMARY KEY (`id`),
  ADD KEY `parent` (`parent`),
  ADD KEY `children` (`children`);

--
-- 表的索引 `role_menu`
--
ALTER TABLE `role_menu`
    ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `role_id_2` (`role_id`,`menu_id`),
  ADD KEY `role_id` (`role_id`),
  ADD KEY `menu_id` (`menu_id`);

--
-- 表的索引 `user`
--
ALTER TABLE `user`
    ADD PRIMARY KEY (`id`),
  ADD KEY `idx_user_updated_at` (`updated_at`),
  ADD KEY `idx_user_created_at` (`created_at`),
  ADD KEY `fk_user_role` (`role_id`),
  ADD KEY `fk_user_department` (`department_id`);

--
-- 表的索引 `user_job`
--
ALTER TABLE `user_job`
    ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `job_id` (`job_id`,`user_id`),
  ADD KEY `user_id` (`user_id`);

--
-- 表的索引 `user_role`
--
ALTER TABLE `user_role`
    ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `role_id` (`role_id`,`user_id`),
  ADD KEY `user_id` (`user_id`);

--
-- 在导出的表使用AUTO_INCREMENT
--

--
-- 使用表AUTO_INCREMENT `casbin_rule`
--
ALTER TABLE `casbin_rule`
    MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=591;

--
-- 使用表AUTO_INCREMENT `department`
--
ALTER TABLE `department`
    MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID', AUTO_INCREMENT=5;

--
-- 使用表AUTO_INCREMENT `department_closure`
--
ALTER TABLE `department_closure`
    MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID', AUTO_INCREMENT=10;

--
-- 使用表AUTO_INCREMENT `dictionary`
--
ALTER TABLE `dictionary`
    MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID', AUTO_INCREMENT=3;

--
-- 使用表AUTO_INCREMENT `dictionary_value`
--
ALTER TABLE `dictionary_value`
    MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID', AUTO_INCREMENT=2;

--
-- 使用表AUTO_INCREMENT `gorm_init`
--
ALTER TABLE `gorm_init`
    MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- 使用表AUTO_INCREMENT `job`
--
ALTER TABLE `job`
    MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID', AUTO_INCREMENT=13;

--
-- 使用表AUTO_INCREMENT `menu`
--
ALTER TABLE `menu`
    MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID', AUTO_INCREMENT=2607;

--
-- 使用表AUTO_INCREMENT `menu_closure`
--
ALTER TABLE `menu_closure`
    MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID', AUTO_INCREMENT=6018;

--
-- 使用表AUTO_INCREMENT `role`
--
ALTER TABLE `role`
    MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID', AUTO_INCREMENT=6;

--
-- 使用表AUTO_INCREMENT `role_closure`
--
ALTER TABLE `role_closure`
    MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID', AUTO_INCREMENT=6;

--
-- 使用表AUTO_INCREMENT `role_menu`
--
ALTER TABLE `role_menu`
    MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID', AUTO_INCREMENT=219;

--
-- 使用表AUTO_INCREMENT `user`
--
ALTER TABLE `user`
    MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID', AUTO_INCREMENT=3;

--
-- 使用表AUTO_INCREMENT `user_job`
--
ALTER TABLE `user_job`
    MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID', AUTO_INCREMENT=7;

--
-- 使用表AUTO_INCREMENT `user_role`
--
ALTER TABLE `user_role`
    MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键ID', AUTO_INCREMENT=4;

--
-- 限制导出的表
--

--
-- 限制表 `department_closure`
--
ALTER TABLE `department_closure`
    ADD CONSTRAINT `department_closure_ibfk_1` FOREIGN KEY (`children`) REFERENCES `department` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `department_closure_ibfk_2` FOREIGN KEY (`parent`) REFERENCES `department` (`id`) ON DELETE CASCADE;

--
-- 限制表 `dictionary_value`
--
ALTER TABLE `dictionary_value`
    ADD CONSTRAINT `fk_dictionary_value_dict` FOREIGN KEY (`dictionary_id`) REFERENCES `dictionary` (`id`) ON DELETE CASCADE;

--
-- 限制表 `menu_closure`
--
ALTER TABLE `menu_closure`
    ADD CONSTRAINT `menu_closure_ibfk_1` FOREIGN KEY (`children`) REFERENCES `menu` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `menu_closure_ibfk_2` FOREIGN KEY (`parent`) REFERENCES `menu` (`id`) ON DELETE CASCADE;

--
-- 限制表 `role_closure`
--
ALTER TABLE `role_closure`
    ADD CONSTRAINT `role_closure_ibfk_1` FOREIGN KEY (`children`) REFERENCES `role` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `role_closure_ibfk_2` FOREIGN KEY (`parent`) REFERENCES `role` (`id`) ON DELETE CASCADE;

--
-- 限制表 `role_menu`
--
ALTER TABLE `role_menu`
    ADD CONSTRAINT `role_menu_ibfk_1` FOREIGN KEY (`menu_id`) REFERENCES `menu` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `role_menu_ibfk_2` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`) ON DELETE CASCADE;

--
-- 限制表 `user`
--
ALTER TABLE `user`
    ADD CONSTRAINT `fk_user_department` FOREIGN KEY (`department_id`) REFERENCES `department` (`id`),
  ADD CONSTRAINT `fk_user_role` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`);

--
-- 限制表 `user_job`
--
ALTER TABLE `user_job`
    ADD CONSTRAINT `user_job_ibfk_1` FOREIGN KEY (`job_id`) REFERENCES `job` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_job_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE;

--
-- 限制表 `user_role`
--
ALTER TABLE `user_role`
    ADD CONSTRAINT `user_role_ibfk_1` FOREIGN KEY (`role_id`) REFERENCES `role` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `user_role_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `user` (`id`) ON DELETE CASCADE;
COMMIT;

