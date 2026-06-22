<%@ Page Language="C#"
    MasterPageFile="~/UserMaster.Master"
    AutoEventWireup="true"
    CodeBehind="UserMyEvents.aspx.cs"
    Inherits="Eventhub.User.UserMyEvents" %>

<%-- ════════════ TITLE ════════════ --%>
<asp:Content ID="cntTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Sự kiện của tôi — EventHub
</asp:Content>

<%-- ════════════ HEAD ════════════ --%>
<asp:Content ID="cntHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Content/UserMyEvents.css") %>" rel="stylesheet" type="text/css" />
</asp:Content>

<%-- ════════════ HERO ════════════ --%>
<asp:Content ID="cntHero" ContentPlaceHolderID="HeroContent" runat="server">
    <section class="page-hero">
        <div>
            <div class="hero-tag">TRANG CỦA BẠN</div>
            <h1 class="hero-title">Sự kiện <em>của tôi</em></h1>
            <p class="hero-sub">
                Theo dõi toàn bộ sự kiện bạn đã đăng ký, đang chờ duyệt
                và lịch trong tuần tới của bạn.
            </p>
            <div class="mini-stats">
                <div class="mini-stat">
                    <div class="mini-stat-num"><asp:Literal ID="litStatTotal"    runat="server" Text="0" /></div>
                    <div class="mini-stat-lbl">Tổng</div>
                </div>
                <div class="mini-stat">
                    <div class="mini-stat-num green"><asp:Literal ID="litStatApproved" runat="server" Text="0" /></div>
                    <div class="mini-stat-lbl">Đã duyệt</div>
                </div>
                <div class="mini-stat">
                    <div class="mini-stat-num amber"><asp:Literal ID="litStatPending"  runat="server" Text="0" /></div>
                    <div class="mini-stat-lbl">Chờ duyệt</div>
                </div>
                <div class="mini-stat">
                    <div class="mini-stat-num"><asp:Literal ID="litStatAttended" runat="server" Text="0" /></div>
                    <div class="mini-stat-lbl">Đã tham gia</div>
                </div>
                <div class="mini-stat">
                    <div class="mini-stat-num red"><asp:Literal ID="litStatRejected"  runat="server" Text="0" /></div>
                    <div class="mini-stat-lbl">Từ chối</div>
                </div>
            </div>
        </div>
        <div class="hero-actions">
            <a href="<%= ResolveUrl("~/User/UserDiscover.aspx") %>" class="btn-cta">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                Tìm sự kiện mới
            </a>
            <asp:LinkButton ID="btnExport" runat="server" CssClass="btn-cta-ghost"
                            OnClick="btnExport_Click" CausesValidation="false">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="8,17 12,21 16,17"/><line x1="12" y1="12" x2="12" y2="21"/><path d="M20.88 18.09A5 5 0 0018 9h-1.26A8 8 0 103 16.29"/></svg>
                Xuất lịch (.ics)
            </asp:LinkButton>
        </div>
    </section>
</asp:Content>

<%-- ════════════ MAIN ════════════ --%>
<asp:Content ID="cntMain" ContentPlaceHolderID="MainContent" runat="server">
<%-- HiddenField giữ giá trị CurrentFilter khi postback sort/search --%>
<asp:HiddenField ID="hfFilter" runat="server" Value="ALL" />

