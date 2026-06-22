using Eventhub.App_Code;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Eventhub.Admin
{
    public partial class Attendancedetail : System.Web.UI.Page
    {
        #region View Models

        public class AttRowVM
        {
            public long RegistrationId { get; set; }
            public long UserId { get; set; }
            public string FullName { get; set; }
            public string EmpId { get; set; }
            public string Department { get; set; }
            public string Initial { get; set; }
            public int ColorIndex { get; set; }

            public string Status { get; set; }   
            public DateTime? CheckedInAt { get; set; }
            public bool IsLate { get; set; }

            // UI helpers
            public string RowClass { get; set; }
            public string TimeText { get; set; }
            public string TimePillClass { get; set; }
        }

        public class FeedRowVM
        {
            public string FullName { get; set; }
            public string Department { get; set; }
            public string Initial { get; set; }
            public int ColorIndex { get; set; }
            public DateTime CheckedInAt { get; set; }
            public string TimeAgo { get; set; }
        }

        public class DeptRowVM
        {
            public string Name { get; set; }
            public int ApprovedCount { get; set; }
            public int PresentCount { get; set; }
            public int Percent
            {
                get
                {
                    if (ApprovedCount <= 0) return 0;
                    return Math.Min(100, (int)Math.Round(PresentCount * 100.0 / ApprovedCount));
                }
            }
        }

        #endregion

        #region Properties

        private long EventId
        {
            get
            {
                long id;
                long.TryParse(Request.QueryString["eventId"] ?? Request.QueryString["id"], out id);
                return id;
            }
        }

        private string Filter
        {
            get { return string.IsNullOrEmpty(hfTabFilter.Value) ? "all" : hfTabFilter.Value; }
            set { hfTabFilter.Value = value ?? "all"; }
        }

        private string Keyword
        {
            get { return (ViewState["kw"] as string) ?? ""; }
            set { ViewState["kw"] = value ?? ""; }
        }

        private long DepartmentId
        {
            get { return (long)(ViewState["dept"] ?? 0L); }
            set { ViewState["dept"] = value; }
        }

        private string SortOrder
        {
            get { return (ViewState["sort"] as string) ?? "name"; }
            set { ViewState["sort"] = value; }
        }

        private DateTime EventStartAt
        {
            get { return (DateTime)(ViewState["startAt"] ?? DateTime.MinValue); }
            set { ViewState["startAt"] = value; }
        }

        #endregion

        protected void Page_Load(object sender, EventArgs e)
        {
            var master = Master as Eventhub.AdminMaster;
            if (master != null) master.Breadcrumb = "Điểm danh";

            if (EventId <= 0)
            {
                Response.Redirect("~/Admin/AttendanceHub.aspx");
                return;
            }

            if (!IsPostBack)
            {
                var qs = Request.QueryString["filter"];
                if (!string.IsNullOrEmpty(qs) &&
                    new[] { "all", "present", "absent", "late" }.Contains(qs))
                    Filter = qs;
                else
                    Filter = "all";

                EnsureAttendanceRows();  
                LoadEventHeader();
                LoadDepartments();
                LoadCountsAndStats();
                LoadList();
                LoadFeed();
                LoadDeptProgress();
            }

            SetTabUrls();
            SetActiveTab();
        }

        #region URL & tab

        private void SetTabUrls()
        {
            var baseUrl = "~/Admin/AttendanceDetail.aspx?eventId=" + EventId;
            tabAll.NavigateUrl = baseUrl + "&filter=all";
            tabPresent.NavigateUrl = baseUrl + "&filter=present";
            tabAbsent.NavigateUrl = baseUrl + "&filter=absent";
            tabLate.NavigateUrl = baseUrl + "&filter=late";
        }

        private void SetActiveTab()
        {
            tabAll.CssClass = "tab" + (Filter == "all" ? " active" : "");
            tabPresent.CssClass = "tab green" + (Filter == "present" ? " active" : "");
            tabAbsent.CssClass = "tab amber" + (Filter == "absent" ? " active" : "");
            tabLate.CssClass = "tab" + (Filter == "late" ? " active" : "");
        }

        #endregion

        #region Ensure attendance rows tồn tại cho mỗi approved registration

        private void EnsureAttendanceRows()
        {
            try
            {
                const string sql = @"
                    INSERT INTO dbo.attendances (event_id, user_id, registration_id, status)
                    SELECT r.event_id, r.user_id, r.id, N'absent'
                    FROM dbo.event_registrations r
                    WHERE r.event_id = @eid
                      AND r.status = N'approved'
                      AND NOT EXISTS (
                          SELECT 1 FROM dbo.attendances a
                          WHERE a.event_id = r.event_id AND a.user_id = r.user_id
                      );";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@eid", EventId);
                    cmd.ExecuteNonQuery();
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("EnsureAttendanceRows error: " + ex.Message);
            }
        }

        #endregion

        #region Load Event header

        private void LoadEventHeader()
        {
            const string sql = @"
                SELECT e.id, e.title, e.start_at, e.end_at, e.location_name, e.location_room,
                       e.capacity, e.status,
                       u.first_name + N' ' + u.last_name AS organizer_name
                FROM dbo.events e
                JOIN dbo.users u ON u.id = e.created_by
                WHERE e.id = @id AND e.deleted_at IS NULL;";

            try
            {
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@id", EventId);
                    using (var rd = cmd.ExecuteReader())
                    {
                        if (!rd.Read())
                        {
                            Response.Redirect("~/Admin/AttendanceHub.aspx");
                            return;
                        }

                        var title = rd["title"].ToString();
                        var startAt = Convert.ToDateTime(rd["start_at"]);
                        var endAt = Convert.ToDateTime(rd["end_at"]);
                        var status = rd["status"].ToString();
                        var location = (rd["location_name"] as string ?? "Chưa có địa điểm");
                        var room = rd["location_room"] as string;
                        if (!string.IsNullOrEmpty(room)) location += " — " + room;

                        EventStartAt = startAt;

                        litEventTitle.Text = HttpUtility.HtmlEncode(title);
                        litPageTitle.Text = "Điểm danh: " + title;
                        litEventDate.Text = startAt.ToString("dd/MM/yyyy");
                        litEventStart.Text = startAt.ToString("HH:mm");
                        litEventLocation.Text = HttpUtility.HtmlEncode(location);
                        litOrganizer.Text = HttpUtility.HtmlEncode(rd["organizer_name"].ToString().Trim());

                        // Pill state
                        var now = DateTime.Now;
                        if (now >= startAt && now <= endAt)
                        {
                            litLivePill.Text = "SỰ KIỆN ĐANG DIỄN RA";
                            spanLivePill.Attributes["class"] = "live-pill live";
                        }
                        else if (now < startAt)
                        {
                            litLivePill.Text = "SẮP DIỄN RA";
                            spanLivePill.Attributes["class"] = "live-pill upcoming";
                        }
                        else
                        {
                            litLivePill.Text = "ĐÃ KẾT THÚC";
                            spanLivePill.Attributes["class"] = "live-pill ended";
                        }

                        var master = Master as Eventhub.AdminMaster;
                        if (master != null) master.Breadcrumb = "Điểm danh: " + title;
                    }
                }
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi tải sự kiện: " + ex.Message, isError: true);
            }
        }

        #endregion

        #region Load Departments dropdown

        private void LoadDepartments()
        {
            ddlDepartment.Items.Clear();
            ddlDepartment.Items.Add(new ListItem("Tất cả phòng ban", "0"));

            try
            {
                const string sql = @"
                    SELECT DISTINCT d.id, d.name
                    FROM dbo.event_registrations r
                    JOIN dbo.users u ON u.id = r.user_id
                    JOIN dbo.departments d ON d.id = u.department_id
                    WHERE r.event_id = @eid AND r.status = N'approved'
                    ORDER BY d.name;";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@eid", EventId);
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
            }
            catch { }
        }

        #endregion

        #region Load stats + counts

        private void LoadCountsAndStats()
        {
            int approved = 0, present = 0, absent = 0, late = 0;

            try
            {
                const string sqlApproved = @"
                    SELECT COUNT(*) FROM dbo.event_registrations
                    WHERE event_id = @eid AND status = N'approved';";
                using (var con = Database.OpenConnection())
                {
                    using (var cmd = new SqlCommand(sqlApproved, con))
                    {
                        cmd.Parameters.AddWithValue("@eid", EventId);
                        var o = cmd.ExecuteScalar();
                        approved = o == null || o == DBNull.Value ? 0 : Convert.ToInt32(o);
                    }

                    const string sqlAtt = @"
                        SELECT
                            SUM(CASE WHEN status IN (N'present', N'late', N'left_early') THEN 1 ELSE 0 END) AS p,
                            SUM(CASE WHEN status = N'absent' THEN 1 ELSE 0 END) AS a,
                            SUM(CASE WHEN is_late = 1 THEN 1 ELSE 0 END) AS l
                        FROM dbo.attendances
                        WHERE event_id = @eid;";
                    using (var cmd = new SqlCommand(sqlAtt, con))
                    {
                        cmd.Parameters.AddWithValue("@eid", EventId);
                        using (var rd = cmd.ExecuteReader())
                        {
                            if (rd.Read())
                            {
                                present = rd["p"] == DBNull.Value ? 0 : Convert.ToInt32(rd["p"]);
                                absent = rd["a"] == DBNull.Value ? 0 : Convert.ToInt32(rd["a"]);
                                late = rd["l"] == DBNull.Value ? 0 : Convert.ToInt32(rd["l"]);
                            }
                        }
                    }
                }
            }
            catch { }

            litStatApproved.Text = approved.ToString();
            litStatPresent.Text = present.ToString();
            litStatAbsent.Text = absent.ToString();
            litStatLate.Text = late.ToString();

            litRingPresent.Text = present.ToString();
            litRingTotal.Text = approved.ToString();

            int pctPresent = approved > 0 ? Math.Min(100, (int)Math.Round(present * 100.0 / approved)) : 0;
            int pctAbsent = approved > 0 ? Math.Min(100, (int)Math.Round(absent * 100.0 / approved)) : 0;
            divPresentBar.Attributes["style"] = "width: " + pctPresent + "%";
            divAbsentBar.Attributes["style"] = "width: " + pctAbsent + "%";

            litCntAll.Text = approved.ToString();
            litCntPresent.Text = present.ToString();
            litCntAbsent.Text = absent.ToString();
            litCntLate.Text = late.ToString();
        }

        #endregion

        #region Load list

        private void LoadList()
        {
            var list = new List<AttRowVM>();
            var sql = new StringBuilder();

            sql.AppendLine(@"
                SELECT a.id AS att_id, a.status, a.checked_in_at, a.is_late,
                       r.id AS reg_id, u.id AS user_id,
                       u.first_name + N' ' + u.last_name AS full_name,
                       u.employee_code,
                       ISNULL(d.name, N'(Chưa có)') AS dept_name,
                       u.department_id
                FROM dbo.event_registrations r
                JOIN dbo.attendances a ON a.event_id = r.event_id AND a.user_id = r.user_id
                JOIN dbo.users u ON u.id = r.user_id
                LEFT JOIN dbo.departments d ON d.id = u.department_id
                WHERE r.event_id = @eid AND r.status = N'approved'");

            switch (Filter)
            {
                case "present": sql.AppendLine(" AND a.status IN (N'present', N'late', N'left_early')"); break;
                case "absent": sql.AppendLine(" AND a.status = N'absent'"); break;
                case "late": sql.AppendLine(" AND a.is_late = 1"); break;
            }

            if (DepartmentId > 0)
                sql.AppendLine(" AND u.department_id = @did");
            if (!string.IsNullOrEmpty(Keyword))
                sql.AppendLine(@" AND (
                    u.first_name + N' ' + u.last_name LIKE @kw
                    OR u.email LIKE @kw
                    OR u.employee_code LIKE @kw)");

            switch (SortOrder)
            {
                case "checkin": sql.AppendLine(" ORDER BY a.checked_in_at, u.first_name"); break;
                case "dept": sql.AppendLine(" ORDER BY d.name, u.first_name"); break;
                default: sql.AppendLine(" ORDER BY u.first_name, u.last_name"); break;
            }

            try
            {
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql.ToString(), con))
                {
                    cmd.Parameters.AddWithValue("@eid", EventId);
                    if (DepartmentId > 0)
                        cmd.Parameters.AddWithValue("@did", DepartmentId);
                    if (!string.IsNullOrEmpty(Keyword))
                        cmd.Parameters.AddWithValue("@kw", "%" + Keyword + "%");

                    using (var rd = cmd.ExecuteReader())
                    {
                        int i = 0;
                        while (rd.Read())
                        {
                            var name = rd["full_name"].ToString().Trim();
                            var status = rd["status"].ToString();
                            DateTime? checkedAt = rd["checked_in_at"] == DBNull.Value
                                ? (DateTime?)null
                                : Convert.ToDateTime(rd["checked_in_at"]);
                            bool isLate = Convert.ToBoolean(rd["is_late"]);

                            var vm = new AttRowVM
                            {
                                RegistrationId = Convert.ToInt64(rd["reg_id"]),
                                UserId = Convert.ToInt64(rd["user_id"]),
                                FullName = name,
                                EmpId = rd["employee_code"] as string ?? "—",
                                Department = rd["dept_name"].ToString(),
                                Initial = BuildInitials(name),
                                ColorIndex = (i % 7) + 1,
                                Status = status,
                                CheckedInAt = checkedAt,
                                IsLate = isLate
                            };

                            bool isPresent = status == "present" || status == "late" || status == "left_early";
                            if (isPresent)
                            {
                                vm.RowClass = isLate ? "att-row checked-in late" : "att-row checked-in";
                                vm.TimePillClass = isLate ? "att-time-pill att-time-late" : "att-time-pill";
                                vm.TimeText = checkedAt.HasValue ? checkedAt.Value.ToString("HH:mm") : "--:--";
                            }
                            else
                            {
                                vm.RowClass = "att-row";
                                vm.TimePillClass = "att-time-empty";
                                vm.TimeText = "— : —";
                            }

                            list.Add(vm);
                            i++;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi tải danh sách: " + ex.Message, isError: true);
            }

            rptList.DataSource = list;
            rptList.DataBind();
            pnlEmpty.Visible = list.Count == 0;
        }

        #endregion

        #region Load activity feed

        private void LoadFeed()
        {
            var list = new List<FeedRowVM>();
            try
            {
                const string sql = @"
                    SELECT TOP 10
                        u.first_name + N' ' + u.last_name AS full_name,
                        ISNULL(d.name, N'(Chưa có)') AS dept_name,
                        a.checked_in_at
                    FROM dbo.attendances a
                    JOIN dbo.users u ON u.id = a.user_id
                    LEFT JOIN dbo.departments d ON d.id = u.department_id
                    WHERE a.event_id = @eid
                      AND a.checked_in_at IS NOT NULL
                    ORDER BY a.checked_in_at DESC;";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@eid", EventId);
                    using (var rd = cmd.ExecuteReader())
                    {
                        int i = 0;
                        while (rd.Read())
                        {
                            var name = rd["full_name"].ToString().Trim();
                            var when = Convert.ToDateTime(rd["checked_in_at"]);
                            list.Add(new FeedRowVM
                            {
                                FullName = name,
                                Department = rd["dept_name"].ToString(),
                                Initial = BuildInitials(name),
                                ColorIndex = (i % 7) + 1,
                                CheckedInAt = when,
                                TimeAgo = RelativeTime(when)
                            });
                            i++;
                        }
                    }
                }
            }
            catch { }

            rptFeed.DataSource = list;
            rptFeed.DataBind();
            phFeedEmpty.Visible = list.Count == 0;
        }

        #endregion

        #region Load Department progress

        private void LoadDeptProgress()
        {
            var list = new List<DeptRowVM>();
            try
            {
                const string sql = @"
                    SELECT d.name,
                           COUNT(*) AS approved_cnt,
                           SUM(CASE WHEN a.status IN (N'present', N'late', N'left_early') THEN 1 ELSE 0 END) AS present_cnt
                    FROM dbo.event_registrations r
                    JOIN dbo.users u ON u.id = r.user_id
                    JOIN dbo.departments d ON d.id = u.department_id
                    LEFT JOIN dbo.attendances a ON a.event_id = r.event_id AND a.user_id = r.user_id
                    WHERE r.event_id = @eid AND r.status = N'approved'
                    GROUP BY d.name
                    ORDER BY d.name;";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@eid", EventId);
                    using (var rd = cmd.ExecuteReader())
                    {
                        while (rd.Read())
                        {
                            list.Add(new DeptRowVM
                            {
                                Name = rd["name"].ToString(),
                                ApprovedCount = Convert.ToInt32(rd["approved_cnt"]),
                                PresentCount = rd["present_cnt"] == DBNull.Value ? 0 : Convert.ToInt32(rd["present_cnt"])
                            });
                        }
                    }
                }
            }
            catch { }

            rptDept.DataSource = list;
            rptDept.DataBind();
        }

        #endregion

        #region Toggle attendance

        protected void rptList_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName != "Toggle") return;
            var arg = (e.CommandArgument ?? "").ToString();
            var parts = arg.Split('|');
            if (parts.Length < 2) return;

            long regId, uid;
            if (!long.TryParse(parts[0], out regId)) return;
            if (!long.TryParse(parts[1], out uid)) return;

            ToggleAttendance(regId, uid);

            LoadCountsAndStats();
            LoadList();
            LoadFeed();
            LoadDeptProgress();
        }

        private void ToggleAttendance(long regId, long userId)
        {
            var user = AuthHelper.CurrentUser(Session);
            long actorId = user != null ? user.Id : 0;

            try
            {
                using (var con = Database.OpenConnection())
                {
                    string currentStatus = "absent";
                    using (var cmd = new SqlCommand(
                        "SELECT status FROM dbo.attendances WHERE event_id = @eid AND user_id = @uid;", con))
                    {
                        cmd.Parameters.AddWithValue("@eid", EventId);
                        cmd.Parameters.AddWithValue("@uid", userId);
                        var o = cmd.ExecuteScalar();
                        if (o != null && o != DBNull.Value) currentStatus = o.ToString();
                    }

                    bool isPresent = currentStatus == "present" || currentStatus == "late" || currentStatus == "left_early";

                    if (isPresent)
                    {
                        const string sql = @"
                            UPDATE dbo.attendances
                            SET status = N'absent',
                                checked_in_at = NULL,
                                check_in_method = NULL,
                                checked_in_by = NULL,
                                is_late = 0
                            WHERE event_id = @eid AND user_id = @uid;";
                        using (var cmd = new SqlCommand(sql, con))
                        {
                            cmd.Parameters.AddWithValue("@eid", EventId);
                            cmd.Parameters.AddWithValue("@uid", userId);
                            cmd.ExecuteNonQuery();
                        }

                        if (actorId > 0)
                            AuthHelper.LogActivity(actorId, "attendance.uncheck",
                                Request.UserHostAddress, Request.UserAgent);
                    }
                    else
                    {
                        bool isLate = false;
                        if (EventStartAt != DateTime.MinValue)
                            isLate = DateTime.Now > EventStartAt.AddMinutes(30);

                        string newStatus = isLate ? "late" : "present";

                        const string sql = @"
                            UPDATE dbo.attendances
                            SET status = @st,
                                checked_in_at = SYSUTCDATETIME(),
                                check_in_method = N'manual',
                                checked_in_by = @actor,
                                is_late = @late
                            WHERE event_id = @eid AND user_id = @uid;";
                        using (var cmd = new SqlCommand(sql, con))
                        {
                            cmd.Parameters.AddWithValue("@eid", EventId);
                            cmd.Parameters.AddWithValue("@uid", userId);
                            cmd.Parameters.AddWithValue("@st", newStatus);
                            cmd.Parameters.AddWithValue("@actor",
                                actorId > 0 ? (object)actorId : DBNull.Value);
                            cmd.Parameters.AddWithValue("@late", isLate ? 1 : 0);
                            cmd.ExecuteNonQuery();
                        }

                        if (actorId > 0)
                            AuthHelper.LogActivity(actorId,
                                isLate ? "attendance.checkin_late" : "attendance.checkin",
                                Request.UserHostAddress, Request.UserAgent);
                    }
                }
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi điểm danh: " + ex.Message, isError: true);
            }
        }

        #endregion

        #region Quick search (Enter để auto check-in)

        protected void txtQuick_TextChanged(object sender, EventArgs e)
        {
            var q = (txtQuick.Text ?? "").Trim();
            if (string.IsNullOrEmpty(q)) return;
            long foundUserId = 0;
            long foundRegId = 0;
            string foundName = "";
            try
            {
                const string sql = @"
                    SELECT TOP 1 r.id AS reg_id, u.id AS user_id,
                           u.first_name + N' ' + u.last_name AS full_name
                    FROM dbo.event_registrations r
                    JOIN dbo.users u ON u.id = r.user_id
                    JOIN dbo.attendances a ON a.event_id = r.event_id AND a.user_id = r.user_id
                    WHERE r.event_id = @eid AND r.status = N'approved'
                      AND a.status = N'absent'
                      AND (u.employee_code = @qExact
                           OR u.email = @qExact
                           OR u.first_name + N' ' + u.last_name LIKE @qLike
                           OR u.employee_code LIKE @qLike
                           OR u.email LIKE @qLike);";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@eid", EventId);
                    cmd.Parameters.AddWithValue("@qExact", q);
                    cmd.Parameters.AddWithValue("@qLike", "%" + q + "%");
                    using (var rd = cmd.ExecuteReader())
                    {
                        if (rd.Read())
                        {
                            foundRegId = Convert.ToInt64(rd["reg_id"]);
                            foundUserId = Convert.ToInt64(rd["user_id"]);
                            foundName = rd["full_name"].ToString().Trim();
                        }
                    }
                }
            }
            catch { }

            if (foundUserId > 0)
            {
                ToggleAttendance(foundRegId, foundUserId);
                ShowAlert("✓ Đã điểm danh: " + foundName, isError: false);
                txtQuick.Text = "";

                LoadCountsAndStats();
                LoadList();
                LoadFeed();
                LoadDeptProgress();
            }
            else
            {
                ShowAlert("Không tìm thấy người phù hợp với từ khoá \"" + q + "\" hoặc người đó đã được điểm danh.", isError: true);
            }
        }

        #endregion

        #region Filter handlers

        protected void txtSearch_TextChanged(object sender, EventArgs e)
        {
            Keyword = (txtSearch.Text ?? "").Trim();
            LoadList();
        }

        protected void ddlDepartment_Changed(object sender, EventArgs e)
        {
            long id; long.TryParse(ddlDepartment.SelectedValue, out id);
            DepartmentId = id;
            LoadList();
        }

        protected void ddlSort_Changed(object sender, EventArgs e)
        {
            SortOrder = ddlSort.SelectedValue;
            LoadList();
        }

        #endregion

        #region Close session

        protected void btnCloseSession_Click(object sender, EventArgs e)
        {
            try
            {
                const string sql = @"
                    UPDATE dbo.events SET status = N'ended', updated_at = SYSUTCDATETIME()
                    WHERE id = @id AND deleted_at IS NULL;";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@id", EventId);
                    cmd.ExecuteNonQuery();
                }

                var user = AuthHelper.CurrentUser(Session);
                if (user != null)
                    AuthHelper.LogActivity(user.Id, "event.close",
                        Request.UserHostAddress, Request.UserAgent);

                Response.Redirect("~/Admin/AttendanceHub.aspx?filter=ended");
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi đóng phiên: " + ex.Message, isError: true);
            }
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

        private static string RelativeTime(DateTime past)
        {
            var diff = DateTime.Now - past;
            if (diff.TotalSeconds < 60) return "vừa xong";
            if (diff.TotalMinutes < 60) return ((int)diff.TotalMinutes) + " phút trước";
            if (diff.TotalHours < 24) return ((int)diff.TotalHours) + " giờ trước";
            return past.ToString("dd/MM");
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