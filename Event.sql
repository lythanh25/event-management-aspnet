CREATE DATABASE EventHub;
USE EventHub;
GO

/* =============================================================
   1. NHOM TO CHUC & NGUOI DUNG
   ============================================================= */

/* --- departments ----------------------------------------- */
CREATE TABLE dbo.departments (
    id              BIGINT IDENTITY(1,1) NOT NULL,
    code            NVARCHAR(20)  NOT NULL,
    name            NVARCHAR(120) NOT NULL,
    description     NVARCHAR(MAX) NULL,
    color_hex       VARCHAR(7)    NULL,
    manager_id      BIGINT        NULL,
    is_external     BIT           NOT NULL CONSTRAINT DF_dept_external DEFAULT 0,
    is_active       BIT           NOT NULL CONSTRAINT DF_dept_active   DEFAULT 1,
    created_at      DATETIME2(0)  NOT NULL CONSTRAINT DF_dept_created  DEFAULT SYSUTCDATETIME(),
    updated_at      DATETIME2(0)  NOT NULL CONSTRAINT DF_dept_updated  DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_departments      PRIMARY KEY (id),
    CONSTRAINT UQ_departments_code UNIQUE (code)
);
GO

/* --- roles ----------------------------------------------- */
CREATE TABLE dbo.roles (
    id           BIGINT IDENTITY(1,1) NOT NULL,
    code         NVARCHAR(30)  NOT NULL,
    name         NVARCHAR(80)  NOT NULL,
    permissions  NVARCHAR(MAX) NULL,
    created_at   DATETIME2(0)  NOT NULL CONSTRAINT DF_roles_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_roles      PRIMARY KEY (id),
    CONSTRAINT UQ_roles_code UNIQUE (code),
    CONSTRAINT CK_roles_permissions_json CHECK (permissions IS NULL OR ISJSON(permissions) = 1)
);
GO

/* --- users ----------------------------------------------- */
CREATE TABLE dbo.users (
    id                   BIGINT IDENTITY(1,1) NOT NULL,
    employee_code        NVARCHAR(20)  NULL,
    email                NVARCHAR(190) NOT NULL,
    email_verified_at    DATETIME2(0)  NULL,
    password_hash        NVARCHAR(255) NOT NULL,
    first_name           NVARCHAR(60)  NOT NULL,
    last_name            NVARCHAR(60)  NOT NULL,
    display_name         NVARCHAR(120) NULL,
    avatar_url           NVARCHAR(500) NULL,
    phone                NVARCHAR(20)  NULL,
    date_of_birth        DATE          NULL,
    gender               NVARCHAR(15)  NULL,
    bio                  NVARCHAR(240) NULL,
    job_title            NVARCHAR(120) NULL,
    department_id        BIGINT        NULL,
    role_id              BIGINT        NOT NULL,
    member_tier          NVARCHAR(15)  NOT NULL CONSTRAINT DF_users_tier   DEFAULT N'standard',
    joined_at            DATE          NULL,
    is_active            BIT           NOT NULL CONSTRAINT DF_users_active DEFAULT 1,
    last_login_at        DATETIME2(0)  NULL,
    remember_token       NVARCHAR(100) NULL,
    created_at           DATETIME2(0)  NOT NULL CONSTRAINT DF_users_created DEFAULT SYSUTCDATETIME(),
    updated_at           DATETIME2(0)  NOT NULL CONSTRAINT DF_users_updated DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_users                PRIMARY KEY (id),
    CONSTRAINT UQ_users_email          UNIQUE (email),
    CONSTRAINT UQ_users_employee_code  UNIQUE (employee_code),
    CONSTRAINT FK_users_department     FOREIGN KEY (department_id) REFERENCES dbo.departments(id) ON DELETE SET NULL,
    CONSTRAINT FK_users_role           FOREIGN KEY (role_id)       REFERENCES dbo.roles(id),
    CONSTRAINT CK_users_gender         CHECK (gender IS NULL OR gender IN (N'male', N'female', N'other', N'undisclosed')),
    CONSTRAINT CK_users_tier           CHECK (member_tier IN (N'standard', N'gold', N'platinum'))
);
GO

CREATE INDEX IX_users_dept_active ON dbo.users (department_id, is_active);
CREATE INDEX IX_users_role        ON dbo.users (role_id);
GO

/* FK departments.manager_id -> users.id (circular, them sau) */
ALTER TABLE dbo.departments
    ADD CONSTRAINT FK_departments_manager FOREIGN KEY (manager_id)
        REFERENCES dbo.users(id) ON DELETE NO ACTION;
GO

/* --- user_sessions --------------------------------------- */
CREATE TABLE dbo.user_sessions (
    id               UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_sess_id DEFAULT NEWID(),
    user_id          BIGINT        NOT NULL,
    device_label     NVARCHAR(120) NULL,
    device_type      NVARCHAR(10)  NULL,
    os               NVARCHAR(80)  NULL,
    browser          NVARCHAR(80)  NULL,
    ip_address       VARCHAR(45)   NULL,
    location_city    NVARCHAR(80)  NULL,
    location_country NVARCHAR(80)  NULL,
    user_agent       NVARCHAR(500) NULL,
    is_current       BIT           NOT NULL CONSTRAINT DF_sess_current DEFAULT 0,
    last_active_at   DATETIME2(0)  NULL,
    revoked_at       DATETIME2(0)  NULL,
    created_at       DATETIME2(0)  NOT NULL CONSTRAINT DF_sess_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_user_sessions       PRIMARY KEY (id),
    CONSTRAINT FK_sessions_user       FOREIGN KEY (user_id) REFERENCES dbo.users(id) ON DELETE CASCADE,
    CONSTRAINT CK_sessions_devtype    CHECK (device_type IS NULL OR device_type IN (N'desktop', N'mobile', N'tablet'))
);
GO
CREATE INDEX IX_sessions_user ON dbo.user_sessions (user_id, revoked_at);
GO

/* --- user_two_factor ------------------------------------- */
CREATE TABLE dbo.user_two_factor (
    user_id      BIGINT        NOT NULL,
    is_enabled   BIT           NOT NULL CONSTRAINT DF_2fa_enabled DEFAULT 0,
    secret       NVARCHAR(255) NULL,
    backup_codes NVARCHAR(MAX) NULL,
    enabled_at   DATETIME2(0)  NULL,
    CONSTRAINT PK_user_two_factor PRIMARY KEY (user_id),
    CONSTRAINT FK_2fa_user        FOREIGN KEY (user_id) REFERENCES dbo.users(id) ON DELETE CASCADE,
    CONSTRAINT CK_2fa_codes_json  CHECK (backup_codes IS NULL OR ISJSON(backup_codes) = 1)
);
GO

/* --- password_resets ------------------------------------- */
CREATE TABLE dbo.password_resets (
    id          BIGINT IDENTITY(1,1) NOT NULL,
    user_id     BIGINT        NOT NULL,
    token_hash  NVARCHAR(255) NOT NULL,
    expires_at  DATETIME2(0)  NOT NULL,
    used_at     DATETIME2(0)  NULL,
    created_at  DATETIME2(0)  NOT NULL CONSTRAINT DF_pwreset_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_password_resets PRIMARY KEY (id),
    CONSTRAINT FK_pwreset_user   FOREIGN KEY (user_id) REFERENCES dbo.users(id) ON DELETE CASCADE
);
GO
CREATE INDEX IX_pwreset_token ON dbo.password_resets (token_hash);
GO

/* --- oauth_accounts -------------------------------------- */
CREATE TABLE dbo.oauth_accounts (
    id                BIGINT IDENTITY(1,1) NOT NULL,
    user_id           BIGINT        NOT NULL,
    provider          NVARCHAR(15)  NOT NULL,
    provider_user_id  NVARCHAR(190) NOT NULL,
    email             NVARCHAR(190) NULL,
    access_token      NVARCHAR(MAX) NULL,
    refresh_token     NVARCHAR(MAX) NULL,
    expires_at        DATETIME2(0)  NULL,
    created_at        DATETIME2(0)  NOT NULL CONSTRAINT DF_oauth_created DEFAULT SYSUTCDATETIME(),
    updated_at        DATETIME2(0)  NOT NULL CONSTRAINT DF_oauth_updated DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_oauth_accounts    PRIMARY KEY (id),
    CONSTRAINT UQ_oauth_provider    UNIQUE (provider, provider_user_id),
    CONSTRAINT FK_oauth_user        FOREIGN KEY (user_id) REFERENCES dbo.users(id) ON DELETE CASCADE,
    CONSTRAINT CK_oauth_provider    CHECK (provider IN (N'google', N'microsoft'))
);
GO

/* --- emergency_contacts ---------------------------------- */
CREATE TABLE dbo.emergency_contacts (
    id           BIGINT IDENTITY(1,1) NOT NULL,
    user_id      BIGINT        NOT NULL,
    full_name    NVARCHAR(120) NOT NULL,
    relationship NVARCHAR(10)  NOT NULL,
    phone        NVARCHAR(20)  NOT NULL,
    is_primary   BIT           NOT NULL CONSTRAINT DF_emerg_primary DEFAULT 1,
    created_at   DATETIME2(0)  NOT NULL CONSTRAINT DF_emerg_created DEFAULT SYSUTCDATETIME(),
    updated_at   DATETIME2(0)  NOT NULL CONSTRAINT DF_emerg_updated DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_emergency_contacts PRIMARY KEY (id),
    CONSTRAINT FK_emerg_user         FOREIGN KEY (user_id) REFERENCES dbo.users(id) ON DELETE CASCADE,
    CONSTRAINT CK_emerg_relationship CHECK (relationship IN (N'parent', N'sibling', N'spouse', N'friend', N'other'))
);
GO
CREATE INDEX IX_emerg_user ON dbo.emergency_contacts (user_id);
GO

/* =============================================================
   2. NHOM SU KIEN
   ============================================================= */

/* --- event_categories ------------------------------------ */
CREATE TABLE dbo.event_categories (
    id          BIGINT IDENTITY(1,1) NOT NULL,
    code        NVARCHAR(40)  NOT NULL,
    name        NVARCHAR(120) NOT NULL,
    icon        NVARCHAR(40)  NULL,
    color_bg    VARCHAR(7)    NULL,
    color_fg    VARCHAR(7)    NULL,
    sort_order  INT           NOT NULL CONSTRAINT DF_cat_sort   DEFAULT 0,
    is_active   BIT           NOT NULL CONSTRAINT DF_cat_active DEFAULT 1,
    CONSTRAINT PK_event_categories      PRIMARY KEY (id),
    CONSTRAINT UQ_event_categories_code UNIQUE (code)
);
GO

/* --- events ---------------------------------------------- */
CREATE TABLE dbo.events (
    id                            BIGINT IDENTITY(1,1) NOT NULL,
    event_code                    NVARCHAR(20)  NOT NULL,
    slug                          NVARCHAR(190) NOT NULL,
    title                         NVARCHAR(120) NOT NULL,
    subtitle                      NVARCHAR(200) NULL,
    description                   NVARCHAR(MAX) NULL,
    objectives                    NVARCHAR(MAX) NULL,
    category_id                   BIGINT        NOT NULL,
    format                        NVARCHAR(10)  NOT NULL CONSTRAINT DF_events_format DEFAULT N'offline',
    start_at                      DATETIME2(0)  NOT NULL,
    end_at                        DATETIME2(0)  NOT NULL,
    timezone                      NVARCHAR(40)  NOT NULL CONSTRAINT DF_events_tz DEFAULT N'Asia/Ho_Chi_Minh',
    registration_opens_at         DATETIME2(0)  NULL,
    registration_deadline         DATETIME2(0)  NULL,
    location_name                 NVARCHAR(200) NULL,
    location_room                 NVARCHAR(120) NULL,
    address                       NVARCHAR(255) NULL,
    online_url                    NVARCHAR(500) NULL,
    capacity                      INT           NOT NULL,
    price                         DECIMAL(12,2) NOT NULL CONSTRAINT DF_events_price DEFAULT 0,
    original_price                DECIMAL(12,2) NULL,
    currency                      CHAR(3)       NOT NULL CONSTRAINT DF_events_currency DEFAULT 'VND',
    organizer_department_id       BIGINT        NOT NULL,
    created_by                    BIGINT        NOT NULL,
    requires_approval             BIT           NOT NULL CONSTRAINT DF_events_appr     DEFAULT 1,
    allow_waitlist                BIT           NOT NULL CONSTRAINT DF_events_waitlist DEFAULT 1,
    is_open_to_all_departments    BIT           NOT NULL CONSTRAINT DF_events_alldept  DEFAULT 1,
    banner_url                    NVARCHAR(500) NULL,
    status                        NVARCHAR(15)  NOT NULL CONSTRAINT DF_events_status DEFAULT N'draft',
    published_at                  DATETIME2(0)  NULL,
    view_count                    INT           NOT NULL CONSTRAINT DF_events_view DEFAULT 0,
    created_at                    DATETIME2(0)  NOT NULL CONSTRAINT DF_events_created DEFAULT SYSUTCDATETIME(),
    updated_at                    DATETIME2(0)  NOT NULL CONSTRAINT DF_events_updated DEFAULT SYSUTCDATETIME(),
    deleted_at                    DATETIME2(0)  NULL,
    CONSTRAINT PK_events            PRIMARY KEY (id),
    CONSTRAINT UQ_events_code       UNIQUE (event_code),
    CONSTRAINT UQ_events_slug       UNIQUE (slug),
    CONSTRAINT FK_events_category   FOREIGN KEY (category_id)             REFERENCES dbo.event_categories(id),
    CONSTRAINT FK_events_orgdept    FOREIGN KEY (organizer_department_id) REFERENCES dbo.departments(id),
    CONSTRAINT FK_events_creator    FOREIGN KEY (created_by)              REFERENCES dbo.users(id),
    CONSTRAINT CK_events_format     CHECK (format IN (N'offline', N'online', N'hybrid')),
    CONSTRAINT CK_events_status     CHECK (status IN (N'draft', N'open', N'closed', N'ended', N'cancelled')),
    CONSTRAINT CK_events_capacity   CHECK (capacity > 0),
    CONSTRAINT CK_events_timerange  CHECK (end_at > start_at),
    CONSTRAINT CK_events_objectives_json CHECK (objectives IS NULL OR ISJSON(objectives) = 1)
);
GO

CREATE INDEX IX_events_status_start ON dbo.events (status, start_at);
CREATE INDEX IX_events_category     ON dbo.events (category_id, status);
CREATE INDEX IX_events_orgdept      ON dbo.events (organizer_department_id);
CREATE INDEX IX_events_start_at     ON dbo.events (start_at);
GO

/* --- event_tags ------------------------------------------ */
CREATE TABLE dbo.event_tags (
    id           BIGINT IDENTITY(1,1) NOT NULL,
    name         NVARCHAR(80)  NOT NULL,
    slug         NVARCHAR(80)  NOT NULL,
    usage_count  INT           NOT NULL CONSTRAINT DF_tags_count   DEFAULT 0,
    created_at   DATETIME2(0)  NOT NULL CONSTRAINT DF_tags_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_event_tags      PRIMARY KEY (id),
    CONSTRAINT UQ_event_tags_name UNIQUE (name),
    CONSTRAINT UQ_event_tags_slug UNIQUE (slug)
);
GO

/* --- event_event_tags (M:N) ------------------------------ */
CREATE TABLE dbo.event_event_tags (
    event_id    BIGINT       NOT NULL,
    tag_id      BIGINT       NOT NULL,
    created_at  DATETIME2(0) NOT NULL CONSTRAINT DF_eetags_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_event_event_tags PRIMARY KEY (event_id, tag_id),
    CONSTRAINT FK_eetags_event     FOREIGN KEY (event_id) REFERENCES dbo.events(id)     ON DELETE CASCADE,
    CONSTRAINT FK_eetags_tag       FOREIGN KEY (tag_id)   REFERENCES dbo.event_tags(id) ON DELETE CASCADE
);
GO

/* --- event_allowed_departments (M:N) --------------------- */
CREATE TABLE dbo.event_allowed_departments (
    event_id      BIGINT NOT NULL,
    department_id BIGINT NOT NULL,
    CONSTRAINT PK_event_allowed_departments PRIMARY KEY (event_id, department_id),
    CONSTRAINT FK_ead_event FOREIGN KEY (event_id)      REFERENCES dbo.events(id)      ON DELETE CASCADE,
    CONSTRAINT FK_ead_dept  FOREIGN KEY (department_id) REFERENCES dbo.departments(id) ON DELETE CASCADE
);
GO

