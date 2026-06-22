<%@ Page Title="Xét duyệt đăng ký" Language="C#" MasterPageFile="~/AdminMaster.Master"
    AutoEventWireup="true" CodeBehind="Approval.aspx.cs"
    Inherits="Eventhub.Admin.approval" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Xét duyệt đăng ký — EventHub Admin
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Content/Approval.css") %>" rel="stylesheet" type="text/css" />
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <%-- Alert --%>
    <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="alert">
        <asp:Literal ID="litAlert" runat="server" />
    </asp:Panel>

    <%-- ─── PAGE HEAD ─── --%>
    <div class="page-head">
        <div>
            <h1 class="page-title">Xét duyệt đăng ký</h1>
            <div class="page-sub">
                <b><asp:Literal ID="litTotalPending" runat="server" Text="0" /> yêu cầu</b> đang chờ xử lý
                trên <b><asp:Literal ID="litEventCount" runat="server" Text="0" /> sự kiện</b>.
                Hệ thống ưu tiên hiển thị các sự kiện có yêu cầu lâu nhất chưa xử lý.
            </div>
        </div>
    </div>

    <%-- ─── STATS STRIP ─── --%>
    <div class="stats-strip">
        <div class="stat-card">
            <div class="stat-card-head">
                <div class="stat-icon-box amber">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/>
                    </svg>
                </div>
                Tổng yêu cầu chờ
            </div>
            <div class="stat-card-value"><asp:Literal ID="litStatPending" runat="server" Text="0" /></div>
            <div class="stat-card-trend"><asp:Literal ID="litStatPendingTrend" runat="server" /></div>
        </div>

        <div class="stat-card">
            <div class="stat-card-head">
                <div class="stat-icon-box dark">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2"/>
                        <line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/>
                        <line x1="3" y1="10" x2="21" y2="10"/>
                    </svg>
                </div>
                Sự kiện cần xử lý
            </div>
            <div class="stat-card-value"><asp:Literal ID="litStatEvents" runat="server" Text="0" /></div>
            <div class="stat-card-trend"><asp:Literal ID="litStatEventsTrend" runat="server" /></div>
        </div>

        <div class="stat-card">
            <div class="stat-card-head">
                <div class="stat-icon-box green">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20,6 9,17 4,12"/>
                    </svg>
                </div>
                Đã duyệt 7 ngày
            </div>
            <div class="stat-card-value"><asp:Literal ID="litStatApproved" runat="server" Text="0" /></div>
            <div class="stat-card-trend green"><asp:Literal ID="litStatApprovedRate" runat="server" /></div>
        </div>

        <div class="stat-card">
            <div class="stat-card-head">
                <div class="stat-icon-box red">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="13" r="8"/><path d="M12 9v4l2 2"/>
                        <path d="M5 3L2 6"/><path d="M22 6l-3-3"/>
                    </svg>
                </div>
                Yêu cầu cũ nhất
            </div>
            <div class="stat-card-value"><asp:Literal ID="litStatOldest" runat="server" Text="—" /></div>
            <div class="stat-card-trend"><asp:Literal ID="litStatOldestTrend" runat="server" /></div>
        </div>
    </div>

    <%-- ─── FILTER BAR ─── --%>
    <div class="filter-bar">
        <asp:HyperLink ID="tabUrgent" runat="server" CssClass="filter-tab">
            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M8.5 14.5A2.5 2.5 0 0011 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 11-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 002.5 2.5z"/>
            </svg>
            Cần xử lý ngay
            <span class="count hot"><asp:Literal ID="litCntUrgent" runat="server" Text="0" /></span>
        </asp:HyperLink>

        <asp:HyperLink ID="tabAll" runat="server" CssClass="filter-tab">
            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/>
            </svg>
            Tất cả có pending
            <span class="count"><asp:Literal ID="litCntAll" runat="server" Text="0" /></span>
        </asp:HyperLink>

        <asp:HyperLink ID="tabFull" runat="server" CssClass="filter-tab">
            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z"/>
                <line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/>
            </svg>
            Sắp đầy chỗ
            <span class="count"><asp:Literal ID="litCntFull" runat="server" Text="0" /></span>
        </asp:HyperLink>

        <div class="filter-spacer"></div>

        <div class="filter-search-inline">
            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
            </svg>
            <asp:TextBox ID="txtSearch" runat="server" placeholder="Tìm sự kiện..." AutoPostBack="true"
                         OnTextChanged="txtSearch_TextChanged" />
        </div>
    </div>

    <%-- ─── MÃ XÁC NHẬN ─── --%>
    <div class="section">
        <div class="section-head">
            <div class="section-title">
                Mã xác nhận
                <span class="section-tag">BÀI THI</span>
            </div>
        </div>

        <div style="max-width: 520px;">
            <div class="filter-search-inline" style="margin-bottom:10px;">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="11" cy="11" r="8"></circle>
                    <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
                </svg>

                <asp:TextBox ID="txtMaXacNhan" runat="server" placeholder="Nhập mã, ví dụ: ABC12@" />
            </div>

            <asp:RequiredFieldValidator
                ID="rfvMaXacNhan"
                runat="server"
                ControlToValidate="txtMaXacNhan"
                ErrorMessage="Vui lòng nhập mã xác nhận."
                ForeColor="Red"
                Display="Dynamic"
                ValidationGroup="vgMaXN" />

            <asp:RegularExpressionValidator
                ID="revMaXacNhan"
                runat="server"
                ControlToValidate="txtMaXacNhan"
                ValidationExpression="^(?=(?:.*[A-Z]){3})(?=(?:.*\d){2})[A-Z\d]{5}@$"
                ErrorMessage="Mã phải gồm 3 chữ hoa, 2 chữ số và kết thúc bằng @."
                ForeColor="Red"
                Display="Dynamic"
                ValidationGroup="vgMaXN" />

            <div style="margin-top:12px;">
                <asp:LinkButton
                    ID="btnThemMa"
                    runat="server"
                    CssClass="btn-modal btn-modal-primary"
                    OnClick="btnThemMa_Click"
                    ValidationGroup="vgMaXN">
                    Thêm mã
                </asp:LinkButton>
            </div>
        </div>

        <asp:Panel ID="pnlMaAlert" runat="server" Visible="false" CssClass="alert" style="margin-top:12px;">
            <asp:Literal ID="litMaAlert" runat="server" />
        </asp:Panel>

        <div style="margin-top:18px;">
            <div class="section-title" style="font-size:18px; margin-bottom:10px;">
                Danh sách mã đã thêm
            </div>

            <ol>
                <asp:Repeater ID="rptMaXacNhan" runat="server" OnItemCommand="rptMaXacNhan_ItemCommand">
                    <ItemTemplate>
                        <li style="margin-bottom:8px;">
                            <asp:LinkButton
                                ID="lnkHide"
                                runat="server"
                                Text='<%# Eval("MaXacNhan") %>'
                                CommandName="Hide"
                                CommandArgument='<%# Eval("Id") %>'
                                CausesValidation="false" />
                        </li>
                    </ItemTemplate>
                </asp:Repeater>
            </ol>
        </div>
    </div>

    <%-- ─── SECTION: SỰ KIỆN CẦN XỬ LÝ ─── --%>
    <div class="section">
        <div class="section-head">
            <div class="section-title">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="width:22px;height:22px;stroke:var(--red);">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
                Sự kiện <em>chờ duyệt</em>
                <span class="section-tag hot"><asp:Literal ID="litSectionCount" runat="server" Text="0" /> SỰ KIỆN</span>
            </div>
        </div>

        <asp:Panel ID="pnlEmpty" runat="server" CssClass="empty-state" Visible="false">
            <svg viewBox="0 0 24 24" fill="none" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="20,6 9,17 4,12"/>
            </svg>
            <div class="empty-title">Không có yêu cầu nào chờ duyệt</div>
            <div class="empty-sub">Mọi đăng ký đã được xử lý xong. Tốt lắm!</div>
        </asp:Panel>

        <div class="event-grid">
            <asp:Repeater ID="rptEvents" runat="server" OnItemCommand="rptEvents_ItemCommand">
                <ItemTemplate>
                    <div class='<%# (int)Eval("PendingCount") > 0 ? "event-card has-pending" : "event-card" %>'>
                        <div class='<%# "event-banner bg-" + Eval("BannerIndex") %>'>
                            <div class="event-time-badge">
                                <div class="event-time-day"><%# Eval("StartAt", "{0:dd}") %></div>
                                <div class="event-time-mon">THG <%# Eval("StartAt", "{0:MM}") %></div>
                            </div>
                            <span class="event-banner-tag"><%# Eval("CategoryName") %></span>
                        </div>
                        <div class="event-body">
                            <h3 class="event-title"><%# Eval("Title") %></h3>
                            <div class="event-meta">
                                <div>
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <rect x="3" y="4" width="18" height="18" rx="2"/>
                                        <line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/>
                                        <line x1="3" y1="10" x2="21" y2="10"/>
                                    </svg>
                                    <%# Eval("StartAt", "{0:dd/MM/yyyy}") %> · <%# Eval("StartAt", "{0:HH:mm}") %>
                                </div>
                                <div>
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/>
                                        <circle cx="12" cy="10" r="3"/>
                                    </svg>
                                    <%# Eval("LocationName") %>
                                </div>
                                <div class='<%# (bool)Eval("IsDeadlineSoon") ? "event-meta-deadline" : "" %>'>
                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                        <circle cx="12" cy="13" r="8"/><path d="M12 9v4l2 2"/>
                                    </svg>
                                    <%# Eval("DeadlineText") %>
                                </div>
                            </div>

                            <div class="reg-progress">
                                <div class="reg-progress-head">
                                    <span class="reg-progress-lbl">NĂNG LỰC <%# Eval("Capacity") %> NGƯỜI</span>
                                    <span class="reg-progress-val">
                                        <%# (int)Eval("ApprovedCount") + (int)Eval("PendingCount") %>
                                        <small>/ <%# Eval("Capacity") %> · <%# Eval("FillPercent") %>%</small>
                                    </span>
                                </div>
                                <div class="reg-progress-bar">
                                    <div class="approved" style='width: <%# Eval("ApprovedPercent") %>%'></div>
                                    <div class="pending" style='width: <%# Eval("PendingPercent") %>%'></div>
                                </div>
                                <div class="reg-progress-legend">
                                    <span class="leg-approved"><%# Eval("ApprovedCount") %> đã duyệt</span>
                                    <span class="leg-pending"><%# Eval("PendingCount") %> chờ</span>
                                    <span class='<%# (int)Eval("Remaining") <= 0 ? "leg-full" : "leg-empty" %>'>
                                        <%# (int)Eval("Remaining") <= 0 ? "⚠ Hết chỗ" : Eval("Remaining") + " còn lại" %>
                                    </span>
                                </div>
                            </div>

                            <div class="recent-activity">
                                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M16 21v-2a4 4 0 00-4-4H6a4 4 0 00-4 4v2"/>
                                    <circle cx="9" cy="7" r="4"/>
                                </svg>
                                <span><%# Eval("LatestActivityText") %></span>
                            </div>
                        </div>
                        <div class="event-footer">
                            <asp:HyperLink runat="server" CssClass="event-action urgent"
                                           NavigateUrl='<%# "~/Admin/RegistrationDetail.aspx?eventId=" + Eval("Id") + "&status=pending" %>'>
                                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M9 11l3 3L22 4"/>
                                    <path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"/>
                                </svg>
                                Xét duyệt
                                <span class="badge-num"><%# Eval("PendingCount") %></span>
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

    <%-- ═════════ MODAL: XÉT DUYỆT NGƯỜI ĐĂNG KÝ ═════════ --%>
    <asp:Panel ID="pnlModal" runat="server" CssClass="modal-overlay" Visible="false">
        <div class="modal-box">
            <div class="modal-head">
                <div>
                    <div class="modal-title">Xét duyệt đăng ký</div>
                    <div class="modal-sub">
                        <asp:Literal ID="litModalEventTitle" runat="server" />
                        — <b><asp:Literal ID="litModalPending" runat="server" Text="0" /></b> yêu cầu chờ duyệt
                    </div>
                </div>
                <div class="modal-head-actions">
                    <asp:LinkButton ID="btnApproveAll" runat="server" CssClass="btn-modal btn-modal-primary"
                                    OnClick="btnApproveAll_Click" CausesValidation="false"
                                    OnClientClick="return confirm('Bạn có chắc muốn duyệt TẤT CẢ yêu cầu chờ trong sự kiện này?');">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="20,6 9,17 4,12"/>
                        </svg>
                        Duyệt tất cả
                    </asp:LinkButton>
                    <asp:LinkButton ID="btnRejectAll" runat="server" CssClass="btn-modal btn-modal-danger"
                                    OnClick="btnRejectAll_Click" CausesValidation="false"
                                    OnClientClick="return confirm('Bạn có chắc muốn TỪ CHỐI tất cả yêu cầu chờ trong sự kiện này?');">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                        </svg>
                        Từ chối tất cả
                    </asp:LinkButton>
                    <asp:LinkButton ID="btnCloseModal" runat="server" CssClass="modal-close"
                                    OnClick="btnCloseModal_Click" CausesValidation="false">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                        </svg>
                    </asp:LinkButton>
                </div>
            </div>

            <div class="modal-body">
                <div class="table-wrap">
                    <table class="tbl">
                        <thead>
                            <tr>
                                <th>#</th>
                                <th>Người đăng ký</th>
                                <th>Phòng ban</th>
                                <th>Thời gian đăng ký</th>
                                <th style="text-align:right;">Hành động</th>
                            </tr>
                        </thead>
                        <tbody>
                            <asp:Repeater ID="rptPending" runat="server"
                                          OnItemCommand="rptPending_ItemCommand">
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
                                            <div class="time-cell">
                                                <%# Eval("TimeAgo") %>
                                                <small><%# Eval("RegisteredAt", "{0:HH:mm, dd/MM}") %></small>
                                            </div>
                                        </td>
                                        <td>
                                            <div class="row-acts">
                                                <asp:LinkButton runat="server" CssClass="row-act-sm approve"
                                                                ToolTip="Duyệt"
                                                                CommandName="ApproveOne"
                                                                CommandArgument='<%# Eval("Id") %>'
                                                                CausesValidation="false">
                                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                                        <polyline points="20,6 9,17 4,12"/>
                                                    </svg>
                                                    Duyệt
                                                </asp:LinkButton>
                                                <asp:LinkButton runat="server" CssClass="row-act-sm reject"
                                                                ToolTip="Từ chối"
                                                                CommandName="RejectOne"
                                                                CommandArgument='<%# Eval("Id") %>'
                                                                CausesValidation="false">
                                                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                        <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                                                    </svg>
                                                    Từ chối
                                                </asp:LinkButton>
                                            </div>
                                        </td>
                                    </tr>
                                </ItemTemplate>
                            </asp:Repeater>

                            <asp:PlaceHolder ID="phModalEmpty" runat="server" Visible="false">
                                <tr>
                                    <td colspan="5" class="empty-cell">
                                        Không có yêu cầu nào chờ duyệt cho sự kiện này.
                                    </td>
                                </tr>
                            </asp:PlaceHolder>
                        </tbody>
                    </table>
                </div>
            </div>

            <div class="modal-foot">
                <span class="modal-foot-info">
                    Tổng <b><asp:Literal ID="litModalTotalFoot" runat="server" Text="0" /></b> yêu cầu chờ
                </span>
                <asp:LinkButton ID="btnCloseModalFoot" runat="server" CssClass="btn-modal btn-modal-ghost"
                                OnClick="btnCloseModal_Click" CausesValidation="false">
                    Đóng
                </asp:LinkButton>
            </div>
        </div>
    </asp:Panel>

    <asp:HiddenField ID="hfEventId" runat="server" Value="0" />
    <asp:HiddenField ID="hfFilter" runat="server" Value="all" />
</asp:Content>

<asp:Content ID="cScripts" ContentPlaceHolderID="ScriptContent" runat="server">
</asp:Content>
