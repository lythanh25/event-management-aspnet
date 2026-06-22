<%@ Page Title="Chi tiết sự kiện" Language="C#" MasterPageFile="~/AdminMaster.Master"
    AutoEventWireup="true" CodeBehind="EventDetail.aspx.cs"
    Inherits="Eventhub.Admin.Eventdetail" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <asp:Literal ID="litPageTitle" runat="server" Text="Chi tiết sự kiện — EventHub Admin" />
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Content/EventDetail.css") %>" rel="stylesheet" type="text/css" />
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <asp:UpdatePanel ID="upMain" runat="server" UpdateMode="Conditional">
        <ContentTemplate>

        <%-- Alert --%>
        <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="alert">
            <asp:Literal ID="litAlert" runat="server" />
        </asp:Panel>

        <%-- ═════════ PAGE HEAD ═════════ --%>
        <div class="page-head">
            <div class="page-head-l">
                <asp:HyperLink ID="lnkBack" runat="server" CssClass="back-link"
                               NavigateUrl="~/Admin/EventsManagement.aspx">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="19" y1="12" x2="5" y2="12"/><polyline points="12,19 5,12 12,5"/>
                    </svg>
                    Quay lại danh sách sự kiện
                </asp:HyperLink>
                <div class="page-title-row">
                    <h1 class="page-title"><asp:Literal ID="litTitle" runat="server" /></h1>
                    <span runat="server" id="spanStatus" class="status-pill-lg">
                        <asp:Literal ID="litStatus" runat="server" />
                    </span>
                </div>
                <div class="page-sub">
                    <span>Tạo lúc <b><asp:Literal ID="litCreatedAt" runat="server" /></b></span>
                    <span class="sep">·</span>
                    <span class="countdown-pill">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/>
                        </svg>
                        <asp:Literal ID="litCountdown" runat="server" />
                    </span>
                    <span class="sep">·</span>
                    <span>Lần sửa cuối <b><asp:Literal ID="litUpdatedAt" runat="server" /></b></span>
                </div>
            </div>
            <div class="page-actions">
                <asp:HyperLink ID="lnkEdit" runat="server" CssClass="btn btn-primary">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/>
                        <path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/>
                    </svg>
                    Chỉnh sửa
                </asp:HyperLink>
            </div>
        </div>

        <%-- ═════════ BANNER ═════════ --%>
        <div class="banner">
            <div class="banner-l">
                <asp:Panel ID="pnlBannerTag" runat="server" CssClass="banner-tag">
                    <asp:Literal ID="litBannerTag1" runat="server" Text="SỰ KIỆN" />
                </asp:Panel>
                <span class="banner-tag amber"><asp:Literal ID="litCategory" runat="server" /></span>
                <h2 class="banner-headline"><asp:Literal ID="litHeadline" runat="server" /></h2>
                <p class="banner-desc"><asp:Literal ID="litSubtitle" runat="server" /></p>
            </div>
            <div class="banner-visual">
                <asp:Image ID="imgBanner" runat="server" Visible="false" CssClass="banner-img" />
                <asp:PlaceHolder ID="phBannerIcon" runat="server">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M9 18h6"/><path d="M10 22h4"/>
                        <path d="M12 2a7 7 0 00-4 12.5V17h8v-2.5A7 7 0 0012 2z"/>
                    </svg>
                </asp:PlaceHolder>
            </div>
        </div>

        <%-- Meta strip --%>
        <div class="banner-meta">
            <div class="banner-meta-cell">
                <div class="banner-meta-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2"/>
                        <line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/>
                        <line x1="3" y1="10" x2="21" y2="10"/>
                    </svg>
                </div>
                <div>
                    <div class="banner-meta-lbl">Ngày</div>
                    <div class="banner-meta-val">
                        <asp:Literal ID="litMetaDate" runat="server" />
                        <small><asp:Literal ID="litMetaDayOfWeek" runat="server" /></small>
                    </div>
                </div>
            </div>

            <div class="banner-meta-cell">
                <div class="banner-meta-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/>
                    </svg>
                </div>
                <div>
                    <div class="banner-meta-lbl">Giờ</div>
                    <div class="banner-meta-val">
                        <asp:Literal ID="litMetaTime" runat="server" />
                        <small><asp:Literal ID="litMetaDuration" runat="server" /></small>
                    </div>
                </div>
            </div>

            <div class="banner-meta-cell">
                <div class="banner-meta-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/>
                        <circle cx="12" cy="10" r="3"/>
                    </svg>
                </div>
                <div>
                    <div class="banner-meta-lbl">Địa điểm</div>
                    <div class="banner-meta-val">
                        <asp:Literal ID="litMetaLocation" runat="server" />
                        <small><asp:Literal ID="litMetaRoom" runat="server" /></small>
                    </div>
                </div>
            </div>

            <div class="banner-meta-cell">
                <div class="banner-meta-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/>
                        <path d="M23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75"/>
                    </svg>
                </div>
                <div>
                    <div class="banner-meta-lbl">Sức chứa</div>
                    <div class="banner-meta-val">
                        <asp:Literal ID="litMetaCapacity" runat="server" />
                        <small><asp:Literal ID="litMetaFormat" runat="server" /></small>
                    </div>
                </div>
            </div>
        </div>

        <%-- ═════════ STATS ═════════ --%>
        <div class="stats">
            <div class="stat">
                <div class="stat-icon dark">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/>
                    </svg>
                </div>
                <div class="stat-body">
                    <div class="stat-value">
                        <asp:Literal ID="litStatRegistered" runat="server" Text="0" />
                        <small>/ <asp:Literal ID="litStatCapacity" runat="server" Text="0" /></small>
                    </div>
                    <div class="stat-label">Đã đăng ký</div>
                </div>
            </div>
            <div class="stat">
                <div class="stat-icon green">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20,6 9,17 4,12"/>
                    </svg>
                </div>
                <div class="stat-body">
                    <div class="stat-value"><asp:Literal ID="litStatApproved" runat="server" Text="0" /></div>
                    <div class="stat-label">Đã duyệt</div>
                </div>
            </div>
            <div class="stat">
                <div class="stat-icon blue">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/>
                    </svg>
                </div>
                <div class="stat-body">
                    <div class="stat-value"><asp:Literal ID="litStatViews" runat="server" Text="0" /></div>
                    <div class="stat-label">Lượt xem</div>
                </div>
            </div>
            <div class="stat">
                <div class="stat-icon amber">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="22,12 18,12 15,21 9,3 6,12 2,12"/>
                    </svg>
                </div>
                <div class="stat-body">
                    <div class="stat-value"><asp:Literal ID="litStatFillRate" runat="server" Text="0" /><small>%</small></div>
                    <div class="stat-label">Tỉ lệ đầy chỗ</div>
                </div>
            </div>
        </div>

        <%-- ═════════ GRID 2-COL ═════════ --%>
        <div class="grid-2">

            <%-- ─── LEFT ─── --%>
            <div>

                <%-- DESCRIPTION --%>
                <div class="card">
                    <div class="card-head">
                        <div class="card-head-l">
                            <div class="card-head-icon">
                                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="3" y="3" width="18" height="18" rx="2"/>
                                    <line x1="9" y1="9" x2="15" y2="9"/><line x1="9" y1="13" x2="15" y2="13"/>
                                    <line x1="9" y1="17" x2="13" y2="17"/>
                                </svg>
                            </div>
                            <div class="card-title">Mô tả <em>sự kiện</em></div>
                        </div>
                    </div>
                    <div class="prose">
                        <asp:Literal ID="litDescription" runat="server" />
                    </div>
                </div>

                <%-- AGENDA --%>
                <asp:Panel ID="pnlAgenda" runat="server" CssClass="card">
                    <div class="card-head">
                        <div class="card-head-l">
                            <div class="card-head-icon">
                                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M9 11l3 3L22 4"/>
                                    <path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"/>
                                </svg>
                            </div>
                            <div class="card-title">Lịch trình <em>chi tiết</em></div>
                        </div>
                    </div>
                    <div class="agenda">
                        <asp:Repeater ID="rptAgenda" runat="server">
                            <ItemTemplate>
                                <div class='<%# "agenda-item " + ((string)Eval("ItemType") == "break" ? "break" : "") %>'>
                                    <div class="agenda-time">
                                        <span><%# Eval("StartTime", "{0:HH:mm}") %></span>
                                        <span>— <%# Eval("EndTime", "{0:HH:mm}") %></span>
                                    </div>
                                    <div class="agenda-content">
                                        <div class="agenda-title"><%# Eval("Title") %></div>
                                        <div class="agenda-desc"><%# Eval("Description") %></div>
                                    </div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                </asp:Panel>

                <%-- SPEAKERS --%>
                <asp:Panel ID="pnlSpeakers" runat="server" CssClass="card">
                    <div class="card-head">
                        <div class="card-head-l">
                            <div class="card-head-icon">
                                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M12 1a3 3 0 00-3 3v8a3 3 0 006 0V4a3 3 0 00-3-3z"/>
                                    <path d="M19 10v2a7 7 0 01-14 0v-2"/>
                                    <line x1="12" y1="19" x2="12" y2="23"/>
                                    <line x1="8" y1="23" x2="16" y2="23"/>
                                </svg>
                            </div>
                            <div class="card-title">Diễn giả &amp; <em>Khách mời</em></div>
                        </div>
                    </div>
                    <div class="speakers-grid">
                        <asp:Repeater ID="rptSpeakers" runat="server">
                            <ItemTemplate>
                                <div class="speaker-row">
                                    <div class='<%# "speaker-av av-" + Eval("ColorIndex") %>'>
                                        <%# Eval("Initial") %>
                                    </div>
                                    <div>
                                        <div class="speaker-name"><%# Eval("FullName") %></div>
                                        <div class="speaker-role"><%# Eval("Title") %></div>
                                    </div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                </asp:Panel>

                <%-- REGISTRANTS --%>
                <div class="card">
                    <div class="card-head">
                        <div class="card-head-l">
                            <div class="card-head-icon">
                                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M16 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/>
                                    <circle cx="8.5" cy="7" r="4"/>
                                    <polyline points="17,11 19,13 23,9"/>
                                </svg>
                            </div>
                            <div class="card-title">Người đăng ký <em>gần đây</em></div>
                        </div>
                        <asp:LinkButton ID="btnShowAll" runat="server" CssClass="card-action"
                                        OnClick="btnShowAll_Click" CausesValidation="false">
                            Xem tất cả
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <polyline points="9,18 15,12 9,6"/>
                            </svg>
                        </asp:LinkButton>
                    </div>
                    <div class="table-wrap">
                        <table class="tbl">
                            <thead>
                                <tr>
                                    <th>Người đăng ký</th>
                                    <th>Phòng ban</th>
                                    <th>Thời gian</th>
                                    <th>Trạng thái</th>
                                    <th style="text-align:right;">Hành động</th>
                                </tr>
                            </thead>
                            <tbody>
                                <asp:Repeater ID="rptRegistrants" runat="server"
                                              OnItemCommand="rptRegistrants_ItemCommand">
                                    <ItemTemplate>
                                        <tr>
                                            <td>
                                                <div class="reg-user">
                                                    <div class='<%# "reg-av av-" + Eval("ColorIndex") %>'>
                                                        <%# Eval("Initial") %>
                                                    </div>
                                                    <div>
                                                        <div class="reg-name"><%# Eval("FullName") %></div>
                                                        <div class="reg-email"><%# Eval("Email") %></div>
                                                    </div>
                                                </div>
                                            </td>
                                            <td><span class="dept-tag"><%# Eval("Department") %></span></td>
                                            <td>
                                                <div class="time-cell">
                                                    <%# Eval("TimeAgo") %>
                                                    <small><%# Eval("RegisteredAt", "{0:HH:mm, dd/MM}") %></small>
                                                </div>
                                            </td>
                                            <td>
                                                <span class='<%# "status-pill " + Eval("Status") %>'>
                                                    <%# Eval("StatusText") %>
                                                </span>
                                            </td>
                                            <td>
                                                <div class="row-acts">
                                                    <asp:LinkButton runat="server" CssClass="row-act approve"
                                                                    ToolTip="Duyệt"
                                                                    CommandName="ApproveReg"
                                                                    CommandArgument='<%# Eval("Id") %>'
                                                                    Visible='<%# (string)Eval("Status") == "pending" %>'
                                                                    CausesValidation="false">
                                                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                                            <polyline points="20,6 9,17 4,12"/>
                                                        </svg>
                                                    </asp:LinkButton>
                                                    <asp:LinkButton runat="server" CssClass="row-act reject"
                                                                    ToolTip="Từ chối"
                                                                    CommandName="RejectReg"
                                                                    CommandArgument='<%# Eval("Id") %>'
                                                                    Visible='<%# (string)Eval("Status") == "pending" %>'
                                                                    CausesValidation="false">
                                                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                            <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                                                        </svg>
                                                    </asp:LinkButton>
                                                    <asp:LinkButton runat="server" CssClass="row-act"
                                                                    ToolTip="Hoàn tác"
                                                                    CommandName="ResetReg"
                                                                    CommandArgument='<%# Eval("Id") %>'
                                                                    Visible='<%# (string)Eval("Status") == "rejected" %>'
                                                                    CausesValidation="false">
                                                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                            <polyline points="1,4 1,10 7,10"/>
                                                            <path d="M3.51 15a9 9 0 102.13-9.36L1 10"/>
                                                        </svg>
                                                    </asp:LinkButton>
                                                </div>
                                            </td>
                                        </tr>
                                    </ItemTemplate>
                                </asp:Repeater>

                                <asp:PlaceHolder ID="phEmpty" runat="server" Visible="false">
                                    <tr><td colspan="5" class="empty-cell">Chưa có người đăng ký nào.</td></tr>
                                </asp:PlaceHolder>
                            </tbody>
                        </table>
                    </div>
                    <div class="table-foot">
                        <span>
                            Hiển thị <b><asp:Literal ID="litShownCount" runat="server" Text="0" /></b>
                            trong <b><asp:Literal ID="litTotalReg" runat="server" Text="0" /></b> người đăng ký
                        </span>
                        <asp:LinkButton ID="btnShowAllFoot" runat="server"
                                        OnClick="btnShowAll_Click" CausesValidation="false">
                            Xem đầy đủ danh sách
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <line x1="5" y1="12" x2="19" y2="12"/><polyline points="12,5 19,12 12,19"/>
                            </svg>
                        </asp:LinkButton>
                    </div>
                </div>

            </div>

            <%-- ─── RIGHT SIDEBAR ─── --%>
            <aside class="side">

                <%-- Registration stats --%>
                <div class="side-card">
                    <div class="side-card-title">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/>
                        </svg>
                        Số chỗ <em style="font-family:'Instrument Serif',serif;font-style:italic;color:var(--amber);">đăng ký</em>
                    </div>
                    <div class="reg-big">
                        <span class="reg-big-num"><asp:Literal ID="litRegBigNum" runat="server" Text="0" /></span>
                        <span class="reg-big-sub">/ <asp:Literal ID="litRegBigTotal" runat="server" Text="0" /> chỗ</span>
                    </div>
                    <div class="reg-bar">
                        <div id="regBarFill" runat="server"></div>
                    </div>
                    <div class="reg-bar-info">
                        <span><b><asp:Literal ID="litFillPct" runat="server" Text="0" />%</b> đầy chỗ</span>
                        <span>Còn <b><asp:Literal ID="litRemaining" runat="server" Text="0" /></b> chỗ</span>
                    </div>
                </div>

                <%-- General info --%>
                <div class="side-card">
                    <div class="side-card-title">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="12" r="10"/>
                            <line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>
                        </svg>
                        Thông tin <em style="font-family:'Instrument Serif',serif;font-style:italic;color:var(--amber);">cơ bản</em>
                    </div>
                    <div class="info-row">
                        <span class="info-row-lbl">Mã sự kiện</span>
                        <span class="info-row-val mono"><asp:Literal ID="litEventCode" runat="server" /></span>
                    </div>
                    <div class="info-row">
                        <span class="info-row-lbl">Hình thức</span>
                        <span class="info-row-val"><asp:Literal ID="litInfoFormat" runat="server" /></span>
                    </div>
                    <div class="info-row">
                        <span class="info-row-lbl">Đối tượng</span>
                        <span class="info-row-val"><asp:Literal ID="litInfoAudience" runat="server" /></span>
                    </div>
                    <div class="info-row">
                        <span class="info-row-lbl">Phí tham gia</span>
                        <span class="info-row-val" style="color: var(--green);">
                            <asp:Literal ID="litInfoPrice" runat="server" Text="Miễn phí" />
                        </span>
                    </div>
                    <div class="info-row">
                        <span class="info-row-lbl">Hạn đăng ký</span>
                        <span class="info-row-val"><asp:Literal ID="litInfoDeadline" runat="server" Text="—" /></span>
                    </div>
                    <div class="info-row">
                        <span class="info-row-lbl">Cần duyệt</span>
                        <span class="info-row-val"><asp:Literal ID="litInfoApproval" runat="server" /></span>
                    </div>
                </div>

                <%-- Organizer --%>
                <div class="side-card">
                    <div class="side-card-title">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/>
                        </svg>
                        Người tạo
                    </div>
                    <div class="org-block">
                        <div class="org-av"><asp:Literal ID="litOrgInitial" runat="server" Text="A" /></div>
                        <div>
                            <div class="org-name"><asp:Literal ID="litOrgName" runat="server" /></div>
                            <div class="org-role"><asp:Literal ID="litOrgRole" runat="server" /></div>
                        </div>
                    </div>
                </div>

                <%-- Activity feed --%>
                <div class="side-card">
                    <div class="side-card-title">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="22,12 18,12 15,21 9,3 6,12 2,12"/>
                        </svg>
                        Hoạt động <em style="font-family:'Instrument Serif',serif;font-style:italic;color:var(--amber);">gần đây</em>
                    </div>
                    <asp:Repeater ID="rptFeed" runat="server">
                        <ItemTemplate>
                            <div class="feed-item">
                                <div class='<%# "feed-dot " + Eval("DotColor") %>'></div>
                                <div class="feed-body">
                                    <div class="feed-text"><%# Eval("Text") %></div>
                                    <div class="feed-time"><%# Eval("TimeText") %></div>
                                </div>
                            </div>
                        </ItemTemplate>
                    </asp:Repeater>
                </div>

            </aside>
        </div>

        <%-- ═════════ MODAL: TẤT CẢ NGƯỜI ĐĂNG KÝ ═════════ --%>
        <asp:Panel ID="pnlAllRegModal" runat="server" CssClass="modal-overlay" Visible="false">
            <div class="modal-box">
                <div class="modal-head">
                    <div>
                        <div class="modal-title">Toàn bộ người đăng ký</div>
                        <div class="modal-sub">
                            <asp:Literal ID="litModalEventTitle" runat="server" />
                            — <b><asp:Literal ID="litModalTotal" runat="server" Text="0" /></b> người
                        </div>
                    </div>
                    <asp:LinkButton ID="btnCloseModal" runat="server" CssClass="modal-close"
                                    OnClick="btnCloseModal_Click" CausesValidation="false">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                        </svg>
                    </asp:LinkButton>
                </div>

                <%-- Filter tabs --%>
                <div class="modal-tabs">
                    <asp:LinkButton ID="tabAll"      runat="server" CssClass="modal-tab active"
                                    CommandArgument="" OnCommand="ModalTab_Command" CausesValidation="false">
                        Tất cả (<asp:Literal ID="litCntAll" runat="server" Text="0" />)
                    </asp:LinkButton>
                    <asp:LinkButton ID="tabApproved" runat="server" CssClass="modal-tab"
                                    CommandArgument="approved" OnCommand="ModalTab_Command" CausesValidation="false">
                        Đã duyệt (<asp:Literal ID="litCntApproved" runat="server" Text="0" />)
                    </asp:LinkButton>
                    <asp:LinkButton ID="tabPending"  runat="server" CssClass="modal-tab"
                                    CommandArgument="pending" OnCommand="ModalTab_Command" CausesValidation="false">
                        Chờ duyệt (<asp:Literal ID="litCntPending" runat="server" Text="0" />)
                    </asp:LinkButton>
                    <asp:LinkButton ID="tabRejected" runat="server" CssClass="modal-tab"
                                    CommandArgument="rejected" OnCommand="ModalTab_Command" CausesValidation="false">
                        Từ chối (<asp:Literal ID="litCntRejected" runat="server" Text="0" />)
                    </asp:LinkButton>
                </div>

                <div class="modal-body">
                    <div class="table-wrap">
                        <table class="tbl">
                            <thead>
                                <tr>
                                    <th>#</th>
                                    <th>Người đăng ký</th>
                                    <th>Phòng ban</th>
                                    <th>Mã vé</th>
                                    <th>Thời gian</th>
                                    <th>Trạng thái</th>
                                    <th style="text-align:right;">Hành động</th>
                                </tr>
                            </thead>
                            <tbody>
                                <asp:Repeater ID="rptAllRegistrants" runat="server"
                                              OnItemCommand="rptAllRegistrants_ItemCommand">
                                    <ItemTemplate>
                                        <tr>
                                            <td><span class="row-num"><%# Container.ItemIndex + 1 %></span></td>
                                            <td>
                                                <div class="reg-user">
                                                    <div class='<%# "reg-av av-" + Eval("ColorIndex") %>'>
                                                        <%# Eval("Initial") %>
                                                    </div>
                                                    <div>
                                                        <div class="reg-name"><%# Eval("FullName") %></div>
                                                        <div class="reg-email"><%# Eval("Email") %></div>
                                                    </div>
                                                </div>
                                            </td>
                                            <td><span class="dept-tag"><%# Eval("Department") %></span></td>
                                            <td>
                                                <span class="ticket-code"><%# Eval("TicketCode") %></span>
                                            </td>
                                            <td>
                                                <div class="time-cell">
                                                    <%# Eval("RegisteredAt", "{0:dd/MM/yyyy}") %>
                                                    <small><%# Eval("RegisteredAt", "{0:HH:mm}") %></small>
                                                </div>
                                            </td>
                                            <td>
                                                <span class='<%# "status-pill " + Eval("Status") %>'>
                                                    <%# Eval("StatusText") %>
                                                </span>
                                            </td>
                                            <td>
                                                <div class="row-acts">
                                                    <asp:LinkButton runat="server" CssClass="row-act approve"
                                                                    ToolTip="Duyệt"
                                                                    CommandName="ApproveReg"
                                                                    CommandArgument='<%# Eval("Id") %>'
                                                                    Visible='<%# (string)Eval("Status") == "pending" %>'
                                                                    CausesValidation="false">
                                                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                                            <polyline points="20,6 9,17 4,12"/>
                                                        </svg>
                                                    </asp:LinkButton>
                                                    <asp:LinkButton runat="server" CssClass="row-act reject"
                                                                    ToolTip="Từ chối"
                                                                    CommandName="RejectReg"
                                                                    CommandArgument='<%# Eval("Id") %>'
                                                                    Visible='<%# (string)Eval("Status") == "pending" %>'
                                                                    CausesValidation="false">
                                                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                            <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                                                        </svg>
                                                    </asp:LinkButton>
                                                    <asp:LinkButton runat="server" CssClass="row-act"
                                                                    ToolTip="Hoàn tác"
                                                                    CommandName="ResetReg"
                                                                    CommandArgument='<%# Eval("Id") %>'
                                                                    Visible='<%# (string)Eval("Status") == "rejected" %>'
                                                                    CausesValidation="false">
                                                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                            <polyline points="1,4 1,10 7,10"/>
                                                            <path d="M3.51 15a9 9 0 102.13-9.36L1 10"/>
                                                        </svg>
                                                    </asp:LinkButton>
                                                </div>
                                            </td>
                                        </tr>
                                    </ItemTemplate>
                                </asp:Repeater>

                                <asp:PlaceHolder ID="phModalEmpty" runat="server" Visible="false">
                                    <tr><td colspan="7" class="empty-cell">Không có người đăng ký phù hợp.</td></tr>
                                </asp:PlaceHolder>
                            </tbody>
                        </table>
                    </div>
                </div>

                <div class="modal-foot">
                    <asp:LinkButton ID="btnCloseModalFoot" runat="server" CssClass="btn btn-ghost"
                                    OnClick="btnCloseModal_Click" CausesValidation="false">
                        Đóng
                    </asp:LinkButton>
                </div>
            </div>
        </asp:Panel>

        <asp:HiddenField ID="hfModalStatus" runat="server" Value="" />

        </ContentTemplate>
    </asp:UpdatePanel>
</asp:Content>

<asp:Content ID="cScripts" ContentPlaceHolderID="ScriptContent" runat="server">
</asp:Content>