/* --- event_organizers ------------------------------------ */
CREATE TABLE dbo.event_organizers (
    id              BIGINT IDENTITY(1,1) NOT NULL,
    event_id        BIGINT       NOT NULL,
    user_id         BIGINT       NOT NULL,
    role_in_event   NVARCHAR(15) NOT NULL CONSTRAINT DF_eorg_role  DEFAULT N'co-organizer',
    added_at        DATETIME2(0) NOT NULL CONSTRAINT DF_eorg_added DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_event_organizers PRIMARY KEY (id),
    CONSTRAINT UQ_event_organizers UNIQUE (event_id, user_id),
    /* CASCADE chinh tu events; user_id NO ACTION de tranh multi-path */
    CONSTRAINT FK_eorg_event FOREIGN KEY (event_id) REFERENCES dbo.events(id) ON DELETE CASCADE,
    CONSTRAINT FK_eorg_user  FOREIGN KEY (user_id)  REFERENCES dbo.users(id)  ON DELETE NO ACTION,
    CONSTRAINT CK_eorg_role  CHECK (role_in_event IN (N'lead', N'co-organizer', N'support'))
);
GO

/* --- event_speakers -------------------------------------- */
CREATE TABLE dbo.event_speakers (
    id           BIGINT IDENTITY(1,1) NOT NULL,
    event_id     BIGINT        NOT NULL,
    user_id      BIGINT        NULL,
    full_name    NVARCHAR(120) NOT NULL,
    title        NVARCHAR(200) NULL,
    bio          NVARCHAR(MAX) NULL,
    avatar_url   NVARCHAR(500) NULL,
    tags         NVARCHAR(MAX) NULL,
    sort_order   INT           NOT NULL CONSTRAINT DF_spk_sort    DEFAULT 0,
    is_featured  BIT           NOT NULL CONSTRAINT DF_spk_feat    DEFAULT 0,
    created_at   DATETIME2(0)  NOT NULL CONSTRAINT DF_spk_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_event_speakers PRIMARY KEY (id),
    CONSTRAINT FK_spk_event      FOREIGN KEY (event_id) REFERENCES dbo.events(id) ON DELETE CASCADE,
    CONSTRAINT FK_spk_user       FOREIGN KEY (user_id)  REFERENCES dbo.users(id)  ON DELETE SET NULL,
    CONSTRAINT CK_spk_tags_json  CHECK (tags IS NULL OR ISJSON(tags) = 1)
);
GO
CREATE INDEX IX_spk_event ON dbo.event_speakers (event_id, sort_order);
GO

/* --- event_agenda_items ---------------------------------- */
CREATE TABLE dbo.event_agenda_items (
    id           BIGINT IDENTITY(1,1) NOT NULL,
    event_id     BIGINT        NOT NULL,
    start_time   DATETIME2(0)  NOT NULL,
    end_time     DATETIME2(0)  NOT NULL,
    title        NVARCHAR(200) NOT NULL,
    description  NVARCHAR(MAX) NULL,
    speaker_id   BIGINT        NULL,
    item_type    NVARCHAR(15)  NOT NULL CONSTRAINT DF_agenda_type DEFAULT N'regular',
    tag_label    NVARCHAR(120) NULL,
    sort_order   INT           NOT NULL CONSTRAINT DF_agenda_sort    DEFAULT 0,
    created_at   DATETIME2(0)  NOT NULL CONSTRAINT DF_agenda_created DEFAULT SYSUTCDATETIME(),
    updated_at   DATETIME2(0)  NOT NULL CONSTRAINT DF_agenda_updated DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_event_agenda_items PRIMARY KEY (id),
    CONSTRAINT FK_agenda_event       FOREIGN KEY (event_id)   REFERENCES dbo.events(id)         ON DELETE CASCADE,
    CONSTRAINT FK_agenda_speaker     FOREIGN KEY (speaker_id) REFERENCES dbo.event_speakers(id) ON DELETE NO ACTION,
    CONSTRAINT CK_agenda_type        CHECK (item_type IN (N'regular', N'major', N'break', N'networking')),
    CONSTRAINT CK_agenda_timerange   CHECK (end_time > start_time)
);
GO
CREATE INDEX IX_agenda_event_time ON dbo.event_agenda_items (event_id, start_time);
GO

/* --- event_media ----------------------------------------- */
CREATE TABLE dbo.event_media (
    id           BIGINT IDENTITY(1,1) NOT NULL,
    event_id     BIGINT        NOT NULL,
    media_type   NVARCHAR(15)  NOT NULL,
    url          NVARCHAR(500) NOT NULL,
    mime_type    NVARCHAR(100) NULL,
    file_size    INT           NULL,
    alt_text     NVARCHAR(255) NULL,
    sort_order   INT           NOT NULL CONSTRAINT DF_media_sort    DEFAULT 0,
    uploaded_by  BIGINT        NOT NULL,
    created_at   DATETIME2(0)  NOT NULL CONSTRAINT DF_media_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_event_media   PRIMARY KEY (id),
    CONSTRAINT FK_media_event   FOREIGN KEY (event_id)    REFERENCES dbo.events(id) ON DELETE CASCADE,
    CONSTRAINT FK_media_user    FOREIGN KEY (uploaded_by) REFERENCES dbo.users(id),
    CONSTRAINT CK_media_type    CHECK (media_type IN (N'banner', N'gallery', N'document'))
);
GO
CREATE INDEX IX_media_event ON dbo.event_media (event_id, media_type);
GO

/* =============================================================
   3. NHOM DANG KY
   ============================================================= */

/* --- event_registrations --------------------------------- */
CREATE TABLE dbo.event_registrations (
    id                  BIGINT IDENTITY(1,1) NOT NULL,
    event_id            BIGINT        NOT NULL,
    user_id             BIGINT        NOT NULL,
    status              NVARCHAR(15)  NOT NULL CONSTRAINT DF_reg_status DEFAULT N'pending',
    ticket_code         NVARCHAR(40)  NULL,
    qr_payload          NVARCHAR(255) NULL,
    registered_at       DATETIME2(0)  NOT NULL CONSTRAINT DF_reg_registered DEFAULT SYSUTCDATETIME(),
    approved_at         DATETIME2(0)  NULL,
    approved_by         BIGINT        NULL,
    rejected_at         DATETIME2(0)  NULL,
    rejected_by         BIGINT        NULL,
    rejection_reason    NVARCHAR(500) NULL,
    cancelled_at        DATETIME2(0)  NULL,
    waitlist_position   INT           NULL,
    notes               NVARCHAR(MAX) NULL,
    source              NVARCHAR(15)  NOT NULL CONSTRAINT DF_reg_source  DEFAULT N'web',
    created_at          DATETIME2(0)  NOT NULL CONSTRAINT DF_reg_created DEFAULT SYSUTCDATETIME(),
    updated_at          DATETIME2(0)  NOT NULL CONSTRAINT DF_reg_updated DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_event_registrations PRIMARY KEY (id),
    CONSTRAINT UQ_reg_event_user      UNIQUE (event_id, user_id),
    CONSTRAINT UQ_reg_ticket          UNIQUE (ticket_code),
    /* CASCADE chinh: event_id. Cac FK den users de NO ACTION tranh multi-path */
    CONSTRAINT FK_reg_event       FOREIGN KEY (event_id)    REFERENCES dbo.events(id) ON DELETE CASCADE,
    CONSTRAINT FK_reg_user        FOREIGN KEY (user_id)     REFERENCES dbo.users(id)  ON DELETE NO ACTION,
    CONSTRAINT FK_reg_approved_by FOREIGN KEY (approved_by) REFERENCES dbo.users(id)  ON DELETE NO ACTION,
    CONSTRAINT FK_reg_rejected_by FOREIGN KEY (rejected_by) REFERENCES dbo.users(id)  ON DELETE NO ACTION,
    CONSTRAINT CK_reg_status      CHECK (status IN (N'pending', N'approved', N'rejected', N'waitlist', N'cancelled')),
    CONSTRAINT CK_reg_source      CHECK (source IN (N'web', N'mobile', N'admin_added'))
);
GO

CREATE INDEX IX_reg_event_status   ON dbo.event_registrations (event_id, status);
CREATE INDEX IX_reg_user_status    ON dbo.event_registrations (user_id, status);
CREATE INDEX IX_reg_registered_at  ON dbo.event_registrations (registered_at);
GO

/* --- registration_approval_logs -------------------------- */
CREATE TABLE dbo.registration_approval_logs (
    id              BIGINT IDENTITY(1,1) NOT NULL,
    registration_id BIGINT        NOT NULL,
    action          NVARCHAR(25)  NOT NULL,
    from_status     NVARCHAR(20)  NULL,
    to_status       NVARCHAR(20)  NOT NULL,
    performed_by    BIGINT        NOT NULL,
    reason          NVARCHAR(500) NULL,
    created_at      DATETIME2(0)  NOT NULL CONSTRAINT DF_apprlog_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_registration_approval_logs PRIMARY KEY (id),
    CONSTRAINT FK_appr_reg  FOREIGN KEY (registration_id) REFERENCES dbo.event_registrations(id) ON DELETE CASCADE,
    CONSTRAINT FK_appr_user FOREIGN KEY (performed_by)    REFERENCES dbo.users(id),
    CONSTRAINT CK_appr_action CHECK (action IN (N'approved', N'rejected', N'reverted', N'moved_to_waitlist', N'cancelled'))
);
GO
CREATE INDEX IX_appr_reg_time ON dbo.registration_approval_logs (registration_id, created_at);
GO

/* --- saved_events ---------------------------------------- */
CREATE TABLE dbo.saved_events (
    user_id    BIGINT       NOT NULL,
    event_id   BIGINT       NOT NULL,
    saved_at   DATETIME2(0) NOT NULL CONSTRAINT DF_sav_saved DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_saved_events PRIMARY KEY (user_id, event_id),
    CONSTRAINT FK_sav_user     FOREIGN KEY (user_id)  REFERENCES dbo.users(id)  ON DELETE CASCADE,
    /* user da CASCADE; event de NO ACTION tranh multi-path */
    CONSTRAINT FK_sav_event    FOREIGN KEY (event_id) REFERENCES dbo.events(id) ON DELETE NO ACTION
);
GO

/* =============================================================
   4. NHOM DIEM DANH
   ============================================================= */

/* --- attendances ----------------------------------------- */
CREATE TABLE dbo.attendances (
    id                 BIGINT IDENTITY(1,1) NOT NULL,
    event_id           BIGINT        NOT NULL,
    user_id            BIGINT        NOT NULL,
    registration_id    BIGINT        NULL,
    status             NVARCHAR(15)  NOT NULL CONSTRAINT DF_att_status DEFAULT N'absent',
    checked_in_at      DATETIME2(0)  NULL,
    checked_out_at     DATETIME2(0)  NULL,
    check_in_method    NVARCHAR(15)  NULL,
    checked_in_by      BIGINT        NULL,
    is_late            BIT           NOT NULL CONSTRAINT DF_att_late    DEFAULT 0,
    notes              NVARCHAR(255) NULL,
    created_at         DATETIME2(0)  NOT NULL CONSTRAINT DF_att_created DEFAULT SYSUTCDATETIME(),
    updated_at         DATETIME2(0)  NOT NULL CONSTRAINT DF_att_updated DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_attendances        PRIMARY KEY (id),
    CONSTRAINT UQ_att_event_user     UNIQUE (event_id, user_id),
    /* CASCADE chinh qua event_id; user, registration, checked_in_by NO ACTION */
    CONSTRAINT FK_att_event FOREIGN KEY (event_id)        REFERENCES dbo.events(id)              ON DELETE CASCADE,
    CONSTRAINT FK_att_user  FOREIGN KEY (user_id)         REFERENCES dbo.users(id)               ON DELETE NO ACTION,
    CONSTRAINT FK_att_reg   FOREIGN KEY (registration_id) REFERENCES dbo.event_registrations(id) ON DELETE NO ACTION,
    CONSTRAINT FK_att_by    FOREIGN KEY (checked_in_by)   REFERENCES dbo.users(id)               ON DELETE NO ACTION,
    CONSTRAINT CK_att_status CHECK (status IN (N'absent', N'present', N'late', N'left_early')),
    CONSTRAINT CK_att_method CHECK (check_in_method IS NULL OR check_in_method IN (N'qr_scan', N'manual', N'quick_search', N'self'))
);
GO

CREATE INDEX IX_att_event_status ON dbo.attendances (event_id, status);
CREATE INDEX IX_att_checkin      ON dbo.attendances (checked_in_at);
GO

/* =============================================================
   5. NHOM THONG BAO
   ============================================================= */

/* --- notifications --------------------------------------- */
CREATE TABLE dbo.notifications (
    id              BIGINT IDENTITY(1,1) NOT NULL,
    user_id         BIGINT        NOT NULL,
    type            NVARCHAR(60)  NOT NULL,
    title           NVARCHAR(200) NOT NULL,
    body            NVARCHAR(MAX) NULL,
    link_url        NVARCHAR(500) NULL,
    event_id        BIGINT        NULL,
    registration_id BIGINT        NULL,
    priority        NVARCHAR(10)  NOT NULL CONSTRAINT DF_notif_pri     DEFAULT N'normal',
    is_read         BIT           NOT NULL CONSTRAINT DF_notif_read    DEFAULT 0,
    read_at         DATETIME2(0)  NULL,
    delivered_via   NVARCHAR(50)  NULL,
    created_at      DATETIME2(0)  NOT NULL CONSTRAINT DF_notif_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_notifications PRIMARY KEY (id),
    /* CASCADE chinh: user. Cac FK con lai NO ACTION */
    CONSTRAINT FK_notif_user  FOREIGN KEY (user_id)         REFERENCES dbo.users(id)               ON DELETE CASCADE,
    CONSTRAINT FK_notif_event FOREIGN KEY (event_id)        REFERENCES dbo.events(id)              ON DELETE NO ACTION,
    CONSTRAINT FK_notif_reg   FOREIGN KEY (registration_id) REFERENCES dbo.event_registrations(id) ON DELETE NO ACTION,
    CONSTRAINT CK_notif_pri   CHECK (priority IN (N'low', N'normal', N'high', N'urgent'))
);
GO

CREATE INDEX IX_notif_user_unread ON dbo.notifications (user_id, is_read, created_at DESC);
CREATE INDEX IX_notif_type        ON dbo.notifications (type, created_at);
GO

/* --- notification_channels ------------------------------- */
CREATE TABLE dbo.notification_channels (
    id                 BIGINT IDENTITY(1,1) NOT NULL,
    user_id            BIGINT        NOT NULL,
    channel            NVARCHAR(10)  NOT NULL,
    is_enabled         BIT           NOT NULL CONSTRAINT DF_nchan_enabled DEFAULT 1,
    connected_account  NVARCHAR(255) NULL,
    connected_at       DATETIME2(0)  NULL,
    created_at         DATETIME2(0)  NOT NULL CONSTRAINT DF_nchan_created DEFAULT SYSUTCDATETIME(),
    updated_at         DATETIME2(0)  NOT NULL CONSTRAINT DF_nchan_updated DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_notification_channels PRIMARY KEY (id),
    CONSTRAINT UQ_nchan_user_channel    UNIQUE (user_id, channel),
    CONSTRAINT FK_nchan_user            FOREIGN KEY (user_id) REFERENCES dbo.users(id) ON DELETE CASCADE,
    CONSTRAINT CK_nchan_channel         CHECK (channel IN (N'email', N'inapp', N'push', N'slack'))
);
GO

/* --- notification_preferences ---------------------------- */
CREATE TABLE dbo.notification_preferences (
    id                 BIGINT IDENTITY(1,1) NOT NULL,
    user_id            BIGINT       NOT NULL,
    notification_type  NVARCHAR(60) NOT NULL,
    via_email          BIT          NOT NULL CONSTRAINT DF_npref_email   DEFAULT 1,
    via_inapp          BIT          NOT NULL CONSTRAINT DF_npref_inapp   DEFAULT 1,
    via_push           BIT          NOT NULL CONSTRAINT DF_npref_push    DEFAULT 0,
    via_slack          BIT          NOT NULL CONSTRAINT DF_npref_slack   DEFAULT 0,
    updated_at         DATETIME2(0) NOT NULL CONSTRAINT DF_npref_updated DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_notification_preferences PRIMARY KEY (id),
    CONSTRAINT UQ_npref_user_type          UNIQUE (user_id, notification_type),
    CONSTRAINT FK_npref_user               FOREIGN KEY (user_id) REFERENCES dbo.users(id) ON DELETE CASCADE
);
GO

