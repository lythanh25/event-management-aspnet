<%@ Page Language="C#"
    MasterPageFile="~/UserMaster.Master"
    AutoEventWireup="true"
    CodeBehind="UserProfile.aspx.cs"
    Inherits="Eventhub.User.UserProfile" %>

<%-- ════════════ TITLE ════════════ --%>
<asp:Content ID="cntTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Hồ sơ cá nhân — EventHub
</asp:Content>

<%-- ════════════ HEAD ════════════ --%>
<asp:Content ID="cntHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Content/UserProfile.css") %>" rel="stylesheet" type="text/css" />
</asp:Content>

<%-- ════════════ HERO (dark zone) ════════════ --%>
<asp:Content ID="cntHero" ContentPlaceHolderID="HeroContent" runat="server">
    <section class="profile-hero">

        <%-- Breadcrumb --%>
        <div class="breadcrumb">
            <a href="<%= ResolveUrl("~/User/UserHome.aspx") %>">Trang chủ</a>
            <span class="sep">›</span>
            <span class="current">Hồ sơ cá nhân</span>
        </div>

        <%-- Hero card --%>
        <div class="hero-card">
            <div class="big-avatar">
                <asp:Literal ID="litAvatarInitial" runat="server" Text="?" />
            </div>

            <div class="hero-info">
                <div class="hero-tag">HỒ SƠ CÁ NHÂN</div>
                <h1 class="hero-name">
                    <asp:Literal ID="litHeroName" runat="server" Text="Người dùng" />
                </h1>
                <div class="hero-role-line">
                    <div>
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
                            <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/>
                        </svg>
                        <asp:Literal ID="litHeroDept" runat="server" Text="—" />
                    </div>
                    <div>
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
                            <rect x="2" y="7" width="20" height="14" rx="2"/>
                            <path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/>
                        </svg>
                        <asp:Literal ID="litHeroJobTitle" runat="server" Text="—" />
                    </div>
                    <div>
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="12" r="10"/>
                            <polyline points="12,6 12,12 16,14"/>
                        </svg>
                        Tham gia từ <b><asp:Literal ID="litHeroJoined" runat="server" Text="—" /></b>
                    </div>
                </div>

                <div class="hero-badges">
                    <asp:Panel ID="pnlBadgeTier" runat="server" CssClass="hero-badge gold" Visible="false">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="8" r="7"/>
                            <polyline points="8.21,13.89 7,23 12,20 17,23 15.79,13.88"/>
                        </svg>
                        <asp:Literal ID="litBadgeTier" runat="server" />
                    </asp:Panel>

                    <asp:Panel ID="pnlBadgeVerified" runat="server" CssClass="hero-badge green" Visible="false">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
                            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                            <polyline points="9,12 11,14 15,10"/>
                        </svg>
                        Email đã xác thực
                    </asp:Panel>

                    <asp:Panel ID="pnlBadgeEmpCode" runat="server" CssClass="hero-badge" Visible="false">
                        <asp:Literal ID="litBadgeEmpCode" runat="server" />
                    </asp:Panel>
                </div>
            </div>

            <div class="hero-actions">
                <asp:LinkButton ID="btnEditHero" runat="server" CssClass="btn-hero primary"
                                OnClientClick="switchSection('profile');return false;">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                        <path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/>
                        <path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/>
                    </svg>
                    Chỉnh sửa hồ sơ
                </asp:LinkButton>
                <button type="button" class="btn-hero ghost"
                        onclick="copyProfileLink()">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                        <path d="M4 12v8a2 2 0 002 2h12a2 2 0 002-2v-8"/>
                        <polyline points="16,6 12,2 8,6"/>
                        <line x1="12" y1="2" x2="12" y2="15"/>
                    </svg>
                    Chia sẻ hồ sơ
                </button>
            </div>
        </div>

        <%-- Stat strip --%>
        <div class="stat-strip">
            <div class="stat-cell">
                <div class="stat-cell-num">
                    <asp:Literal ID="litStatEventsAttended" runat="server" Text="0" />
                </div>
                <div class="stat-cell-lbl">Sự kiện đã tham gia</div>
            </div>
            <div class="stat-cell">
                <div class="stat-cell-num amber">
                    <asp:Literal ID="litStatPending" runat="server" Text="0" />
                </div>
                <div class="stat-cell-lbl">Đang chờ duyệt</div>
            </div>
            <div class="stat-cell">
                <div class="stat-cell-num green">
                    <asp:Literal ID="litStatAttendRate" runat="server" Text="0" /><small>%</small>
                </div>
                <div class="stat-cell-lbl">Tỉ lệ tham dự</div>
            </div>
            <div class="stat-cell">
                <div class="stat-cell-num">
                    <asp:Literal ID="litStatTrainingHours" runat="server" Text="0" />
                </div>
                <div class="stat-cell-lbl">Giờ đào tạo</div>
            </div>
            <div class="stat-cell">
                <div class="stat-cell-num amber">
                    <asp:Literal ID="litStatPoints" runat="server" Text="0" />
                </div>
                <div class="stat-cell-lbl">Điểm tích luỹ</div>
            </div>
        </div>

    </section>
