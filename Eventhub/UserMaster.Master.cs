using Eventhub.App_Code;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Eventhub
{
    public partial class UserMaster : System.Web.UI.MasterPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // ─── BẢO VỆ ───
            // 1. Chưa đăng nhập → về Login
            if (!AuthHelper.IsAuthenticated(Session))
            {
                Response.Redirect("~/Account/Login.aspx");
                return;
            }

            // 2. Admin/Organizer → chuyển sang khu Admin
            if (AuthHelper.CanAccessAdminArea(Session))
            {
                Response.Redirect(AuthHelper.GetRedirectUrl(AuthHelper.CurrentUser(Session)));
                return;
            }

            if (!IsPostBack)
            {
                LoadUserInfo();
                LoadNotification();
            }
        }

        /// <summary>Đổ thông tin user lên user-chip ở header.</summary>
        private void LoadUserInfo()
        {
            var user = AuthHelper.CurrentUser(Session);
            if (user == null)
            {
                ltrUserName.Text = "Khách";
                ltrUserDept.Text = "—";
                ltrUserInitial.Text = "?";
                return;
            }

            ltrUserName.Text = Server.HtmlEncode(user.FullName);
            ltrUserDept.Text = Server.HtmlEncode(user.DepartmentName ?? "—");
            ltrUserInitial.Text = GetInitial(user.FullName);
        }

        /// <summary>Lấy chữ cái đầu (first_name) — chữ cuối trong họ tên đầy đủ.</summary>
        private static string GetInitial(string fullName)
        {
            if (string.IsNullOrWhiteSpace(fullName)) return "?";
            var parts = fullName.Trim().Split(' ');
            string last = parts[parts.Length - 1];
            return last.Substring(0, 1).ToUpper();
        }

        /// <summary>Hiển thị chấm đỏ thông báo (nếu có).</summary>
        private void LoadNotification()
        {
            // TODO: thực tế đếm từ DB
            int count = CountUnreadNotifications();
            pnlNotifDot.Visible = count > 0;
        }

        private int CountUnreadNotifications()
        {
            // TODO: truy vấn DB. Hiện trả giá trị mẫu.
            return 1;
        }

        /// <summary>
        /// Trả về "active" nếu trang hiện tại khớp với 1 trong các pageNames.
        /// Dùng trong .Master để bôi đậm mục menu đang active.
        /// </summary>
        public string GetActiveClass(params string[] pageNames)
        {
            try
            {
                string current = Path.GetFileNameWithoutExtension(Request.AppRelativeCurrentExecutionFilePath ?? "");
                bool isActive = pageNames.Any(p =>
                    string.Equals(p, current, StringComparison.OrdinalIgnoreCase));
                return isActive ? "active" : string.Empty;
            }
            catch
            {
                return string.Empty;
            }
        }

        /// <summary>Xử lý click nút Đăng xuất.</summary>
        protected void btnLogout_Click(object sender, EventArgs e)
        {
            var user = AuthHelper.CurrentUser(Session);
            if (user != null)
            {
                AuthHelper.LogActivity(user.Id, "logout", Request.UserHostAddress, Request.UserAgent);
            }
            AuthHelper.SignOut(Session);
            Response.Redirect("~/Account/Login.aspx");
        }
    }
}