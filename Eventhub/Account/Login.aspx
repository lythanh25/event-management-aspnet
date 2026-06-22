<%@ Page Language="C#" AutoEventWireup="true"
    CodeBehind="Login.aspx.cs" Inherits="Eventhub.Account.Login" %>

<!DOCTYPE html>
<html lang="vi">
<head runat="server">
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Đăng nhập — EventHub</title>

    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@0;1&family=Geist:wght@300;400;500;600;700&family=Geist+Mono:wght@400;500&display=swap" rel="stylesheet">

    <link href="<%= ResolveUrl("~/Content/Auth.css") %>" rel="stylesheet" type="text/css" />
    <style>
        select.input {
            appearance: none;
            -webkit-appearance: none;
            -moz-appearance: none;
            background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%238A7E72' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><polyline points='6 9 12 15 18 9'/></svg>");
            background-repeat: no-repeat;
            background-position: right 14px center;
            padding-right: 40px;
        }
    </style>
</head>
<body>
<form id="form1" runat="server" autocomplete="on">

<asp:HiddenField ID="hdnActiveTab" runat="server" Value="login" />

<asp:ValidationSummary ID="vsLogin" runat="server"
    ValidationGroup="Login"
    ShowMessageBox="true"
    ShowSummary="false"
    HeaderText="Vui lòng kiểm tra lại:" />

<asp:ValidationSummary ID="vsRegister" runat="server"
    ValidationGroup="Register"
    ShowMessageBox="true"
    ShowSummary="false"
    HeaderText="Vui lòng kiểm tra lại:" />

