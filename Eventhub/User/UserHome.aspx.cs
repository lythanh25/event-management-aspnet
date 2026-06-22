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

namespace Eventhub.User
{
    public partial class UserHome : System.Web.UI.Page
    {
        private string connStr;
        private readonly CultureInfo vi = new CultureInfo("vi-VN");

        private string CurrentSearch
        {
            get => ViewState["Search"] as string ?? string.Empty;
            set => ViewState["Search"] = value;
        }

        private string CurrentFilter
        {
            get => ViewState["Filter"] as string ?? "ALL";
            set => ViewState["Filter"] = value;
        }

        private long CurrentUserId
        {
            get
            {
                object userId = Session["UserId"];
                if (userId == null)
                    throw new InvalidOperationException("Session UserId is missing.");
                return Convert.ToInt64(userId);
            }
        }

        // ──────────────────────────────────────────────────────────────
        // PAGE LIFECYCLE
        // ──────────────────────────────────────────────────────────────
        protected override void OnInit(EventArgs e)
        {
            base.OnInit(e);

            var cs = ConfigurationManager.ConnectionStrings["EventHub"];
            if (cs == null)
                throw new ConfigurationErrorsException("Missing connection string 'EventHub'.");

            connStr = cs.ConnectionString;
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            // Bảo vệ trang — Master cũng đã check, nhưng check lại cho an toàn.
            if (Session["UserId"] == null)
            {
                Response.Redirect("~/Account/Login.aspx");
                return;
            }

            if (!IsPostBack)
            {
                LoadAllData();
            }
        }

        // ──────────────────────────────────────────────────────────────
        // LOAD ALL — gọi mỗi khi cần render lại toàn bộ trang
        // ──────────────────────────────────────────────────────────────
        private void LoadAllData()
        {
            lblTodayLabel.Text = GetTodayLabel();
            lblPageMessage.Text = string.Empty;

            if (txtSearch != null)
                txtSearch.Text = CurrentSearch;

            LoadHeroUserInfo();
            LoadDashboardStats();
            LoadFeaturedEvent();
            LoadHotEvents();
            LoadUpcomingEvents(CurrentSearch, CurrentFilter);
            ApplyFilterState();
        }

        /// <summary>Cập nhật CSS class cho các filter-pill (đánh dấu mục đang chọn).</summary>
        private void ApplyFilterState()
        {
            SetPillClass(btnFilterAll, "ALL");
            SetPillClass(btnFilterTech, "Công nghệ");
            SetPillClass(btnFilterHR, "Nhân sự");
            SetPillClass(btnFilterCulture, "Văn hoá");
            SetPillClass(btnFilterTraining, "Đào tạo");
        }

        private void SetPillClass(LinkButton btn, string filterValue)
        {
            if (btn == null) return;
            btn.CssClass = CurrentFilter == filterValue ? "search-pill active" : "search-pill";
        }

        // ──────────────────────────────────────────────────────────────
        // HERO — Lấy first_name user để chào
        // ──────────────────────────────────────────────────────────────
        private void LoadHeroUserInfo()
        {
            const string sql = @"
                SELECT TOP 1 u.first_name
                FROM dbo.users u
                WHERE u.id = @UserId;";

            DataTable dt = ExecuteTable(sql,
                new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });

            lblShortName.Text = dt.Rows.Count == 0
                ? "bạn"
                : SafeString(dt.Rows[0]["first_name"], "bạn");
        }

        // ──────────────────────────────────────────────────────────────
        // DASHBOARD STATS — 3 chỉ số ở Hero
        // ──────────────────────────────────────────────────────────────
        private void LoadDashboardStats()
        {
            const string sql = @"
                SELECT
                    (SELECT COUNT(*)
                       FROM dbo.events
                      WHERE deleted_at IS NULL
                        AND status     = N'open'
                        AND start_at  >= GETDATE())                              AS UpcomingEvents,
 
                    (SELECT COUNT(*)
                       FROM dbo.event_registrations
                      WHERE user_id = @UserId
                        AND status  IN (N'pending', N'approved', N'waitlist'))   AS RegisteredEvents,
 
                    (SELECT COUNT(*)
                       FROM dbo.event_registrations
                      WHERE status = N'approved')                                AS TotalParticipants;";

            DataTable dt = ExecuteTable(sql,
                new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });

