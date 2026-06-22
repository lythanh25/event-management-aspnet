<%@ Page Title="Xét duyệt người đăng ký" Language="C#" MasterPageFile="~/AdminMaster.Master"
    AutoEventWireup="true" CodeBehind="RegistrationDetail.aspx.cs"
    Inherits="Eventhub.Admin.registrationdetail" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <asp:Literal ID="litPageTitle" runat="server" Text="Xét duyệt người đăng ký — EventHub Admin" />
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Content/RegistrationDetail.css") %>" rel="stylesheet" type="text/css" />
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <%-- Alert --%>
    <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="alert">
        <asp:Literal ID="litAlert" runat="server" />
    </asp:Panel>

    <%-- ═════════ EVENT HEADER ═════════ --%>
    <div class="event-head">
        <div class="event-head-left">
            <asp:HyperLink ID="lnkBack" runat="server" CssClass="back-link"
                           NavigateUrl="~/Admin/Approval.aspx">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="19" y1="12" x2="5" y2="12"/><polyline points="12,19 5,12 12,5"/>
                </svg>
                Quay lại trang xét duyệt
            </asp:HyperLink>
            <h1 class="page-title">Xét duyệt <em>người đăng ký</em></h1>
            <div class="event-meta">
                <div>
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M20.59 13.41l-7.17 7.17a2 2 0 01-2.83 0L2 12V2h10l8.59 8.59a2 2 0 010 2.82z"/>
                        <line x1="7" y1="7" x2="7.01" y2="7"/>
                    </svg>
                    <b><asp:Literal ID="litEventTitle" runat="server" /></b>
                </div>
                <span class="event-meta-divider"></span>
                <div>
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2"/>
                        <line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/>
                        <line x1="3" y1="10" x2="21" y2="10"/>
                    </svg>
                    <asp:Literal ID="litEventDate" runat="server" />
                </div>
                <span class="event-meta-divider"></span>
                <div>
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/>
                    </svg>
                    <asp:Literal ID="litEventTime" runat="server" />
                </div>
                <span class="event-meta-divider"></span>
                <div>
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/>
                        <circle cx="12" cy="10" r="3"/>
                    </svg>
                    <asp:Literal ID="litEventLocation" runat="server" />
                </div>
                <span runat="server" id="spanStatus" class="meta-pill">
                    <asp:Literal ID="litEventStatus" runat="server" />
                </span>
            </div>
        </div>
        <div class="head-actions">
            <asp:HyperLink ID="lnkEventDetail" runat="server" CssClass="btn btn-ghost">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/>
                </svg>
                Xem chi tiết sự kiện
            </asp:HyperLink>
            <asp:LinkButton ID="btnApproveAll" runat="server" CssClass="btn btn-primary"
                            OnClick="btnApproveAll_Click" CausesValidation="false"
                            OnClientClick="return confirm('Bạn có chắc muốn duyệt TẤT CẢ yêu cầu chờ?');">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="20,6 9,17 4,12"/>
                </svg>
                Duyệt tất cả pending
            </asp:LinkButton>
        </div>
    </div>

    <%-- ═════════ STATS ═════════ --%>
    <div class="stats">
        <div class="stat">
            <div class="stat-head">
                <div class="stat-icon dark">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/>
                        <circle cx="9" cy="7" r="4"/>
                    </svg>
                </div>
                Tổng đăng ký
            </div>
            <div class="stat-value">
                <asp:Literal ID="litTotal" runat="server" Text="0" />
                <small>/ <asp:Literal ID="litCapacity" runat="server" Text="0" /></small>
            </div>
            <div class="stat-progress">
                <div id="divProgress" runat="server"></div>
            </div>
        </div>

        <div class="stat">
            <div class="stat-head">
                <div class="stat-icon amber">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/>
                    </svg>
                </div>
                Chờ duyệt
            </div>
            <div class="stat-value"><asp:Literal ID="litPending" runat="server" Text="0" /></div>
            <div class="stat-trend"><asp:Literal ID="litPendingTrend" runat="server" /></div>
        </div>

        <div class="stat">
            <div class="stat-head">
                <div class="stat-icon green">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20,6 9,17 4,12"/>
                    </svg>
                </div>
                Đã duyệt
            </div>
            <div class="stat-value"><asp:Literal ID="litApproved" runat="server" Text="0" /></div>
            <div class="stat-trend green"><asp:Literal ID="litApprovedRate" runat="server" /></div>
        </div>

        <div class="stat">
            <div class="stat-head">
                <div class="stat-icon red">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/>
                        <line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/>
                    </svg>
                </div>
                Đã từ chối
            </div>
            <div class="stat-value"><asp:Literal ID="litRejected" runat="server" Text="0" /></div>
            <div class="stat-trend"><asp:Literal ID="litRejectedRate" runat="server" /></div>
        </div>

        <div class="stat">
            <div class="stat-head">
                <div class="stat-icon blue">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="10" y1="6" x2="21" y2="6"/><line x1="10" y1="12" x2="21" y2="12"/>
                        <line x1="10" y1="18" x2="21" y2="18"/>
                        <path d="M4 6h1v4M4 10h2M6 18H4c0-1 2-2 2-3s-1-1.5-2-1"/>
                    </svg>
                </div>
                Danh sách chờ
            </div>
            <div class="stat-value"><asp:Literal ID="litWaitlist" runat="server" Text="0" /></div>
            <div class="stat-trend">Sẽ duyệt khi có chỗ</div>
        </div>
    </div>

    <%-- ═════════ PANEL ═════════ --%>
    <div class="panel">

        <%-- TABS --%>
        <div class="tabs">
            <asp:HyperLink ID="tabAll"      runat="server" CssClass="tab">
                Tất cả <span class="tab-count"><asp:Literal ID="litCntAll" runat="server" Text="0" /></span>
            </asp:HyperLink>
            <asp:HyperLink ID="tabPending"  runat="server" CssClass="tab amber">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/>
                </svg>
                Chờ duyệt <span class="tab-count"><asp:Literal ID="litCntPending" runat="server" Text="0" /></span>
            </asp:HyperLink>
            <asp:HyperLink ID="tabApproved" runat="server" CssClass="tab green">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="20,6 9,17 4,12"/>
                </svg>
                Đã duyệt <span class="tab-count"><asp:Literal ID="litCntApproved" runat="server" Text="0" /></span>
            </asp:HyperLink>
            <asp:HyperLink ID="tabRejected" runat="server" CssClass="tab red">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                </svg>
                Đã từ chối <span class="tab-count"><asp:Literal ID="litCntRejected" runat="server" Text="0" /></span>
            </asp:HyperLink>
            <asp:HyperLink ID="tabWaitlist" runat="server" CssClass="tab">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="10" y1="6" x2="21" y2="6"/><line x1="10" y1="12" x2="21" y2="12"/>
                    <line x1="10" y1="18" x2="21" y2="18"/>
                </svg>
                Danh sách chờ <span class="tab-count"><asp:Literal ID="litCntWaitlist" runat="server" Text="0" /></span>
            </asp:HyperLink>
        </div>

        <%-- TOOLBAR --%>
        <div class="toolbar">
            <div class="search-inline">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
                </svg>
                <asp:TextBox ID="txtSearch" runat="server"
                             placeholder="Tìm theo tên, email hoặc mã NV..."
                             AutoPostBack="true" OnTextChanged="txtSearch_TextChanged" />
            </div>
            <asp:DropDownList ID="ddlDepartment" runat="server" CssClass="filter-chip-ddl"
                              AutoPostBack="true" OnSelectedIndexChanged="ddlDepartment_Changed" />
            <asp:DropDownList ID="ddlSort" runat="server" CssClass="filter-chip-ddl"
                              AutoPostBack="true" OnSelectedIndexChanged="ddlSort_Changed">
                <asp:ListItem Value="newest" Text="Mới nhất trước" Selected="True" />
                <asp:ListItem Value="oldest" Text="Cũ nhất trước" />
                <asp:ListItem Value="name"   Text="Tên A → Z" />
            </asp:DropDownList>
        </div>

        <%-- TABLE --%>
        <div class="table-wrap">
            <table class="tbl">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Người đăng ký</th>
                        <th>Phòng ban</th>
                        <th>Thời gian đăng ký</th>
                        <th>Mã NV</th>
                        <th>Mã vé</th>
                        <th>Trạng thái</th>
                        <th style="text-align: right;">Thao tác</th>
                    </tr>
                </thead>
                <tbody>
                    <asp:Repeater ID="rptList" runat="server" OnItemCommand="rptList_ItemCommand">
                        <ItemTemplate>
                            <tr>
                                <td><span class="row-num"><%# Container.ItemIndex + 1 %></span></td>
                                <td>
                                    <div class="user-cell">
                                        <div class='<%# "user-avatar av-" + Eval("ColorIndex") %>'>
                                            <%# Eval("Initial") %>
                                        </div>
                                        <div>
                                            <div class="user-name"><%# Eval("FullName") %></div>
                                            <div class="user-email"><%# Eval("Email") %></div>
                                        </div>
                                    </div>
                                </td>
                                <td><span class="dept-tag"><%# Eval("Department") %></span></td>
                                <td>
                                    <div class="date-cell">
                                        <%# Eval("RegisteredAt", "{0:dd/MM/yyyy}") %>
                                        <small><%# Eval("RegisteredAt", "{0:HH:mm}") %> — <%# Eval("TimeAgo") %></small>
                                    </div>
                                </td>
                                <td><span class="emp-id"><%# Eval("EmpId") %></span></td>
                                <td><span class="ticket-code"><%# Eval("TicketCode") %></span></td>
                                <td>
                                    <span class='<%# "status-pill " + Eval("Status") %>'>
                                        <%# Eval("StatusText") %>
                                    </span>
                                </td>
                                <td>
                                    <div class="row-actions">
                                        <asp:LinkButton runat="server" CssClass="row-btn approve"
                                                        CommandName="Approve"
                                                        CommandArgument='<%# Eval("Id") %>'
                                                        Visible='<%# (string)Eval("Status") == "pending" || (string)Eval("Status") == "waitlist" %>'
                                                        CausesValidation="false">
                                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                                                <polyline points="20,6 9,17 4,12"/>
                                            </svg>
                                            Duyệt
                                        </asp:LinkButton>

                                        <asp:LinkButton runat="server" CssClass="row-btn reject"
                                                        CommandName="Reject"
                                                        CommandArgument='<%# Eval("Id") %>'
                                                        Visible='<%# (string)Eval("Status") == "pending" || (string)Eval("Status") == "approved" %>'
                                                        CausesValidation="false">
                                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                                            </svg>
                                            Từ chối
                                        </asp:LinkButton>

                                        <asp:LinkButton runat="server" CssClass="row-btn"
                                                        CommandName="Reset"
                                                        CommandArgument='<%# Eval("Id") %>'
                                                        Visible='<%# (string)Eval("Status") == "rejected" %>'
                                                        CausesValidation="false">
                                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                <polyline points="1,4 1,10 7,10"/>
                                                <path d="M3.51 15a9 9 0 102.13-9.36L1 10"/>
                                            </svg>
                                            Hoàn tác
                                        </asp:LinkButton>
                                    </div>
                                </td>
                            </tr>
                        </ItemTemplate>
                    </asp:Repeater>

                    <asp:PlaceHolder ID="phEmpty" runat="server" Visible="false">
                        <tr>
                            <td colspan="8" class="empty-cell">
                                <svg viewBox="0 0 24 24" fill="none" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                                    <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/>
                                    <circle cx="9" cy="7" r="4"/>
                                </svg>
                                <div>Không có người đăng ký nào phù hợp.</div>
                            </td>
                        </tr>
                    </asp:PlaceHolder>
                </tbody>
            </table>
        </div>

        <%-- FOOTER --%>
        <div class="table-foot">
            <span>
                Hiển thị <b><asp:Literal ID="litShownCount" runat="server" Text="0" /></b>
                trên tổng <b><asp:Literal ID="litTotalCount" runat="server" Text="0" /></b> người đăng ký
            </span>
        </div>
    </div>

    <asp:HiddenField ID="hfStatusFilter" runat="server" Value="all" />
</asp:Content>

<asp:Content ID="cScripts" ContentPlaceHolderID="ScriptContent" runat="server">
</asp:Content>
