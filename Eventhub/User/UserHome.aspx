<%@ Page Title="Trang chủ — EventHub" Language="C#"
    MasterPageFile="~/UserMaster.Master"
    AutoEventWireup="true"
    CodeBehind="UserHome.aspx.cs"
    Inherits="Eventhub.User.UserHome" %>

<%-- ════════════ TITLE ════════════ --%>
<asp:Content ID="cntTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Trang chủ — EventHub
</asp:Content>

<%-- ════════════ HEAD (CSS riêng cho trang) ════════════ --%>
<asp:Content ID="cntHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Content/UserHome.css") %>" rel="stylesheet" type="text/css" />
</asp:Content>

<%-- ════════════ HERO (nằm trong .dark-zone của Master) ════════════ --%>
<asp:Content ID="cntHero" ContentPlaceHolderID="HeroContent" runat="server">

    <section class="hero">

        <%-- ── LEFT: Lời chào + stats ── --%>
        <div>
            <div class="hero-date">
                <asp:Label ID="lblTodayLabel" runat="server" />
            </div>

            <h1 class="hero-title">
                Xin chào,
                <span class="accent"><asp:Label ID="lblShortName" runat="server" Text="bạn" />.</span><br />
                Sự kiện nào hôm nay?
            </h1>

            <p class="hero-desc">
                Khám phá các sự kiện nội bộ đang diễn ra và sắp tới.
                Tham gia để tối ưu sự đóng góp và phát triển bản thân.
            </p>

            <asp:Label ID="lblPageMessage" runat="server"
                       CssClass="page-message" EnableViewState="false" />

            <div class="hero-stats">
                <div>
                    <div class="hero-stat-num">
                        <asp:Label ID="lblUpcomingCount" runat="server" Text="0" />
                    </div>
                    <div class="hero-stat-lbl">Sự kiện sắp tới</div>
                </div>
                <div>
                    <div class="hero-stat-num">
                        <asp:Label ID="lblRegisteredCount" runat="server" Text="0" />
                    </div>
                    <div class="hero-stat-lbl">Bạn đã đăng ký</div>
                </div>
                <div>
                    <div class="hero-stat-num">
                        <asp:Label ID="lblTotalParticipants" runat="server" Text="0" />
                    </div>
                    <div class="hero-stat-lbl">Người tham gia</div>
                </div>
            </div>
        </div>

        <%-- ── RIGHT: Sự kiện nổi bật (featured card) ── --%>
        <div class="featured-card">
            <span class="featured-pill">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2.2"
                     stroke-linecap="round" stroke-linejoin="round">
                    <polygon points="13,2 3,14 12,14 11,22 21,10 12,10 13,2" />
                </svg>
                <asp:Label ID="lblFeaturedStatus" runat="server" Text="ĐANG MỞ ĐĂNG KÝ" />
            </span>

            <div class="featured-title">
                <asp:Label ID="lblFeaturedTitle" runat="server" Text="Hội thảo Chuyển đổi Số 2025" />
            </div>

            <div class="featured-meta">
                <div>
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2" />
                        <line x1="16" y1="2"  x2="16" y2="6" />
                        <line x1="8"  y1="2"  x2="8"  y2="6" />
                        <line x1="3"  y1="10" x2="21" y2="10" />
                    </svg>
                    <asp:Label ID="lblFeaturedDate" runat="server" Text="—" />
                </div>
                <div>
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" />
                        <circle cx="12" cy="10" r="3" />
                    </svg>
                    <asp:Label ID="lblFeaturedLocation" runat="server" Text="—" />
                </div>
            </div>

            <div class="featured-progress">
                <div class="featured-progress-head">
                    <span class="lbl">
                        <asp:Label ID="lblFeaturedRegisteredText" runat="server"
                                   Text="0 / 0 người đã đăng ký" />
                    </span>
                    <span class="val">
                        <asp:Label ID="lblFeaturedPercent" runat="server" Text="0%" />
                    </span>
                </div>
                <div class="featured-progress-bar">
                    <div id="featuredProgressFill" runat="server" style="width:0%"></div>
                </div>
            </div>

            <asp:LinkButton ID="btnFeaturedRegister" runat="server"
                            CssClass="featured-cta"
                            OnClick="btnFeaturedRegister_Click">
                Đăng ký ngay →
            </asp:LinkButton>
        </div>

    </section>

