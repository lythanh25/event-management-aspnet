<%@ Page Language="C#"
    MasterPageFile="~/UserMaster.Master"
    AutoEventWireup="true"
    CodeBehind="UserEventDetail.aspx.cs"
    Inherits="Eventhub.User.UserEventDetail" %>

<%-- ════════════ TITLE ════════════ --%>
<asp:Content ID="cntTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <asp:Literal ID="litPageTitle" runat="server" Text="Chi tiết sự kiện" /> — EventHub
</asp:Content>

<%-- ════════════ HEAD (CSS riêng) ════════════ --%>
<asp:Content ID="cntHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Content/Usereventdetail.css") %>" rel="stylesheet" type="text/css" />
</asp:Content>

<%-- ════════════ HERO (trong .dark-zone của Master) ════════════ --%>
<asp:Content ID="cntHero" ContentPlaceHolderID="HeroContent" runat="server">

    <section class="event-hero">

        <%-- Breadcrumb --%>
        <div class="breadcrumb">
            <a href="<%= ResolveUrl("~/User/UserHome.aspx") %>">Trang chủ</a>
            <span class="sep">›</span>
            <a href="<%= ResolveUrl("~/User/UserDiscover.aspx") %>">Sự kiện</a>
            <span class="sep">›</span>
            <span class="current">
                <asp:Literal ID="litCrumbTitle" runat="server" Text="Chi tiết" />
            </span>
        </div>

        <%-- Badges --%>
        <div class="hero-badges">
            <asp:Panel ID="pnlBadgeStatus" runat="server" CssClass="h-badge open">
                <asp:Literal ID="litBadgeStatus" runat="server" Text="Đang mở đăng ký" />
            </asp:Panel>
            <asp:Panel ID="pnlBadgeCategory" runat="server" CssClass="h-badge tag" Visible="false">
                <asp:Literal ID="litBadgeCategory" runat="server" />
            </asp:Panel>
            <asp:Panel ID="pnlBadgeFormat" runat="server" CssClass="h-badge lim" Visible="false">
                <asp:Literal ID="litBadgeFormat" runat="server" />
            </asp:Panel>
        </div>

        <%-- Title & subtitle --%>
        <h1 class="hero-title">
            <asp:Literal ID="litTitle" runat="server" Text="Chi tiết sự kiện" />
        </h1>
        <asp:Panel ID="pnlSubtitle" runat="server" CssClass="hero-sub" Visible="false">
            <asp:Literal ID="litSubtitle" runat="server" />
        </asp:Panel>

        <%-- Meta: date, time, location --%>
        <div class="hero-meta">
            <div>
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="4" width="18" height="18" rx="2" />
                    <line x1="16" y1="2" x2="16" y2="6" />
                    <line x1="8"  y1="2" x2="8"  y2="6" />
                    <line x1="3"  y1="10" x2="21" y2="10" />
                </svg>
                <asp:Literal ID="litMetaDate" runat="server" Text="—" />
            </div>
            <span class="divider">·</span>
            <div>
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10" />
                    <polyline points="12,6 12,12 16,14" />
                </svg>
                <asp:Literal ID="litMetaTime" runat="server" Text="—" />
            </div>
            <span class="divider">·</span>
            <div>
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" />
                    <circle cx="12" cy="10" r="3" />
                </svg>
                <asp:Literal ID="litMetaLocation" runat="server" Text="—" />
            </div>
        </div>

        <%-- Organizer --%>
        <div class="hero-organizer">
            Ban tổ chức: <b><asp:Literal ID="litOrganizer" runat="server" Text="—" /></b>
        </div>

        <%-- Stats --%>
        <div class="hero-stats">
            <div>
                <div class="hero-stat-num">
                    <asp:Literal ID="litStatRegistered" runat="server" Text="0" />
                    <small>/ <asp:Literal ID="litStatCapacity" runat="server" Text="0" /></small>
                </div>
                <div class="hero-stat-lbl">Đã đăng ký</div>
            </div>
            <div>
                <div class="hero-stat-num amber">
                    <asp:Literal ID="litStatRemaining" runat="server" Text="0" />
                </div>
                <div class="hero-stat-lbl">Chỗ trống</div>
            </div>
            <div>
                <div class="hero-stat-num">
                    <asp:Literal ID="litStatSpeakers" runat="server" Text="0" />
                </div>
                <div class="hero-stat-lbl">Diễn giả khách mời</div>
            </div>
            <div>
                <div class="hero-stat-num">
                    <asp:Literal ID="litStatDaysLeft" runat="server" Text="0" />
                </div>
                <div class="hero-stat-lbl">Ngày còn lại</div>
            </div>
        </div>

    </section>