/* --- quiet_hours_settings -------------------------------- */
CREATE TABLE dbo.quiet_hours_settings (
    user_id        BIGINT       NOT NULL,
    is_enabled     BIT          NOT NULL CONSTRAINT DF_quiet_enabled  DEFAULT 0,
    start_time     TIME(0)      NOT NULL CONSTRAINT DF_quiet_start    DEFAULT '22:00:00',
    end_time       TIME(0)      NOT NULL CONSTRAINT DF_quiet_end      DEFAULT '07:00:00',
    timezone       NVARCHAR(40) NOT NULL CONSTRAINT DF_quiet_tz       DEFAULT N'Asia/Ho_Chi_Minh',
    apply_weekends BIT          NOT NULL CONSTRAINT DF_quiet_weekends DEFAULT 1,
    updated_at     DATETIME2(0) NOT NULL CONSTRAINT DF_quiet_updated  DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_quiet_hours_settings PRIMARY KEY (user_id),
    CONSTRAINT FK_quiet_user           FOREIGN KEY (user_id) REFERENCES dbo.users(id) ON DELETE CASCADE
);
GO

/* =============================================================
   6. NHOM HE THONG
   ============================================================= */

/* --- activity_logs --------------------------------------- */
CREATE TABLE dbo.activity_logs (
    id           BIGINT IDENTITY(1,1) NOT NULL,
    user_id      BIGINT        NULL,
    action       NVARCHAR(80)  NOT NULL,
    entity_type  NVARCHAR(60)  NULL,
    entity_id    BIGINT        NULL,
    metadata     NVARCHAR(MAX) NULL,
    ip_address   VARCHAR(45)   NULL,
    user_agent   NVARCHAR(500) NULL,
    created_at   DATETIME2(0)  NOT NULL CONSTRAINT DF_log_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_activity_logs PRIMARY KEY (id),
    CONSTRAINT FK_log_user      FOREIGN KEY (user_id) REFERENCES dbo.users(id) ON DELETE SET NULL,
    CONSTRAINT CK_log_meta_json CHECK (metadata IS NULL OR ISJSON(metadata) = 1)
);
GO

CREATE INDEX IX_log_user_time ON dbo.activity_logs (user_id, created_at);
CREATE INDEX IX_log_entity    ON dbo.activity_logs (entity_type, entity_id, created_at);
GO

/* --- event_questions (Hoi dap) --------------------------- */
CREATE TABLE dbo.event_questions (
    id            BIGINT IDENTITY(1,1) NOT NULL,
    event_id      BIGINT        NOT NULL,
    user_id       BIGINT        NOT NULL,
    parent_id     BIGINT        NULL,
    content       NVARCHAR(MAX) NOT NULL,
    is_answered   BIT           NOT NULL CONSTRAINT DF_qa_answered DEFAULT 0,
    is_pinned     BIT           NOT NULL CONSTRAINT DF_qa_pinned   DEFAULT 0,
    upvotes       INT           NOT NULL CONSTRAINT DF_qa_upvotes  DEFAULT 0,
    created_at    DATETIME2(0)  NOT NULL CONSTRAINT DF_qa_created  DEFAULT SYSUTCDATETIME(),
    updated_at    DATETIME2(0)  NOT NULL CONSTRAINT DF_qa_updated  DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_event_questions PRIMARY KEY (id),
    CONSTRAINT FK_qa_event  FOREIGN KEY (event_id)  REFERENCES dbo.events(id)          ON DELETE CASCADE,
    CONSTRAINT FK_qa_user   FOREIGN KEY (user_id)   REFERENCES dbo.users(id)           ON DELETE NO ACTION,
    /* self-reference: bat buoc NO ACTION */
    CONSTRAINT FK_qa_parent FOREIGN KEY (parent_id) REFERENCES dbo.event_questions(id) ON DELETE NO ACTION
);
GO
CREATE INDEX IX_qa_event ON dbo.event_questions (event_id, created_at);
GO

/* =============================================================
   7. TRIGGERS - Tu cap nhat cot updated_at
   ============================================================= */

CREATE OR ALTER TRIGGER dbo.tr_users_updated
ON dbo.users
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE u SET updated_at = SYSUTCDATETIME()
    FROM dbo.users u INNER JOIN inserted i ON u.id = i.id;
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_events_updated
ON dbo.events
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE e SET updated_at = SYSUTCDATETIME()
    FROM dbo.events e INNER JOIN inserted i ON e.id = i.id;
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_event_registrations_updated
ON dbo.event_registrations
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE r SET updated_at = SYSUTCDATETIME()
    FROM dbo.event_registrations r INNER JOIN inserted i ON r.id = i.id;
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_attendances_updated
ON dbo.attendances
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE a SET updated_at = SYSUTCDATETIME()
    FROM dbo.attendances a INNER JOIN inserted i ON a.id = i.id;
END;
GO

CREATE OR ALTER TRIGGER dbo.tr_departments_updated
ON dbo.departments
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE d SET updated_at = SYSUTCDATETIME()
    FROM dbo.departments d INNER JOIN inserted i ON d.id = i.id;
END;
GO

/* =============================================================
   8. SEED DATA - Du lieu khoi tao
   ============================================================= */

INSERT INTO dbo.roles (code, name, permissions) VALUES
    (N'admin',     N'Quản trị viên hệ thống', N'["*"]'),
    (N'organizer', N'Ban tổ chức',            N'["event.create","event.update","event.approve","attendance.manage"]'),
    (N'employee',  N'Nhân viên',              N'["event.view","event.register","profile.update"]');
GO

INSERT INTO dbo.departments (code, name, color_hex, is_external) VALUES
    (N'IT',   N'Công nghệ thông tin',  '#2A4D86', 0),
    (N'MKT',  N'Marketing',            '#B36F12', 0),
    (N'HR',   N'Nhân sự',              '#5A3FA8', 0),
    (N'FIN',  N'Tài chính',            '#1F6E45', 0),
    (N'OPS',  N'Vận hành',             '#8C3024', 0),
    (N'TECH', N'Kỹ thuật & Công nghệ', '#6B7DA1', 0),
    (N'EXT',  N'Đối tác ngoài',        '#8C5A2C', 1);
GO

INSERT INTO dbo.event_categories (code, name, icon, color_bg, color_fg, sort_order) VALUES
    (N'tech',          N'Công nghệ',           N'cpu',            '#FBE5E2', '#8C3024', 1),
    (N'workshop',      N'Hội thảo / Workshop', N'book-open',      '#FBF1E5', '#8C5A2C', 2),
    (N'conference',    N'Hội nghị',            N'mic',            '#FBF1E5', '#8C5A2C', 3),
    (N'training',      N'Đào tạo nội bộ',      N'graduation-cap', '#FCEAD0', '#8C5A1F', 4),
    (N'team_building', N'Team Building',       N'users',          '#E5F0E5', '#2E5A2E', 5),
    (N'anniversary',   N'Lễ kỷ niệm',          N'cake',           '#F5E1F0', '#5A2A55', 6),
    (N'culture',       N'Văn hoá',             N'book',           '#F0E5D0', '#6B5530', 7),
    (N'hr',            N'Nhân sự',             N'users',          '#E5F0E5', '#2E5A2E', 8);
GO

/* =============================================================
   9. VIEWS huu ich cho Dashboard
   ============================================================= */

/* Thong ke dang ky theo su kien */
CREATE OR ALTER VIEW dbo.v_event_registration_stats AS
SELECT
    e.id                        AS event_id,
    e.event_code,
    e.title,
    e.capacity,
    SUM(CASE WHEN r.status = N'approved' THEN 1 ELSE 0 END) AS approved_count,
    SUM(CASE WHEN r.status = N'pending'  THEN 1 ELSE 0 END) AS pending_count,
    SUM(CASE WHEN r.status = N'rejected' THEN 1 ELSE 0 END) AS rejected_count,
    SUM(CASE WHEN r.status = N'waitlist' THEN 1 ELSE 0 END) AS waitlist_count,
    e.capacity
        - SUM(CASE WHEN r.status IN (N'approved', N'pending') THEN 1 ELSE 0 END) AS available_slots
FROM dbo.events e
LEFT JOIN dbo.event_registrations r ON r.event_id = e.id
GROUP BY e.id, e.event_code, e.title, e.capacity;
GO

/* Thong ke diem danh */
CREATE OR ALTER VIEW dbo.v_event_attendance_stats AS
SELECT
    e.id          AS event_id,
    e.event_code,
    e.title,
    SUM(CASE WHEN a.status = N'present' THEN 1 ELSE 0 END) AS present_count,
    SUM(CASE WHEN a.status = N'late'    THEN 1 ELSE 0 END) AS late_count,
    SUM(CASE WHEN a.status = N'absent'  THEN 1 ELSE 0 END) AS absent_count,
    COUNT(a.id)                                            AS total_attendees
FROM dbo.events e
LEFT JOIN dbo.attendances a ON a.event_id = e.id
GROUP BY e.id, e.event_code, e.title;
GO
INSERT INTO dbo.users (
    employee_code,      -- Mã nhân viên, dùng làm MẬT KHẨU đăng nhập
    email,              -- Địa chỉ email dùng để đăng nhập
    email_verified_at,  -- Thời điểm email được xác minh
    password_hash,      -- Mật khẩu đã băm SHA2-256 từ employee_code
    first_name,         -- Họ (và tên đệm) của người dùng
    last_name,          -- Tên chính của người dùng
    display_name,       -- Tên hiển thị trên giao diện
    avatar_url,         -- Đường dẫn ảnh đại diện
    phone,              -- Số điện thoại liên hệ
    date_of_birth,      -- Ngày tháng năm sinh
    gender,             -- Giới tính: male / female / other / undisclosed
    bio,                -- Giới thiệu ngắn về bản thân
    job_title,          -- Chức danh công việc
    department_id,      -- FK → departments.id (1=IT,2=MKT,3=HR,4=FIN,5=OPS,6=TECH,7=EXT)
    role_id,            -- FK → roles.id (1=admin, 2=organizer, 3=employee)
    member_tier,        -- Hạng thành viên: standard / gold / platinum
    joined_at,          -- Ngày chính thức gia nhập công ty
    is_active,          -- Trạng thái: 1=đang hoạt động, 0=vô hiệu hóa
    last_login_at       -- Thời điểm đăng nhập gần nhất
) VALUES
/* ───────────── 2 QUẢN TRỊ VIÊN ───────────── */
(N'NV001',N'nguyen.van.an@company.vn',   '2023-01-10 08:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV001'),2),N'Nguyễn Văn', N'An',    N'Nguyễn Văn An',    N'https://i.pravatar.cc/150?img=1', N'0901234501','1985-03-15',N'male',  N'Quản trị hệ thống EventHub toàn công ty.',            N'System Administrator',       1,1,N'platinum','2020-01-15',1,'2025-05-19 08:31:00'),
(N'NV002',N'tran.thi.binh@company.vn',   '2023-01-10 08:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV002'),2),N'Trần Thị',  N'Bình',  N'Trần Thị Bình',    N'https://i.pravatar.cc/150?img=2', N'0901234502','1988-07-22',N'female',N'Phụ trách vận hành hệ thống và quản lý người dùng.',  N'Operations Manager',         3,1,N'platinum','2020-02-01',1,'2025-05-18 17:45:00'),
/* ───────────── 5 BAN TỔ CHỨC ───────────── */
(N'NV003',N'le.van.cuong@company.vn',    '2023-02-01 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV003'),2),N'Lê Văn',   N'Cường', N'Lê Văn Cường',    N'https://i.pravatar.cc/150?img=3', N'0901234503','1990-11-05',N'male',  N'Trưởng nhóm tổ chức sự kiện phòng IT.',              N'IT Event Lead',              1,2,N'gold',    '2021-03-10',1,'2025-05-19 07:55:00'),
(N'NV004',N'pham.thi.dung@company.vn',   '2023-02-15 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV004'),2),N'Phạm Thị', N'Dung',  N'Phạm Thị Dung',   N'https://i.pravatar.cc/150?img=4', N'0901234504','1992-04-18',N'female',N'Chuyên viên tổ chức sự kiện phòng Marketing.',        N'Marketing Event Specialist', 2,2,N'gold',    '2021-04-01',1,'2025-05-18 16:20:00'),
(N'NV005',N'hoang.van.em@company.vn',    '2023-03-01 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV005'),2),N'Hoàng Văn',N'Em',    N'Hoàng Văn Em',    N'https://i.pravatar.cc/150?img=5', N'0901234505','1991-09-30',N'male',  N'Phụ trách tổ chức sự kiện nội bộ phòng Nhân sự.',    N'HR Event Specialist',        3,2,N'gold',    '2021-05-15',1,'2025-05-17 14:00:00'),
(N'NV006',N'vu.thi.phuong@company.vn',   '2023-03-15 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV006'),2),N'Vũ Thị',   N'Phương',N'Vũ Thị Phương',  N'https://i.pravatar.cc/150?img=6', N'0901234506','1989-12-10',N'female',N'Điều phối các hội nghị và sự kiện tài chính.',        N'Finance Event Coordinator',  4,2,N'gold',    '2021-06-01',1,'2025-05-19 09:10:00'),
(N'NV007',N'dang.van.giang@company.vn',  '2023-04-01 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV007'),2),N'Đặng Văn', N'Giang', N'Đặng Văn Giang',  N'https://i.pravatar.cc/150?img=7', N'0901234507','1993-06-25',N'male',  N'Phụ trách tổ chức các sự kiện vận hành.',            N'Operations Event Lead',      5,2,N'gold',    '2021-07-10',1,'2025-05-16 11:30:00'),
/* ───────────── 18 NHÂN VIÊN + 1 ĐỐI TÁC ───────────── */
(N'NV008',N'ngo.thi.ha@company.vn',      '2023-05-01 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV008'),2),N'Ngô Thị',  N'Hà',    N'Ngô Thị Hà',      N'https://i.pravatar.cc/150?img=8', N'0901234508','1995-02-14',N'female',N'Lập trình viên frontend tại phòng IT.',               N'Frontend Developer',         1,3,N'standard','2022-01-10',1,'2025-05-19 08:05:00'),
(N'NV009',N'bui.van.ich@company.vn',     '2023-05-15 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV009'),2),N'Bùi Văn',  N'Ích',   N'Bùi Văn Ích',     N'https://i.pravatar.cc/150?img=9', N'0901234509','1994-08-03',N'male',  N'Kỹ sư phần cứng tại phòng Kỹ thuật.',                N'Hardware Engineer',          6,3,N'standard','2022-02-01',1,'2025-05-18 09:30:00'),
(N'NV010',N'do.thi.khanh@company.vn',    '2023-06-01 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV010'),2),N'Đỗ Thị',   N'Khánh', N'Đỗ Thị Khánh',    N'https://i.pravatar.cc/150?img=10',N'0901234510','1996-05-20',N'female',N'Chuyên viên truyền thông mạng xã hội.',               N'Social Media Specialist',    2,3,N'gold',    '2022-03-15',1,'2025-05-19 07:45:00'),
(N'NV011',N'ho.van.long@company.vn',     '2023-06-15 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV011'),2),N'Hồ Văn',   N'Long',  N'Hồ Văn Long',     N'https://i.pravatar.cc/150?img=11',N'0901234511','1990-10-08',N'male',  N'Kỹ sư DevOps phụ trách hạ tầng cloud.',              N'DevOps Engineer',            1,3,N'standard','2022-04-01',1,'2025-05-17 16:00:00'),
(N'NV012',N'mai.thi.mai@company.vn',     '2023-07-01 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV012'),2),N'Mai Thị',  N'Mai',   N'Mai Thị Mai',     N'https://i.pravatar.cc/150?img=12',N'0901234512','1993-01-17',N'female',N'Chuyên viên tuyển dụng nhân sự.',                    N'HR Recruiter',               3,3,N'standard','2022-05-10',1,'2025-05-18 10:15:00'),
(N'NV013',N'trinh.van.nam@company.vn',   '2023-07-15 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV013'),2),N'Trịnh Văn',N'Nam',   N'Trịnh Văn Nam',   N'https://i.pravatar.cc/150?img=13',N'0901234513','1987-11-29',N'male',  N'Kế toán trưởng phụ trách báo cáo tài chính.',        N'Senior Accountant',          4,3,N'standard','2022-06-01',1,'2025-05-16 08:50:00'),
(N'NV014',N'duong.thi.oanh@company.vn',  '2023-08-01 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV014'),2),N'Dương Thị',N'Oanh',  N'Dương Thị Oanh',  N'https://i.pravatar.cc/150?img=14',N'0901234514','1997-03-11',N'female',N'Chuyên viên quảng cáo và content marketing.',         N'Content Marketer',           2,3,N'standard','2022-07-10',1,'2025-05-19 08:55:00'),
(N'NV015',N'ly.van.phong@company.vn',    '2023-08-15 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV015'),2),N'Lý Văn',   N'Phong', N'Lý Văn Phong',    N'https://i.pravatar.cc/150?img=15',N'0901234515','1991-07-04',N'male',  N'Kỹ sư IoT và hệ thống nhúng.',                       N'IoT Engineer',               6,3,N'standard','2022-08-01',1,'2025-05-18 14:45:00'),
(N'NV016',N'phan.thi.quynh@company.vn',  '2023-09-01 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV016'),2),N'Phan Thị', N'Quỳnh', N'Phan Thị Quỳnh',  N'https://i.pravatar.cc/150?img=16',N'0901234516','1994-06-19',N'female',N'Chuyên viên quản lý kho và logistics.',               N'Logistics Coordinator',      5,3,N'standard','2022-09-15',1,'2025-05-17 11:20:00'),
(N'NV017',N'cao.van.rong@company.vn',    '2023-09-15 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV017'),2),N'Cao Văn',  N'Rồng',  N'Cao Văn Rồng',    N'https://i.pravatar.cc/150?img=17',N'0901234517','1989-09-12',N'male',  N'Lập trình viên backend API và microservices.',        N'Backend Developer',          1,3,N'gold',    '2022-10-01',1,'2025-05-19 07:30:00'),
(N'NV018',N'dinh.thi.suong@company.vn',  '2023-10-01 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV018'),2),N'Đinh Thị', N'Sương', N'Đinh Thị Sương',  N'https://i.pravatar.cc/150?img=18',N'0901234518','1996-12-02',N'female',N'Phân tích tài chính và lập kế hoạch ngân sách.',     N'Financial Analyst',          4,3,N'standard','2022-11-10',1,'2025-05-18 13:30:00'),
(N'NV019',N'to.van.tuan@company.vn',     '2023-10-15 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV019'),2),N'Tô Văn',   N'Tuấn',  N'Tô Văn Tuấn',     N'https://i.pravatar.cc/150?img=19',N'0901234519','1993-04-27',N'male',  N'Chuyên viên SEO và digital marketing.',               N'SEO Specialist',             2,3,N'standard','2022-12-01',1,'2025-05-17 09:00:00'),
(N'NV020',N'chu.thi.uyen@company.vn',    '2023-11-01 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV020'),2),N'Chu Thị',  N'Uyên',  N'Chu Thị Uyên',    N'https://i.pravatar.cc/150?img=20',N'0901234520','1995-08-16',N'female',N'Chuyên viên phúc lợi và quan hệ lao động.',          N'HR Benefits Specialist',     3,3,N'standard','2023-01-10',1,'2025-05-18 15:10:00'),
(N'NV021',N'luu.van.vinh@company.vn',    '2023-11-15 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV021'),2),N'Lưu Văn',  N'Vinh',  N'Lưu Văn Vinh',    N'https://i.pravatar.cc/150?img=21',N'0901234521','1990-02-28',N'male',  N'Kỹ sư mạng và bảo mật thông tin.',                   N'Network Security Engineer',  6,3,N'standard','2023-02-01',1,'2025-05-16 17:00:00'),
(N'NV022',N'nghiem.thi.xuan@company.vn', '2023-12-01 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV022'),2),N'Nghiêm Thị',N'Xuân', N'Nghiêm Thị Xuân', N'https://i.pravatar.cc/150?img=22',N'0901234522','1997-05-09',N'female',N'Điều phối viên vận hành và hỗ trợ khách hàng.',      N'Operations Coordinator',     5,3,N'standard','2023-03-10',1,'2025-05-19 08:00:00'),
(N'NV023',N'kim.van.yen@company.vn',     '2024-01-10 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV023'),2),N'Kim Văn',  N'Yên',   N'Kim Văn Yên',     N'https://i.pravatar.cc/150?img=23',N'0901234523','1992-11-14',N'male',  N'Lập trình viên mobile iOS/Android.',                 N'Mobile Developer',           1,3,N'standard','2023-04-01',1,'2025-05-18 08:20:00'),
(N'NV024',N'tu.thi.diem@company.vn',     '2024-02-01 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV024'),2),N'Từ Thị',   N'Diễm',  N'Từ Thị Diễm',     N'https://i.pravatar.cc/150?img=24',N'0901234524','1998-01-23',N'female',N'Nhân viên thiết kế đồ họa và UI/UX.',                N'UX/UI Designer',             2,3,N'standard','2023-05-15',1,'2025-05-17 13:00:00'),
(N'NV025',N'alex.johnson@partner.com',   '2024-03-01 09:00:00',CONVERT(NVARCHAR(255),HASHBYTES('SHA2_256',N'NV025'),2),N'Alex',     N'Johnson',N'Alex Johnson',    N'https://i.pravatar.cc/150?img=25',N'0901234525','1985-06-30',N'male',  N'Đối tác công nghệ từ bên ngoài công ty.',             N'Technology Partner',         7,3,N'standard','2024-03-01',1,'2025-05-15 10:00:00');
GO