<div class="my-events-zone">

    <%-- Alert --%>
    <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="me-alert info">
        <asp:Literal ID="litAlert" runat="server" />
    </asp:Panel>

    <div class="my-events-grid">

        <%-- ══════ SIDEBAR ══════ --%>
        <aside class="side">
            <div class="filter-card">
                <div class="filter-label">Lọc theo trạng thái</div>

                <%-- Dùng <a runat="server"> — tin cậy hơn LinkButton với inner SVG --%>
                <a id="lnkFAll"       runat="server" class="filter-item" href="#">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
                    Tất cả
                    <span class="count"><asp:Literal ID="litSbAll"       runat="server" Text="0" /></span>
                </a>
                <a id="lnkFApproved"  runat="server" class="filter-item" href="#">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20,6 9,17 4,12"/></svg>
                    Đã duyệt
                    <span class="count"><asp:Literal ID="litSbApproved"  runat="server" Text="0" /></span>
                </a>
                <a id="lnkFPending"   runat="server" class="filter-item" href="#">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/></svg>
                    Chờ duyệt
                    <span class="count"><asp:Literal ID="litSbPending"   runat="server" Text="0" /></span>
                </a>
                <a id="lnkFWaitlist"  runat="server" class="filter-item" href="#">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="10" y1="6" x2="21" y2="6"/><line x1="10" y1="12" x2="21" y2="12"/><line x1="10" y1="18" x2="21" y2="18"/></svg>
                    Danh sách chờ
                    <span class="count"><asp:Literal ID="litSbWaitlist"  runat="server" Text="0" /></span>
                </a>
                <a id="lnkFAttended"  runat="server" class="filter-item" href="#">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><polyline points="9,12 11,14 15,10"/></svg>
                    Đã tham gia
                    <span class="count"><asp:Literal ID="litSbAttended"  runat="server" Text="0" /></span>
                </a>
                <a id="lnkFRejected"  runat="server" class="filter-item" href="#">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
                    Bị từ chối
                    <span class="count"><asp:Literal ID="litSbRejected"  runat="server" Text="0" /></span>
                </a>
                <a id="lnkFCancelled" runat="server" class="filter-item" href="#">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="4.93" y1="4.93" x2="19.07" y2="19.07"/></svg>
                    Đã huỷ
                    <span class="count"><asp:Literal ID="litSbCancelled" runat="server" Text="0" /></span>
                </a>
            </div>

            <div class="filter-card">
                <div class="filter-label">Sắp diễn ra</div>
                <div style="padding:4px 10px; font-size:11.5px; color:var(--muted); line-height:1.6;">
                    Bạn có <b style="color:var(--ink);"><asp:Literal ID="litUpcomingCount" runat="server" Text="0" /></b>
                    sự kiện trong <b style="color:var(--ink);">7 ngày tới</b>. Kiểm tra lịch để chuẩn bị nhé!
                </div>
            </div>

            <div class="side-tip">
                <div class="side-tip-title">Mẹo nhỏ</div>
                <div class="side-tip-sub">
                    Bật <b>thông báo qua email</b> để không bỏ lỡ kết quả xét duyệt hay nhắc lịch sự kiện.
                </div>
            </div>
        </aside>

        <%-- ══════ CONTENT ══════ --%>
        <div class="content">

            <%-- Search + Sort --%>
            <div class="me-search-bar">
                <svg class="search-icon" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
                <asp:TextBox ID="txtSearch" runat="server" placeholder="Tìm trong sự kiện của bạn..." />
                <asp:LinkButton ID="btnSearch" runat="server" CssClass="me-search-btn"
                                OnClick="btnSearch_Click" ToolTip="Tìm kiếm">🔍</asp:LinkButton>
            </div>

            <div class="section-head">
                <div class="section-title">
                    <asp:Literal ID="litSectionTitle" runat="server" Text="Tất cả" />
                    <em>&amp; của bạn</em>
                    <span class="section-count"><asp:Literal ID="litSectionCount" runat="server" Text="0" /></span>
                </div>
                <asp:DropDownList ID="ddlSort" runat="server" CssClass="section-sort-select"
                                  AutoPostBack="true" OnSelectedIndexChanged="ddlSort_Changed">
                    <asp:ListItem Value="DATE_DESC" Text="Mới nhất" />
                    <asp:ListItem Value="DATE_ASC"  Text="Cũ nhất" />
                    <asp:ListItem Value="EVENT_ASC" Text="Tên A→Z" />
                </asp:DropDownList>
            </div>

            <%-- Event list --%>
            <asp:Repeater ID="rptRegs" runat="server"
                          OnItemCommand="rptRegs_ItemCommand"
                          OnItemDataBound="rptRegs_ItemDataBound">
                <HeaderTemplate><div class="event-list"></HeaderTemplate>
                <ItemTemplate>
                    <div class='<%# "event-item " + GetItemClass(Eval("reg_status"), Eval("attended")) %>'
                         onclick='<%# "window.location.href=\"" + ResolveUrl("~/User/UserEventDetail.aspx") + "?id=" + Eval("event_id") + "\"" %>'>

                        <div class="event-date-box">
                            <div class="event-date-day"><%# Eval("start_day") %></div>
                            <div class="event-date-mon"><%# Eval("start_mon") %></div>
                            <div class="event-date-dow"><%# Eval("start_dow") %></div>
                        </div>

                        <div class="event-body">
                            <div class="event-title-row">
                                <div>
                                    <asp:Panel ID="pnlBadges" runat="server" CssClass="event-side-badges" Visible="false">
                                        <asp:Literal ID="litBadges" runat="server" />
                                    </asp:Panel>
                                    <h3 class="event-title"><%# Eval("event_title") %></h3>
                                </div>
                                <span class='<%# "event-status " + GetItemClass(Eval("reg_status"), Eval("attended")) %>'>
                                    <%# GetStatusIconHtml(Eval("reg_status"), Eval("attended")) %>
                                    <%# GetStatusLabel(Eval("reg_status"), Eval("attended")) %>
                                </span>
                            </div>

                            <div class="event-cat"><%# Eval("category_name") %></div>

                            <div class="event-meta">
                                <div>
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/></svg>
                                    <%# Eval("schedule_text") %>
                                </div>
                                <div>
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                                    <%# Eval("location_text") %>
                                </div>
                                <div>
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                                    Đăng ký: <%# Eval("registered_date") %>
                                </div>
                            </div>

                            <asp:Panel ID="pnlRowAlert" runat="server" CssClass="event-alert" Visible="false">
                                <asp:Literal ID="litAlertIcon" runat="server" />
                                <asp:Literal ID="litAlertMsg"  runat="server" />
                            </asp:Panel>

                            <div class="event-actions" onclick="event.stopPropagation();">
                                <a href='<%# ResolveUrl("~/User/UserEventDetail.aspx") + "?id=" + Eval("event_id") %>'
                                   class="ea-btn primary">
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                                    Xem chi tiết
                                </a>
                                <asp:Panel ID="pnlBtnCalendar" runat="server" Visible="false" style="display:inline-block;">
                                    <asp:LinkButton ID="btnAddCalendar" runat="server" CssClass="ea-btn"
                                                    CommandName="AddCalendar" CommandArgument='<%# Eval("event_id") %>'
                                                    OnClientClick="event.stopPropagation();">
                                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                                        Thêm vào lịch
                                    </asp:LinkButton>
                                </asp:Panel>
                                <asp:Panel ID="pnlBtnCancel" runat="server" Visible="false" style="display:inline-block; margin-left:auto;">
                                    <asp:LinkButton ID="btnCancel" runat="server" CssClass="ea-btn danger spacer"
                                                    CommandName="CancelReg" CommandArgument='<%# Eval("reg_id") %>'
                                                    OnClientClick="return confirm('Bạn có chắc muốn huỷ đăng ký sự kiện này?');event.stopPropagation();">
                                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/></svg>
                                        <asp:Literal ID="litCancelText" runat="server" Text="Huỷ đăng ký" />
                                    </asp:LinkButton>
                                </asp:Panel>
                            </div>
                        </div>
                    </div>
                </ItemTemplate>
                <FooterTemplate></div></FooterTemplate>
            </asp:Repeater>

            <asp:Panel ID="pnlEmpty" runat="server" CssClass="me-empty" Visible="false">
                <div class="me-empty-icon">📭</div>
                <h3>Chưa có sự kiện nào</h3>
                <p><asp:Literal ID="litEmptyMsg" runat="server" Text="Bạn chưa đăng ký sự kiện nào." /></p>
                <a href="<%= ResolveUrl("~/User/UserDiscover.aspx") %>" class="me-empty-cta">Khám phá sự kiện ngay</a>
            </asp:Panel>

        </div>
    </div>
</div>
</asp:Content>
