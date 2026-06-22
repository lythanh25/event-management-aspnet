using Eventhub.App_Code;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Eventhub.Admin
{
    public partial class dashboard : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {

            var master = this.Master as AdminMaster;
            if (master != null) master.Breadcrumb = "Dashboard";

            if (!IsPostBack)
            {
                litLastUpdate.Text = "Hôm nay, "
                    + DateTime.Now.ToString("HH:mm", CultureInfo.InvariantCulture)
                    + " — Tháng " + DateTime.Now.Month + " năm " + DateTime.Now.Year;

                try
                {
                    LoadMainStats();
                    LoadMiniStats();
                    LoadMonthlyChart();
                    LoadTasks();
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine("Dashboard load error: " + ex.Message);
                }
            }
        }

        // ─────────────────────────────────────────────────────────
        // 4 thẻ thống kê chính
        // ─────────────────────────────────────────────────────────
        private void LoadMainStats()
        {
            const string sql = @"
                DECLARE @firstOfMonth DATETIME2 = DATEFROMPARTS(YEAR(SYSUTCDATETIME()), MONTH(SYSUTCDATETIME()), 1);
                DECLARE @firstOfPrev  DATETIME2 = DATEADD(MONTH, -1, @firstOfMonth);

                SELECT
                    (SELECT COUNT(*) FROM dbo.events WHERE deleted_at IS NULL)                                    AS TotalEvents,
                    (SELECT COUNT(*) FROM dbo.events WHERE deleted_at IS NULL AND created_at >= @firstOfMonth)   AS EventsThisMonth,
                    (SELECT COUNT(*) FROM dbo.events WHERE deleted_at IS NULL AND created_at >= @firstOfPrev 
                                                       AND created_at <  @firstOfMonth)                           AS EventsLastMonth,

                    (SELECT COUNT(*) FROM dbo.users WHERE is_active = 1)                                          AS TotalUsers,
                    (SELECT COUNT(*) FROM dbo.users WHERE is_active = 1 AND created_at >= @firstOfMonth)         AS UsersThisMonth,
                    (SELECT COUNT(*) FROM dbo.users WHERE is_active = 1 AND created_at >= @firstOfPrev 
                                                       AND created_at <  @firstOfMonth)                           AS UsersLastMonth,

                    (SELECT COUNT(*) FROM dbo.event_registrations)                                                AS TotalRegs,
                    (SELECT COUNT(*) FROM dbo.event_registrations WHERE registered_at >= @firstOfMonth)          AS RegsThisMonth,
                    (SELECT COUNT(*) FROM dbo.event_registrations WHERE registered_at >= @firstOfPrev 
                                                                  AND registered_at <  @firstOfMonth)             AS RegsLastMonth,

                    ISNULL((
                        SELECT CAST(SUM(CASE WHEN a.status = N'present' THEN 1 ELSE 0 END) AS FLOAT)
                               / NULLIF(COUNT(a.id), 0) * 100
                        FROM dbo.attendances a
                        INNER JOIN dbo.events e ON e.id = a.event_id
                        WHERE e.end_at >= @firstOfMonth
                    ), 0) AS AttendanceThisMonth,

                    ISNULL((
                        SELECT CAST(SUM(CASE WHEN a.status = N'present' THEN 1 ELSE 0 END) AS FLOAT)
                               / NULLIF(COUNT(a.id), 0) * 100
                        FROM dbo.attendances a
                        INNER JOIN dbo.events e ON e.id = a.event_id
                        WHERE e.end_at >= @firstOfPrev AND e.end_at < @firstOfMonth
                    ), 0) AS AttendanceLastMonth;
            ";

            using (var conn = Database.OpenConnection())
            using (var cmd = new SqlCommand(sql, conn))
            using (var r = cmd.ExecuteReader())
            {
                if (r.Read())
                {
                    int totalEvents = ToInt(r["TotalEvents"]);
                    int evtThis = ToInt(r["EventsThisMonth"]);
                    int evtPrev = ToInt(r["EventsLastMonth"]);

                    int totalUsers = ToInt(r["TotalUsers"]);
                    int usrThis = ToInt(r["UsersThisMonth"]);
                    int usrPrev = ToInt(r["UsersLastMonth"]);

                    int totalRegs = ToInt(r["TotalRegs"]);
                    int regThis = ToInt(r["RegsThisMonth"]);
                    int regPrev = ToInt(r["RegsLastMonth"]);

                    double attThis = ToDouble(r["AttendanceThisMonth"]);
                    double attPrev = ToDouble(r["AttendanceLastMonth"]);

                    litTotalEvents.Text = totalEvents.ToString("N0");
                    litEventsThisMonth.Text = evtThis.ToString();
                    litEventsTrend.Text = FormatTrend(evtThis, evtPrev);

                    litTotalUsers.Text = totalUsers.ToString("N0");
                    litUsersThisMonth.Text = usrThis.ToString();
                    litUsersTrend.Text = ComputeTrend(usrThis, usrPrev).ToString("0");

                    litTotalRegistrations.Text = totalRegs.ToString("N0");
                    litRegThisMonth.Text = regThis.ToString();
                    litRegTrend.Text = ComputeTrend(regThis, regPrev).ToString("0");

                    litAttendanceRate.Text = attThis.ToString("0.0");
                    litAttendPrev.Text = attPrev.ToString("0.0");
                    litAttendTrend.Text = (attThis - attPrev).ToString("+0.#;-0.#;0");
                }
            }
        }

        // ─────────────────────────────────────────────────────────
        // 4 thẻ mini
        // ─────────────────────────────────────────────────────────
        private void LoadMiniStats()
        {
            const string sql = @"
                DECLARE @nextMonthStart DATETIME2 = DATEFROMPARTS(YEAR(DATEADD(MONTH,1,SYSUTCDATETIME())),
                                                                  MONTH(DATEADD(MONTH,1,SYSUTCDATETIME())), 1);
                DECLARE @nextMonthEnd DATETIME2 = DATEADD(MONTH, 1, @nextMonthStart);

                SELECT
                    (SELECT COUNT(*) FROM dbo.event_registrations WHERE status = N'pending')                  AS Pending,
                    (SELECT COUNT(*) FROM dbo.events WHERE status = N'open' AND deleted_at IS NULL)           AS OpenEvents,
                    (SELECT COUNT(*) FROM dbo.v_event_registration_stats 
                         WHERE available_slots <= 5 AND available_slots > 0)                                   AS AlmostFull,
                    (SELECT COUNT(*) FROM dbo.events 
                         WHERE deleted_at IS NULL 
                           AND start_at >= @nextMonthStart 
                           AND start_at <  @nextMonthEnd)                                                      AS NextMonth;
            ";

            using (var conn = Database.OpenConnection())
            using (var cmd = new SqlCommand(sql, conn))
            using (var r = cmd.ExecuteReader())
            {
                if (r.Read())
                {
                    litPending.Text = ToInt(r["Pending"]).ToString();
                    litOpenEvents.Text = ToInt(r["OpenEvents"]).ToString();
                    litAlmostFull.Text = ToInt(r["AlmostFull"]).ToString();
                    litNextMonth.Text = ToInt(r["NextMonth"]).ToString();
                }
            }
        }

        // ─────────────────────────────────────────────────────────
        // Biểu đồ cột: 6 tháng gần nhất
        // ─────────────────────────────────────────────────────────
        private void LoadMonthlyChart()
        {
            const string sql = @"
                ;WITH months AS (
                    SELECT 0 AS i UNION ALL SELECT 1 UNION ALL SELECT 2 
                    UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
                ),
                m AS (
                    SELECT
                        DATEFROMPARTS(YEAR(DATEADD(MONTH, -i, SYSUTCDATETIME())),
                                      MONTH(DATEADD(MONTH, -i, SYSUTCDATETIME())), 1) AS startDate
                    FROM months
                )
                SELECT 
                    MONTH(m.startDate) AS MonthNum,
                    (SELECT COUNT(*) FROM dbo.event_registrations r
                        WHERE r.registered_at >= m.startDate 
                          AND r.registered_at <  DATEADD(MONTH,1,m.startDate)) AS Signups,
                    (SELECT COUNT(*) FROM dbo.attendances a 
                        WHERE a.status = N'present'
                          AND a.checked_in_at >= m.startDate 
                          AND a.checked_in_at <  DATEADD(MONTH,1,m.startDate)) AS Attends
                FROM m
                ORDER BY m.startDate ASC;
            ";

            var dt = new DataTable();
            using (var conn = Database.OpenConnection())
            using (var cmd = new SqlCommand(sql, conn))
            using (var da = new SqlDataAdapter(cmd))
            {
                da.Fill(dt);
            }

            int maxVal = 1;
            foreach (DataRow row in dt.Rows)
            {
                int s = ToInt(row["Signups"]);
                int a = ToInt(row["Attends"]);
                if (s > maxVal) maxVal = s;
                if (a > maxVal) maxVal = a;
            }

            var chart = new List<object>();
            foreach (DataRow row in dt.Rows)
            {
                int s = ToInt(row["Signups"]);
                int a = ToInt(row["Attends"]);
                int month = ToInt(row["MonthNum"]);

                chart.Add(new
                {
                    MonthLabel = "T" + month,
                    SignupHeight = (int)(s * 95.0 / maxVal),
                    AttendHeight = (int)(a * 95.0 / maxVal)
                });
            }

            rptMonthlyChart.DataSource = chart;
            rptMonthlyChart.DataBind();
        }

        // ─────────────────────────────────────────────────────────
        // Cần xử lý ngay
        // ─────────────────────────────────────────────────────────
        private void LoadTasks()
        {
            phTasks.Controls.Clear();

            // 1. Đơn pending quá 24h
            int oldPending = ExecScalarInt(@"
                SELECT COUNT(*) FROM dbo.event_registrations 
                WHERE status = N'pending' 
                  AND registered_at < DATEADD(HOUR, -24, SYSUTCDATETIME())");

            if (oldPending > 0)
            {
                phTasks.Controls.Add(BuildTask(
                    "urgent", "red", "alert",
                    "<b>" + oldPending + " đơn đăng ký</b> đang chờ xét duyệt quá 24 giờ",
                    "Bây giờ"));
            }

            // 2. Sự kiện sắp diễn ra (≤3 ngày)
            using (var conn = Database.OpenConnection())
            using (var cmd = new SqlCommand(@"
                SELECT TOP 1 title 
                FROM dbo.events 
                WHERE status = N'open' AND deleted_at IS NULL
                  AND start_at BETWEEN SYSUTCDATETIME() AND DATEADD(DAY, 3, SYSUTCDATETIME())
                ORDER BY start_at ASC", conn))
            {
                object o = cmd.ExecuteScalar();
                if (o != null && o != DBNull.Value)
                {
                    phTasks.Controls.Add(BuildTask(
                        "warn", "amber", "clock",
                        "Sự kiện <b>\"" + Server.HtmlEncode(o.ToString()) + "\"</b> sắp diễn ra — chưa gửi nhắc nhở",
                        "Hôm nay"));
                }
            }

            // 3. Sự kiện đã kết thúc, chưa có điểm danh
            using (var conn = Database.OpenConnection())
            using (var cmd = new SqlCommand(@"
                SELECT TOP 1 title 
                FROM dbo.events 
                WHERE deleted_at IS NULL AND status IN (N'open', N'closed')
                  AND end_at < SYSUTCDATETIME()
                  AND id NOT IN (SELECT DISTINCT event_id FROM dbo.attendances)
                ORDER BY end_at DESC", conn))
            {
                object o = cmd.ExecuteScalar();
                if (o != null && o != DBNull.Value)
                {
                    phTasks.Controls.Add(BuildTask(
                        "info", "blue", "check",
                        "Sự kiện <b>" + Server.HtmlEncode(o.ToString()) + "</b> đã kết thúc — cần xác nhận điểm danh",
                        "1 ngày"));
                }
            }

            if (phTasks.Controls.Count == 0)
            {
                phTasks.Controls.Add(new LiteralControl(
                    @"<div class='task-item muted'>
                        <div class='task-icon green'>
                            <svg viewBox='0 0 24 24' fill='none' stroke-linecap='round' stroke-linejoin='round'>
                                <polyline points='20,6 9,17 4,12'/>
                            </svg>
                        </div>
                        <div class='task-content'>
                            <div class='task-row-1'>
                                <div class='task-text'>Mọi việc đều ổn — không có nhiệm vụ cần xử lý.</div>
                            </div>
                        </div>
                    </div>"));
            }
        }

        // ─────────────────────────────────────────────────────────
        // Helpers
        // ─────────────────────────────────────────────────────────
        private LiteralControl BuildTask(string itemCss, string iconColor, string iconType, string textHtml, string time)
        {
            string iconSvg;
            switch (iconType)
            {
                case "alert":
                    iconSvg = @"<svg viewBox='0 0 24 24' fill='none' stroke-linecap='round' stroke-linejoin='round'>
                        <circle cx='12' cy='12' r='10'/><line x1='12' y1='8' x2='12' y2='12'/><line x1='12' y1='16' x2='12.01' y2='16'/></svg>";
                    break;
                case "clock":
                    iconSvg = @"<svg viewBox='0 0 24 24' fill='none' stroke-linecap='round' stroke-linejoin='round'>
                        <circle cx='12' cy='12' r='10'/><polyline points='12,6 12,12 16,14'/></svg>";
                    break;
                default:
                    iconSvg = @"<svg viewBox='0 0 24 24' fill='none' stroke-linecap='round' stroke-linejoin='round'>
                        <polyline points='20,6 9,17 4,12'/></svg>";
                    break;
            }

            string html =
                "<div class='task-item " + itemCss + "'>" +
                    "<div class='task-icon " + iconColor + "'>" + iconSvg + "</div>" +
                    "<div class='task-content'>" +
                        "<div class='task-row-1'>" +
                            "<div class='task-text'>" + textHtml + "</div>" +
                            "<div class='task-time'>" + time + "</div>" +
                        "</div>" +
                    "</div>" +
                "</div>";
            return new LiteralControl(html);
        }

        private int ExecScalarInt(string sql)
        {
            using (var conn = Database.OpenConnection())
            using (var cmd = new SqlCommand(sql, conn))
            {
                object o = cmd.ExecuteScalar();
                return (o == null || o == DBNull.Value) ? 0 : Convert.ToInt32(o);
            }
        }

        private static int ToInt(object o)
        {
            return (o == null || o == DBNull.Value) ? 0 : Convert.ToInt32(o);
        }

        private static double ToDouble(object o)
        {
            return (o == null || o == DBNull.Value) ? 0 : Convert.ToDouble(o);
        }

        private static double ComputeTrend(int current, int previous)
        {
            if (previous == 0) return current > 0 ? 100 : 0;
            return Math.Round(((current - previous) * 100.0) / previous);
        }

        private static string FormatTrend(int current, int previous)
        {
            double t = ComputeTrend(current, previous);
            return (t >= 0 ? "+" : "") + t.ToString("0") + "%";
        }
    }
}