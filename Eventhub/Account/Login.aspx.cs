using Eventhub.App_Code;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace Eventhub.Account
{
    public partial class Login : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            // Đã đăng nhập → redirect ngay
            if (!IsPostBack && AuthHelper.IsAuthenticated(Session))
            {
                var user = AuthHelper.CurrentUser(Session);
                Response.Redirect(AuthHelper.GetRedirectUrl(user));
                return;
            }

            if (!IsPostBack)
            {
                LoadDepartments();
            }
        }

        private void LoadDepartments()
        {
            try
            {
                var list = AuthHelper.GetActiveDepartments();
                ddlDepartment.Items.Clear();
                ddlDepartment.Items.Add(new ListItem("-- Chọn phòng ban --", ""));
                foreach (var kv in list)
                {
                    ddlDepartment.Items.Add(new ListItem(kv.Value, kv.Key.ToString()));
                }
            }
            catch (Exception ex)
            {
                ShowAlert("Không kết nối được tới cơ sở dữ liệu: " + ex.Message, isError: true);
                ShowPopup("❌ Lỗi kết nối cơ sở dữ liệu.\\n\\nVui lòng kiểm tra connectionString trong Web.config.");
            }
        }

        // ════════════════════════════════════════════════════════
        // LOGIN
        // ════════════════════════════════════════════════════════
        protected void btnLogin_Click(object sender, EventArgs e)
        {
            Page.Validate("Login");
            if (!Page.IsValid) return;

            string email = txtEmail.Text.Trim();
            string password = txtPassword.Text;

            UserAccount user;
            try
            {
                user = AuthHelper.FindUser(email, password);
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi cơ sở dữ liệu: " + ex.Message, isError: true);
                ShowPopup("❌ Lỗi kết nối cơ sở dữ liệu.\\nVui lòng thử lại sau.");
                hdnActiveTab.Value = "login";
                return;
            }

            // ❌ Sai email hoặc mật khẩu
            if (user == null)
            {
                AuthHelper.LogActivity(null, "login_failed", GetIp(), GetUserAgent());

                ShowAlert("Email hoặc mật khẩu không đúng. Vui lòng thử lại.", isError: true);
                ShowPopup("❌ ĐĂNG NHẬP THẤT BẠI\\n\\nEmail hoặc mật khẩu không chính xác.\\nVui lòng kiểm tra lại.");
                txtPassword.Text = "";
                hdnActiveTab.Value = "login";
                return;
            }

            // ✅ Đăng nhập thành công
            AuthHelper.SignIn(Session, user);
            AuthHelper.TouchLastLogin(user.Id);
            AuthHelper.LogActivity(user.Id, "login_success", GetIp(), GetUserAgent());

            if (hdnRemember.Value == "true")
            {
                var cookie = new System.Web.HttpCookie("RememberEmail", user.Email)
                {
                    Expires = DateTime.Now.AddDays(30),
                    HttpOnly = true
                };
                Response.Cookies.Add(cookie);
            }
            string redirectUrl = ResolveUrl(AuthHelper.GetRedirectUrl(user));
            string welcomeMsg = "✅ ĐĂNG NHẬP THÀNH CÔNG\\n\\nXin chào " + EscapeJs(user.FullName) + "!\\nChào mừng bạn quay trở lại.";
            ShowPopupAndRedirect(welcomeMsg, redirectUrl);
        }

        // ════════════════════════════════════════════════════════
        // REGISTER
        // ════════════════════════════════════════════════════════
        protected void btnRegister_Click(object sender, EventArgs e)
        {
            Page.Validate("Register");
            if (!Page.IsValid)
            {
                hdnActiveTab.Value = "register";
                return;
            }

            //  Chưa đồng ý điều khoản
            if (hdnAgreeTerms.Value != "true")
            {
                ShowAlert("Bạn phải đồng ý với Điều khoản & Chính sách trước khi đăng ký.", isError: true);
                ShowPopup("⚠️ CHƯA ĐỒNG Ý ĐIỀU KHOẢN\\n\\nVui lòng tích vào ô đồng ý với\\nĐiều khoản sử dụng & Chính sách bảo mật.");
                hdnActiveTab.Value = "register";
                return;
            }

            string fullName = txtFullName.Text.Trim();
            string email = txtRegEmail.Text.Trim();
            string empCode = txtEmpCode.Text.Trim();
            string password = txtRegPassword.Text;

            long deptId;
            if (!long.TryParse(ddlDepartment.SelectedValue, out deptId) || deptId <= 0)
            {
                ShowAlert("Vui lòng chọn phòng ban hợp lệ.", isError: true);
                ShowPopup("⚠️ Vui lòng chọn phòng ban!");
                hdnActiveTab.Value = "register";
                return;
            }

            try
            {
                //  Email đã tồn tại
                if (AuthHelper.EmailExists(email))
                {
                    ShowAlert("Email này đã được sử dụng.", isError: true);
                    ShowPopup("❌ EMAIL ĐÃ TỒN TẠI\\n\\nEmail \"" + EscapeJs(email) + "\" đã được đăng ký trước đó.\\n\\nVui lòng dùng email khác hoặc chuyển sang tab Đăng nhập.");
                    hdnActiveTab.Value = "register";
                    return;
                }

                //  Mã nhân viên đã tồn tại
                if (AuthHelper.EmployeeCodeExists(empCode))
                {
                    ShowAlert("Mã nhân viên đã được sử dụng.", isError: true);
                    ShowPopup("❌ MÃ NHÂN VIÊN ĐÃ TỒN TẠI\\n\\nMã \"" + EscapeJs(empCode) + "\" đã được sử dụng.\\nVui lòng kiểm tra lại hoặc dùng mã khác.");
                    hdnActiveTab.Value = "register";
                    return;
                }

                //  Tạo tài khoản
                var newUser = AuthHelper.Register(fullName, email, deptId, empCode, password);
                if (newUser == null)
                {
                    ShowAlert("Không thể tạo tài khoản. Vui lòng thử lại.", isError: true);
                    ShowPopup("❌ Không thể tạo tài khoản.\\nVui lòng thử lại sau.");
                    hdnActiveTab.Value = "register";
                    return;
                }

                AuthHelper.SignIn(Session, newUser);
                AuthHelper.TouchLastLogin(newUser.Id);
                AuthHelper.LogActivity(newUser.Id, "register", GetIp(), GetUserAgent());

                string redirectUrl = ResolveUrl(AuthHelper.GetRedirectUrl(newUser));
                string successMsg = "🎉 ĐĂNG KÝ THÀNH CÔNG!\\n\\nChào mừng " + EscapeJs(newUser.FullName) + " đến với EventHub Nội Bộ!\\n\\nNhấn OK để vào trang chủ.";
                ShowPopupAndRedirect(successMsg, redirectUrl);
            }
            catch (Exception ex)
            {
                ShowAlert("Lỗi: " + ex.Message, isError: true);
                ShowPopup("❌ Đã xảy ra lỗi:\\n" + EscapeJs(ex.Message));
                hdnActiveTab.Value = "register";
            }
        }

        // ════════════════════════════════════════════════════════
        // HELPERS — Hiển thị thông báo
        // ════════════════════════════════════════════════════════

        private void ShowAlert(string message, bool isError)
        {
            pnlAlert.Visible = true;
            pnlAlert.CssClass = "auth-alert " + (isError ? "error" : "success");
            litAlert.Text = Server.HtmlEncode(message);
        }

        private void ShowPopup(string message)
        {
            string script = "alert('" + message + "');";
            string key = "popup_" + Guid.NewGuid().ToString("N");
            ClientScript.RegisterStartupScript(GetType(), key, script, true);
        }

        private void ShowPopupAndRedirect(string message, string redirectUrl)
        {
            string script = "alert('" + message + "'); window.location.href = '" + redirectUrl + "';";
            string key = "redirect_" + Guid.NewGuid().ToString("N");
            ClientScript.RegisterStartupScript(GetType(), key, script, true);
        }

        private static string EscapeJs(string s)
        {
            if (string.IsNullOrEmpty(s)) return "";
            return s.Replace("\\", "\\\\")
                    .Replace("'", "\\'")
                    .Replace("\r", "")
                    .Replace("\n", "\\n");
        }

        private string GetIp()
        {
            var ip = Request.UserHostAddress;
            return ip != null && ip.Length > 45 ? ip.Substring(0, 45) : ip;
        }

        private string GetUserAgent()
        {
            var ua = Request.UserAgent ?? "";
            return ua.Length > 500 ? ua.Substring(0, 500) : ua;
        }
    }
}