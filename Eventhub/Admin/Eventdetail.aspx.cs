using Eventhub.App_Code;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Eventhub.Admin
{
    public partial class Eventdetail : System.Web.UI.Page
    {
        #region View models

        public class RegistrantVM
        {
            public long Id { get; set; }
            public string FullName { get; set; }
            public string Email { get; set; }
            public string Department { get; set; }
            public DateTime RegisteredAt { get; set; }
            public string Status { get; set; }
            public string StatusText { get; set; }
            public string TimeAgo { get; set; }
            public string Initial { get; set; }
            public int ColorIndex { get; set; }
            public string TicketCode { get; set; }
        }

        public class AgendaVM
        {
            public DateTime StartTime { get; set; }
            public DateTime EndTime { get; set; }
            public string Title { get; set; }
            public string Description { get; set; }
            public string ItemType { get; set; }
        }

        public class SpeakerVM
        {
            public string FullName { get; set; }
            public string Title { get; set; }
            public string Initial { get; set; }
            public int ColorIndex { get; set; }
        }

        public class FeedVM
        {
            public string Text { get; set; }
            public string TimeText { get; set; }
            public string DotColor { get; set; }
        }

        #endregion

        #region Properties

        private long EventId
        {
            get
            {
                long id;
                long.TryParse(Request.QueryString["id"], out id);
                return id;
            }
        }

        public string StatusClass { get; set; }

        private string CurrentModalFilter
        {
            get { return hfModalStatus.Value ?? ""; }
            set { hfModalStatus.Value = value ?? ""; }
        }

        #endregion

        protected void Page_Load(object sender, EventArgs e)
        {
            var master = Master as Eventhub.AdminMaster;
            if (master != null) master.Breadcrumb = "Chi tiết sự kiện";

            if (EventId <= 0)
            {
                Response.Redirect("~/Admin/EventsManagement.aspx");
                return;
            }

            if (!IsPostBack)
            {
                LoadEventDetail();
                LoadStats();
                LoadAgenda();
                LoadSpeakers();
                LoadRecentRegistrants();
                LoadFeed();
            }
        }

        #region Load Event Detail

        private void LoadEventDetail()
        {
            const string sql = @"
                SELECT e.*,
                       c.name AS category_name, c.code AS category_code,
                       d.name AS department_name,
                       u.first_name + N' ' + u.last_name AS creator_name,
                       ud.name AS creator_department
                FROM dbo.events e
                JOIN dbo.event_categories c ON c.id = e.category_id
                JOIN dbo.departments d ON d.id = e.organizer_department_id
                JOIN dbo.users u ON u.id = e.created_by
                LEFT JOIN dbo.departments ud ON ud.id = u.department_id
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
                            Response.Redirect("~/Admin/EventsManagement.aspx");
                            return;
                        }

                        var title = rd["title"].ToString();
                        litTitle.Text = HttpUtility.HtmlEncode(title);
                        litPageTitle.Text = title + " — EventHub Admin";

                        var master = Master as Eventhub.AdminMaster;
                        if (master != null) master.Breadcrumb = title;

                        var status = rd["status"].ToString();
                        litStatus.Text = MapStatusEvent(status);
                        StatusClass = "status-" + status;
                        spanStatus.Attributes["class"] = "status-pill-lg status-" + status;

                        var createdAt = Convert.ToDateTime(rd["created_at"]);
                        var updatedAt = Convert.ToDateTime(rd["updated_at"]);
                        litCreatedAt.Text = createdAt.ToString("HH:mm, dd/MM/yyyy");
                        litUpdatedAt.Text = RelativeTime(updatedAt);

                        var startAt = Convert.ToDateTime(rd["start_at"]);
                        var endAt = Convert.ToDateTime(rd["end_at"]);
                        litCountdown.Text = BuildCountdown(startAt, endAt);

                        litCategory.Text = HttpUtility.HtmlEncode(rd["category_name"].ToString());
                        litHeadline.Text = HttpUtility.HtmlEncode(title);
                        litSubtitle.Text = rd["subtitle"] != DBNull.Value
                            ? HttpUtility.HtmlEncode(rd["subtitle"].ToString())
                            : "";

                        var bannerUrl = rd["banner_url"] as string;
                        if (!string.IsNullOrEmpty(bannerUrl))
                        {
                            imgBanner.ImageUrl = bannerUrl;
                            imgBanner.Visible = true;
                            phBannerIcon.Visible = false;
                        }

                        var daysToStart = (startAt - DateTime.Now).TotalDays;
                        if (daysToStart >= 0 && daysToStart <= 7)
                            litBannerTag1.Text = "HOT EVENT";
                        else if (status == "draft")
                            litBannerTag1.Text = "BẢN NHÁP";
                        else if (status == "ended")
                            litBannerTag1.Text = "ĐÃ KẾT THÚC";
                        else
                            litBannerTag1.Text = "SỰ KIỆN";

                        litMetaDate.Text = startAt.ToString("dd/MM/yyyy");
                        litMetaDayOfWeek.Text = VietnameseDayOfWeek(startAt);
                        litMetaTime.Text = startAt.ToString("HH:mm") + " — " + endAt.ToString("HH:mm");
                        litMetaDuration.Text = FormatDuration(endAt - startAt);

                        var locName = rd["location_name"] as string;
                        var locRoom = rd["location_room"] as string;
                        litMetaLocation.Text = HttpUtility.HtmlEncode(locName ?? "Chưa có địa điểm");
                        litMetaRoom.Text = HttpUtility.HtmlEncode(locRoom ?? "");

                        var capacity = Convert.ToInt32(rd["capacity"]);
                        litMetaCapacity.Text = capacity.ToString("N0") + " người tối đa";
                        litMetaFormat.Text = MapFormat(rd["format"].ToString());

                        var desc = rd["description"] as string;
                        litDescription.Text = !string.IsNullOrEmpty(desc)
                            ? desc      
                            : "<p><i>Sự kiện này chưa có mô tả chi tiết.</i></p>";

                        ViewState["capacity"] = capacity;
                        ViewState["status"] = status;
                        ViewState["startAt"] = startAt;

                        litEventCode.Text = HttpUtility.HtmlEncode(rd["event_code"].ToString());
                        litInfoFormat.Text = MapFormat(rd["format"].ToString());
                        litInfoAudience.Text = Convert.ToBoolean(rd["is_open_to_all_departments"])
                            ? "Toàn công ty" : "Nội bộ phòng ban";

                        var price = Convert.ToDecimal(rd["price"]);
                        litInfoPrice.Text = price == 0
                            ? "Miễn phí"
                            : price.ToString("N0") + " " + rd["currency"];

                        if (rd["registration_deadline"] != DBNull.Value)
                            litInfoDeadline.Text = Convert.ToDateTime(rd["registration_deadline"]).ToString("dd/MM/yyyy");
                        else
                            litInfoDeadline.Text = "—";

                        litInfoApproval.Text = Convert.ToBoolean(rd["requires_approval"]) ? "Có" : "Không";

                        var creatorName = rd["creator_name"].ToString().Trim();
                        litOrgName.Text = HttpUtility.HtmlEncode(creatorName);
                        litOrgInitial.Text = string.IsNullOrEmpty(creatorName) ? "?" : creatorName[0].ToString().ToUpper();
                        var creatorDept = rd["creator_department"] as string;
                        litOrgRole.Text = (creatorDept ?? rd["department_name"].ToString()) + " · Người tạo sự kiện";


                        lnkEdit.NavigateUrl = "~/Admin/EventCreate.aspx?id=" + EventId;
                    }
                }
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi khi tải sự kiện: " + ex.Message, isError: true);
            }
        }

        #endregion

        #region Load Stats

        private void LoadStats()
        {
            int registered = 0, approved = 0, rejected = 0;
            int capacity = (int)(ViewState["capacity"] ?? 0);
            int views = 0;

            try
            {
                const string sqlReg = @"
                    SELECT
                        SUM(CASE WHEN status IN (N'approved', N'pending') THEN 1 ELSE 0 END) AS registered,
                        SUM(CASE WHEN status = N'approved' THEN 1 ELSE 0 END) AS approved,
                        SUM(CASE WHEN status = N'rejected' THEN 1 ELSE 0 END) AS rejected
                    FROM dbo.event_registrations
                    WHERE event_id = @eid;";

                using (var con = Database.OpenConnection())
                {
                    using (var cmd = new SqlCommand(sqlReg, con))
                    {
                        cmd.Parameters.AddWithValue("@eid", EventId);
                        using (var rd = cmd.ExecuteReader())
                        {
                            if (rd.Read())
                            {
                                registered = rd["registered"] == DBNull.Value ? 0 : Convert.ToInt32(rd["registered"]);
                                approved = rd["approved"] == DBNull.Value ? 0 : Convert.ToInt32(rd["approved"]);
                                rejected = rd["rejected"] == DBNull.Value ? 0 : Convert.ToInt32(rd["rejected"]);
                            }
                        }
                    }

                    using (var cmd = new SqlCommand("SELECT view_count FROM dbo.events WHERE id = @eid;", con))
                    {
                        cmd.Parameters.AddWithValue("@eid", EventId);
                        var o = cmd.ExecuteScalar();
                        if (o != null && o != DBNull.Value) views = Convert.ToInt32(o);
                    }
                }
            }
            catch {  }

            int fillPct = capacity > 0 ? (int)Math.Round(registered * 100.0 / capacity) : 0;
            if (fillPct > 100) fillPct = 100;

            litStatRegistered.Text = registered.ToString();
            litStatCapacity.Text = capacity.ToString();
            litStatApproved.Text = approved.ToString();
            litStatViews.Text = views.ToString();
            litStatFillRate.Text = fillPct.ToString();

            litRegBigNum.Text = registered.ToString();
            litRegBigTotal.Text = capacity.ToString();
            litFillPct.Text = fillPct.ToString();
            litRemaining.Text = Math.Max(0, capacity - registered).ToString();
            regBarFill.Attributes["style"] = "width: " + fillPct + "%";

            litTotalReg.Text = registered.ToString();
        }

        #endregion

        #region Load Agenda

        private void LoadAgenda()
        {
            var list = new List<AgendaVM>();
            try
            {
                const string sql = @"
                    SELECT start_time, end_time, title, description, item_type
                    FROM dbo.event_agenda_items
                    WHERE event_id = @eid
                    ORDER BY start_time, sort_order;";

                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@eid", EventId);
                    using (var rd = cmd.ExecuteReader())
                    {
                        while (rd.Read())
                        {
                            list.Add(new AgendaVM
                            {
                                StartTime = Convert.ToDateTime(rd["start_time"]),
                                EndTime = Convert.ToDateTime(rd["end_time"]),
                                Title = rd["title"].ToString(),
                                Description = rd["description"] as string ?? "",
                                ItemType = rd["item_type"].ToString()
                            });
                        }
                    }
                }
            }
            catch { }

            pnlAgenda.Visible = list.Count > 0;
            rptAgenda.DataSource = list;
            rptAgenda.DataBind();
        }

        #endregion

        #region Load Speakers

        private void LoadSpeakers()
        {
            var list = new List<SpeakerVM>();
            try
            {
                const string sql = @"
                    SELECT full_name, title
                    FROM dbo.event_speakers
                    WHERE event_id = @eid
                    ORDER BY sort_order, id;";

                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@eid", EventId);
                    using (var rd = cmd.ExecuteReader())
                    {
                        int i = 0;
                        while (rd.Read())
                        {
                            var name = rd["full_name"].ToString();
                            list.Add(new SpeakerVM
                            {
                                FullName = name,
                                Title = rd["title"] as string ?? "",
                                Initial = string.IsNullOrEmpty(name) ? "?" : name[0].ToString().ToUpper(),
                                ColorIndex = (i % 4) + 1
                            });
                            i++;
                        }
                    }
                }
            }
            catch { }

            pnlSpeakers.Visible = list.Count > 0;
            rptSpeakers.DataSource = list;
            rptSpeakers.DataBind();
        }

        #endregion

        #region Load Registrants

        private void LoadRecentRegistrants()
        {
            var list = LoadRegistrantsFromDb(statusFilter: null, top: 5);

            rptRegistrants.DataSource = list;
            rptRegistrants.DataBind();

            phEmpty.Visible = list.Count == 0;
            litShownCount.Text = list.Count.ToString();
        }

        /// <summary>
        /// Load người đăng ký từ DB.
        /// </summary>
        /// <param name="statusFilter">"approved" | "pending" | "rejected" | null=tất cả</param>
        /// <param name="top">Số bản ghi tối đa; null = không giới hạn</param>
        private List<RegistrantVM> LoadRegistrantsFromDb(string statusFilter, int? top)
        {
            var list = new List<RegistrantVM>();

            var sql = (top.HasValue ? "SELECT TOP " + top.Value + " " : "SELECT ") + @"
                r.id, r.status, r.registered_at, r.ticket_code,
                u.first_name + N' ' + u.last_name AS full_name,
                u.email,
                ISNULL(d.name, N'(Không phòng ban)') AS dept_name
                FROM dbo.event_registrations r
                JOIN dbo.users u ON u.id = r.user_id
                LEFT JOIN dbo.departments d ON d.id = u.department_id
                WHERE r.event_id = @eid";

            if (!string.IsNullOrEmpty(statusFilter))
                sql += " AND r.status = @st";

            sql += " ORDER BY r.registered_at DESC;";

            try
            {
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@eid", EventId);
                    if (!string.IsNullOrEmpty(statusFilter))
                        cmd.Parameters.AddWithValue("@st", statusFilter);

                    using (var rd = cmd.ExecuteReader())
                    {
                        int i = 0;
                        while (rd.Read())
                        {
                            var name = rd["full_name"].ToString().Trim();
                            var status = rd["status"].ToString();
                            var regAt = Convert.ToDateTime(rd["registered_at"]);

                            list.Add(new RegistrantVM
                            {
                                Id = Convert.ToInt64(rd["id"]),
                                FullName = name,
                                Email = rd["email"].ToString(),
                                Department = rd["dept_name"].ToString(),
                                RegisteredAt = regAt,
                                Status = status,
                                StatusText = MapStatusReg(status),
                                TimeAgo = RelativeTime(regAt),
                                Initial = string.IsNullOrEmpty(name)
                                    ? "?"
                                    : BuildInitials(name),
                                ColorIndex = (i % 6) + 1,
                                TicketCode = rd["ticket_code"] as string ?? ""
                            });
                            i++;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("LoadRegistrants error: " + ex.Message);
            }

            return list;
        }

        #endregion

        #region Load Feed

        private void LoadFeed()
        {
            var list = new List<FeedVM>();
            try
            {
                const string sql = @"
                    SELECT TOP 10 al.action, al.created_at, al.entity_type, al.entity_id,
                           u.first_name + N' ' + u.last_name AS user_name
                    FROM dbo.activity_logs al
                    LEFT JOIN dbo.users u ON u.id = al.user_id
                    WHERE (al.entity_type = N'event' AND al.entity_id = @eid)
                       OR (al.entity_type = N'event_registration'
                           AND al.entity_id IN (SELECT id FROM dbo.event_registrations WHERE event_id = @eid))
                    ORDER BY al.created_at DESC;";

                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@eid", EventId);
                    using (var rd = cmd.ExecuteReader())
                    {
                        while (rd.Read())
                        {
                            var action = rd["action"].ToString();
                            var when = Convert.ToDateTime(rd["created_at"]);
                            var userName = rd["user_name"] as string ?? "Hệ thống";

                            list.Add(new FeedVM
                            {
                                Text = BuildFeedText(action, userName),
                                TimeText = when.ToString("HH:mm, dd/MM") + " · " + RelativeTime(when),
                                DotColor = MapFeedDot(action)
                            });
                        }
                    }
                }
            }
            catch { }

            if (list.Count == 0)
            {
                list.Add(new FeedVM
                {
                    Text = "<b>Hệ thống</b> đã tạo sự kiện",
                    TimeText = "hôm nay",
                    DotColor = ""
                });
            }

            rptFeed.DataSource = list;
            rptFeed.DataBind();
        }

        private static string BuildFeedText(string action, string userName)
        {
            switch (action)
            {
                case "event.create": return "<b>" + HttpUtility.HtmlEncode(userName) + "</b> đã tạo sự kiện";
                case "event.update": return "<b>" + HttpUtility.HtmlEncode(userName) + "</b> đã cập nhật sự kiện";
                case "event.publish": return "<b>" + HttpUtility.HtmlEncode(userName) + "</b> đã đăng sự kiện";
                case "event.cancel": return "<b>" + HttpUtility.HtmlEncode(userName) + "</b> đã huỷ sự kiện";
                case "registration.create": return "<b>" + HttpUtility.HtmlEncode(userName) + "</b> vừa đăng ký tham dự";
                case "registration.approve": return "<b>" + HttpUtility.HtmlEncode(userName) + "</b> duyệt đăng ký";
                case "registration.reject": return "<b>" + HttpUtility.HtmlEncode(userName) + "</b> từ chối đăng ký";
                case "registration.cancel": return "<b>" + HttpUtility.HtmlEncode(userName) + "</b> đã huỷ đăng ký";
                default: return "<b>" + HttpUtility.HtmlEncode(userName) + "</b> " + HttpUtility.HtmlEncode(action);
            }
        }

        private static string MapFeedDot(string action)
        {
            if (action.StartsWith("event.create") || action.StartsWith("event.publish")) return "green";
            if (action.StartsWith("registration.approve")) return "green";
            if (action.StartsWith("registration.reject") || action.StartsWith("event.cancel")) return "red";
            if (action.StartsWith("event.update")) return "blue";
            if (action.StartsWith("registration.create")) return "dark";
            return "";
        }

        #endregion

        #region Modal "Xem tất cả"

        protected void btnShowAll_Click(object sender, EventArgs e)
        {
            CurrentModalFilter = "";
            ShowAllModal();
        }

        protected void btnCloseModal_Click(object sender, EventArgs e)
        {
            pnlAllRegModal.Visible = false;
        }

        protected void ModalTab_Command(object sender, CommandEventArgs e)
        {
            CurrentModalFilter = (e.CommandArgument ?? "").ToString();
            ShowAllModal();
        }

        private void ShowAllModal()
        {
            pnlAllRegModal.Visible = true;

            litModalEventTitle.Text = litTitle.Text;

            var counts = LoadRegCounts();
            int total = counts["all"];
            litModalTotal.Text = total.ToString();
            litCntAll.Text = total.ToString();
            litCntApproved.Text = counts["approved"].ToString();
            litCntPending.Text = counts["pending"].ToString();
            litCntRejected.Text = counts["rejected"].ToString();

            var statusFilter = CurrentModalFilter;
            var list = LoadRegistrantsFromDb(
                string.IsNullOrEmpty(statusFilter) ? null : statusFilter,
                top: null);

            rptAllRegistrants.DataSource = list;
            rptAllRegistrants.DataBind();
            phModalEmpty.Visible = list.Count == 0;

            tabAll.CssClass = "modal-tab" + (string.IsNullOrEmpty(statusFilter) ? " active" : "");
            tabApproved.CssClass = "modal-tab" + (statusFilter == "approved" ? " active" : "");
            tabPending.CssClass = "modal-tab" + (statusFilter == "pending" ? " active" : "");
            tabRejected.CssClass = "modal-tab" + (statusFilter == "rejected" ? " active" : "");
        }

        private Dictionary<string, int> LoadRegCounts()
        {
            var dict = new Dictionary<string, int>
            {
                { "all", 0 }, { "approved", 0 }, { "pending", 0 }, { "rejected", 0 }
            };

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
                            dict["all"] += c;
                            if (dict.ContainsKey(st)) dict[st] = c;
                        }
                    }
                }
            }
            catch { }

            return dict;
        }

        #endregion

        #region Approve / Reject / Reset

        protected void rptRegistrants_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            HandleRegCommand(e.CommandName, e.CommandArgument);
            LoadStats();
            LoadRecentRegistrants();
            LoadFeed();
        }

        protected void rptAllRegistrants_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            HandleRegCommand(e.CommandName, e.CommandArgument);
            LoadStats();
            LoadRecentRegistrants();
            LoadFeed();
            ShowAllModal();
        }

        private void HandleRegCommand(string command, object arg)
        {
            long regId;
            if (!long.TryParse((arg ?? "").ToString(), out regId)) return;

            var currentUser = AuthHelper.CurrentUser(Session);
            long actorId = currentUser != null ? currentUser.Id : 0;

            try
            {
                string newStatus;
                string sql;

                switch (command)
                {
                    case "ApproveReg":
                        newStatus = "approved";
                        sql = @"UPDATE dbo.event_registrations
                                SET status = N'approved',
                                    approved_at = SYSUTCDATETIME(),
                                    approved_by = @uid,
                                    rejected_at = NULL,
                                    rejected_by = NULL
                                WHERE id = @rid;";
                        break;

                    case "RejectReg":
                        newStatus = "rejected";
                        sql = @"UPDATE dbo.event_registrations
                                SET status = N'rejected',
                                    rejected_at = SYSUTCDATETIME(),
                                    rejected_by = @uid,
                                    approved_at = NULL,
                                    approved_by = NULL
                                WHERE id = @rid;";
                        break;

                    case "ResetReg":
                        newStatus = "pending";
                        sql = @"UPDATE dbo.event_registrations
                                SET status = N'pending',
                                    approved_at = NULL, approved_by = NULL,
                                    rejected_at = NULL, rejected_by = NULL
                                WHERE id = @rid;";
                        break;

                    default:
                        return;
                }

                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@rid", regId);
                    cmd.Parameters.AddWithValue("@uid", actorId > 0 ? (object)actorId : DBNull.Value);
                    cmd.ExecuteNonQuery();
                }

                if (actorId > 0)
                {
                    AuthHelper.LogActivity(actorId,
                        "registration." + (newStatus == "pending" ? "reset" : newStatus),
                        Request.UserHostAddress, Request.UserAgent);
                }

                ShowAlert("Đã cập nhật trạng thái đăng ký.", isError: false);
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi cập nhật: " + ex.Message, isError: true);
            }
        }

        #endregion

        #region Helpers

        private static string MapStatusEvent(string s)
        {
            switch (s)
            {
                case "open": return "Đang mở";
                case "closed": return "Đóng đăng ký";
                case "ended": return "Đã kết thúc";
                case "draft": return "Bản nháp";
                case "cancelled": return "Đã huỷ";
                default: return s;
            }
        }

        private static string MapStatusReg(string s)
        {
            switch (s)
            {
                case "pending": return "Chờ duyệt";
                case "approved": return "Đã duyệt";
                case "rejected": return "Từ chối";
                case "waitlist": return "Danh sách chờ";
                case "cancelled": return "Đã huỷ";
                default: return s;
            }
        }

        private static string MapFormat(string s)
        {
            switch (s)
            {
                case "offline": return "Trực tiếp (Offline)";
                case "online": return "Trực tuyến (Online)";
                case "hybrid": return "Kết hợp (Hybrid)";
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

        private static string FormatDuration(TimeSpan ts)
        {
            int h = (int)ts.TotalHours;
            int m = ts.Minutes;
            if (h > 0 && m > 0) return h + "h " + m + "m";
            if (h > 0) return h + " giờ";
            return m + " phút";
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

        private static string BuildCountdown(DateTime startAt, DateTime endAt)
        {
            var now = DateTime.Now;
            if (now < startAt)
            {
                var d = (startAt - now).TotalDays;
                if (d < 1) return "Còn " + (int)(startAt - now).TotalHours + " giờ";
                return "Còn " + (int)Math.Ceiling(d) + " ngày trước";
            }
            if (now >= startAt && now <= endAt) return "Đang diễn ra";
            return "Đã kết thúc";
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