/* ================================================================
   CẬP NHẬT QUẢN LÝ PHÒNG BAN (departments.manager_id)
   Thực hiện sau khi users đã được chèn
   ================================================================ */
UPDATE dbo.departments SET manager_id=(SELECT id FROM dbo.users WHERE employee_code=N'NV003') WHERE code=N'IT';   -- Lê Văn Cường – Trưởng nhóm IT
UPDATE dbo.departments SET manager_id=(SELECT id FROM dbo.users WHERE employee_code=N'NV004') WHERE code=N'MKT';  -- Phạm Thị Dung – Trưởng Marketing
UPDATE dbo.departments SET manager_id=(SELECT id FROM dbo.users WHERE employee_code=N'NV002') WHERE code=N'HR';   -- Trần Thị Bình – Trưởng Nhân sự
UPDATE dbo.departments SET manager_id=(SELECT id FROM dbo.users WHERE employee_code=N'NV006') WHERE code=N'FIN';  -- Vũ Thị Phương – Trưởng Tài chính
UPDATE dbo.departments SET manager_id=(SELECT id FROM dbo.users WHERE employee_code=N'NV007') WHERE code=N'OPS';  -- Đặng Văn Giang – Trưởng Vận hành
UPDATE dbo.departments SET manager_id=(SELECT id FROM dbo.users WHERE employee_code=N'NV005') WHERE code=N'TECH'; -- Hoàng Văn Em – Trưởng Kỹ thuật
UPDATE dbo.departments SET manager_id=(SELECT id FROM dbo.users WHERE employee_code=N'NV001') WHERE code=N'EXT';  -- Nguyễn Văn An – Quản lý Đối tác ngoài
GO

/* ================================================================
   BẢNG: dbo.events  – Sự kiện
   20 bản ghi: 8 đã kết thúc + 10 đang mở + 2 bản nháp
   ================================================================ */
INSERT INTO dbo.events (
    event_code,                   -- Mã sự kiện, duy nhất trong hệ thống
    slug,                         -- Đường dẫn thân thiện URL (không dấu)
    title,                        -- Tiêu đề chính của sự kiện
    subtitle,                     -- Tiêu đề phụ mô tả ngắn gọn
    description,                  -- Mô tả chi tiết nội dung sự kiện
    objectives,                   -- Mục tiêu sự kiện (JSON array)
    category_id,                  -- FK → event_categories.id
    format,                       -- Hình thức: offline / online / hybrid
    start_at,                     -- Thời gian bắt đầu
    end_at,                       -- Thời gian kết thúc
    timezone,                     -- Múi giờ áp dụng
    registration_opens_at,        -- Thời điểm mở đăng ký
    registration_deadline,        -- Hạn chót đăng ký
    location_name,                -- Tên địa điểm tổ chức
    location_room,                -- Phòng / khu vực cụ thể
    address,                      -- Địa chỉ đầy đủ
    online_url,                   -- Đường link họp trực tuyến (nếu có)
    capacity,                     -- Số lượng người tham dự tối đa
    price,                        -- Giá vé (0 = miễn phí)
    original_price,               -- Giá gốc trước khi giảm
    currency,                     -- Đơn vị tiền tệ
    organizer_department_id,      -- FK → departments.id (phòng ban chủ trì)
    created_by,                   -- FK → users.id (người tạo sự kiện)
    requires_approval,            -- 1=cần duyệt đăng ký, 0=tự động duyệt
    allow_waitlist,               -- 1=cho phép danh sách chờ khi hết chỗ
    is_open_to_all_departments,   -- 1=mở cho tất cả phòng ban, 0=giới hạn
    banner_url,                   -- URL ảnh banner sự kiện
    status,                       -- Trạng thái: draft/open/closed/ended/cancelled
    published_at,                 -- Thời điểm công bố sự kiện
    view_count                    -- Số lượt xem trang sự kiện
) VALUES
/* ── SỰ KIỆN ĐÃ KẾT THÚC (status = 'ended') ── */
(N'EVT-2025-001',N'techtalk-q1-2025-ai-machine-learning',
 N'TechTalk Q1 2025 – Xu Hướng AI & Machine Learning',N'Cập nhật công nghệ AI mới nhất cho kỹ sư phần mềm',
 N'Buổi chia sẻ nội bộ về xu hướng AI/ML trong năm 2025, ứng dụng thực tiễn tại doanh nghiệp và demo live model.',
 N'["Hiểu xu hướng AI 2025","Áp dụng ML vào dự án thực tế","Networking với đội ngũ kỹ thuật"]',
 1,N'offline','2025-01-15 09:00:00','2025-01-15 12:00:00',N'Asia/Ho_Chi_Minh',
 '2024-12-20 08:00:00','2025-01-13 23:59:00',N'Hội trường A – Trụ sở chính',N'Phòng 301',N'123 Nguyễn Huệ, Quận 1, TP.HCM',
 NULL,80,0,NULL,'VND',1,3,1,1,1,N'https://picsum.photos/seed/evt1/1200/400',N'ended','2024-12-21 08:00:00',245),

(N'EVT-2025-002',N'workshop-excel-nang-cao-phan-tich-du-lieu',
 N'Workshop Excel Nâng Cao – Phân Tích Dữ Liệu',N'Từ bảng tính cơ bản đến Power Query và Pivot Table chuyên nghiệp',
 N'Workshop thực hành kỹ năng Excel nâng cao: hàm phức tạp, Power Query, Pivot Table và kết nối dữ liệu ngoài.',
 N'["Thành thạo hàm Index/Match/XLookup","Xây dựng Pivot Table","Làm sạch dữ liệu với Power Query"]',
 2,N'offline','2025-02-05 13:30:00','2025-02-05 17:30:00',N'Asia/Ho_Chi_Minh',
 '2025-01-10 08:00:00','2025-02-03 23:59:00',N'Phòng đào tạo B – Trụ sở chính',N'Phòng 201',N'123 Nguyễn Huệ, Quận 1, TP.HCM',
 NULL,30,0,NULL,'VND',4,6,1,0,0,N'https://picsum.photos/seed/evt2/1200/400',N'ended','2025-01-11 08:00:00',112),

(N'EVT-2025-003',N'hoi-nghi-digital-marketing-2025',
 N'Hội Nghị Digital Marketing 2025',N'Chiến lược marketing số trong kỷ nguyên AI',
 N'Hội nghị thường niên của phòng Marketing, tổng kết 2024 và xây dựng chiến lược cho năm 2025.',
 N'["Đánh giá hiệu quả chiến dịch 2024","Xây dựng chiến lược 2025","Giới thiệu công cụ AI Marketing"]',
 3,N'hybrid','2025-02-20 08:00:00','2025-02-20 17:00:00',N'Asia/Ho_Chi_Minh',
 '2025-01-25 08:00:00','2025-02-18 23:59:00',N'Trung tâm hội nghị Gem Center',N'Phòng Diamond',N'8 Nguyễn Bỉnh Khiêm, Quận 1, TP.HCM',
 N'https://meet.company.vn/mkt-conf-2025',120,0,NULL,'VND',2,4,1,1,0,N'https://picsum.photos/seed/evt3/1200/400',N'ended','2025-01-26 08:00:00',389),

(N'EVT-2025-004',N'dao-tao-an-toan-thong-tin-iso27001',
 N'Đào Tạo An Toàn Thông Tin – ISO 27001 Awareness',N'Nâng cao nhận thức bảo mật thông tin cho toàn thể nhân viên',
 N'Chương trình đào tạo bắt buộc về an toàn thông tin theo chuẩn ISO 27001, dành cho tất cả nhân viên công ty.',
 N'["Hiểu rủi ro bảo mật thông tin","Nhận biết phishing và social engineering","Thực hành chính sách mật khẩu mạnh"]',
 4,N'online','2025-03-05 09:00:00','2025-03-05 11:30:00',N'Asia/Ho_Chi_Minh',
 '2025-02-10 08:00:00','2025-03-03 23:59:00',NULL,NULL,NULL,
 N'https://meet.company.vn/security-training-2025',200,0,NULL,'VND',1,3,0,0,1,N'https://picsum.photos/seed/evt4/1200/400',N'ended','2025-02-11 08:00:00',520),

(N'EVT-2025-005',N'team-building-mua-xuan-2025',
 N'Team Building Mùa Xuân 2025 – Kết Nối & Phát Triển',N'Hoạt động gắn kết đội nhóm ngoài trời chào đón năm mới',
 N'Chuyến dã ngoại team building kết hợp các trò chơi tập thể, hoạt động ngoài trời và gala dinner ấm cúng.',
 N'["Tăng cường tinh thần đồng đội","Xây dựng mối quan hệ liên phòng ban","Tạo kỷ niệm đáng nhớ"]',
 5,N'offline','2025-03-15 07:00:00','2025-03-15 22:00:00',N'Asia/Ho_Chi_Minh',
 '2025-02-15 08:00:00','2025-03-10 23:59:00',N'Khu du lịch sinh thái Bửu Long',N'Khu ngoài trời – Khu A',N'Bửu Long, Biên Hòa, Đồng Nai',
 NULL,150,0,NULL,'VND',3,5,1,1,1,N'https://picsum.photos/seed/evt5/1200/400',N'ended','2025-02-16 08:00:00',478),

(N'EVT-2025-006',N'le-ky-niem-5-nam-thanh-lap-cong-ty',
 N'Lễ Kỷ Niệm 5 Năm Thành Lập Công Ty',N'Chào mừng chặng đường 5 năm xây dựng và phát triển',
 N'Buổi lễ long trọng kỷ niệm 5 năm thành lập với sự tham dự của ban lãnh đạo, toàn thể nhân viên và đối tác chiến lược.',
 N'["Nhìn lại hành trình 5 năm","Tôn vinh nhân viên xuất sắc","Công bố định hướng chiến lược mới"]',
 6,N'offline','2025-04-01 18:00:00','2025-04-01 22:00:00',N'Asia/Ho_Chi_Minh',
 '2025-02-20 08:00:00','2025-03-28 23:59:00',N'Khách sạn Caravelle Saigon',N'Grand Ballroom – Tầng 8',N'19 Công Trường Lam Sơn, Quận 1, TP.HCM',
 NULL,200,0,NULL,'VND',5,7,1,0,1,N'https://picsum.photos/seed/evt6/1200/400',N'ended','2025-02-21 08:00:00',612),

(N'EVT-2025-007',N'tuan-le-van-hoa-doanh-nghiep-2025',
 N'Tuần Lễ Văn Hoá Doanh Nghiệp 2025',N'Tôn vinh sự đa dạng văn hoá và giá trị cốt lõi',
 N'Chuỗi sự kiện trong 3 ngày gồm triển lãm ẩm thực, biểu diễn văn nghệ và các hoạt động tương tác.',
 N'["Lan toả văn hoá công ty","Gắn kết nhân viên đa vùng miền","Tôn vinh sự đa dạng văn hoá"]',
 7,N'offline','2025-04-14 08:00:00','2025-04-16 17:00:00',N'Asia/Ho_Chi_Minh',
 '2025-03-01 08:00:00','2025-04-11 23:59:00',N'Sân ngoài trời – Trụ sở chính',N'Khu vực A & B',N'123 Nguyễn Huệ, Quận 1, TP.HCM',
 NULL,300,0,NULL,'VND',3,5,0,0,1,N'https://picsum.photos/seed/evt7/1200/400',N'ended','2025-03-02 08:00:00',731),