<div class="auth-shell">

    <div class="auth-left">

        <div class="auth-brand">
            <div class="auth-brand-mark">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="4" width="18" height="18" rx="3"/>
                    <path d="M16 2v4M8 2v4M3 10h18"/>
                </svg>
            </div>
            <div>
                <div class="auth-brand-name">EventHub</div>
                <div class="auth-brand-sub">Hệ thống quản lý sự kiện</div>
            </div>
        </div>

        <div class="auth-hero">
            <h1 class="auth-hero-title">Kết nối <em>mọi sự kiện</em><br />trong tổ chức</h1>
            <p class="auth-hero-desc">
                Đăng ký, theo dõi và tham gia các sự kiện nội bộ một cách dễ dàng.
                Dành cho toàn thể nhân viên công ty.
            </p>
        </div>

        <div class="auth-features">
            <div class="auth-feature">Xem lịch và đăng ký sự kiện trực tuyến</div>
            <div class="auth-feature">Nhận thông báo duyệt đăng ký tức thì</div>
            <div class="auth-feature">Quản lý toàn bộ sự kiện bởi Ban tổ chức</div>
        </div>

        <div class="auth-footer">
            <span>© 2025 EventHub · Internal Use Only</span>
            <a href="#">Cần hỗ trợ?</a>
        </div>
    </div>

    <div class="auth-right">
        <div class="auth-form-wrap">

            <div class="auth-tabs" id="tabs">
                <div class="auth-tab-indicator"></div>
                <button type="button" class="auth-tab" data-panel="login">Đăng nhập</button>
                <button type="button" class="auth-tab" data-panel="register">Đăng ký</button>
            </div>

            <asp:Panel ID="pnlAlert" runat="server" CssClass="auth-alert error" Visible="false">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="8" x2="12" y2="12"/>
                    <line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                <asp:Literal ID="litAlert" runat="server" />
            </asp:Panel>

            <%-- ════════════ LOGIN PANEL ═════════════════ --%>
            <div class="form-panel" data-form="login" id="panelLogin">

                <h2 class="form-title">Chào mừng <em>trở lại</em></h2>
                <p class="form-subtitle">Đăng nhập để khám phá sự kiện nội bộ</p>

                <div class="field">
                    <label class="label" for="<%= txtEmail.ClientID %>">Email công ty</label>
                    <div class="input-wrap">
                        <asp:TextBox ID="txtEmail" runat="server" CssClass="input"
                                     TextMode="Email" placeholder="ten@congty.com" />
                    </div>
                    <asp:RequiredFieldValidator runat="server"
                        ControlToValidate="txtEmail"
                        ValidationGroup="Login"
                        ErrorMessage="Vui lòng nhập email"
                        Text="Vui lòng nhập email"
                        CssClass="field-error" Display="Dynamic" />
                </div>

                <div class="field">
                    <label class="label" for="<%= txtPassword.ClientID %>">Mật khẩu</label>
                    <div class="input-wrap">
                        <asp:TextBox ID="txtPassword" runat="server" CssClass="input input-with-icon"
                                     TextMode="Password" placeholder="Nhập mật khẩu" />
                        <button class="input-icon" data-toggle-pw="<%= txtPassword.ClientID %>" type="button" title="Hiện/ẩn mật khẩu">
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
                                <line x1="1" y1="1" x2="23" y2="23"/>
                            </svg>
                        </button>
                    </div>
                    <asp:RequiredFieldValidator runat="server"
                        ControlToValidate="txtPassword"
                        ValidationGroup="Login"
                        ErrorMessage="Vui lòng nhập mật khẩu"
                        Text="Vui lòng nhập mật khẩu"
                        CssClass="field-error" Display="Dynamic" />
                </div>

                <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:22px;">
                    <div class="check-row" id="rowRemember" style="margin-bottom:0;">
                        <div class="check-box"></div>
                        <span>Ghi nhớ đăng nhập</span>
                    </div>
                    <asp:HiddenField ID="hdnRemember" runat="server" Value="false" />
                    <a class="label-link" href="#">Quên mật khẩu?</a>
                </div>

                <asp:Button ID="btnLogin" runat="server" Text="Đăng nhập"
                            CssClass="btn-submit" ValidationGroup="Login"
                            OnClick="btnLogin_Click"
                            OnClientClick="document.getElementById('<%= hdnActiveTab.ClientID %>').value='login';" />

                <div class="divider">hoặc</div>

                <button type="button" class="btn-google">
                    <svg viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg">
                        <path d="M17.64 9.205c0-.638-.057-1.252-.164-1.841H9v3.481h4.844a4.14 4.14 0 0 1-1.796 2.716v2.259h2.908c1.702-1.567 2.684-3.875 2.684-6.615z" fill="#4285F4"/>
                        <path d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332A8.997 8.997 0 0 0 9 18z" fill="#34A853"/>
                        <path d="M3.964 10.71A5.41 5.41 0 0 1 3.682 9c0-.593.102-1.17.282-1.71V4.958H.957A8.996 8.996 0 0 0 0 9c0 1.452.348 2.827.957 4.042l3.007-2.332z" fill="#FBBC05"/>
                        <path d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0A8.997 8.997 0 0 0 .957 4.958L3.964 7.29C4.672 5.163 6.656 3.58 9 3.58z" fill="#EA4335"/>
                    </svg>
                    Đăng nhập với Google Workspace
                </button>

                <div class="form-help">
                    Chưa có tài khoản?
                    <a data-switch="register">Đăng ký ngay</a>
                </div>
            </div>

            <%-- ════════════ REGISTER PANEL ══════════════ --%>
            <div class="form-panel" data-form="register" id="panelRegister">

                <h2 class="form-title">Tạo <em>tài khoản</em> mới</h2>
                <p class="form-subtitle">Đăng ký bằng email công ty để tham gia sự kiện</p>

                <div class="field">
                    <label class="label" for="<%= txtFullName.ClientID %>">Họ và tên</label>
                    <div class="input-wrap">
                        <asp:TextBox ID="txtFullName" runat="server" CssClass="input"
                                     placeholder="Nguyễn Phương Anh" />
                    </div>
                    <asp:RequiredFieldValidator runat="server"
                        ControlToValidate="txtFullName"
                        ValidationGroup="Register"
                        ErrorMessage="Vui lòng nhập họ tên"
                        Text="Vui lòng nhập họ tên"
                        CssClass="field-error" Display="Dynamic" />
                </div>

                <div class="field">
                    <label class="label" for="<%= txtRegEmail.ClientID %>">Email công ty</label>
                    <div class="input-wrap">
                        <asp:TextBox ID="txtRegEmail" runat="server" CssClass="input"
                                     TextMode="Email" placeholder="ten@congty.com" />
                    </div>
                    <asp:RequiredFieldValidator runat="server"
                        ControlToValidate="txtRegEmail"
                        ValidationGroup="Register"
                        ErrorMessage="Vui lòng nhập email"
                        Text="Vui lòng nhập email"
                        CssClass="field-error" Display="Dynamic" />
                    <asp:RegularExpressionValidator runat="server"
                        ControlToValidate="txtRegEmail"
                        ValidationGroup="Register"
                        ValidationExpression="^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"
                        ErrorMessage="Email không hợp lệ"
                        Text="Email không hợp lệ"
                        CssClass="field-error" Display="Dynamic" />
                </div>

                <div class="row-2">
                    <div class="field">
                        <label class="label" for="<%= ddlDepartment.ClientID %>">Phòng ban</label>
                        <div class="input-wrap">
                            <asp:DropDownList ID="ddlDepartment" runat="server" CssClass="input" />
                        </div>
                        <asp:RequiredFieldValidator runat="server"
                            ControlToValidate="ddlDepartment"
                            InitialValue=""
                            ValidationGroup="Register"
                            ErrorMessage="Vui lòng chọn phòng ban"
                            Text="Vui lòng chọn phòng ban"
                            CssClass="field-error" Display="Dynamic" />
                    </div>
                    <div class="field">
                        <label class="label" for="<%= txtEmpCode.ClientID %>">Mã nhân viên</label>
                        <div class="input-wrap">
                            <asp:TextBox ID="txtEmpCode" runat="server" CssClass="input"
                                         placeholder="EMP-1234" MaxLength="20" />
                        </div>
                        <asp:RequiredFieldValidator runat="server"
                            ControlToValidate="txtEmpCode"
                            ValidationGroup="Register"
                            ErrorMessage="Vui lòng nhập mã nhân viên"
                            Text="Vui lòng nhập mã"
                            CssClass="field-error" Display="Dynamic" />
                    </div>
                </div>

                <div class="field">
                    <label class="label" for="<%= txtRegPassword.ClientID %>">Mật khẩu</label>
                    <div class="input-wrap">
                        <asp:TextBox ID="txtRegPassword" runat="server" CssClass="input input-with-icon"
                                     TextMode="Password" placeholder="Tối thiểu 8 ký tự" />
                        <button class="input-icon" data-toggle-pw="<%= txtRegPassword.ClientID %>" type="button">
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
                                <line x1="1" y1="1" x2="23" y2="23"/>
                            </svg>
                        </button>
                    </div>
                    <asp:RequiredFieldValidator runat="server"
                        ControlToValidate="txtRegPassword"
                        ValidationGroup="Register"
                        ErrorMessage="Vui lòng nhập mật khẩu"
                        Text="Vui lòng nhập mật khẩu"
                        CssClass="field-error" Display="Dynamic" />
                    <asp:RegularExpressionValidator runat="server"
                        ControlToValidate="txtRegPassword"
                        ValidationGroup="Register"
                        ValidationExpression=".{8,}"
                        ErrorMessage="Mật khẩu phải có tối thiểu 8 ký tự"
                        Text="Mật khẩu phải tối thiểu 8 ký tự"
                        CssClass="field-error" Display="Dynamic" />
                </div>

                <div class="terms-row" id="rowTerms">
                    <div class="check-box"></div>
                    <span>Tôi đồng ý với <a href="#">Điều khoản sử dụng</a> và <a href="#">Chính sách bảo mật</a> của EventHub Nội Bộ.</span>
                </div>
                <asp:HiddenField ID="hdnAgreeTerms" runat="server" Value="false" />

                <asp:Button ID="btnRegister" runat="server" Text="Tạo tài khoản"
                            CssClass="btn-submit" ValidationGroup="Register"
                            OnClick="btnRegister_Click"
                            OnClientClick="document.getElementById('<%= hdnActiveTab.ClientID %>').value='register';" />

                <div class="divider">hoặc</div>

                <button type="button" class="btn-google">
                    <svg viewBox="0 0 18 18" xmlns="http://www.w3.org/2000/svg">
                        <path d="M17.64 9.205c0-.638-.057-1.252-.164-1.841H9v3.481h4.844a4.14 4.14 0 0 1-1.796 2.716v2.259h2.908c1.702-1.567 2.684-3.875 2.684-6.615z" fill="#4285F4"/>
                        <path d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332A8.997 8.997 0 0 0 9 18z" fill="#34A853"/>
                        <path d="M3.964 10.71A5.41 5.41 0 0 1 3.682 9c0-.593.102-1.17.282-1.71V4.958H.957A8.996 8.996 0 0 0 0 9c0 1.452.348 2.827.957 4.042l3.007-2.332z" fill="#FBBC05"/>
                        <path d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0A8.997 8.997 0 0 0 .957 4.958L3.964 7.29C4.672 5.163 6.656 3.58 9 3.58z" fill="#EA4335"/>
                    </svg>
                    Đăng ký với Google Workspace
                </button>

                <div class="form-help">
                    Đã có tài khoản?
                    <a data-switch="login">Đăng nhập</a>
                </div>
            </div>

        </div>
    </div>
