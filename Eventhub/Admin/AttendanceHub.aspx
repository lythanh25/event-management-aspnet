<%@ Page Title="Điểm danh sự kiện" Language="C#" MasterPageFile="~/AdminMaster.Master"
    AutoEventWireup="true" CodeBehind="AttendanceHub.aspx.cs"
    Inherits="Eventhub.Admin.attendancedetail" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Điểm danh sự kiện — EventHub Admin
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Content/AttendanceHub.css") %>" rel="stylesheet" type="text/css" />
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <%-- ═════════ HEADER ═════════ --%>
    <div class="page-head">
        <div>
            <h1 class="page-title">Điểm danh <em>sự kiện</em></h1>
            <div class="page-sub">
                Chọn sự kiện cần điểm danh hoặc xem báo cáo. Hệ thống ưu tiên hiển thị các sự kiện
                <b>đang diễn ra</b> và <b>sắp tới</b> trong 7 ngày.
            </div>
        </div>
    </div>

    <%-- ═════════ LIVE HERO (sự kiện đang diễn ra) ═════════ --%>
    <asp:Panel ID="pnlLiveHero" runat="server" CssClass="live-hero" Visible="false">
        <div class="live-hero-left">
            <span class="live-pill">SỰ KIỆN ĐANG DIỄN RA</span>
            <h2 class="live-title"><asp:Literal ID="litLiveTitle" runat="server" /></h2>
            <div class="live-meta">
                <div>
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2"/>
                        <line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/>
                        <line x1="3" y1="10" x2="21" y2="10"/>
                    </svg>
                    <asp:Literal ID="litLiveDate" runat="server" />
                </div>
                <div>
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/>
                    </svg>
                    <strong><asp:Literal ID="litLiveTime" runat="server" /></strong>
                </div>
                <div>
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/>
                        <circle cx="12" cy="10" r="3"/>
                    </svg>
                    <asp:Literal ID="litLiveLocation" runat="server" />
                </div>
                <div>
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/>
                        <circle cx="12" cy="7" r="4"/>
                    </svg>
                    Phụ trách: <strong><asp:Literal ID="litLiveOrganizer" runat="server" /></strong>
                </div>
            </div>

            <div class="live-stats">
                <div class="live-stat-item">
                    <div class="live-stat-num"><asp:Literal ID="litLiveApproved" runat="server" Text="0" /></div>
                    <div class="live-stat-lbl">Đã được duyệt</div>
                </div>
                <div class="live-stat-item">
                    <div class="live-stat-num">
                        <asp:Literal ID="litLiveCheckedIn" runat="server" Text="0" />
                        <small>/ <asp:Literal ID="litLiveApprovedSlash" runat="server" Text="0" /></small>
                    </div>
                    <div class="live-stat-lbl">Đã có mặt</div>
                    <div class="live-stat-bar"><div id="divLiveBar" runat="server"></div></div>
                </div>
                <div class="live-stat-item">
                    <div class="live-stat-num red"><asp:Literal ID="litLiveLate" runat="server" Text="0" /></div>
                    <div class="live-stat-lbl">Đến muộn</div>
                </div>
                <div class="live-stat-item">
                    <div class="live-stat-num"><asp:Literal ID="litLiveAbsent" runat="server" Text="0" /></div>
                    <div class="live-stat-lbl">Chưa đến</div>
                </div>
            </div>
        </div>

        <div class="live-hero-right">
            <asp:HyperLink ID="lnkLiveEnter" runat="server" CssClass="btn-live">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M16 21v-2a4 4 0 00-4-4H6a4 4 0 00-4 4v2"/>
                    <circle cx="9" cy="7" r="4"/>
                    <path d="M22 11l-3 3-2-2"/>
                </svg>
                Vào điểm danh
                <svg style="margin-left: 4px" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="5" y1="12" x2="19" y2="12"/><polyline points="12,5 19,12 12,19"/>
                </svg>
            </asp:HyperLink>
        </div>
    </asp:Panel>

    <%-- ═════════ FILTER BAR ═════════ --%>
    <div class="filter-bar">
        <asp:HyperLink ID="tabToday" runat="server" CssClass="filter-tab">
            Hôm nay
            <span class="count"><asp:Literal ID="litCntToday" runat="server" Text="0" /></span>
        </asp:HyperLink>
        <asp:HyperLink ID="tabUpcoming" runat="server" CssClass="filter-tab">
            Sắp diễn ra
            <span class="count"><asp:Literal ID="litCntUpcoming" runat="server" Text="0" /></span>
        </asp:HyperLink>
        <asp:HyperLink ID="tabEnded" runat="server" CssClass="filter-tab">
            Đã kết thúc
            <span class="count"><asp:Literal ID="litCntEnded" runat="server" Text="0" /></span>
        </asp:HyperLink>
        <asp:HyperLink ID="tabAll" runat="server" CssClass="filter-tab">
            Tất cả
            <span class="count"><asp:Literal ID="litCntAll" runat="server" Text="0" /></span>
        </asp:HyperLink>

        <div class="filter-spacer"></div>

        <div class="filter-search-inline">
            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <asp:TextBox ID="txtSearch" runat="server" placeholder="Tìm sự kiện..."
                         AutoPostBack="true" OnTextChanged="txtSearch_TextChanged" />
        </div>
    </div>

    <%-- ═════════ EVENT GRID ═════════ --%>
    <div class="section">
        <div class="section-head">
            <div class="section-title">
                <asp:Literal ID="litSectionTitle" runat="server" Text="Hôm nay" />
                <em>— <asp:Literal ID="litSectionSub" runat="server" /></em>
                <span class="section-tag"><asp:Literal ID="litSectionCount" runat="server" Text="0" /> SỰ KIỆN</span>
            </div>
        </div>

        <asp:Panel ID="pnlEmpty" runat="server" CssClass="empty-state" Visible="false">
            <svg viewBox="0 0 24 24" fill="none" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                <rect x="3" y="4" width="18" height="18" rx="2"/>
                <line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/>
                <line x1="3" y1="10" x2="21" y2="10"/>
            </svg>
            <div class="empty-title">Không có sự kiện nào</div>
            <div class="empty-sub">Hãy thử chọn bộ lọc khác.</div>
        </asp:Panel>

        <div class="event-grid">
            <asp:Repeater ID="rptEvents" runat="server">
                <ItemTemplate>
                    <div class="event-card">
                        <div class='<%# "event-banner bg-" + Eval("BannerIndex") %>'>
                            <span class='<%# "event-status " + Eval("StatusBadgeClass") %>'>
                                <%# Eval("StatusBadgeText") %>
                            </span>
                            <div class="event-time-badge">
                                <div class="event-time-day"><%# Eval("StartAt", "{0:dd}") %></div>
                                <div class="event-time-mon">THG <%# Eval("StartAt", "{0:MM}") %></div>
                            </div>
                            <span class="event-banner-tag"><%# Eval("BannerTag") %></span>
                        </div>
                        <div class="event-body">
                            <h3 class="event-title"><%# Eval("Title") %></h3>
                            <div class="event-meta">
                                <div>
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/>
                                    </svg>
                                    <%# Eval("TimeText") %>
                                </div>
                                <div>
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/>
                                        <circle cx="12" cy="10" r="3"/>
                                    </svg>
                                    <%# Eval("LocationName") %>
                                </div>
                                <div>
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/>
                                    </svg>
                                    Phụ trách: <%# Eval("OrganizerName") %>
                                </div>
                            </div>

                            <div class="att-progress">
                                <div class="att-progress-head">
                                    <span class="att-progress-lbl"><%# Eval("ProgressLabel") %></span>
                                    <span class="att-progress-val">
                                        <%# Eval("ProgressNum") %>
                                        <small>/ <%# Eval("ProgressDenom") %> · <%# Eval("ProgressPercent") %>%</small>
                                    </span>
                                </div>
                                <div class="att-progress-bar">
                                    <div class='<%# Eval("ProgressColor") %>' style='width: <%# Eval("ProgressPercent") %>%'></div>
                                </div>
                            </div>

                            <div class="info-row">
                                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/>
                                    <circle cx="9" cy="7" r="4"/>
                                </svg>
                                <span><b><%# Eval("ProgressNum") %></b> <%# Eval("InfoRowText") %></span>
                            </div>
                        </div>
                        <div class="event-footer">
                            <asp:HyperLink runat="server" CssClass='<%# "event-action " + Eval("ActionClass") %>'
                                           NavigateUrl='<%# "~/Admin/AttendanceDetail.aspx?eventId=" + Eval("Id") %>'>
                                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M16 21v-2a4 4 0 00-4-4H6a4 4 0 00-4 4v2"/>
                                    <circle cx="9" cy="7" r="4"/>
                                    <path d="M22 11l-3 3-2-2"/>
                                </svg>
                                <%# Eval("ActionText") %>
                            </asp:HyperLink>
                            <asp:HyperLink runat="server" CssClass="event-action-icon" ToolTip="Chi tiết"
                                           NavigateUrl='<%# "~/Admin/EventDetail.aspx?id=" + Eval("Id") %>'>
                                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <circle cx="12" cy="12" r="10"/>
                                    <line x1="12" y1="16" x2="12" y2="12"/>
                                    <line x1="12" y1="8" x2="12.01" y2="8"/>
                                </svg>
                            </asp:HyperLink>
                        </div>
                    </div>
                </ItemTemplate>
            </asp:Repeater>
        </div>
    </div>
</asp:Content>

<asp:Content ID="cScripts" ContentPlaceHolderID="ScriptContent" runat="server">
</asp:Content>
