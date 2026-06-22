<%@ Page Language="C#"
    MasterPageFile="~/UserMaster.Master"
    AutoEventWireup="true"
    CodeBehind="UserDiscover.aspx.cs"
    Inherits="Eventhub.User.UserDiscover" %>

<asp:Content ID="cntTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Khám phá sự kiện — EventHub
</asp:Content>

<asp:Content ID="cntHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Content/UserDiscover.css") %>" rel="stylesheet" type="text/css" />
</asp:Content>

<%-- ═══ HERO ═══ --%>
<asp:Content ID="cntHero" ContentPlaceHolderID="HeroContent" runat="server">
    <section class="hero hero-discover">
        <h1 class="hero-title">
            Tìm kiếm sự kiện
            <em>dành cho bạn</em>
        </h1>
        <p class="hero-sub">
            Khám phá các sự kiện nội bộ đang diễn ra và sắp tới của các phòng ban trên toàn công ty.
        </p>
        <div class="big-search">
            <svg class="icon" viewBox="0 0 24 24" fill="none" stroke-width="2"
                 stroke-linecap="round" stroke-linejoin="round">
                <circle cx="11" cy="11" r="8"/>
                <line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <asp:TextBox ID="txtSearch" runat="server"
                         placeholder="Tìm sự kiện, chủ đề, diễn giả..." />
            <asp:LinkButton ID="btnSearch" runat="server" CssClass="big-search-btn"
                            OnClick="btnSearch_Click" ToolTip="Tìm kiếm">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2.2"
                     stroke-linecap="round" stroke-linejoin="round">
                    <line x1="5" y1="12" x2="19" y2="12"/>
                    <polyline points="12,5 19,12 12,19"/>
                </svg>
            </asp:LinkButton>
        </div>
    </section>
</asp:Content>

<%-- ═══ MAIN ═══ --%>
<asp:Content ID="cntMain" ContentPlaceHolderID="MainContent" runat="server">

<%-- HiddenFields giữ state khi postback sort/search --%>
<asp:HiddenField ID="hfCategory" runat="server" Value="" />
<asp:HiddenField ID="hfFilter"   runat="server" Value="ALL" />
<asp:HiddenField ID="hfPage"     runat="server" Value="1" />

