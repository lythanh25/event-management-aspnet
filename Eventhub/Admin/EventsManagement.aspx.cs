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
    public partial class eventsmanagement : System.Web.UI.Page
    {
        #region ViewModel

        public class EventRow
        {
            public long Id { get; set; }
            public string EventCode { get; set; }
            public string Title { get; set; }
            public string Subtitle { get; set; }
            public DateTime StartAt { get; set; }
            public int Capacity { get; set; }
            public int ApprovedCount { get; set; }
            public string Status { get; set; }         
            public string StatusText { get; set; }     
            public string CategoryCode { get; set; }
            public string CategoryName { get; set; }
            public string CategoryClass { get; set; }  
            public string IconClass { get; set; }      
            public string DepartmentName { get; set; }

            public int SlotPercent
            {
                get
                {
                    if (Capacity <= 0) return 0;
                    int p = (int)Math.Round(ApprovedCount * 100.0 / Capacity);
                    return Math.Min(p, 100);
                }
            }

            public string SlotBarClass
            {
                get
                {
                    int p = SlotPercent;
                    if (p >= 85) return "red";
                    if (p >= 70) return "amber";
                    return "green";
                }
            }
        }

        public class PagerItem
        {
            public int Page { get; set; }
            public bool IsActive { get; set; }
        }

        #endregion

        #region State (lưu vào ViewState)

        private string CurrentStatus
        {
            get { return (ViewState["status"] as string) ?? ""; }
            set { ViewState["status"] = value ?? ""; }
        }

        private string Keyword
        {
            get { return (ViewState["kw"] as string) ?? ""; }
            set { ViewState["kw"] = value ?? ""; }
        }

        private long CategoryId
        {
            get { return (long)(ViewState["cat"] ?? 0L); }
            set { ViewState["cat"] = value; }
        }

        private int MonthFilter
        {
            get { return (int)(ViewState["mo"] ?? 0); }
            set { ViewState["mo"] = value; }
        }

        private long DepartmentId
        {
            get { return (long)(ViewState["dept"] ?? 0L); }
            set { ViewState["dept"] = value; }
        }

        private int CurrentPage
        {
            get { return (int)(ViewState["pg"] ?? 1); }
            set { ViewState["pg"] = value < 1 ? 1 : value; }
        }

        private int PageSize
        {
            get { return (int)(ViewState["ps"] ?? 10); }
            set { ViewState["ps"] = value <= 0 ? 10 : value; }
        }

        #endregion

        protected void Page_Load(object sender, EventArgs e)
        {
            var master = Master as Eventhub.AdminMaster;
            if (master != null) master.Breadcrumb = "Quản lý Sự kiện";

            if (!IsPostBack)
            {
                CurrentStatus = Request.QueryString["status"] ?? "";

                LoadCategoryDropDown();
                LoadDepartmentDropDown();
                LoadCounts();
                LoadEvents();
            }

            SetTabUrls();
            SetActiveTabClass();
        }

        private void SetTabUrls()
        {
            tabAll.NavigateUrl = "~/Admin/EventsManagement.aspx";
            tabOpen.NavigateUrl = "~/Admin/EventsManagement.aspx?status=open";
            tabClosed.NavigateUrl = "~/Admin/EventsManagement.aspx?status=closed";
            tabEnded.NavigateUrl = "~/Admin/EventsManagement.aspx?status=ended";
            tabDraft.NavigateUrl = "~/Admin/EventsManagement.aspx?status=draft";
        }

        #region Load dropdowns

        private void LoadCategoryDropDown()
        {
            ddlCategory.Items.Clear();
            ddlCategory.Items.Add(new ListItem("Chủ đề: Tất cả", "0"));

            try
            {
                const string sql = @"
                    SELECT id, name FROM dbo.event_categories
                    WHERE is_active = 1 ORDER BY sort_order, name;";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                using (var rd = cmd.ExecuteReader())
                {
                    while (rd.Read())
                    {
                        ddlCategory.Items.Add(new ListItem(
                            rd["name"].ToString(),
                            Convert.ToInt64(rd["id"]).ToString()));
                    }
                }
            }
            catch {  }
        }

        private void LoadDepartmentDropDown()
        {
            ddlDepartment.Items.Clear();
            ddlDepartment.Items.Add(new ListItem("Ban tổ chức: Tất cả", "0"));

            try
            {
                const string sql = @"
                    SELECT id, name FROM dbo.departments
                    WHERE is_active = 1 ORDER BY name;";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
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
            catch { }
        }

        #endregion

        #region Count cho stat tabs

        private void LoadCounts()
        {
            int cAll = 0, cOpen = 0, cClosed = 0, cEnded = 0, cDraft = 0;

            try
            {
                const string sql = @"
                    SELECT status, COUNT(*) AS c
                    FROM dbo.events
                    WHERE deleted_at IS NULL
                    GROUP BY status;";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                using (var rd = cmd.ExecuteReader())
                {
                    while (rd.Read())
                    {
                        var st = rd["status"].ToString();
                        var c = Convert.ToInt32(rd["c"]);
                        cAll += c;
                        switch (st)
                        {
                            case "open": cOpen = c; break;
                            case "closed": cClosed = c; break;
                            case "ended": cEnded = c; break;
                            case "draft": cDraft = c; break;
                        }
                    }
                }
            }
            catch { }

            litCntAll.Text = cAll.ToString();
            litCntOpen.Text = cOpen.ToString();
            litCntClosed.Text = cClosed.ToString();
            litCntEnded.Text = cEnded.ToString();
            litCntDraft.Text = cDraft.ToString();
            litTotalCount.Text = cAll.ToString();
            litUpdatedAt.Text = DateTime.Now.ToString("HH:mm, dd/MM/yyyy");
        }

        #endregion

        #region Load danh sách sự kiện (filter + paging)

        private void LoadEvents()
        {
            var sql = new StringBuilder();
            sql.AppendLine(@"
                ;WITH e_paged AS (
                    SELECT
                        e.id, e.event_code, e.title, e.subtitle, e.start_at,
                        e.capacity, e.status,
                        c.code      AS category_code,
                        c.name      AS category_name,
                        d.name      AS department_name,
                        ISNULL(s.approved_count, 0) AS approved_count,
                        ROW_NUMBER() OVER (ORDER BY e.start_at DESC, e.id DESC) AS rn,
                        COUNT(*) OVER () AS total_rows
                    FROM dbo.events e
                    INNER JOIN dbo.event_categories c ON c.id = e.category_id
                    INNER JOIN dbo.departments      d ON d.id = e.organizer_department_id
                    LEFT  JOIN dbo.v_event_registration_stats s ON s.event_id = e.id
                    WHERE e.deleted_at IS NULL");

            if (!string.IsNullOrEmpty(CurrentStatus))
                sql.AppendLine(" AND e.status = @status");

            if (CategoryId > 0)
                sql.AppendLine(" AND e.category_id = @catId");

            if (DepartmentId > 0)
                sql.AppendLine(" AND e.organizer_department_id = @deptId");

            if (MonthFilter >= 1 && MonthFilter <= 12)
                sql.AppendLine(" AND MONTH(e.start_at) = @mo");

            if (!string.IsNullOrEmpty(Keyword))
                sql.AppendLine(@" AND (
                        e.title       LIKE @kw OR
                        e.event_code  LIKE @kw OR
                        d.name        LIKE @kw OR
                        e.subtitle    LIKE @kw )");

            sql.AppendLine(@"
                )
                SELECT * FROM e_paged
                WHERE rn BETWEEN @rnFrom AND @rnTo
                ORDER BY rn;");

            int rnFrom = (CurrentPage - 1) * PageSize + 1;
            int rnTo = CurrentPage * PageSize;

            var list = new List<EventRow>();
            int totalRows = 0;

            try
            {
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql.ToString(), con))
                {
                    if (!string.IsNullOrEmpty(CurrentStatus))
                        cmd.Parameters.AddWithValue("@status", CurrentStatus);
                    if (CategoryId > 0)
                        cmd.Parameters.AddWithValue("@catId", CategoryId);
                    if (DepartmentId > 0)
                        cmd.Parameters.AddWithValue("@deptId", DepartmentId);
                    if (MonthFilter >= 1 && MonthFilter <= 12)
                        cmd.Parameters.AddWithValue("@mo", MonthFilter);
                    if (!string.IsNullOrEmpty(Keyword))
                        cmd.Parameters.AddWithValue("@kw", "%" + Keyword + "%");

                    cmd.Parameters.AddWithValue("@rnFrom", rnFrom);
                    cmd.Parameters.AddWithValue("@rnTo", rnTo);

                    using (var rd = cmd.ExecuteReader())
                    {
                        while (rd.Read())
                        {
                            if (totalRows == 0)
                                totalRows = Convert.ToInt32(rd["total_rows"]);

                            var row = new EventRow
                            {
                                Id = Convert.ToInt64(rd["id"]),
                                EventCode = rd["event_code"].ToString(),
                                Title = rd["title"].ToString(),
                                Subtitle = rd["subtitle"] == DBNull.Value ? "" : rd["subtitle"].ToString(),
                                StartAt = Convert.ToDateTime(rd["start_at"]),
                                Capacity = Convert.ToInt32(rd["capacity"]),
                                ApprovedCount = Convert.ToInt32(rd["approved_count"]),
                                Status = rd["status"].ToString(),
                                CategoryCode = rd["category_code"].ToString(),
                                CategoryName = rd["category_name"].ToString(),
                                DepartmentName = rd["department_name"].ToString(),
                            };
                            row.StatusText = MapStatusText(row.Status);
                            row.CategoryClass = MapCategoryClass(row.CategoryCode);
                            row.IconClass = MapIconClass(row.CategoryCode);

                            list.Add(row);
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

            phEmpty.Visible = (list.Count == 0);

            BuildPager(totalRows);
        }

        private void BuildPager(int totalRows)
        {
            int totalPages = totalRows == 0 ? 1 : (int)Math.Ceiling(totalRows / (double)PageSize);
            if (CurrentPage > totalPages) CurrentPage = totalPages;

            int from = totalRows == 0 ? 0 : (CurrentPage - 1) * PageSize + 1;
            int to = Math.Min(CurrentPage * PageSize, totalRows);

            litFromTo.Text = from + "–" + to;
            litTotal.Text = totalRows.ToString();

            int windowStart = Math.Max(1, CurrentPage - 2);
            int windowEnd = Math.Min(totalPages, windowStart + 4);
            windowStart = Math.Max(1, windowEnd - 4);

            var pager = new List<PagerItem>();
            for (int p = windowStart; p <= windowEnd; p++)
                pager.Add(new PagerItem { Page = p, IsActive = (p == CurrentPage) });

            rptPager.DataSource = pager;
            rptPager.DataBind();

            btnPrev.Enabled = CurrentPage > 1;
            btnNext.Enabled = CurrentPage < totalPages;
        }

        #endregion

        #region Mapping hiển thị

        private static string MapStatusText(string status)
        {
            switch (status)
            {
                case "open": return "Mở đăng ký";
                case "closed": return "Đóng đăng ký";
                case "ended": return "Đã kết thúc";
                case "draft": return "Bản nháp";
                case "cancelled": return "Đã huỷ";
                default: return status;
            }
        }

        private static string MapCategoryClass(string code)
        {
            switch (code)
            {
                case "tech": return "tech";
                case "workshop": return "train";
                case "conference": return "train";
                case "training": return "train";
                case "team_building": return "event";
                case "anniversary": return "event";
                case "culture": return "culture";
                case "hr": return "hr";
                default: return "";
            }
        }

        private static string MapIconClass(string code)
        {
            switch (code)
            {
                case "tech": return "ic-tech-1";
                case "workshop": return "ic-mic";
                case "conference": return "ic-sem";
                case "training": return "ic-excel";
                case "team_building": return "ic-team";
                case "anniversary": return "ic-celeb";
                case "culture": return "ic-book";
                case "hr": return "ic-hr";
                default: return "ic-tech-2";
            }
        }

        #endregion

        #region Event handlers

        private void SetActiveTabClass()
        {
            tabAll.CssClass = "stat-tab" + (CurrentStatus == "" ? " active" : "");
            tabOpen.CssClass = "stat-tab" + (CurrentStatus == "open" ? " active" : "");
            tabClosed.CssClass = "stat-tab" + (CurrentStatus == "closed" ? " active" : "");
            tabEnded.CssClass = "stat-tab" + (CurrentStatus == "ended" ? " active" : "");
            tabDraft.CssClass = "stat-tab" + (CurrentStatus == "draft" ? " active" : "");
        }

        protected void Filter_Changed(object sender, EventArgs e)
        {
            ApplyFiltersFromUI();
            CurrentPage = 1;
            LoadEvents();
        }

        protected void btnSearch_Click(object sender, EventArgs e)
        {
            ApplyFiltersFromUI();
            CurrentPage = 1;
            LoadEvents();
        }

        private void ApplyFiltersFromUI()
        {
            Keyword = (txtKeyword.Text ?? "").Trim();

            long catId; long.TryParse(ddlCategory.SelectedValue, out catId);
            CategoryId = catId;

            long deptId; long.TryParse(ddlDepartment.SelectedValue, out deptId);
            DepartmentId = deptId;

            int mo; int.TryParse(ddlMonth.SelectedValue, out mo);
            MonthFilter = mo;
        }

        protected void btnClearFilter_Click(object sender, EventArgs e)
        {
            txtKeyword.Text = "";
            ddlCategory.SelectedIndex = 0;
            ddlDepartment.SelectedIndex = 0;
            ddlMonth.SelectedIndex = 0;

            CurrentStatus = "";
            Keyword = "";
            CategoryId = 0;
            DepartmentId = 0;
            MonthFilter = 0;
            CurrentPage = 1;

            Response.Redirect("~/Admin/EventsManagement.aspx");
        }

        protected void rptEvents_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "DeleteEvent")
            {
                long id;
                if (long.TryParse(e.CommandArgument.ToString(), out id))
                {
                    DeleteEvent(id);
                    LoadCounts();
                    LoadEvents();
                }
            }
        }

        private static void DeleteEvent(long id)
        {
            try
            {
                const string sql = @"
                    UPDATE dbo.events
                    SET deleted_at = SYSUTCDATETIME(), updated_at = SYSUTCDATETIME()
                    WHERE id = @id AND deleted_at IS NULL;";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    cmd.ExecuteNonQuery();
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine("DeleteEvent error: " + ex.Message);
            }
        }

        protected void rptPager_ItemCommand(object source, RepeaterCommandEventArgs e)
        {
            if (e.CommandName == "GoPage")
            {
                int p;
                if (int.TryParse(e.CommandArgument.ToString(), out p))
                {
                    CurrentPage = p;
                    LoadEvents();
                }
            }
        }

        protected void btnPrev_Click(object sender, EventArgs e)
        {
            if (CurrentPage > 1)
            {
                CurrentPage--;
                LoadEvents();
            }
        }

        protected void btnNext_Click(object sender, EventArgs e)
        {
            CurrentPage++;
            LoadEvents();
        }

        protected void ddlPageSize_Changed(object sender, EventArgs e)
        {
            int ps;
            if (int.TryParse(ddlPageSize.SelectedValue, out ps))
            {
                PageSize = ps;
                CurrentPage = 1;
                LoadEvents();
            }
        }

        #endregion
    }
}