using Eventhub.App_Code;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;

namespace Eventhub.User
{
    public partial class UserMyEvents : System.Web.UI.Page
    {
        private string connStr;
        private readonly CultureInfo vi = new CultureInfo("vi-VN");

        /// <summary>
        /// Filter được đọc từ QueryString (?filter=X).
        /// Trên postback (sort/search), đọc từ HiddenField để giữ state.
        /// </summary>
        protected string CurrentFilter
        {
            get => hfFilter.Value ?? "ALL";
            set { if (hfFilter != null) hfFilter.Value = value; }
        }

        private string CurrentSearch
        {
            get => ViewState["Search"] as string ?? string.Empty;
            set => ViewState["Search"] = value;
        }

        private string CurrentSort
        {
            get => ViewState["Sort"] as string ?? "DATE_DESC";
            set => ViewState["Sort"] = value;
        }

        private long CurrentUserId
        {
            get
            {
                object u = Session["UserId"];
                if (u == null) throw new InvalidOperationException("Session UserId is missing.");
                return Convert.ToInt64(u);
            }
        }

        // ──────────────────────────────────────────────────────────────
        // PAGE LIFECYCLE
        // ──────────────────────────────────────────────────────────────
        protected override void OnInit(EventArgs e)
        {
            base.OnInit(e);
            var cs = ConfigurationManager.ConnectionStrings["EventHub"];
            if (cs == null) throw new ConfigurationErrorsException("Missing connection string 'EventHub'.");
            connStr = cs.ConnectionString;
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["UserId"] == null) { Response.Redirect("~/Account/Login.aspx"); return; }

            if (!IsPostBack)
            {
                // Đọc filter từ QueryString khi load trang lần đầu hoặc click link filter
                string qsFilter = Request.QueryString["filter"] ?? "ALL";
                string qsSort = Request.QueryString["sort"] ?? "DATE_DESC";
                string qsSearch = Request.QueryString["q"] ?? string.Empty;

                CurrentFilter = qsFilter;
                CurrentSort = qsSort;
                CurrentSearch = qsSearch;

                if (ddlSort != null) ddlSort.SelectedValue = CurrentSort;
                if (txtSearch != null) txtSearch.Text = CurrentSearch;
            }

            LoadAllData();
        }

        // ──────────────────────────────────────────────────────────────
        // LOAD ALL
        // ──────────────────────────────────────────────────────────────
        private void LoadAllData()
        {
            LoadStats();
            BuildFilterLinks();
            LoadRegistrations();
        }

        // ──────────────────────────────────────────────────────────────
        // STATS
        // ──────────────────────────────────────────────────────────────
        private void LoadStats()
        {
            const string sql = @"
                SELECT
                    COUNT(*)                                                             AS Total,
                    SUM(CASE WHEN r.status = N'approved'  THEN 1 ELSE 0 END)            AS Approved,
                    SUM(CASE WHEN r.status = N'pending'   THEN 1 ELSE 0 END)            AS Pending,
                    SUM(CASE WHEN r.status = N'waitlist'  THEN 1 ELSE 0 END)            AS Waitlist,
                    SUM(CASE WHEN r.status = N'rejected'  THEN 1 ELSE 0 END)            AS Rejected,
                    SUM(CASE WHEN r.status = N'cancelled' THEN 1 ELSE 0 END)            AS Cancelled,
                    SUM(CASE WHEN a.status IN (N'present', N'late', N'left_early')
                              THEN 1 ELSE 0 END)                                        AS Attended,
                    SUM(CASE WHEN e.start_at >= GETDATE()
                              AND e.start_at  < DATEADD(DAY, 7, GETDATE())
                              AND r.status   IN (N'approved', N'pending', N'waitlist')
                              THEN 1 ELSE 0 END)                                        AS UpcomingWeek
                FROM dbo.event_registrations r
                INNER JOIN dbo.events       e ON e.id = r.event_id
                LEFT JOIN  dbo.attendances  a ON a.registration_id = r.id
                WHERE r.user_id = @UserId AND e.deleted_at IS NULL;";

            DataTable dt = ExecuteTable(sql, new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });
            if (dt.Rows.Count == 0) return;

