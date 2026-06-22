using Eventhub.App_Code;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Eventhub.Admin
{
    public partial class settings : System.Web.UI.Page
    {
        #region VMs

        public class SessionRow
        {
            public long Id { get; set; }
            public bool IsCurrent { get; set; }
            public string DeviceText { get; set; }
            public string IpText { get; set; }
            public string LastSeenText { get; set; }
            public string RelativeTime { get; set; }
        }

        #endregion

        #region Properties

        private string Section
        {
            get { return (ViewState["sec"] as string) ?? "profile"; }
            set { ViewState["sec"] = value; }
        }

        private long CurrentUserId
        {
            get
            {
                var u = AuthHelper.CurrentUser(Session);
                return u != null ? u.Id : 0;
            }
        }

        #endregion

        protected void Page_Load(object sender, EventArgs e)
        {
            var master = Master as Eventhub.AdminMaster;
            if (master != null) master.Breadcrumb = "Cài đặt";

            if (CurrentUserId <= 0)
            {
                Response.Redirect("~/Account/Login.aspx");
                return;
            }

            if (!IsPostBack)
            {
                var qs = Request.QueryString["sec"];
                if (!string.IsNullOrEmpty(qs) &&
                    new[] { "profile", "security", "notifications" }.Contains(qs))
                    Section = qs;
                else
                    Section = "profile";

                LoadDepartments();
                LoadProfile();
                LoadSecurityInfo();
                LoadNotifications();
            }

            ApplyActiveSection();
            litSavedAt.Text = DateTime.Now.ToString("HH:mm, dd/MM/yyyy");
        }

        #region Switch section

        private void ApplyActiveSection()
        {
            navProfile.CssClass = "settings-nav-item" + (Section == "profile" ? " active" : "");
            navSecurity.CssClass = "settings-nav-item" + (Section == "security" ? " active" : "");
            navNotifications.CssClass = "settings-nav-item" + (Section == "notifications" ? " active" : "");

            pnlProfile.Visible = Section == "profile";
            pnlSecurity.Visible = Section == "security";
            pnlNotifications.Visible = Section == "notifications";
        }

        #endregion

        #region Load dropdowns

        private void LoadDepartments()
        {
            ddlDepartment.Items.Clear();
            ddlDepartment.Items.Add(new ListItem("— Chọn phòng ban —", "0"));
            try
            {
                const string sql = @"
                    SELECT id, name FROM dbo.departments
                    WHERE is_active = 1 ORDER BY name;";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                using (var rd = cmd.ExecuteReader())
                {
                    while (rd.Read())
                    {
                        ddlDepartment.Items.Add(new ListItem(
                            rd["name"].ToString(),
                            Convert.ToInt64(rd["id"]).ToString()));
                    }
                }
            }
            catch { }
        }

        #endregion

        #region Load Profile

        private void LoadProfile()
        {
            try
            {
                const string sql = @"
                    SELECT u.first_name, u.last_name, u.display_name, u.email, u.email_verified_at,
                           u.phone, u.bio, u.job_title, u.department_id, u.employee_code, u.avatar_url
                    FROM dbo.users u
                    WHERE u.id = @uid;";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@uid", CurrentUserId);
                    using (var rd = cmd.ExecuteReader())
                    {
                        if (!rd.Read()) return;

                        var firstName = rd["first_name"].ToString();
                        var lastName = rd["last_name"].ToString();
                        var displayName = rd["display_name"] as string;

                        txtFirstName.Text = firstName;
                        txtLastName.Text = lastName;
                        txtDisplayName.Text = displayName ?? "";
                        txtEmail.Text = rd["email"].ToString();
                        txtPhone.Text = rd["phone"] as string ?? "";
                        txtBio.Text = rd["bio"] as string ?? "";
                        txtJobTitle.Text = rd["job_title"] as string ?? "";
                        txtEmployeeCode.Text = rd["employee_code"] as string ?? "—";

                        if (rd["department_id"] != DBNull.Value)
                        {
                            var did = Convert.ToInt64(rd["department_id"]).ToString();
                            var item = ddlDepartment.Items.FindByValue(did);
                            if (item != null)
                            {
                                ddlDepartment.ClearSelection();
                                item.Selected = true;
                            }
                        }

                        var full = (firstName + " " + lastName).Trim();
                        litUserName.Text = HttpUtility.HtmlEncode(string.IsNullOrEmpty(displayName) ? full : displayName);
                        litAvatarInitial.Text = string.IsNullOrEmpty(full) ? "?" : full[0].ToString().ToUpper();

                        litEmailHint.Text = rd["email_verified_at"] != DBNull.Value
                            ? "<span class=\"hint green\">Đã xác thực</span>"
                            : "<span class=\"hint amber\">Chưa xác thực</span>";

                        if (rd["department_id"] != DBNull.Value)
                        {
                            var idStr = Convert.ToInt64(rd["department_id"]).ToString();
                            var itm = ddlDepartment.Items.FindByValue(idStr);
                            litUserDept.Text = itm != null
                                ? HttpUtility.HtmlEncode(itm.Text)
                                : "Chưa có phòng ban";
                        }
                        else
                        {
                            litUserDept.Text = "Chưa có phòng ban";
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi tải hồ sơ: " + ex.Message, isError: true);
            }
        }

        #endregion

        #region Save profile

        protected void btnSaveProfile_Click(object sender, EventArgs e)
        {
            // Validate
            var first = (txtFirstName.Text ?? "").Trim();
            var last = (txtLastName.Text ?? "").Trim();
            if (string.IsNullOrEmpty(first) || string.IsNullOrEmpty(last))
            {
                ShowAlert("Họ và tên không được để trống.", isError: true);
                return;
            }
            if (first.Length > 60 || last.Length > 60)
            {
                ShowAlert("Họ hoặc tên vượt quá 60 ký tự.", isError: true);
                return;
            }

            var phone = (txtPhone.Text ?? "").Trim();
            if (!string.IsNullOrEmpty(phone) && !Regex.IsMatch(phone, @"^[+\d\s\-()]{6,20}$"))
            {
                ShowAlert("Số điện thoại không hợp lệ.", isError: true);
                return;
            }

            long deptId; long.TryParse(ddlDepartment.SelectedValue, out deptId);

            // Avatar upload (nếu có)
            string newAvatarUrl = SaveAvatarIfAny();

            try
            {
                string sql = @"
                    UPDATE dbo.users SET
                        first_name   = @fn,
                        last_name    = @ln,
                        display_name = @dn,
                        phone        = @ph,
                        bio          = @bio,
                        job_title    = @jt,
                        department_id = @did,
                        updated_at   = SYSUTCDATETIME()" +
                        (newAvatarUrl != null ? ", avatar_url = @av" : "") +
                    @" WHERE id = @uid;";

                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@fn", first);
                    cmd.Parameters.AddWithValue("@ln", last);
                    cmd.Parameters.AddWithValue("@dn",
                        string.IsNullOrEmpty(txtDisplayName.Text)
                            ? (object)DBNull.Value : txtDisplayName.Text.Trim());
                    cmd.Parameters.AddWithValue("@ph",
                        string.IsNullOrEmpty(phone) ? (object)DBNull.Value : phone);
                    cmd.Parameters.AddWithValue("@bio",
                        string.IsNullOrEmpty(txtBio.Text)
                            ? (object)DBNull.Value : txtBio.Text.Trim());
                    cmd.Parameters.AddWithValue("@jt",
                        string.IsNullOrEmpty(txtJobTitle.Text)
                            ? (object)DBNull.Value : txtJobTitle.Text.Trim());
                    cmd.Parameters.AddWithValue("@did",
                        deptId > 0 ? (object)deptId : DBNull.Value);
                    cmd.Parameters.AddWithValue("@uid", CurrentUserId);
                    if (newAvatarUrl != null)
                        cmd.Parameters.AddWithValue("@av", newAvatarUrl);

                    cmd.ExecuteNonQuery();
                }

                AuthHelper.LogActivity(CurrentUserId, "user.update_profile",
                    Request.UserHostAddress, Request.UserAgent);

                ShowAlert("✓ Đã lưu thay đổi hồ sơ.", isError: false);
                LoadProfile();
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi lưu hồ sơ: " + ex.Message, isError: true);
            }
        }

        private string SaveAvatarIfAny()
        {
            if (!fuAvatar.HasFile) return null;

            try
            {
                var ext = Path.GetExtension(fuAvatar.FileName).ToLowerInvariant();
                var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif" };
                if (Array.IndexOf(allowed, ext) < 0)
                {
                    ShowAlert("Định dạng ảnh không hợp lệ. Chỉ chấp nhận JPG, PNG, WEBP, GIF.", isError: true);
                    return null;
                }
                if (fuAvatar.PostedFile.ContentLength > 2 * 1024 * 1024)
                {
                    ShowAlert("Dung lượng ảnh không quá 2MB.", isError: true);
                    return null;
                }

                var folder = Server.MapPath("~/Uploads/avatars");
                if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);

                var fileName = "avatar-" + CurrentUserId + "-" + DateTime.Now.ToString("yyyyMMddHHmmss") + ext;
                var fullPath = Path.Combine(folder, fileName);
                fuAvatar.SaveAs(fullPath);
                return "~/Uploads/avatars/" + fileName;
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi tải ảnh: " + ex.Message, isError: true);
                return null;
            }
        }

        protected void btnCancelProfile_Click(object sender, EventArgs e)
        {
            LoadProfile();
            ShowAlert("Đã khôi phục thông tin về trạng thái lưu trước đó.", isError: false);
        }

        protected void btnRemoveAvatar_Click(object sender, EventArgs e)
        {
            try
            {
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(
                    "UPDATE dbo.users SET avatar_url = NULL, updated_at = SYSUTCDATETIME() WHERE id = @uid;", con))
                {
                    cmd.Parameters.AddWithValue("@uid", CurrentUserId);
                    cmd.ExecuteNonQuery();
                }
                ShowAlert("Đã xoá ảnh đại diện.", isError: false);
                LoadProfile();
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi: " + ex.Message, isError: true);
            }
        }

        #endregion

        #region Security: load

        private void LoadSecurityInfo()
        {
            try
            {
                const string sqlLast = @"
                    SELECT TOP 1 created_at FROM dbo.activity_logs
                    WHERE user_id = @uid AND action = N'user.change_password'
                    ORDER BY created_at DESC;";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sqlLast, con))
                {
                    cmd.Parameters.AddWithValue("@uid", CurrentUserId);
                    var o = cmd.ExecuteScalar();
                    if (o != null && o != DBNull.Value)
                    {
                        var when = Convert.ToDateTime(o);
                        litPwLastChanged.Text = "Lần cuối: " + RelativeTime(when);
                    }
                    else
                    {
                        litPwLastChanged.Text = "Chưa đổi mật khẩu";
                    }
                }
            }
            catch { litPwLastChanged.Text = ""; }

            LoadSessions();
        }

        private void LoadSessions()
        {
            var list = new List<SessionRow>();
            string currentToken = "";
            try { currentToken = (Session["session_token"] as string) ?? ""; } catch { }

            try
            {
                const string sql = @"
                    SELECT id, session_token, ip_address, user_agent, last_seen_at, created_at
                    FROM dbo.user_sessions
                    WHERE user_id = @uid AND (revoked_at IS NULL)
                    ORDER BY last_seen_at DESC;";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@uid", CurrentUserId);
                    using (var rd = cmd.ExecuteReader())
                    {
                        while (rd.Read())
                        {
                            var token = rd["session_token"] as string ?? "";
                            var ua = rd["user_agent"] as string ?? "";
                            var ip = rd["ip_address"] as string ?? "—";
                            var lastSeen = Convert.ToDateTime(rd["last_seen_at"]);

                            list.Add(new SessionRow
                            {
                                Id = Convert.ToInt64(rd["id"]),
                                IsCurrent = !string.IsNullOrEmpty(currentToken)
                                               && currentToken.Equals(token, StringComparison.Ordinal),
                                DeviceText = ParseUserAgent(ua),
                                IpText = "IP: " + ip,
                                LastSeenText = lastSeen.ToString("HH:mm, dd/MM/yyyy"),
                                RelativeTime = RelativeTime(lastSeen)
                            });
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("LoadSessions error: " + ex.Message);
            }

            list = list.OrderByDescending(x => x.IsCurrent).ToList();

            rptSessions.DataSource = list;
            rptSessions.DataBind();
            phNoSessions.Visible = list.Count <= 1;
        }

        private static string ParseUserAgent(string ua)
        {
            if (string.IsNullOrEmpty(ua)) return "Trình duyệt không xác định";
            var u = ua.ToLowerInvariant();
            string browser = "Trình duyệt";
            if (u.Contains("edg/")) browser = "Microsoft Edge";
            else if (u.Contains("chrome/") && !u.Contains("edg/")) browser = "Google Chrome";
            else if (u.Contains("firefox/")) browser = "Mozilla Firefox";
            else if (u.Contains("safari/") && !u.Contains("chrome/")) browser = "Safari";

            string os = "Hệ điều hành";
            if (u.Contains("windows")) os = "Windows";
            else if (u.Contains("mac os") || u.Contains("macintosh")) os = "macOS";
            else if (u.Contains("android")) os = "Android";
            else if (u.Contains("iphone") || u.Contains("ios")) os = "iOS";
            else if (u.Contains("linux")) os = "Linux";

            return browser + " · " + os;
        }

        #endregion

        #region Security: change password

        protected void btnChangePw_Click(object sender, EventArgs e)
        {
            var cur = (txtPwCurrent.Text ?? "").Trim();
            var newPw = (txtPwNew.Text ?? "").Trim();
            var confirm = (txtPwConfirm.Text ?? "").Trim();

            if (string.IsNullOrEmpty(cur) || string.IsNullOrEmpty(newPw) || string.IsNullOrEmpty(confirm))
            {
                ShowAlert("Vui lòng điền đầy đủ mật khẩu hiện tại, mật khẩu mới và xác nhận.", isError: true);
                return;
            }

            if (newPw != confirm)
            {
                ShowAlert("Xác nhận mật khẩu không khớp với mật khẩu mới.", isError: true);
                return;
            }

            if (!IsStrongPassword(newPw))
            {
                ShowAlert("Mật khẩu mới chưa đủ mạnh. Cần ≥8 ký tự, có chữ HOA, chữ thường, số và ký tự đặc biệt.", isError: true);
                return;
            }

            try
            {
                string storedHash = "";
                using (var con = Database.OpenConnection())
                {
                    using (var cmd = new SqlCommand(
                        "SELECT password_hash FROM dbo.users WHERE id = @uid;", con))
                    {
                        cmd.Parameters.AddWithValue("@uid", CurrentUserId);
                        var o = cmd.ExecuteScalar();
                        storedHash = o == null ? "" : o.ToString();
                    }

                    if (!VerifyPassword(cur, storedHash))
                    {
                        ShowAlert("Mật khẩu hiện tại không đúng.", isError: true);
                        return;
                    }

                    if (VerifyPassword(newPw, storedHash))
                    {
                        ShowAlert("Mật khẩu mới không được trùng mật khẩu cũ.", isError: true);
                        return;
                    }

                    var newHash = HashPassword(newPw);
                    using (var cmd = new SqlCommand(@"
                        UPDATE dbo.users SET password_hash = @h, updated_at = SYSUTCDATETIME()
                        WHERE id = @uid;", con))
                    {
                        cmd.Parameters.AddWithValue("@h", newHash);
                        cmd.Parameters.AddWithValue("@uid", CurrentUserId);
                        cmd.ExecuteNonQuery();
                    }
                }

                AuthHelper.LogActivity(CurrentUserId, "user.change_password",
                    Request.UserHostAddress, Request.UserAgent);

                txtPwCurrent.Text = txtPwNew.Text = txtPwConfirm.Text = "";
                ShowAlert("✓ Đã cập nhật mật khẩu thành công.", isError: false);
                LoadSecurityInfo();
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi đổi mật khẩu: " + ex.Message, isError: true);
            }
        }

        protected void btnCancelPw_Click(object sender, EventArgs e)
        {
            txtPwCurrent.Text = txtPwNew.Text = txtPwConfirm.Text = "";
            ShowAlert("Đã huỷ thao tác đổi mật khẩu.", isError: false);
        }

        private static bool IsStrongPassword(string s)
        {
            if (string.IsNullOrEmpty(s) || s.Length < 8) return false;
            bool hasUpper = false, hasLower = false, hasDigit = false, hasSpecial = false;
            foreach (var c in s)
            {
                if (char.IsUpper(c)) hasUpper = true;
                else if (char.IsLower(c)) hasLower = true;
                else if (char.IsDigit(c)) hasDigit = true;
                else hasSpecial = true;
            }
            return hasUpper && hasLower && hasDigit && hasSpecial;
        }

        private static string HashPassword(string raw)
        {
            try
            {
                var t = typeof(AuthHelper);
                var mi = t.GetMethod("HashPassword",
                    System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Static);
                if (mi != null)
                {
                    var result = mi.Invoke(null, new object[] { raw }) as string;
                    if (!string.IsNullOrEmpty(result)) return result;
                }
            }
            catch { }

            using (var sha = SHA256.Create())
            {
                var bytes = sha.ComputeHash(Encoding.UTF8.GetBytes(raw));
                var sb = new StringBuilder();
                foreach (var b in bytes) sb.Append(b.ToString("x2"));
                return sb.ToString();
            }
        }

        private static bool VerifyPassword(string raw, string storedHash)
        {
            if (string.IsNullOrEmpty(storedHash)) return false;

            try
            {
                var t = typeof(AuthHelper);
                var mi = t.GetMethod("VerifyPassword",
                    System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Static);
                if (mi != null)
                {
                    var result = mi.Invoke(null, new object[] { raw, storedHash });
                    if (result is bool) return (bool)result;
                }
            }
            catch { }

            var hash = HashPassword(raw);
            return string.Equals(hash, storedHash, StringComparison.OrdinalIgnoreCase);
        }

        #endregion

        #region Security: sessions

        protected void rptSessions_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName != "RevokeSession") return;

            long sid;
            if (!long.TryParse(e.CommandArgument.ToString(), out sid)) return;

            try
            {
                const string sql = @"
                    UPDATE dbo.user_sessions
                    SET revoked_at = SYSUTCDATETIME()
                    WHERE id = @sid AND user_id = @uid;";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@sid", sid);
                    cmd.Parameters.AddWithValue("@uid", CurrentUserId);
                    cmd.ExecuteNonQuery();
                }

                AuthHelper.LogActivity(CurrentUserId, "user.revoke_session",
                    Request.UserHostAddress, Request.UserAgent);

                ShowAlert("Đã đăng xuất phiên này.", isError: false);
                LoadSessions();
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi: " + ex.Message, isError: true);
            }
        }

        protected void btnLogoutOthers_Click(object sender, EventArgs e)
        {
            string currentToken = "";
            try { currentToken = (Session["session_token"] as string) ?? ""; } catch { }

            try
            {
                string sql;
                if (!string.IsNullOrEmpty(currentToken))
                {
                    sql = @"UPDATE dbo.user_sessions
                            SET revoked_at = SYSUTCDATETIME()
                            WHERE user_id = @uid AND revoked_at IS NULL
                              AND session_token <> @tok;";
                }
                else
                {
                    sql = @"UPDATE dbo.user_sessions
                            SET revoked_at = SYSUTCDATETIME()
                            WHERE user_id = @uid AND revoked_at IS NULL;";
                }
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@uid", CurrentUserId);
                    if (!string.IsNullOrEmpty(currentToken))
                        cmd.Parameters.AddWithValue("@tok", currentToken);
                    cmd.ExecuteNonQuery();
                }

                AuthHelper.LogActivity(CurrentUserId, "user.revoke_all_sessions",
                    Request.UserHostAddress, Request.UserAgent);

                ShowAlert("Đã đăng xuất tất cả các phiên khác.", isError: false);
                LoadSessions();
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi: " + ex.Message, isError: true);
            }
        }

        #endregion

        #region Notifications (lưu vào Session, có thể đổi sang bảng riêng sau)

        private const string PREF_KEY = "notif_prefs";

        private class NotifPrefs
        {
            public bool ChEmail = true;
            public bool ChPush = true;
            public bool ChSms = false;
            public bool NotifNewReg = true;
            public bool NotifFull = true;
            public bool NotifReminder = true;
            public bool NotifWeekly = false;
            public bool QuietEnabled = false;
            public string QuietStart = "22:00";
            public string QuietEnd = "07:00";
        }

        private NotifPrefs GetPrefs()
        {
            var p = Session[PREF_KEY + "_" + CurrentUserId] as NotifPrefs;
            return p ?? new NotifPrefs();
        }

        private void SavePrefs(NotifPrefs p)
        {
            Session[PREF_KEY + "_" + CurrentUserId] = p;
        }

        private void LoadNotifications()
        {
            litEmailChannel.Text = HttpUtility.HtmlEncode(GetUserEmail());

            var p = GetPrefs();
            cbChannelEmail.Checked = p.ChEmail;
            cbChannelPush.Checked = p.ChPush;
            cbChannelSms.Checked = p.ChSms;
            cbNotifNewReg.Checked = p.NotifNewReg;
            cbNotifFull.Checked = p.NotifFull;
            cbNotifReminder.Checked = p.NotifReminder;
            cbNotifWeekly.Checked = p.NotifWeekly;
            cbQuietEnabled.Checked = p.QuietEnabled;
            txtQuietStart.Text = p.QuietStart;
            txtQuietEnd.Text = p.QuietEnd;
        }

        private string GetUserEmail()
        {
            try
            {
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand("SELECT email FROM dbo.users WHERE id = @uid;", con))
                {
                    cmd.Parameters.AddWithValue("@uid", CurrentUserId);
                    var o = cmd.ExecuteScalar();
                    return o == null || o == DBNull.Value ? "" : o.ToString();
                }
            }
            catch { return ""; }
        }

        protected void btnSaveNotif_Click(object sender, EventArgs e)
        {
            var p = new NotifPrefs
            {
                ChEmail = cbChannelEmail.Checked,
                ChPush = cbChannelPush.Checked,
                ChSms = cbChannelSms.Checked,
                NotifNewReg = cbNotifNewReg.Checked,
                NotifFull = cbNotifFull.Checked,
                NotifReminder = cbNotifReminder.Checked,
                NotifWeekly = cbNotifWeekly.Checked,
                QuietEnabled = cbQuietEnabled.Checked,
                QuietStart = txtQuietStart.Text,
                QuietEnd = txtQuietEnd.Text
            };
            SavePrefs(p);

            AuthHelper.LogActivity(CurrentUserId, "user.update_notif_prefs",
                Request.UserHostAddress, Request.UserAgent);

            ShowAlert("✓ Đã lưu cài đặt thông báo.", isError: false);
        }

        protected void btnCancelNotif_Click(object sender, EventArgs e)
        {
            LoadNotifications();
            ShowAlert("Đã khôi phục cài đặt thông báo.", isError: false);
        }

        #endregion

        #region Helpers

        private static string RelativeTime(DateTime past)
        {
            var diff = DateTime.Now - past;
            if (diff.TotalSeconds < 60) return "vừa xong";
            if (diff.TotalMinutes < 60) return ((int)diff.TotalMinutes) + " phút trước";
            if (diff.TotalHours < 24) return ((int)diff.TotalHours) + " giờ trước";
            if (diff.TotalDays < 30) return ((int)diff.TotalDays) + " ngày trước";
            return past.ToString("dd/MM/yyyy");
        }

        private void ShowAlert(string msg, bool isError)
        {
            pnlAlert.Visible = true;
            pnlAlert.CssClass = isError ? "alert alert-error" : "alert alert-success";
            litAlert.Text = HttpUtility.HtmlEncode(msg);
        }

        #endregion
    }
}