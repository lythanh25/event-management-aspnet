<%@ Page Title="Quản lý Sự kiện" Language="C#" MasterPageFile="~/AdminMaster.Master"
    AutoEventWireup="true" CodeBehind="EventsManagement.aspx.cs"
    Inherits="Eventhub.Admin.eventsmanagement" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Quản lý Sự kiện — EventHub Admin
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Content/EventsManagement.css") %>" rel="stylesheet" type="text/css" />
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <%-- ── PAGE HEAD ── --%>
    <div class="page-head">
        <div>
            <h1 class="page-title">Quản lý <em>Sự kiện</em></h1>
            <div class="page-sub">
                Tổng cộng <b><asp:Literal ID="litTotalCount" runat="server" Text="0" /> sự kiện</b>
                — Cập nhật lúc <asp:Literal ID="litUpdatedAt" runat="server" />
            </div>
        </div>
        <asp:HyperLink ID="lnkCreate" runat="server" CssClass="btn-create"
                       NavigateUrl="~/Admin/EventCreate.aspx">
            <svg viewBox="0 0 24 24" fill="none" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Tạo sự kiện mới
        </asp:HyperLink>
    </div>

    <%-- ── STAT TABS (filter nhanh theo status) ── --%>
       <div class="stat-tabs">
        <asp:HyperLink ID="tabAll" runat="server" CssClass="stat-tab active">
            <div class="stat-tab-icon amber">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="4" width="18" height="18" rx="2"/><path d="M16 2v4M8 2v4M3 10h18"/>
                </svg>
            </div>
            <div>
                <div class="stat-tab-num"><asp:Literal ID="litCntAll" runat="server" Text="0" /></div>
                <div class="stat-tab-label">Tất cả</div>
            </div>
        </asp:HyperLink>

        <asp:HyperLink ID="tabOpen" runat="server" CssClass="stat-tab">
            <div class="stat-tab-icon green-fill">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="20,6 9,17 4,12"/>
                </svg>
            </div>
            <div>
                <div class="stat-tab-num"><asp:Literal ID="litCntOpen" runat="server" Text="0" /></div>
                <div class="stat-tab-label">Mở đăng ký</div>
            </div>
        </asp:HyperLink>

        <asp:HyperLink ID="tabClosed" runat="server" CssClass="stat-tab">
            <div class="stat-tab-icon muted">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0110 0v4"/>
                </svg>
            </div>
            <div>
                <div class="stat-tab-num"><asp:Literal ID="litCntClosed" runat="server" Text="0" /></div>
                <div class="stat-tab-label">Đóng đăng ký</div>
            </div>
        </asp:HyperLink>

        <asp:HyperLink ID="tabEnded" runat="server" CssClass="stat-tab">
            <div class="stat-tab-icon green">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="3" width="18" height="18" rx="2"/><polyline points="9,12 11,14 15,10"/>
                </svg>
            </div>
            <div>
                <div class="stat-tab-num"><asp:Literal ID="litCntEnded" runat="server" Text="0" /></div>
                <div class="stat-tab-label">Đã kết thúc</div>
            </div>
        </asp:HyperLink>

        <asp:HyperLink ID="tabDraft" runat="server" CssClass="stat-tab">
            <div class="stat-tab-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/>
                    <polyline points="14,2 14,8 20,8"/>
                </svg>
            </div>
            <div>
                <div class="stat-tab-num"><asp:Literal ID="litCntDraft" runat="server" Text="0" /></div>
                <div class="stat-tab-label">Bản nháp</div>
            </div>
        </asp:HyperLink>
    </div>

    <%-- ── PANEL ── --%>
    <div class="panel">

        <%-- Filter bar --%>
        <div class="filter-bar">
            <div class="filter-search">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
                </svg>
                <asp:TextBox ID="txtKeyword" runat="server" placeholder="Tên sự kiện, mã ID, ban tổ chức..." />
            </div>

            <asp:DropDownList ID="ddlCategory" runat="server" CssClass="filter-select-ddl"
                              AutoPostBack="true" OnSelectedIndexChanged="Filter_Changed" />

            <asp:DropDownList ID="ddlMonth" runat="server" CssClass="filter-select-ddl"
                              AutoPostBack="true" OnSelectedIndexChanged="Filter_Changed">
                <asp:ListItem Value="" Text="Tháng: Tất cả" />
                <asp:ListItem Value="1"  Text="Tháng 1" />
                <asp:ListItem Value="2"  Text="Tháng 2" />
                <asp:ListItem Value="3"  Text="Tháng 3" />
                <asp:ListItem Value="4"  Text="Tháng 4" />
                <asp:ListItem Value="5"  Text="Tháng 5" />
                <asp:ListItem Value="6"  Text="Tháng 6" />
                <asp:ListItem Value="7"  Text="Tháng 7" />
                <asp:ListItem Value="8"  Text="Tháng 8" />
                <asp:ListItem Value="9"  Text="Tháng 9" />
                <asp:ListItem Value="10" Text="Tháng 10" />
                <asp:ListItem Value="11" Text="Tháng 11" />
                <asp:ListItem Value="12" Text="Tháng 12" />
            </asp:DropDownList>

            <asp:DropDownList ID="ddlDepartment" runat="server" CssClass="filter-select-ddl"
                              AutoPostBack="true" OnSelectedIndexChanged="Filter_Changed" />

            <asp:Button ID="btnSearch" runat="server" Text="Tìm" CssClass="btn-filter-search"
                        OnClick="btnSearch_Click" />
            <asp:LinkButton ID="btnClearFilter" runat="server" CssClass="filter-clear"
                            OnClick="btnClearFilter_Click" CausesValidation="false">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                </svg>
                Xoá lọc
            </asp:LinkButton>
        </div>

        <%-- TABLE --%>
        <div class="table-wrap">
            <table class="tbl">
                <thead>
                    <tr>
                        <th>Mã</th>
                        <th>Sự kiện</th>
                        <th>Chủ đề</th>
                        <th>Ngày tổ chức</th>
                        <th>Chỗ đăng ký</th>
                        <th>Ban tổ chức</th>
                        <th>Trạng thái</th>
                        <th style="text-align:right;">Thao tác</th>
                    </tr>
                </thead>
                <tbody>
                    <asp:Repeater ID="rptEvents" runat="server" OnItemCommand="rptEvents_ItemCommand">
                        <ItemTemplate>
                            <tr>
                                <td>
                                    <div class="event-code"><%# Eval("EventCode") %></div>
                                </td>
                                <td>
                                    <div class="event-cell">
                                        <div class='event-icon <%# Eval("IconClass") %>'>
                                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                <rect x="3" y="4" width="18" height="18" rx="2"/>
                                                <path d="M16 2v4M8 2v4M3 10h18"/>
                                            </svg>
                                        </div>
                                        <div>
                                            <div class="event-name"><%# Eval("Title") %></div>
                                            <div class="event-id"><%# Eval("Subtitle") %></div>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <span class='theme-tag <%# Eval("CategoryClass") %>'>
                                        <%# Eval("CategoryName") %>
                                    </span>
                                </td>
                                <td>
                                    <div class="date-cell">
                                        <%# Eval("StartAt", "{0:dd/MM/yyyy}") %>
                                        <small><%# Eval("StartAt", "{0:HH:mm}") %></small>
                                    </div>
                                </td>
                                <td>
                                    <div class="slots-cell">
                                        <div class="slots-num">
                                            <%# Eval("ApprovedCount") %>/<%# Eval("Capacity") %> chỗ
                                        </div>
                                        <div class="slots-bar">
                                            <div class='<%# Eval("SlotBarClass") %>'
                                                 style='width: <%# Eval("SlotPercent") %>%;'></div>
                                        </div>
                                    </div>
                                </td>
                                <td>
                                    <div class="org-text"><%# Eval("DepartmentName") %></div>
                                </td>
                                <td>
                                    <span class='status-pill <%# Eval("Status") %>'>
                                        <%# Eval("StatusText") %>
                                    </span>
                                </td>
                                <td>
                                    <div class="row-actions">
                                        <asp:HyperLink runat="server" CssClass="row-btn" ToolTip="Xem chi tiết"
                                                       NavigateUrl='<%# "~/Admin/Eventdetail.aspx?id=" + Eval("Id") %>'>
                                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                                                <circle cx="12" cy="12" r="3"/>
                                            </svg>
                                        </asp:HyperLink>

                                        <asp:HyperLink runat="server" CssClass="row-btn" ToolTip="Sửa"
                                                       NavigateUrl='<%# "~/Admin/EventCreate.aspx?id=" + Eval("Id") %>'>
                                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                <path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/>
                                                <path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/>
                                            </svg>
                                        </asp:HyperLink>

                                        <asp:LinkButton runat="server" CssClass="row-btn danger" ToolTip="Xoá"
                                                        CommandName="DeleteEvent"
                                                        CommandArgument='<%# Eval("Id") %>'
                                                        CausesValidation="false"
                                                        OnClientClick='<%# "return confirm(\"Bạn có chắc muốn xoá sự kiện \\\"" + Eval("Title") + "\\\"?\");" %>'>
                                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                <polyline points="3,6 5,6 21,6"/>
                                                <path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/>
                                                <path d="M10 11v6M14 11v6"/>
                                            </svg>
                                        </asp:LinkButton>
                                    </div>
                                </td>
                            </tr>
                        </ItemTemplate>
                    </asp:Repeater>
                </tbody>
            </table>

            <%-- Empty state --%>
            <asp:PlaceHolder ID="phEmpty" runat="server" Visible="false">
                <div class="empty-state">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2"/>
                        <path d="M16 2v4M8 2v4M3 10h18"/>
                    </svg>
                    <div class="empty-title">Không có sự kiện nào</div>
                    <div class="empty-sub">Thử xoá bộ lọc hoặc tạo sự kiện mới.</div>
                </div>
            </asp:PlaceHolder>
        </div>

        <%-- PAGINATION --%>
        <div class="pagination">
            <div>
                Hiển thị
                <b><asp:Literal ID="litFromTo" runat="server" Text="0–0" /></b>
                trong
                <b><asp:Literal ID="litTotal" runat="server" Text="0" /></b>
                sự kiện
            </div>

            <div class="pag-controls">
                <asp:LinkButton ID="btnPrev" runat="server" CssClass="pag-btn"
                                OnClick="btnPrev_Click" CausesValidation="false">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="15,18 9,12 15,6"/>
                    </svg>
                </asp:LinkButton>

                <asp:Repeater ID="rptPager" runat="server" OnItemCommand="rptPager_ItemCommand">
                    <ItemTemplate>
                        <asp:LinkButton runat="server"
                                        CssClass='<%# (bool)Eval("IsActive") ? "pag-btn active" : "pag-btn" %>'
                                        Text='<%# Eval("Page") %>'
                                        CommandName="GoPage"
                                        CommandArgument='<%# Eval("Page") %>'
                                        CausesValidation="false" />
                    </ItemTemplate>
                </asp:Repeater>

                <asp:LinkButton ID="btnNext" runat="server" CssClass="pag-btn"
                                OnClick="btnNext_Click" CausesValidation="false">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="9,18 15,12 9,6"/>
                    </svg>
                </asp:LinkButton>
            </div>

            <div class="page-size">
                <span>Hiển thị</span>
                <asp:DropDownList ID="ddlPageSize" runat="server" CssClass="page-size-input"
                                  AutoPostBack="true" OnSelectedIndexChanged="ddlPageSize_Changed">
                    <asp:ListItem Value="10" Selected="True" />
                    <asp:ListItem Value="20" />
                    <asp:ListItem Value="50" />
                </asp:DropDownList>
                <span>/ trang</span>
            </div>
        </div>
    </div>

    <%-- Hidden state --%>
    <asp:HiddenField ID="hfStatus"   runat="server" Value="" />
    <asp:HiddenField ID="hfPage"     runat="server" Value="1" />
</asp:Content>

<asp:Content ID="cScripts" ContentPlaceHolderID="ScriptContent" runat="server">
</asp:Content>