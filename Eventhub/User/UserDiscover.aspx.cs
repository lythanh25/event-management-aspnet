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
    public partial class UserDiscover : System.Web.UI.Page
    {
        private const int PageSize = 12;
        private string connStr;
        private readonly CultureInfo vi = new CultureInfo("vi-VN");

        // ── State (QS lần đầu, HiddenField khi postback) ──
        protected string CurrentSearch
        {
            get => hfFilter.Value.StartsWith("__") ? hfFilter.Value.Substring(2) : (ViewState["Search"] as string ?? string.Empty);
            set => ViewState["Search"] = value;
        }
        protected string CurrentCategory
        {
            get => hfCategory.Value ?? string.Empty;
            set { if (hfCategory != null) hfCategory.Value = value; }
        }
        protected string CurrentFilter
        {
            get => hfFilter.Value ?? "ALL";
            set { if (hfFilter != null) hfFilter.Value = value; }
        }
        protected string CurrentSort
        {
            get => ViewState["Sort"] as string ?? "START_ASC";
            set => ViewState["Sort"] = value;
        }
        protected int CurrentPage
        {
            get => hfPage.Value != null && int.TryParse(hfPage.Value, out int p) ? p : 1;
            set { if (hfPage != null) hfPage.Value = value.ToString(); }
        }

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
            if (cs == null) throw new ConfigurationErrorsException("Missing connection string 'EventHub'.");
            connStr = cs.ConnectionString;
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Session["UserId"] == null) { Response.Redirect("~/Account/Login.aspx"); return; }

            if (!IsPostBack)
            {
                // Đọc state từ QueryString khi GET (click link filter/category)
                CurrentFilter = Request.QueryString["filter"] ?? "ALL";
                CurrentCategory = Request.QueryString["cat"] ?? string.Empty;
                CurrentSort = Request.QueryString["sort"] ?? "START_ASC";
                int.TryParse(Request.QueryString["page"] ?? "1", out int pg);
                CurrentPage = pg > 0 ? pg : 1;

                string qs = Request.QueryString["q"] ?? string.Empty;
                ViewState["Search"] = qs;

                if (txtSearch != null) txtSearch.Text = qs;
                if (ddlSort != null) ddlSort.SelectedValue = CurrentSort;
            }
            else
            {
                // Khi postback (sort dropdown / btnSearch / load more), đọc từ HiddenField
                if (ddlSort != null) CurrentSort = ddlSort.SelectedValue;
            }

            LoadAllData();
        }

        private void LoadAllData()
        {
            LoadStats();
            LoadCategories();
            LoadFeaturedEvent();
            LoadEvents();
            BuildFilterLinks();
            BuildActiveFilterTags();
        }

        // ── STATS ──
        private void LoadStats()
        {
            const string sql = @"
                SELECT
                    (SELECT COUNT(*) FROM dbo.events WHERE deleted_at IS NULL AND status <> N'cancelled') AS TotalEvents,
                    (SELECT COUNT(*) FROM dbo.events WHERE deleted_at IS NULL AND status = N'open' AND start_at >= GETDATE()) AS OpenEvents,
                    (SELECT COUNT(*) FROM dbo.events WHERE deleted_at IS NULL AND status <> N'cancelled'
                      AND start_at >= CAST(GETDATE() AS DATE) AND start_at < DATEADD(DAY,7,CAST(GETDATE() AS DATE))) AS ThisWeek,
                    (SELECT COUNT(*) FROM dbo.event_registrations WHERE user_id=@UserId AND status IN (N'pending',N'approved',N'waitlist')) AS MyReg;";

            DataTable dt = Exec(sql, new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });
            if (dt.Rows.Count == 0) return;
            DataRow r = dt.Rows[0];
            litStatTotal.Text = Str(r["TotalEvents"], "0");
            litStatOpen.Text = Str(r["OpenEvents"], "0");
            litStatThisWeek.Text = Str(r["ThisWeek"], "0");
            litStatRegisteredByMe.Text = Str(r["MyReg"], "0");
            litCountAll.Text = Str(r["TotalEvents"], "0");
            litCatAllCount.Text = Str(r["TotalEvents"], "0");
        }

        // ── CATEGORIES (render bằng Literal HTML) ──
        private void LoadCategories()
        {
            const string sql = @"
                SELECT c.id, c.code, c.name, ISNULL(ec.cnt,0) AS event_count
                FROM dbo.event_categories c
                LEFT JOIN (SELECT category_id, COUNT(*) AS cnt FROM dbo.events
                           WHERE deleted_at IS NULL AND status <> N'cancelled' GROUP BY category_id) ec
                       ON ec.category_id = c.id
                WHERE c.is_active = 1 ORDER BY c.sort_order, c.name;";

            DataTable dt = Exec(sql);
            string pageUrl = ResolveUrl("~/User/UserDiscover.aspx");
            string sort = HttpUtility.UrlEncode(CurrentSort);
            string search = HttpUtility.UrlEncode(ViewState["Search"] as string ?? "");

            // Cập nhật link "Tất cả"
            bool allActive = string.IsNullOrEmpty(CurrentCategory);
            lnkCatAll.Attributes["class"] = allActive ? "cat-card active" : "cat-card";
            lnkCatAll.HRef = $"{pageUrl}?filter={HttpUtility.UrlEncode(CurrentFilter)}&cat=&sort={sort}&q={search}";

            // Render các category card bằng StringBuilder (tránh SVG-in-LinkButton hoàn toàn)
            var sb = new StringBuilder();
            foreach (DataRow row in dt.Rows)
            {
                string name = HttpUtility.HtmlEncode(Str(row["name"]));
                string code = Str(row["code"]);
                int count = Convert.ToInt32(row["event_count"]);
                bool active = string.Equals(CurrentCategory, Str(row["name"]), StringComparison.OrdinalIgnoreCase);
                string cls = active ? "cat-card active" : "cat-card";
                string href = $"{pageUrl}?filter={HttpUtility.UrlEncode(CurrentFilter)}&cat={HttpUtility.UrlEncode(Str(row["name"]))}&sort={sort}&q={search}";

                sb.AppendLine($@"<a class=""{cls}"" href=""{href}"">
                    <span class=""cat-icon"">{GetCategoryIconHtml(code)}</span>
                    <span class=""cat-name"">{name}</span>
                    <span class=""cat-count"">{count} sự kiện</span>
                </a>");
            }
            litCategories.Text = sb.ToString();
        }

        // ── FEATURED EVENT ──
        private void LoadFeaturedEvent()
        {
            const string sql = @"
                SELECT TOP 1 e.id, e.title, e.start_at, e.capacity, e.format,
                       e.location_name, e.location_room, e.address,
                       ISNULL(rc.registered_count,0) AS registered_count,
                       CASE WHEN ur.event_id IS NULL THEN 0 ELSE 1 END AS is_registered
                FROM dbo.events e
                LEFT JOIN (SELECT event_id, COUNT(*) AS registered_count FROM dbo.event_registrations
                           WHERE status IN (N'pending',N'approved',N'waitlist') GROUP BY event_id) rc ON rc.event_id=e.id
                LEFT JOIN (SELECT event_id FROM dbo.event_registrations WHERE user_id=@UserId
                           AND status IN (N'pending',N'approved',N'waitlist') GROUP BY event_id) ur ON ur.event_id=e.id
                WHERE e.deleted_at IS NULL AND e.status=N'open' AND e.start_at>=GETDATE()
                ORDER BY ISNULL(rc.registered_count,0) DESC, e.start_at ASC;";

            DataTable dt = Exec(sql, new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId });
            if (dt.Rows.Count == 0) { pnlFeatured.Visible = false; return; }

            pnlFeatured.Visible = true;
            DataRow r = dt.Rows[0];
            long eventId = Convert.ToInt64(r["id"]);
            DateTime start = Convert.ToDateTime(r["start_at"]);
            int cap = Convert.ToInt32(r["capacity"]);
            int reg = Convert.ToInt32(r["registered_count"]);
            int rem = Math.Max(0, cap - reg);
            bool isReg = Convert.ToInt32(r["is_registered"]) == 1;

            litFePill.Text = rem <= 0 ? "ĐÃ ĐẦY" : rem <= 10 ? "SẮP HẾT CHỖ" : "SỰ KIỆN ĐẶC BIỆT";
            litFeTitle.Text = HttpUtility.HtmlEncode(Str(r["title"]));
            litFeDate.Text = " " + FormatFeaturedDate(start);
            litFeLocation.Text = " " + HttpUtility.HtmlEncode(FormatLocation(r["format"], r["location_name"], r["location_room"], r["address"]));
            litFeCapacity.Text = $" {cap} chỗ tham gia";
            litFeCountdown.Text = Math.Max(0, (int)Math.Ceiling((start - DateTime.Now).TotalDays)).ToString();
            litFeSpots.Text = rem > 0 ? $"Còn <b>{rem}</b> chỗ trống" : "Đã hết chỗ";

            btnFeRegister.CommandArgument = eventId.ToString();
            if (isReg)
            {
                litFeBtnText.Text = "&#10003; Đã đăng ký";
                btnFeRegister.Enabled = false;
                btnFeRegister.CssClass = "fe-cta registered";
            }
            else
            {
                litFeBtnText.Text = "Đăng ký ngay";
                btnFeRegister.Enabled = true;
                btnFeRegister.CssClass = "fe-cta";
            }
        }

        // ── EVENTS GRID ──
        private void LoadEvents()
        {
            string orderBy;
            switch ((CurrentSort ?? "START_ASC").ToUpperInvariant())
            {
                case "START_DESC": orderBy = "start_at DESC"; break;
                case "POPULAR": orderBy = "registered_count DESC, start_at ASC"; break;
                case "NEW": orderBy = "created_at DESC"; break;
                default: orderBy = "CASE WHEN start_at >= GETDATE() THEN 0 ELSE 1 END, start_at ASC"; break;
            }

            int take = CurrentPage * PageSize;
            string keyword = ViewState["Search"] as string ?? string.Empty;
            string category = CurrentCategory;
            string filter = CurrentFilter;

            string sql = $@"
                ;WITH src AS (
                    SELECT e.id, e.title, e.start_at, e.end_at, e.format, e.created_at,
                           e.location_name, e.location_room, e.address, e.capacity, e.price,
                           COALESCE(c.name,N'Sự kiện') AS category_name,
                           ISNULL(rc.registered_count,0) AS registered_count,
                           CAST(CASE WHEN e.capacity>0 THEN ROUND(100.0*ISNULL(rc.registered_count,0)/e.capacity,0) ELSE 0 END AS INT) AS occupancy_percent,
                           CASE WHEN ISNULL(rc.registered_count,0)>=e.capacity THEN N'hot'
                                WHEN e.capacity-ISNULL(rc.registered_count,0)<=10 THEN N'hot'
                                WHEN DATEDIFF(DAY,GETDATE(),e.start_at)<=7 THEN N'new' ELSE N'new' END AS badge_class,
                           CASE WHEN ISNULL(rc.registered_count,0)>=e.capacity THEN N'ĐÃ ĐẦY'
                                WHEN e.capacity-ISNULL(rc.registered_count,0)<=10 THEN N'HOT'
                                WHEN DATEDIFF(DAY,GETDATE(),e.start_at)<=7 THEN N'Mới' ELSE N'HOT' END AS badge_text,
                           CASE WHEN ur.event_id IS NULL THEN 0 ELSE 1 END AS is_registered
                    FROM dbo.events e
                    LEFT JOIN dbo.event_categories c ON c.id=e.category_id
                    LEFT JOIN (SELECT event_id,COUNT(*) AS registered_count FROM dbo.event_registrations
                               WHERE status IN (N'pending',N'approved',N'waitlist') GROUP BY event_id) rc ON rc.event_id=e.id
                    LEFT JOIN (SELECT event_id FROM dbo.event_registrations WHERE user_id=@UserId
                               AND status IN (N'pending',N'approved',N'waitlist') GROUP BY event_id) ur ON ur.event_id=e.id
                    WHERE e.deleted_at IS NULL AND e.status<>N'cancelled'
                      AND (@Keyword=N'' OR e.title LIKE N'%'+@Keyword+N'%' OR e.description LIKE N'%'+@Keyword+N'%')
                      AND (@Category=N'' OR c.name=@Category)
                      AND (@Filter=N'ALL'
                          OR (@Filter=N'OPEN'   AND e.status=N'open' AND e.start_at>=GETDATE())
                          OR (@Filter=N'FREE'   AND e.price<=0)
                          OR (@Filter=N'ONLINE' AND e.format IN (N'online',N'hybrid'))
                          OR (@Filter=N'TODAY'  AND CAST(e.start_at AS DATE)=CAST(GETDATE() AS DATE))
                          OR (@Filter=N'WEEK'   AND e.start_at>=CAST(GETDATE() AS DATE) AND e.start_at<DATEADD(DAY,7,CAST(GETDATE() AS DATE))))
                )
                SELECT TOP (@Take) *, (SELECT COUNT(*) FROM src) AS total_count FROM src ORDER BY {orderBy};";

            DataTable dt = Exec(sql,
                new SqlParameter("@UserId", SqlDbType.BigInt) { Value = CurrentUserId },
                new SqlParameter("@Keyword", SqlDbType.NVarChar, 200) { Value = keyword },
                new SqlParameter("@Category", SqlDbType.NVarChar, 120) { Value = category },
                new SqlParameter("@Filter", SqlDbType.NVarChar, 15) { Value = filter },
                new SqlParameter("@Take", SqlDbType.Int) { Value = take });

            rptEvents.DataSource = dt;
            rptEvents.DataBind();

            int shown = dt.Rows.Count;
            int total = shown == 0 ? 0 : Convert.ToInt32(dt.Rows[0]["total_count"]);

            litShownCount.Text = shown.ToString();
            litTotalCount.Text = total.ToString();
            pnlEmpty.Visible = shown == 0;
            rptEvents.Visible = shown > 0;

            int remaining = Math.Max(0, total - shown);
            pnlLoadMore.Visible = remaining > 0;
            litLoadMoreNum.Text = Math.Min(PageSize, remaining).ToString();
        }

        // ── BUILD FILTER LINK HREFS ──
        private void BuildFilterLinks()
        {
            string pageUrl = ResolveUrl("~/User/UserDiscover.aspx");
            string sort = HttpUtility.UrlEncode(CurrentSort);
            string cat = HttpUtility.UrlEncode(CurrentCategory);
            string search = HttpUtility.UrlEncode(ViewState["Search"] as string ?? "");

            SetAnchor(lnkFAll, "ALL", pageUrl, cat, sort, search);
            SetAnchor(lnkFOpen, "OPEN", pageUrl, cat, sort, search);
            SetAnchor(lnkFFree, "FREE", pageUrl, cat, sort, search);
            SetAnchor(lnkFOnline, "ONLINE", pageUrl, cat, sort, search);
            SetAnchor(lnkFToday, "TODAY", pageUrl, cat, sort, search);
            SetAnchor(lnkFWeek, "WEEK", pageUrl, cat, sort, search);

            // Clear filters link
            lnkClearFilters.HRef = $"{pageUrl}?filter=ALL&cat=&sort=START_ASC&q=";
            // Empty state clear link
            lnkEmptyClear.HRef = $"{pageUrl}?filter=ALL&cat=&sort=START_ASC&q=";
        }

        private void SetAnchor(HtmlAnchor a, string filterVal, string pageUrl,
                                string cat, string sort, string search)
        {
            if (a == null) return;
            bool active = string.Equals(CurrentFilter, filterVal, StringComparison.OrdinalIgnoreCase);
            a.Attributes["class"] = active ? "filter-pill active" : "filter-pill";
            a.HRef = $"{pageUrl}?filter={HttpUtility.UrlEncode(filterVal)}&cat={cat}&sort={sort}&q={search}";
        }

        private void BuildActiveFilterTags()
        {
            var parts = new System.Collections.Generic.List<string>();
            string search = ViewState["Search"] as string ?? "";
            if (!string.IsNullOrWhiteSpace(search))
                parts.Add($"<span class='tag'>Từ khoá: <b>{HttpUtility.HtmlEncode(search)}</b></span>");
            if (!string.IsNullOrWhiteSpace(CurrentCategory))
                parts.Add($"<span class='tag'>Chủ đề: <b>{HttpUtility.HtmlEncode(CurrentCategory)}</b></span>");
            if (CurrentFilter != "ALL")
                parts.Add($"<span class='tag'>Lọc: <b>{FilterLabel(CurrentFilter)}</b></span>");

            pnlActiveTags.Visible = parts.Count > 0;
            litActiveFilters.Text = string.Join("", parts);
        }

        private static string FilterLabel(string code)
        {
            switch (code)
            {
                case "OPEN": return "Đang mở";
                case "FREE": return "Miễn phí";
                case "ONLINE": return "Online";
                case "TODAY": return "Hôm nay";
                case "WEEK": return "Tuần này";
                default: return "Tất cả";
            }
        }

        // ── EVENT HANDLERS ──
        protected void btnSearch_Click(object sender, EventArgs e)
        {
            string keyword = (txtSearch.Text ?? "").Trim();
            ViewState["Search"] = keyword;
            CurrentPage = 1;
            LoadAllData();
        }

        protected void ddlSort_Changed(object sender, EventArgs e)
        {
            CurrentSort = ddlSort.SelectedValue;
            CurrentPage = 1;
            LoadAllData();
        }

        protected void LoadMore_Click(object sender, EventArgs e)
        {
            CurrentPage++;
            LoadAllData();
        }

        protected void btnFeRegister_Click(object sender, EventArgs e)
        {
            if (!long.TryParse(btnFeRegister.CommandArgument, out long eventId)) return;
            TryRegister(eventId, out string msg, out bool ok);
            ShowAlert(msg, ok ? "success" : "error");
            LoadAllData();
        }

        protected void rptEvents_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName != "Register") return;
            if (!long.TryParse(Convert.ToString(e.CommandArgument), out long eventId)) return;
            TryRegister(eventId, out string msg, out bool ok);
            ShowAlert(msg, ok ? "success" : "error");
            LoadAllData();
        }

        protected void rptEvents_ItemDataBound(object sender, RepeaterItemEventArgs e)
        {
            if (e.Item.ItemType != ListItemType.Item && e.Item.ItemType != ListItemType.AlternatingItem) return;
            if (!(e.Item.DataItem is DataRowView row)) return;
            bool isReg = Convert.ToInt32(row["is_registered"]) == 1;
            var btnR = (LinkButton)e.Item.FindControl("btnRegister");
            var btnD = (LinkButton)e.Item.FindControl("btnRegistered");
            if (btnR != null) btnR.Visible = !isReg;
            if (btnD != null) btnD.Visible = isReg;
        }

        // ── REGISTRATION ──
        private void TryRegister(long eventId, out string message, out bool ok)
        {
            message = ""; ok = false;
            long userId = CurrentUserId;
            try
            {
                using (var conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    using (var tx = conn.BeginTransaction())
                    {
                        // Check existing
                        long? existingId = null; string existingStatus = "";
                        using (var cmd = new SqlCommand(@"SELECT TOP 1 id,status FROM dbo.event_registrations WITH(UPDLOCK,HOLDLOCK) WHERE event_id=@E AND user_id=@U;", conn, tx))
                        {
                            cmd.Parameters.Add("@E", SqlDbType.BigInt).Value = eventId;
                            cmd.Parameters.Add("@U", SqlDbType.BigInt).Value = userId;
                            using (var rd = cmd.ExecuteReader()) { if (rd.Read()) { existingId = Convert.ToInt64(rd["id"]); existingStatus = Str(rd["status"]); } }
                        }
                        if (existingId.HasValue && IsActive(existingStatus)) { tx.Rollback(); message = "Bạn đã đăng ký sự kiện này rồi."; return; }

                        // Get event info
                        long cap; bool reqApproval, allowWait; string status;
                        using (var cmd = new SqlCommand("SELECT capacity,requires_approval,allow_waitlist,status FROM dbo.events WHERE id=@E AND deleted_at IS NULL;", conn, tx))
                        {
                            cmd.Parameters.Add("@E", SqlDbType.BigInt).Value = eventId;
                            using (var rd = cmd.ExecuteReader())
                            {
                                if (!rd.Read()) { tx.Rollback(); message = "Sự kiện không tồn tại."; return; }
                                cap = Convert.ToInt64(rd["capacity"]); reqApproval = Convert.ToBoolean(rd["requires_approval"]);
                                allowWait = Convert.ToBoolean(rd["allow_waitlist"]); status = Str(rd["status"]);
                                if (!status.Equals("open", StringComparison.OrdinalIgnoreCase)) { tx.Rollback(); message = "Sự kiện hiện không mở đăng ký."; return; }
                            }
                        }

                        // Count registered
                        long registered;
                        using (var cmd = new SqlCommand("SELECT COUNT(*) FROM dbo.event_registrations WHERE event_id=@E AND status IN(N'pending',N'approved',N'waitlist');", conn, tx))
                        {
                            cmd.Parameters.Add("@E", SqlDbType.BigInt).Value = eventId;
                            registered = Convert.ToInt64(cmd.ExecuteScalar());
                        }

                        string insertStatus;
                        if (registered >= cap) { if (!allowWait) { tx.Rollback(); message = "Sự kiện đã đầy."; return; } insertStatus = "waitlist"; }
                        else insertStatus = reqApproval ? "pending" : "approved";

                        string ticket = $"EV{eventId}-U{userId}-{Guid.NewGuid():N}".Substring(0, 40).ToUpper();

                        if (existingId.HasValue)
                        {
                            using (var cmd = new SqlCommand(@"UPDATE dbo.event_registrations SET status=@S,ticket_code=@T,qr_payload=NULL,registered_at=SYSUTCDATETIME(),approved_at=CASE WHEN @S=N'approved' THEN SYSUTCDATETIME() ELSE NULL END,approved_by=NULL,rejected_at=NULL,rejected_by=NULL,rejection_reason=NULL,cancelled_at=NULL,waitlist_position=CASE WHEN @S=N'waitlist' THEN(SELECT COUNT(*)+1 FROM dbo.event_registrations WHERE event_id=@E AND status=N'waitlist' AND id<>@R)ELSE NULL END,source=N'web',updated_at=SYSUTCDATETIME() WHERE id=@R;", conn, tx))
                            {
                                cmd.Parameters.Add("@R", SqlDbType.BigInt).Value = existingId.Value;
                                cmd.Parameters.Add("@E", SqlDbType.BigInt).Value = eventId;
                                cmd.Parameters.Add("@S", SqlDbType.NVarChar, 15).Value = insertStatus;
                                cmd.Parameters.Add("@T", SqlDbType.NVarChar, 40).Value = ticket;
                                cmd.ExecuteNonQuery();
                            }
                        }
                        else
                        {
                            using (var cmd = new SqlCommand("INSERT INTO dbo.event_registrations(event_id,user_id,status,ticket_code,qr_payload,source)VALUES(@E,@U,@S,@T,NULL,N'web');", conn, tx))
                            {
                                cmd.Parameters.Add("@E", SqlDbType.BigInt).Value = eventId;
                                cmd.Parameters.Add("@U", SqlDbType.BigInt).Value = userId;
                                cmd.Parameters.Add("@S", SqlDbType.NVarChar, 15).Value = insertStatus;
                                cmd.Parameters.Add("@T", SqlDbType.NVarChar, 40).Value = ticket;
                                cmd.ExecuteNonQuery();
                            }
                        }
                        tx.Commit();
                        message = insertStatus == "waitlist" ? "Sự kiện đã đầy, bạn được vào danh sách chờ."
                                : insertStatus == "approved" ? "Đăng ký thành công!"
                                : "Đăng ký thành công, đơn đang chờ phê duyệt.";
                        ok = true;
                    }
                }
            }
            catch (SqlException ex) { message = "Lỗi CSDL: " + ex.Message; }
            catch (Exception ex) { message = "Lỗi: " + ex.Message; }
        }

        private void ShowAlert(string msg, string kind = "info")
        {
            pnlAlert.Visible = true; pnlAlert.CssClass = "detail-alert " + kind;
            litAlert.Text = HttpUtility.HtmlEncode(msg);
        }

        // ── UTILITIES ──
        private DataTable Exec(string sql, params SqlParameter[] prms)
        {
            using (var conn = new SqlConnection(connStr))
            using (var cmd = new SqlCommand(sql, conn))
            using (var da = new SqlDataAdapter(cmd))
            {
                if (prms != null) cmd.Parameters.AddRange(prms);
                var dt = new DataTable(); da.Fill(dt); return dt;
            }
        }

        private static string Str(object v, string fb = "") { if (v == null || v == DBNull.Value) return fb; string t = Convert.ToString(v); return string.IsNullOrWhiteSpace(t) ? fb : t; }
        private static bool IsActive(string s) { s = (s ?? "").ToLowerInvariant(); return s == "pending" || s == "approved" || s == "waitlist"; }

        // ── PUBLIC HELPERS for databinding ──
        public string GetBannerClass(int i) { return "bg-" + ((i % 6) + 1); }
        public string GetProgressColor(object pct) { int.TryParse(Str(pct, "0"), out int p); return p >= 85 ? "red" : p >= 50 ? "amber" : "green"; }

        public string FormatCardDate(object v)
        {
            if (v == null || v == DBNull.Value) return "—";
            DateTime dt = Convert.ToDateTime(v);
            string day = dt.ToString("dddd", vi); day = char.ToUpper(day[0]) + day.Substring(1);
            return $"{day}, {dt:dd/MM} — {dt:HH:mm}";
        }

        public string FormatFeaturedDate(DateTime dt)
        {
            string day = dt.ToString("dddd", vi); day = char.ToUpper(day[0]) + day.Substring(1);
            return $"{day}, {dt:dd/MM/yyyy} — {dt:HH:mm}";
        }

        public string FormatLocation(object fmt, object ln, object lr, object addr)
        {
            string f = Str(fmt, "offline").ToLowerInvariant();
            if (f == "online") return "Online";
            string r = Str(ln);
            if (!string.IsNullOrWhiteSpace(Str(lr))) r = string.IsNullOrWhiteSpace(r) ? Str(lr) : r + ", " + Str(lr);
            if (string.IsNullOrWhiteSpace(r)) r = Str(addr);
            else if (!string.IsNullOrWhiteSpace(Str(addr)) && !r.Contains(Str(addr))) r += " · " + Str(addr);
            if (f == "hybrid") return string.IsNullOrWhiteSpace(r) ? "Hybrid" : r + " · Hybrid";
            return string.IsNullOrWhiteSpace(r) ? "—" : r;
        }

        private static string GetCategoryIconHtml(string code)
        {
            code = (code ?? "").ToLowerInvariant();
            if (code.Contains("tech") || code.Contains("cn") || code.Contains("it"))
                return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><circle cx='12' cy='12' r='3'/><path d='M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 01-2.83 2.83l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09a1.65 1.65 0 00-1-1.51 1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09a1.65 1.65 0 001.51-1 1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06a1.65 1.65 0 001.82.33h0a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06a1.65 1.65 0 00-.33 1.82v0a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z'/></svg>";
            if (code.Contains("train") || code.Contains("daotao") || code.Contains("edu"))
                return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M4 19.5A2.5 2.5 0 016.5 17H20'/><path d='M6.5 2H20v20H6.5A2.5 2.5 0 014 19.5v-15A2.5 2.5 0 016.5 2z'/></svg>";
            if (code.Contains("hr") || code.Contains("nhansu") || code.Contains("nhan_su") || code.Contains("ns"))
                return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2'/><circle cx='9' cy='7' r='4'/><path d='M23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75'/></svg>";
            if (code.Contains("cul") || code.Contains("vanhoa") || code.Contains("van_hoa") || code.Contains("vh"))
                return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M11 20A7 7 0 019.8 6.1C15.5 5 17 4.48 19 2c1 2 2 4.18 2 8 0 5.5-4.78 10-10 10z'/><path d='M2 21c0-3 1.85-5.36 5.08-6'/></svg>";
            if (code.Contains("team") || code.Contains("tb"))
                return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2'/><circle cx='9' cy='7' r='4'/><path d='M23 21v-2a4 4 0 00-3-3.87'/><path d='M16 3.13a4 4 0 010 7.75'/></svg>";
            if (code.Contains("hoi_thao") || code.Contains("hoithao") || code.Contains("workshop") || code.Contains("ws") || code.Contains("seminar"))
                return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z'/></svg>";
            if (code.Contains("hoi_nghi") || code.Contains("hoingh") || code.Contains("conf"))
                return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect x='3' y='3' width='18' height='18' rx='2'/><path d='M3 9h18'/><path d='M9 21V9'/></svg>";
            if (code.Contains("le") || code.Contains("event") || code.Contains("ceremony"))
                return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5'/></svg>";
            // default
            return @"<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><polygon points='12,2 2,7 12,12 22,7 12,2'/><polyline points='2,17 12,22 22,17'/><polyline points='2,12 12,17 22,12'/></svg>";
        }
    }
}