</asp:Content>

<%-- ════════════ MAIN ════════════ --%>
<asp:Content ID="cntMain" ContentPlaceHolderID="MainContent" runat="server">

    <%-- Hidden field: tab đang hiển thị --%>
    <asp:HiddenField ID="hfSection" runat="server" Value="profile" />

    <div class="profile-zone">

        <%-- Alert --%>
        <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="pf-alert info">
            <asp:Literal ID="litAlert" runat="server" />
        </asp:Panel>

        <div class="profile-layout">

            <%-- ══════ SIDE NAV ══════ --%>
            <aside class="side-nav">
                <div class="nav-card">
                    <div class="nav-card-label">Tài khoản</div>

                    <a id="navProfile"       class="nav-item" href="javascript:void(0)" onclick="switchSection('profile')">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                        Hồ sơ cá nhân
                        <span class="nav-arrow"><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9,18 15,12 9,6"/></svg></span>
                    </a>
                    <a id="navContact"       class="nav-item" href="javascript:void(0)" onclick="switchSection('contact')">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                        Liên hệ &amp; Địa chỉ
                        <span class="nav-arrow"><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9,18 15,12 9,6"/></svg></span>
                    </a>
                    <a id="navNotifications" class="nav-item" href="javascript:void(0)" onclick="switchSection('notifications')">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>
                        Thông báo
                        <span class="nav-arrow"><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9,18 15,12 9,6"/></svg></span>
                    </a>
                    <a id="navSecurity"      class="nav-item" href="javascript:void(0)" onclick="switchSection('security')">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
                        Bảo mật &amp; Mật khẩu
                        <span class="nav-arrow"><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9,18 15,12 9,6"/></svg></span>
                    </a>
                    <a id="navActivity"      class="nav-item" href="javascript:void(0)" onclick="switchSection('activity')">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="22,12 18,12 15,21 9,3 6,12 2,12"/></svg>
                        Hoạt động gần đây
                        <span class="nav-arrow"><svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="9,18 15,12 9,6"/></svg></span>
                    </a>
                </div>

                <asp:LinkButton ID="btnLogoutSide" runat="server" CssClass="logout-item"
                                OnClick="btnLogoutSide_Click" CausesValidation="false">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                        <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/>
                        <polyline points="16,17 21,12 16,7"/>
                        <line x1="21" y1="12" x2="9" y2="12"/>
                    </svg>
                    Đăng xuất khỏi tài khoản
                </asp:LinkButton>

                <div class="tip-card">
                    <div class="tip-title">Mẹo nhỏ</div>
                    <div class="tip-sub">Cập nhật thông tin liên hệ giúp Ban tổ chức gửi thông báo sự kiện chính xác đến bạn.</div>
                </div>
            </aside>

            <%-- ══════ CONTENT ══════ --%>
            <div class="content" id="profileContent">

                <%-- ═══ SECTION: PROFILE ═══ --%>
                <div class="section" id="sec-profile">

                    <%-- Thông tin cơ bản --%>
                    <div class="pf-card">
                        <div class="card-head">
                            <div class="card-head-l">
                                <div class="card-head-icon">
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                                </div>
                                <div>
                                    <div class="card-title">Thông tin <em>cơ bản</em></div>
                                    <div class="card-sub">Thông tin định danh và công việc của bạn</div>
                                </div>
                            </div>
                        </div>

                        <div class="row">
                            <div class="field">
                                <label class="label">Họ <span class="req">*</span></label>
                                <asp:TextBox ID="txtLastName" runat="server" CssClass="input" MaxLength="60" />
                            </div>
                            <div class="field">
                                <label class="label">Tên <span class="req">*</span></label>
                                <asp:TextBox ID="txtFirstName" runat="server" CssClass="input" MaxLength="60" />
                            </div>
                        </div>

                        <div class="row">
                            <div class="field">
                                <label class="label">Tên hiển thị</label>
                                <asp:TextBox ID="txtDisplayName" runat="server" CssClass="input" MaxLength="120" />
                            </div>
                            <div class="field">
                                <label class="label">Ngày sinh</label>
                                <asp:TextBox ID="txtDateOfBirth" runat="server" CssClass="input"
                                             TextMode="Date" />
                            </div>
                        </div>

                        <div class="row">
                            <div class="field">
                                <label class="label">Giới tính</label>
                                <asp:DropDownList ID="ddlGender" runat="server" CssClass="select">
                                    <asp:ListItem Value=""              Text="— Chọn —" />
                                    <asp:ListItem Value="male"          Text="Nam" />
                                    <asp:ListItem Value="female"        Text="Nữ" />
                                    <asp:ListItem Value="other"         Text="Khác" />
                                    <asp:ListItem Value="undisclosed"   Text="Không muốn tiết lộ" />
                                </asp:DropDownList>
                            </div>
                            <div class="field">
                                <label class="label">
                                    Mã nhân viên
                                    <span class="hint mono">Không thể chỉnh sửa</span>
                                </label>
                                <asp:TextBox ID="txtEmpCode" runat="server" CssClass="input mono"
                                             ReadOnly="true" Enabled="false" />
                            </div>
                        </div>

                        <div class="field" style="margin-bottom:0;">
                            <label class="label">
                                Giới thiệu ngắn
                                <span class="hint" id="bioCount">0 / 240</span>
                            </label>
                            <asp:TextBox ID="txtBio" runat="server" CssClass="textarea"
                                         TextMode="MultiLine" Rows="3" MaxLength="240"
                                         onkeyup="updateBioCount(this)" />
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

                    <%-- Thông tin công việc (read-only) --%>
                    <div class="pf-card">
                        <div class="card-head">
                            <div class="card-head-l">
                                <div class="card-head-icon">
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 00-2-2h-4a2 2 0 00-2 2v16"/></svg>
                                </div>
                                <div>
                                    <div class="card-title">Thông tin <em>công việc</em></div>
                                    <div class="card-sub">Phòng ban và chức vụ tại công ty</div>
                                </div>
                            </div>
                        </div>

                        <div class="row">
                            <div class="field">
                                <label class="label">Phòng ban</label>
                                <asp:TextBox ID="txtDept" runat="server" CssClass="input"
                                             ReadOnly="true" Enabled="false" />
                            </div>
                            <div class="field">
                                <label class="label">Chức vụ</label>
                                <asp:TextBox ID="txtJobTitle" runat="server" CssClass="input"
                                             ReadOnly="true" Enabled="false" />
                            </div>
                        </div>

                        <div class="row">
                            <div class="field">
                                <label class="label">Email công ty</label>
                                <asp:TextBox ID="txtEmailWork" runat="server" CssClass="input"
                                             ReadOnly="true" Enabled="false" />
                            </div>
                            <div class="field">
                                <label class="label">Ngày vào hệ thống</label>
                                <asp:TextBox ID="txtJoinedAt" runat="server" CssClass="input"
                                             ReadOnly="true" Enabled="false" />
                            </div>
                        </div>
                    </div>

                    <%-- Sở thích sự kiện --%>
                    <div class="pf-card">
                        <div class="card-head">
                            <div class="card-head-l">
                                <div class="card-head-icon">
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><path d="M8 14s1.5 2 4 2 4-2 4-2"/><line x1="9" y1="9" x2="9.01" y2="9"/><line x1="15" y1="9" x2="15.01" y2="9"/></svg>
                                </div>
                                <div>
                                    <div class="card-title">Sở thích <em>sự kiện</em></div>
                                    <div class="card-sub">Giúp hệ thống gợi ý sự kiện phù hợp với bạn</div>
                                </div>
                            </div>
                        </div>

                        <div class="row">
                            <div class="field">
                                <label class="label">Hình thức ưu tiên</label>
                                <asp:DropDownList ID="ddlPreferFormat" runat="server" CssClass="select">
                                    <asp:ListItem Value="offline" Text="Trực tiếp (Offline)" />
                                    <asp:ListItem Value="online"  Text="Trực tuyến (Online)" />
                                    <asp:ListItem Value="both"    Text="Cả hai hình thức" Selected="True" />
                                </asp:DropDownList>
                            </div>
                            <div class="field">
                                <label class="label">Ngôn ngữ giao diện</label>
                                <asp:DropDownList ID="ddlLanguage" runat="server" CssClass="select">
                                    <asp:ListItem Value="vi" Text="Tiếng Việt" Selected="True" />
                                    <asp:ListItem Value="en" Text="English" />
                                </asp:DropDownList>
                            </div>
                        </div>

                        <div class="actionbar">
                            <asp:Button ID="btnSavePrefs" runat="server" CssClass="btn btn-primary"
                                        Text="Lưu sở thích" OnClick="btnSavePrefs_Click" />
                        </div>
                    </div>

                </div>

                <%-- ═══ SECTION: CONTACT ═══ --%>
                <div class="section" id="sec-contact" style="display:none;">

                    <div class="pf-card">
                        <div class="card-head">
                            <div class="card-head-l">
                                <div class="card-head-icon">
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"/><polyline points="22,6 12,13 2,6"/></svg>
                                </div>
                                <div>
                                    <div class="card-title">Thông tin <em>liên hệ</em></div>
                                    <div class="card-sub">Email, số điện thoại và mạng xã hội</div>
                                </div>
                            </div>
                        </div>

                        <div class="row">
                            <div class="field">
                                <label class="label">Email công ty <span class="req">*</span>
                                    <asp:Panel ID="pnlEmailVerified" runat="server" CssClass="hint" style="display:inline;">Đã xác thực</asp:Panel>
                                </label>
                                <asp:TextBox ID="txtEmailWork2" runat="server" CssClass="input"
                                             ReadOnly="true" Enabled="false" />
                            </div>
                            <div class="field">
                                <label class="label">Email cá nhân</label>
                                <asp:TextBox ID="txtEmailPersonal" runat="server" CssClass="input"
                                             MaxLength="190" TextMode="Email" />
                            </div>
                        </div>

                        <div class="row">
                            <div class="field">
                                <label class="label">Số điện thoại</label>
                                <asp:TextBox ID="txtPhone" runat="server" CssClass="input"
                                             MaxLength="20" />
                            </div>
                            <div class="field">
                                <label class="label">Số máy lẻ nội bộ</label>
                                <asp:TextBox ID="txtExtension" runat="server" CssClass="input"
                                             MaxLength="10" />
                            </div>
                        </div>

                        <div class="field">
                            <label class="label">Địa chỉ nơi ở</label>
                            <asp:TextBox ID="txtAddress" runat="server" CssClass="input" MaxLength="255" />
                        </div>

                        <div class="row" style="margin-bottom:0;">
                            <div class="field">
                                <label class="label">LinkedIn</label>
                                <asp:TextBox ID="txtLinkedIn" runat="server" CssClass="input"
                                             MaxLength="255" placeholder="linkedin.com/in/..." />
                            </div>
                            <div class="field">
                                <label class="label">GitHub</label>
                                <asp:TextBox ID="txtGitHub" runat="server" CssClass="input"
                                             MaxLength="255" placeholder="github.com/..." />
                            </div>
                        </div>

                        <div class="actionbar">
                            <asp:Button ID="btnSaveContact" runat="server" CssClass="btn btn-primary"
                                        Text="Lưu liên hệ" OnClick="btnSaveContact_Click" />
                        </div>
                    </div>

                    <%-- Liên hệ khẩn cấp --%>
                    <div class="pf-card">
                        <div class="card-head">
                            <div class="card-head-l">
                                <div class="card-head-icon" style="background:var(--red-soft);color:var(--red);">
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
                                </div>
                                <div>
                                    <div class="card-title">Liên hệ <em>khẩn cấp</em></div>
                                    <div class="card-sub">Sẽ được liên hệ trong trường hợp khẩn cấp tại sự kiện</div>
                                </div>
                            </div>
                        </div>

                        <div class="row">
                            <div class="field">
                                <label class="label">Họ tên</label>
                                <asp:TextBox ID="txtEmergName" runat="server" CssClass="input" MaxLength="120" />
                            </div>
                            <div class="field">
                                <label class="label">Mối quan hệ</label>
                                <asp:DropDownList ID="ddlEmergRelation" runat="server" CssClass="select">
                                    <asp:ListItem Value="parent"  Text="Bố/Mẹ" />
                                    <asp:ListItem Value="sibling" Text="Anh/Chị/Em" />
                                    <asp:ListItem Value="spouse"  Text="Vợ/Chồng" />
                                    <asp:ListItem Value="friend"  Text="Bạn bè" />
                                    <asp:ListItem Value="other"   Text="Khác" />
                                </asp:DropDownList>
                            </div>
                        </div>

                        <div class="field" style="margin-bottom:0;">
                            <label class="label">Số điện thoại liên hệ</label>
                            <asp:TextBox ID="txtEmergPhone" runat="server" CssClass="input" MaxLength="20" />
                        </div>

                        <div class="actionbar">
                            <asp:Button ID="btnSaveEmerg" runat="server" CssClass="btn btn-primary"
                                        Text="Lưu liên hệ khẩn cấp" OnClick="btnSaveEmerg_Click" />
                        </div>
                    </div>

                </div>

                <%-- ═══ SECTION: NOTIFICATIONS ═══ --%>
                <div class="section" id="sec-notifications" style="display:none;">

                    <div class="pf-card">
                        <div class="card-head">
                            <div class="card-head-l">
                                <div class="card-head-icon">
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 01-3.46 0"/></svg>
                                </div>
                                <div>
                                    <div class="card-title">Tuỳ chỉnh <em>thông báo</em></div>
                                    <div class="card-sub">Chọn loại thông báo bạn muốn nhận</div>
                                </div>
                            </div>
                        </div>

                        <%-- Repeater để render từng loại thông báo --%>
                        <asp:Repeater ID="rptNotifPrefs" runat="server">
                            <ItemTemplate>
                                <div class="toggle-row">
                                    <div class="toggle-info">
                                        <div class="toggle-info-title">
                                            <%# Eval("label") %>
                                            <asp:Panel ID="pnlNotifBadge" runat="server"
                                                       CssClass="toggle-badge amber"
                                                       Visible='<%# (bool)Eval("is_recommended") %>'>
                                                KHUYẾN NGHỊ
                                            </asp:Panel>
                                        </div>
                                        <div class="toggle-info-sub"><%# Eval("description") %></div>
                                    </div>
                                    <asp:CheckBox ID="chkNotif" runat="server"
                                                  CssClass="toggle-checkbox"
                                                  Checked='<%# Convert.ToBoolean(Eval("via_email")) %>' />
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>

                        <div class="actionbar">
                            <asp:Button ID="btnSaveNotifs" runat="server" CssClass="btn btn-primary"
                                        Text="Lưu cài đặt thông báo" OnClick="btnSaveNotifs_Click" />
                        </div>
                    </div>

                </div>

                <%-- ═══ SECTION: SECURITY ═══ --%>
                <div class="section" id="sec-security" style="display:none;">

                    <%-- Đổi mật khẩu --%>
                    <div class="pf-card">
                        <div class="card-head">
                            <div class="card-head-l">
                                <div class="card-head-icon">
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
                                </div>
                                <div>
                                    <div class="card-title">Đổi <em>mật khẩu</em></div>
                                    <div class="card-sub">Nên đổi mật khẩu định kỳ để bảo mật tài khoản</div>
                                </div>
                            </div>
                        </div>

                        <div class="field">
                            <label class="label">Mật khẩu hiện tại</label>
                            <div class="pw-field">
                                <asp:TextBox ID="txtPwCurrent" runat="server" CssClass="input"
                                             TextMode="Password" placeholder="••••••••" />
                                <button type="button" class="pw-toggle" onclick="togglePw('<%=txtPwCurrent.ClientID%>', this)">
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                                    Hiện
                                </button>
                            </div>
                        </div>

                        <div class="row">
                            <div class="field">
                                <label class="label">Mật khẩu mới</label>
                                <div class="pw-field">
                                    <asp:TextBox ID="txtPwNew" runat="server" CssClass="input"
                                                 TextMode="Password" placeholder="Tối thiểu 8 ký tự" />
                                    <button type="button" class="pw-toggle" onclick="togglePw('<%=txtPwNew.ClientID%>', this)">
                                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                                        Hiện
                                    </button>
                                </div>
                            </div>
                            <div class="field">
                                <label class="label">Xác nhận mật khẩu mới</label>
                                <div class="pw-field">
                                    <asp:TextBox ID="txtPwConfirm" runat="server" CssClass="input"
                                                 TextMode="Password" placeholder="Nhập lại mật khẩu" />
                                    <button type="button" class="pw-toggle" onclick="togglePw('<%=txtPwConfirm.ClientID%>', this)">
                                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                                        Hiện
                                    </button>
                                </div>
                            </div>
                        </div>

                        <div class="actionbar">
                            <asp:Button ID="btnChangePassword" runat="server" CssClass="btn btn-primary"
                                        Text="Cập nhật mật khẩu" OnClick="btnChangePassword_Click" />
                        </div>
                    </div>

                    <%-- Phiên đăng nhập --%>
                    <div class="pf-card">
                        <div class="card-head">
                            <div class="card-head-l">
                                <div class="card-head-icon">
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
                                </div>
                                <div>
                                    <div class="card-title">Phiên đăng nhập <em>đang hoạt động</em></div>
                                    <div class="card-sub">Đăng xuất nếu thấy thiết bị lạ</div>
                                </div>
                            </div>
                        </div>

                        <asp:Repeater ID="rptSessions" runat="server"
                                      OnItemCommand="rptSessions_ItemCommand">
                            <ItemTemplate>
                                <div class="session-row">
                                    <div class='<%# "session-icon " + (Convert.ToBoolean(Eval("is_current")) ? "current" : "") %>'>
                                        <%# GetDeviceIcon(Eval("device_type")) %>
                                    </div>
                                    <div>
                                        <div class="session-title">
                                            <%# BuildDeviceLabel(Eval("device_label"), Eval("os"), Eval("browser")) %>
                                            <asp:Panel ID="pnlCurrentBadge" runat="server"
                                                       CssClass="session-current-badge"
                                                       Visible='<%# Convert.ToBoolean(Eval("is_current")) %>'>
                                                HIỆN TẠI
                                            </asp:Panel>
                                        </div>
                                        <div class="session-meta">
                                            <span><%# BuildLocation(Eval("location_city"), Eval("location_country")) %></span>
                                            <span class="sep">•</span>
                                            <span><%# FormatLastActive(Eval("last_active_at")) %></span>
                                        </div>
                                    </div>
                                    <asp:Panel ID="pnlRevokeBtn" runat="server"
                                               Visible='<%# !Convert.ToBoolean(Eval("is_current")) %>'>
                                        <asp:LinkButton ID="btnRevoke" runat="server"
                                                        CssClass="session-revoke"
                                                        CommandName="RevokeSession"
                                                        CommandArgument='<%# Eval("id") %>'>
                                            Đăng xuất
                                        </asp:LinkButton>
                                    </asp:Panel>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>

                        <asp:Panel ID="pnlNoSessions" runat="server" Visible="false"
                                   style="font-size:13px; color:var(--muted); padding:12px 0;">
                            Không có dữ liệu phiên đăng nhập.
                        </asp:Panel>
                    </div>

                    <%-- Danger zone --%>
                    <div class="danger-zone">
                        <div class="danger-head">
                            <div class="danger-icon">
                                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
                            </div>
                            <div class="danger-title">Vùng nguy hiểm</div>
                        </div>
                        <div class="danger-row">
                            <div class="danger-row-info">
                                <div class="danger-row-title">Đăng xuất khỏi mọi thiết bị</div>
                                <div class="danger-row-sub">Buộc đăng xuất tất cả thiết bị, bao gồm thiết bị hiện tại.</div>
                            </div>
                            <asp:Button ID="btnRevokeAll" runat="server" CssClass="danger-btn"
                                        Text="Đăng xuất tất cả"
                                        OnClientClick="return confirm('Bạn sẽ bị đăng xuất ngay. Tiếp tục?');"
                                        OnClick="btnRevokeAll_Click" />
                        </div>
                    </div>

                </div>

                <%-- ═══ SECTION: ACTIVITY ═══ --%>
                <div class="section" id="sec-activity" style="display:none;">

                    <div class="pf-card">
                        <div class="card-head">
                            <div class="card-head-l">
                                <div class="card-head-icon">
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="22,12 18,12 15,21 9,3 6,12 2,12"/></svg>
                                </div>
                                <div>
                                    <div class="card-title">Hoạt động <em>gần đây</em></div>
                                    <div class="card-sub">Các thao tác và sự kiện liên quan đến tài khoản bạn</div>
                                </div>
                            </div>
                        </div>

                        <asp:Repeater ID="rptActivity" runat="server">
                            <HeaderTemplate><div class="activity-list"></HeaderTemplate>
                            <ItemTemplate>
                                <div class="activity-item">
                                    <div class='<%# "activity-icon " + GetActivityColor(Eval("action")) %>'>
                                        <%# GetActivityIcon(Eval("action")) %>
                                    </div>
                                    <div class="activity-content">
                                        <div class="activity-title"><%# Eval("description") %></div>
                                        <div class="activity-meta">
                                            <span><%# FormatActivityTime(Eval("created_at")) %></span>
                                            <asp:Panel ID="pnlIpMeta" runat="server"
                                                       Visible='<%# !string.IsNullOrEmpty(Eval("ip_address") as string) %>'>
                                                <span class="sep">•</span>
                                                <span><%# Eval("ip_address") %></span>
                                            </asp:Panel>
                                        </div>
                                    </div>
                                </div>
                            </ItemTemplate>
                            <FooterTemplate></div></FooterTemplate>
                        </asp:Repeater>

                        <asp:Panel ID="pnlNoActivity" runat="server" Visible="false"
                                   style="font-size:13px; color:var(--muted); padding:16px 0; text-align:center;">
                            Chưa có hoạt động nào được ghi nhận.
                        </asp:Panel>
                    </div>

                </div>

            </div>
        </div>
    </div>

    <%-- ══════ JAVASCRIPT ══════ --%>
    <script type="text/javascript">
        // ── Tab switching ──
        var sections = ['profile', 'contact', 'notifications', 'security', 'activity'];

        function switchSection(name) {
            sections.forEach(function(s) {
                var sec = document.getElementById('sec-' + s);
                var nav = document.getElementById('nav' + s.charAt(0).toUpperCase() + s.slice(1));
                if (sec) sec.style.display = (s === name) ? '' : 'none';
                if (nav) {
                    nav.classList.toggle('active', s === name);
                }
            });
            // Lưu vào hidden field để postback giữ state
            var hf = document.getElementById('<%= hfSection.ClientID %>');
            if (hf) hf.value = name;
        }

        // Phục hồi tab sau postback
        window.addEventListener('DOMContentLoaded', function() {
            var hf = document.getElementById('<%= hfSection.ClientID %>');
            var section = (hf && hf.value) ? hf.value : 'profile';
            switchSection(section);
            // Bio counter
            updateBioCount(document.getElementById('<%= txtBio.ClientID %>'));
        });

        // ── Bio character counter ──
        function updateBioCount(el) {
            if (!el) return;
            var cnt = document.getElementById('bioCount');
            if (cnt) cnt.textContent = el.value.length + ' / 240';
        }

        // ── Password show/hide ──
        function togglePw(inputId, btn) {
            var inp = document.getElementById(inputId);
            if (!inp) return;
            var show = inp.type === 'password';
            inp.type = show ? 'text' : 'password';
            btn.querySelector('svg').style.opacity = show ? '0.5' : '1';
        }

        // ── Share profile ──
        function copyProfileLink() {
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(window.location.href).then(function() {
                    alert('Đã sao chép link hồ sơ!');
                });
            } else {
                prompt('Copy link:', window.location.href);
            }
        }
    </script>

</asp:Content>
