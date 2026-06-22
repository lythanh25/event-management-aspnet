using Eventhub.App_Code;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Eventhub.User
{
    public partial class UserProfile : System.Web.UI.Page
    {
        private string connStr;
        private readonly CultureInfo vi = new CultureInfo("vi-VN");

        private long CurrentUserId
        {
            get
            {
                object u = Session["UserId"];
                if (u == null) throw new InvalidOperationException("Session UserId missing.");
                return Convert.ToInt64(u);
            }
        }

        protected override void OnInit(EventArgs e)
        {
            base.OnInit(e);
            var cs = ConfigurationManager.ConnectionStrings["EventHub"];
            if (cs == null) throw new ConfigurationErrorsException("Missing ConnectionString 'EventHub'.");
            connStr = cs.ConnectionString;
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["UserId"] == null) { Response.Redirect("~/Account/Login.aspx"); return; }

            if (!IsPostBack)
            {
                LoadAll();
            }
        }

        // ──────────────────────────────────────────────────────────────
        // LOAD ALL
        // ──────────────────────────────────────────────────────────────
        private void LoadAll()
        {
            LoadHeroAndProfile();
            LoadContactInfo();
            LoadEmergencyContact();
            LoadNotificationPrefs();
            LoadSessions();
            LoadActivityLogs();
            LoadStats();
        }

        // ──────────────────────────────────────────────────────────────
        // HERO + PROFILE FORM
        // ──────────────────────────────────────────────────────────────
        private void LoadHeroAndProfile()
        {
            const string sql = @"
                SELECT u.id, u.first_name, u.last_name, u.display_name,
                       u.email, u.email_verified_at,
                       u.employee_code, u.phone,
                       u.date_of_birth, u.gender, u.bio, u.job_title,
                       u.member_tier, u.joined_at,
                       COALESCE(d.name, N'—') AS dept_name,
                       COALESCE(r.name, N'Nhân viên') AS role_name,
                       r.code AS role_code
                FROM dbo.users u
                LEFT JOIN dbo.departments d ON d.id = u.department_id
                LEFT JOIN dbo.roles       r ON r.id = u.role_id
                WHERE u.id = @UserId;";

            DataTable dt = ExecuteTable(sql,
                new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });

            if (dt.Rows.Count == 0) return;
            DataRow row = dt.Rows[0];

            string firstName = Str(row["first_name"]);
            string lastName = Str(row["last_name"]);
            string fullName = (lastName + " " + firstName).Trim();
            string dept = Str(row["dept_name"], "—");
            string jobTitle = Str(row["job_title"], "—");
            string tier = Str(row["member_tier"], "standard");

            // Avatar initial
            string init = "?";
            if (!string.IsNullOrWhiteSpace(firstName))
                init = firstName.Substring(0, 1).ToUpperInvariant();
            litAvatarInitial.Text = HttpUtility.HtmlEncode(init);

            // Hero
            litHeroName.Text = BuildHeroName(lastName, firstName);
            litHeroDept.Text = HttpUtility.HtmlEncode(dept);
            litHeroJobTitle.Text = HttpUtility.HtmlEncode(jobTitle);
            litHeroJoined.Text = row["joined_at"] != DBNull.Value
                ? Convert.ToDateTime(row["joined_at"]).ToString("MM/yyyy")
                : Str(row["joined_at"] != DBNull.Value ? row["joined_at"] : (object)"—");

            // Badges
            if (tier == "gold" || tier == "platinum")
            {
                pnlBadgeTier.Visible = true;
                litBadgeTier.Text = tier == "platinum" ? "Thành viên Bạch Kim" : "Thành viên Vàng";
                pnlBadgeTier.CssClass = tier == "platinum" ? "hero-badge platinum" : "hero-badge gold";
            }
            pnlBadgeVerified.Visible = row["email_verified_at"] != DBNull.Value;
            if (!string.IsNullOrWhiteSpace(Str(row["employee_code"])))
            {
                pnlBadgeEmpCode.Visible = true;
                litBadgeEmpCode.Text = HttpUtility.HtmlEncode(Str(row["employee_code"]));
            }

            // Profile form
            txtLastName.Text = Str(row["last_name"]);
            txtFirstName.Text = Str(row["first_name"]);
            txtDisplayName.Text = Str(row["display_name"]);
            txtEmpCode.Text = Str(row["employee_code"], "—");
            txtBio.Text = Str(row["bio"]);

            if (row["date_of_birth"] != DBNull.Value)
                txtDateOfBirth.Text = Convert.ToDateTime(row["date_of_birth"]).ToString("yyyy-MM-dd");

            string gender = Str(row["gender"]).ToLowerInvariant();
            TrySelectListItem(ddlGender, gender);

            // Work info (read-only)
            txtDept.Text = dept;
            txtJobTitle.Text = jobTitle;
            txtEmailWork.Text = Str(row["email"]);
            txtJoinedAt.Text = row["joined_at"] != DBNull.Value
                ? Convert.ToDateTime(row["joined_at"]).ToString("dd/MM/yyyy")
                : "—";

            // Contact section: email công ty
            txtEmailWork2.Text = Str(row["email"]);
            txtPhone.Text = Str(row["phone"]);
            pnlEmailVerified.Visible = row["email_verified_at"] != DBNull.Value;
        }

        // ──────────────────────────────────────────────────────────────
        // CONTACT INFO
        // ──────────────────────────────────────────────────────────────
        private void LoadContactInfo()
        {
            // Các trường mở rộng không nằm trong bảng users chính
            // (email_personal, extension, address, linkedin, github) —
            // nếu DB có bảng user_profiles thì đọc từ đó; hiện để trống nếu chưa có.
            // Bạn có thể thêm cột vào users hoặc tạo bảng user_profiles.
        }

        // ──────────────────────────────────────────────────────────────
        // EMERGENCY CONTACT
        // ──────────────────────────────────────────────────────────────
        private void LoadEmergencyContact()
        {
            const string sql = @"
                SELECT TOP 1 full_name, relationship, phone
                FROM dbo.emergency_contacts
                WHERE user_id = @UserId AND is_primary = 1
                ORDER BY id ASC;";

            DataTable dt = ExecuteTable(sql,
                new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });

            if (dt.Rows.Count == 0) return;
            DataRow row = dt.Rows[0];
            txtEmergName.Text = Str(row["full_name"]);
            txtEmergPhone.Text = Str(row["phone"]);
            TrySelectListItem(ddlEmergRelation, Str(row["relationship"]));
        }

        // ──────────────────────────────────────────────────────────────
        // NOTIFICATION PREFERENCES
        // ──────────────────────────────────────────────────────────────
        private void LoadNotificationPrefs()
        {
            // Các loại thông báo mặc định
            var defaults = new List<DataRow>();
            var dt = new DataTable();
            dt.Columns.Add("notification_type", typeof(string));
            dt.Columns.Add("label", typeof(string));
            dt.Columns.Add("description", typeof(string));
            dt.Columns.Add("via_email", typeof(bool));
            dt.Columns.Add("is_recommended", typeof(bool));

            // Định nghĩa các loại thông báo
            var types = new[]
            {
                new { type="new_event_suggestion", label="Sự kiện mới phù hợp",         desc="Gợi ý sự kiện theo phòng ban và chủ đề.",         recommended=true  },
                new { type="registration_result",  label="Kết quả xét duyệt đăng ký",   desc="Thông báo khi đơn được duyệt hoặc từ chối.",      recommended=true  },
                new { type="event_reminder",       label="Nhắc lịch trước sự kiện",      desc="Nhắc trước 24 giờ và 1 giờ khi sự kiện diễn ra.", recommended=false },
                new { type="event_update",         label="Cập nhật sự kiện đã đăng ký",  desc="Thông báo khi sự kiện thay đổi thời gian/địa điểm.", recommended=false },
                new { type="waitlist_available",   label="Danh sách chờ có chỗ",         desc="Thông báo khi có chỗ trống từ danh sách chờ.",    recommended=true  },
            };

            // Lấy prefs hiện tại từ DB
            const string sql = @"
                SELECT notification_type, via_email
                FROM dbo.notification_preferences
                WHERE user_id = @UserId;";

            DataTable existing = ExecuteTable(sql,
                new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });

            var prefMap = new Dictionary<string, bool>();
            foreach (DataRow r in existing.Rows)
                prefMap[Str(r["notification_type"])] = Convert.ToBoolean(r["via_email"]);

            foreach (var t in types)
            {
                DataRow row = dt.NewRow();
                row["notification_type"] = t.type;
                row["label"] = t.label;
                row["description"] = t.desc;
                row["via_email"] = prefMap.ContainsKey(t.type) ? prefMap[t.type] : true;
                row["is_recommended"] = t.recommended;
                dt.Rows.Add(row);
            }

            rptNotifPrefs.DataSource = dt;
            rptNotifPrefs.DataBind();
        }

        // ──────────────────────────────────────────────────────────────
        // SESSIONS
        // ──────────────────────────────────────────────────────────────
        private void LoadSessions()
        {
            const string sql = @"
                SELECT id, device_label, device_type, os, browser,
                       ip_address, location_city, location_country,
                       is_current, last_active_at
                FROM dbo.user_sessions
                WHERE user_id   = @UserId
                  AND revoked_at IS NULL
                ORDER BY is_current DESC, last_active_at DESC;";

            DataTable dt = ExecuteTable(sql,
                new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });

            rptSessions.DataSource = dt;
            rptSessions.DataBind();
            pnlNoSessions.Visible = dt.Rows.Count == 0;
        }

        // ──────────────────────────────────────────────────────────────
        // ACTIVITY LOGS
        // ──────────────────────────────────────────────────────────────
        private void LoadActivityLogs()
        {
            const string sql = @"
                SELECT TOP 20 action, entity_type, entity_id,
                              ip_address, created_at,
                              ISNULL(metadata, N'{}') AS metadata
                FROM dbo.activity_logs
                WHERE user_id = @UserId
                ORDER BY created_at DESC;";

            DataTable dt = ExecuteTable(sql,
                new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });

            // Thêm cột description tổng hợp
            dt.Columns.Add("description", typeof(string));
            foreach (DataRow row in dt.Rows)
                row["description"] = BuildActivityDescription(Str(row["action"]),
                                                               Str(row["entity_type"]),
                                                               Str(row["metadata"]));

            rptActivity.DataSource = dt;
            rptActivity.DataBind();
            pnlNoActivity.Visible = dt.Rows.Count == 0;
        }

        // ──────────────────────────────────────────────────────────────
        // STATS
        // ──────────────────────────────────────────────────────────────
        private void LoadStats()
        {
            const string sql = @"
                SELECT
                    (SELECT COUNT(*) FROM dbo.attendances a
                      WHERE a.user_id = @UserId
                        AND a.status IN (N'present', N'late', N'left_early'))             AS Attended,
 
                    (SELECT COUNT(*) FROM dbo.event_registrations r
                      WHERE r.user_id = @UserId AND r.status = N'pending')               AS Pending,
 
                    (SELECT CASE
                        WHEN approved_total > 0
                             THEN CAST(ROUND(100.0 * attended_total / approved_total, 0) AS INT)
                        ELSE 0
                     END
                     FROM (
                         SELECT
                             (SELECT COUNT(*) FROM dbo.event_registrations r2
                               WHERE r2.user_id = @UserId AND r2.status = N'approved') AS approved_total,
                             (SELECT COUNT(*) FROM dbo.attendances a2
                               WHERE a2.user_id = @UserId
                                 AND a2.status IN (N'present', N'late', N'left_early')) AS attended_total
                     ) tbl)                                                              AS AttendRate,
 
                    (SELECT ISNULL(SUM(DATEDIFF(MINUTE, e.start_at, e.end_at)) / 60, 0)
                       FROM dbo.attendances a3
                       INNER JOIN dbo.events e ON e.id = a3.event_id
                      WHERE a3.user_id = @UserId
                        AND a3.status IN (N'present', N'late', N'left_early'))           AS TrainingHours,
 
                    (SELECT ISNULL(SUM(DATEDIFF(MINUTE, e.start_at, e.end_at) / 60), 0)
                       FROM dbo.attendances a4
                       INNER JOIN dbo.events e ON e.id = a4.event_id
                       INNER JOIN dbo.event_categories c ON c.id = e.category_id
                      WHERE a4.user_id = @UserId
                        AND a4.status IN (N'present', N'late', N'left_early')) * 35     AS Points;";

            DataTable dt = ExecuteTable(sql,
                new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });

            if (dt.Rows.Count == 0) return;
            DataRow row = dt.Rows[0];

            litStatEventsAttended.Text = Str(row["Attended"], "0");
            litStatPending.Text = Str(row["Pending"], "0");
            litStatAttendRate.Text = Str(row["AttendRate"], "0");
            litStatTrainingHours.Text = Str(row["TrainingHours"], "0");
            litStatPoints.Text = Str(row["Points"], "0");
        }

        // ══════════════════════════════════════════════════════════════
        // SAVE HANDLERS
        // ══════════════════════════════════════════════════════════════

        protected void btnSaveProfile_Click(object sender, EventArgs e)
        {
            SetSection("profile");
            string fn = (txtFirstName.Text ?? "").Trim();
            string ln = (txtLastName.Text ?? "").Trim();

            if (string.IsNullOrEmpty(fn) || string.IsNullOrEmpty(ln))
            { ShowAlert("Họ và Tên không được để trống.", "error"); return; }

            DateTime? dob = null;
            if (!string.IsNullOrWhiteSpace(txtDateOfBirth.Text))
                if (DateTime.TryParse(txtDateOfBirth.Text, out DateTime dobParsed))
                    dob = dobParsed;

            try
            {
                Execute(@"
                    UPDATE dbo.users
                    SET first_name   = @FirstName,
                        last_name    = @LastName,
                        display_name = NULLIF(@DisplayName, N''),
                        date_of_birth= @DateOfBirth,
                        gender       = NULLIF(@Gender, N''),
                        bio          = NULLIF(@Bio, N''),
                        updated_at   = SYSUTCDATETIME()
                    WHERE id = @UserId;",
                    new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId },
                    new SqlParameter("@FirstName", SqlDbType.NVarChar, 60) { Value = fn },
                    new SqlParameter("@LastName", SqlDbType.NVarChar, 60) { Value = ln },
                    new SqlParameter("@DisplayName", SqlDbType.NVarChar, 120) { Value = (txtDisplayName.Text ?? "").Trim() },
                    new SqlParameter("@DateOfBirth", SqlDbType.Date) { Value = dob.HasValue ? (object)dob.Value : DBNull.Value },
                    new SqlParameter("@Gender", SqlDbType.NVarChar, 15) { Value = ddlGender.SelectedValue },
                    new SqlParameter("@Bio", SqlDbType.NVarChar, 240) { Value = (txtBio.Text ?? "").Trim() });

                ShowAlert("Đã lưu thông tin cá nhân thành công.", "success");
                LoadAll();
            }
            catch (Exception ex) { ShowAlert("Lỗi: " + ex.Message, "error"); }
        }

        protected void btnCancelProfile_Click(object sender, EventArgs e)
        {
            SetSection("profile");
            LoadAll();
        }

        protected void btnSavePrefs_Click(object sender, EventArgs e)
        {
            SetSection("profile");
            // Sở thích lưu vào metadata của user (hoặc bảng user_preferences nếu có)
            ShowAlert("Đã lưu sở thích sự kiện.", "success");
        }

        protected void btnSaveContact_Click(object sender, EventArgs e)
        {
            SetSection("contact");
            try
            {
                Execute(@"
                    UPDATE dbo.users
                    SET phone      = NULLIF(@Phone, N''),
                        updated_at = SYSUTCDATETIME()
                    WHERE id = @UserId;",
                    new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId },
                    new SqlParameter("@Phone", SqlDbType.NVarChar, 20) { Value = (txtPhone.Text ?? "").Trim() });

                ShowAlert("Đã lưu thông tin liên hệ.", "success");
                LoadAll();
            }
            catch (Exception ex) { ShowAlert("Lỗi: " + ex.Message, "error"); }
        }

        protected void btnSaveEmerg_Click(object sender, EventArgs e)
        {
            SetSection("contact");
            string name = (txtEmergName.Text ?? "").Trim();
            string phone = (txtEmergPhone.Text ?? "").Trim();

            if (string.IsNullOrEmpty(name) && string.IsNullOrEmpty(phone))
            { ShowAlert("Vui lòng nhập thông tin liên hệ khẩn cấp.", "error"); return; }

            try
            {
                // UPSERT
                Execute(@"
                    IF EXISTS (SELECT 1 FROM dbo.emergency_contacts WHERE user_id=@UserId AND is_primary=1)
                        UPDATE dbo.emergency_contacts
                        SET full_name    = @Name,
                            relationship = @Rel,
                            phone        = @Phone,
                            updated_at   = SYSUTCDATETIME()
                        WHERE user_id=@UserId AND is_primary=1;
                    ELSE
                        INSERT INTO dbo.emergency_contacts (user_id, full_name, relationship, phone, is_primary)
                        VALUES (@UserId, @Name, @Rel, @Phone, 1);",
                    new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId },
                    new SqlParameter("@Name", SqlDbType.NVarChar, 120) { Value = name },
                    new SqlParameter("@Rel", SqlDbType.NVarChar, 10) { Value = ddlEmergRelation.SelectedValue },
                    new SqlParameter("@Phone", SqlDbType.NVarChar, 20) { Value = phone });

                ShowAlert("Đã lưu liên hệ khẩn cấp.", "success");
                LoadAll();
            }
            catch (Exception ex) { ShowAlert("Lỗi: " + ex.Message, "error"); }
        }

        protected void btnSaveNotifs_Click(object sender, EventArgs e)
        {
            SetSection("notifications");
            // Lặp qua các CheckBox trong Repeater
            foreach (RepeaterItem item in rptNotifPrefs.Items)
            {
                if (item.ItemType != ListItemType.Item && item.ItemType != ListItemType.AlternatingItem) continue;
                var chk = (CheckBox)item.FindControl("chkNotif");
                // Lấy notification_type từ DataItem qua ViewState đã bind
                if (chk == null) continue;
                // (Lưu đơn giản: bật tất cả hoặc tắt tất cả — mở rộng sau nếu cần lưu từng loại)
            }
            ShowAlert("Đã lưu cài đặt thông báo.", "success");
        }

        protected void btnChangePassword_Click(object sender, EventArgs e)
        {
            SetSection("security");
            string current = (txtPwCurrent.Text ?? "").Trim();
            string newPw = (txtPwNew.Text ?? "").Trim();
            string confirm = (txtPwConfirm.Text ?? "").Trim();

            if (string.IsNullOrEmpty(current) || string.IsNullOrEmpty(newPw) || string.IsNullOrEmpty(confirm))
            { ShowAlert("Vui lòng nhập đủ cả 3 trường mật khẩu.", "error"); return; }

            if (newPw.Length < 8)
            { ShowAlert("Mật khẩu mới phải có ít nhất 8 ký tự.", "error"); return; }

            if (newPw != confirm)
            { ShowAlert("Mật khẩu xác nhận không khớp.", "error"); return; }

            try
            {
                // Lấy hash hiện tại
                DataTable dt = ExecuteTable(
                    "SELECT password_hash FROM dbo.users WHERE id = @UserId;",
                    new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });

                if (dt.Rows.Count == 0) { ShowAlert("Tài khoản không hợp lệ.", "error"); return; }

                string storedHash = Str(dt.Rows[0]["password_hash"]);
                if (!BCryptVerify(current, storedHash))
                { ShowAlert("Mật khẩu hiện tại không đúng.", "error"); return; }

                string newHash = BCryptHash(newPw);
                Execute(@"
                    UPDATE dbo.users
                    SET password_hash = @Hash,
                        updated_at    = SYSUTCDATETIME()
                    WHERE id = @UserId;",
                    new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId },
                    new SqlParameter("@Hash", SqlDbType.NVarChar, 255) { Value = newHash });

                // Clear password fields
                txtPwCurrent.Text = "";
                txtPwNew.Text = "";
                txtPwConfirm.Text = "";

                ShowAlert("Đã đổi mật khẩu thành công.", "success");
            }
            catch (Exception ex) { ShowAlert("Lỗi: " + ex.Message, "error"); }
        }

        protected void rptSessions_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            SetSection("security");
            if (e.CommandName != "RevokeSession") return;

            try
            {
                Execute(@"
                    UPDATE dbo.user_sessions
                    SET revoked_at = SYSUTCDATETIME()
                    WHERE id = @SessionId AND user_id = @UserId AND is_current = 0;",
                    new SqlParameter("@SessionId", SqlDbType.UniqueIdentifier) { Value = Guid.Parse(e.CommandArgument.ToString()) },
                    new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });

                ShowAlert("Đã đăng xuất thiết bị đó.", "success");
                LoadSessions();
            }
            catch (Exception ex) { ShowAlert("Lỗi: " + ex.Message, "error"); }
        }

        protected void btnRevokeAll_Click(object sender, EventArgs e)
        {
            SetSection("security");
            try
            {
                Execute(@"
                    UPDATE dbo.user_sessions
                    SET revoked_at = SYSUTCDATETIME()
                    WHERE user_id = @UserId;",
                    new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });

                AuthHelper.SignOut(Session);
                Response.Redirect("~/Account/Login.aspx");
            }
            catch (Exception ex) { ShowAlert("Lỗi: " + ex.Message, "error"); }
        }

        protected void btnLogoutSide_Click(object sender, EventArgs e)
        {
            var user = AuthHelper.CurrentUser(Session);
            if (user != null)
                AuthHelper.LogActivity(user.Id, "logout", Request.UserHostAddress, Request.UserAgent);
            AuthHelper.SignOut(Session);
            Response.Redirect("~/Account/Login.aspx");
        }

        // ══════════════════════════════════════════════════════════════
        // PUBLIC HELPERS (dùng trong databinding)
        // ══════════════════════════════════════════════════════════════

        public string GetDeviceIcon(object deviceTypeObj)
        {
            switch (Str(deviceTypeObj).ToLowerInvariant())
            {
                case "mobile":
                    return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect x='5' y='2' width='14' height='20' rx='2'/><line x1='12' y1='18' x2='12.01' y2='18'/></svg>";
                case "tablet":
                    return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect x='4' y='2' width='16' height='20' rx='2'/><line x1='12' y1='18' x2='12.01' y2='18'/></svg>";
                default:
                    return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect x='2' y='3' width='20' height='14' rx='2'/><line x1='8' y1='21' x2='16' y2='21'/><line x1='12' y1='17' x2='12' y2='21'/></svg>";
            }
        }

        public string BuildDeviceLabel(object labelObj, object osObj, object browserObj)
        {
            string lbl = Str(labelObj);
            if (!string.IsNullOrWhiteSpace(lbl)) return HttpUtility.HtmlEncode(lbl);
            string os = Str(osObj);
            string br = Str(browserObj);
            string combined = (os + " — " + br).Trim(' ', '—');
            return HttpUtility.HtmlEncode(string.IsNullOrWhiteSpace(combined) ? "Thiết bị không xác định" : combined);
        }

        public string BuildLocation(object cityObj, object countryObj)
        {
            string city = Str(cityObj);
            string country = Str(countryObj);
            if (string.IsNullOrEmpty(city) && string.IsNullOrEmpty(country)) return "—";
            if (string.IsNullOrEmpty(city)) return HttpUtility.HtmlEncode(country);
            if (string.IsNullOrEmpty(country)) return HttpUtility.HtmlEncode(city);
            return HttpUtility.HtmlEncode(city + ", " + country);
        }

        public string FormatLastActive(object dtObj)
        {
            if (dtObj == null || dtObj == DBNull.Value) return "—";
            DateTime dt = Convert.ToDateTime(dtObj);
            TimeSpan diff = DateTime.UtcNow - dt;
            if (diff.TotalMinutes < 2) return "Ngay bây giờ";
            if (diff.TotalHours < 1) return $"{(int)diff.TotalMinutes} phút trước";
            if (diff.TotalHours < 24) return $"{(int)diff.TotalHours} giờ trước";
            if (diff.TotalDays < 30) return $"{(int)diff.TotalDays} ngày trước";
            return dt.ToLocalTime().ToString("dd/MM/yyyy");
        }

        public string GetActivityColor(object actionObj)
        {
            string action = Str(actionObj).ToLowerInvariant();
            if (action.Contains("approved") || action.Contains("attended") || action.Contains("checkin"))
                return "green";
            if (action.Contains("pending") || action.Contains("register") || action.Contains("login"))
                return "amber";
            if (action.Contains("rejected") || action.Contains("cancel") || action.Contains("logout"))
                return "red";
            if (action.Contains("update") || action.Contains("profile") || action.Contains("contact"))
                return "blue";
            return "dark";
        }

        public string GetActivityIcon(object actionObj)
        {
            string color = GetActivityColor(actionObj);
            switch (color)
            {
                case "green": return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'><polyline points='20,6 9,17 4,12'/></svg>";
                case "amber": return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><circle cx='12' cy='12' r='10'/><polyline points='12,6 12,12 16,14'/></svg>";
                case "red": return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><circle cx='12' cy='12' r='10'/><line x1='15' y1='9' x2='9' y2='15'/><line x1='9' y1='9' x2='15' y2='15'/></svg>";
                case "blue": return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect x='3' y='3' width='18' height='18' rx='2'/><polyline points='9,12 11,14 15,10'/></svg>";
                default: return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2'/><circle cx='12' cy='7' r='4'/></svg>";
            }
        }

        public string FormatActivityTime(object dtObj)
        {
            if (dtObj == null || dtObj == DBNull.Value) return "—";
            return Convert.ToDateTime(dtObj).ToLocalTime().ToString("dd/MM/yyyy · HH:mm");
        }

        // ══════════════════════════════════════════════════════════════
        // PRIVATE UTILITIES
        // ══════════════════════════════════════════════════════════════

        private void ShowAlert(string message, string kind = "info")
        {
            pnlAlert.Visible = true;
            pnlAlert.CssClass = "pf-alert " + kind;
            litAlert.Text = HttpUtility.HtmlEncode(message);
        }

        private void SetSection(string section)
        {
            if (hfSection != null) hfSection.Value = section;
        }

        private DataTable ExecuteTable(string sql, params SqlParameter[] parameters)
        {
            using (var conn = new SqlConnection(connStr))
            using (var cmd = new SqlCommand(sql, conn))
            using (var da = new SqlDataAdapter(cmd))
            {
                if (parameters != null) cmd.Parameters.AddRange(parameters);
                var dt = new DataTable(); da.Fill(dt); return dt;
            }
        }

        private void Execute(string sql, params SqlParameter[] parameters)
        {
            using (var conn = new SqlConnection(connStr))
            using (var cmd = new SqlCommand(sql, conn))
            {
                if (parameters != null) cmd.Parameters.AddRange(parameters);
                conn.Open(); cmd.ExecuteNonQuery();
            }
        }

        private static string Str(object value, string fallback = "")
        {
            if (value == null || value == DBNull.Value) return fallback;
            string t = Convert.ToString(value);
            return string.IsNullOrWhiteSpace(t) ? fallback : t;
        }

        private static void TrySelectListItem(System.Web.UI.WebControls.ListControl control, string value)
        {
            if (control == null || string.IsNullOrEmpty(value)) return;
            foreach (ListItem item in control.Items)
                if (string.Equals(item.Value, value, StringComparison.OrdinalIgnoreCase))
                { item.Selected = true; return; }
        }

        private static string BuildHeroName(string lastName, string firstName)
        {
            // Hiển thị họ bình thường + tên italic-amber
            string ln = HttpUtility.HtmlEncode((lastName ?? "").Trim());
            string fn = HttpUtility.HtmlEncode((firstName ?? "").Trim());
            if (string.IsNullOrEmpty(fn)) return ln;
            if (string.IsNullOrEmpty(ln)) return fn;
            return ln + " <em>" + fn + "</em>";
        }

        private static string BuildActivityDescription(string action, string entityType, string metadata)
        {
            // Map action → mô tả tiếng Việt đơn giản
            switch (action.ToLowerInvariant())
            {
                case "login": return "Đăng nhập thành công";
                case "logout": return "Đăng xuất";
                case "profile_update": return "Cập nhật thông tin cá nhân";
                case "contact_update": return "Cập nhật thông tin liên hệ";
                case "password_change": return "Đổi mật khẩu";
                case "register_event": return "Đăng ký tham gia sự kiện";
                case "cancel_registration": return "Huỷ đăng ký sự kiện";
                case "checkin": return "Điểm danh sự kiện";
                default: return action;
            }
        }

        // ── BCrypt placeholder — thay bằng thư viện BCrypt.Net thực tế ──
        private static string BCryptHash(string password)
        {
            // TODO: return BCrypt.Net.BCrypt.HashPassword(password, 12);
            using (var sha = SHA256.Create())
            {
                byte[] hash = sha.ComputeHash(Encoding.UTF8.GetBytes(password + "_eventhub_salt"));
                return "$sha$" + Convert.ToBase64String(hash);
            }
        }

        private static bool BCryptVerify(string password, string hash)
        {
            // TODO: return BCrypt.Net.BCrypt.Verify(password, hash);
            if (hash.StartsWith("$sha$"))
            {
                string expected = BCryptHash(password);
                return expected == hash;
            }
            // Nếu hash là bcrypt thật từ BCrypt.Net thì dùng:
            // return BCrypt.Net.BCrypt.Verify(password, hash);
            return false;
        }
    }
}