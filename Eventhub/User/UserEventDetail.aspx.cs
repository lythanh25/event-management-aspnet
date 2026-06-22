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
    public partial class UserEventDetail : System.Web.UI.Page
    {
        private string connStr;
        private readonly CultureInfo vi = new CultureInfo("vi-VN");

        /// <summary>ID sự kiện đang xem — lưu vào ViewState để giữ qua postback.</summary>
        private long CurrentEventId
        {
            get => ViewState["EventId"] is long v ? v : 0L;
            set => ViewState["EventId"] = value;
        }

        /// <summary>Số category_id của event hiện tại — dùng để load related events.</summary>
        private long CurrentCategoryId
        {
            get => ViewState["CategoryId"] is long v ? v : 0L;
            set => ViewState["CategoryId"] = value;
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
            if (cs == null)
                throw new ConfigurationErrorsException("Missing connection string 'EventHub'.");
            connStr = cs.ConnectionString;
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["UserId"] == null)
            {
                Response.Redirect("~/Account/Login.aspx");
                return;
            }

            if (!IsPostBack)
            {
                // Lấy id từ query string
                if (!long.TryParse(Request.QueryString["id"], out long id) || id <= 0)
                {
                    ShowNotFound();
                    return;
                }
                CurrentEventId = id;
                LoadAllData();
            }
        }

        // ──────────────────────────────────────────────────────────────
        // LOAD ALL
        // ──────────────────────────────────────────────────────────────
        private void LoadAllData()
        {
            if (CurrentEventId <= 0) { ShowNotFound(); return; }

            if (!LoadEventDetail())
            {
                ShowNotFound();
                return;
            }

            LoadAgenda();
            LoadSpeakers();
            LoadRelatedEvents();
            LoadSavedState();
        }

        private void ShowNotFound()
        {
            pnlContent.Visible = false;
            pnlNotFound.Visible = true;
        }

        // ──────────────────────────────────────────────────────────────
        // LOAD: EVENT DETAIL  (Hero + Description + Register card + Info card)
        // ──────────────────────────────────────────────────────────────
        private bool LoadEventDetail()
        {
            const string sql = @"
                SELECT TOP 1
                    e.id, e.title, e.subtitle, e.description, e.objectives,
                    e.category_id,
                    e.start_at, e.end_at,
                    e.registration_deadline,
                    e.format, e.location_name, e.location_room, e.address, e.online_url,
                    e.capacity, e.price, e.original_price, e.currency,
                    e.status, e.organizer_department_id,
                    COALESCE(c.name, N'Sự kiện')           AS category_name,
                    COALESCE(d.name, N'Chưa xác định')     AS organizer_name,
                    ISNULL(rc.registered_count, 0)         AS registered_count,
                    ISNULL(sp.speaker_count, 0)            AS speaker_count,
                    CASE WHEN EXISTS (
                        SELECT 1 FROM dbo.event_registrations x
                        WHERE x.event_id = e.id
                          AND x.user_id  = @UserId
                          AND x.status   IN (N'pending', N'approved', N'waitlist')
                    ) THEN 1 ELSE 0 END                    AS is_registered
                FROM dbo.events e
                LEFT JOIN dbo.event_categories c ON c.id = e.category_id
                LEFT JOIN dbo.departments       d ON d.id = e.organizer_department_id
                LEFT JOIN (
                    SELECT event_id, COUNT(*) AS registered_count
                    FROM dbo.event_registrations
                    WHERE status IN (N'pending', N'approved', N'waitlist')
                    GROUP BY event_id
                ) rc ON rc.event_id = e.id
                LEFT JOIN (
                    SELECT event_id, COUNT(*) AS speaker_count
                    FROM dbo.event_speakers
                    GROUP BY event_id
                ) sp ON sp.event_id = e.id
                WHERE e.id = @Id AND e.deleted_at IS NULL;";

            DataTable dt = ExecuteTable(sql,
                new SqlParameter("@Id", SqlDbType.BigInt) { Value = CurrentEventId },
                new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });

            if (dt.Rows.Count == 0) return false;

            DataRow r = dt.Rows[0];

            // ── HERO ──
            string title = SafeString(r["title"], "Chi tiết sự kiện");
            string subtitle = SafeString(r["subtitle"]);
            string categoryName = SafeString(r["category_name"]);
            string organizerName = SafeString(r["organizer_name"]);
            string status = SafeString(r["status"], "draft");
            string fmt = SafeString(r["format"], "offline");

            DateTime startAt = Convert.ToDateTime(r["start_at"]);
            DateTime endAt = Convert.ToDateTime(r["end_at"]);
            int capacity = Convert.ToInt32(r["capacity"]);
            int registered = Convert.ToInt32(r["registered_count"]);
            int speakerCount = Convert.ToInt32(r["speaker_count"]);
            bool isRegistered = Convert.ToInt32(r["is_registered"]) == 1;

            CurrentCategoryId = Convert.ToInt64(r["category_id"]);

            // Title (browser tab + breadcrumb)
            litPageTitle.Text = Server.HtmlEncode(title);
            litCrumbTitle.Text = Server.HtmlEncode(title);

            // Badges
            ApplyStatusBadge(status, registered, capacity);

            if (!string.IsNullOrWhiteSpace(categoryName))
            {
                pnlBadgeCategory.Visible = true;
                litBadgeCategory.Text = Server.HtmlEncode(categoryName);
            }

            pnlBadgeFormat.Visible = true;
            litBadgeFormat.Text = FormatLabel(fmt);

            // Title + subtitle
            litTitle.Text = Server.HtmlEncode(title);
            if (!string.IsNullOrWhiteSpace(subtitle))
            {
                pnlSubtitle.Visible = true;
                litSubtitle.Text = Server.HtmlEncode(subtitle);
            }

            // Meta
            litMetaDate.Text = FormatHeroDate(startAt);
            litMetaTime.Text = FormatHeroTime(startAt, endAt);
            litMetaLocation.Text = Server.HtmlEncode(FormatLocation(fmt,
                SafeString(r["location_name"]),
                SafeString(r["location_room"]),
                SafeString(r["address"])));

            // Organizer
            litOrganizer.Text = Server.HtmlEncode(organizerName);

            // Stats
            int remaining = Math.Max(0, capacity - registered);
            int daysLeft = 0;
            if (r["registration_deadline"] != DBNull.Value)
            {
                DateTime dl = Convert.ToDateTime(r["registration_deadline"]);
                daysLeft = Math.Max(0, (int)Math.Ceiling((dl - DateTime.Now).TotalDays));
            }
            else
            {
                daysLeft = Math.Max(0, (int)Math.Ceiling((startAt - DateTime.Now).TotalDays));
            }
            litStatRegistered.Text = registered.ToString();
            litStatCapacity.Text = capacity.ToString();
            litStatRemaining.Text = remaining.ToString();
            litStatSpeakers.Text = speakerCount.ToString();
            litStatDaysLeft.Text = daysLeft.ToString();

            // ── DESCRIPTION ──
            litDescription.Text = BuildDescriptionHtml(SafeString(r["description"]));

            // Objectives (JSON string array)
            var objectives = ParseObjectives(SafeString(r["objectives"]));
            if (objectives.Count > 0)
            {
                pnlObjectives.Visible = true;
                rptObjectives.DataSource = objectives;
                rptObjectives.DataBind();
            }

            // ── REGISTER CARD ──
            litRegTitle.Text = Server.HtmlEncode(title);
            litRegPrice.Text = FormatPrice(r["price"], r["original_price"], SafeString(r["currency"], "VND"));
            litRegProgressText.Text = $"{registered} / {capacity}";
            SetRegProgress(capacity == 0 ? 0 : (int)Math.Min(100, Math.Round(100.0 * registered / capacity)));

            ApplyRegPillAndWarning(status, registered, capacity, daysLeft, r["registration_deadline"]);
            ApplyRegisterButton(status, registered, capacity, isRegistered);

            // ── INFO CARD ──
            litInfoDate.Text = startAt.ToString("dd/MM/yyyy");
            litInfoDateSub.Text = " " + startAt.ToString("dddd", vi).Substring(0, 1).ToUpper(vi)
                                  + startAt.ToString("dddd", vi).Substring(1)
                                  + $", {startAt:HH:mm} – {endAt:HH:mm}";

            string physLoc = BuildPhysicalLocation(SafeString(r["location_name"]),
                                                   SafeString(r["location_room"]),
                                                   SafeString(r["address"]));
            if (fmt == "online")
            {
                litInfoLocation.Text = "Sự kiện trực tuyến";
                litInfoLocationSub.Text = string.IsNullOrWhiteSpace(SafeString(r["online_url"]))
                    ? " Link sẽ gửi qua email"
                    : " Tham gia qua link đăng ký";
            }
            else
            {
                litInfoLocation.Text = Server.HtmlEncode(string.IsNullOrWhiteSpace(physLoc) ? "—" : physLoc);
                litInfoLocationSub.Text = fmt == "hybrid" ? " Hình thức: Hybrid" : "";
            }

            litInfoOrg.Text = Server.HtmlEncode(organizerName);

            if (r["registration_deadline"] != DBNull.Value)
            {
                DateTime dl = Convert.ToDateTime(r["registration_deadline"]);
                litInfoDeadline.Text = " " + dl.ToString("dd/MM/yyyy HH:mm");
            }
            else
            {
                litInfoDeadline.Text = " Cho đến khi sự kiện bắt đầu";
            }

            return true;
        }

        // ──────────────────────────────────────────────────────────────
        // LOAD: AGENDA
        // ──────────────────────────────────────────────────────────────
        private void LoadAgenda()
        {
            const string sql = @"
                SELECT id, start_time, end_time, title, description, item_type, tag_label
                FROM dbo.event_agenda_items
                WHERE event_id = @EventId
                ORDER BY start_time ASC, sort_order ASC;";

            DataTable dt = ExecuteTable(sql,
                new SqlParameter("@EventId", SqlDbType.BigInt) { Value = CurrentEventId });

            rptAgenda.DataSource = dt;
            rptAgenda.DataBind();
            pnlEmptyAgenda.Visible = dt.Rows.Count == 0;
        }

        // ──────────────────────────────────────────────────────────────
        // LOAD: SPEAKERS
        // ──────────────────────────────────────────────────────────────
        private void LoadSpeakers()
        {
            const string sql = @"
                SELECT id, full_name, title, bio, avatar_url, sort_order
                FROM dbo.event_speakers
                WHERE event_id = @EventId
                ORDER BY is_featured DESC, sort_order ASC, id ASC;";

            DataTable dt = ExecuteTable(sql,
                new SqlParameter("@EventId", SqlDbType.BigInt) { Value = CurrentEventId });

            if (dt.Rows.Count > 0)
            {
                pnlSpeakers.Visible = true;
                rptSpeakers.DataSource = dt;
                rptSpeakers.DataBind();
            }
        }

        // ──────────────────────────────────────────────────────────────
        // LOAD: RELATED EVENTS  (top 3 cùng category, khác sự kiện hiện tại)
        // ──────────────────────────────────────────────────────────────
        private void LoadRelatedEvents()
        {
            if (CurrentCategoryId <= 0) return;

            const string sql = @"
                SELECT TOP 3 e.id, e.title, e.start_at
                FROM dbo.events e
                WHERE e.category_id = @CategoryId
                  AND e.id         <> @EventId
                  AND e.deleted_at IS NULL
                  AND e.status     <> N'cancelled'
                ORDER BY
                    CASE WHEN e.start_at >= GETDATE() THEN 0 ELSE 1 END,
                    e.start_at ASC;";

            DataTable dt = ExecuteTable(sql,
                new SqlParameter("@CategoryId", SqlDbType.BigInt) { Value = CurrentCategoryId },
                new SqlParameter("@EventId", SqlDbType.BigInt) { Value = CurrentEventId });

            if (dt.Rows.Count > 0)
            {
                pnlRelated.Visible = true;
                rptRelated.DataSource = dt;
                rptRelated.DataBind();
            }
        }

        // ──────────────────────────────────────────────────────────────
        // LOAD: SAVED STATE  (đã bookmark / lưu)
        // ──────────────────────────────────────────────────────────────
        private void LoadSavedState()
        {
            const string sql = @"
                SELECT COUNT(*) FROM dbo.saved_events
                WHERE user_id = @UserId AND event_id = @EventId;";

            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.Add("@UserId", SqlDbType.BigInt).Value = CurrentUserId;
                cmd.Parameters.Add("@EventId", SqlDbType.BigInt).Value = CurrentEventId;
                conn.Open();
                int n = Convert.ToInt32(cmd.ExecuteScalar());
                litSaveText.Text = n > 0 ? "Đã lưu" : "Lưu lại";
            }
        }

        // ══════════════════════════════════════════════════════════════
        // EVENT HANDLERS
        // ══════════════════════════════════════════════════════════════

        protected void btnRegister_Click(object sender, EventArgs e)
        {
            if (CurrentEventId <= 0) return;

            TryRegisterEvent(CurrentEventId, out string message, out bool ok);

            ShowAlert(message, ok ? "success" : "error");
            LoadAllData();
        }

        protected void btnSave_Click(object sender, EventArgs e)
        {
            if (CurrentEventId <= 0) return;
            long userId = CurrentUserId;

            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();

                    // Toggle: nếu đã có thì xoá, chưa có thì thêm
                    int existing;
                    using (SqlCommand cmd = new SqlCommand(@"
                        SELECT COUNT(*) FROM dbo.saved_events
                        WHERE user_id = @UserId AND event_id = @EventId;", conn))
                    {
                        cmd.Parameters.Add("@UserId", SqlDbType.BigInt).Value = userId;
                        cmd.Parameters.Add("@EventId", SqlDbType.BigInt).Value = CurrentEventId;
                        existing = Convert.ToInt32(cmd.ExecuteScalar());
                    }

                    if (existing > 0)
                    {
                        using (SqlCommand cmd = new SqlCommand(@"
                            DELETE FROM dbo.saved_events
                            WHERE user_id = @UserId AND event_id = @EventId;", conn))
                        {
                            cmd.Parameters.Add("@UserId", SqlDbType.BigInt).Value = userId;
                            cmd.Parameters.Add("@EventId", SqlDbType.BigInt).Value = CurrentEventId;
                            cmd.ExecuteNonQuery();
                        }
                        litSaveText.Text = "Lưu lại";
                        ShowAlert("Đã bỏ lưu sự kiện.", "info");
                    }
                    else
                    {
                        using (SqlCommand cmd = new SqlCommand(@"
                            INSERT INTO dbo.saved_events (user_id, event_id)
                            VALUES (@UserId, @EventId);", conn))
                        {
                            cmd.Parameters.Add("@UserId", SqlDbType.BigInt).Value = userId;
                            cmd.Parameters.Add("@EventId", SqlDbType.BigInt).Value = CurrentEventId;
                            cmd.ExecuteNonQuery();
                        }
                        litSaveText.Text = "Đã lưu";
                        ShowAlert("Đã lưu sự kiện vào danh sách của bạn.", "success");
                    }
                }
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi: " + ex.Message, "error");
            }
        }

        // ══════════════════════════════════════════════════════════════
        // REGISTRATION LOGIC (transactional, đồng nhất với UserHome.aspx.cs)
        // ══════════════════════════════════════════════════════════════
        private void TryRegisterEvent(long eventId, out string message, out bool ok)
        {
            message = string.Empty;
            ok = false;
            long userId = CurrentUserId;

            try
            {
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    using (SqlTransaction tx = conn.BeginTransaction())
                    {
                        // 1) Có bản ghi đăng ký từ trước?
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
                            return;
                        }

                        // 2) Lấy info event
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
                                    return;
                                }
                                capacity = Convert.ToInt64(r["capacity"]);
                                requiresApproval = Convert.ToBoolean(r["requires_approval"]);
                                allowWaitlist = Convert.ToBoolean(r["allow_waitlist"]);
                                status = SafeString(r["status"], "draft");

                                if (!string.Equals(status, "open", StringComparison.OrdinalIgnoreCase))
                                {
                                    tx.Rollback();
                                    message = "Sự kiện hiện không mở đăng ký.";
                                    return;
                                }
                            }
                        }

                        // 3) Đếm registered
                        long registered;
                        using (SqlCommand cmd = new SqlCommand(@"
                            SELECT COUNT(*) FROM dbo.event_registrations
                            WHERE event_id = @EventId
                              AND status IN (N'pending', N'approved', N'waitlist');", conn, tx))
                        {
                            cmd.Parameters.Add("@EventId", SqlDbType.BigInt).Value = eventId;
                            registered = Convert.ToInt64(cmd.ExecuteScalar());
                        }

                        // 4) Status sẽ insert
                        string insertStatus;
                        if (registered >= capacity)
                        {
                            if (!allowWaitlist)
                            {
                                tx.Rollback();
                                message = "Sự kiện đã đầy.";
                                return;
                            }
                            insertStatus = "waitlist";
                        }
                        else
                        {
                            insertStatus = requiresApproval ? "pending" : "approved";
                        }

                        string ticketCode = GenerateTicketCode(eventId, userId);

                        // 5) UPDATE / INSERT
                        if (existingId.HasValue)
                        {
                            using (SqlCommand cmd = new SqlCommand(@"
                                UPDATE dbo.event_registrations
                                SET status            = @Status,
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
                                ? "✅ Đăng ký thành công!"
                                : "✅ Đăng ký thành công, đơn đang chờ phê duyệt.");
                        ok = true;
                    }
                }
            }
            catch (SqlException ex) { message = "Lỗi CSDL: " + ex.Message; }
            catch (Exception ex) { message = "Không thể đăng ký: " + ex.Message; }
        }

        // ══════════════════════════════════════════════════════════════
        // UI HELPERS
        // ══════════════════════════════════════════════════════════════

        private void ApplyStatusBadge(string status, int registered, int capacity)
        {
            string text; string cssClass;
            status = (status ?? "").ToLowerInvariant();

            if (status == "cancelled") { text = "Đã huỷ"; cssClass = "h-badge lim"; }
            else if (status == "ended") { text = "Đã kết thúc"; cssClass = "h-badge lim"; }
            else if (status == "closed") { text = "Đã đóng đăng ký"; cssClass = "h-badge lim"; }
            else if (status == "draft") { text = "Bản nháp"; cssClass = "h-badge lim"; }
            else /* open */
            {
                if (registered >= capacity) { text = "Đã đầy"; cssClass = "h-badge tag"; }
                else if (capacity - registered <= 10) { text = "Sắp hết chỗ"; cssClass = "h-badge tag"; }
                else { text = "Đang mở đăng ký"; cssClass = "h-badge open"; }
            }

            pnlBadgeStatus.CssClass = cssClass;
            litBadgeStatus.Text = text;
        }

        private void ApplyRegPillAndWarning(string status, int registered, int capacity,
                                            int daysLeft, object deadlineObj)
        {
            int remaining = Math.Max(0, capacity - registered);
            status = (status ?? "").ToLowerInvariant();

            if (status == "open" && registered < capacity)
            {
                litRegPill.Text = "ĐANG MỞ ĐĂNG KÝ";
            }
            else if (status == "open" && registered >= capacity)
            {
                litRegPill.Text = "ĐÃ ĐẦY · WAITLIST";
            }
            else
            {
                litRegPill.Text = status.ToUpper();
            }

            // Warning: chỉ hiện khi gần hết chỗ hoặc gần hết hạn
            bool showWarn = false;
            string warn = "";

            if (status == "open" && remaining > 0 && remaining <= 15)
            {
                warn = $"Còn <b>{remaining} chỗ</b>";
                showWarn = true;
            }

            if (deadlineObj != DBNull.Value && deadlineObj != null && daysLeft <= 7 && daysLeft >= 0)
            {
                DateTime dl = Convert.ToDateTime(deadlineObj);
                string sep = showWarn ? " · " : "";
                warn += $"{sep}Hạn đăng ký: <b>{dl:dd/MM/yyyy}</b> (còn {daysLeft} ngày)";
                showWarn = true;
            }

            pnlRegWarning.Visible = showWarn;
            litRegWarning.Text = warn;
        }

        private void ApplyRegisterButton(string status, int registered, int capacity, bool isRegistered)
        {
            status = (status ?? "").ToLowerInvariant();

            if (isRegistered)
            {
                btnRegister.Text = "✓ Đã đăng ký";
                btnRegister.Enabled = false;
                btnRegister.CssClass = "reg-cta registered";
                return;
            }

            if (status != "open")
            {
                btnRegister.Text = "Không mở đăng ký";
                btnRegister.Enabled = false;
                btnRegister.CssClass = "reg-cta disabled";
                return;
            }

            if (registered >= capacity)
            {
                btnRegister.Text = "Đăng ký vào danh sách chờ";
                btnRegister.Enabled = true;
                btnRegister.CssClass = "reg-cta";
                return;
            }

            btnRegister.Text = "Đăng ký tham gia";
            btnRegister.Enabled = true;
            btnRegister.CssClass = "reg-cta";
        }

        private void SetRegProgress(int percent)
        {
            if (percent < 0) percent = 0;
            if (percent > 100) percent = 100;
            regProgressFill.Style["width"] = percent + "%";
        }

        private void ShowAlert(string message, string kind = "info")
        {
            pnlAlert.Visible = true;
            pnlAlert.CssClass = "detail-alert " + kind;
            litAlert.Text = Server.HtmlEncode(message);
        }

        // ══════════════════════════════════════════════════════════════
        // UTILITIES — DB / parsing
        // ══════════════════════════════════════════════════════════════

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

        private static bool IsActiveRegistrationStatus(string status)
        {
            status = (status ?? "").Trim().ToLowerInvariant();
            return status == "pending" || status == "approved" || status == "waitlist";
        }

        private static string GenerateTicketCode(long eventId, long userId)
            => $"EV{eventId}-U{userId}-{Guid.NewGuid():N}".Substring(0, 40).ToUpper();

        /// <summary>
        /// Parse cột objectives (JSON dạng ["mục 1","mục 2",...]) thành List string.
        /// Nếu fail, trả về list rỗng.
        /// </summary>
        private List<string> ParseObjectives(string json)
        {
            var list = new List<string>();
            if (string.IsNullOrWhiteSpace(json)) return list;

            // Trick gọn để tránh add JSON.NET: dùng JavaScriptSerializer (BCL)
            try
            {
                var ser = new System.Web.Script.Serialization.JavaScriptSerializer();
                var arr = ser.Deserialize<string[]>(json);
                if (arr != null)
                {
                    foreach (var s in arr)
                        if (!string.IsNullOrWhiteSpace(s)) list.Add(s);
                }
            }
            catch { /* JSON xấu thì bỏ qua */ }

            return list;
        }

        /// <summary>Render description thành các <p> đơn giản (mỗi đoạn rỗng tách <p>).</summary>
        private string BuildDescriptionHtml(string raw)
        {
            if (string.IsNullOrWhiteSpace(raw)) return "<p>Chưa có mô tả.</p>";

            var paragraphs = raw.Replace("\r\n", "\n")
                                .Split(new[] { "\n\n" }, StringSplitOptions.RemoveEmptyEntries);

            var sb = new System.Text.StringBuilder();
            foreach (var p in paragraphs)
            {
                string trim = p.Trim();
                if (trim.Length == 0) continue;
                sb.Append("<p>").Append(Server.HtmlEncode(trim).Replace("\n", "<br />")).Append("</p>");
            }
            return sb.Length == 0 ? "<p>Chưa có mô tả.</p>" : sb.ToString();
        }

        // ══════════════════════════════════════════════════════════════
        // PUBLIC HELPERS — dùng trong data-binding <%# ... %>
        // ══════════════════════════════════════════════════════════════

        public string SafeStr(object value)
            => value == null || value == DBNull.Value ? string.Empty : Convert.ToString(value);

        public string FormatAgendaTime(object value)
        {
            if (value == null || value == DBNull.Value) return "--:--";
            return Convert.ToDateTime(value).ToString("HH:mm");
        }

        public string FormatRelatedDate(object value)
        {
            if (value == null || value == DBNull.Value) return "—";
            DateTime dt = Convert.ToDateTime(value);
            return dt.ToString("dd/MM/yyyy · HH:mm");
        }

        public string GetAvatarClass(int index)
        {
            int mod = index % 3;
            return mod == 0 ? "av-1" : (mod == 1 ? "av-2" : "av-3");
        }

        public string GetRelatedThumbClass(int index)
        {
            int mod = index % 3;
            return mod == 0 ? "bg-a" : (mod == 1 ? "bg-b" : "bg-c");
        }

        public string GetInitial(object fullName)
        {
            string s = SafeStr(fullName);
            if (string.IsNullOrWhiteSpace(s)) return "?";
            var parts = s.Trim().Split(' ');
            return parts[parts.Length - 1].Substring(0, 1).ToUpper();
        }

        public string TruncateText(string text, int max)
        {
            if (string.IsNullOrWhiteSpace(text)) return string.Empty;
            text = text.Trim();
            return text.Length <= max ? text : text.Substring(0, max - 1).TrimEnd() + "…";
        }

        // ══════════════════════════════════════════════════════════════
        // FORMAT HELPERS — date / location / format
        // ══════════════════════════════════════════════════════════════

        private string FormatHeroDate(DateTime d)
        {
            string day = d.ToString("dddd", vi);
            day = char.ToUpper(day[0]) + day.Substring(1);
            return $"{day}, <strong>{d:dd} tháng {d.Month} năm {d.Year}</strong>";
        }

        private static string FormatHeroTime(DateTime start, DateTime end)
        {
            int hours = (int)Math.Round((end - start).TotalHours);
            string totalLabel = hours > 0 ? $" ({hours} tiếng)" : "";
            return $"<strong>{start:HH:mm} — {end:HH:mm}</strong>{totalLabel}";
        }

        private static string FormatLabel(string fmt)
        {
            switch ((fmt ?? "").ToLowerInvariant())
            {
                case "online": return "Online";
                case "hybrid": return "Hybrid";
                default: return "Offline";
            }
        }

        private static string FormatLocation(string fmt, string locationName, string locationRoom, string address)
        {
            fmt = (fmt ?? "offline").ToLowerInvariant();
            if (fmt == "online") return "Online";

            string local = BuildPhysicalLocation(locationName, locationRoom, address);
            if (fmt == "hybrid")
                return string.IsNullOrWhiteSpace(local) ? "Hybrid" : local + " · Hybrid";
            return string.IsNullOrWhiteSpace(local) ? "—" : local;
        }

        private static string BuildPhysicalLocation(string locationName, string locationRoom, string address)
        {
            string result = locationName ?? string.Empty;
            if (!string.IsNullOrWhiteSpace(locationRoom))
                result = string.IsNullOrWhiteSpace(result) ? locationRoom : result + ", " + locationRoom;

            if (string.IsNullOrWhiteSpace(result))
                result = address ?? string.Empty;
            else if (!string.IsNullOrWhiteSpace(address) && !result.Contains(address))
                result += " · " + address;

            return result;
        }

        private string FormatPrice(object price, object originalPrice, string currency)
        {
            decimal p = (price == null || price == DBNull.Value) ? 0m : Convert.ToDecimal(price);
            if (p <= 0m) return "Miễn phí";

            string main = string.Equals(currency, "VND", StringComparison.OrdinalIgnoreCase)
                ? $"{p:N0} ₫"
                : $"{p:N0} {currency}";

            if (originalPrice != null && originalPrice != DBNull.Value)
            {
                decimal op = Convert.ToDecimal(originalPrice);
                if (op > p)
                {
                    string strike = string.Equals(currency, "VND", StringComparison.OrdinalIgnoreCase)
                        ? $"{op:N0} ₫" : $"{op:N0} {currency}";
                    return $"{main} <small>{strike}</small>";
                }
            }
            return main;
        }
    }
}