</div>

<script>
    (function () {
        var hdnActiveTab   = document.getElementById('<%= hdnActiveTab.ClientID %>');
        var hdnRemember    = document.getElementById('<%= hdnRemember.ClientID %>');
        var hdnAgreeTerms  = document.getElementById('<%= hdnAgreeTerms.ClientID %>');

        var tabs = document.getElementById('tabs');
        var tabBtns = tabs.querySelectorAll('.auth-tab');
        var panels = document.querySelectorAll('.form-panel');

        function switchTo(name) {
            tabBtns.forEach(function (b) { b.classList.toggle('active', b.dataset.panel === name); });
            panels.forEach(function (p) { p.classList.toggle('active', p.dataset.form === name); });
            tabs.classList.toggle('tab-2', name === 'register');
            hdnActiveTab.value = name;
        }

        tabBtns.forEach(function (btn) {
            btn.addEventListener('click', function () { switchTo(btn.dataset.panel); });
        });
        document.querySelectorAll('[data-switch]').forEach(function (a) {
            a.addEventListener('click', function () { switchTo(a.dataset.switch); });
        });

        switchTo(hdnActiveTab.value || 'login');

        var rowRemember = document.getElementById('rowRemember');
        if (hdnRemember.value === 'true') rowRemember.classList.add('checked');
        rowRemember.addEventListener('click', function () {
            rowRemember.classList.toggle('checked');
            hdnRemember.value = rowRemember.classList.contains('checked') ? 'true' : 'false';
        });

        var rowTerms = document.getElementById('rowTerms');
        if (hdnAgreeTerms.value === 'true') rowTerms.classList.add('checked');
        rowTerms.addEventListener('click', function () {
            rowTerms.classList.toggle('checked');
            hdnAgreeTerms.value = rowTerms.classList.contains('checked') ? 'true' : 'false';
        });

        document.querySelectorAll('[data-toggle-pw]').forEach(function (btn) {
            btn.addEventListener('click', function () {
                var input = document.getElementById(btn.dataset.togglePw);
                if (!input) return;
                input.type = (input.type === 'password') ? 'text' : 'password';
            });
        });
    })();
</script>

</form>
</body>
</html>
