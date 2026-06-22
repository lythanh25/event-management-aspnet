<%@ Page Title="Cài đặt" Language="C#" MasterPageFile="~/AdminMaster.Master"
    AutoEventWireup="true" CodeBehind="Settings.aspx.cs"
    Inherits="Eventhub.Admin.settings" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Cài đặt — EventHub Admin
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Content/Settings.css") %>" rel="stylesheet" type="text/css" />
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <%-- Alert --%>
    <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="alert">
        <asp:Literal ID="litAlert" runat="server" />
    </asp:Panel>

    <%-- ─── PAGE HEAD ─── --%>
    <div class="page-head">
        <div>
            <h1 class="page-title">Cài <em>đặt</em></h1>
            <div class="page-sub">Quản lý hồ sơ, bảo mật và tuỳ chỉnh thông báo của tài khoản admin.</div>
        </div>
        <span class="save-status">
            Cập nhật lúc <asp:Literal ID="litSavedAt" runat="server" />
        </span>
    </div>

    <%-- ═════════ GRID ═════════ --%>
    <div class="grid">

        <%-- ─── LEFT NAV ─── --%>
        <nav class="settings-nav">
            <div class="settings-nav-label">Tài khoản</div>

            <asp:HyperLink ID="navProfile" runat="server" CssClass="settings-nav-item active"
                           NavigateUrl="~/Admin/Settings.aspx?sec=profile">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/>
                </svg>
                Hồ sơ cá nhân
                <span class="settings-nav-arrow">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="9,18 15,12 9,6"/>
                    </svg>
                </span>
            </asp:HyperLink>

            <asp:HyperLink ID="navSecurity" runat="server" CssClass="settings-nav-item"
                           NavigateUrl="~/Admin/Settings.aspx?sec=security">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="11" width="18" height="11" rx="2"/>
                    <path d="M7 11V7a5 5 0 0110 0v4"/>
                </svg>
                Bảo mật &amp; Mật khẩu
                <span class="settings-nav-arrow">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="9,18 15,12 9,6"/>
                    </svg>
                </span>
            </asp:HyperLink>

            <asp:HyperLink ID="navNotifications" runat="server" CssClass="settings-nav-item"
                           NavigateUrl="~/Admin/Settings.aspx?sec=notifications">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                    <path d="M13.73 21a2 2 0 01-3.46 0"/>
                </svg>
                Thông báo
                <span class="settings-nav-arrow">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="9,18 15,12 9,6"/>
                    </svg>
                </span>
            </asp:HyperLink>
        </nav>

        <%-- ─── RIGHT CONTENT ─── --%>
        <div class="content">

            <%-- ╔═══════ SECTION: PROFILE ═══════╗ --%>
            <asp:Panel ID="pnlProfile" runat="server" CssClass="section">

                <%-- Profile card --%>
                <div class="card">
                    <div class="card-head">
                        <div>
                            <div class="card-title">Hồ sơ <em>cá nhân</em></div>
                            <div class="card-sub">Thông tin sẽ hiển thị trên các sự kiện bạn tổ chức và quản lý.</div>
                        </div>
                        <div class="card-tag">CÔNG KHAI</div>
                    </div>

                    <div class="avatar-editor">
                        <div class="avatar-big">
                            <asp:Literal ID="litAvatarInitial" runat="server" />
                        </div>
                        <div class="avatar-editor-info">
                            <div class="avatar-editor-name"><asp:Literal ID="litUserName" runat="server" /></div>
                            <div class="avatar-editor-role">
                                Quản trị viên · <b><asp:Literal ID="litUserDept" runat="server" /></b>
                            </div>
                            <div class="avatar-editor-actions">
                                <asp:FileUpload ID="fuAvatar" runat="server" CssClass="avatar-file" />
                                <asp:LinkButton ID="btnRemoveAvatar" runat="server" CssClass="btn-small danger-ghost"
                                                OnClick="btnRemoveAvatar_Click" CausesValidation="false">
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <polyline points="3,6 5,6 21,6"/>
                                        <path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/>
                                    </svg>
                                    Xoá ảnh
                                </asp:LinkButton>
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="field">
                            <label class="label">Họ <span class="req">*</span></label>
                            <asp:TextBox ID="txtFirstName" runat="server" CssClass="input" MaxLength="60" />
                        </div>
                        <div class="field">
                            <label class="label">Tên <span class="req">*</span></label>
                            <asp:TextBox ID="txtLastName" runat="server" CssClass="input" MaxLength="60" />
                        </div>
                    </div>

                    <div class="row">
                        <div class="field">
                            <label class="label">Tên hiển thị</label>
                            <asp:TextBox ID="txtDisplayName" runat="server" CssClass="input" MaxLength="120"
                                         placeholder="Tên ngắn hiển thị trên giao diện" />
                        </div>
                        <div class="field">
                            <label class="label">Chức danh</label>
                            <asp:TextBox ID="txtJobTitle" runat="server" CssClass="input" MaxLength="120"
                                         placeholder="VD: Trưởng ban Tổ chức" />
                        </div>
                    </div>

                    <div class="row">
                        <div class="field">
                            <label class="label">
                                Email công ty <span class="req">*</span>
                                <asp:Literal ID="litEmailHint" runat="server" />
                            </label>
                            <div class="input-with-icon">
                                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/>
                                    <polyline points="22,6 12,13 2,6"/>
                                </svg>
                                <asp:TextBox ID="txtEmail" runat="server" CssClass="input" ReadOnly="true" />
                            </div>
                        </div>
                        <div class="field">
                            <label class="label">Số điện thoại</label>
                            <div class="input-with-icon">
                                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M22 16.92v3a2 2 0 01-2.18 2 19.79 19.79 0 01-8.63-3.07 19.5 19.5 0 01-6-6 19.79 19.79 0 01-3.07-8.67A2 2 0 014.11 2h3a2 2 0 012 1.72c.127.96.361 1.903.7 2.81a2 2 0 01-.45 2.11L8.09 9.91a16 16 0 006 6l1.27-1.27a2 2 0 012.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0122 16.92z"/>
                                </svg>
                                <asp:TextBox ID="txtPhone" runat="server" CssClass="input" MaxLength="20"
                                             placeholder="+84 ..." />
                            </div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="field">
                            <label class="label">Phòng ban</label>
                            <asp:DropDownList ID="ddlDepartment" runat="server" CssClass="select" />
                        </div>
                        <div class="field">
                            <label class="label">
                                Mã nhân viên
                                <span class="hint mono">Không thể chỉnh sửa</span>
                            </label>
                            <asp:TextBox ID="txtEmployeeCode" runat="server" CssClass="input mono" ReadOnly="true" />
                        </div>
                    </div>

                    <div class="field">
                        <label class="label">
                            Giới thiệu ngắn
                            <span class="hint" id="bioCount">0 / 240</span>
                        </label>
                        <asp:TextBox ID="txtBio" runat="server" CssClass="textarea"
                                     TextMode="MultiLine" Rows="3" MaxLength="240"
                                     placeholder="Một vài dòng về vai trò và lĩnh vực phụ trách..." />
                    </div>

                    <div class="actionbar">
                        <asp:LinkButton ID="btnCancelProfile" runat="server" CssClass="btn btn-ghost"
                                        OnClick="btnCancelProfile_Click" CausesValidation="false">
                            Huỷ thay đổi
                        </asp:LinkButton>
                        <asp:Button ID="btnSaveProfile" runat="server" CssClass="btn btn-primary"
                                    Text="Lưu thay đổi" OnClick="btnSaveProfile_Click" />
                    </div>
                </div>

            </asp:Panel>

            <%-- ╔═══════ SECTION: SECURITY ═══════╗ --%>
            <asp:Panel ID="pnlSecurity" runat="server" CssClass="section" Visible="false">

                <%-- Change password --%>
                <div class="card">
                    <div class="card-head">
                        <div>
                            <div class="card-title">Đổi <em>mật khẩu</em></div>
                            <div class="card-sub">Cập nhật mật khẩu định kỳ để giữ tài khoản an toàn.</div>
                        </div>
                        <div class="card-tag"><asp:Literal ID="litPwLastChanged" runat="server" /></div>
                    </div>

                    <div class="field">
                        <label class="label">Mật khẩu hiện tại <span class="req">*</span></label>
                        <asp:TextBox ID="txtPwCurrent" runat="server" CssClass="input"
                                     TextMode="Password" placeholder="••••••••••••" />
                    </div>

                    <div class="row">
                        <div class="field">
                            <label class="label">Mật khẩu mới <span class="req">*</span></label>
                            <asp:TextBox ID="txtPwNew" runat="server" CssClass="input"
                                         TextMode="Password" placeholder="Tối thiểu 8 ký tự"
                                         ClientIDMode="Static" />
                        </div>
                        <div class="field">
                            <label class="label">Xác nhận mật khẩu <span class="req">*</span></label>
                            <asp:TextBox ID="txtPwConfirm" runat="server" CssClass="input"
                                         TextMode="Password" placeholder="Nhập lại mật khẩu mới" />
                        </div>
                    </div>

                    <div class="pw-strength" id="pwStrength">
                        <div class="pw-strength-bar">
                            <div></div><div></div><div></div><div></div>
                        </div>
                        <div class="pw-strength-label">
                            <span>Độ mạnh</span>
                            <b id="pwStrengthLabel">Chưa nhập</b>
                        </div>
                    </div>

                    <div class="pw-rules">
                        <div class="pw-rules-title">Yêu cầu mật khẩu</div>
                        <div class="pw-rule" id="rule-length">
                            <div class="tick"><svg viewBox="0 0 24 24" fill="none" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20,6 9,17 4,12"/></svg></div>
                            Ít nhất 8 ký tự
                        </div>
                        <div class="pw-rule" id="rule-upper">
                            <div class="tick"><svg viewBox="0 0 24 24" fill="none" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20,6 9,17 4,12"/></svg></div>
                            Bao gồm chữ HOA và chữ thường
                        </div>
                        <div class="pw-rule" id="rule-digit">
                            <div class="tick"><svg viewBox="0 0 24 24" fill="none" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20,6 9,17 4,12"/></svg></div>
                            Bao gồm ít nhất 1 chữ số
                        </div>
                        <div class="pw-rule" id="rule-special">
                            <div class="tick"><svg viewBox="0 0 24 24" fill="none" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20,6 9,17 4,12"/></svg></div>
                            Bao gồm ít nhất 1 ký tự đặc biệt (!@#$%…)
                        </div>
                    </div>

                    <div class="actionbar">
                        <asp:LinkButton ID="btnCancelPw" runat="server" CssClass="btn btn-ghost"
                                        OnClick="btnCancelPw_Click" CausesValidation="false">
                            Huỷ
                        </asp:LinkButton>
                        <asp:Button ID="btnChangePw" runat="server" CssClass="btn btn-primary"
                                    Text="Cập nhật mật khẩu" OnClick="btnChangePw_Click" />
                    </div>
                </div>

                <%-- Active sessions --%>
                <div class="card">
                    <div class="card-head">
                        <div>
                            <div class="card-title">Phiên đăng nhập <em>đang hoạt động</em></div>
                            <div class="card-sub">Bạn có thể đăng xuất từ xa tất cả các thiết bị khác bằng nút bên dưới.</div>
                        </div>
                        <asp:LinkButton ID="btnLogoutOthers" runat="server" CssClass="btn-small danger-ghost"
                                        OnClick="btnLogoutOthers_Click" CausesValidation="false"
                                        OnClientClick="return confirm('Đăng xuất tất cả các phiên KHÁC ngoài thiết bị hiện tại?');">
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/>
                                <polyline points="16,17 21,12 16,7"/>
                                <line x1="21" y1="12" x2="9" y2="12"/>
                            </svg>
                            Đăng xuất các thiết bị khác
                        </asp:LinkButton>
                    </div>

                    <div class="sessions-list">
                        <asp:Repeater ID="rptSessions" runat="server" OnItemCommand="rptSessions_ItemCommand">
                            <ItemTemplate>
                                <div class='<%# "session-row" + ((bool)Eval("IsCurrent") ? " current" : "") %>'>
                                    <div class="session-icon">
                                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                            <rect x="2" y="3" width="20" height="14" rx="2"/>
                                            <line x1="8" y1="21" x2="16" y2="21"/>
                                            <line x1="12" y1="17" x2="12" y2="21"/>
                                        </svg>
                                    </div>
                                    <div class="session-info">
                                        <div class="session-device"><%# Eval("DeviceText") %></div>
                                        <div class="session-meta">
                                            <%# Eval("IpText") %> · Truy cập <%# Eval("LastSeenText") %>
                                        </div>
                                    </div>
                                    <div class='<%# (bool)Eval("IsCurrent") ? "session-tag current" : "session-tag" %>'>
                                        <%# (bool)Eval("IsCurrent") ? "PHIÊN HIỆN TẠI" : Eval("RelativeTime") %>
                                    </div>
                                    <asp:LinkButton runat="server" CssClass="session-btn"
                                                    Visible='<%# !(bool)Eval("IsCurrent") %>'
                                                    CommandName="RevokeSession"
                                                    CommandArgument='<%# Eval("Id") %>'
                                                    CausesValidation="false"
                                                    OnClientClick="return confirm('Đăng xuất phiên này?');"
                                                    ToolTip="Đăng xuất phiên này">
                                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                            <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                                        </svg>
                                    </asp:LinkButton>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>

                        <asp:PlaceHolder ID="phNoSessions" runat="server" Visible="false">
                            <div class="empty-mini">Chỉ có phiên hiện tại đang hoạt động.</div>
                        </asp:PlaceHolder>
                    </div>
                </div>

            </asp:Panel>

            <%-- ╔═══════ SECTION: NOTIFICATIONS ═══════╗ --%>
            <asp:Panel ID="pnlNotifications" runat="server" CssClass="section" Visible="false">

                <%-- Channels --%>
                <div class="card">
                    <div class="card-head">
                        <div>
                            <div class="card-title">Kênh <em>nhận thông báo</em></div>
                            <div class="card-sub">Chọn các kênh nhận thông báo từ hệ thống EventHub.</div>
                        </div>
                    </div>

                    <div class="toggles">
                        <div class="toggle-row">
                            <div class="toggle-info">
                                <div class="toggle-info-title">
                                    Email
                                    <span class="toggle-badge green">KHUYẾN NGHỊ</span>
                                </div>
                                <div class="toggle-info-sub">
                                    Gửi tới: <b><asp:Literal ID="litEmailChannel" runat="server" /></b>
                                </div>
                            </div>
                            <asp:CheckBox ID="cbChannelEmail" runat="server" CssClass="switch-cb" Checked="true" />
                        </div>
                        <div class="toggle-row">
                            <div class="toggle-info">
                                <div class="toggle-info-title">Thông báo đẩy (Push)</div>
                                <div class="toggle-info-sub">Hiện thông báo trực tiếp trên trình duyệt khi bạn đang mở EventHub.</div>
                            </div>
                            <asp:CheckBox ID="cbChannelPush" runat="server" CssClass="switch-cb" Checked="true" />
                        </div>
                        <div class="toggle-row">
                            <div class="toggle-info">
                                <div class="toggle-info-title">SMS</div>
                                <div class="toggle-info-sub">Chỉ áp dụng cho cảnh báo bảo mật quan trọng.</div>
                            </div>
                            <asp:CheckBox ID="cbChannelSms" runat="server" CssClass="switch-cb" />
                        </div>
                    </div>
                </div>

                <%-- Notification types --%>
                <div class="card">
                    <div class="card-head">
                        <div>
                            <div class="card-title">Loại <em>thông báo</em></div>
                            <div class="card-sub">Bật/tắt từng loại sự kiện cần thông báo.</div>
                        </div>
                    </div>

                    <div class="toggles">
                        <div class="toggle-row">
                            <div class="toggle-info">
                                <div class="toggle-info-title">Đăng ký mới chờ duyệt</div>
                                <div class="toggle-info-sub">Khi có người gửi yêu cầu tham gia sự kiện bạn quản lý.</div>
                            </div>
                            <asp:CheckBox ID="cbNotifNewReg" runat="server" CssClass="switch-cb" Checked="true" />
                        </div>
                        <div class="toggle-row">
                            <div class="toggle-info">
                                <div class="toggle-info-title">Sự kiện sắp đầy chỗ</div>
                                <div class="toggle-info-sub">Khi sự kiện đạt 85% sức chứa.</div>
                            </div>
                            <asp:CheckBox ID="cbNotifFull" runat="server" CssClass="switch-cb" Checked="true" />
                        </div>
                        <div class="toggle-row">
                            <div class="toggle-info">
                                <div class="toggle-info-title">Nhắc trước sự kiện</div>
                                <div class="toggle-info-sub">Nhận nhắc nhở 24h, 1h trước khi sự kiện diễn ra.</div>
                            </div>
                            <asp:CheckBox ID="cbNotifReminder" runat="server" CssClass="switch-cb" Checked="true" />
                        </div>
                        <div class="toggle-row">
                            <div class="toggle-info">
                                <div class="toggle-info-title">Báo cáo hàng tuần</div>
                                <div class="toggle-info-sub">Tổng kết hoạt động sự kiện gửi vào sáng thứ Hai.</div>
                            </div>
                            <asp:CheckBox ID="cbNotifWeekly" runat="server" CssClass="switch-cb" />
                        </div>
                        <div class="toggle-row">
                            <div class="toggle-info">
                                <div class="toggle-info-title">
                                    Cảnh báo bảo mật
                                    <span class="toggle-badge amber">BẮT BUỘC</span>
                                </div>
                                <div class="toggle-info-sub">Đăng nhập từ thiết bị lạ, đổi mật khẩu, thay đổi quyền.</div>
                            </div>
                            <asp:CheckBox ID="cbNotifSecurity" runat="server" CssClass="switch-cb" Checked="true" Enabled="false" />
                        </div>
                    </div>
                </div>

                <%-- Quiet hours --%>
                <div class="card">
                    <div class="card-head">
                        <div>
                            <div class="card-title">Giờ <em>im lặng</em></div>
                            <div class="card-sub">Trong khung giờ này, hệ thống sẽ không gửi push/SMS (trừ cảnh báo bảo mật).</div>
                        </div>
                        <asp:CheckBox ID="cbQuietEnabled" runat="server" CssClass="switch-cb" />
                    </div>

                    <div class="row" style="margin-bottom: 0;">
                        <div class="field">
                            <label class="label">Bắt đầu</label>
                            <asp:TextBox ID="txtQuietStart" runat="server" CssClass="input"
                                         TextMode="Time" Text="22:00" />
                        </div>
                        <div class="field">
                            <label class="label">Kết thúc</label>
                            <asp:TextBox ID="txtQuietEnd" runat="server" CssClass="input"
                                         TextMode="Time" Text="07:00" />
                        </div>
                    </div>
                </div>

                <div class="actionbar full">
                    <asp:LinkButton ID="btnCancelNotif" runat="server" CssClass="btn btn-ghost"
                                    OnClick="btnCancelNotif_Click" CausesValidation="false">
                        Huỷ
                    </asp:LinkButton>
                    <asp:Button ID="btnSaveNotif" runat="server" CssClass="btn btn-primary"
                                Text="Lưu cài đặt thông báo" OnClick="btnSaveNotif_Click" />
                </div>

            </asp:Panel>

        </div>
    </div>
</asp:Content>

<asp:Content ID="cScripts" ContentPlaceHolderID="ScriptContent" runat="server">
    <script>
        (function () {
            // Bio character counter
            var bio = document.getElementById('<%= txtBio.ClientID %>');
            var bioCount = document.getElementById('bioCount');
            if (bio && bioCount) {
                function syncBio() {
                    bioCount.textContent = bio.value.length + ' / 240';
                }
                bio.addEventListener('input', syncBio);
                syncBio();
            }

            // Password strength meter (chỉ trong section security)
            var pwNew = document.getElementById('txtPwNew');
            if (pwNew) {
                var strBars = document.querySelectorAll('#pwStrength .pw-strength-bar > div');
                var strLabel = document.getElementById('pwStrengthLabel');
                var rules = {
                    length:  function (s) { return s.length >= 8; },
                    upper:   function (s) { return /[a-z]/.test(s) && /[A-Z]/.test(s); },
                    digit:   function (s) { return /\d/.test(s); },
                    special: function (s) { return /[^A-Za-z0-9]/.test(s); }
                };
                pwNew.addEventListener('input', function () {
                    var v = pwNew.value;
                    var passed = 0;
                    for (var k in rules) {
                        var ok = rules[k](v);
                        var row = document.getElementById('rule-' + k);
                        if (row) row.classList.toggle('ok', ok);
                        if (ok) passed++;
                    }
                    // Update bars
                    strBars.forEach(function (b, i) {
                        b.className = '';
                        if (i < passed) {
                            if (passed === 1) b.className = 'weak';
                            else if (passed === 2) b.className = 'medium';
                            else if (passed === 3) b.className = 'good';
                            else if (passed === 4) b.className = 'strong';
                        }
                    });
                    if (strLabel) {
                        if (!v) strLabel.textContent = 'Chưa nhập';
                        else if (passed <= 1) strLabel.textContent = 'Yếu';
                        else if (passed === 2) strLabel.textContent = 'Trung bình';
                        else if (passed === 3) strLabel.textContent = 'Khá';
                        else strLabel.textContent = 'Mạnh';
                    }
                });
            }
        })();
    </script>
</asp:Content>
