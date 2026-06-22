using Eventhub.App_Code;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Eventhub.Admin
{
    public partial class UserManagement : System.Web.UI.Page
    {
        private const int DefaultPageSize = 10;

        #region View Model

        public class UserRowVM
        {
            public long Id { get; set; }
            public int RowNum { get; set; }
            public string FullName { get; set; }
            public string Initial { get; set; }
            public int ColorIndex { get; set; }
            public string StatusDotClass { get; set; }
            public string EmployeeCode { get; set; }
            public string Email { get; set; }
            public string DepartmentName { get; set; }
            public int DeptDotIndex { get; set; }
            public string RoleCode { get; set; }
            public string RoleName { get; set; }
            public bool IsActive { get; set; }
            public string StatusClass { get; set; }
            public string StatusText { get; set; }
            public int EventsJoined { get; set; }
            public string LastLoginText { get; set; }
            public string LastLoginSub { get; set; }
            public DateTime CreatedAt { get; set; }
        }

        public class PageNumVM
        {
            public int PageNum { get; set; }
            public bool IsCurrent { get; set; }
        }

        #endregion

        #region Properties

        private string CurrentStatus
        {
            get { return string.IsNullOrEmpty(hfStatusFilter.Value) ? "all" : hfStatusFilter.Value; }
            set { hfStatusFilter.Value = value ?? "all"; }
        }

        private int CurrentPage
        {
            get { int p; return int.TryParse(hfPage.Value, out p) && p > 0 ? p : 1; }
            set { hfPage.Value = value.ToString(); }
        }

        private int PageSize
        {
            get { int n; return int.TryParse(ddlPageSize.SelectedValue, out n) && n > 0 ? n : DefaultPageSize; }
        }

        private string Keyword
        {
            get { return (ViewState["kw"] as string) ?? ""; }
            set { ViewState["kw"] = value ?? ""; }
        }

        private long FilterDepartmentId
        {
            get { return (long)(ViewState["dept"] ?? 0L); }
            set { ViewState["dept"] = value; }
        }

        private long FilterRoleId
        {
            get { return (long)(ViewState["role"] ?? 0L); }
            set { ViewState["role"] = value; }
        }

        private long EditId
        {
            get { long id; long.TryParse(hfEditId.Value, out id); return id; }
            set { hfEditId.Value = value.ToString(); }
        }

        #endregion

        protected void Page_Load(object sender, EventArgs e)
        {
            var master = Master as Eventhub.AdminMaster;
            if (master != null) master.Breadcrumb = "Quản lý Người dùng";

            if (!IsPostBack)
            {
                var qs = Request.QueryString["status"];
                if (!string.IsNullOrEmpty(qs) &&
                    new[] { "all", "active", "new", "locked", "admin" }.Contains(qs))
                    CurrentStatus = qs;
                else
                    CurrentStatus = "all";

                LoadDepartments();
                LoadRoles();
                LoadCounts();
                LoadUsers();
            }

            SetTabUrls();
            SetActiveTab();
            litUpdatedAt.Text = DateTime.Now.ToString("HH:mm, dd/MM/yyyy");
        }

        #region Tab URLs & active

        private void SetTabUrls()
        {
            tabAll.NavigateUrl = "~/Admin/UserManagement.aspx?status=all";
            tabActive.NavigateUrl = "~/Admin/UserManagement.aspx?status=active";
            tabNew.NavigateUrl = "~/Admin/UserManagement.aspx?status=new";
            tabLocked.NavigateUrl = "~/Admin/UserManagement.aspx?status=locked";
            tabAdmin.NavigateUrl = "~/Admin/UserManagement.aspx?status=admin";
        }

        private void SetActiveTab()
        {
            tabAll.CssClass = "stat-tab" + (CurrentStatus == "all" ? " active" : "");
            tabActive.CssClass = "stat-tab" + (CurrentStatus == "active" ? " active" : "");
            tabNew.CssClass = "stat-tab" + (CurrentStatus == "new" ? " active" : "");
            tabLocked.CssClass = "stat-tab" + (CurrentStatus == "locked" ? " active" : "");
            tabAdmin.CssClass = "stat-tab" + (CurrentStatus == "admin" ? " active" : "");
        }

        #endregion

        #region Load dropdowns

        private void LoadDepartments()
        {
            ddlDepartment.Items.Clear();
            ddlMDepartment.Items.Clear();
            ddlDepartment.Items.Add(new ListItem("Phòng ban: Tất cả", "0"));
            ddlMDepartment.Items.Add(new ListItem("— Chọn phòng ban —", "0"));
            try
            {
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(
                    "SELECT id, name FROM dbo.departments WHERE is_active = 1 ORDER BY name;", con))
                using (var rd = cmd.ExecuteReader())
                {
                    while (rd.Read())
                    {
                        var id = Convert.ToInt64(rd["id"]).ToString();
                        var name = rd["name"].ToString();
                        ddlDepartment.Items.Add(new ListItem(name, id));
                        ddlMDepartment.Items.Add(new ListItem(name, id));
                    }
                }
            }
            catch { }
        }

        private void LoadRoles()
        {
            ddlRole.Items.Clear();
            ddlMRole.Items.Clear();
            ddlRole.Items.Add(new ListItem("Vai trò: Tất cả", "0"));
            try
            {
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand("SELECT id, code, name FROM dbo.roles ORDER BY id;", con))
                using (var rd = cmd.ExecuteReader())
                {
                    while (rd.Read())
                    {
                        var id = Convert.ToInt64(rd["id"]).ToString();
                        var name = rd["name"].ToString();
                        ddlRole.Items.Add(new ListItem(name, id));
                        ddlMRole.Items.Add(new ListItem(name, id));
                    }
                }
            }
            catch { }
        }

        #endregion

        #region Load Counts

        private void LoadCounts()
        {
            int total = 0, active = 0, newM = 0, locked = 0, admin = 0;
            int prevMonth = 0;

            try
            {
                const string sql = @"
                    SELECT
                        COUNT(*) AS total_cnt,
                        SUM(CASE WHEN is_active = 1 THEN 1 ELSE 0 END) AS active_cnt,
                        SUM(CASE WHEN is_active = 0 THEN 1 ELSE 0 END) AS locked_cnt,
                        SUM(CASE WHEN MONTH(created_at) = MONTH(SYSDATETIME())
                              AND YEAR(created_at) = YEAR(SYSDATETIME()) THEN 1 ELSE 0 END) AS new_cnt,
                        SUM(CASE WHEN created_at >= DATEADD(MONTH, -1, SYSDATETIME())
                                AND created_at < DATEFROMPARTS(YEAR(SYSDATETIME()), MONTH(SYSDATETIME()), 1)
                              THEN 1 ELSE 0 END) AS prev_month_cnt,
                        (SELECT COUNT(*) FROM dbo.users u
                         JOIN dbo.roles r ON r.id = u.role_id
                         WHERE r.code = N'admin') AS admin_cnt
                    FROM dbo.users;";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                using (var rd = cmd.ExecuteReader())
                {
                    if (rd.Read())
                    {
                        total = rd["total_cnt"] == DBNull.Value ? 0 : Convert.ToInt32(rd["total_cnt"]);
                        active = rd["active_cnt"] == DBNull.Value ? 0 : Convert.ToInt32(rd["active_cnt"]);
                        locked = rd["locked_cnt"] == DBNull.Value ? 0 : Convert.ToInt32(rd["locked_cnt"]);
                        newM = rd["new_cnt"] == DBNull.Value ? 0 : Convert.ToInt32(rd["new_cnt"]);
                        prevMonth = rd["prev_month_cnt"] == DBNull.Value ? 0 : Convert.ToInt32(rd["prev_month_cnt"]);
                        admin = rd["admin_cnt"] == DBNull.Value ? 0 : Convert.ToInt32(rd["admin_cnt"]);
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("LoadCounts error: " + ex.Message);
            }

            litTotalUsers.Text = total.ToString("N0");
            litCntAll.Text = total.ToString("N0");
            litCntActive.Text = active.ToString("N0");
            litCntNew.Text = newM.ToString("N0");
            litCntLocked.Text = locked.ToString("N0");
            litCntAdmin.Text = admin.ToString("N0");

            litDeltaAll.Text = newM > 0 ? "+ " + newM + " tháng này" : "—";
            litDeltaActive.Text = total > 0
                ? Math.Round(active * 100.0 / total, 1).ToString("F1") + "% tổng số"
                : "—";
            litDeltaNew.Text = prevMonth > 0
                ? (newM >= prevMonth ? "+" : "") + (newM - prevMonth) + " so với tháng trước"
                : (newM > 0 ? "+" + newM + " tài khoản mới" : "—");
            litDeltaLocked.Text = locked > 0 ? "Cần kiểm tra" : "Tốt";
            litDeltaAdmin.Text = "Không đổi";
        }

        #endregion

        #region Load Users

        private void LoadUsers()
        {
            var list = new List<UserRowVM>();
            int totalRows = 0;

            var where = new StringBuilder(" WHERE 1=1 ");

            switch (CurrentStatus)
            {
                case "active": where.Append(" AND u.is_active = 1 "); break;
                case "locked": where.Append(" AND u.is_active = 0 "); break;
                case "new": where.Append(" AND MONTH(u.created_at) = MONTH(SYSDATETIME()) AND YEAR(u.created_at) = YEAR(SYSDATETIME()) "); break;
                case "admin": where.Append(" AND r.code = N'admin' "); break;
            }

            if (!string.IsNullOrEmpty(Keyword))
                where.Append(@" AND (u.first_name + N' ' + u.last_name LIKE @kw
                                OR u.email LIKE @kw
                                OR u.employee_code LIKE @kw) ");

            if (FilterDepartmentId > 0)
                where.Append(" AND u.department_id = @did ");
            if (FilterRoleId > 0)
                where.Append(" AND u.role_id = @rid ");

            var sql = @"
                ;WITH q AS (
                    SELECT u.id, u.first_name, u.last_name, u.display_name, u.email,
                           u.employee_code, u.is_active, u.last_login_at, u.created_at,
                           u.department_id,
                           ISNULL(d.name, N'(Chưa có)') AS dept_name,
                           r.id AS role_id, r.code AS role_code, r.name AS role_name,
                           ROW_NUMBER() OVER (ORDER BY u.created_at DESC, u.id DESC) AS rn,
                           COUNT(*) OVER () AS total_cnt
                    FROM dbo.users u
                    LEFT JOIN dbo.departments d ON d.id = u.department_id
                    JOIN dbo.roles r ON r.id = u.role_id
                    " + where + @"
                )
                SELECT * FROM q
                WHERE rn > @skip AND rn <= @take
                ORDER BY rn;";

            try
            {
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@skip", (CurrentPage - 1) * PageSize);
                    cmd.Parameters.AddWithValue("@take", CurrentPage * PageSize);
                    if (!string.IsNullOrEmpty(Keyword))
                        cmd.Parameters.AddWithValue("@kw", "%" + Keyword + "%");
                    if (FilterDepartmentId > 0)
                        cmd.Parameters.AddWithValue("@did", FilterDepartmentId);
                    if (FilterRoleId > 0)
                        cmd.Parameters.AddWithValue("@rid", FilterRoleId);

                    using (var rd = cmd.ExecuteReader())
                    {
                        while (rd.Read())
                        {
                            var name = (rd["first_name"].ToString() + " " + rd["last_name"].ToString()).Trim();
                            var rn = Convert.ToInt32(rd["rn"]);
                            totalRows = Convert.ToInt32(rd["total_cnt"]);
                            var isActive = Convert.ToBoolean(rd["is_active"]);
                            DateTime? lastLogin = rd["last_login_at"] == DBNull.Value
                                ? (DateTime?)null
                                : Convert.ToDateTime(rd["last_login_at"]);
                            long? deptId = rd["department_id"] == DBNull.Value
                                ? (long?)null
                                : Convert.ToInt64(rd["department_id"]);

                            var displayName = rd["display_name"] as string;
                            var displayed = string.IsNullOrEmpty(displayName) ? name : displayName;

                            list.Add(new UserRowVM
                            {
                                Id = Convert.ToInt64(rd["id"]),
                                RowNum = rn,
                                FullName = displayed,
                                Initial = BuildInitials(name),
                                ColorIndex = ((int)(Convert.ToInt64(rd["id"]) % 7)) + 1,
                                StatusDotClass = (lastLogin.HasValue && (DateTime.Now - lastLogin.Value).TotalMinutes < 15)
                                                   ? "online" : "offline",
                                EmployeeCode = rd["employee_code"] as string ?? "",
                                Email = rd["email"].ToString(),
                                DepartmentName = rd["dept_name"].ToString(),
                                DeptDotIndex = deptId.HasValue ? (int)(deptId.Value % 6) + 1 : 1,
                                RoleCode = rd["role_code"].ToString(),
                                RoleName = rd["role_name"].ToString(),
                                IsActive = isActive,
                                StatusClass = isActive ? "active" : "locked",
                                StatusText = isActive ? "Hoạt động" : "Bị khoá",
                                LastLoginText = lastLogin.HasValue ? BuildLastLoginText(lastLogin.Value) : "Chưa đăng nhập",
                                LastLoginSub = lastLogin.HasValue ? lastLogin.Value.ToString("dd/MM/yyyy HH:mm") : "",
                                CreatedAt = Convert.ToDateTime(rd["created_at"])
                            });
                        }
                    }
                }

                if (list.Count > 0)
                {
                    var ids = string.Join(",", list.Select(x => x.Id));
                    var sqlEv = @"
                        SELECT user_id, COUNT(*) AS c
                        FROM dbo.event_registrations
                        WHERE status = N'approved' AND user_id IN (" + ids + @")
                        GROUP BY user_id;";
                    using (var con = Database.OpenConnection())
                    using (var cmd = new SqlCommand(sqlEv, con))
                    using (var rd = cmd.ExecuteReader())
                    {
                        while (rd.Read())
                        {
                            var uid = Convert.ToInt64(rd["user_id"]);
                            var c = Convert.ToInt32(rd["c"]);
                            var u = list.FirstOrDefault(x => x.Id == uid);
                            if (u != null) u.EventsJoined = c;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi tải danh sách: " + ex.Message, isError: true);
            }

            rptUsers.DataSource = list;
            rptUsers.DataBind();
            phEmpty.Visible = list.Count == 0;

            int totalPages = Math.Max(1, (int)Math.Ceiling(totalRows / (double)PageSize));
            if (CurrentPage > totalPages) CurrentPage = totalPages;

            litPageFrom.Text = totalRows == 0 ? "0" : (((CurrentPage - 1) * PageSize) + 1).ToString();
            litPageTo.Text = Math.Min(CurrentPage * PageSize, totalRows).ToString();
            litPageTotal.Text = totalRows.ToString("N0");

            btnPrev.Enabled = CurrentPage > 1;
            btnNext.Enabled = CurrentPage < totalPages;

            BuildPager(totalPages);
        }

        private void BuildPager(int totalPages)
        {
            var pages = new List<PageNumVM>();
            int start = Math.Max(1, CurrentPage - 2);
            int end = Math.Min(totalPages, CurrentPage + 2);
            for (int i = start; i <= end; i++)
                pages.Add(new PageNumVM { PageNum = i, IsCurrent = i == CurrentPage });

            rptPager.DataSource = pages;
            rptPager.DataBind();
        }

        #endregion

        #region Filter / Pagination handlers

        protected void Filter_Changed(object sender, EventArgs e)
        {
            long id;
            long.TryParse(ddlDepartment.SelectedValue, out id); FilterDepartmentId = id;
            long.TryParse(ddlRole.SelectedValue, out id); FilterRoleId = id;
            CurrentPage = 1;
            LoadUsers();
        }

        protected void btnSearch_Click(object sender, EventArgs e)
        {
            Keyword = (txtSearch.Text ?? "").Trim();
            CurrentPage = 1;
            LoadUsers();
        }

        protected void btnClearFilter_Click(object sender, EventArgs e)
        {
            Response.Redirect("~/Admin/UserManagement.aspx");
        }

        protected void ddlPageSize_Changed(object sender, EventArgs e)
        {
            CurrentPage = 1;
            LoadUsers();
        }

        protected void btnPrev_Click(object sender, EventArgs e)
        {
            if (CurrentPage > 1) CurrentPage--;
            LoadUsers();
        }

        protected void btnNext_Click(object sender, EventArgs e)
        {
            CurrentPage++;
            LoadUsers();
        }

        protected void rptPager_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName != "GoPage") return;
            int p;
            if (int.TryParse(e.CommandArgument.ToString(), out p) && p > 0)
            {
                CurrentPage = p;
                LoadUsers();
            }
        }

        #endregion

        #region Row actions

        protected void rptUsers_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            long uid;
            if (!long.TryParse((e.CommandArgument ?? "").ToString(), out uid)) return;

            switch (e.CommandName)
            {
                case "Edit": OpenEditModal(uid); break;
                case "ToggleLock": ToggleLock(uid); LoadCounts(); LoadUsers(); break;
                case "Delete": DeleteUser(uid); LoadCounts(); LoadUsers(); break;
            }
        }

        private void ToggleLock(long userId)
        {
            try
            {
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(@"
                    UPDATE dbo.users
                    SET is_active = CASE WHEN is_active = 1 THEN 0 ELSE 1 END,
                        updated_at = SYSUTCDATETIME()
                    WHERE id = @uid;", con))
                {
                    cmd.Parameters.AddWithValue("@uid", userId);
                    cmd.ExecuteNonQuery();
                }
                LogActivitySafe("user.toggle_lock");
                ShowAlert("Đã cập nhật trạng thái tài khoản.", isError: false);
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi: " + ex.Message, isError: true);
            }
        }

        private void DeleteUser(long userId)
        {
            var me = AuthHelper.CurrentUser(Session);
            if (me != null && me.Id == userId)
            {
                ShowAlert("Không thể xoá tài khoản đang đăng nhập.", isError: true);
                return;
            }

            try
            {
                using (var con = Database.OpenConnection())
                {
                    try
                    {
                        using (var cmd = new SqlCommand("DELETE FROM dbo.users WHERE id = @uid;", con))
                        {
                            cmd.Parameters.AddWithValue("@uid", userId);
                            cmd.ExecuteNonQuery();
                        }
                        LogActivitySafe("user.delete");
                        ShowAlert("Đã xoá tài khoản.", isError: false);
                        return;
                    }
                    catch (SqlException)
                    {
                        // FK constraint → soft delete
                        using (var cmd = new SqlCommand(@"
                            UPDATE dbo.users SET is_active = 0, updated_at = SYSUTCDATETIME()
                            WHERE id = @uid;", con))
                        {
                            cmd.Parameters.AddWithValue("@uid", userId);
                            cmd.ExecuteNonQuery();
                        }
                        LogActivitySafe("user.deactivate");
                        ShowAlert("Không thể xoá vĩnh viễn (tài khoản đã có dữ liệu liên quan). Đã chuyển sang trạng thái KHOÁ.", isError: false);
                    }
                }
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi: " + ex.Message, isError: true);
            }
        }

        #endregion

        #region Modal Add/Edit

        protected void btnOpenAdd_Click(object sender, EventArgs e)
        {
            EditId = 0;
            litModalTitle.Text = "Thêm người dùng mới";
            litModalSub.Text = "Tạo tài khoản và gán phòng ban / vai trò.";

            txtMFirstName.Text = "";
            txtMLastName.Text = "";
            txtMEmail.Text = "";
            txtMEmpCode.Text = "";
            txtMPhone.Text = "";
            txtMJobTitle.Text = "";
            ddlMDepartment.ClearSelection();
            if (ddlMDepartment.Items.Count > 0) ddlMDepartment.Items[0].Selected = true;

            ddlMRole.ClearSelection();
            ListItem defaultRole = null;
            foreach (ListItem it in ddlMRole.Items)
            {
                var lt = (it.Text ?? "").ToLower();
                if (lt.Contains("nhân viên") || lt.Contains("employee"))
                { defaultRole = it; break; }
            }
            if (defaultRole != null) defaultRole.Selected = true;
            else if (ddlMRole.Items.Count > 0) ddlMRole.Items[0].Selected = true;

            cbMIsActive.Checked = true;
            pnlMPassword.Visible = true;
            txtMPassword.Text = "";

            pnlModal.Visible = true;
        }

        private void OpenEditModal(long userId)
        {
            EditId = userId;
            try
            {
                const string sql = @"
                    SELECT first_name, last_name, email, employee_code, phone, job_title,
                           department_id, role_id, is_active
                    FROM dbo.users WHERE id = @uid;";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@uid", userId);
                    using (var rd = cmd.ExecuteReader())
                    {
                        if (!rd.Read())
                        {
                            ShowAlert("Không tìm thấy người dùng.", isError: true);
                            return;
                        }

                        var fn = rd["first_name"].ToString();
                        var ln = rd["last_name"].ToString();
                        litModalTitle.Text = "Chỉnh sửa: " + HttpUtility.HtmlEncode((fn + " " + ln).Trim());
                        litModalSub.Text = "Cập nhật thông tin tài khoản. Mật khẩu không thay đổi qua form này.";

                        txtMFirstName.Text = fn;
                        txtMLastName.Text = ln;
                        txtMEmail.Text = rd["email"].ToString();
                        txtMEmpCode.Text = rd["employee_code"] as string ?? "";
                        txtMPhone.Text = rd["phone"] as string ?? "";
                        txtMJobTitle.Text = rd["job_title"] as string ?? "";

                        ddlMDepartment.ClearSelection();
                        if (rd["department_id"] != DBNull.Value)
                        {
                            var did = Convert.ToInt64(rd["department_id"]).ToString();
                            var it = ddlMDepartment.Items.FindByValue(did);
                            if (it != null) it.Selected = true;
                            else if (ddlMDepartment.Items.Count > 0) ddlMDepartment.Items[0].Selected = true;
                        }
                        else if (ddlMDepartment.Items.Count > 0) ddlMDepartment.Items[0].Selected = true;

                        var rid = Convert.ToInt64(rd["role_id"]).ToString();
                        var ri = ddlMRole.Items.FindByValue(rid);
                        ddlMRole.ClearSelection();
                        if (ri != null) ri.Selected = true;

                        cbMIsActive.Checked = Convert.ToBoolean(rd["is_active"]);
                    }
                }

                pnlMPassword.Visible = false;
                txtMPassword.Text = "";
                pnlModal.Visible = true;
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi tải user: " + ex.Message, isError: true);
            }
        }

        protected void btnCloseModal_Click(object sender, EventArgs e)
        {
            pnlModal.Visible = false;
            EditId = 0;
        }

        protected void btnSaveUser_Click(object sender, EventArgs e)
        {
            var fn = (txtMFirstName.Text ?? "").Trim();
            var ln = (txtMLastName.Text ?? "").Trim();
            var em = (txtMEmail.Text ?? "").Trim();

            if (string.IsNullOrEmpty(fn) || string.IsNullOrEmpty(ln) || string.IsNullOrEmpty(em))
            {
                ShowAlert("Họ, Tên và Email không được để trống.", isError: true);
                pnlModal.Visible = true;
                return;
            }
            if (!Regex.IsMatch(em, @"^[^@\s]+@[^@\s]+\.[^@\s]+$"))
            {
                ShowAlert("Định dạng email không hợp lệ.", isError: true);
                pnlModal.Visible = true;
                return;
            }

            long roleId; long.TryParse(ddlMRole.SelectedValue, out roleId);
            if (roleId <= 0)
            {
                ShowAlert("Vui lòng chọn vai trò.", isError: true);
                pnlModal.Visible = true;
                return;
            }

            long deptId; long.TryParse(ddlMDepartment.SelectedValue, out deptId);
            var phone = (txtMPhone.Text ?? "").Trim();
            var jobTitle = (txtMJobTitle.Text ?? "").Trim();
            var empCode = (txtMEmpCode.Text ?? "").Trim();
            bool isActive = cbMIsActive.Checked;

            try
            {
                using (var con = Database.OpenConnection())
                {
                    using (var cmd = new SqlCommand(
                        "SELECT COUNT(*) FROM dbo.users WHERE email = @em AND id <> @uid;", con))
                    {
                        cmd.Parameters.AddWithValue("@em", em);
                        cmd.Parameters.AddWithValue("@uid", EditId);
                        if (Convert.ToInt32(cmd.ExecuteScalar()) > 0)
                        {
                            ShowAlert("Email \"" + em + "\" đã được dùng bởi tài khoản khác.", isError: true);
                            pnlModal.Visible = true;
                            return;
                        }
                    }
                    if (!string.IsNullOrEmpty(empCode))
                    {
                        using (var cmd = new SqlCommand(
                            "SELECT COUNT(*) FROM dbo.users WHERE employee_code = @ec AND id <> @uid;", con))
                        {
                            cmd.Parameters.AddWithValue("@ec", empCode);
                            cmd.Parameters.AddWithValue("@uid", EditId);
                            if (Convert.ToInt32(cmd.ExecuteScalar()) > 0)
                            {
                                ShowAlert("Mã NV \"" + empCode + "\" đã tồn tại.", isError: true);
                                pnlModal.Visible = true;
                                return;
                            }
                        }
                    }

                    if (EditId > 0)
                    {
                        const string sql = @"
                            UPDATE dbo.users SET
                                first_name    = @fn,
                                last_name     = @ln,
                                email         = @em,
                                employee_code = @ec,
                                phone         = @ph,
                                job_title     = @jt,
                                department_id = @did,
                                role_id       = @rid,
                                is_active     = @ia,
                                updated_at    = SYSUTCDATETIME()
                            WHERE id = @uid;";
                        using (var cmd = new SqlCommand(sql, con))
                        {
                            cmd.Parameters.AddWithValue("@fn", fn);
                            cmd.Parameters.AddWithValue("@ln", ln);
                            cmd.Parameters.AddWithValue("@em", em);
                            cmd.Parameters.AddWithValue("@ec", string.IsNullOrEmpty(empCode) ? (object)DBNull.Value : empCode);
                            cmd.Parameters.AddWithValue("@ph", string.IsNullOrEmpty(phone) ? (object)DBNull.Value : phone);
                            cmd.Parameters.AddWithValue("@jt", string.IsNullOrEmpty(jobTitle) ? (object)DBNull.Value : jobTitle);
                            cmd.Parameters.AddWithValue("@did", deptId > 0 ? (object)deptId : DBNull.Value);
                            cmd.Parameters.AddWithValue("@rid", roleId);
                            cmd.Parameters.AddWithValue("@ia", isActive ? 1 : 0);
                            cmd.Parameters.AddWithValue("@uid", EditId);
                            cmd.ExecuteNonQuery();
                        }
                        LogActivitySafe("user.update");
                        ShowAlert("✓ Đã cập nhật người dùng.", isError: false);
                    }
                    else
                    {
                        var pw = (txtMPassword.Text ?? "").Trim();
                        if (string.IsNullOrEmpty(pw) || pw.Length < 8)
                        {
                            ShowAlert("Mật khẩu khởi tạo phải có ít nhất 8 ký tự.", isError: true);
                            pnlModal.Visible = true;
                            return;
                        }
                        var pwHash = HashPassword(pw);

                        const string sql = @"
                            INSERT INTO dbo.users
                                (employee_code, email, password_hash, first_name, last_name,
                                 phone, job_title, department_id, role_id, is_active)
                            VALUES
                                (@ec, @em, @h, @fn, @ln, @ph, @jt, @did, @rid, @ia);";
                        using (var cmd = new SqlCommand(sql, con))
                        {
                            cmd.Parameters.AddWithValue("@ec", string.IsNullOrEmpty(empCode) ? (object)DBNull.Value : empCode);
                            cmd.Parameters.AddWithValue("@em", em);
                            cmd.Parameters.AddWithValue("@h", pwHash);
                            cmd.Parameters.AddWithValue("@fn", fn);
                            cmd.Parameters.AddWithValue("@ln", ln);
                            cmd.Parameters.AddWithValue("@ph", string.IsNullOrEmpty(phone) ? (object)DBNull.Value : phone);
                            cmd.Parameters.AddWithValue("@jt", string.IsNullOrEmpty(jobTitle) ? (object)DBNull.Value : jobTitle);
                            cmd.Parameters.AddWithValue("@did", deptId > 0 ? (object)deptId : DBNull.Value);
                            cmd.Parameters.AddWithValue("@rid", roleId);
                            cmd.Parameters.AddWithValue("@ia", isActive ? 1 : 0);
                            cmd.ExecuteNonQuery();
                        }
                        LogActivitySafe("user.create");
                        ShowAlert("✓ Đã thêm người dùng \"" + (fn + " " + ln).Trim() + "\".", isError: false);
                    }
                }

                pnlModal.Visible = false;
                EditId = 0;
                LoadCounts();
                LoadUsers();
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi lưu: " + ex.Message, isError: true);
                pnlModal.Visible = true;
            }
        }

        #endregion

        #region Export CSV

        protected void btnExport_Click(object sender, EventArgs e)
        {
            try
            {
                const string sql = @"
                    SELECT u.id, u.employee_code, u.email,
                           u.first_name, u.last_name,
                           u.phone, u.job_title,
                           ISNULL(d.name, N'') AS dept_name,
                           r.name AS role_name,
                           CASE WHEN u.is_active = 1 THEN N'Hoạt động' ELSE N'Bị khoá' END AS status_text,
                           u.last_login_at, u.created_at
                    FROM dbo.users u
                    LEFT JOIN dbo.departments d ON d.id = u.department_id
                    JOIN dbo.roles r ON r.id = u.role_id
                    ORDER BY u.created_at DESC;";

                var sb = new StringBuilder();
                sb.Append('\uFEFF'); // BOM for UTF-8
                sb.AppendLine("ID,Mã NV,Email,Họ,Tên,SĐT,Chức danh,Phòng ban,Vai trò,Trạng thái,Đăng nhập gần nhất,Ngày tạo");

                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                using (var rd = cmd.ExecuteReader())
                {
                    while (rd.Read())
                    {
                        sb.Append(rd["id"]).Append(',');
                        sb.Append(CsvField(rd["employee_code"] as string ?? "")).Append(',');
                        sb.Append(CsvField(rd["email"].ToString())).Append(',');
                        sb.Append(CsvField(rd["first_name"].ToString())).Append(',');
                        sb.Append(CsvField(rd["last_name"].ToString())).Append(',');
                        sb.Append(CsvField(rd["phone"] as string ?? "")).Append(',');
                        sb.Append(CsvField(rd["job_title"] as string ?? "")).Append(',');
                        sb.Append(CsvField(rd["dept_name"].ToString())).Append(',');
                        sb.Append(CsvField(rd["role_name"].ToString())).Append(',');
                        sb.Append(CsvField(rd["status_text"].ToString())).Append(',');
                        sb.Append(rd["last_login_at"] == DBNull.Value
                            ? "" : Convert.ToDateTime(rd["last_login_at"]).ToString("yyyy-MM-dd HH:mm")).Append(',');
                        sb.Append(Convert.ToDateTime(rd["created_at"]).ToString("yyyy-MM-dd HH:mm"));
                        sb.AppendLine();
                    }
                }

                LogActivitySafe("user.export");

                var filename = "users-" + DateTime.Now.ToString("yyyyMMdd-HHmmss") + ".csv";
                Response.Clear();
                Response.ContentType = "text/csv; charset=utf-8";
                Response.AddHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
                Response.Write(sb.ToString());
                Response.End();
            }
            catch (System.Threading.ThreadAbortException) { /* normal end */ }
            catch (Exception ex)
            {
                ShowAlert("Lỗi xuất CSV: " + ex.Message, isError: true);
            }
        }

        private static string CsvField(string s)
        {
            if (string.IsNullOrEmpty(s)) return "";
            if (s.Contains(",") || s.Contains("\"") || s.Contains("\n"))
                return "\"" + s.Replace("\"", "\"\"") + "\"";
            return s;
        }

        #endregion

        #region Helpers

        private static string BuildInitials(string fullName)
        {
            if (string.IsNullOrEmpty(fullName)) return "?";
            var parts = fullName.Trim().Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length == 1) return parts[0].Substring(0, 1).ToUpper();
            return (parts[0].Substring(0, 1) + parts[parts.Length - 1].Substring(0, 1)).ToUpper();
        }

        private static string BuildLastLoginText(DateTime past)
        {
            var diff = DateTime.Now - past;
            if (diff.TotalSeconds < 60) return "Vừa xong";
            if (diff.TotalMinutes < 60) return ((int)diff.TotalMinutes) + " phút trước";
            if (past.Date == DateTime.Today) return "Hôm nay, " + past.ToString("HH:mm");
            if (diff.TotalDays < 2) return "Hôm qua, " + past.ToString("HH:mm");
            if (diff.TotalDays < 30) return ((int)diff.TotalDays) + " ngày trước";
            return past.ToString("dd/MM/yyyy");
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

        private void LogActivitySafe(string action)
        {
            try
            {
                var u = AuthHelper.CurrentUser(Session);
                if (u != null)
                    AuthHelper.LogActivity(u.Id, action, Request.UserHostAddress, Request.UserAgent);
            }
            catch { }
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