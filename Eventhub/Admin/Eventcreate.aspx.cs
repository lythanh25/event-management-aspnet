using Eventhub.App_Code;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Eventhub.Admin
{
    public partial class eventcreate : System.Web.UI.Page
    {
        #region Properties

        private long EventId
        {
            get
            {
                long id;
                long.TryParse(hfEventId.Value, out id);
                return id;
            }
            set { hfEventId.Value = value.ToString(); }
        }

        private bool IsEdit => EventId > 0;

        #endregion

        #region Page_Load

        protected void Page_Load(object sender, EventArgs e)
        {
            var master = Master as Eventhub.AdminMaster;
            if (master != null)
                master.Breadcrumb = IsEditUrl() ? "Chỉnh sửa sự kiện" : "Tạo sự kiện mới";

            if (!IsPostBack)
            {
                long qsId;
                if (long.TryParse(Request.QueryString["id"], out qsId) && qsId > 0)
                    EventId = qsId;

                LoadCategories();
                LoadDepartments();

                if (IsEdit)
                {
                    LoadEventForEdit(EventId);
                    litHeading.Text = "Chỉnh sửa ";
                    litHeadingEm.Text = "sự kiện";
                    litPageTitle.Text = "Chỉnh sửa sự kiện — EventHub Admin";
                    btnPublish.Text = btnPublishTop.Text = "Cập nhật & Đăng";
                }
                else
                {
                    txtStartDate.Text = DateTime.Now.Date.AddDays(7).ToString("yyyy-MM-dd");
                    txtStartTime.Text = "08:30";
                    txtEndDate.Text = DateTime.Now.Date.AddDays(7).ToString("yyyy-MM-dd");
                    txtEndTime.Text = "17:00";
                    txtDeadline.Text = DateTime.Now.Date.AddDays(5).ToString("yyyy-MM-dd");
                    txtCapacity.Text = "100";
                }
            }
        }

        private bool IsEditUrl()
        {
            long id;
            return long.TryParse(Request.QueryString["id"], out id) && id > 0;
        }

        #endregion

        #region Load dropdowns

        private void LoadCategories()
        {
            ddlCategory.Items.Clear();
            ddlCategory.Items.Add(new ListItem("— Chọn chủ đề —", "0"));

            try
            {
                const string sql = @"SELECT id, name FROM dbo.event_categories
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
            catch (Exception ex)
            {
                ShowAlert("Lỗi tải danh mục: " + ex.Message, isError: true);
            }
        }

        private void LoadDepartments()
        {
            ddlDepartment.Items.Clear();
            ddlDepartment.Items.Add(new ListItem("— Chọn ban tổ chức —", "0"));

            try
            {
                const string sql = @"SELECT id, name FROM dbo.departments
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
            catch (Exception ex)
            {
                ShowAlert("Lỗi tải ban tổ chức: " + ex.Message, isError: true);
            }
        }

        #endregion

        #region Load Event (Edit mode)

        private void LoadEventForEdit(long id)
        {
            try
            {
                const string sql = @"
                    SELECT e.*, 
                           (SELECT STRING_AGG(t.name, ', ')
                            FROM dbo.event_event_tags et
                            JOIN dbo.event_tags t ON t.id = et.tag_id
                            WHERE et.event_id = e.id) AS tag_list
                    FROM dbo.events e
                    WHERE e.id = @id AND e.deleted_at IS NULL;";

                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    cmd.Parameters.AddWithValue("@id", id);
                    using (var rd = cmd.ExecuteReader())
                    {
                        if (!rd.Read())
                        {
                            ShowAlert("Không tìm thấy sự kiện này.", isError: true);
                            Response.Redirect("~/Admin/EventsManagement.aspx");
                            return;
                        }

                        litEventCode.Text = rd["event_code"].ToString();
                        txtTitle.Text = rd["title"].ToString();
                        txtSubtitle.Text = rd["subtitle"] as string ?? "";
                        txtDescription.Text = rd["description"] as string ?? "";

                        SetDropDownValue(ddlCategory, Convert.ToInt64(rd["category_id"]).ToString());
                        SetDropDownValue(ddlFormat, rd["format"].ToString());
                        SetDropDownValue(ddlDepartment, Convert.ToInt64(rd["organizer_department_id"]).ToString());

                        var startAt = Convert.ToDateTime(rd["start_at"]);
                        var endAt = Convert.ToDateTime(rd["end_at"]);
                        txtStartDate.Text = startAt.ToString("yyyy-MM-dd");
                        txtStartTime.Text = startAt.ToString("HH:mm");
                        txtEndDate.Text = endAt.ToString("yyyy-MM-dd");
                        txtEndTime.Text = endAt.ToString("HH:mm");

                        if (rd["registration_deadline"] != DBNull.Value)
                            txtDeadline.Text = Convert.ToDateTime(rd["registration_deadline"]).ToString("yyyy-MM-dd");

                        txtLocation.Text = rd["location_name"] as string ?? "";
                        txtRoom.Text = rd["location_room"] as string ?? "";
                        txtAddress.Text = rd["address"] as string ?? "";
                        txtOnlineUrl.Text = rd["online_url"] as string ?? "";
                        txtCapacity.Text = rd["capacity"].ToString();

                        var bannerUrl = rd["banner_url"] as string;
                        if (!string.IsNullOrEmpty(bannerUrl))
                        {
                            hfBannerUrl.Value = bannerUrl;
                            imgBanner.ImageUrl = bannerUrl;
                            imgBanner.Visible = true;
                            litBannerTag.Text = Path.GetFileName(bannerUrl);
                        }

                        cbRequireApproval.Checked = Convert.ToBoolean(rd["requires_approval"]);
                        cbAllowWaitlist.Checked = Convert.ToBoolean(rd["allow_waitlist"]);
                        cbOpenAll.Checked = Convert.ToBoolean(rd["is_open_to_all_departments"]);

                        var status = rd["status"].ToString();
                        litStatusLabel.Text = MapStatus(status);

                        txtTags.Text = rd["tag_list"] as string ?? "";
                    }
                }
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi khi tải dữ liệu: " + ex.Message, isError: true);
            }
        }

        private static void SetDropDownValue(DropDownList ddl, string value)
        {
            var item = ddl.Items.FindByValue(value);
            if (item != null)
            {
                ddl.ClearSelection();
                item.Selected = true;
            }
        }

        private static string MapStatus(string s)
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

        #endregion

        #region Save handlers

        protected void btnSaveDraft_Click(object sender, EventArgs e)
        {
            SaveEvent(publish: false);
        }

        protected void btnPublish_Click(object sender, EventArgs e)
        {
            Page.Validate();
            if (!Page.IsValid)
            {
                ShowAlert("Vui lòng kiểm tra lại các trường bắt buộc.", isError: true);
                return;
            }
            SaveEvent(publish: true);
        }

        private void SaveEvent(bool publish)
        {
            string title = (txtTitle.Text ?? "").Trim();
            if (string.IsNullOrEmpty(title))
            {
                ShowAlert("Tên sự kiện không được để trống.", isError: true);
                return;
            }

            long categoryId;
            if (!long.TryParse(ddlCategory.SelectedValue, out categoryId) || categoryId <= 0)
            {
                if (publish)
                {
                    ShowAlert("Vui lòng chọn chủ đề sự kiện.", isError: true);
                    return;
                }
            }

            long departmentId;
            if (!long.TryParse(ddlDepartment.SelectedValue, out departmentId) || departmentId <= 0)
            {
                if (publish)
                {
                    ShowAlert("Vui lòng chọn ban tổ chức.", isError: true);
                    return;
                }
            }

            DateTime startAt, endAt;
            if (!TryBuildDateTime(txtStartDate.Text, txtStartTime.Text, out startAt))
            {
                if (publish)
                {
                    ShowAlert("Thời gian bắt đầu không hợp lệ.", isError: true);
                    return;
                }
                startAt = DateTime.Now.AddDays(7);
            }
            if (!TryBuildDateTime(txtEndDate.Text, txtEndTime.Text, out endAt))
            {
                if (publish)
                {
                    ShowAlert("Thời gian kết thúc không hợp lệ.", isError: true);
                    return;
                }
                endAt = startAt.AddHours(2);
            }
            if (endAt <= startAt)
            {
                ShowAlert("Thời gian kết thúc phải sau thời gian bắt đầu.", isError: true);
                return;
            }

            int capacity;
            if (!int.TryParse(txtCapacity.Text, out capacity) || capacity <= 0)
            {
                ShowAlert("Số người tham gia phải là số dương.", isError: true);
                return;
            }

            DateTime? deadline = null;
            DateTime dl;
            if (DateTime.TryParse(txtDeadline.Text, out dl)) deadline = dl;

            string format = ddlFormat.SelectedValue;
            if (string.IsNullOrEmpty(format)) format = "offline";

            string bannerUrl = hfBannerUrl.Value;
            if (fuBanner.HasFile)
            {
                var newUrl = SaveBanner(fuBanner);
                if (newUrl != null) bannerUrl = newUrl;
            }

            var user = AuthHelper.CurrentUser(Session);
            long createdBy = user != null ? user.Id : 0;
            if (createdBy <= 0)
            {
                ShowAlert("Không xác định được người tạo. Vui lòng đăng nhập lại.", isError: true);
                return;
            }

            try
            {
                long savedId;
                using (var con = Database.OpenConnection())
                using (var tx = con.BeginTransaction())
                {
                    try
                    {
                        if (IsEdit)
                        {
                            UpdateEventCore(con, tx, EventId, title, format, categoryId, departmentId,
                                startAt, endAt, deadline, capacity, bannerUrl, publish);
                            savedId = EventId;
                        }
                        else
                        {
                            savedId = InsertEventCore(con, tx, title, format, categoryId, departmentId,
                                createdBy, startAt, endAt, deadline, capacity, bannerUrl, publish);
                            EventId = savedId;
                        }

                        ReplaceEventTags(con, tx, savedId, ParseTags(txtTags.Text));

                        tx.Commit();
                    }
                    catch
                    {
                        tx.Rollback();
                        throw;
                    }
                }

                AuthHelper.LogActivity(createdBy,
                    IsEdit ? "event.update" : "event.create",
                    Request.UserHostAddress, Request.UserAgent);

                Response.Redirect("~/Admin/EventsManagement.aspx?saved=" + savedId, false);
                Context.ApplicationInstance.CompleteRequest();
            }
            catch (SqlException ex) when (ex.Number == 2627 || ex.Number == 2601) 
            {
                ShowAlert("Mã sự kiện hoặc slug đã tồn tại. Vui lòng thử lại.", isError: true);
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi khi lưu: " + ex.Message, isError: true);
            }
        }

        #endregion

        #region INSERT / UPDATE core

        private long InsertEventCore(SqlConnection con, SqlTransaction tx,
            string title, string format, long categoryId, long departmentId, long createdBy,
            DateTime startAt, DateTime endAt, DateTime? deadline,
            int capacity, string bannerUrl, bool publish)
        {
            string code = GenerateEventCode(con, tx);
            string slug = GenerateSlug(title) + "-" + DateTime.Now.Ticks;
            string status = publish ? "open" : "draft";

            if (categoryId <= 0)
                categoryId = GetFirstId(con, tx, "dbo.event_categories");
            if (departmentId <= 0)
                departmentId = GetFirstId(con, tx, "dbo.departments");

            const string sql = @"
                INSERT INTO dbo.events
                    (event_code, slug, title, subtitle, description,
                     category_id, format,
                     start_at, end_at, registration_deadline,
                     location_name, location_room, address, online_url,
                     capacity, organizer_department_id, created_by,
                     requires_approval, allow_waitlist, is_open_to_all_departments,
                     banner_url, status, published_at)
                OUTPUT INSERTED.id
                VALUES
                    (@code, @slug, @title, @subtitle, @description,
                     @categoryId, @format,
                     @startAt, @endAt, @deadline,
                     @loc, @room, @addr, @url,
                     @capacity, @deptId, @createdBy,
                     @reqAppr, @waitlist, @openAll,
                     @banner, @status, @publishedAt);";

            using (var cmd = new SqlCommand(sql, con, tx))
            {
                AddCommonParams(cmd, code, slug, title, format, categoryId, departmentId,
                    startAt, endAt, deadline, capacity, bannerUrl, publish);

                cmd.Parameters.AddWithValue("@createdBy", createdBy);
                cmd.Parameters.AddWithValue("@status", status);
                cmd.Parameters.AddWithValue("@publishedAt",
                    publish ? (object)DateTime.UtcNow : DBNull.Value);

                var idObj = cmd.ExecuteScalar();
                return Convert.ToInt64(idObj);
            }
        }

        private void UpdateEventCore(SqlConnection con, SqlTransaction tx, long id,
            string title, string format, long categoryId, long departmentId,
            DateTime startAt, DateTime endAt, DateTime? deadline,
            int capacity, string bannerUrl, bool publish)
        {
            if (categoryId <= 0)
                categoryId = GetFirstId(con, tx, "dbo.event_categories");
            if (departmentId <= 0)
                departmentId = GetFirstId(con, tx, "dbo.departments");

            const string sql = @"
                UPDATE dbo.events SET
                    title           = @title,
                    subtitle        = @subtitle,
                    description     = @description,
                    category_id     = @categoryId,
                    format          = @format,
                    start_at        = @startAt,
                    end_at          = @endAt,
                    registration_deadline = @deadline,
                    location_name   = @loc,
                    location_room   = @room,
                    address         = @addr,
                    online_url      = @url,
                    capacity        = @capacity,
                    organizer_department_id = @deptId,
                    requires_approval = @reqAppr,
                    allow_waitlist  = @waitlist,
                    is_open_to_all_departments = @openAll,
                    banner_url      = @banner,
                    status          = CASE
                                        WHEN @publish = 1 AND status = N'draft' THEN N'open'
                                        WHEN @publish = 1 THEN status
                                        WHEN @publish = 0 AND status = N'open' THEN N'open'
                                        ELSE status
                                      END,
                    published_at    = CASE
                                        WHEN @publish = 1 AND published_at IS NULL THEN SYSUTCDATETIME()
                                        ELSE published_at
                                      END
                WHERE id = @id AND deleted_at IS NULL;";

            using (var cmd = new SqlCommand(sql, con, tx))
            {
                AddCommonParams(cmd, null, null, title, format, categoryId, departmentId,
                    startAt, endAt, deadline, capacity, bannerUrl, publish);

                cmd.Parameters.AddWithValue("@id", id);
                cmd.Parameters.AddWithValue("@publish", publish ? 1 : 0);
                cmd.ExecuteNonQuery();
            }
        }

        private void AddCommonParams(SqlCommand cmd, string code, string slug,
            string title, string format, long categoryId, long departmentId,
            DateTime startAt, DateTime endAt, DateTime? deadline,
            int capacity, string bannerUrl, bool publish)
        {
            if (code != null) cmd.Parameters.AddWithValue("@code", code);
            if (slug != null) cmd.Parameters.AddWithValue("@slug", slug);

            cmd.Parameters.AddWithValue("@title", title);
            cmd.Parameters.AddWithValue("@subtitle",
                string.IsNullOrEmpty(txtSubtitle.Text) ? (object)DBNull.Value : txtSubtitle.Text.Trim());
            cmd.Parameters.AddWithValue("@description",
                string.IsNullOrEmpty(txtDescription.Text) ? (object)DBNull.Value : txtDescription.Text);

            cmd.Parameters.AddWithValue("@categoryId", categoryId);
            cmd.Parameters.AddWithValue("@format", format);
            cmd.Parameters.AddWithValue("@startAt", startAt);
            cmd.Parameters.AddWithValue("@endAt", endAt);
            cmd.Parameters.AddWithValue("@deadline", deadline.HasValue ? (object)deadline.Value : DBNull.Value);

            cmd.Parameters.AddWithValue("@loc",
                string.IsNullOrEmpty(txtLocation.Text) ? (object)DBNull.Value : txtLocation.Text.Trim());
            cmd.Parameters.AddWithValue("@room",
                string.IsNullOrEmpty(txtRoom.Text) ? (object)DBNull.Value : txtRoom.Text.Trim());
            cmd.Parameters.AddWithValue("@addr",
                string.IsNullOrEmpty(txtAddress.Text) ? (object)DBNull.Value : txtAddress.Text.Trim());
            cmd.Parameters.AddWithValue("@url",
                string.IsNullOrEmpty(txtOnlineUrl.Text) ? (object)DBNull.Value : txtOnlineUrl.Text.Trim());

            cmd.Parameters.AddWithValue("@capacity", capacity);
            cmd.Parameters.AddWithValue("@deptId", departmentId);

            cmd.Parameters.AddWithValue("@reqAppr", cbRequireApproval.Checked ? 1 : 0);
            cmd.Parameters.AddWithValue("@waitlist", cbAllowWaitlist.Checked ? 1 : 0);
            cmd.Parameters.AddWithValue("@openAll", cbOpenAll.Checked ? 1 : 0);

            cmd.Parameters.AddWithValue("@banner",
                string.IsNullOrEmpty(bannerUrl) ? (object)DBNull.Value : bannerUrl);
        }

        private static long GetFirstId(SqlConnection con, SqlTransaction tx, string table)
        {
            using (var cmd = new SqlCommand("SELECT TOP 1 id FROM " + table + " WHERE is_active = 1 ORDER BY id;", con, tx))
            {
                var o = cmd.ExecuteScalar();
                return o == null ? 1L : Convert.ToInt64(o);
            }
        }

        #endregion

        #region Helpers: code, slug, tags, banner

        private static string GenerateEventCode(SqlConnection con, SqlTransaction tx)
        {
            int year = DateTime.Now.Year;
            int n = 0;
            using (var cmd = new SqlCommand(
                "SELECT COUNT(*) FROM dbo.events WHERE YEAR(created_at) = @y;", con, tx))
            {
                cmd.Parameters.AddWithValue("@y", year);
                var o = cmd.ExecuteScalar();
                if (o != null && o != DBNull.Value) n = Convert.ToInt32(o);
            }

            string code;
            int attempt = 0;
            do
            {
                n++;
                code = string.Format("EVT-{0}-{1:0000}", year, n);
                attempt++;
            }
            while (CodeExists(con, tx, code) && attempt < 100);

            return code;
        }

        private static bool CodeExists(SqlConnection con, SqlTransaction tx, string code)
        {
            using (var cmd = new SqlCommand(
                "SELECT COUNT(1) FROM dbo.events WHERE event_code = @c;", con, tx))
            {
                cmd.Parameters.AddWithValue("@c", code);
                var o = cmd.ExecuteScalar();
                return o != null && Convert.ToInt32(o) > 0;
            }
        }

        private static string GenerateSlug(string title)
        {
            if (string.IsNullOrEmpty(title)) return "event";
            string s = title.ToLowerInvariant();

            s = RemoveDiacritics(s);
            s = Regex.Replace(s, @"[^a-z0-9]+", "-");
            s = s.Trim('-');
            if (s.Length > 80) s = s.Substring(0, 80).TrimEnd('-');
            return string.IsNullOrEmpty(s) ? "event" : s;
        }

        private static string RemoveDiacritics(string text)
        {
            var normalized = text.Normalize(System.Text.NormalizationForm.FormD);
            var sb = new StringBuilder();
            foreach (char c in normalized)
            {
                var uc = System.Globalization.CharUnicodeInfo.GetUnicodeCategory(c);
                if (uc != System.Globalization.UnicodeCategory.NonSpacingMark)
                    sb.Append(c);
            }
            return sb.ToString()
                .Replace('đ', 'd').Replace('Đ', 'D')
                .Normalize(System.Text.NormalizationForm.FormC);
        }

        private static List<string> ParseTags(string raw)
        {
            var result = new List<string>();
            if (string.IsNullOrWhiteSpace(raw)) return result;

            foreach (var part in raw.Split(','))
            {
                var t = part.Trim();
                if (t.Length == 0) continue;
                if (t.Length > 80) t = t.Substring(0, 80);
                if (!result.Contains(t, StringComparer.OrdinalIgnoreCase))
                    result.Add(t);
            }
            return result;
        }

        private static void ReplaceEventTags(SqlConnection con, SqlTransaction tx,
            long eventId, List<string> tagNames)
        {
            using (var cmd = new SqlCommand(
                "DELETE FROM dbo.event_event_tags WHERE event_id = @eid;", con, tx))
            {
                cmd.Parameters.AddWithValue("@eid", eventId);
                cmd.ExecuteNonQuery();
            }

            if (tagNames == null || tagNames.Count == 0) return;

            foreach (var name in tagNames)
            {
                long tagId = GetOrCreateTag(con, tx, name);

                using (var cmd = new SqlCommand(
                    @"IF NOT EXISTS (SELECT 1 FROM dbo.event_event_tags WHERE event_id = @eid AND tag_id = @tid)
                      INSERT INTO dbo.event_event_tags (event_id, tag_id) VALUES (@eid, @tid);", con, tx))
                {
                    cmd.Parameters.AddWithValue("@eid", eventId);
                    cmd.Parameters.AddWithValue("@tid", tagId);
                    cmd.ExecuteNonQuery();
                }

                using (var cmd = new SqlCommand(
                    "UPDATE dbo.event_tags SET usage_count = usage_count + 1 WHERE id = @tid;", con, tx))
                {
                    cmd.Parameters.AddWithValue("@tid", tagId);
                    cmd.ExecuteNonQuery();
                }
            }
        }

        private static long GetOrCreateTag(SqlConnection con, SqlTransaction tx, string name)
        {
            using (var cmd = new SqlCommand(
                "SELECT id FROM dbo.event_tags WHERE name = @n;", con, tx))
            {
                cmd.Parameters.AddWithValue("@n", name);
                var o = cmd.ExecuteScalar();
                if (o != null && o != DBNull.Value) return Convert.ToInt64(o);
            }

            string slug = GenerateSlug(name);
            int n = 0;
            string finalSlug = slug;
            while (TagSlugExists(con, tx, finalSlug))
            {
                n++;
                finalSlug = slug + "-" + n;
            }

            using (var cmd = new SqlCommand(
                @"INSERT INTO dbo.event_tags (name, slug, usage_count)
                  OUTPUT INSERTED.id
                  VALUES (@n, @s, 0);", con, tx))
            {
                cmd.Parameters.AddWithValue("@n", name);
                cmd.Parameters.AddWithValue("@s", finalSlug);
                return Convert.ToInt64(cmd.ExecuteScalar());
            }
        }

        private static bool TagSlugExists(SqlConnection con, SqlTransaction tx, string slug)
        {
            using (var cmd = new SqlCommand(
                "SELECT COUNT(1) FROM dbo.event_tags WHERE slug = @s;", con, tx))
            {
                cmd.Parameters.AddWithValue("@s", slug);
                var o = cmd.ExecuteScalar();
                return o != null && Convert.ToInt32(o) > 0;
            }
        }

        private string SaveBanner(FileUpload fu)
        {
            try
            {
                if (!fu.HasFile) return null;

                string ext = Path.GetExtension(fu.FileName).ToLowerInvariant();
                var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif" };
                if (Array.IndexOf(allowed, ext) < 0)
                {
                    ShowAlert("Định dạng banner không hợp lệ. Chỉ chấp nhận JPG, PNG, WEBP, GIF.", isError: true);
                    return null;
                }

                if (fu.PostedFile.ContentLength > 5 * 1024 * 1024)
                {
                    ShowAlert("Dung lượng banner vượt quá 5MB.", isError: true);
                    return null;
                }

                string folder = Server.MapPath("~/Uploads/banners");
                if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);

                string fileName = "banner-" + DateTime.Now.ToString("yyyyMMddHHmmss") + "-"
                                + Guid.NewGuid().ToString("N").Substring(0, 8) + ext;
                string fullPath = Path.Combine(folder, fileName);
                fu.SaveAs(fullPath);

                string virtualUrl = "~/Uploads/banners/" + fileName;
                hfBannerUrl.Value = virtualUrl;
                return virtualUrl;
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi upload banner: " + ex.Message, isError: true);
                return null;
            }
        }

        protected void btnRemoveBanner_Click(object sender, EventArgs e)
        {
            hfBannerUrl.Value = "";
            imgBanner.ImageUrl = "";
            imgBanner.Visible = false;
            litBannerTag.Text = "Đã xoá banner";
        }

        #endregion

        #region UI helpers

        private static bool TryBuildDateTime(string dateStr, string timeStr, out DateTime result)
        {
            result = DateTime.MinValue;
            if (string.IsNullOrEmpty(dateStr)) return false;
            if (string.IsNullOrEmpty(timeStr)) timeStr = "00:00";

            DateTime d;
            if (!DateTime.TryParse(dateStr, out d)) return false;

            TimeSpan t;
            if (!TimeSpan.TryParse(timeStr, out t)) t = TimeSpan.Zero;

            result = d.Date + t;
            return true;
        }

        private void ShowAlert(string msg, bool isError)
        {
            pnlAlert.Visible = true;
            pnlAlert.CssClass = isError ? "alert alert-error" : "alert alert-success";
            litAlertMsg.Text = HttpUtility.HtmlEncode(msg);
        }

        #endregion
    }
}