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
    public partial class approval : System.Web.UI.Page
    {
        #region View Models

        public class EventCardVM
        {
            public long Id { get; set; }
            public string Title { get; set; }
            public string CategoryName { get; set; }
            public DateTime StartAt { get; set; }
            public string LocationName { get; set; }
            public int Capacity { get; set; }
            public int ApprovedCount { get; set; }
            public int PendingCount { get; set; }
            public int Remaining => Math.Max(0, Capacity - ApprovedCount - PendingCount);
            public DateTime? Deadline { get; set; }
            public string DeadlineText { get; set; }
            public bool IsDeadlineSoon { get; set; }
            public string LatestActivityText { get; set; }
            public int BannerIndex { get; set; } 
            public int FillPercent
            {
                get
                {
                    if (Capacity <= 0) return 0;
                    return Math.Min(100, (int)Math.Round((ApprovedCount + PendingCount) * 100.0 / Capacity));
                }
            }
            public int ApprovedPercent
            {
                get { return Capacity <= 0 ? 0 : Math.Min(100, (int)Math.Round(ApprovedCount * 100.0 / Capacity)); }
            }
            public int PendingPercent
            {
                get { return Capacity <= 0 ? 0 : Math.Min(100 - ApprovedPercent, (int)Math.Round(PendingCount * 100.0 / Capacity)); }
            }
        }

        public class PendingRegVM
        {
            public long Id { get; set; }
            public string FullName { get; set; }
            public string Email { get; set; }
            public string Department { get; set; }
            public DateTime RegisteredAt { get; set; }
            public string TimeAgo { get; set; }
            public string Initial { get; set; }
            public int ColorIndex { get; set; }
        }

        #endregion

        #region Properties

        private long ModalEventId
        {
            get { long id; long.TryParse(hfEventId.Value, out id); return id; }
            set { hfEventId.Value = value.ToString(); }
        }

        private string Filter
        {
            get { return string.IsNullOrEmpty(hfFilter.Value) ? "all" : hfFilter.Value; }
            set { hfFilter.Value = value ?? "all"; }
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
            if (master != null) master.Breadcrumb = "Xét duyệt đăng ký";

            if (!IsPostBack)
            {
                var qs = Request.QueryString["filter"];
                if (!string.IsNullOrEmpty(qs) && (qs == "urgent" || qs == "all" || qs == "full"))
                    Filter = qs;
                else
                    Filter = "all";

                var list = Session["ConfirmCodes"] as List<ConfirmCodeItem>;
                if (list != null)
                {
                    list.ForEach(x => x.IsHidden = false);
                }

                LoadStats();
                LoadEvents();
            }

            BindConfirmList();
            SetTabUrls();
            SetActiveTab();
        }

        #region URL & active tab

        private void SetTabUrls()
        {
            tabUrgent.NavigateUrl = "~/Admin/Approval.aspx?filter=urgent";
            tabAll.NavigateUrl = "~/Admin/Approval.aspx?filter=all";
            tabFull.NavigateUrl = "~/Admin/Approval.aspx?filter=full";
        }

        private void SetActiveTab()
        {
            tabUrgent.CssClass = "filter-tab" + (Filter == "urgent" ? " active" : "");
            tabAll.CssClass = "filter-tab" + (Filter == "all" ? " active" : "");
            tabFull.CssClass = "filter-tab" + (Filter == "full" ? " active" : "");
        }

        #endregion

        #region Load stats

        private void LoadStats()
        {
            int totalPending = 0, eventCount = 0;
            int approved7 = 0, total7 = 0;
            DateTime? oldestPending = null;
            int urgentCnt = 0, allCnt = 0, fullCnt = 0;

            try
            {
                const string sqlTotal = @"
                    SELECT
                        (SELECT COUNT(*) FROM dbo.event_registrations r
                         JOIN dbo.events e ON e.id = r.event_id
                         WHERE r.status = N'pending' AND e.deleted_at IS NULL)            AS total_pending,
                        (SELECT COUNT(DISTINCT r.event_id) FROM dbo.event_registrations r
                         JOIN dbo.events e ON e.id = r.event_id
                         WHERE r.status = N'pending' AND e.deleted_at IS NULL)            AS event_count,
                        (SELECT MIN(registered_at) FROM dbo.event_registrations r
                         JOIN dbo.events e ON e.id = r.event_id
                         WHERE r.status = N'pending' AND e.deleted_at IS NULL)            AS oldest;";

                using (var con = Database.OpenConnection())
                {
                    using (var cmd = new SqlCommand(sqlTotal, con))
                    using (var rd = cmd.ExecuteReader())
                    {
                        if (rd.Read())
                        {
                            totalPending = rd["total_pending"] == DBNull.Value ? 0 : Convert.ToInt32(rd["total_pending"]);
                            eventCount = rd["event_count"] == DBNull.Value ? 0 : Convert.ToInt32(rd["event_count"]);
                            if (rd["oldest"] != DBNull.Value) oldestPending = Convert.ToDateTime(rd["oldest"]);
                        }
                    }

                    const string sql7 = @"
                        SELECT
                            SUM(CASE WHEN status = N'approved' THEN 1 ELSE 0 END) AS approved7,
                            COUNT(*) AS total7
                        FROM dbo.event_registrations
                        WHERE updated_at >= DATEADD(DAY, -7, SYSUTCDATETIME())
                          AND status IN (N'approved', N'rejected');";
                    using (var cmd = new SqlCommand(sql7, con))
                    using (var rd = cmd.ExecuteReader())
                    {
                        if (rd.Read())
                        {
                            approved7 = rd["approved7"] == DBNull.Value ? 0 : Convert.ToInt32(rd["approved7"]);
                            total7 = rd["total7"] == DBNull.Value ? 0 : Convert.ToInt32(rd["total7"]);
                        }
                    }

                    const string sqlCounts = @"
                        SELECT
                            event_id,
                            SUM(CASE WHEN status = N'pending'  THEN 1 ELSE 0 END) AS pend,
                            SUM(CASE WHEN status = N'approved' THEN 1 ELSE 0 END) AS appr
                        FROM dbo.event_registrations
                        WHERE event_id IN (SELECT id FROM dbo.events WHERE deleted_at IS NULL)
                        GROUP BY event_id;";

                    var pendByEvt = new Dictionary<long, int>();
                    var apprByEvt = new Dictionary<long, int>();
                    using (var cmd = new SqlCommand(sqlCounts, con))
                    using (var rd = cmd.ExecuteReader())
                    {
                        while (rd.Read())
                        {
                            var eid = Convert.ToInt64(rd["event_id"]);
                            pendByEvt[eid] = Convert.ToInt32(rd["pend"]);
                            apprByEvt[eid] = Convert.ToInt32(rd["appr"]);
                        }
                    }

                    const string sqlEvents = @"
                        SELECT id, capacity, start_at, registration_deadline
                        FROM dbo.events
                        WHERE deleted_at IS NULL AND status IN (N'open', N'closed');";
                    using (var cmd = new SqlCommand(sqlEvents, con))
                    using (var rd = cmd.ExecuteReader())
                    {
                        while (rd.Read())
                        {
                            var eid = Convert.ToInt64(rd["id"]);
                            var cap = Convert.ToInt32(rd["capacity"]);
                            var start = Convert.ToDateTime(rd["start_at"]);
                            DateTime? dl = rd["registration_deadline"] == DBNull.Value
                                ? (DateTime?)null
                                : Convert.ToDateTime(rd["registration_deadline"]);

                            int pend = pendByEvt.ContainsKey(eid) ? pendByEvt[eid] : 0;
                            int appr = apprByEvt.ContainsKey(eid) ? apprByEvt[eid] : 0;

                            if (pend > 0) allCnt++;
                            bool urgent = pend > 0 && (
                                (dl.HasValue && (dl.Value - DateTime.Now).TotalDays <= 3) ||
                                (start - DateTime.Now).TotalDays <= 3);
                            if (urgent) urgentCnt++;
                            if (cap > 0 && pend > 0 && ((appr + pend) * 100.0 / cap) >= 85) fullCnt++;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("LoadStats error: " + ex.Message);
            }

            litTotalPending.Text = totalPending.ToString();
            litEventCount.Text = eventCount.ToString();
            litStatPending.Text = totalPending.ToString();
            litStatPendingTrend.Text = totalPending > 0 ? "Cần xử lý sớm" : "Không có yêu cầu chờ";
            litStatEvents.Text = eventCount.ToString();
            litStatEventsTrend.Text = eventCount > 0 ? eventCount + " sự kiện đang chờ" : "Đã xử lý hết";
            litStatApproved.Text = approved7.ToString();
            litStatApprovedRate.Text = total7 > 0
                ? Math.Round(approved7 * 100.0 / total7) + "% tỉ lệ duyệt"
                : "Chưa có dữ liệu";

            if (oldestPending.HasValue)
            {
                var hours = (DateTime.Now - oldestPending.Value).TotalHours;
                if (hours >= 24)
                {
                    litStatOldest.Text = (int)(hours / 24) + " ngày";
                    litStatOldestTrend.Text = "⚠ Đã quá 24 giờ";
                }
                else
                {
                    litStatOldest.Text = (int)hours + " giờ";
                    litStatOldestTrend.Text = "Trong ngày";
                }
            }
            else
            {
                litStatOldest.Text = "—";
                litStatOldestTrend.Text = "";
            }

            litCntUrgent.Text = urgentCnt.ToString();
            litCntAll.Text = allCnt.ToString();
            litCntFull.Text = fullCnt.ToString();
        }

        #endregion

        #region Load events

        private void LoadEvents()
        {
            var list = new List<EventCardVM>();

            try
            {
                var sql = new System.Text.StringBuilder();
                sql.AppendLine(@"
                    ;WITH agg AS (
                        SELECT event_id,
                               SUM(CASE WHEN status = N'pending'  THEN 1 ELSE 0 END) AS pending_cnt,
                               SUM(CASE WHEN status = N'approved' THEN 1 ELSE 0 END) AS approved_cnt,
                               MIN(CASE WHEN status = N'pending' THEN registered_at END) AS oldest_pending
                        FROM dbo.event_registrations
                        GROUP BY event_id
                    )
                    SELECT e.id, e.title, e.start_at, e.location_name, e.capacity,
                           e.registration_deadline,
                           c.name AS category_name,
                           ISNULL(a.pending_cnt, 0)  AS pending_cnt,
                           ISNULL(a.approved_cnt, 0) AS approved_cnt,
                           a.oldest_pending
                    FROM dbo.events e
                    JOIN dbo.event_categories c ON c.id = e.category_id
                    LEFT JOIN agg a ON a.event_id = e.id
                    WHERE e.deleted_at IS NULL
                      AND e.status IN (N'open', N'closed')
                      AND ISNULL(a.pending_cnt, 0) > 0");

                if (!string.IsNullOrEmpty(Keyword))
                    sql.AppendLine(" AND e.title LIKE @kw");
                if (Filter == "urgent")
                {
                    sql.AppendLine(@" AND (
                        (e.registration_deadline IS NOT NULL AND DATEDIFF(DAY, SYSUTCDATETIME(), e.registration_deadline) <= 3)
                        OR DATEDIFF(DAY, SYSUTCDATETIME(), e.start_at) <= 3)");
                }
                else if (Filter == "full")
                {
                    sql.AppendLine(@" AND e.capacity > 0
                        AND ((a.approved_cnt + a.pending_cnt) * 100.0 / e.capacity) >= 85");
                }

                sql.AppendLine(" ORDER BY ISNULL(a.oldest_pending, e.start_at), e.start_at;");

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
                            DateTime? dl = rd["registration_deadline"] == DBNull.Value
                                ? (DateTime?)null
                                : Convert.ToDateTime(rd["registration_deadline"]);

                            list.Add(new EventCardVM
                            {
                                Id = Convert.ToInt64(rd["id"]),
                                Title = rd["title"].ToString(),
                                CategoryName = rd["category_name"].ToString().ToUpper(),
                                StartAt = startAt,
                                LocationName = rd["location_name"] as string ?? "Chưa có địa điểm",
                                Capacity = Convert.ToInt32(rd["capacity"]),
                                ApprovedCount = Convert.ToInt32(rd["approved_cnt"]),
                                PendingCount = Convert.ToInt32(rd["pending_cnt"]),
                                Deadline = dl,
                                DeadlineText = BuildDeadlineText(dl, startAt),
                                IsDeadlineSoon = dl.HasValue && (dl.Value - DateTime.Now).TotalDays <= 3,
                                LatestActivityText = "Có yêu cầu mới cần xử lý",
                                BannerIndex = (idx % 6) + 1
                            });
                            idx++;
                        }
                    }
                }

                if (list.Count > 0)
                {
                    var ids = string.Join(",", list.Select(x => x.Id));
                    var sqlAct = @"
                        SELECT r.event_id, u.first_name + N' ' + u.last_name AS user_name,
                               r.registered_at,
                               ROW_NUMBER() OVER (PARTITION BY r.event_id ORDER BY r.registered_at DESC) AS rn
                        FROM dbo.event_registrations r
                        JOIN dbo.users u ON u.id = r.user_id
                        WHERE r.event_id IN (" + ids + @")
                          AND r.status = N'pending'";
                    using (var con2 = Database.OpenConnection())
                    using (var cmd2 = new SqlCommand("SELECT * FROM (" + sqlAct + ") t WHERE rn = 1;", con2))
                    using (var rd2 = cmd2.ExecuteReader())
                    {
                        while (rd2.Read())
                        {
                            var eid = Convert.ToInt64(rd2["event_id"]);
                            var name = rd2["user_name"].ToString().Trim();
                            var at = Convert.ToDateTime(rd2["registered_at"]);
                            var item = list.FirstOrDefault(x => x.Id == eid);
                            if (item != null)
                                item.LatestActivityText =
                                    "<b>" + HttpUtility.HtmlEncode(name) + "</b> vừa đăng ký · " + RelativeTime(at);
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

        #endregion

        #region Modal: show pending list

        protected void rptEvents_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "ShowApprove")
            {
                long eid;
                if (long.TryParse(e.CommandArgument.ToString(), out eid))
                {
                    ModalEventId = eid;
                    OpenModal();
                }
            }
        }

        private void OpenModal()
        {
            pnlModal.Visible = true;

            try
            {
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand("SELECT title FROM dbo.events WHERE id = @id;", con))
                {
                    cmd.Parameters.AddWithValue("@id", ModalEventId);
                    var o = cmd.ExecuteScalar();
                    litModalEventTitle.Text = o != null && o != DBNull.Value
                        ? HttpUtility.HtmlEncode(o.ToString())
                        : "(Không xác định)";
                }
            }
            catch { litModalEventTitle.Text = ""; }

            var list = LoadPendingForEvent(ModalEventId);
            rptPending.DataSource = list;
            rptPending.DataBind();
            phModalEmpty.Visible = list.Count == 0;

            litModalPending.Text = list.Count.ToString();
            litModalTotalFoot.Text = list.Count.ToString();

            btnApproveAll.Visible = list.Count > 0;
            btnRejectAll.Visible = list.Count > 0;
        }

        protected void btnCloseModal_Click(object sender, EventArgs e)
        {
            pnlModal.Visible = false;
            ModalEventId = 0;
        }

        private List<PendingRegVM> LoadPendingForEvent(long eventId)
        {
            var list = new List<PendingRegVM>();
            try
            {
                const string sql = @"
                    SELECT r.id, r.registered_at,
                           u.first_name + N' ' + u.last_name AS full_name,
                           u.email,
                           ISNULL(d.name, N'(Không phòng ban)') AS dept_name
                    FROM dbo.event_registrations r
                    JOIN dbo.users u ON u.id = r.user_id
                    LEFT JOIN dbo.departments d ON d.id = u.department_id
                    WHERE r.event_id = @eid AND r.status = N'pending'
                    ORDER BY r.registered_at;";

                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@eid", eventId);
                    using (var rd = cmd.ExecuteReader())
                    {
                        int i = 0;
                        while (rd.Read())
                        {
                            var name = rd["full_name"].ToString().Trim();
                            var regAt = Convert.ToDateTime(rd["registered_at"]);
                            list.Add(new PendingRegVM
                            {
                                Id = Convert.ToInt64(rd["id"]),
                                FullName = name,
                                Email = rd["email"].ToString(),
                                Department = rd["dept_name"].ToString(),
                                RegisteredAt = regAt,
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
                System.Diagnostics.Debug.WriteLine("LoadPendingForEvent error: " + ex.Message);
            }
            return list;
        }

        #endregion

        #region Approve / Reject

        protected void rptPending_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            long regId;
            if (!long.TryParse((e.CommandArgument ?? "").ToString(), out regId)) return;

            if (e.CommandName == "ApproveOne")
                UpdateRegStatus(regId, "approved");
            else if (e.CommandName == "RejectOne")
                UpdateRegStatus(regId, "rejected");

            LoadStats();
            LoadEvents();
            OpenModal();
        }

        protected void btnApproveAll_Click(object sender, EventArgs e)
        {
            BulkUpdate("approved");
            LoadStats();
            LoadEvents();
            OpenModal();
            ShowAlert("Đã duyệt tất cả yêu cầu chờ cho sự kiện này.", isError: false);
        }

        protected void btnRejectAll_Click(object sender, EventArgs e)
        {
            BulkUpdate("rejected");
            LoadStats();
            LoadEvents();
            OpenModal();
            ShowAlert("Đã từ chối tất cả yêu cầu chờ cho sự kiện này.", isError: false);
        }

        private void UpdateRegStatus(long regId, string newStatus)
        {
            var user = AuthHelper.CurrentUser(Session);
            long actorId = user != null ? user.Id : 0;

            try
            {
                string sql;
                if (newStatus == "approved")
                {
                    sql = @"UPDATE dbo.event_registrations
                            SET status = N'approved',
                                approved_at = SYSUTCDATETIME(),
                                approved_by = @uid,
                                rejected_at = NULL, rejected_by = NULL
                            WHERE id = @rid AND status = N'pending';";
                }
                else
                {
                    sql = @"UPDATE dbo.event_registrations
                            SET status = N'rejected',
                                rejected_at = SYSUTCDATETIME(),
                                rejected_by = @uid,
                                approved_at = NULL, approved_by = NULL
                            WHERE id = @rid AND status = N'pending';";
                }

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
                ShowAlert("Lỗi cập nhật: " + ex.Message, isError: true);
            }
        }

        private void BulkUpdate(string newStatus)
        {
            if (ModalEventId <= 0) return;
            var user = AuthHelper.CurrentUser(Session);
            long actorId = user != null ? user.Id : 0;

            try
            {
                string sql;
                if (newStatus == "approved")
                {
                    sql = @"UPDATE dbo.event_registrations
                            SET status = N'approved',
                                approved_at = SYSUTCDATETIME(),
                                approved_by = @uid
                            WHERE event_id = @eid AND status = N'pending';";
                }
                else
                {
                    sql = @"UPDATE dbo.event_registrations
                            SET status = N'rejected',
                                rejected_at = SYSUTCDATETIME(),
                                rejected_by = @uid
                            WHERE event_id = @eid AND status = N'pending';";
                }

                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@eid", ModalEventId);
                    cmd.Parameters.AddWithValue("@uid", actorId > 0 ? (object)actorId : DBNull.Value);
                    cmd.ExecuteNonQuery();
                }

                if (actorId > 0)
                    AuthHelper.LogActivity(actorId, "registration.bulk_" + newStatus,
                        Request.UserHostAddress, Request.UserAgent);
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi cập nhật hàng loạt: " + ex.Message, isError: true);
            }
        }

        #endregion

        #region Search

        protected void txtSearch_TextChanged(object sender, EventArgs e)
        {
            Keyword = (txtSearch.Text ?? "").Trim();
            LoadEvents();
        }

        #endregion

        #region Helpers

        private static string BuildDeadlineText(DateTime? deadline, DateTime startAt)
        {
            var dl = deadline ?? startAt;
            var diff = dl - DateTime.Now;
            if (diff.TotalSeconds <= 0) return "Đã hết hạn";
            if (diff.TotalDays >= 1)
            {
                int days = (int)Math.Floor(diff.TotalDays);
                int hours = diff.Hours;
                return "Hạn ĐK: còn " + days + " ngày" + (hours > 0 ? " " + hours + " giờ" : "");
            }
            return "Hạn ĐK: còn " + (int)diff.TotalHours + " giờ";
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

        private bool IsValidConfirmCode(string code)
        {
            if (string.IsNullOrEmpty(code)) return false;

            return System.Text.RegularExpressions.Regex.IsMatch(
                code,
                @"^(?=(?:.*[A-Z]){3})(?=(?:.*\d){2})[A-Z\d]{5}@$"
            );
        }

        protected void btnThemMa_Click(object sender, EventArgs e)
        {
            string code = txtMaXacNhan.Text.Trim().ToUpper();

            if (!IsValidConfirmCode(code))
            {
                pnlMaAlert.Visible = true;
                litMaAlert.Text = "Mã xác nhận không hợp lệ!";
                return;
            }

            List<ConfirmCodeItem> list = Session["ConfirmCodes"] as List<ConfirmCodeItem>;
            if (list == null)
            {
                list = new List<ConfirmCodeItem>();
            }

            list.Add(new ConfirmCodeItem
            {
                Id = list.Count == 0 ? 1 : list.Max(x => x.Id) + 1,
                MaXacNhan = code
            });

            Session["ConfirmCodes"] = list;

            txtMaXacNhan.Text = "";
            pnlMaAlert.Visible = true;
            litMaAlert.Text = "Thêm mã thành công!";

            BindConfirmList();
        }

        private void BindConfirmList()
        {
            var list = Session["ConfirmCodes"] as List<ConfirmCodeItem>;
            if (list == null) list = new List<ConfirmCodeItem>();

            rptMaXacNhan.DataSource = list.Where(x => !x.IsHidden).ToList();
            rptMaXacNhan.DataBind();
        }

        protected void rptMaXacNhan_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "Hide")
            {
                int id = Convert.ToInt32(e.CommandArgument);

                var list = Session["ConfirmCodes"] as List<ConfirmCodeItem>;
                if (list != null)
                {
                    var item = list.FirstOrDefault(x => x.Id == id);
                    if (item != null)
                    {
                        item.IsHidden = true;
                        Session["ConfirmCodes"] = list;
                    }
                }

                BindConfirmList();
            }
        }

        public class ConfirmCodeItem
        {
            public int Id { get; set; }
            public string MaXacNhan { get; set; }
            public bool IsHidden { get; set; } = false;

        }
    }
}