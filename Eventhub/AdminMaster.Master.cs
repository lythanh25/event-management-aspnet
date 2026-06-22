using Eventhub.App_Code;
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Eventhub
{
    /// <summary>
    /// Master Page khu Admin. Bảo vệ truy cập + đếm số đơn pending từ DB.
    /// </summary>
    public partial class AdminMaster: System.Web.UI.MasterPage
    {
        /// <summary>Breadcrumb hiển thị trên topbar.</summary>
        public string Breadcrumb
        {
            get { return litBreadcrumb.Text; }
            set { litBreadcrumb.Text = value; }
        }

        public int PendingApprovalCount
        {
            get { int n; return int.TryParse(lblPendingBadge.Text, out n) ? n : 0; }
            set
            {
                lblPendingBadge.Text = value.ToString();
                lblPendingBadge.Visible = value > 0;
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            // ─── BẢO VỆ ───
            if (!AuthHelper.IsAuthenticated(Session))
            {
                Response.Redirect("~/Account/Login.aspx");
                return;
            }

            if (!AuthHelper.CanAccessAdminArea(Session))
            {
                Response.Redirect("~/User/UserHome.aspx");
                return;
            }

            if (!IsPostBack)
            {
                PendingApprovalCount = CountPendingRegistrations();
            }
        }

        private static int CountPendingRegistrations()
        {
            try
            {
                const string sql =
                    "SELECT COUNT(1) FROM dbo.event_registrations WHERE status = N'pending';";
                using (var con = Database.OpenConnection())
                using (var cmd = new SqlCommand(sql, con))
                {
                    var o = cmd.ExecuteScalar();
                    return o == null || o == DBNull.Value ? 0 : Convert.ToInt32(o);
                }
            }
            catch
            {
                return 0;
            }
        }

        protected string GetNavClass(params string[] pageNames)
        {
            string current = Path.GetFileName(Request.AppRelativeCurrentExecutionFilePath ?? "");
            bool isActive = pageNames.Any(p =>
                string.Equals(p, current, StringComparison.OrdinalIgnoreCase));
            return isActive ? "nav-item active" : "nav-item";
        }

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
