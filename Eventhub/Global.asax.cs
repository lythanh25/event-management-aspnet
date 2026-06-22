using Eventhub.App_Code;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Optimization;
using System.Web.Routing;
using System.Web.Security;
using System.Web.SessionState;
using System.Web.UI;

namespace Eventhub
{
    public class Global : HttpApplication
    {
        protected void Application_Start(object sender, EventArgs e)
        {
            ScriptManager.ScriptResourceMapping.AddDefinition("jquery",
            new ScriptResourceDefinition { Path = "~/Scripts/jquery-3.x.x.min.js" });
            AuthHelper.EnsureSeedAdmin();    
            // ─── Tự tạo tài khoản admin mặc định nếu DB chưa có ───
            // Email: admin@congty.com
            // Pass : admin123
            try
            {
                AuthHelper.EnsureSeedAdmin();
            }
            catch (Exception ex)
            {
                System.Diagnostics.Trace.WriteLine("Seed admin failed: " + ex.Message);
            }

        }

        protected void Application_Error(object sender, EventArgs e)
        {
            var ex = Server.GetLastError();
            System.Diagnostics.Trace.WriteLine("App error: " + ex);
        }
    }
}