(N'EVT-2025-008',N'ngay-hoi-tuyen-dung-noi-bo-2025',
 N'Ngày Hội Tuyển Dụng Nội Bộ 2025',N'Cơ hội thăng tiến và chuyển vị trí trong nội bộ',
 N'Sự kiện giới thiệu các vị trí tuyển dụng nội bộ, mỗi phòng ban thuyết trình về cơ hội thăng tiến.',
 N'["Giới thiệu vị trí tuyển dụng nội bộ","Hỗ trợ định hướng nghề nghiệp","Kết nối nhân sự liên phòng"]',
 8,N'offline','2025-04-25 09:00:00','2025-04-25 16:00:00',N'Asia/Ho_Chi_Minh',
 '2025-04-01 08:00:00','2025-04-23 23:59:00',N'Hội trường A – Trụ sở chính',N'Toàn bộ Hội trường A',N'123 Nguyễn Huệ, Quận 1, TP.HCM',
 NULL,100,0,NULL,'VND',3,5,0,0,1,N'https://picsum.photos/seed/evt8/1200/400',N'ended','2025-04-02 08:00:00',298),

/* ── SỰ KIỆN ĐANG MỞ ĐĂNG KÝ (status = 'open') ── */
(N'EVT-2025-009',N'workshop-python-tu-co-ban-den-nang-cao',
 N'Workshop Python – Từ Cơ Bản Đến Nâng Cao',N'Khóa học thực hành Python dành cho nhân viên phi kỹ thuật',
 N'Workshop 2 ngày: biến, vòng lặp, hàm, xử lý dữ liệu với Pandas và visualisation bằng Matplotlib.',
 N'["Viết được script Python cơ bản","Xử lý dữ liệu bằng Pandas","Vẽ biểu đồ với Matplotlib"]',
 2,N'offline','2025-06-07 09:00:00','2025-06-08 17:00:00',N'Asia/Ho_Chi_Minh',
 '2025-05-01 08:00:00','2025-06-04 23:59:00',N'Phòng đào tạo B – Trụ sở chính',N'Phòng 202 – Lab máy tính',N'123 Nguyễn Huệ, Quận 1, TP.HCM',
 NULL,25,0,NULL,'VND',1,3,1,1,1,N'https://picsum.photos/seed/evt9/1200/400',N'open','2025-05-01 08:00:00',187),

(N'EVT-2025-010',N'hoi-nghi-iot-edge-computing-2025',
 N'Hội Nghị IoT & Edge Computing 2025',N'Kết nối vạn vật – Tương lai của hạ tầng thông minh',
 N'Hội nghị chuyên sâu về IoT và Edge Computing, trình bày case study thực tế và xu hướng công nghệ 2025.',
 N'["Nắm bắt xu hướng IoT 2025","Trao đổi giải pháp Edge Computing","Kết nối cộng đồng kỹ sư IoT"]',
 1,N'hybrid','2025-06-20 09:00:00','2025-06-20 17:00:00',N'Asia/Ho_Chi_Minh',
 '2025-05-10 08:00:00','2025-06-17 23:59:00',N'Bitexco Financial Tower',N'Tầng 6 – Phòng Hall A',N'2 Hải Triều, Quận 1, TP.HCM',
 N'https://meet.company.vn/iot-2025',100,0,NULL,'VND',6,7,1,1,0,N'https://picsum.photos/seed/evt10/1200/400',N'open','2025-05-11 08:00:00',234),

(N'EVT-2025-011',N'dao-tao-ky-nang-thuyet-trinh-chuyen-nghiep',
 N'Đào Tạo Kỹ Năng Thuyết Trình Chuyên Nghiệp',N'Tự tin trình bày và thuyết phục trong mọi tình huống',
 N'Khóa đào tạo kỹ năng mềm về thuyết trình, ngôn ngữ cơ thể và thiết kế slide PowerPoint hiệu quả.',
 N'["Xây dựng cấu trúc bài thuyết trình","Kiểm soát lo lắng khi nói trước đám đông","Thiết kế slide chuyên nghiệp"]',
 4,N'offline','2025-06-25 13:00:00','2025-06-25 17:00:00',N'Asia/Ho_Chi_Minh',
 '2025-05-15 08:00:00','2025-06-22 23:59:00',N'Phòng họp C – Trụ sở chính',N'Phòng C01',N'123 Nguyễn Huệ, Quận 1, TP.HCM',
 NULL,40,0,NULL,'VND',3,5,1,1,1,N'https://picsum.photos/seed/evt11/1200/400',N'open','2025-05-16 08:00:00',156),

(N'EVT-2025-012',N'techtalk-q2-2025-microservices-docker',
 N'TechTalk Q2 2025 – Microservices & Docker',N'Deep dive vào kiến trúc container hoá và Kubernetes',
 N'Chuỗi TechTalk quý 2 tập trung vào kiến trúc phần mềm hiện đại: microservices, Docker và CI/CD.',
 N'["Hiểu kiến trúc microservices","Triển khai ứng dụng với Docker","Vận hành Kubernetes cơ bản"]',
 1,N'offline','2025-07-10 09:00:00','2025-07-10 12:00:00',N'Asia/Ho_Chi_Minh',
 '2025-06-01 08:00:00','2025-07-07 23:59:00',N'Hội trường A – Trụ sở chính',N'Phòng 301',N'123 Nguyễn Huệ, Quận 1, TP.HCM',
 NULL,80,0,NULL,'VND',1,3,1,1,1,N'https://picsum.photos/seed/evt12/1200/400',N'open','2025-06-01 08:00:00',98),

(N'EVT-2025-013',N'workshop-design-thinking-doi-moi-sang-tao',
 N'Workshop Design Thinking – Đổi Mới Sáng Tạo',N'Tư duy thiết kế để giải quyết vấn đề kinh doanh',
 N'Workshop thực hành 5 bước Design Thinking: Empathise, Define, Ideate, Prototype, Test áp dụng vào dự án thực.',
 N'["Áp dụng 5 bước Design Thinking","Xây dựng prototype nhanh","Kiểm tra giả thuyết với người dùng"]',
 2,N'offline','2025-07-18 09:00:00','2025-07-18 17:00:00',N'Asia/Ho_Chi_Minh',
 '2025-06-10 08:00:00','2025-07-15 23:59:00',N'Không gian sáng tạo D – Trụ sở chính',N'Design Lab D01',N'123 Nguyễn Huệ, Quận 1, TP.HCM',
 NULL,30,0,NULL,'VND',2,4,1,1,1,N'https://picsum.photos/seed/evt13/1200/400',N'open','2025-06-11 08:00:00',87),

(N'EVT-2025-014',N'hoi-nghi-tai-chinh-nua-nam-2025',
 N'Hội Nghị Tài Chính Nửa Năm 2025',N'Đánh giá kết quả kinh doanh 6 tháng đầu năm',
 N'Hội nghị nội bộ đánh giá kết quả tài chính H1/2025 và điều chỉnh kế hoạch ngân sách nửa năm còn lại.',
 N'["Đánh giá hiệu quả tài chính H1/2025","Phân tích biến động chi phí và doanh thu","Điều chỉnh ngân sách H2/2025"]',
 3,N'offline','2025-07-25 09:00:00','2025-07-25 16:00:00',N'Asia/Ho_Chi_Minh',
 '2025-06-20 08:00:00','2025-07-22 23:59:00',N'Phòng Board – Trụ sở chính',N'Board Room tầng 10',N'123 Nguyễn Huệ, Quận 1, TP.HCM',
 NULL,50,0,NULL,'VND',4,6,1,0,0,N'https://picsum.photos/seed/evt14/1200/400',N'open','2025-06-21 08:00:00',76),

(N'EVT-2025-015',N'dao-tao-git-cicd-pipeline-developer',
 N'Đào Tạo Git & CI/CD Pipeline Cho Developer',N'Quản lý source code và tự động hoá quy trình phát triển',
 N'Khóa đào tạo thực hành Git workflow nâng cao và thiết lập CI/CD pipeline với GitHub Actions và Jenkins.',
 N'["Thành thạo Git branching strategy","Thiết lập pipeline CI/CD","Tích hợp automated testing"]',
 4,N'online','2025-07-03 14:00:00','2025-07-03 17:00:00',N'Asia/Ho_Chi_Minh',
 '2025-06-01 08:00:00','2025-07-01 23:59:00',NULL,NULL,NULL,
 N'https://meet.company.vn/git-cicd-2025',60,0,NULL,'VND',1,3,0,1,1,N'https://picsum.photos/seed/evt15/1200/400',N'open','2025-06-01 09:00:00',134),

(N'EVT-2025-016',N'workshop-content-marketing-viet-de-ban-hang',
 N'Workshop Content Marketing – Viết Để Bán Hàng',N'Kỹ thuật tạo nội dung thu hút và chuyển đổi khách hàng',
 N'Workshop thực hành các kỹ thuật viết content marketing: copywriting, storytelling và tối ưu SEO content.',
 N'["Nắm vững kỹ thuật copywriting","Xây dựng content calendar hiệu quả","Tối ưu content cho SEO"]',
 2,N'offline','2025-07-12 09:00:00','2025-07-12 12:00:00',N'Asia/Ho_Chi_Minh',
 '2025-06-05 08:00:00','2025-07-09 23:59:00',N'Phòng đào tạo E – Trụ sở chính',N'Phòng E01',N'123 Nguyễn Huệ, Quận 1, TP.HCM',
 NULL,35,0,NULL,'VND',2,4,1,1,0,N'https://picsum.photos/seed/evt16/1200/400',N'open','2025-06-05 09:00:00',92),

(N'EVT-2025-017',N'team-building-cuoi-nam-2025-cung-nhau-tien-buoc',
 N'Team Building Cuối Năm 2025 – Cùng Nhau Tiến Bước',N'Kết thúc năm bằng những trải nghiệm đáng nhớ cùng đồng nghiệp',
 N'Chuyến team building 2 ngày 1 đêm tại Đà Lạt, kết hợp hoạt động ngoài trời và gala dinner tổng kết năm.',
 N'["Gắn kết đội ngũ toàn công ty","Nghỉ dưỡng và nạp lại năng lượng","Tổng kết thành tích năm 2025"]',
 5,N'offline','2025-11-28 06:00:00','2025-11-29 22:00:00',N'Asia/Ho_Chi_Minh',
 '2025-09-01 08:00:00','2025-11-20 23:59:00',N'Ana Mandara Đà Lạt Resort & Spa',N'Toàn khu nghỉ dưỡng',N'Lê Lai, Phường 5, Đà Lạt, Lâm Đồng',
 NULL,200,0,NULL,'VND',3,5,1,1,1,N'https://picsum.photos/seed/evt17/1200/400',N'open','2025-09-01 08:00:00',45),

/* ── BẢN NHÁP (status = 'draft') ── */
(N'EVT-2025-018',N'hoi-nghi-cong-nghe-q3-2025',
 N'Hội Nghị Công Nghệ Q3 2025',N'Cập nhật xu hướng công nghệ và lộ trình kỹ thuật quý 3',
 N'Hội nghị nội bộ phòng TECH và IT, trình bày kết quả nghiên cứu công nghệ mới và kế hoạch triển khai.',
 N'["Cập nhật xu hướng công nghệ mới","Thảo luận roadmap kỹ thuật Q3","Đánh giá hiệu suất hạ tầng"]',
 3,N'offline','2025-08-15 09:00:00','2025-08-15 17:00:00',N'Asia/Ho_Chi_Minh',
 '2025-07-01 08:00:00','2025-08-12 23:59:00',N'Hội trường A – Trụ sở chính',N'Phòng 302',N'123 Nguyễn Huệ, Quận 1, TP.HCM',
 NULL,60,0,NULL,'VND',6,3,1,1,0,N'https://picsum.photos/seed/evt18/1200/400',N'draft',NULL,0),

(N'EVT-2025-019',N'ngay-nhan-vien-2025-ton-vinh-cong-hien',
 N'Ngày Nhân Viên 2025 – Tôn Vinh Những Cống Hiến',N'Gala dinner tri ân toàn thể cán bộ nhân viên',
 N'Chương trình gala dinner thường niên tri ân nhân viên, trao giải thưởng xuất sắc và biểu diễn văn nghệ.',
 N'["Tôn vinh nhân viên xuất sắc 2025","Trao giải thưởng cống hiến","Gắn kết tinh thần đồng đội"]',
 6,N'offline','2025-12-20 18:00:00','2025-12-20 22:30:00',N'Asia/Ho_Chi_Minh',
 '2025-10-01 08:00:00','2025-12-15 23:59:00',N'Intercontinental Saigon Hotel',N'Grand Ballroom – Tầng 5',N'Corner of Hai Ba Trung & Le Duan, Quận 1, TP.HCM',
 NULL,250,0,NULL,'VND',3,2,1,0,1,N'https://picsum.photos/seed/evt19/1200/400',N'draft',NULL,0),

(N'EVT-2025-020',N'dao-tao-pccc-an-toan-lao-dong-2025',
 N'Đào Tạo PCCC & An Toàn Lao Động 2025',N'Trang bị kiến thức PCCC và sơ cứu cho toàn bộ nhân viên',
 N'Khóa đào tạo bắt buộc theo quy định pháp luật về phòng cháy chữa cháy và an toàn lao động.',
 N'["Nhận biết và xử lý tình huống cháy nổ","Sử dụng thiết bị PCCC đúng cách","Kỹ năng sơ cứu cơ bản"]',
 4,N'offline','2025-09-10 08:00:00','2025-09-10 12:00:00',N'Asia/Ho_Chi_Minh',
 '2025-08-01 08:00:00','2025-09-08 23:59:00',N'Sân ngoài trời – Trụ sở chính',N'Khu vực tập kết an toàn B',N'123 Nguyễn Huệ, Quận 1, TP.HCM',
 NULL,200,0,NULL,'VND',5,7,0,0,1,N'https://picsum.photos/seed/evt20/1200/400',N'draft',NULL,0);
GO

/* ================================================================
   BẢNG: dbo.event_tags  – Thẻ tag phân loại sự kiện
   20 bản ghi
   ================================================================ */
INSERT INTO dbo.event_tags (
    name,          -- Tên hiển thị của tag
    slug,          -- Dạng slug không dấu dùng trong URL
    usage_count    -- Số sự kiện đang sử dụng tag này
) VALUES
(N'AI & Machine Learning', N'ai-machine-learning',  12),
(N'Cloud Computing',       N'cloud-computing',       9),
(N'DevOps',                N'devops',                7),
(N'Python',                N'python',                6),
(N'JavaScript',            N'javascript',            5),
(N'Digital Marketing',     N'digital-marketing',     8),
(N'Branding',              N'branding',              4),
(N'Content Creation',      N'content-creation',      6),
(N'Leadership',            N'leadership',            10),
(N'Teamwork',              N'teamwork',              11),
(N'Excel & Power BI',      N'excel-power-bi',        5),
(N'IoT',                   N'iot',                   4),
(N'Cybersecurity',         N'cybersecurity',         6),
(N'UX/UI Design',          N'ux-ui-design',          5),
(N'Project Management',    N'project-management',    7),
(N'Agile & Scrum',         N'agile-scrum',           6),
(N'Data Analysis',         N'data-analysis',         8),
(N'Communication Skills',  N'communication-skills',  9),
(N'Personal Development',  N'personal-development',  11),
(N'Networking',            N'networking',            7);
GO

/* ================================================================
   BẢNG: dbo.event_event_tags  – Liên kết sự kiện ↔ tag (M:N)
   22 bản ghi
   ================================================================ */
INSERT INTO dbo.event_event_tags (event_id, tag_id) VALUES
(1,  1),  -- TechTalk Q1  ↔ AI & Machine Learning
(1, 20),  -- TechTalk Q1  ↔ Networking
(2, 11),  -- Excel WS     ↔ Excel & Power BI
(2, 17),  -- Excel WS     ↔ Data Analysis
(3,  6),  -- Conf MKT     ↔ Digital Marketing
(3,  8),  -- Conf MKT     ↔ Content Creation
(4, 13),  -- Security     ↔ Cybersecurity
(5, 10),  -- Team Build   ↔ Teamwork
(5,  9),  -- Team Build   ↔ Leadership
(6,  9),  -- Anniversary  ↔ Leadership
(7, 10),  -- Culture Week ↔ Teamwork
(9,  4),  -- Python WS    ↔ Python
(9, 17),  -- Python WS    ↔ Data Analysis
(10,12),  -- IoT Conf     ↔ IoT
(10, 2),  -- IoT Conf     ↔ Cloud Computing
(11,18),  -- Presentation ↔ Communication Skills
(12, 3),  -- TechTalk Q2  ↔ DevOps
(12, 2),  -- TechTalk Q2  ↔ Cloud Computing
(13,14),  -- Design Think ↔ UX/UI Design
(15, 3),  -- Git CI/CD    ↔ DevOps
(16, 6),  -- Content MKT  ↔ Digital Marketing
(16, 8);  -- Content MKT  ↔ Content Creation
GO

