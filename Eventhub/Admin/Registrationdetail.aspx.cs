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
    public partial class registrationdetail : System.Web.UI.Page
    {
        #region View Models

        public class RowVM
        {
            public long Id { get; set; }
            public string FullName { get; set; }
            public string Email { get; set; }
            public string Department { get; set; }
            public string EmpId { get; set; }
            public string TicketCode { get; set; }
            public DateTime RegisteredAt { get; set; }
            public string Status { get; set; }
            public string StatusText { get; set; }
            public string TimeAgo { get; set; }
            public string Initial { get; set; }
            public int ColorIndex { get; set; }
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

        public string StatusClass { get; set; }

        private string StatusFilter
        {
            get { return string.IsNullOrEmpty(hfStatusFilter.Value) ? "all" : hfStatusFilter.Value; }
            set { hfStatusFilter.Value = value ?? "all"; }
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
            get { return (ViewState["sort"] as string) ?? "newest"; }
            set { ViewState["sort"] = value; }
        }

        #endregion

        protected void Page_Load(object sender, EventArgs e)
        {
            var master = Master as Eventhub.AdminMaster;
            if (master != null) master.Breadcrumb = "Xét duyệt người đăng ký";

            if (EventId <= 0)
            {
                Response.Redirect("~/Admin/Approval.aspx");
                return;
            }

            if (!IsPostBack)
            {
                // Đọc filter từ querystring
                var qs = Request.QueryString["status"];
                if (!string.IsNullOrEmpty(qs) &&
                    new[] { "all", "pending", "approved", "rejected", "waitlist" }.Contains(qs))
                {
                    StatusFilter = qs;
                }
                else
                {
                    StatusFilter = "all";
                }

                LoadEventInfo();
                LoadDepartments();
                LoadCounts();
                LoadList();
            }

            SetTabUrls();
            SetActiveTab();

            // Detail link
            lnkEventDetail.NavigateUrl = "~/Admin/EventDetail.aspx?id=" + EventId;
        }

        #region URL tab handlers

        private void SetTabUrls()
        {
            var baseUrl = "~/Admin/RegistrationDetail.aspx?eventId=" + EventId;
            tabAll.NavigateUrl = baseUrl + "&status=all";
            tabPending.NavigateUrl = baseUrl + "&status=pending";
            tabApproved.NavigateUrl = baseUrl + "&status=approved";
            tabRejected.NavigateUrl = baseUrl + "&status=rejected";
            tabWaitlist.NavigateUrl = baseUrl + "&status=waitlist";
        }

        private void SetActiveTab()
        {
            tabAll.CssClass = "tab" + (StatusFilter == "all" ? " active" : "");
            tabPending.CssClass = "tab amber" + (StatusFilter == "pending" ? " active" : "");
            tabApproved.CssClass = "tab green" + (StatusFilter == "approved" ? " active" : "");
            tabRejected.CssClass = "tab red" + (StatusFilter == "rejected" ? " active" : "");
            tabWaitlist.CssClass = "tab" + (StatusFilter == "waitlist" ? " active" : "");
        }

        #endregion

        #region Load Event Info

        private void LoadEventInfo()
        {
            const string sql = @"
                SELECT e.id, e.title, e.start_at, e.end_at, e.location_name, e.capacity, e.status
                FROM dbo.events e
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
                            Response.Redirect("~/Admin/Approval.aspx");
                            return;
                        }

                        var title = rd["title"].ToString();
                        var startAt = Convert.ToDateTime(rd["start_at"]);
                        var endAt = Convert.ToDateTime(rd["end_at"]);
                        var status = rd["status"].ToString();

                        litEventTitle.Text = HttpUtility.HtmlEncode(title);
                        litEventDate.Text = VietnameseDayOfWeek(startAt) + ", " + startAt.ToString("dd/MM/yyyy");
                        litEventTime.Text = startAt.ToString("HH:mm") + " – " + endAt.ToString("HH:mm");
                        litEventLocation.Text = HttpUtility.HtmlEncode(rd["location_name"] as string ?? "Chưa có địa điểm");
                        litEventStatus.Text = MapEventStatus(status);
                        StatusClass = "status-" + status;
                        spanStatus.Attributes["class"] = "meta-pill status-" + status;
                        litCapacity.Text = Convert.ToInt32(rd["capacity"]).ToString();
                        litPageTitle.Text = "Xét duyệt: " + title;

                        var master = Master as Eventhub.AdminMaster;
                        if (master != null) master.Breadcrumb = "Xét duyệt: " + title;

                        ViewState["capacity"] = Convert.ToInt32(rd["capacity"]);
                    }
                }
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi tải thông tin sự kiện: " + ex.Message, isError: true);
            }
        }

        #endregion

        #region Load Departments

        private void LoadDepartments()
        {
            ddlDepartment.Items.Clear();
            ddlDepartment.Items.Add(new ListItem("Phòng ban: Tất cả", "0"));

            try
            {
                const string sql = @"
                    SELECT DISTINCT d.id, d.name
                    FROM dbo.event_registrations r
                    JOIN dbo.users u ON u.id = r.user_id
                    JOIN dbo.departments d ON d.id = u.department_id
                    WHERE r.event_id = @eid
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

        #region Load Counts

        private void LoadCounts()
        {
            int total = 0, pending = 0, approved = 0, rejected = 0, waitlist = 0;

            try
            {
                const string sql = @"
                    SELECT status, COUNT(*) AS c
                    FROM dbo.event_registrations
                    WHERE event_id = @eid
                    GROUP BY status;";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@eid", EventId);
                    using (var rd = cmd.ExecuteReader())
                    {
                        while (rd.Read())
                        {
                            var st = rd["status"].ToString();
                            var c = Convert.ToInt32(rd["c"]);
                            total += c;
                            switch (st)
                            {
                                case "pending": pending = c; break;
                                case "approved": approved = c; break;
                                case "rejected": rejected = c; break;
                                case "waitlist": waitlist = c; break;
                            }
                        }
                    }
                }
            }
            catch { }

            int totalReg = approved + pending;
            int capacity = (int)(ViewState["capacity"] ?? 0);

            litTotal.Text = totalReg.ToString();
            litPending.Text = pending.ToString();
            litApproved.Text = approved.ToString();
            litRejected.Text = rejected.ToString();
            litWaitlist.Text = waitlist.ToString();

            int pct = capacity > 0 ? Math.Min(100, (int)Math.Round(totalReg * 100.0 / capacity)) : 0;
            divProgress.Attributes["style"] = "width: " + pct + "%";

            litPendingTrend.Text = pending > 0 ? "Cần xử lý sớm" : "Đã xử lý hết";
            int totalDecisions = approved + rejected;
            litApprovedRate.Text = totalDecisions > 0
                ? "↗ " + Math.Round(approved * 100.0 / totalDecisions) + "% tỉ lệ duyệt"
                : "Chưa có dữ liệu";
            litRejectedRate.Text = totalDecisions > 0
                ? Math.Round(rejected * 100.0 / totalDecisions) + "% tỉ lệ"
                : "—";

            litCntAll.Text = total.ToString();
            litCntPending.Text = pending.ToString();
            litCntApproved.Text = approved.ToString();
            litCntRejected.Text = rejected.ToString();
            litCntWaitlist.Text = waitlist.ToString();
        }

        #endregion

        #region Load List

        private void LoadList()
        {
            var list = new List<RowVM>();

            var sql = new StringBuilder();
            sql.AppendLine(@"
                SELECT r.id, r.status, r.registered_at, r.ticket_code,
                       u.first_name + N' ' + u.last_name AS full_name,
                       u.email, u.employee_code,
                       ISNULL(d.name, N'(Chưa có phòng ban)') AS dept_name,
                       u.department_id
                FROM dbo.event_registrations r
                JOIN dbo.users u ON u.id = r.user_id
                LEFT JOIN dbo.departments d ON d.id = u.department_id
                WHERE r.event_id = @eid");

            if (StatusFilter != "all")
                sql.AppendLine(" AND r.status = @st");

            if (DepartmentId > 0)
                sql.AppendLine(" AND u.department_id = @did");

            if (!string.IsNullOrEmpty(Keyword))
                sql.AppendLine(@" AND (
                    u.first_name + N' ' + u.last_name LIKE @kw
                    OR u.email LIKE @kw
                    OR u.employee_code LIKE @kw)");

            // Sort
            switch (SortOrder)
            {
                case "oldest": sql.AppendLine(" ORDER BY r.registered_at ASC"); break;
                case "name": sql.AppendLine(" ORDER BY u.first_name, u.last_name"); break;
                default: sql.AppendLine(" ORDER BY r.registered_at DESC"); break;
            }

            try
            {
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql.ToString(), con))
                {
                    cmd.Parameters.AddWithValue("@eid", EventId);
                    if (StatusFilter != "all")
                        cmd.Parameters.AddWithValue("@st", StatusFilter);
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
                            var regAt = Convert.ToDateTime(rd["registered_at"]);

                            list.Add(new RowVM
                            {
                                Id = Convert.ToInt64(rd["id"]),
                                FullName = name,
                                Email = rd["email"].ToString(),
                                Department = rd["dept_name"].ToString(),
                                EmpId = rd["employee_code"] as string ?? "—",
                                TicketCode = rd["ticket_code"] as string ?? "—",
                                RegisteredAt = regAt,
                                Status = status,
                                StatusText = MapRegStatus(status),
                                TimeAgo = RelativeTime(regAt),
                                Initial = BuildInitials(name),
                                ColorIndex = (i % 6) + 1
                            });
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
            phEmpty.Visible = list.Count == 0;

            litShownCount.Text = list.Count.ToString();
            litTotalCount.Text = list.Count.ToString();
        }

        #endregion

        #region Actions: Approve / Reject / Reset / Approve All

        protected void rptList_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            long regId;
            if (!long.TryParse((e.CommandArgument ?? "").ToString(), out regId)) return;

            switch (e.CommandName)
            {
                case "Approve": UpdateStatus(regId, "approved"); break;
                case "Reject": UpdateStatus(regId, "rejected"); break;
                case "Reset": UpdateStatus(regId, "pending"); break;
            }

            LoadCounts();
            LoadList();
        }

        protected void btnApproveAll_Click(object sender, EventArgs e)
        {
            var user = AuthHelper.CurrentUser(Session);
            long actorId = user != null ? user.Id : 0;

            try
            {
                const string sql = @"
                    UPDATE dbo.event_registrations
                    SET status = N'approved',
                        approved_at = SYSUTCDATETIME(),
                        approved_by = @uid
                    WHERE event_id = @eid AND status = N'pending';";

                int affected;
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@eid", EventId);
                    cmd.Parameters.AddWithValue("@uid", actorId > 0 ? (object)actorId : DBNull.Value);
                    affected = cmd.ExecuteNonQuery();
                }

                if (actorId > 0)
                    AuthHelper.LogActivity(actorId, "registration.bulk_approve",
                        Request.UserHostAddress, Request.UserAgent);

                ShowAlert("Đã duyệt " + affected + " yêu cầu chờ.", isError: false);
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi: " + ex.Message, isError: true);
            }

            LoadCounts();
            LoadList();
        }

        private void UpdateStatus(long regId, string newStatus)
        {
            var user = AuthHelper.CurrentUser(Session);
            long actorId = user != null ? user.Id : 0;

            string sql;
            switch (newStatus)
            {
                case "approved":
                    sql = @"UPDATE dbo.event_registrations
                            SET status = N'approved',
                                approved_at = SYSUTCDATETIME(),
                                approved_by = @uid,
                                rejected_at = NULL, rejected_by = NULL
                            WHERE id = @rid;";
                    break;
                case "rejected":
                    sql = @"UPDATE dbo.event_registrations
                            SET status = N'rejected',
                                rejected_at = SYSUTCDATETIME(),
                                rejected_by = @uid,
                                approved_at = NULL, approved_by = NULL
                            WHERE id = @rid;";
                    break;
                case "pending":
                    sql = @"UPDATE dbo.event_registrations
                            SET status = N'pending',
                                approved_at = NULL, approved_by = NULL,
                                rejected_at = NULL, rejected_by = NULL
                            WHERE id = @rid;";
                    break;
                default: return;
            }

            try
            {
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@rid", regId);
                    cmd.Parameters.AddWithValue("@uid", actorId > 0 ? (object)actorId : DBNull.Value);
                    cmd.ExecuteNonQuery();
                }

                if (actorId > 0)
                    AuthHelper.LogActivity(actorId, "registration." + newStatus,
                        Request.UserHostAddress, Request.UserAgent);
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi: " + ex.Message, isError: true);
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

        #region Helpers

        private static string MapRegStatus(string s)
        {
            switch (s)
            {
                case "pending": return "Chờ duyệt";
                case "approved": return "Đã duyệt";
                case "rejected": return "Đã từ chối";
                case "waitlist": return "Danh sách chờ";
                case "cancelled": return "Đã huỷ";
                default: return s;
            }
        }

        private static string MapEventStatus(string s)
        {
            switch (s)
            {
                case "open": return "Đang mở đăng ký";
                case "closed": return "Đóng đăng ký";
                case "ended": return "Đã kết thúc";
                case "draft": return "Bản nháp";
                case "cancelled": return "Đã huỷ";
                default: return s;
            }
        }

        private static string VietnameseDayOfWeek(DateTime d)
        {
            switch (d.DayOfWeek)
            {
                case DayOfWeek.Monday: return "Thứ Hai";
                case DayOfWeek.Tuesday: return "Thứ Ba";
                case DayOfWeek.Wednesday: return "Thứ Tư";
                case DayOfWeek.Thursday: return "Thứ Năm";
                case DayOfWeek.Friday: return "Thứ Sáu";
                case DayOfWeek.Saturday: return "Thứ Bảy";
                default: return "Chủ Nhật";
            }
        }

        private static string RelativeTime(DateTime past)
        {
            var diff = DateTime.Now - past;
            if (diff.TotalSeconds < 60) return "vừa xong";
            if (diff.TotalMinutes < 60) return ((int)diff.TotalMinutes) + " phút trước";
            if (diff.TotalHours < 24) return ((int)diff.TotalHours) + " giờ trước";
            if (diff.TotalDays < 30) return ((int)diff.TotalDays) + " ngày trước";
            return past.ToString("dd/MM/yyyy");
        }

        private static string BuildInitials(string fullName)
        {
            if (string.IsNullOrEmpty(fullName)) return "?";
            var parts = fullName.Trim().Split(new[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            if (parts.Length == 1) return parts[0].Substring(0, 1).ToUpper();
            return (parts[0].Substring(0, 1) + parts[parts.Length - 1].Substring(0, 1)).ToUpper();
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