            DataRow r = dt.Rows[0];
            litStatTotal.Text = SafeStr(r["Total"], "0");
            litStatApproved.Text = SafeStr(r["Approved"], "0");
            litStatPending.Text = SafeStr(r["Pending"], "0");
            litStatAttended.Text = SafeStr(r["Attended"], "0");
            litStatRejected.Text = SafeStr(r["Rejected"], "0");

            litSbAll.Text = SafeStr(r["Total"], "0");
            litSbApproved.Text = SafeStr(r["Approved"], "0");
            litSbPending.Text = SafeStr(r["Pending"], "0");
            litSbWaitlist.Text = SafeStr(r["Waitlist"], "0");
            litSbAttended.Text = SafeStr(r["Attended"], "0");
            litSbRejected.Text = SafeStr(r["Rejected"], "0");
            litSbCancelled.Text = SafeStr(r["Cancelled"], "0");
            litUpcomingCount.Text = SafeStr(r["UpcomingWeek"], "0");
        }

        // ──────────────────────────────────────────────────────────────
        // BUILD FILTER LINKS — set href + active class trên HtmlAnchor
        // Đây là điểm mấu chốt: dùng HtmlAnchor thay LinkButton nên
        // KHÔNG bao giờ mất giao diện sau postback/filter click.
        // ──────────────────────────────────────────────────────────────
        private void BuildFilterLinks()
        {
            string sort = HttpUtility.UrlEncode(CurrentSort);
            string search = HttpUtility.UrlEncode(CurrentSearch);
            string basePath = Request.AppRelativeCurrentExecutionFilePath
                .TrimStart('~').TrimStart('/');
            // Đường dẫn tuyệt đối tới trang hiện tại
            string pageUrl = ResolveUrl("~/User/UserMyEvents.aspx");

            SetFilterAnchor(lnkFAll, "ALL", pageUrl, sort, search);
            SetFilterAnchor(lnkFApproved, "approved", pageUrl, sort, search);
            SetFilterAnchor(lnkFPending, "pending", pageUrl, sort, search);
            SetFilterAnchor(lnkFWaitlist, "waitlist", pageUrl, sort, search);
            SetFilterAnchor(lnkFAttended, "attended", pageUrl, sort, search);
            SetFilterAnchor(lnkFRejected, "rejected", pageUrl, sort, search);
            SetFilterAnchor(lnkFCancelled, "cancelled", pageUrl, sort, search);
        }

        private void SetFilterAnchor(HtmlAnchor anchor, string filterVal,
                                      string pageUrl, string sort, string search)
        {
            if (anchor == null) return;
            bool isActive = string.Equals(CurrentFilter, filterVal,
                                          StringComparison.OrdinalIgnoreCase);
            anchor.Attributes["class"] = isActive ? "filter-item active" : "filter-item";
            anchor.HRef = $"{pageUrl}?filter={filterVal}&sort={sort}&q={search}";
        }

        // ──────────────────────────────────────────────────────────────
        // REGISTRATIONS
        // ──────────────────────────────────────────────────────────────
        private void LoadRegistrations()
        {
            string orderBy;
            switch ((CurrentSort ?? "DATE_DESC").ToUpperInvariant())
            {
                case "DATE_ASC": orderBy = "e.start_at ASC"; break;
                case "EVENT_ASC": orderBy = "e.title ASC"; break;
                default: orderBy = "r.registered_at DESC"; break;
            }

            string sql = $@"
                SELECT
                    r.id                                                   AS reg_id,
                    r.status                                               AS reg_status,
                    r.registered_at,
                    r.waitlist_position,
                    r.rejection_reason,
                    e.id                                                   AS event_id,
                    e.title                                                AS event_title,
                    e.format,
                    e.start_at, e.end_at,
                    e.location_name, e.location_room, e.address, e.online_url,
                    e.capacity,
                    COALESCE(c.name, N'Sự kiện')                          AS category_name,
                    ISNULL(att.status, N'')                                AS attended,
                    CASE WHEN e.start_at >= GETDATE() THEN 1 ELSE 0 END   AS is_upcoming,
                    ISNULL(rc.registered_count, 0)                        AS registered_count,
                    FORMAT(e.start_at, 'dd', 'vi-VN')                     AS start_day,
                    'Thg ' + CAST(MONTH(e.start_at) AS NVARCHAR(2))       AS start_mon,
                    DATENAME(WEEKDAY, e.start_at)                         AS start_dow_raw,
                    FORMAT(r.registered_at, 'dd/MM/yyyy')                 AS registered_date
                FROM dbo.event_registrations r
                INNER JOIN dbo.events           e  ON e.id = r.event_id
                LEFT JOIN  dbo.event_categories c  ON c.id = e.category_id
                LEFT JOIN  dbo.attendances      att ON att.registration_id = r.id
                LEFT JOIN (
                    SELECT event_id, COUNT(*) AS registered_count
                    FROM dbo.event_registrations
                    WHERE status IN (N'pending', N'approved', N'waitlist')
                    GROUP BY event_id
                ) rc ON rc.event_id = e.id
                WHERE r.user_id    = @UserId
                  AND e.deleted_at IS NULL
                  AND (@Keyword = N'' OR e.title LIKE N'%' + @Keyword + N'%')
                  AND (
                       @Filter = N'ALL'
                    OR (@Filter = N'attended' AND att.status IN (N'present', N'late', N'left_early'))
                    OR (@Filter = r.status)
                  )
                ORDER BY {orderBy};";

            DataTable dt = ExecuteTable(sql,
                new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId },
                new SqlParameter("@Keyword", SqlDbType.NVarChar, 200) { Value = CurrentSearch ?? string.Empty },
                new SqlParameter("@Filter", SqlDbType.NVarChar, 15) { Value = CurrentFilter ?? "ALL" });

            // Cột computed
            dt.Columns.Add("start_dow", typeof(string));
            dt.Columns.Add("schedule_text", typeof(string));
            dt.Columns.Add("location_text", typeof(string));
            dt.Columns.Add("badge_class", typeof(string));
            dt.Columns.Add("badge_text", typeof(string));

            foreach (DataRow row in dt.Rows)
            {
                row["start_dow"] = AbbreviateDow(SafeStr(row["start_dow_raw"]));
                row["schedule_text"] = FormatScheduleText(row["start_at"], row["end_at"]);
                row["location_text"] = FormatLocation(SafeStr(row["format"]),
                                                       SafeStr(row["location_name"]),
                                                       SafeStr(row["location_room"]),
                                                       SafeStr(row["address"]));
                // badge
                int cap = Convert.ToInt32(row["capacity"]);
                int reg = Convert.ToInt32(row["registered_count"]);
                if (cap > 0 && cap - reg <= 10 && cap - reg > 0)
                { row["badge_class"] = "almost-full"; row["badge_text"] = "Sắp hết chỗ"; }
                else if (cap > 0 && reg >= cap)
                { row["badge_class"] = "hot"; row["badge_text"] = "Đã đầy"; }
                else if (row["start_at"] != DBNull.Value &&
                         Convert.ToDateTime(row["start_at"]) >= DateTime.Now &&
                         (Convert.ToDateTime(row["start_at"]) - DateTime.Now).TotalDays <= 7)
                { row["badge_class"] = "new"; row["badge_text"] = "Sắp diễn ra"; }
                else
                { row["badge_class"] = ""; row["badge_text"] = ""; }
            }

            rptRegs.DataSource = dt;
            rptRegs.DataBind();

            int count = dt.Rows.Count;
            pnlEmpty.Visible = count == 0;
            rptRegs.Visible = count > 0;
            litSectionCount.Text = count.ToString();
            litSectionTitle.Text = FilterToTitle(CurrentFilter);

            litEmptyMsg.Text = CurrentFilter == "ALL"
                ? "Bạn chưa đăng ký sự kiện nào."
                : $"Không có sự kiện nào với trạng thái \"{FilterToTitle(CurrentFilter)}\".";
        }

        // ──────────────────────────────────────────────────────────────
        // ItemDataBound
        // ──────────────────────────────────────────────────────────────
        protected void rptRegs_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item &&
                e.Item.ItemType != ListItemType.AlternatingItem) return;

            var row = (DataRowView)e.Item.DataItem;
            string status = SafeStr(row["reg_status"]).ToLowerInvariant();
            string attended = SafeStr(row["attended"]).ToLowerInvariant();
            bool isActive = status == "approved" || status == "pending" || status == "waitlist";
            bool isFuture = Convert.ToInt32(row["is_upcoming"]) == 1;

            // Badges
            var pnlBadges = (Panel)e.Item.FindControl("pnlBadges");
            var litBadges = (Literal)e.Item.FindControl("litBadges");
            string bc = SafeStr(row["badge_class"]);
            if (!string.IsNullOrEmpty(bc) && pnlBadges != null && litBadges != null)
            {
                pnlBadges.Visible = true;
                litBadges.Text = $"<span class='badge-mini {bc}'>{HttpUtility.HtmlEncode(SafeStr(row["badge_text"]))}</span>";
            }

            // Alert bar
            var pnlRowAlert = (Panel)e.Item.FindControl("pnlRowAlert");
            var litAlertIcon = (Literal)e.Item.FindControl("litAlertIcon");
            var litAlertMsg = (Literal)e.Item.FindControl("litAlertMsg");

            if (pnlRowAlert != null && litAlertIcon != null && litAlertMsg != null)
            {
                switch (status)
                {
                    case "approved":
                        bool hasAtt = attended == "present" || attended == "late" || attended == "left_early";
                        if (hasAtt)
                        { pnlRowAlert.Visible = true; pnlRowAlert.CssClass = "event-alert confirmed"; litAlertIcon.Text = CheckSvg(); litAlertMsg.Text = "Bạn đã tham gia sự kiện này. Cảm ơn!"; }
                        else if (isFuture)
                        { pnlRowAlert.Visible = true; pnlRowAlert.CssClass = "event-alert confirmed"; litAlertIcon.Text = CheckSvg(); litAlertMsg.Text = "Bạn đã được duyệt tham gia. <b>Vé QR</b> đã được gửi đến email."; }
                        break;
                    case "pending":
                        pnlRowAlert.Visible = true; pnlRowAlert.CssClass = "event-alert pending";
                        litAlertIcon.Text = ClockSvg();
                        litAlertMsg.Text = "Yêu cầu đang được Ban tổ chức xét duyệt. Sẽ thông báo trong vòng <b>24 giờ</b>.";
                        break;
                    case "waitlist":
                        int pos = row["waitlist_position"] == DBNull.Value ? 0 : Convert.ToInt32(row["waitlist_position"]);
                        pnlRowAlert.Visible = true; pnlRowAlert.CssClass = "event-alert waitlist";
                        litAlertIcon.Text = ListSvg();
                        litAlertMsg.Text = pos > 0
                            ? $"Lớp đã đủ chỗ. Bạn ở <b>vị trí #{pos}</b>. Sẽ được duyệt tự động nếu có chỗ trống."
                            : "Bạn đang trong danh sách chờ. Sẽ được duyệt tự động nếu có chỗ trống.";
                        break;
                    case "rejected":
                        pnlRowAlert.Visible = true; pnlRowAlert.CssClass = "event-alert rejected";
                        litAlertIcon.Text = XCircleSvg();
                        string reason = SafeStr(row["rejection_reason"]);
                        litAlertMsg.Text = string.IsNullOrWhiteSpace(reason)
                            ? "Yêu cầu đã bị từ chối. Vui lòng liên hệ Ban tổ chức để biết thêm."
                            : $"Lý do: <b>{HttpUtility.HtmlEncode(reason)}</b>";
                        break;
                    case "cancelled":
                        pnlRowAlert.Visible = true; pnlRowAlert.CssClass = "event-alert rejected";
                        litAlertIcon.Text = XCircleSvg();
                        litAlertMsg.Text = "Bạn đã huỷ đăng ký sự kiện này.";
                        break;
                }
            }

            // Action buttons
            var pnlCalendar = (Panel)e.Item.FindControl("pnlBtnCalendar");
            var pnlCancel = (Panel)e.Item.FindControl("pnlBtnCancel");
            var litCancelTxt = e.Item.FindControl("litCancelText") as Literal;

            if (pnlCalendar != null) pnlCalendar.Visible = isActive && isFuture;
            if (pnlCancel != null)
            {
                pnlCancel.Visible = isActive;
                if (litCancelTxt != null)
                    litCancelTxt.Text = status == "waitlist" ? "Rời danh sách chờ" : "Huỷ đăng ký";
            }
        }

        protected void rptRegs_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "CancelReg" &&
                long.TryParse(Convert.ToString(e.CommandArgument), out long regId))
                CancelRegistration(regId);
        }

        // ──────────────────────────────────────────────────────────────
        // EVENT HANDLERS
        // ──────────────────────────────────────────────────────────────
        protected void btnSearch_Click(object sender, EventArgs e)
        {
            CurrentSearch = (txtSearch.Text ?? string.Empty).Trim();
            LoadAllData();
        }

        protected void ddlSort_Changed(object sender, EventArgs e)
        {
            CurrentSort = ddlSort.SelectedValue;
            LoadAllData();
        }

        protected void btnExport_Click(object sender, EventArgs e)
        {
            ExportAllIcs();
        }

        // ──────────────────────────────────────────────────────────────
        // CANCEL REGISTRATION
        // ──────────────────────────────────────────────────────────────
        private void CancelRegistration(long regId)
        {
            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    using (SqlCommand cmd = new SqlCommand(@"
                        UPDATE dbo.event_registrations
                        SET status       = N'cancelled',
                            cancelled_at = SYSUTCDATETIME(),
                            updated_at   = SYSUTCDATETIME()
                        WHERE id = @RegId AND user_id = @UserId
                          AND status IN (N'pending', N'approved', N'waitlist');", conn))
                    {
                        cmd.Parameters.Add("@RegId", SqlDbType.BigInt).Value = regId;
                        cmd.Parameters.Add("@UserId", SqlDbType.BigInt).Value = CurrentUserId;
                        int rows = cmd.ExecuteNonQuery();
                        ShowAlert(rows > 0 ? "Đã huỷ đăng ký thành công." : "Không thể huỷ (trạng thái đã thay đổi).",
                                  rows > 0 ? "success" : "error");
                    }
                }
            }
            catch (Exception ex) { ShowAlert("Lỗi: " + ex.Message, "error"); }

            LoadAllData();
        }

        // ──────────────────────────────────────────────────────────────
        // EXPORT .ICS
        // ──────────────────────────────────────────────────────────────
        private void ExportAllIcs()
        {
            const string sql = @"
                SELECT e.title, e.description, e.start_at, e.end_at,
                       e.location_name, e.location_room, e.address, e.format
                FROM dbo.event_registrations r
                INNER JOIN dbo.events e ON e.id = r.event_id
                WHERE r.user_id = @UserId
                  AND r.status  IN (N'approved', N'pending')
                  AND e.start_at >= GETDATE()
                  AND e.deleted_at IS NULL
                ORDER BY e.start_at ASC;";

            DataTable dt = ExecuteTable(sql, new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });

            var sb = new StringBuilder();
            sb.AppendLine("BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//EventHub//MyEvents//VI\r\nCALSCALE:GREGORIAN");
            foreach (DataRow row in dt.Rows)
            {
                DateTime start = Convert.ToDateTime(row["start_at"]);
                DateTime end = Convert.ToDateTime(row["end_at"]);
                sb.AppendLine($"BEGIN:VEVENT\r\nUID:{Guid.NewGuid()}@eventhub\r\nDTSTART:{start:yyyyMMddTHHmmss}\r\nDTEND:{end:yyyyMMddTHHmmss}\r\nSUMMARY:{SafeStr(row["title"])}\r\nLOCATION:{FormatLocation(SafeStr(row["format"]), SafeStr(row["location_name"]), SafeStr(row["location_room"]), SafeStr(row["address"]))}\r\nEND:VEVENT");
            }
            sb.AppendLine("END:VCALENDAR");

            Response.Clear();
            Response.ContentType = "text/calendar";
            Response.AddHeader("Content-Disposition", "attachment; filename=my-events.ics");
            Response.Write(sb.ToString());
            Response.End();
        }

        private void ShowAlert(string message, string kind = "info")
        {
            pnlAlert.Visible = true;
            pnlAlert.CssClass = "me-alert " + kind;
            litAlert.Text = HttpUtility.HtmlEncode(message);
        }

        // ──────────────────────────────────────────────────────────────
        // UTILITIES
        // ──────────────────────────────────────────────────────────────
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

        private static string SafeStr(object value, string fallback = "")
        {
            if (value == null || value == DBNull.Value) return fallback;
            string t = Convert.ToString(value);
            return string.IsNullOrWhiteSpace(t) ? fallback : t;
        }

        private static string FilterToTitle(string f)
        {
            switch ((f ?? "ALL").ToLowerInvariant())
            {
                case "approved": return "Đã duyệt";
                case "pending": return "Chờ duyệt";
                case "waitlist": return "Danh sách chờ";
                case "attended": return "Đã tham gia";
                case "rejected": return "Bị từ chối";
                case "cancelled": return "Đã huỷ";
                default: return "Tất cả";
            }
        }

        private static string FormatScheduleText(object startObj, object endObj)
        {
            if (startObj == null || startObj == DBNull.Value) return "—";
            DateTime start = Convert.ToDateTime(startObj);
            DateTime end = endObj == null || endObj == DBNull.Value ? start.AddHours(1) : Convert.ToDateTime(endObj);
            return $"{start:dd/MM/yyyy} · {start:HH:mm} — {end:HH:mm}";
        }

        private static string FormatLocation(string fmt, string locationName, string locationRoom, string address)
        {
            fmt = (fmt ?? "offline").ToLowerInvariant();
            if (fmt == "online") return "Online";
            string r = locationName ?? "";
            if (!string.IsNullOrWhiteSpace(locationRoom))
                r = string.IsNullOrWhiteSpace(r) ? locationRoom : r + ", " + locationRoom;
            if (string.IsNullOrWhiteSpace(r)) r = address ?? "";
            else if (!string.IsNullOrWhiteSpace(address) && !r.Contains(address)) r += " · " + address;
            if (fmt == "hybrid") return string.IsNullOrWhiteSpace(r) ? "Hybrid" : r + " · Hybrid";
            return string.IsNullOrWhiteSpace(r) ? "—" : r;
        }

        private static string AbbreviateDow(string d)
        {
            switch ((d ?? "").ToLowerInvariant().Trim())
            {
                case "monday": case "thứ hai": return "Thứ Hai";
                case "tuesday": case "thứ ba": return "Thứ Ba";
                case "wednesday": case "thứ tư": return "Thứ Tư";
                case "thursday": case "thứ năm": return "Thứ Năm";
                case "friday": case "thứ sáu": return "Thứ Sáu";
                case "saturday": case "thứ bảy": return "Thứ Bảy";
                case "sunday": case "chủ nhật": return "CN";
                default: return string.IsNullOrEmpty(d) ? "—" : d;
            }
        }

        // Public helpers cho databinding <%# ... %>
        public string GetItemClass(object statusObj, object attendedObj)
        {
            string attended = SafeStr(attendedObj).ToLowerInvariant();
            if (attended == "present" || attended == "late" || attended == "left_early") return "confirmed";
            switch (SafeStr(statusObj).ToLowerInvariant())
            {
                case "approved": return "confirmed";
                case "pending": return "pending";
                case "waitlist": return "waitlist";
                case "rejected": return "rejected";
                case "cancelled": return "cancelled";
                default: return "pending";
            }
        }

        public string GetStatusLabel(object statusObj, object attendedObj)
        {
            string attended = SafeStr(attendedObj).ToLowerInvariant();
            if (attended == "present" || attended == "late" || attended == "left_early") return "Đã tham gia";
            switch (SafeStr(statusObj).ToLowerInvariant())
            {
                case "approved": return "Đã duyệt";
                case "pending": return "Chờ duyệt";
                case "waitlist": return "Danh sách chờ";
                case "rejected": return "Đã từ chối";
                case "cancelled": return "Đã huỷ";
                default: return SafeStr(statusObj);
            }
        }

        public string GetStatusIconHtml(object s, object a) => CheckSvgForClass(GetItemClass(s, a));

        private static string CheckSvgForClass(string cls)
        {
            switch (cls)
            {
                case "confirmed": return CheckSvg();
                case "pending": return ClockSvg();
                case "waitlist": return ListSvg();
                default: return XSvg();
            }
        }

        private static string CheckSvg() => "<svg viewBox='0 0 24 24' fill='none' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'><polyline points='20,6 9,17 4,12'/></svg>";
        private static string ClockSvg() => "<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><circle cx='12' cy='12' r='10'/><polyline points='12,6 12,12 16,14'/></svg>";
        private static string ListSvg() => "<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><line x1='10' y1='6' x2='21' y2='6'/><line x1='10' y1='12' x2='21' y2='12'/><line x1='10' y1='18' x2='21' y2='18'/></svg>";
        private static string XSvg() => "<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><line x1='18' y1='6' x2='6' y2='18'/><line x1='6' y1='6' x2='18' y2='18'/></svg>";
        private static string XCircleSvg() => "<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><circle cx='12' cy='12' r='10'/><line x1='15' y1='9' x2='9' y2='15'/><line x1='9' y1='9' x2='15' y2='15'/></svg>";
    }
}