/* ================================================================
   BẢNG: dbo.event_allowed_departments  – Phòng ban được phép tham dự
   Chỉ áp dụng khi is_open_to_all_departments = 0
   ================================================================ */
INSERT INTO dbo.event_allowed_departments (event_id, department_id) VALUES
-- EVT-002 (Excel WS): chỉ FIN và IT
(2, 4),   -- FIN được phép tham dự Excel WS
(2, 1),   -- IT  được phép tham dự Excel WS
-- EVT-003 (Conf MKT): MKT + EXT
(3, 2),   -- MKT
(3, 7),   -- EXT (đối tác)
-- EVT-010 (IoT Conf): TECH + IT
(10, 6),  -- TECH
(10, 1),  -- IT
-- EVT-014 (FIN Hội nghị): FIN + HR (kế hoạch)
(14, 4),  -- FIN
(14, 3),  -- HR
-- EVT-016 (Content MKT WS): MKT + IT (để làm content kỹ thuật)
(16, 2),  -- MKT
(16, 1);  -- IT
GO

/* ================================================================
   BẢNG: dbo.event_organizers  – Ban tổ chức từng sự kiện
   22 bản ghi
   ================================================================ */
INSERT INTO dbo.event_organizers (
    event_id,       -- FK → events.id
    user_id,        -- FK → users.id (thành viên ban tổ chức)
    role_in_event   -- Vai trò: lead / co-organizer / support
) VALUES
(1, 3, N'lead'),        (1, 11, N'support'),    (1, 17, N'support'),
(2, 6, N'lead'),        (2, 13, N'co-organizer'),
(3, 4, N'lead'),        (3, 10, N'co-organizer'),(3, 14, N'support'),
(4, 3, N'lead'),        (4, 21, N'co-organizer'),
(5, 5, N'lead'),        (5, 12, N'co-organizer'),(5, 20, N'support'),
(6, 7, N'lead'),        (6, 2,  N'co-organizer'),
(7, 5, N'lead'),        (7, 12, N'support'),
(8, 5, N'lead'),        (8, 20, N'co-organizer'),
(9, 3, N'lead'),        (9, 23, N'co-organizer'),
(10,7, N'lead');
GO

/* ================================================================
   BẢNG: dbo.event_speakers  – Diễn giả / Người trình bày
   20 bản ghi
   ================================================================ */
INSERT INTO dbo.event_speakers (
    event_id,     -- FK → events.id
    user_id,      -- FK → users.id (NULL nếu là khách mời bên ngoài)
    full_name,    -- Họ tên đầy đủ của diễn giả
    title,        -- Chức danh / vai trò của diễn giả
    bio,          -- Tiểu sử ngắn
    avatar_url,   -- URL ảnh đại diện
    tags,         -- Mảng JSON các chủ đề chuyên môn
    sort_order,   -- Thứ tự hiển thị
    is_featured   -- 1 = diễn giả nổi bật được đặt đầu trang
) VALUES
(1,  3,  N'Lê Văn Cường',    N'IT Event Lead – Công ty',           N'Chuyên gia AI/ML với 7 năm kinh nghiệm phát triển sản phẩm.',               N'https://i.pravatar.cc/150?img=3', N'["AI","Machine Learning","Python"]',0,1),
(1,  17, N'Cao Văn Rồng',    N'Backend Developer – Công ty',       N'Kỹ sư backend với kinh nghiệm xây dựng API phục vụ AI model.',               N'https://i.pravatar.cc/150?img=17',N'["API","Microservices","Python"]',1,0),
(1,  NULL,N'Nguyễn Minh Trí',N'AI Engineer – FPT Software',        N'Chuyên gia AI đến từ FPT Software, tác giả của 3 bài báo khoa học về NLP.',  N'https://i.pravatar.cc/150?img=30',N'["NLP","LLM","AI Research"]',     2,1),
(2,  6,  N'Vũ Thị Phương',   N'Finance Event Coordinator',         N'Chuyên gia Excel với chứng chỉ Microsoft Office Specialist.',               N'https://i.pravatar.cc/150?img=6', N'["Excel","Power Query","Finance"]',0,1),
(3,  4,  N'Phạm Thị Dung',   N'Marketing Event Specialist',        N'5 năm kinh nghiệm digital marketing, chuyên về chiến lược đa kênh.',         N'https://i.pravatar.cc/150?img=4', N'["Digital Marketing","SEO","Analytics"]',0,1),
(3,  NULL,N'Trần Hoàng Khoa', N'Head of Growth – Shopee Vietnam',   N'Phụ trách tăng trưởng user tại Shopee với 8 năm kinh nghiệm marketing.',     N'https://i.pravatar.cc/150?img=31',N'["Growth Hacking","Data-driven Marketing"]',1,1),
(4,  3,  N'Lê Văn Cường',    N'IT Event Lead & Security Champion', N'Chứng chỉ CEH, phụ trách chương trình bảo mật nội bộ.',                      N'https://i.pravatar.cc/150?img=3', N'["Cybersecurity","ISO27001","Phishing"]',0,1),
(4,  21, N'Lưu Văn Vinh',    N'Network Security Engineer',         N'Kỹ sư bảo mật mạng với 6 năm kinh nghiệm, chứng chỉ CISSP.',                N'https://i.pravatar.cc/150?img=21',N'["Network Security","Firewall","VPN"]',1,1),
(5,  5,  N'Hoàng Văn Em',    N'HR Event Specialist',               N'Chuyên gia team building với kinh nghiệm tổ chức 50+ sự kiện ngoài trời.',   N'https://i.pravatar.cc/150?img=5', N'["Team Building","Leadership","Soft Skills"]',0,1),
(6,  1,  N'Nguyễn Văn An',   N'System Administrator – CEO',        N'Người đồng sáng lập và dẫn dắt công ty qua 5 năm phát triển.',               N'https://i.pravatar.cc/150?img=1', N'["Leadership","Strategy","Innovation"]',0,1),
(9,  3,  N'Lê Văn Cường',    N'IT Event Lead',                     N'Chuyên gia Python với 5 năm kinh nghiệm data engineering.',                  N'https://i.pravatar.cc/150?img=3', N'["Python","Data Engineering","Pandas"]',0,1),
(9,  23, N'Kim Văn Yên',     N'Mobile Developer',                  N'Lập trình viên có kinh nghiệm Python automation và scripting.',              N'https://i.pravatar.cc/150?img=23',N'["Python","Automation","Mobile"]',1,0),
(10, 15, N'Lý Văn Phong',    N'IoT Engineer',                      N'Kỹ sư IoT với 4 năm kinh nghiệm triển khai hệ thống nhúng thực tế.',         N'https://i.pravatar.cc/150?img=15',N'["IoT","Embedded Systems","Edge AI"]',0,1),
(10, 9,  N'Bùi Văn Ích',     N'Hardware Engineer',                 N'Kỹ sư phần cứng chuyên về thiết kế board mạch IoT.',                         N'https://i.pravatar.cc/150?img=9', N'["Hardware","PCB Design","IoT"]',1,0),
(10,NULL, N'Phạm Duy Anh',   N'IoT Solution Architect – Siemens VN',N'Kiến trúc sư giải pháp IoT cấp doanh nghiệp, diễn giả tại nhiều hội thảo.', N'https://i.pravatar.cc/150?img=32',N'["IoT","Industry 4.0","Edge Computing"]',2,1),
(11, 5,  N'Hoàng Văn Em',    N'HR Event Specialist',               N'Trainer chuyên về kỹ năng mềm và phát triển bản thân.',                      N'https://i.pravatar.cc/150?img=5', N'["Communication","Presentation","Soft Skills"]',0,1),
(12, 11, N'Hồ Văn Long',     N'DevOps Engineer',                   N'Kỹ sư DevOps với chứng chỉ CKA (Certified Kubernetes Administrator).',        N'https://i.pravatar.cc/150?img=11',N'["Docker","Kubernetes","CI/CD"]',0,1),
(12, 3,  N'Lê Văn Cường',    N'IT Event Lead',                     N'Architect hệ thống microservices với 7 năm kinh nghiệm.',                    N'https://i.pravatar.cc/150?img=3', N'["Microservices","Architecture","Kafka"]',1,1),
(13, 4,  N'Phạm Thị Dung',   N'Marketing Event Specialist',        N'Facilitator Design Thinking được chứng nhận bởi IDEO.',                      N'https://i.pravatar.cc/150?img=4', N'["Design Thinking","Innovation","UX"]',0,1),
(15, 11, N'Hồ Văn Long',     N'DevOps Engineer',                   N'Chuyên gia Git workflow và CI/CD automation.',                               N'https://i.pravatar.cc/150?img=11',N'["Git","GitHub Actions","Jenkins"]',0,1);
GO

/* ================================================================
   BẢNG: dbo.event_agenda_items  – Lịch trình chi tiết sự kiện
   25 bản ghi
   ================================================================ */
INSERT INTO dbo.event_agenda_items (
    event_id,    -- FK → events.id
    start_time,  -- Thời gian bắt đầu mục lịch trình
    end_time,    -- Thời gian kết thúc mục lịch trình
    title,       -- Tên / tiêu đề mục lịch trình
    description, -- Mô tả chi tiết nội dung
    speaker_id,  -- FK → event_speakers.id (diễn giả phụ trách)
    item_type,   -- Loại: regular / major / break / networking
    tag_label,   -- Nhãn tag hiển thị (vd: "Keynote", "Workshop")
    sort_order   -- Thứ tự hiển thị trong chương trình
) VALUES
-- Lịch trình EVT-001 (TechTalk Q1 2025)
(1,'2025-01-15 09:00:00','2025-01-15 09:15:00', N'Đón tiếp & Đăng ký',         N'Check-in, nhận tài liệu và tham quan khu vực trưng bày.',                     NULL,N'regular',   N'Khai mạc',  1),
(1,'2025-01-15 09:15:00','2025-01-15 09:30:00', N'Phát biểu khai mạc',          N'Ban lãnh đạo chào mừng đại biểu và giới thiệu chương trình.',                  NULL,N'major',    N'Khai mạc',  2),
(1,'2025-01-15 09:30:00','2025-01-15 10:30:00', N'Keynote: Xu hướng AI 2025',   N'Tổng quan các đột phá AI và ML đang định hình lại ngành công nghệ.',            1,  N'major',    N'Keynote',   3),
(1,'2025-01-15 10:30:00','2025-01-15 10:45:00', N'Giải lao & Networking',       N'Cà phê và kết nối với diễn giả.',                                              NULL,N'break',    N'Nghỉ giải lao',4),
(1,'2025-01-15 10:45:00','2025-01-15 11:45:00', N'Ứng dụng ML trong dự án thực', N'Demo live: xây dựng model dự đoán bằng Python và scikit-learn.',               2,  N'regular',  N'Talk',      5),
(1,'2025-01-15 11:45:00','2025-01-15 12:00:00', N'Q&A và Tổng kết',             N'Phiên hỏi đáp trực tiếp với diễn giả.',                                        NULL,N'networking',N'Q&A',       6),

-- Lịch trình EVT-003 (Hội nghị Digital Marketing)
(3,'2025-02-20 08:00:00','2025-02-20 08:30:00', N'Đăng ký & Trưng bày',         N'Check-in, nhận tài liệu và tham quan gian hàng đối tác.',                     NULL,N'regular',  N'Khai mạc',  1),
(3,'2025-02-20 08:30:00','2025-02-20 09:30:00', N'Tổng kết chiến dịch 2024',    N'Báo cáo kết quả KPI các kênh marketing trong năm 2024.',                       5,  N'major',    N'Report',    2),
(3,'2025-02-20 09:30:00','2025-02-20 10:30:00', N'Keynote: AI trong Marketing', N'Cách các thương hiệu lớn đang sử dụng AI để cá nhân hoá trải nghiệm.',          6,  N'major',    N'Keynote',   3),
(3,'2025-02-20 10:30:00','2025-02-20 10:45:00', N'Giải lao',                    N'Nghỉ giải lao, thưởng thức refreshment.',                                      NULL,N'break',    N'Nghỉ giải lao',4),
(3,'2025-02-20 10:45:00','2025-02-20 12:00:00', N'Workshop: Xây dựng kế hoạch', N'Chia nhóm thảo luận và xây dựng kế hoạch marketing Q1/2025.',                  5,  N'regular',  N'Workshop',  5),

-- Lịch trình EVT-005 (Team Building)
(5,'2025-03-15 07:00:00','2025-03-15 08:00:00', N'Xe đưa đón xuất phát',        N'Tập trung tại trụ sở, xe xuất phát lúc 7h00.',                                 NULL,N'regular',  N'Logistics', 1),
(5,'2025-03-15 09:00:00','2025-03-15 11:30:00', N'Trò chơi phá băng & Teamwork', N'Các trò chơi ngoài trời theo đội nhóm liên phòng ban.',                        9,  N'major',    N'Activity',  2),
(5,'2025-03-15 11:30:00','2025-03-15 13:00:00', N'Tiệc trưa BBQ tập thể',       N'Ăn trưa BBQ ngoài trời, giao lưu tự do.',                                      NULL,N'break',    N'Ăn uống',   3),
(5,'2025-03-15 13:00:00','2025-03-15 17:00:00', N'Thử thách thể thao tập thể',  N'Bóng đá, kéo co, bắn cung và các môn thể thao tập thể.',                       9,  N'regular',  N'Activity',  4),
(5,'2025-03-15 19:00:00','2025-03-15 22:00:00', N'Gala Dinner & Văn nghệ',      N'Bữa tiệc tối ấm cúng, trao giải đội thắng và chương trình văn nghệ.',           NULL,N'major',    N'Gala',      5),

-- Lịch trình EVT-009 (Python Workshop)
(9,'2025-06-07 09:00:00','2025-06-07 09:15:00', N'Giới thiệu chương trình',     N'Mục tiêu, phương pháp học và setup môi trường.',                               11, N'regular',  N'Setup',     1),
(9,'2025-06-07 09:15:00','2025-06-07 12:00:00', N'Python cơ bản',               N'Biến, kiểu dữ liệu, điều kiện, vòng lặp và hàm.',                              11, N'regular',  N'Lab',       2),
(9,'2025-06-07 12:00:00','2025-06-07 13:00:00', N'Nghỉ trưa',                   N'Break trưa.',                                                                  NULL,N'break',    N'Nghỉ trưa', 3),
(9,'2025-06-07 13:00:00','2025-06-07 17:00:00', N'Python nâng cao – Pandas',    N'Đọc dữ liệu CSV, lọc, nhóm và tổng hợp dữ liệu với Pandas.',                   11, N'regular',  N'Lab',       4),
(9,'2025-06-08 09:00:00','2025-06-08 12:00:00', N'Visualisation với Matplotlib', N'Vẽ biểu đồ line, bar, pie và scatter plot từ dữ liệu thực.',                   12, N'regular',  N'Lab',       5),
(9,'2025-06-08 13:00:00','2025-06-08 16:00:00', N'Dự án thực hành nhóm',        N'Chia nhóm phân tích dataset thực tế và báo cáo kết quả.',                      11, N'major',    N'Project',   6),
(9,'2025-06-08 16:00:00','2025-06-08 17:00:00', N'Thuyết trình & Trao chứng chỉ',N'Nhóm thuyết trình kết quả, trao chứng chỉ hoàn thành.',                       NULL,N'major',    N'Closing',   7);
GO

/* ================================================================
   BẢNG: dbo.event_media  – Hình ảnh / tài liệu đính kèm sự kiện
   20 bản ghi
   ================================================================ */