<div class="discover-zone">

    <%-- Stats strip --%>
    <div class="stats-strip">
        <div class="stat-pill">
            <div class="stat-pill-icon amber">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
            </div>
            <div>
                <div class="stat-pill-value"><asp:Literal ID="litStatTotal" runat="server" Text="0" /></div>
                <div class="stat-pill-lbl">Tổng sự kiện</div>
            </div>
        </div>
        <div class="stat-pill">
            <div class="stat-pill-icon green">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20,6 9,17 4,12"/></svg>
            </div>
            <div>
                <div class="stat-pill-value"><asp:Literal ID="litStatOpen" runat="server" Text="0" /></div>
                <div class="stat-pill-lbl">Đang mở đăng ký</div>
            </div>
        </div>
        <div class="stat-pill">
            <div class="stat-pill-icon blue">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/></svg>
            </div>
            <div>
                <div class="stat-pill-value"><asp:Literal ID="litStatThisWeek" runat="server" Text="0" /></div>
                <div class="stat-pill-lbl">Tuần này</div>
            </div>
        </div>
        <div class="stat-pill">
            <div class="stat-pill-icon red">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M8.5 14.5A2.5 2.5 0 0011 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 11-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 002.5 2.5z"/></svg>
            </div>
            <div>
                <div class="stat-pill-value"><asp:Literal ID="litStatRegisteredByMe" runat="server" Text="0" /></div>
                <div class="stat-pill-lbl">Bạn đã đăng ký</div>
            </div>
        </div>
    </div>

    <%-- Alert --%>
    <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="detail-alert info">
        <asp:Literal ID="litAlert" runat="server" />
    </asp:Panel>

    <%-- ─── CATEGORIES ─── --%>
    <div class="section">
        <div class="section-head">
            <div class="section-title">Khám phá theo <em>chủ đề</em></div>
        </div>

        <div class="cat-grid">
            <%-- "Tất cả" — dùng <a> thông thường, không LinkButton --%>
            <a id="lnkCatAll" runat="server" class="cat-card" href="#">
                <span class="cat-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
                </span>
                <span class="cat-name">Tất cả</span>
                <span class="cat-count">
                    <asp:Literal ID="litCatAllCount" runat="server" Text="0" /> sự kiện
                </span>
            </a>

            <%-- Các category từ DB — render bằng Literal để tránh SVG-in-LinkButton --%>
            <asp:Literal ID="litCategories" runat="server" />
        </div>
    </div>

    <%-- ─── FEATURED EVENT ─── --%>
    <asp:Panel ID="pnlFeatured" runat="server" CssClass="section" Visible="false">
        <div class="section-head">
            <div class="section-title">
                <span class="icon">&#11088;</span>
                Sự kiện <em>nổi bật</em>
            </div>
        </div>
        <div class="featured-event">
            <div class="fe-content">
                <span class="fe-pill">
                    <asp:Literal ID="litFePill" runat="server" Text="SỰ KIỆN ĐẶC BIỆT" />
                </span>
                <h3 class="fe-title">
                    <asp:Literal ID="litFeTitle" runat="server" />
                </h3>
                <div class="fe-meta">
                    <div>
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                        <asp:Literal ID="litFeDate" runat="server" />
                    </div>
                    <div>
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                        <asp:Literal ID="litFeLocation" runat="server" />
                    </div>
                    <div>
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
                        <asp:Literal ID="litFeCapacity" runat="server" />
                    </div>
                </div>
                <div class="fe-actions">
                    <asp:LinkButton ID="btnFeRegister" runat="server" CssClass="fe-cta"
                                    OnClick="btnFeRegister_Click">
                        <asp:Literal ID="litFeBtnText" runat="server" Text="Đăng ký ngay" />
                    </asp:LinkButton>
                    <span class="fe-spots"><asp:Literal ID="litFeSpots" runat="server" /></span>
                </div>
            </div>
            <div class="fe-countdown">
                <div class="fe-countdown-num"><asp:Literal ID="litFeCountdown" runat="server" Text="0" /></div>
                <div class="fe-countdown-lbl">Ngày nữa</div>
            </div>
            <div class="fe-spotlight">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18h6"/><path d="M10 22h4"/><path d="M12 2a7 7 0 00-4 12.5V17h8v-2.5A7 7 0 0012 2z"/></svg>
            </div>
        </div>
    </asp:Panel>

    <%-- ─── FILTER PILLS ─── --%>
    <%-- Dùng <a runat="server"> để tránh SVG-in-LinkButton --%>
    <div class="filter-row">
        <a id="lnkFAll"    runat="server" class="filter-pill" href="#">
            Tất cả <span class="count"><asp:Literal ID="litCountAll" runat="server" Text="0" /></span>
        </a>
        <a id="lnkFOpen"   runat="server" class="filter-pill" href="#">
            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/></svg>
            Đang mở
        </a>
        <a id="lnkFFree"   runat="server" class="filter-pill" href="#">Miễn phí</a>
        <a id="lnkFOnline" runat="server" class="filter-pill" href="#">Online</a>
        <a id="lnkFToday"  runat="server" class="filter-pill" href="#">Hôm nay</a>
        <a id="lnkFWeek"   runat="server" class="filter-pill" href="#">Tuần này</a>

        <div class="filter-spacer"></div>

        <asp:DropDownList ID="ddlSort" runat="server" CssClass="filter-sort-select"
                          AutoPostBack="true" OnSelectedIndexChanged="ddlSort_Changed">
            <asp:ListItem Value="START_ASC"  Text="Sắp xếp: Gần đây nhất" />
            <asp:ListItem Value="START_DESC" Text="Sắp xếp: Xa nhất" />
            <asp:ListItem Value="POPULAR"    Text="Sắp xếp: Phổ biến nhất" />
            <asp:ListItem Value="NEW"        Text="Sắp xếp: Mới đăng" />
        </asp:DropDownList>
    </div>

    <%-- Counter + active tags --%>
    <div class="event-counter-row">
        <span class="event-counter">
            Hiển thị <b><asp:Literal ID="litShownCount" runat="server" Text="0" /></b>
            / <asp:Literal ID="litTotalCount" runat="server" Text="0" /> sự kiện
        </span>
        <asp:Panel ID="pnlActiveTags" runat="server" CssClass="active-filter-tags" Visible="false">
            <asp:Literal ID="litActiveFilters" runat="server" />
            <a id="lnkClearFilters" runat="server" class="clear-filters" href="#">&#10005; Xoá lọc</a>
        </asp:Panel>
    </div>

    <%-- ─── EVENT GRID ─── --%>
    <asp:Repeater ID="rptEvents" runat="server"
                  OnItemCommand="rptEvents_ItemCommand"
                  OnItemDataBound="rptEvents_ItemDataBound">
        <HeaderTemplate><div class="event-grid"></HeaderTemplate>
        <ItemTemplate>
            <div class="event-card"
                 onclick='<%# "window.location.href=\"" + ResolveUrl("~/User/UserEventDetail.aspx") + "?id=" + Eval("id") + "\"" %>'>
                <div class='<%# "event-banner " + GetBannerClass(Container.ItemIndex) %>'>
                    <span class='<%# "event-badge " + Eval("badge_class") %>'><%# Eval("badge_text") %></span>
                    <div class="event-banner-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                    </div>
                </div>
                <div class="event-body">
                    <div class="event-cat"><%# Eval("category_name") %></div>
                    <h3 class="event-title"><%# Eval("title") %></h3>
                    <div class="event-meta">
                        <div>
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
                            <%# FormatCardDate(Eval("start_at")) %>
                        </div>
                        <div>
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>
                            <%# FormatLocation(Eval("format"), Eval("location_name"), Eval("location_room"), Eval("address")) %>
                        </div>
                    </div>
                    <div class="event-foot">
                        <div class="event-progress">
                            <div class="event-progress-head">
                                <span>Đã đăng ký</span>
                                <span class="event-progress-val"><%# Eval("registered_count") %> / <%# Eval("capacity") %></span>
                            </div>
                            <div class="event-progress-bar">
                                <div class='<%# GetProgressColor(Eval("occupancy_percent")) %>'
                                     style='<%# "width:" + Eval("occupancy_percent") + "%;" %>'></div>
                            </div>
                        </div>
                        <asp:LinkButton ID="btnRegister" runat="server" CssClass="event-cta primary"
                                        CommandName="Register" CommandArgument='<%# Eval("id") %>'
                                        OnClientClick="event.stopPropagation();">
                            Đăng ký
                        </asp:LinkButton>
                        <asp:LinkButton ID="btnRegistered" runat="server" CssClass="event-cta registered"
                                        Enabled="false" Visible="false">
                            &#10003; Đã ĐK
                        </asp:LinkButton>
                    </div>
                </div>
            </div>
        </ItemTemplate>
        <FooterTemplate></div></FooterTemplate>
    </asp:Repeater>

    <%-- Empty state --%>
    <asp:Panel ID="pnlEmpty" runat="server" CssClass="empty-state" Visible="false">
        <div class="empty-icon">&#128269;</div>
        <h3>Không tìm thấy sự kiện</h3>
        <p>Hãy thử thay đổi từ khoá hoặc bộ lọc.</p>
        <a id="lnkEmptyClear" runat="server" class="empty-cta" href="#">Xoá tất cả bộ lọc</a>
    </asp:Panel>

    <%-- Load more --%>
    <asp:Panel ID="pnlLoadMore" runat="server" CssClass="load-more" Visible="false">
        <asp:LinkButton ID="btnLoadMore" runat="server" CssClass="load-more-btn"
                        OnClick="LoadMore_Click" CausesValidation="false">
            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            Xem thêm <asp:Literal ID="litLoadMoreNum" runat="server" /> sự kiện
        </asp:LinkButton>
    </asp:Panel>

</div>

</asp:Content>