            if (dt.Rows.Count == 0)
            {
                lblUpcomingCount.Text = "0";
                lblRegisteredCount.Text = "0";
                lblTotalParticipants.Text = "0";
                return;
            }

            DataRow row = dt.Rows[0];
            lblUpcomingCount.Text = SafeString(row["UpcomingEvents"], "0");
            lblRegisteredCount.Text = SafeString(row["RegisteredEvents"], "0");
            lblTotalParticipants.Text = SafeString(row["TotalParticipants"], "0");
        }

        // ──────────────────────────────────────────────────────────────
        // FEATURED EVENT — Sự kiện nổi bật (1 cái)
        // ──────────────────────────────────────────────────────────────
        private void LoadFeaturedEvent()
        {
            const string sql = @"
                SELECT TOP 1
                    e.id,
                    e.title,
                    e.start_at,
                    e.end_at,
                    e.location_name,
                    e.location_room,
                    e.address,
                    e.format,
                    e.capacity,
                    COALESCE(c.name, N'Sự kiện') AS category_name,
                    ISNULL(rc.registered_count, 0) AS registered_count,
                    CAST(CASE WHEN e.capacity > 0
                              THEN ROUND(100.0 * ISNULL(rc.registered_count, 0) / e.capacity, 0)
                              ELSE 0
                         END AS INT) AS occupancy_percent,
                    CASE
                        WHEN ISNULL(rc.registered_count, 0) >= e.capacity              THEN N'full'
                        WHEN e.capacity - ISNULL(rc.registered_count, 0) <= 10         THEN N'almost'
                        ELSE N'hot'
                    END AS badge_class,
                    CASE
                        WHEN ISNULL(rc.registered_count, 0) >= e.capacity              THEN N'ĐÃ ĐẦY'
                        WHEN e.capacity - ISNULL(rc.registered_count, 0) <= 10         THEN N'SẮP HẾT CHỖ'
                        ELSE N'ĐANG MỞ ĐĂNG KÝ'
                    END AS badge_text,
                    CASE WHEN EXISTS (
                        SELECT 1 FROM dbo.event_registrations x
                        WHERE x.event_id = e.id
                          AND x.user_id  = @UserId
                          AND x.status   IN (N'pending', N'approved', N'waitlist')
                    ) THEN 1 ELSE 0 END AS is_registered
                FROM dbo.events e
                LEFT JOIN dbo.event_categories c ON c.id = e.category_id
                LEFT JOIN (
                    SELECT event_id, COUNT(*) AS registered_count
                    FROM dbo.event_registrations
                    WHERE status IN (N'pending', N'approved', N'waitlist')
                    GROUP BY event_id
                ) rc ON rc.event_id = e.id
                WHERE e.deleted_at IS NULL
                  AND e.status     <> N'cancelled'
                ORDER BY
                    CASE WHEN e.status = N'open' THEN 0 ELSE 1 END,
                    ISNULL(rc.registered_count, 0) DESC,
                    e.start_at ASC;";

            DataTable dt = ExecuteTable(sql,
                new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });

            if (dt.Rows.Count == 0)
            {
                lblFeaturedStatus.Text = "ĐANG CẬP NHẬT";
                lblFeaturedTitle.Text = "Chưa có sự kiện nổi bật";
                lblFeaturedDate.Text = "—";
                lblFeaturedLocation.Text = "—";
                lblFeaturedRegisteredText.Text = "0 / 0 người đã đăng ký";
                lblFeaturedPercent.Text = "0%";
                SetFeaturedProgress(0);
                btnFeaturedRegister.Text = "Đang cập nhật";
                btnFeaturedRegister.Enabled = false;
                btnFeaturedRegister.CssClass = "featured-cta registered";
                btnFeaturedRegister.CommandArgument = string.Empty;
                return;
            }

            DataRow row = dt.Rows[0];
            long eventId = Convert.ToInt64(row["id"]);
            int registered = Convert.ToInt32(row["registered_count"]);
            int capacity = Convert.ToInt32(row["capacity"]);
            int percent = Convert.ToInt32(row["occupancy_percent"]);
            bool isRegistered = Convert.ToInt32(row["is_registered"]) == 1;

            lblFeaturedStatus.Text = SafeString(row["badge_text"], "ĐANG MỞ ĐĂNG KÝ");
            lblFeaturedTitle.Text = SafeString(row["title"], "Sự kiện nổi bật");
            lblFeaturedDate.Text = FormatFeaturedDate(Convert.ToDateTime(row["start_at"]));
            lblFeaturedLocation.Text = FormatLocation(row["format"], row["location_name"],
                                                     row["location_room"], row["address"]);
            lblFeaturedRegisteredText.Text = $"{registered} / {capacity} người đã đăng ký";
            lblFeaturedPercent.Text = $"{percent}%";
            SetFeaturedProgress(percent);

            btnFeaturedRegister.CommandArgument = eventId.ToString();
            if (isRegistered)
            {
                btnFeaturedRegister.Text = "✓ Đã đăng ký";
                btnFeaturedRegister.Enabled = false;
                btnFeaturedRegister.CssClass = "featured-cta registered";
            }
            else
            {
                btnFeaturedRegister.Text = "Đăng ký ngay →";
                btnFeaturedRegister.Enabled = true;
                btnFeaturedRegister.CssClass = "featured-cta";
            }
        }

        // ──────────────────────────────────────────────────────────────
        // HOT EVENTS — Top 3 sự kiện đang HOT
        // ──────────────────────────────────────────────────────────────
        private void LoadHotEvents()
        {
            const string sql = @"
                SELECT TOP 3
                    e.id, e.title, e.start_at, e.end_at,
                    e.location_name, e.location_room, e.address, e.format, e.capacity,
                    COALESCE(c.name, N'Sự kiện') AS category_name,
                    ISNULL(rc.registered_count, 0) AS registered_count,
                    CASE
                        WHEN ISNULL(rc.registered_count, 0) >= e.capacity              THEN N'full'
                        WHEN e.capacity - ISNULL(rc.registered_count, 0) <= 10         THEN N'almost'
                        ELSE N'hot'
                    END AS badge_class,
                    CASE
                        WHEN ISNULL(rc.registered_count, 0) >= e.capacity              THEN N'ĐÃ ĐẦY'
                        WHEN e.capacity - ISNULL(rc.registered_count, 0) <= 10         THEN N'SẮP HẾT CHỖ'
                        ELSE N'HOT'
                    END AS badge_text,
                    CASE WHEN ur.event_id IS NULL THEN 0 ELSE 1 END AS is_registered
                FROM dbo.events e
                LEFT JOIN dbo.event_categories c ON c.id = e.category_id
                LEFT JOIN (
                    SELECT event_id, COUNT(*) AS registered_count
                    FROM dbo.event_registrations
                    WHERE status IN (N'pending', N'approved', N'waitlist')
                    GROUP BY event_id
                ) rc ON rc.event_id = e.id
                LEFT JOIN (
                    SELECT event_id
                    FROM dbo.event_registrations
                    WHERE user_id = @UserId
                      AND status  IN (N'pending', N'approved', N'waitlist')
                    GROUP BY event_id
                ) ur ON ur.event_id = e.id
                WHERE e.deleted_at IS NULL
                  AND e.status <> N'cancelled'
                ORDER BY
                    ISNULL(rc.registered_count, 0) DESC,
                    CASE WHEN e.status = N'open' THEN 0 ELSE 1 END,
                    e.start_at ASC;";

            DataTable dt = ExecuteTable(sql,
                new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });

            rptHotEvents.DataSource = dt;
            rptHotEvents.DataBind();

            if (pnlEmptyHot != null)
                pnlEmptyHot.Visible = dt.Rows.Count == 0;
        }

        // ──────────────────────────────────────────────────────────────
        // UPCOMING EVENTS — Top 4 sự kiện sắp diễn ra (có search + filter)
        // ──────────────────────────────────────────────────────────────
        private void LoadUpcomingEvents(string keyword, string filter)
        {
            const string sql = @"
                SELECT TOP 4
                    e.id, e.title, e.subtitle, e.description,
                    e.start_at, e.end_at,
                    e.location_name, e.location_room, e.address, e.format, e.capacity,
                    COALESCE(c.name, N'Sự kiện') AS category_name,
                    ISNULL(rc.registered_count, 0) AS registered_count,
                    CAST(CASE WHEN e.capacity > 0
                              THEN ROUND(100.0 * ISNULL(rc.registered_count, 0) / e.capacity, 0)
                              ELSE 0
                         END AS INT) AS occupancy_percent,
                    CASE
                        WHEN ISNULL(rc.registered_count, 0) >= e.capacity              THEN N'full'
                        WHEN e.capacity - ISNULL(rc.registered_count, 0) <= 10         THEN N'almost-full'
                        WHEN DATEDIFF(DAY, GETDATE(), e.start_at) <= 7                 THEN N'new'
                        ELSE N'bestseller'
                    END AS badge_class,
                    CASE
                        WHEN ISNULL(rc.registered_count, 0) >= e.capacity              THEN N'ĐÃ ĐẦY'
                        WHEN e.capacity - ISNULL(rc.registered_count, 0) <= 10         THEN N'SẮP HẾT CHỖ'
                        WHEN DATEDIFF(DAY, GETDATE(), e.start_at) <= 7                 THEN N'MỚI'
                        ELSE N'HOT'
                    END AS badge_text,
                    CASE WHEN ur.event_id IS NULL THEN 0 ELSE 1 END AS is_registered,
                    CASE
                        WHEN e.registration_deadline IS NULL                        THEN 0
                        WHEN DATEDIFF(DAY, GETDATE(), e.registration_deadline) < 0  THEN 0
                        ELSE DATEDIFF(DAY, GETDATE(), e.registration_deadline)
                    END AS days_left
                FROM dbo.events e
                LEFT JOIN dbo.event_categories c ON c.id = e.category_id
                LEFT JOIN (
                    SELECT event_id, COUNT(*) AS registered_count
                    FROM dbo.event_registrations
                    WHERE status IN (N'pending', N'approved', N'waitlist')
                    GROUP BY event_id
                ) rc ON rc.event_id = e.id
                LEFT JOIN (
                    SELECT event_id
                    FROM dbo.event_registrations
                    WHERE user_id = @UserId
                      AND status  IN (N'pending', N'approved', N'waitlist')
                    GROUP BY event_id
                ) ur ON ur.event_id = e.id
                WHERE e.deleted_at IS NULL
                  AND e.status <> N'cancelled'
                  AND (@Keyword = N''   OR e.title       LIKE '%' + @Keyword + '%'
                                        OR e.description LIKE '%' + @Keyword + '%')
                  AND (@Filter  = N'ALL' OR @Filter = N'' OR c.name = @Filter)
                ORDER BY
                    CASE WHEN e.start_at >= GETDATE() THEN 0 ELSE 1 END,
                    e.start_at ASC;";

            DataTable dt = ExecuteTable(sql,
                new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId },
                new SqlParameter("@Keyword", SqlDbType.NVarChar, 200) { Value = keyword ?? string.Empty },
                new SqlParameter("@Filter", SqlDbType.NVarChar, 50) { Value = filter ?? "ALL" });

            rptUpcomingEvents.DataSource = dt;
            rptUpcomingEvents.DataBind();

            if (pnlEmptyUpcoming != null)
                pnlEmptyUpcoming.Visible = dt.Rows.Count == 0;
        }

        // ══════════════════════════════════════════════════════════════
        // EVENT HANDLERS
        // ══════════════════════════════════════════════════════════════

        protected void btnSearch_Click(object sender, EventArgs e)
        {
            CurrentSearch = (txtSearch.Text ?? string.Empty).Trim();
            LoadAllData();
        }

        protected void Filter_Click(object sender, EventArgs e)
        {
            CurrentFilter = ((LinkButton)sender).CommandArgument;
            LoadAllData();
        }

        protected void btnFeaturedRegister_Click(object sender, EventArgs e)
        {
            if (!long.TryParse(btnFeaturedRegister.CommandArgument, out long eventId)) return;

            TryRegisterEvent(eventId, out string message);
            lblPageMessage.Text = message;
            LoadAllData();
        }

        protected void rptHotEvents_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (!string.Equals(e.CommandName, "Register", StringComparison.OrdinalIgnoreCase)) return;
            if (!long.TryParse(Convert.ToString(e.CommandArgument), out long eventId)) return;

            TryRegisterEvent(eventId, out string message);
            lblPageMessage.Text = message;
            LoadAllData();
        }

        protected void rptHotEvents_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            ToggleRegisterButtons(e, "btnRegisterHot", "btnRegisteredHot");
        }

        protected void rptUpcomingEvents_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (!string.Equals(e.CommandName, "Register", StringComparison.OrdinalIgnoreCase)) return;
            if (!long.TryParse(Convert.ToString(e.CommandArgument), out long eventId)) return;

            TryRegisterEvent(eventId, out string message);
            lblPageMessage.Text = message;
            LoadAllData();
        }

        protected void rptUpcomingEvents_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            ToggleRegisterButtons(e, "btnRegisterUp", "btnRegisteredUp");
        }

        /// <summary>Hiển thị nút Đăng ký / Đã đăng ký theo trạng thái row.</summary>
        private static void ToggleRegisterButtons(RepeaterItemEventArgs e,
                                                  string registerBtnId,
                                                  string registeredBtnId)
        {
            if (e.Item.ItemType != ListItemType.Item &&
                e.Item.ItemType != ListItemType.AlternatingItem) return;

            if (!(e.Item.DataItem is DataRowView row)) return;

            bool isRegistered = Convert.ToInt32(row["is_registered"]) == 1;

            var btnRegister = (LinkButton)e.Item.FindControl(registerBtnId);
            var btnRegistered = (LinkButton)e.Item.FindControl(registeredBtnId);

            if (btnRegister != null) btnRegister.Visible = !isRegistered;
            if (btnRegistered != null) btnRegistered.Visible = isRegistered;
        }

        // ══════════════════════════════════════════════════════════════
        // REGISTRATION LOGIC — Đăng ký 1 sự kiện (transactional)
        // ══════════════════════════════════════════════════════════════
        private bool TryRegisterEvent(long eventId, out string message)
        {
            message = string.Empty;
            long userId = CurrentUserId;

            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    using (SqlTransaction tx = conn.BeginTransaction())
                    {
                        // ── 1) Có bản ghi đăng ký từ trước chưa? ──
                        long? existingId = null;
                        string existingStatus = string.Empty;

                        using (SqlCommand cmd = new SqlCommand(@"
                            SELECT TOP 1 id, status
                            FROM dbo.event_registrations WITH (UPDLOCK, HOLDLOCK)
                            WHERE event_id = @EventId AND user_id = @UserId;", conn, tx))
                        {
                            cmd.Parameters.Add("@EventId", SqlDbType.BigInt).Value = eventId;
                            cmd.Parameters.Add("@UserId", SqlDbType.BigInt).Value = userId;

                            using (SqlDataReader r = cmd.ExecuteReader())
                            {
                                if (r.Read())
                                {
                                    existingId = Convert.ToInt64(r["id"]);
                                    existingStatus = SafeString(r["status"], "").ToLowerInvariant();
                                }
                            }
                        }

                        if (existingId.HasValue && IsActiveRegistrationStatus(existingStatus))
                        {
                            tx.Rollback();
                            message = "Bạn đã đăng ký sự kiện này rồi.";
                            return false;
                        }

                        // ── 2) Lấy info sự kiện ──
                        long capacity;
                        bool requiresApproval, allowWaitlist;
                        string status;

                        using (SqlCommand cmd = new SqlCommand(@"
                            SELECT capacity, requires_approval, allow_waitlist, status
                            FROM dbo.events
                            WHERE id = @EventId AND deleted_at IS NULL;", conn, tx))
                        {
                            cmd.Parameters.Add("@EventId", SqlDbType.BigInt).Value = eventId;
                            using (SqlDataReader r = cmd.ExecuteReader())
                            {
                                if (!r.Read())
                                {
                                    tx.Rollback();
                                    message = "Sự kiện không tồn tại.";
                                    return false;
                                }

                                capacity = Convert.ToInt64(r["capacity"]);
                                requiresApproval = Convert.ToBoolean(r["requires_approval"]);
                                allowWaitlist = Convert.ToBoolean(r["allow_waitlist"]);
                                status = SafeString(r["status"], "draft");

                                if (!string.Equals(status, "open", StringComparison.OrdinalIgnoreCase))
                                {
                                    tx.Rollback();
                                    message = "Sự kiện hiện không mở đăng ký.";
                                    return false;
                                }
                            }
                        }

                        // ── 3) Đếm số người đã đăng ký ──
                        long registered;
                        using (SqlCommand cmd = new SqlCommand(@"
                            SELECT COUNT(*)
                            FROM dbo.event_registrations
                            WHERE event_id = @EventId
                              AND status IN (N'pending', N'approved', N'waitlist');", conn, tx))
                        {
                            cmd.Parameters.Add("@EventId", SqlDbType.BigInt).Value = eventId;
                            registered = Convert.ToInt64(cmd.ExecuteScalar());
                        }

                        // ── 4) Xác định status sẽ insert ──
                        string insertStatus;
                        if (registered >= capacity)
                        {
                            if (!allowWaitlist)
                            {
                                tx.Rollback();
                                message = "Sự kiện đã đầy.";
                                return false;
                            }
                            insertStatus = "waitlist";
                        }
                        else
                        {
                            insertStatus = requiresApproval ? "pending" : "approved";
                        }

                        string ticketCode = GenerateTicketCode(eventId, userId);

                        // ── 5) UPDATE (đã có bản ghi cũ) hoặc INSERT mới ──
                        if (existingId.HasValue)
                        {
                            using (SqlCommand cmd = new SqlCommand(@"
                                UPDATE dbo.event_registrations
                                SET
                                    status            = @Status,
                                    ticket_code       = @TicketCode,
                                    qr_payload        = NULL,
                                    registered_at     = SYSUTCDATETIME(),
                                    approved_at       = CASE WHEN @Status = N'approved' THEN SYSUTCDATETIME() ELSE NULL END,
                                    approved_by       = NULL,
                                    rejected_at       = NULL,
                                    rejected_by       = NULL,
                                    rejection_reason  = NULL,
                                    cancelled_at      = NULL,
                                    waitlist_position = CASE
                                        WHEN @Status = N'waitlist' THEN
                                            (SELECT COUNT(*) + 1
                                               FROM dbo.event_registrations
                                              WHERE event_id = @EventId
                                                AND status   = N'waitlist'
                                                AND id      <> @RegId)
                                        ELSE NULL
                                    END,
                                    source            = N'web',
                                    updated_at        = SYSUTCDATETIME()
                                WHERE id = @RegId;", conn, tx))
                            {
                                cmd.Parameters.Add("@RegId", SqlDbType.BigInt).Value = existingId.Value;
                                cmd.Parameters.Add("@EventId", SqlDbType.BigInt).Value = eventId;
                                cmd.Parameters.Add("@Status", SqlDbType.NVarChar, 15).Value = insertStatus;
                                cmd.Parameters.Add("@TicketCode", SqlDbType.NVarChar, 40).Value = ticketCode;
                                cmd.ExecuteNonQuery();
                            }
                        }
                        else
                        {
                            using (SqlCommand cmd = new SqlCommand(@"
                                INSERT INTO dbo.event_registrations
                                    (event_id, user_id, status, ticket_code, qr_payload, source)
                                VALUES
                                    (@EventId, @UserId, @Status, @TicketCode, NULL, N'web');", conn, tx))
                            {
                                cmd.Parameters.Add("@EventId", SqlDbType.BigInt).Value = eventId;
                                cmd.Parameters.Add("@UserId", SqlDbType.BigInt).Value = userId;
                                cmd.Parameters.Add("@Status", SqlDbType.NVarChar, 15).Value = insertStatus;
                                cmd.Parameters.Add("@TicketCode", SqlDbType.NVarChar, 40).Value = ticketCode;
                                cmd.ExecuteNonQuery();
                            }
                        }

                        tx.Commit();

                        message = insertStatus == "waitlist"
                            ? "Sự kiện đã đầy, bạn được thêm vào danh sách chờ."
                            : (insertStatus == "approved"
                                ? "Đăng ký thành công."
                                : "Đăng ký thành công, đang chờ phê duyệt.");

                        return true;
                    }
                }
            }
            catch (SqlException ex)
            {
                message = "Lỗi CSDL: " + ex.Message;
                return false;
            }
            catch (Exception ex)
            {
                message = "Không thể đăng ký: " + ex.Message;
                return false;
            }
        }

        // ══════════════════════════════════════════════════════════════
        // UTILITIES — Helper DB / formatting
        // ══════════════════════════════════════════════════════════════

        private void SetFeaturedProgress(int percent)
        {
            if (percent < 0) percent = 0;
            if (percent > 100) percent = 100;
            featuredProgressFill.Style["width"] = percent + "%";
        }

        private static bool IsActiveRegistrationStatus(string status)
        {
            status = (status ?? string.Empty).Trim().ToLowerInvariant();
            return status == "pending" || status == "approved" || status == "waitlist";
        }

        private static string GenerateTicketCode(long eventId, long userId)
            => $"EV{eventId}-U{userId}-{Guid.NewGuid():N}".Substring(0, 40).ToUpper();

        private DataTable ExecuteTable(string sql, params SqlParameter[] parameters)
        {
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            using (SqlDataAdapter da = new SqlDataAdapter(cmd))
            {
                if (parameters != null && parameters.Length > 0)
                    cmd.Parameters.AddRange(parameters);

                DataTable dt = new DataTable();
                da.Fill(dt);
                return dt;
            }
        }

        private static string SafeString(object value, string fallback = "")
        {
            if (value == null || value == DBNull.Value) return fallback;
            string text = Convert.ToString(value);
            return string.IsNullOrWhiteSpace(text) ? fallback : text;
        }

        // ══════════════════════════════════════════════════════════════
        // FORMAT HELPERS — gọi từ databinding <%# ... %>
        // ══════════════════════════════════════════════════════════════

        private string GetTodayLabel()
            => DateTime.Now.ToString("dddd, dd 'tháng' M 'năm' yyyy", vi).ToUpper(vi);

        private static string FormatFeaturedDate(DateTime date)
            => date.ToString("dd/MM/yyyy - HH:mm");

        public string GetHotBannerClass(int index)
        {
            int mod = index % 3;
            return mod == 0 ? "bg-1" : (mod == 1 ? "bg-2" : "bg-3");
        }

        public string GetDay(object value)
        {
            if (value == null || value == DBNull.Value) return "--";
            return Convert.ToDateTime(value).ToString("dd");
        }

        public string GetMonthShort(object value)
        {
            if (value == null || value == DBNull.Value) return "Thg";
            return "Thg " + Convert.ToDateTime(value).Month;
        }

        public string FormatHotDate(object value)
        {
            if (value == null || value == DBNull.Value) return "—";
            DateTime dt = Convert.ToDateTime(value);
            return $"{dt.ToString("dddd", vi).ToUpper(vi)}, {dt:dd/MM} — {dt:HH:mm}";
        }

        public string FormatUpcomingSchedule(object startValue, object endValue)
        {
            if (startValue == null || startValue == DBNull.Value ||
                endValue == null || endValue == DBNull.Value) return "—";

            DateTime start = Convert.ToDateTime(startValue);
            DateTime end = Convert.ToDateTime(endValue);
            return $"{start.ToString("dddd", vi).ToUpper(vi)}, {start:dd/MM} — {start:HH:mm} – {end:HH:mm}";
        }

        public string FormatLocation(object formatValue, object locationNameValue,
                                     object locationRoomValue, object addressValue)
        {
            string fmt = SafeString(formatValue, "offline").ToLowerInvariant();
            string locationName = SafeString(locationNameValue);
            string locationRoom = SafeString(locationRoomValue);
            string address = SafeString(addressValue);

            if (fmt == "online") return "Online";
            if (fmt == "hybrid")
            {
                string local = BuildPhysicalLocation(locationName, locationRoom, address);
                return string.IsNullOrWhiteSpace(local) ? "Hybrid" : local + " · Hybrid";
            }
            return BuildPhysicalLocation(locationName, locationRoom, address);
        }

        private static string BuildPhysicalLocation(string locationName, string locationRoom, string address)
        {
            string result = locationName;

            if (!string.IsNullOrWhiteSpace(locationRoom))
                result = string.IsNullOrWhiteSpace(result)
                       ? locationRoom
                       : result + ", " + locationRoom;

            if (string.IsNullOrWhiteSpace(result))
                result = address;
            else if (!string.IsNullOrWhiteSpace(address) && !result.Contains(address))
                result += " · " + address;

            return string.IsNullOrWhiteSpace(result) ? "—" : result;
        }

        public string GetCardDescription(object subtitleValue, object descriptionValue)
        {
            string subtitle = SafeString(subtitleValue);
            if (!string.IsNullOrWhiteSpace(subtitle)) return Truncate(subtitle, 120);
            return Truncate(SafeString(descriptionValue), 120);
        }

        private static string Truncate(string text, int maxLength)
        {
            if (string.IsNullOrWhiteSpace(text)) return "—";
            text = text.Trim();
            return text.Length <= maxLength ? text : text.Substring(0, maxLength - 1).TrimEnd() + "…";
        }

        public string GetProgressBarClass(object percentValue)
        {
            int.TryParse(SafeString(percentValue, "0"), out int percent);
            if (percent >= 85) return "red";
            if (percent >= 50) return "amber";
            return "green";
        }
    }
}