INSERT INTO dbo.event_media (
    event_id,    -- FK → events.id
    media_type,  -- Loại media: banner / gallery / document
    url,         -- Đường dẫn file hoặc URL
    mime_type,   -- Kiểu MIME của file
    file_size,   -- Kích thước file (bytes)
    alt_text,    -- Văn bản mô tả thay thế ảnh (SEO, accessibility)
    sort_order,  -- Thứ tự hiển thị
    uploaded_by  -- FK → users.id (người upload)
) VALUES
(1, N'banner',   N'https://picsum.photos/seed/evt1b/1200/400',   N'image/jpeg', 245000, N'Banner TechTalk Q1 2025 AI ML',             0, 3),
(1, N'gallery',  N'https://picsum.photos/seed/evt1g1/800/600',   N'image/jpeg', 180000, N'Ảnh diễn giả trình bày keynote',            1, 3),
(1, N'gallery',  N'https://picsum.photos/seed/evt1g2/800/600',   N'image/jpeg', 165000, N'Ảnh khán giả đặt câu hỏi',                  2, 3),
(1, N'document', N'https://cdn.company.vn/docs/techtalk-q1-2025-slides.pdf', N'application/pdf', 3200000, N'Slide TechTalk Q1 2025', 0, 3),
(2, N'banner',   N'https://picsum.photos/seed/evt2b/1200/400',   N'image/jpeg', 220000, N'Banner Workshop Excel',                     0, 6),
(2, N'document', N'https://cdn.company.vn/docs/excel-advanced-workbook.xlsx', N'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 1800000, N'File thực hành Excel', 0, 6),
(3, N'banner',   N'https://picsum.photos/seed/evt3b/1200/400',   N'image/jpeg', 280000, N'Banner Hội nghị Digital Marketing 2025',    0, 4),
(3, N'gallery',  N'https://picsum.photos/seed/evt3g1/800/600',   N'image/jpeg', 195000, N'Ảnh diễn giả thuyết trình',                 1, 4),
(3, N'document', N'https://cdn.company.vn/docs/mkt-conf-2025-report.pdf',    N'application/pdf', 5100000, N'Báo cáo hội nghị MKT 2025', 0, 4),
(5, N'banner',   N'https://picsum.photos/seed/evt5b/1200/400',   N'image/jpeg', 310000, N'Banner Team Building Mùa Xuân 2025',        0, 5),
(5, N'gallery',  N'https://picsum.photos/seed/evt5g1/800/600',   N'image/jpeg', 210000, N'Ảnh hoạt động ngoài trời',                  1, 5),
(5, N'gallery',  N'https://picsum.photos/seed/evt5g2/800/600',   N'image/jpeg', 198000, N'Ảnh gala dinner đội nhóm',                  2, 5),
(5, N'gallery',  N'https://picsum.photos/seed/evt5g3/800/600',   N'image/jpeg', 175000, N'Ảnh trò chơi kéo co',                       3, 5),
(6, N'banner',   N'https://picsum.photos/seed/evt6b/1200/400',   N'image/jpeg', 295000, N'Banner Lễ kỷ niệm 5 năm',                  0, 7),
(6, N'gallery',  N'https://picsum.photos/seed/evt6g1/800/600',   N'image/jpeg', 225000, N'Ảnh lễ kỷ niệm và trao giải',               1, 7),
(9, N'banner',   N'https://picsum.photos/seed/evt9b/1200/400',   N'image/jpeg', 190000, N'Banner Workshop Python',                    0, 3),
(9, N'document', N'https://cdn.company.vn/docs/python-workshop-handbook.pdf',N'application/pdf', 2400000, N'Tài liệu Workshop Python', 0, 3),
(10,N'banner',   N'https://picsum.photos/seed/evt10b/1200/400',  N'image/jpeg', 265000, N'Banner Hội nghị IoT 2025',                 0, 7),
(12,N'banner',   N'https://picsum.photos/seed/evt12b/1200/400',  N'image/jpeg', 230000, N'Banner TechTalk Q2 2025',                  0, 3),
(13,N'banner',   N'https://picsum.photos/seed/evt13b/1200/400',  N'image/jpeg', 245000, N'Banner Workshop Design Thinking',          0, 4);
GO

/* ================================================================
   BẢNG: dbo.event_registrations  – Đăng ký tham dự sự kiện
   28 bản ghi
   ================================================================ */
INSERT INTO dbo.event_registrations (
    event_id,          -- FK → events.id
    user_id,           -- FK → users.id (người đăng ký)
    status,            -- Trạng thái: pending/approved/rejected/waitlist/cancelled
    ticket_code,       -- Mã vé duy nhất cấp cho người đăng ký
    qr_payload,        -- Nội dung mã QR để check-in
    registered_at,     -- Thời điểm đăng ký
    approved_at,       -- Thời điểm được duyệt
    approved_by,       -- FK → users.id (người phê duyệt)
    rejected_at,       -- Thời điểm bị từ chối
    rejected_by,       -- FK → users.id (người từ chối)
    rejection_reason,  -- Lý do từ chối
    notes,             -- Ghi chú của người đăng ký
    source             -- Nguồn đăng ký: web / mobile / admin_added
) VALUES
/* ── Đăng ký cho EVT-001 (TechTalk Q1) – đã kết thúc ── */
(1, 8,  N'approved', N'TKT-2501-00001',N'EVT001-UID008','2024-12-21 09:15:00','2024-12-22 10:00:00',3, NULL,NULL,NULL,NULL,N'web'),
(1, 11, N'approved', N'TKT-2501-00002',N'EVT001-UID011','2024-12-22 10:30:00','2024-12-23 09:00:00',3, NULL,NULL,NULL,NULL,N'web'),
(1, 17, N'approved', N'TKT-2501-00003',N'EVT001-UID017','2024-12-22 14:00:00','2024-12-23 09:00:00',3, NULL,NULL,NULL,NULL,N'web'),
(1, 23, N'approved', N'TKT-2501-00004',N'EVT001-UID023','2024-12-23 08:45:00','2024-12-24 10:00:00',3, NULL,NULL,NULL,NULL,N'mobile'),
(1, 9,  N'approved', N'TKT-2501-00005',N'EVT001-UID009','2024-12-24 11:00:00','2024-12-25 09:00:00',3, NULL,NULL,NULL,NULL,N'web'),
(1, 21, N'approved', N'TKT-2501-00006',N'EVT001-UID021','2024-12-25 09:30:00','2024-12-26 10:00:00',3, NULL,NULL,NULL,NULL,N'web'),
(1, 15, N'rejected', NULL,             NULL,            '2025-01-02 10:00:00',NULL,               NULL,'2025-01-03 09:00:00',3,N'Không thuộc phòng ban liên quan đến chủ đề sự kiện.',NULL,N'web'),
(1, 25, N'approved', N'TKT-2501-00007',N'EVT001-UID025','2025-01-05 14:00:00','2025-01-06 09:00:00',3, NULL,NULL,NULL,N'Đối tác muốn trao đổi về hợp tác AI',N'web'),

/* ── Đăng ký cho EVT-002 (Excel Workshop) – đã kết thúc ── */
(2, 13, N'approved', N'TKT-2502-00001',N'EVT002-UID013','2025-01-12 09:00:00','2025-01-13 10:00:00',6, NULL,NULL,NULL,NULL,N'web'),
(2, 18, N'approved', N'TKT-2502-00002',N'EVT002-UID018','2025-01-13 10:30:00','2025-01-14 09:00:00',6, NULL,NULL,NULL,NULL,N'web'),
(2, 6,  N'approved', N'TKT-2502-00003',N'EVT002-UID006','2025-01-14 08:00:00','2025-01-14 10:00:00',1, NULL,NULL,NULL,N'Tham gia để hỗ trợ diễn giả',N'admin_added'),
(2, 8,  N'approved', N'TKT-2502-00004',N'EVT002-UID008','2025-01-15 09:00:00','2025-01-15 11:00:00',6, NULL,NULL,NULL,NULL,N'web'),
(2, 24, N'approved', N'TKT-2502-00005',N'EVT002-UID024','2025-01-16 14:00:00','2025-01-17 09:00:00',6, NULL,NULL,NULL,NULL,N'web'),

/* ── Đăng ký cho EVT-005 (Team Building) – đã kết thúc ── */
(5, 8,  N'approved', N'TKT-2505-00001',N'EVT005-UID008','2025-02-16 09:00:00','2025-02-17 10:00:00',5, NULL,NULL,NULL,NULL,N'web'),
(5, 10, N'approved', N'TKT-2505-00002',N'EVT005-UID010','2025-02-17 10:00:00','2025-02-18 09:00:00',5, NULL,NULL,NULL,NULL,N'mobile'),
(5, 12, N'approved', N'TKT-2505-00003',N'EVT005-UID012','2025-02-18 08:30:00','2025-02-19 10:00:00',5, NULL,NULL,NULL,NULL,N'web'),
(5, 14, N'approved', N'TKT-2505-00004',N'EVT005-UID014','2025-02-19 09:00:00','2025-02-20 09:00:00',5, NULL,NULL,NULL,NULL,N'web'),
(5, 19, N'approved', N'TKT-2505-00005',N'EVT005-UID019','2025-02-20 10:00:00','2025-02-21 10:00:00',5, NULL,NULL,NULL,NULL,N'mobile'),
(5, 22, N'waitlist', NULL,             NULL,            '2025-03-08 16:00:00', NULL,              NULL,NULL,NULL,NULL,NULL,N'web'),

/* ── Đăng ký cho EVT-009 (Python Workshop) – đang mở ── */
(9, 11, N'approved', N'TKT-2509-00001',N'EVT009-UID011','2025-05-02 09:00:00','2025-05-03 10:00:00',3, NULL,NULL,NULL,N'Muốn học Python để tự động hoá công việc DevOps',N'web'),
(9, 23, N'approved', N'TKT-2509-00002',N'EVT009-UID023','2025-05-03 10:30:00','2025-05-04 09:00:00',3, NULL,NULL,NULL,NULL,N'web'),
(9, 24, N'pending',  NULL,             NULL,            '2025-05-10 14:00:00', NULL,              NULL,NULL,NULL,NULL,N'Muốn học Python để tự động hoá thiết kế',N'web'),
(9, 14, N'pending',  NULL,             NULL,            '2025-05-12 09:00:00', NULL,              NULL,NULL,NULL,NULL,NULL,N'mobile'),

/* ── Đăng ký cho EVT-011 (Kỹ năng thuyết trình) – đang mở ── */
(11,12, N'approved', N'TKT-2511-00001',N'EVT011-UID012','2025-05-16 10:00:00','2025-05-17 09:00:00',5, NULL,NULL,NULL,NULL,N'web'),
(11,20, N'approved', N'TKT-2511-00002',N'EVT011-UID020','2025-05-17 09:30:00','2025-05-18 10:00:00',5, NULL,NULL,NULL,NULL,N'web'),
(11,16, N'pending',  NULL,             NULL,            '2025-05-18 11:00:00', NULL,              NULL,NULL,NULL,NULL,N'Muốn cải thiện kỹ năng trình bày dự án',N'mobile'),

/* ── Đăng ký cho EVT-010 (IoT Conf) – đang mở ── */
(10,15, N'approved', N'TKT-2510-00001',N'EVT010-UID015','2025-05-11 09:00:00','2025-05-12 10:00:00',7, NULL,NULL,NULL,NULL,N'web'),
(10,25, N'approved', N'TKT-2510-00002',N'EVT010-UID025','2025-05-12 14:00:00','2025-05-13 09:00:00',7, NULL,NULL,NULL,N'Đối tác muốn trao đổi về hợp tác IoT',N'web'),
(10,9,  N'pending',  NULL,             NULL,            '2025-05-15 10:00:00', NULL,              NULL,NULL,NULL,NULL,NULL,N'web');
GO

/* ================================================================
   BẢNG: dbo.registration_approval_logs  – Nhật ký duyệt đăng ký
   22 bản ghi
   ================================================================ */
INSERT INTO dbo.registration_approval_logs (
    registration_id, -- FK → event_registrations.id
    action,          -- Hành động: approved/rejected/reverted/moved_to_waitlist/cancelled
    from_status,     -- Trạng thái trước khi thực hiện hành động
    to_status,       -- Trạng thái sau khi thực hiện hành động
    performed_by,    -- FK → users.id (người thực hiện)
    reason           -- Lý do (bắt buộc với rejected)
) VALUES
(1,  N'approved',N'pending', N'approved',3, NULL),
(2,  N'approved',N'pending', N'approved',3, NULL),
(3,  N'approved',N'pending', N'approved',3, NULL),
(4,  N'approved',N'pending', N'approved',3, NULL),
(5,  N'approved',N'pending', N'approved',3, NULL),
(6,  N'approved',N'pending', N'approved',3, NULL),
(7,  N'rejected', N'pending',N'rejected', 3, N'Không thuộc phòng ban liên quan đến chủ đề sự kiện.'),
(8,  N'approved',N'pending', N'approved',3, NULL),
(9,  N'approved',N'pending', N'approved',6, NULL),
(10, N'approved',N'pending', N'approved',6, NULL),
(11, N'approved',N'pending', N'approved',1, NULL),
(12, N'approved',N'pending', N'approved',6, NULL),
(13, N'approved',N'pending', N'approved',6, NULL),
(14, N'approved',N'pending', N'approved',5, NULL),
(15, N'approved',N'pending', N'approved',5, NULL),
(16, N'approved',N'pending', N'approved',5, NULL),
(17, N'approved',N'pending', N'approved',5, NULL),
(18, N'approved',N'pending', N'approved',5, NULL),
(19, N'moved_to_waitlist',N'pending',N'waitlist',5, N'Sự kiện đã đạt số lượng đăng ký tối đa.'),
(20, N'approved',N'pending', N'approved',3, NULL),
(21, N'approved',N'pending', N'approved',3, NULL),
(25, N'approved',N'pending', N'approved',5, NULL);
GO

/* ================================================================
   BẢNG: dbo.saved_events  – Sự kiện được lưu / theo dõi
   20 bản ghi
   ================================================================ */
INSERT INTO dbo.saved_events (
    user_id,   -- FK → users.id (người lưu sự kiện)
    event_id,  -- FK → events.id (sự kiện được lưu)
    saved_at   -- Thời điểm lưu
) VALUES
(8,  9,  '2025-05-02 08:30:00'),   (8,  12, '2025-05-05 10:00:00'),
(10, 13, '2025-05-08 09:15:00'),   (10, 16, '2025-05-09 14:30:00'),
(11, 12, '2025-05-03 11:00:00'),   (11, 15, '2025-05-04 09:00:00'),
(12, 11, '2025-05-16 08:45:00'),   (12, 17, '2025-05-17 10:20:00'),
(13, 14, '2025-05-10 09:00:00'),   (14, 16, '2025-05-11 13:00:00'),
(15, 10, '2025-05-12 08:30:00'),   (16, 11, '2025-05-14 10:00:00'),
(17, 12, '2025-05-05 14:00:00'),   (17, 15, '2025-05-06 09:30:00'),
(18, 14, '2025-05-13 08:00:00'),   (19, 16, '2025-05-07 11:00:00'),
(20, 11, '2025-05-16 15:00:00'),   (21, 10, '2025-05-12 09:00:00'),
(23, 9,  '2025-05-01 16:00:00'),   (24, 13, '2025-05-09 10:30:00');
GO

/* ================================================================
   BẢNG: dbo.attendances  – Điểm danh sự kiện
   25 bản ghi – chỉ cho các sự kiện đã kết thúc
   ================================================================ */
INSERT INTO dbo.attendances (
    event_id,          -- FK → events.id
    user_id,           -- FK → users.id (người tham dự)
    registration_id,   -- FK → event_registrations.id (đăng ký tương ứng)
    status,            -- Trạng thái: absent / present / late / left_early
    checked_in_at,     -- Thời điểm check-in
    checked_out_at,    -- Thời điểm check-out
    check_in_method,   -- Phương thức: qr_scan / manual / quick_search / self
    checked_in_by,     -- FK → users.id (người thực hiện check-in, NULL nếu tự check)
    is_late,           -- 1 = đến muộn (sau 15 phút kể từ giờ bắt đầu)
    notes              -- Ghi chú điểm danh
) VALUES
-- Điểm danh EVT-001 (TechTalk Q1 – 09:00)
(1, 8,  1,  N'present',   '2025-01-15 08:52:00','2025-01-15 12:05:00',N'qr_scan',   3, 0, NULL),
(1, 11, 2,  N'present',   '2025-01-15 08:58:00','2025-01-15 12:00:00',N'qr_scan',   3, 0, NULL),
(1, 17, 3,  N'present',   '2025-01-15 09:05:00','2025-01-15 12:00:00',N'qr_scan',   3, 0, NULL),
(1, 23, 4,  N'late',      '2025-01-15 09:28:00','2025-01-15 12:00:00',N'qr_scan',   3, 1, N'Kẹt xe trên đường'),
(1, 9,  5,  N'present',   '2025-01-15 08:55:00','2025-01-15 12:00:00',N'qr_scan',   3, 0, NULL),
(1, 21, 6,  N'absent',    NULL,                  NULL,                 NULL,         NULL,0, N'Báo ốm trước ngày diễn ra'),
(1, 25, 8,  N'present',   '2025-01-15 09:00:00','2025-01-15 12:00:00',N'manual',    3, 0, N'Đối tác check-in tại quầy'),

-- Điểm danh EVT-002 (Excel Workshop – 13:30)
(2, 13, 9,  N'present',   '2025-02-05 13:20:00','2025-02-05 17:35:00',N'qr_scan',   6, 0, NULL),
(2, 18, 10, N'present',   '2025-02-05 13:28:00','2025-02-05 17:30:00',N'qr_scan',   6, 0, NULL),
(2, 6,  11, N'present',   '2025-02-05 13:15:00','2025-02-05 17:40:00',N'manual',    1, 0, NULL),
(2, 8,  12, N'late',      '2025-02-05 14:05:00','2025-02-05 17:30:00',N'qr_scan',   6, 1, N'Họp kéo dài hơn dự kiến'),
(2, 24, 13, N'present',   '2025-02-05 13:25:00','2025-02-05 17:30:00',N'qr_scan',   6, 0, NULL),

-- Điểm danh EVT-005 (Team Building – 07:00)
(5, 8,  14, N'present',   '2025-03-15 07:05:00','2025-03-15 21:55:00',N'qr_scan',   5, 0, NULL),
(5, 10, 15, N'present',   '2025-03-15 06:55:00','2025-03-15 22:00:00',N'qr_scan',   5, 0, NULL),
(5, 12, 16, N'present',   '2025-03-15 07:00:00','2025-03-15 21:50:00',N'qr_scan',   5, 0, NULL),
(5, 14, 17, N'late',      '2025-03-15 07:45:00','2025-03-15 22:00:00',N'manual',    5, 1, N'Đến muộn do chờ xe bus'),
(5, 19, 18, N'present',   '2025-03-15 07:02:00','2025-03-15 21:58:00',N'qr_scan',   5, 0, NULL),

-- Điểm danh EVT-006 (Lễ kỷ niệm – 18:00)
(6, 8,  NULL,N'present',  '2025-04-01 17:52:00','2025-04-01 22:00:00',N'manual',    7, 0, NULL),
(6, 10, NULL,N'present',  '2025-04-01 18:00:00','2025-04-01 22:05:00',N'manual',    7, 0, NULL),
(6, 13, NULL,N'present',  '2025-04-01 18:10:00','2025-04-01 22:00:00',N'manual',    7, 1, NULL),
(6, 17, NULL,N'present',  '2025-04-01 17:58:00','2025-04-01 22:00:00',N'manual',    7, 0, NULL),
(6, 20, NULL,N'present',  '2025-04-01 18:00:00','2025-04-01 22:00:00',N'manual',    7, 0, NULL),
(6, 22, NULL,N'absent',   NULL,                  NULL,                 NULL,         NULL,0, N'Báo bận việc gia đình'),
(6, 24, NULL,N'present',  '2025-04-01 18:05:00','2025-04-01 21:45:00',N'manual',    7, 0, N'Về sớm do sức khoẻ'),
(6, 25, NULL,N'present',  '2025-04-01 17:55:00','2025-04-01 22:00:00',N'manual',    7, 0, N'Đối tác tham dự theo lời mời VIP');
GO

/* ================================================================
   BẢNG: dbo.notifications  – Thông báo trong hệ thống
   25 bản ghi
   ================================================================ */
INSERT INTO dbo.notifications (
    user_id,         -- FK → users.id (người nhận thông báo)
    type,            -- Loại thông báo (event.registered, registration.approved, v.v.)
    title,           -- Tiêu đề thông báo ngắn gọn
    body,            -- Nội dung chi tiết thông báo
    link_url,        -- URL dẫn đến trang liên quan
    event_id,        -- FK → events.id (sự kiện liên quan, nếu có)
    registration_id, -- FK → event_registrations.id (đăng ký liên quan)
    priority,        -- Độ ưu tiên: low / normal / high / urgent
    is_read,         -- 0 = chưa đọc, 1 = đã đọc
    read_at,         -- Thời điểm đọc thông báo
    delivered_via    -- Kênh gửi: email, inapp, push
) VALUES
(8,  N'registration.approved',   N'Đăng ký được duyệt!',          N'Đăng ký của bạn cho TechTalk Q1 2025 đã được phê duyệt. Hẹn gặp bạn ngày 15/01!',              N'/events/techtalk-q1-2025/detail', 1, 1,  N'high',   1,'2025-12-22 10:30:00',N'inapp,email'),
(11, N'registration.approved',   N'Đăng ký được duyệt!',          N'Đăng ký của bạn cho TechTalk Q1 2025 đã được phê duyệt.',                                        N'/events/techtalk-q1-2025/detail', 1, 2,  N'high',   1,'2024-12-23 09:15:00',N'inapp,email'),
(7,  N'event.registration_new',  N'Đăng ký mới cần xét duyệt',    N'Nguyễn Văn An đã đăng ký tham dự Hội nghị IoT & Edge Computing 2025.',                          N'/admin/approvals',                10,NULL,N'normal', 0, NULL,              N'inapp'),
(15, N'registration.approved',   N'Đăng ký IoT Conf được duyệt',  N'Đăng ký của bạn cho Hội nghị IoT & Edge Computing 2025 đã được phê duyệt.',                      N'/events/hoi-nghi-iot-edge-computing-2025/detail',10,25,N'high',1,'2025-05-12 10:30:00',N'inapp,email'),
(8,  N'event.reminder',          N'Nhắc nhở: Workshop Python sắp diễn ra', N'Workshop Python sẽ bắt đầu vào ngày 07/06/2025. Đừng quên kiểm tra tài liệu chuẩn bị!',  N'/events/workshop-python-tu-co-ban-den-nang-cao/detail',9,20,N'normal',0,NULL,N'inapp,email'),
(23, N'registration.approved',   N'Đăng ký Python WS được duyệt', N'Đăng ký của bạn cho Workshop Python đã được phê duyệt. Mang máy tính cá nhân nhé!',              N'/events/workshop-python-tu-co-ban-den-nang-cao/detail',9,21,N'high',1,'2025-05-04 09:30:00',N'inapp'),
(3,  N'event.registration_new',  N'3 đăng ký mới – Python WS',    N'Có 3 đăng ký mới đang chờ xét duyệt cho Workshop Python.',                                       N'/admin/approvals',                9, NULL,N'normal', 0, NULL,             N'inapp'),
(12, N'registration.approved',   N'Đăng ký Thuyết trình được duyệt',N'Đăng ký của bạn cho khoá Kỹ năng Thuyết trình Chuyên nghiệp đã được phê duyệt.',                N'/events/dao-tao-ky-nang-thuyet-trinh-chuyen-nghiep/detail',11,25,N'high',1,'2025-05-17 09:30:00',N'inapp,email'),
(24, N'registration.pending',    N'Đăng ký đang chờ xét duyệt',   N'Đăng ký của bạn cho Workshop Python đang được xem xét. Chúng tôi sẽ thông báo sớm!',             N'/my-events',                       9,23,N'normal', 1,'2025-05-10 14:30:00',N'inapp'),
(22, N'registration.waitlisted', N'Bạn đang trong danh sách chờ', N'Sự kiện Team Building đã đầy. Bạn đang ở vị trí #1 trong danh sách chờ.',                         N'/my-events',                       5,19,N'normal', 1,'2025-03-08 16:30:00',N'inapp,email'),
(5,  N'event.published',         N'Sự kiện mới vừa được đăng',    N'Đào Tạo Kỹ Năng Thuyết Trình Chuyên Nghiệp vừa được công bố. Đăng ký ngay!',                     N'/events/dao-tao-ky-nang-thuyet-trinh-chuyen-nghiep/detail',11,NULL,N'low',1,'2025-05-16 09:00:00',N'inapp'),
(1,  N'system.alert',            N'Dung lượng lưu trữ sắp đầy',   N'Dung lượng lưu trữ file đã đạt 87%. Vui lòng kiểm tra và dọn dẹp file cũ.',                       N'/settings',                       NULL,NULL,N'urgent',0,NULL,N'inapp,email'),
(4,  N'event.registration_new',  N'5 đăng ký mới – IoT Conf',     N'Có 5 đăng ký mới đang chờ xét duyệt cho Hội nghị IoT.',                                          N'/admin/approvals',                10,NULL,N'normal', 1,'2025-05-15 11:00:00',N'inapp'),
(9,  N'registration.pending',    N'Đăng ký IoT Conf đang chờ',    N'Đăng ký tham dự Hội nghị IoT đang được xem xét.',                                                 N'/my-events',                      10,28,N'normal', 0, NULL,             N'inapp'),
(16, N'registration.pending',    N'Đăng ký đang chờ xét duyệt',   N'Đăng ký của bạn cho Đào Tạo Kỹ Năng Thuyết Trình đang được xem xét.',                            N'/my-events',                      11,27,N'normal', 1,'2025-05-18 11:30:00',N'inapp'),
(20, N'registration.approved',   N'Đăng ký Thuyết trình được duyệt',N'Đăng ký của bạn cho khoá Kỹ năng Thuyết trình đã được phê duyệt.',                              N'/events/dao-tao-ky-nang-thuyet-trinh-chuyen-nghiep/detail',11,26,N'high',0,NULL,N'inapp,email'),
(14, N'registration.pending',    N'Đăng ký Python WS đang chờ',   N'Đăng ký của bạn cho Workshop Python đang được xem xét. Chúng tôi sẽ thông báo sớm!',             N'/my-events',                      9, 24,N'normal', 0, NULL,             N'inapp'),
(8,  N'attendance.checked_in',   N'Check-in thành công',           N'Bạn đã check-in sự kiện TechTalk Q1 2025 lúc 08:52. Chúc bạn học vui!',                          N'/my-events',                      1, 1, N'low',    1,'2025-01-15 08:52:30',N'inapp'),
(3,  N'event.started',           N'TechTalk Q1 2025 đã bắt đầu',  N'Sự kiện TechTalk Q1 2025 đã chính thức bắt đầu. 7/8 người đăng ký đã check-in.',                  N'/events/techtalk-q1-2025/attendance',1,NULL,N'normal',1,'2025-01-15 09:05:00',N'inapp'),
(2,  N'system.report_ready',     N'Báo cáo tháng 1/2025 đã sẵn sàng',N'Báo cáo thống kê sự kiện tháng 01/2025 đã được tạo. Tải xuống trong mục Báo cáo.',            N'/admin/reports',                  NULL,NULL,N'normal',1,'2025-02-01 07:00:00',N'inapp,email'),
(10, N'event.published',         N'Hội nghị IoT & Edge Computing', N'Hội nghị IoT & Edge Computing 2025 vừa được công bố. Số lượng có hạn, đăng ký ngay!',            N'/events/hoi-nghi-iot-edge-computing-2025/detail',10,NULL,N'normal',1,'2025-05-11 08:30:00',N'inapp'),
(17, N'event.published',         N'TechTalk Q2 2025 đã mở đăng ký',N'TechTalk Q2 2025 chủ đề Microservices & Docker vừa mở đăng ký. Đừng bỏ lỡ!',                    N'/events/techtalk-q2-2025-microservices-docker/detail',12,NULL,N'normal',0,NULL,N'inapp'),
(5,  N'event.approved_by_admin', N'Sự kiện của bạn đã được duyệt', N'Sự kiện "Đào Tạo Kỹ Năng Thuyết Trình" vừa được quản trị viên phê duyệt và đã công bố.',         N'/events/dao-tao-ky-nang-thuyet-trinh-chuyen-nghiep/detail',11,NULL,N'high',1,'2025-05-16 07:30:00',N'inapp,email'),
(25, N'registration.approved',   N'Đăng ký được duyệt – IoT Conf',N'Đăng ký của bạn cho Hội nghị IoT & Edge Computing đã được phê duyệt.',                           N'/events/hoi-nghi-iot-edge-computing-2025/detail',10,26,N'high',1,'2025-05-13 09:30:00',N'inapp,email'),
(13, N'event.published',         N'Hội nghị Tài chính H1/2025',   N'Hội nghị Tài chính Nửa Năm 2025 đã mở đăng ký. Dành riêng cho phòng FIN & HR.',                  N'/events/hoi-nghi-tai-chinh-nua-nam-2025/detail',14,NULL,N'normal',0,NULL,N'inapp');
GO

/* ================================================================
   BẢNG: dbo.notification_channels  – Kênh nhận thông báo của người dùng
   20 bản ghi
   ================================================================ */
INSERT INTO dbo.notification_channels (
    user_id,           -- FK → users.id
    channel,           -- Kênh: email / inapp / push / slack
    is_enabled,        -- 1 = đã bật, 0 = đã tắt
    connected_account, -- Tài khoản kết nối (email, Slack workspace...)
    connected_at       -- Thời điểm kết nối kênh
) VALUES
(1,  N'email', 1, N'nguyen.van.an@company.vn',    '2023-01-10 08:00:00'),
(1,  N'inapp', 1,  NULL,                           '2023-01-10 08:00:00'),
(2,  N'email', 1, N'tran.thi.binh@company.vn',    '2023-01-10 08:05:00'),
(2,  N'inapp', 1,  NULL,                           '2023-01-10 08:05:00'),
(3,  N'email', 1, N'le.van.cuong@company.vn',     '2023-02-01 09:00:00'),
(3,  N'inapp', 1,  NULL,                           '2023-02-01 09:00:00'),
(3,  N'slack', 1, N'U003ABC@company.slack.com',   '2023-06-01 10:00:00'),
(5,  N'email', 1, N'hoang.van.em@company.vn',     '2023-03-01 09:00:00'),
(5,  N'inapp', 1,  NULL,                           '2023-03-01 09:00:00'),
(8,  N'email', 1, N'ngo.thi.ha@company.vn',       '2023-05-01 09:00:00'),
(8,  N'inapp', 1,  NULL,                           '2023-05-01 09:00:00'),
(8,  N'push',  1,  N'device_token_NV008_ios',     '2024-01-15 10:00:00'),
(10, N'email', 1, N'do.thi.khanh@company.vn',     '2023-06-01 09:00:00'),
(10, N'inapp', 1,  NULL,                           '2023-06-01 09:00:00'),
(11, N'email', 1, N'ho.van.long@company.vn',      '2023-06-15 09:00:00'),
(11, N'inapp', 1,  NULL,                           '2023-06-15 09:00:00'),
(17, N'email', 1, N'cao.van.rong@company.vn',     '2023-09-15 09:00:00'),
(17, N'inapp', 1,  NULL,                           '2023-09-15 09:00:00'),
(17, N'push',  1, N'device_token_NV017_android',  '2024-02-10 11:00:00'),
(25, N'email', 1, N'alex.johnson@partner.com',    '2024-03-01 09:00:00');
GO

/* ================================================================
   BẢNG: dbo.notification_preferences  – Tuỳ chỉnh loại thông báo nhận
   20 bản ghi
   ================================================================ */
INSERT INTO dbo.notification_preferences (
    user_id,           -- FK → users.id
    notification_type, -- Loại thông báo áp dụng tuỳ chỉnh
    via_email,         -- 1 = nhận qua email
    via_inapp,         -- 1 = nhận qua thông báo trong ứng dụng
    via_push,          -- 1 = nhận qua push notification
    via_slack          -- 1 = nhận qua Slack
) VALUES
(1,  N'registration.approved',  1,1,0,0),
(1,  N'event.registration_new', 1,1,0,0),
(2,  N'system.alert',           1,1,0,0),
(3,  N'registration.approved',  1,1,0,1),
(3,  N'event.registration_new', 1,1,0,1),
(3,  N'event.started',          0,1,0,1),
(5,  N'registration.approved',  1,1,0,0),
(5,  N'event.registration_new', 1,1,0,0),
(8,  N'registration.approved',  1,1,1,0),
(8,  N'event.reminder',         0,1,1,0),
(8,  N'attendance.checked_in',  0,1,0,0),
(10, N'registration.approved',  1,1,0,0);

ALTER TABLE dbo.event_registrations
DROP CONSTRAINT UQ_reg_ticket;

-- Tạo lại constraint với filtered index (cho phép NULL lặp lại)

-- ALTER TABLE dbo.event_registrations
-- ADD CONSTRAINT UQ_reg_ticket UNIQUE (ticket_code)
-- WHERE ticket_code IS NOT NULL;

CREATE UNIQUE INDEX UQ_reg_ticket
ON dbo.event_registrations(ticket_code)
WHERE ticket_code IS NOT NULL;

UPDATE dbo.events 
SET start_at = DATEADD(day, 30, SYSUTCDATETIME()), 
    end_at = DATEADD(day, 31, SYSUTCDATETIME())
WHERE status = N'open';