</asp:Content>

<%-- ════════════ MAIN (light-zone — nằm trong <main> của Master) ════════════ --%>
<asp:Content ID="cntMain" ContentPlaceHolderID="MainContent" runat="server">

    <div class="light-zone">

        <%-- ─────────── SEARCH + FILTER BAR ─────────── --%>
        <div class="search-bar">
            <svg class="search-bar-icon" viewBox="0 0 24 24" fill="none"
                 stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="11" cy="11" r="8" />
                <line x1="21" y1="21" x2="16.65" y2="16.65" />
            </svg>

            <asp:TextBox ID="txtSearch" runat="server"
                         CssClass="search-input"
                         placeholder="Tìm kiếm sự kiện, chủ đề, diễn giả..." />

            <asp:LinkButton ID="btnSearch" runat="server"
                            CssClass="search-icon-btn dark"
                            OnClick="btnSearch_Click"
                            ToolTip="Tìm kiếm">🔍</asp:LinkButton>

            <div class="search-divider"></div>

            <asp:LinkButton ID="btnFilterAll"      runat="server" CssClass="search-pill active"
                            CommandArgument="ALL"      OnClick="Filter_Click">Tất cả</asp:LinkButton>
            <asp:LinkButton ID="btnFilterTech"     runat="server" CssClass="search-pill"
                            CommandArgument="Công nghệ" OnClick="Filter_Click">Kỹ thuật</asp:LinkButton>
            <asp:LinkButton ID="btnFilterHR"       runat="server" CssClass="search-pill"
                            CommandArgument="Nhân sự"   OnClick="Filter_Click">Nhân sự</asp:LinkButton>
            <asp:LinkButton ID="btnFilterCulture"  runat="server" CssClass="search-pill"
                            CommandArgument="Văn hoá"   OnClick="Filter_Click">Văn hoá</asp:LinkButton>
            <asp:LinkButton ID="btnFilterTraining" runat="server" CssClass="search-pill"
                            CommandArgument="Đào tạo"   OnClick="Filter_Click">Đào tạo</asp:LinkButton>

            <div class="search-divider"></div>

            <button class="search-icon-btn" type="button" title="Lịch sự kiện">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                     stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="4" width="18" height="18" rx="2" />
                    <line x1="16" y1="2"  x2="16" y2="6" />
                    <line x1="8"  y1="2"  x2="8"  y2="6" />
                    <line x1="3"  y1="10" x2="21" y2="10" />
                </svg>
            </button>

            <button class="search-icon-btn dark" type="button" title="Lọc nâng cao">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                     stroke-linecap="round" stroke-linejoin="round">
                    <line x1="3"  y1="6"  x2="21" y2="6" />
                    <line x1="6"  y1="12" x2="18" y2="12" />
                    <line x1="9"  y1="18" x2="15" y2="18" />
                </svg>
            </button>
        </div>

        <%-- ─────────── SECTION: HOT EVENTS ─────────── --%>
        <section class="section">
            <div class="section-head">
                <div class="section-title">
                    <span class="icon">🔥</span>
                    Sự kiện <em>đang Hot</em>
                </div>
                <a class="section-link" href="<%= ResolveUrl("~/User/UserDiscover.aspx") %>">
                    Xem tất cả
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                        <line x1="5"  y1="12" x2="19" y2="12" />
                        <polyline points="12,5 19,12 12,19" />
                    </svg>
                </a>
            </div>

            <asp:Repeater ID="rptHotEvents" runat="server"
                          OnItemCommand="rptHotEvents_ItemCommand"
                          OnItemDataBound="rptHotEvents_ItemDataBound">

                <HeaderTemplate>
                    <div class="hot-grid">
                </HeaderTemplate>

                <ItemTemplate>
                    <div class="hot-card"
                         onclick="window.location.href='<%= ResolveUrl("~/User/UserEventDetail.aspx") %>?id=<%# Eval("id") %>'"
                         style="cursor:pointer;">

                        <div class='<%# "hot-banner " + GetHotBannerClass(Container.ItemIndex) %>'>
                            <span class='<%# "hot-badge " + Eval("badge_class") %>'>
                                <%# Eval("badge_text") %>
                            </span>
                            <div class="hot-banner-icon">
                                <svg viewBox="0 0 24 24" fill="none" stroke-width="1.5"
                                     stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M9 18h6" />
                                    <path d="M10 22h4" />
                                    <path d="M12 2a7 7 0 00-4 12.5V17h8v-2.5A7 7 0 0012 2z" />
                                </svg>
                            </div>
                        </div>

                        <div class="hot-body">
                            <div class="hot-cat"><%# Eval("category_name") %></div>
                            <h3 class="hot-title"><%# Eval("title") %></h3>

                            <div class="hot-meta">
                                <div>
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                                         stroke-linecap="round" stroke-linejoin="round">
                                        <rect x="3" y="4" width="18" height="18" rx="2" />
                                        <line x1="16" y1="2"  x2="16" y2="6" />
                                        <line x1="8"  y1="2"  x2="8"  y2="6" />
                                        <line x1="3"  y1="10" x2="21" y2="10" />
                                    </svg>
                                    <%# FormatHotDate(Eval("start_at")) %>
                                </div>
                                <div>
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                                         stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" />
                                        <circle cx="12" cy="10" r="3" />
                                    </svg>
                                    <%# FormatLocation(Eval("format"), Eval("location_name"),
                                                       Eval("location_room"), Eval("address")) %>
                                </div>
                            </div>

                            <div class="hot-foot">
                                <div class="hot-foot-info">
                                    <%# Eval("registered_count") %> / <%# Eval("capacity") %>
                                    <small>người đã đăng ký</small>
                                </div>

                                <asp:LinkButton ID="btnRegisterHot" runat="server"
                                                CssClass="hot-cta primary"
                                                CommandName="Register"
                                                CommandArgument='<%# Eval("id") %>'
                                                OnClientClick="event.stopPropagation();">
                                    Đăng ký
                                </asp:LinkButton>

                                <asp:LinkButton ID="btnRegisteredHot" runat="server"
                                                CssClass="hot-cta registered"
                                                Enabled="false" Visible="false">
                                    ✓ Đã đăng ký
                                </asp:LinkButton>
                            </div>
                        </div>
                    </div>
                </ItemTemplate>

                <FooterTemplate>
                    </div>
                </FooterTemplate>
            </asp:Repeater>

            <asp:Panel ID="pnlEmptyHot" runat="server" Visible="false">
                <div class="empty-card">
                    <h3 class="hot-title">Chưa có sự kiện hot</h3>
                    <p class="up-desc">Hệ thống sẽ hiển thị sự kiện ngay khi có dữ liệu phù hợp.</p>
                </div>
            </asp:Panel>
        </section>

        <%-- ─────────── SECTION: UPCOMING EVENTS ─────────── --%>
        <section class="section">
            <div class="section-head">
                <div class="section-title">
                    <span class="icon">🗓</span>
                    Sự kiện <em>sắp diễn ra</em>
                </div>
                <a class="section-link" href="<%= ResolveUrl("~/User/UserDiscover.aspx") %>">
                    Xem tất cả
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                        <line x1="5"  y1="12" x2="19" y2="12" />
                        <polyline points="12,5 19,12 12,19" />
                    </svg>
                </a>
            </div>

            <asp:Repeater ID="rptUpcomingEvents" runat="server"
                          OnItemCommand="rptUpcomingEvents_ItemCommand"
                          OnItemDataBound="rptUpcomingEvents_ItemDataBound">

                <HeaderTemplate>
                    <div class="upcoming-grid">
                </HeaderTemplate>

                <ItemTemplate>
                    <div class="up-card"
                         onclick="window.location.href='<%= ResolveUrl("~/User/UserEventDetail.aspx") %>?id=<%# Eval("id") %>'"
                         style="cursor:pointer;">

                        <div class="up-card-head">
                            <div class="up-date-box">
                                <div class="up-date-day"><%# GetDay(Eval("start_at")) %></div>
                                <div class="up-date-mon"><%# GetMonthShort(Eval("start_at")) %></div>
                            </div>
                            <div class="up-tags-stack">
                                <span class='<%# "up-tag " + Eval("badge_class") %>'>
                                    <%# Eval("badge_text") %>
                                </span>
                            </div>
                        </div>

                        <div class="up-cat"><%# Eval("category_name") %></div>
                        <h3 class="up-title"><%# Eval("title") %></h3>
                        <p class="up-desc">
                            <%# GetCardDescription(Eval("subtitle"), Eval("description")) %>
                        </p>

                        <div class="up-meta">
                            <div>
                                <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                                     stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="3" y="4" width="18" height="18" rx="2" />
                                    <line x1="16" y1="2"  x2="16" y2="6" />
                                    <line x1="8"  y1="2"  x2="8"  y2="6" />
                                    <line x1="3"  y1="10" x2="21" y2="10" />
                                </svg>
                                <%# FormatUpcomingSchedule(Eval("start_at"), Eval("end_at")) %>
                            </div>
                            <div>
                                <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                                     stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" />
                                    <circle cx="12" cy="10" r="3" />
                                </svg>
                                <%# FormatLocation(Eval("format"), Eval("location_name"),
                                                   Eval("location_room"), Eval("address")) %>
                            </div>
                        </div>

                        <div class="up-progress">
                            <div class="up-progress-head">
                                <span class="up-progress-lbl">Đăng ký</span>
                                <span class="up-progress-val">
                                    <%# Eval("registered_count") %>
                                    <small>/ <%# Eval("capacity") %> · <%# Eval("occupancy_percent") %>%</small>
                                </span>
                            </div>
                            <div class="up-progress-bar">
                                <div class='<%# GetProgressBarClass(Eval("occupancy_percent")) %>'
                                     style='<%# "width:" + Eval("occupancy_percent") + "%;" %>'></div>
                            </div>
                        </div>

                        <div class="up-foot">
                            <div class='<%# "up-foot-info" + ((Eval("days_left") != DBNull.Value && Convert.ToInt32(Eval("days_left")) <= 3) ? " deadline-close" : "") %>'>
                                Hạn: còn <%# Eval("days_left") %> ngày
                            </div>

                            <asp:LinkButton ID="btnRegisterUp" runat="server"
                                            CssClass="up-cta primary"
                                            CommandName="Register"
                                            CommandArgument='<%# Eval("id") %>'
                                            OnClientClick="event.stopPropagation();">
                                Đăng ký
                            </asp:LinkButton>

                            <asp:LinkButton ID="btnRegisteredUp" runat="server"
                                            CssClass="up-cta registered"
                                            Enabled="false" Visible="false">
                                ✓ Đã đăng ký
                            </asp:LinkButton>
                        </div>
                    </div>
                </ItemTemplate>

                <FooterTemplate>
                    </div>
                </FooterTemplate>
            </asp:Repeater>

            <asp:Panel ID="pnlEmptyUpcoming" runat="server" Visible="false">
                <div class="empty-card">
                    <h3 class="up-title">Chưa có sự kiện nào để hiển thị</h3>
                    <p class="up-desc">Hệ thống sẽ tự động hiện sự kiện khi có dữ liệu mới.</p>
                </div>
            </asp:Panel>

            <div class="load-more">
                <a class="load-more-btn" href="<%= ResolveUrl("~/User/UserDiscover.aspx") %>">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                         stroke-linecap="round" stroke-linejoin="round">
                        <line x1="12" y1="5"  x2="12" y2="19" />
                        <line x1="5"  y1="12" x2="19" y2="12" />
                    </svg>
                    Xem thêm sự kiện
                </a>
            </div>
        </section>

    </div>
    <%-- /.light-zone --%>

</asp:Content>
