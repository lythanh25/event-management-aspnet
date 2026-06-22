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
    public partial class attendancedetail : System.Web.UI.Page
    {
        #region View Model

        public class EventCardVM
        {
            public long Id { get; set; }
            public string Title { get; set; }
            public DateTime StartAt { get; set; }
            public DateTime EndAt { get; set; }
            public string LocationName { get; set; }
            public string CategoryName { get; set; }
            public string Format { get; set; }
            public string OrganizerName { get; set; }
            public int Capacity { get; set; }
            public int ApprovedCount { get; set; }
            public int CheckedInCount { get; set; }
            public int LateCount { get; set; }

            public int BannerIndex { get; set; }
            public string TimeText { get; set; }
            public string BannerTag { get; set; }

            // Status badge
            public string StatusBadgeClass { get; set; }  
            public string StatusBadgeText { get; set; }

            // Progress
            public string ProgressLabel { get; set; }     
            public int ProgressNum { get; set; }
            public int ProgressDenom { get; set; }
            public int ProgressPercent { get; set; }
            public string ProgressColor { get; set; }     
            public string InfoRowText { get; set; }

            // Footer action
            public string ActionClass { get; set; }       
            public string ActionText { get; set; }
        }

        #endregion

        #region Properties

        private string Filter
        {
            get { return (ViewState["filter"] as string) ?? "today"; }
            set { ViewState["filter"] = value; }
        }

        private string Keyword
        {
            get { return (ViewState["kw"] as string) ?? ""; }
            set { ViewState["kw"] = value ?? ""; }
        }

        #endregion

        protected void Page_Load(object sender, EventArgs e)
        {
            var master = Master as Eventhub.AdminMaster;
            if (master != null) master.Breadcrumb = "Điểm danh";

            if (!IsPostBack)
            {
                var qs = Request.QueryString["filter"];
                if (!string.IsNullOrEmpty(qs) &&
                    new[] { "today", "upcoming", "ended", "all" }.Contains(qs))
                {
                    Filter = qs;
                }
                else
                {
                    Filter = "today";
                }

                LoadCounts();
                LoadLiveHero();
                LoadEvents();
            }

            SetTabUrls();
            SetActiveTab();
        }

        #region URL & active tab

        private void SetTabUrls()
        {
            tabToday.NavigateUrl = "~/Admin/AttendanceHub.aspx?filter=today";
            tabUpcoming.NavigateUrl = "~/Admin/AttendanceHub.aspx?filter=upcoming";
            tabEnded.NavigateUrl = "~/Admin/AttendanceHub.aspx?filter=ended";
            tabAll.NavigateUrl = "~/Admin/AttendanceHub.aspx?filter=all";
        }

        private void SetActiveTab()
        {
            tabToday.CssClass = "filter-tab" + (Filter == "today" ? " active" : "");
            tabUpcoming.CssClass = "filter-tab" + (Filter == "upcoming" ? " active" : "");
            tabEnded.CssClass = "filter-tab" + (Filter == "ended" ? " active" : "");
            tabAll.CssClass = "filter-tab" + (Filter == "all" ? " active" : "");

            switch (Filter)
            {
                case "today":
                    litSectionTitle.Text = "Hôm nay";
                    litSectionSub.Text = DateTime.Now.ToString("dd/MM");
                    break;
                case "upcoming":
                    litSectionTitle.Text = "Sắp diễn ra";
                    litSectionSub.Text = "7 ngày tới";
                    break;
                case "ended":
                    litSectionTitle.Text = "Đã kết thúc";
                    litSectionSub.Text = "30 ngày qua";
                    break;
                default:
                    litSectionTitle.Text = "Tất cả";
                    litSectionSub.Text = "sự kiện được phép điểm danh";
                    break;
            }
        }

        #endregion

        #region Load Counts (cho 4 tab)

        private void LoadCounts()
        {
            int today = 0, upcoming = 0, ended = 0, all = 0;
            var now = DateTime.Now;

            try
            {
                const string sql = @"
                    SELECT id, start_at, end_at
                    FROM dbo.events
                    WHERE deleted_at IS NULL
                      AND status IN (N'open', N'closed', N'ended');";

                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                using (var rd = cmd.ExecuteReader())
                {
                    while (rd.Read())
                    {
                        var start = Convert.ToDateTime(rd["start_at"]);
                        var end = Convert.ToDateTime(rd["end_at"]);

                        if (start.Date == now.Date || (now >= start && now <= end))
                            today++;
                        else if (start > now && (start - now).TotalDays <= 7)
                            upcoming++;
                        else if (end < now && (now - end).TotalDays <= 30)
                            ended++;

                        all++;
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("LoadCounts error: " + ex.Message);
            }

            litCntToday.Text = today.ToString();
            litCntUpcoming.Text = upcoming.ToString();
            litCntEnded.Text = ended.ToString();
            litCntAll.Text = all.ToString();
        }

        #endregion

        #region Load Live Hero

        private void LoadLiveHero()
        {
            try
            {
                const string sql = @"
                    SELECT TOP 1 e.id, e.title, e.start_at, e.end_at, e.location_name, e.capacity,
                           u.first_name + N' ' + u.last_name AS organizer_name,
                           (SELECT COUNT(*) FROM dbo.event_registrations r
                            WHERE r.event_id = e.id AND r.status = N'approved') AS approved_cnt,
                           (SELECT COUNT(*) FROM dbo.attendances a
                            WHERE a.event_id = e.id AND a.status IN (N'present', N'late', N'left_early')) AS checked_in_cnt,
                           (SELECT COUNT(*) FROM dbo.attendances a
                            WHERE a.event_id = e.id AND a.is_late = 1) AS late_cnt
                    FROM dbo.events e
                    JOIN dbo.users u ON u.id = e.created_by
                    WHERE e.deleted_at IS NULL
                      AND SYSDATETIME() BETWEEN e.start_at AND e.end_at
                      AND e.status IN (N'open', N'closed')
                    ORDER BY e.start_at;";

                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                using (var rd = cmd.ExecuteReader())
                {
                    if (rd.Read())
                    {
                        var startAt = Convert.ToDateTime(rd["start_at"]);
                        var endAt = Convert.ToDateTime(rd["end_at"]);
                        var approved = Convert.ToInt32(rd["approved_cnt"]);
                        var checkedIn = Convert.ToInt32(rd["checked_in_cnt"]);
                        var late = Convert.ToInt32(rd["late_cnt"]);
                        var eid = Convert.ToInt64(rd["id"]);

                        pnlLiveHero.Visible = true;
                        litLiveTitle.Text = HttpUtility.HtmlEncode(rd["title"].ToString());
                        litLiveDate.Text = (startAt.Date == DateTime.Now.Date ? "Hôm nay, " : "")
                                              + startAt.ToString("dd/MM/yyyy");
                        litLiveTime.Text = startAt.ToString("HH:mm") + " – " + endAt.ToString("HH:mm");
                        litLiveLocation.Text = HttpUtility.HtmlEncode(rd["location_name"] as string ?? "Chưa có địa điểm");
                        litLiveOrganizer.Text = HttpUtility.HtmlEncode(rd["organizer_name"].ToString().Trim());

                        litLiveApproved.Text = approved.ToString();
                        litLiveCheckedIn.Text = checkedIn.ToString();
                        litLiveApprovedSlash.Text = approved.ToString();
                        litLiveLate.Text = late.ToString();
                        litLiveAbsent.Text = Math.Max(0, approved - checkedIn).ToString();

                        int pct = approved > 0 ? Math.Min(100, (int)Math.Round(checkedIn * 100.0 / approved)) : 0;
                        divLiveBar.Attributes["style"] = "width: " + pct + "%";

                        lnkLiveEnter.NavigateUrl = "~/Admin/AttendanceDetail.aspx?eventId=" + eid;
                    }
                    else
                    {
                        pnlLiveHero.Visible = false;
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("LoadLiveHero error: " + ex.Message);
                pnlLiveHero.Visible = false;
            }
        }

        #endregion

        #region Load Events Grid

        private void LoadEvents()
        {
            var list = new List<EventCardVM>();
            var now = DateTime.Now;

            var sql = new StringBuilder();
            sql.AppendLine(@"
                SELECT e.id, e.title, e.start_at, e.end_at, e.location_name, e.capacity, e.format,
                       c.name AS category_name,
                       u.first_name + N' ' + u.last_name AS organizer_name,
                       (SELECT COUNT(*) FROM dbo.event_registrations r
                        WHERE r.event_id = e.id AND r.status = N'approved') AS approved_cnt,
                       ISNULL((SELECT COUNT(*) FROM dbo.attendances a
                               WHERE a.event_id = e.id AND a.status IN (N'present', N'late', N'left_early')), 0) AS checked_in_cnt,
                       ISNULL((SELECT COUNT(*) FROM dbo.attendances a
                               WHERE a.event_id = e.id AND a.is_late = 1), 0) AS late_cnt
                FROM dbo.events e
                JOIN dbo.event_categories c ON c.id = e.category_id
                JOIN dbo.users u ON u.id = e.created_by
                WHERE e.deleted_at IS NULL
                  AND e.status IN (N'open', N'closed', N'ended')");

            switch (Filter)
            {
                case "today":
                    sql.AppendLine(@" AND (CAST(e.start_at AS DATE) = CAST(SYSDATETIME() AS DATE)
                                       OR (SYSDATETIME() BETWEEN e.start_at AND e.end_at))");
                    break;
                case "upcoming":
                    sql.AppendLine(@" AND e.start_at > SYSDATETIME()
                                  AND DATEDIFF(DAY, SYSDATETIME(), e.start_at) <= 7");
                    break;
                case "ended":
                    sql.AppendLine(@" AND e.end_at < SYSDATETIME()
                                  AND DATEDIFF(DAY, e.end_at, SYSDATETIME()) <= 30");
                    break;
            }

            if (!string.IsNullOrEmpty(Keyword))
                sql.AppendLine(@" AND e.title LIKE @kw");

            if (Filter == "ended")
                sql.AppendLine(" ORDER BY e.end_at DESC;");
            else
                sql.AppendLine(" ORDER BY e.start_at;");

            try
            {
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql.ToString(), con))
                {
                    if (!string.IsNullOrEmpty(Keyword))
                        cmd.Parameters.AddWithValue("@kw", "%" + Keyword + "%");

                    using (var rd = cmd.ExecuteReader())
                    {
                        int idx = 0;
                        while (rd.Read())
                        {
                            var startAt = Convert.ToDateTime(rd["start_at"]);
                            var endAt = Convert.ToDateTime(rd["end_at"]);
                            var approved = Convert.ToInt32(rd["approved_cnt"]);
                            var checkedIn = Convert.ToInt32(rd["checked_in_cnt"]);

                            var item = new EventCardVM
                            {
                                Id = Convert.ToInt64(rd["id"]),
                                Title = rd["title"].ToString(),
                                StartAt = startAt,
                                EndAt = endAt,
                                LocationName = rd["location_name"] as string ?? "Chưa có địa điểm",
                                CategoryName = rd["category_name"].ToString(),
                                Format = rd["format"].ToString(),
                                OrganizerName = rd["organizer_name"].ToString().Trim(),
                                Capacity = Convert.ToInt32(rd["capacity"]),
                                ApprovedCount = approved,
                                CheckedInCount = checkedIn,
                                LateCount = Convert.ToInt32(rd["late_cnt"]),
                                BannerIndex = (idx % 6) + 1
                            };

                            BuildBadgesAndProgress(item, now);
                            list.Add(item);
                            idx++;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("LoadEvents error: " + ex.Message);
            }

            rptEvents.DataSource = list;
            rptEvents.DataBind();

            pnlEmpty.Visible = list.Count == 0;
            litSectionCount.Text = list.Count.ToString();
        }

        private static void BuildBadgesAndProgress(EventCardVM item, DateTime now)
        {
            if (now >= item.StartAt && now <= item.EndAt)
            {
                item.StatusBadgeClass = "live";
                item.StatusBadgeText = "ĐANG DIỄN RA";
                item.ActionClass = "live";
                item.ActionText = "Mở điểm danh";

                int pct = item.ApprovedCount > 0
                    ? Math.Min(100, (int)Math.Round(item.CheckedInCount * 100.0 / item.ApprovedCount))
                    : 0;
                item.ProgressLabel = "Đã có mặt";
                item.ProgressNum = item.CheckedInCount;
                item.ProgressDenom = item.ApprovedCount;
                item.ProgressPercent = pct;
                item.ProgressColor = "amber";
                item.InfoRowText = "người đã check-in";
                item.TimeText = item.StartAt.ToString("HH:mm") + " – " + item.EndAt.ToString("HH:mm") + " · đang diễn ra";
            }
            else if (item.StartAt > now)
            {
                var diff = item.StartAt - now;
                if (diff.TotalHours <= 6)
                {
                    item.StatusBadgeClass = "starting";
                    item.StatusBadgeText = "SẮP BẮT ĐẦU";
                }
                else if (item.StartAt.Date == now.Date)
                {
                    item.StatusBadgeClass = "starting";
                    item.StatusBadgeText = "HÔM NAY";
                }
                else
                {
                    item.StatusBadgeClass = "upcoming";
                    item.StatusBadgeText = "SẮP DIỄN RA";
                }

                item.ActionClass = "primary";
                item.ActionText = "Chuẩn bị điểm danh";

                int pct = item.Capacity > 0
                    ? Math.Min(100, (int)Math.Round(item.ApprovedCount * 100.0 / item.Capacity))
                    : 0;
                item.ProgressLabel = "Đã đăng ký";
                item.ProgressNum = item.ApprovedCount;
                item.ProgressDenom = item.Capacity;
                item.ProgressPercent = pct;
                item.ProgressColor = "green";
                item.InfoRowText = "người sẵn sàng";

                item.TimeText = item.StartAt.ToString("HH:mm") + " – " + item.EndAt.ToString("HH:mm")
                              + " · còn " + FormatDistance(diff);
            }
            else
            {
                item.StatusBadgeClass = "ended";
                item.StatusBadgeText = "ĐÃ KẾT THÚC";
                item.ActionClass = "ghost";
                item.ActionText = "Xem báo cáo";

                int pct = item.ApprovedCount > 0
                    ? Math.Min(100, (int)Math.Round(item.CheckedInCount * 100.0 / item.ApprovedCount))
                    : 0;
                item.ProgressLabel = "Tổng kết";
                item.ProgressNum = item.CheckedInCount;
                item.ProgressDenom = item.ApprovedCount;
                item.ProgressPercent = pct;
                item.ProgressColor = "dark";
                item.InfoRowText = "đã tham dự";

                item.TimeText = item.StartAt.ToString("HH:mm") + " – " + item.EndAt.ToString("HH:mm")
                              + " · " + (now - item.EndAt).Days + " ngày trước";
            }
            string format;
            switch (item.Format)
            {
                case "online": format = "ONLINE"; break;
                case "hybrid": format = "HYBRID"; break;
                default: format = "OFFLINE"; break;
            }
            item.BannerTag = item.CategoryName.ToUpper() + " • " + format;
        }

        private static string FormatDistance(TimeSpan ts)
        {
            int days = (int)Math.Floor(ts.TotalDays);
            int hours = ts.Hours;
            int minutes = ts.Minutes;

            if (days >= 1)
                return days + " ngày" + (hours > 0 ? " " + hours + " giờ" : "");
            if (hours >= 1)
                return hours + " giờ" + (minutes > 0 ? " " + minutes + " phút" : "");
            return minutes + " phút";
        }

        #endregion

        #region Search

        protected void txtSearch_TextChanged(object sender, EventArgs e)
        {
            Keyword = (txtSearch.Text ?? "").Trim();
            LoadEvents();
        }

        #endregion
    }
}