</asp:Content>

<%-- ════════════ MAIN ════════════ --%>
<asp:Content ID="cntMain" ContentPlaceHolderID="MainContent" runat="server">

    <%-- Trường hợp event không tồn tại / đã bị xoá --%>
    <asp:Panel ID="pnlNotFound" runat="server" Visible="false">
        <div class="event-notfound">
            <h2>Không tìm thấy sự kiện</h2>
            <p>Sự kiện bạn đang xem không tồn tại hoặc đã bị xoá.</p>
            <a href="<%= ResolveUrl("~/User/UserHome.aspx") %>" class="reg-cta">← Về trang chủ</a>
        </div>
    </asp:Panel>

    <asp:Panel ID="pnlContent" runat="server">

        <div class="event-main">

            <%-- ════════ LEFT COLUMN ════════ --%>
            <div>

                <%-- Alert sau khi đăng ký --%>
                <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="detail-alert info">
                    <asp:Literal ID="litAlert" runat="server" />
                </asp:Panel>

                <%-- ─── DESCRIPTION CARD ─── --%>
                <div class="card">
                    <div class="card-head">
                        <div class="card-head-icon">
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                                 stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="12" cy="12" r="10" />
                                <line x1="12" y1="16" x2="12" y2="12" />
                                <line x1="12" y1="8" x2="12.01" y2="8" />
                            </svg>
                        </div>
                        <h2 class="card-title">Giới thiệu <em>sự kiện</em></h2>
                    </div>

                    <div class="prose">
                        <asp:Literal ID="litDescription" runat="server" />

                        <asp:Panel ID="pnlObjectives" runat="server" Visible="false" CssClass="prose-sub">
                            <div class="prose-sub-title">
                                <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                                     stroke-linecap="round" stroke-linejoin="round">
                                    <circle cx="12" cy="12" r="10" />
                                    <circle cx="12" cy="12" r="6" />
                                    <circle cx="12" cy="12" r="2" />
                                </svg>
                                Mục tiêu sự kiện
                            </div>
                            <asp:Repeater ID="rptObjectives" runat="server">
                                <HeaderTemplate><ul class="obj-list"></HeaderTemplate>
                                <ItemTemplate><li><%# Container.DataItem %></li></ItemTemplate>
                                <FooterTemplate></ul></FooterTemplate>
                            </asp:Repeater>
                        </asp:Panel>
                    </div>
                </div>

                <%-- ─── AGENDA CARD ─── --%>
                <div class="card">
                    <div class="card-head">
                        <div class="card-head-icon">
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                                 stroke-linecap="round" stroke-linejoin="round">
                                <path d="M9 11l3 3L22 4" />
                                <path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11" />
                            </svg>
                        </div>
                        <h2 class="card-title">Chương trình <em>chi tiết</em></h2>
                    </div>

                    <asp:Repeater ID="rptAgenda" runat="server">
                        <HeaderTemplate><div class="agenda"></HeaderTemplate>
                        <ItemTemplate>
                            <div class='<%# "agenda-item " + Eval("item_type") %>'>
                                <div class="agenda-time">
                                    <%# FormatAgendaTime(Eval("start_time")) %><br />
                                    — <%# FormatAgendaTime(Eval("end_time")) %>
                                </div>
                                <div class="agenda-content">
                                    <div class="agenda-title"><%# Eval("title") %></div>
                                    <%# !string.IsNullOrWhiteSpace(SafeStr(Eval("description")))
                                        ? "<div class='agenda-desc'>" + Server.HtmlEncode(SafeStr(Eval("description"))) + "</div>"
                                        : "" %>
                                    <%# !string.IsNullOrWhiteSpace(SafeStr(Eval("tag_label")))
                                        ? "<span class='agenda-tag " + (Eval("item_type").ToString() == "major" ? "featured" : "") + "'>" + Server.HtmlEncode(SafeStr(Eval("tag_label"))) + "</span>"
                                        : "" %>
                                </div>
                            </div>
                        </ItemTemplate>
                        <FooterTemplate></div></FooterTemplate>
                    </asp:Repeater>

                    <asp:Panel ID="pnlEmptyAgenda" runat="server" Visible="false">
                        <p style="color:var(--muted); font-size:13px; padding:8px 0;">
                            Chương trình chi tiết sẽ được cập nhật sớm.
                        </p>
                    </asp:Panel>
                </div>

            </div>

            <%-- ════════ RIGHT SIDEBAR ════════ --%>
            <aside class="event-side">

                <%-- ─── REGISTER CARD ─── --%>
                <div class="reg-card">
                    <span class="reg-pill">
                        <asp:Literal ID="litRegPill" runat="server" Text="ĐANG MỞ ĐĂNG KÝ" />
                    </span>
                    <div class="reg-title">
                        <asp:Literal ID="litRegTitle" runat="server" />
                    </div>
                    <div class="reg-price">
                        <asp:Literal ID="litRegPrice" runat="server" Text="Miễn phí" />
                    </div>

                    <div class="reg-progress">
                        <div class="reg-progress-head">
                            <span>Đã đăng ký</span>
                            <span class="reg-progress-val">
                                <asp:Literal ID="litRegProgressText" runat="server" Text="0 / 0" />
                            </span>
                        </div>
                        <div class="reg-progress-bar">
                            <div id="regProgressFill" runat="server" style="width:0%"></div>
                        </div>
                    </div>

                    <asp:Panel ID="pnlRegWarning" runat="server" CssClass="reg-warning" Visible="false">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
                            <circle cx="12" cy="13" r="8" />
                            <path d="M12 9v4l2 2" />
                        </svg>
                        <div>
                            <asp:Literal ID="litRegWarning" runat="server" />
                        </div>
                    </asp:Panel>

                    <asp:LinkButton ID="btnRegister" runat="server"
                                    CssClass="reg-cta"
                                    OnClick="btnRegister_Click">
                        Đăng ký tham gia
                    </asp:LinkButton>

                    <div class="reg-share">
                        <a href="javascript:void(0)" title="Hỏi đáp">
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                                 stroke-linecap="round" stroke-linejoin="round">
                                <path d="M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z" />
                            </svg>
                            Hỏi đáp
                        </a>
                        <asp:LinkButton ID="btnSave" runat="server"
                                        OnClick="btnSave_Click" CausesValidation="false">
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                                 stroke-linecap="round" stroke-linejoin="round">
                                <path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z" />
                            </svg>
                            <asp:Literal ID="litSaveText" runat="server" Text="Lưu lại" />
                        </asp:LinkButton>
                        <a href="javascript:void(0)" onclick="copyEventLink();return false;" title="Chia sẻ">
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                                 stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="18" cy="5" r="3" />
                                <circle cx="6" cy="12" r="3" />
                                <circle cx="18" cy="19" r="3" />
                                <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" />
                                <line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
                            </svg>
                            Chia sẻ
                        </a>
                    </div>

                    <%-- Benefit list (cứng) — sau này có thể chuyển sang DB cho từng sự kiện --%>
                    <div class="reg-benefits">
                        <div class="reg-benefit">
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5"
                                 stroke-linecap="round" stroke-linejoin="round">
                                <polyline points="20,6 9,17 4,12" />
                            </svg>
                            Bao gồm tài liệu sự kiện
                        </div>
                        <div class="reg-benefit">
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5"
                                 stroke-linecap="round" stroke-linejoin="round">
                                <polyline points="20,6 9,17 4,12" />
                            </svg>
                            Có chứng nhận tham dự
                        </div>
                        <div class="reg-benefit">
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5"
                                 stroke-linecap="round" stroke-linejoin="round">
                                <polyline points="20,6 9,17 4,12" />
                            </svg>
                            Tài liệu được gửi qua email sau sự kiện
                        </div>
                    </div>
                </div>

                <%-- ─── INFO CARD ─── --%>
                <div class="info-card">
                    <div class="info-title">Thông tin chi tiết</div>

                    <div class="info-row">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
                            <rect x="3" y="4" width="18" height="18" rx="2" />
                            <line x1="16" y1="2" x2="16" y2="6" />
                            <line x1="8"  y1="2" x2="8"  y2="6" />
                            <line x1="3"  y1="10" x2="21" y2="10" />
                        </svg>
                        <div>
                            <b><asp:Literal ID="litInfoDate" runat="server" /></b>
                            <asp:Literal ID="litInfoDateSub" runat="server" />
                        </div>
                    </div>

                    <div class="info-row">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
                            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" />
                            <circle cx="12" cy="10" r="3" />
                        </svg>
                        <div>
                            <b><asp:Literal ID="litInfoLocation" runat="server" /></b>
                            <asp:Literal ID="litInfoLocationSub" runat="server" />
                        </div>
                    </div>

                    <div class="info-row">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
                            <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2" />
                            <circle cx="12" cy="7" r="4" />
                        </svg>
                        <div>
                            <b><asp:Literal ID="litInfoOrg" runat="server" /></b>
                            Ban tổ chức
                        </div>
                    </div>

                    <div class="info-row">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
                            <rect x="3" y="5" width="18" height="14" rx="2" />
                            <polyline points="3,7 12,13 21,7" />
                        </svg>
                        <div>
                            <b>Hạn đăng ký</b>
                            <asp:Literal ID="litInfoDeadline" runat="server" />
                        </div>
                    </div>
                </div>

                <%-- ─── RELATED EVENTS ─── --%>
                <asp:Panel ID="pnlRelated" runat="server" CssClass="related-card" Visible="false">
                    <div class="related-title">Sự kiện liên quan</div>

                    <asp:Repeater ID="rptRelated" runat="server">
                        <ItemTemplate>
                            <a href='<%# ResolveUrl("~/User/UserEventDetail.aspx") + "?id=" + Eval("id") %>'
                               class="related-item">
                                <div class='<%# "related-thumb " + GetRelatedThumbClass(Container.ItemIndex) %>'>
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                                         stroke-linecap="round" stroke-linejoin="round">
                                        <rect x="3" y="4" width="18" height="18" rx="2" />
                                        <line x1="16" y1="2"  x2="16" y2="6" />
                                        <line x1="8"  y1="2"  x2="8"  y2="6" />
                                        <line x1="3"  y1="10" x2="21" y2="10" />
                                    </svg>
                                </div>
                                <div class="related-content">
                                    <div class="related-name"><%# Eval("title") %></div>
                                    <div class="related-date"><%# FormatRelatedDate(Eval("start_at")) %></div>
                                </div>
                            </a>
                        </ItemTemplate>
                    </asp:Repeater>
                </asp:Panel>

                <%-- ─── SPEAKERS CARD ─── --%>
                <asp:Panel ID="pnlSpeakers" runat="server" CssClass="speakers-card" Visible="false">
                    <div class="speakers-head">
                        <div class="speakers-icon">
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2"
                                 stroke-linecap="round" stroke-linejoin="round">
                                <path d="M12 1a3 3 0 00-3 3v8a3 3 0 006 0V4a3 3 0 00-3-3z" />
                                <path d="M19 10v2a7 7 0 01-14 0v-2" />
                                <line x1="12" y1="19" x2="12" y2="23" />
                                <line x1="8" y1="23" x2="16" y2="23" />
                            </svg>
                        </div>
                        <div class="speakers-title">Diễn giả &amp; <em>Chuyên gia</em></div>
                    </div>

                    <asp:Repeater ID="rptSpeakers" runat="server">
                        <ItemTemplate>
                            <div class="speaker">
                                <div class='<%# "speaker-avatar " + GetAvatarClass(Container.ItemIndex) %>'>
                                    <%# GetInitial(Eval("full_name")) %>
                                </div>
                                <div>
                                    <div class="speaker-name"><%# Eval("full_name") %></div>
                                    <%# !string.IsNullOrWhiteSpace(SafeStr(Eval("title")))
                                        ? "<div class='speaker-role'>" + Server.HtmlEncode(SafeStr(Eval("title"))) + "</div>"
                                        : "" %>
                                    <%# !string.IsNullOrWhiteSpace(SafeStr(Eval("bio")))
                                        ? "<div class='speaker-bio'>" + Server.HtmlEncode(TruncateText(SafeStr(Eval("bio")), 180)) + "</div>"
                                        : "" %>
                                </div>
                            </div>
                        </ItemTemplate>
                    </asp:Repeater>
                </asp:Panel>

            </aside>

        </div>

    </asp:Panel>

    <%-- ════════ SCRIPTS ════════ --%>
    <script type="text/javascript">
        function copyEventLink() {
            var url = window.location.href;
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(url).then(function () {
                    alert('Đã copy link sự kiện!');
                });
            } else {
                // Fallback IE/old browser
                var input = document.createElement('input');
                input.value = url;
                document.body.appendChild(input);
                input.select();
                try { document.execCommand('copy'); alert('Đã copy link sự kiện!'); }
                catch (err) { prompt('Copy link:', url); }
                document.body.removeChild(input);
            }
        }
    </script>

</asp:Content>
