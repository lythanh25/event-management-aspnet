<%@ Page Title="Quản lý người dùng" Language="C#" MasterPageFile="~/AdminMaster.Master"
    AutoEventWireup="true" CodeBehind="UserManagement.aspx.cs"
    Inherits="Eventhub.Admin.UserManagement" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    Quản lý người dùng — EventHub Admin
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Content/UserManagement.css") %>" rel="stylesheet" type="text/css" />
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <%-- Alert --%>
    <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="alert">
        <asp:Literal ID="litAlert" runat="server" />
    </asp:Panel>

    <%-- ─── PAGE HEAD ─── --%>
    <div class="page-head">
        <div>
            <h1 class="page-title">Quản lý <em>Người dùng</em></h1>
            <div class="page-sub">
                Tổng cộng <b><asp:Literal ID="litTotalUsers" runat="server" Text="0" /> tài khoản</b>
                — Cập nhật lúc <asp:Literal ID="litUpdatedAt" runat="server" />
            </div>
        </div>
        <div class="head-btns">
            <asp:LinkButton ID="btnExport" runat="server" CssClass="btn" OnClick="btnExport_Click"
                            CausesValidation="false">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/>
                    <polyline points="7,10 12,15 17,10"/>
                    <line x1="12" y1="15" x2="12" y2="3"/>
                </svg>
                Xuất CSV
            </asp:LinkButton>
            <asp:LinkButton ID="btnOpenAdd" runat="server" CssClass="btn btn-primary"
                            OnClick="btnOpenAdd_Click" CausesValidation="false">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="12" y1="5" x2="12" y2="19"/>
                    <line x1="5" y1="12" x2="19" y2="12"/>
                </svg>
                Thêm người dùng
            </asp:LinkButton>
        </div>
    </div>

    <%-- ─── STAT TABS ─── --%>
    <div class="stat-tabs">
        <asp:HyperLink ID="tabAll" runat="server" CssClass="stat-tab active">
            <div class="stat-tab-icon all">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/>
                    <circle cx="9" cy="7" r="4"/>
                    <path d="M23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75"/>
                </svg>
            </div>
            <div>
                <div class="stat-tab-num"><asp:Literal ID="litCntAll" runat="server" Text="0" /></div>
                <div class="stat-tab-label">Tất cả</div>
                <div class="stat-tab-delta"><asp:Literal ID="litDeltaAll" runat="server" /></div>
            </div>
        </asp:HyperLink>

        <asp:HyperLink ID="tabActive" runat="server" CssClass="stat-tab">
            <div class="stat-tab-icon active-i">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M22 11.08V12a10 10 0 11-5.93-9.14"/>
                    <polyline points="22 4 12 14.01 9 11.01"/>
                </svg>
            </div>
            <div>
                <div class="stat-tab-num"><asp:Literal ID="litCntActive" runat="server" Text="0" /></div>
                <div class="stat-tab-label">Đang hoạt động</div>
                <div class="stat-tab-delta"><asp:Literal ID="litDeltaActive" runat="server" /></div>
            </div>
        </asp:HyperLink>

        <asp:HyperLink ID="tabNew" runat="server" CssClass="stat-tab">
            <div class="stat-tab-icon new">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M16 21v-2a4 4 0 00-4-4H6a4 4 0 00-4 4v2"/>
                    <circle cx="9" cy="7" r="4"/>
                    <line x1="19" y1="8" x2="19" y2="14"/>
                    <line x1="22" y1="11" x2="16" y2="11"/>
                </svg>
            </div>
            <div>
                <div class="stat-tab-num"><asp:Literal ID="litCntNew" runat="server" Text="0" /></div>
                <div class="stat-tab-label">Mới tháng này</div>
                <div class="stat-tab-delta"><asp:Literal ID="litDeltaNew" runat="server" /></div>
            </div>
        </asp:HyperLink>

        <asp:HyperLink ID="tabLocked" runat="server" CssClass="stat-tab">
            <div class="stat-tab-icon locked">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="11" width="18" height="11" rx="2"/>
                    <path d="M7 11V7a5 5 0 0110 0v4"/>
                </svg>
            </div>
            <div>
                <div class="stat-tab-num"><asp:Literal ID="litCntLocked" runat="server" Text="0" /></div>
                <div class="stat-tab-label">Bị khoá</div>
                <div class="stat-tab-delta"><asp:Literal ID="litDeltaLocked" runat="server" /></div>
            </div>
        </asp:HyperLink>

        <asp:HyperLink ID="tabAdmin" runat="server" CssClass="stat-tab">
            <div class="stat-tab-icon admin">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>
                </svg>
            </div>
            <div>
                <div class="stat-tab-num"><asp:Literal ID="litCntAdmin" runat="server" Text="0" /></div>
                <div class="stat-tab-label">Quản trị viên</div>
                <div class="stat-tab-delta"><asp:Literal ID="litDeltaAdmin" runat="server" /></div>
            </div>
        </asp:HyperLink>
    </div>

    <%-- ─── PANEL ─── --%>
    <div class="panel">

        <%-- FILTER BAR --%>
        <div class="filter-bar">
            <div class="filter-search">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="11" cy="11" r="8"/>
                    <line x1="21" y1="21" x2="16.65" y2="16.65"/>
                </svg>
                <asp:TextBox ID="txtSearch" runat="server" placeholder="Tìm tên, email, mã nhân viên..." />
            </div>

            <asp:DropDownList ID="ddlDepartment" runat="server" CssClass="filter-chip-ddl"
                              AutoPostBack="true" OnSelectedIndexChanged="Filter_Changed" />
            <asp:DropDownList ID="ddlRole" runat="server" CssClass="filter-chip-ddl"
                              AutoPostBack="true" OnSelectedIndexChanged="Filter_Changed" />

            <asp:LinkButton ID="btnSearch" runat="server" CssClass="btn-find"
                            OnClick="btnSearch_Click" CausesValidation="false">
                Tìm
            </asp:LinkButton>
            <asp:LinkButton ID="btnClearFilter" runat="server" CssClass="btn-clear"
                            OnClick="btnClearFilter_Click" CausesValidation="false">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="18" y1="6" x2="6" y2="18"/>
                    <line x1="6" y1="6" x2="18" y2="18"/>
                </svg>
                Xoá lọc
            </asp:LinkButton>
        </div>

        <%-- TABLE --%>
        <div class="table-wrap">
            <table class="tbl">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Người dùng</th>
                        <th>Email</th>
                        <th>Phòng ban</th>
                        <th>Vai trò</th>
                        <th>Trạng thái</th>
                        <th>Sự kiện</th>
                        <th>Đăng nhập gần nhất</th>
                        <th>Ngày tạo</th>
                        <th style="text-align: right;">Thao tác</th>
                    </tr>
                </thead>
                <tbody>
                    <asp:Repeater ID="rptUsers" runat="server" OnItemCommand="rptUsers_ItemCommand">
                        <ItemTemplate>
                            <tr>
                                <td><span class="row-num"><%# Eval("RowNum") %></span></td>
                                <td>
                                    <div class="user-cell">
                                        <div class='<%# "avatar av-" + Eval("ColorIndex") %>'>
                                            <%# Eval("Initial") %>
                                            <div class='<%# "status-dot " + Eval("StatusDotClass") %>'></div>
                                        </div>
                                        <div>
                                            <div class="user-name"><%# Eval("FullName") %></div>
                                            <div class="user-id">
                                                USR-<%# string.Format("{0:0000}", Eval("Id")) %><%# !string.IsNullOrEmpty((string)Eval("EmployeeCode")) ? " · " + Eval("EmployeeCode") : "" %>
                                            </div>
                                        </div>
                                    </div>
                                </td>
                                <td class="email-cell"><%# Eval("Email") %></td>
                                <td>
                                    <span class="dept-cell">
                                        <span class='<%# "dept-dot d" + Eval("DeptDotIndex") %>'></span>
                                        <%# Eval("DepartmentName") %>
                                    </span>
                                </td>
                                <td><span class='<%# "role-badge " + Eval("RoleCode") %>'><%# Eval("RoleName") %></span></td>
                                <td><span class='<%# "status-pill " + Eval("StatusClass") %>'><%# Eval("StatusText") %></span></td>
                                <td><span class="events-count"><%# Eval("EventsJoined") %> <small>sự kiện</small></span></td>
                                <td>
                                    <div class="login-cell">
                                        <%# Eval("LastLoginText") %>
                                        <small><%# Eval("LastLoginSub") %></small>
                                    </div>
                                </td>
                                <td>
                                    <div class="login-cell">
                                        <%# Eval("CreatedAt", "{0:dd/MM/yyyy}") %>
                                    </div>
                                </td>
                                <td>
                                    <div class="row-actions">
                                        <asp:LinkButton runat="server" CssClass="row-btn" ToolTip="Chỉnh sửa"
                                                        CommandName="Edit" CommandArgument='<%# Eval("Id") %>'
                                                        CausesValidation="false">
                                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                <path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/>
                                                <path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/>
                                            </svg>
                                        </asp:LinkButton>
                                        <asp:LinkButton runat="server" CssClass='<%# (bool)Eval("IsActive") ? "row-btn danger" : "row-btn success" %>'
                                                        ToolTip='<%# (bool)Eval("IsActive") ? "Khoá tài khoản" : "Kích hoạt lại" %>'
                                                        CommandName="ToggleLock" CommandArgument='<%# Eval("Id") %>'
                                                        CausesValidation="false"
                                                        OnClientClick='<%# (bool)Eval("IsActive") ? "return confirm(\"Khoá tài khoản này?\");" : "return confirm(\"Kích hoạt lại tài khoản này?\");" %>'>
                                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                <rect x="3" y="11" width="18" height="11" rx="2"/>
                                                <path d="M7 11V7a5 5 0 0110 0v4"/>
                                            </svg>
                                        </asp:LinkButton>
                                        <asp:LinkButton runat="server" CssClass="row-btn danger" ToolTip="Xoá"
                                                        CommandName="Delete" CommandArgument='<%# Eval("Id") %>'
                                                        CausesValidation="false"
                                                        OnClientClick="return confirm('Xoá vĩnh viễn tài khoản này? Lưu ý: không thể hoàn tác.');">
                                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                                <polyline points="3 6 5 6 21 6"/>
                                                <path d="M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/>
                                            </svg>
                                        </asp:LinkButton>
                                    </div>
                                </td>
                            </tr>
                        </ItemTemplate>
                    </asp:Repeater>

                    <asp:PlaceHolder ID="phEmpty" runat="server" Visible="false">
                        <tr>
                            <td colspan="10" class="empty-cell">
                                Không tìm thấy người dùng nào phù hợp.
                            </td>
                        </tr>
                    </asp:PlaceHolder>
                </tbody>
            </table>
        </div>

        <%-- PAGINATION --%>
        <div class="pagination">
            <div class="pag-info">
                Hiển thị <b><asp:Literal ID="litPageFrom" runat="server" Text="0" /> – <asp:Literal ID="litPageTo" runat="server" Text="0" /></b>
                trong tổng số <b><asp:Literal ID="litPageTotal" runat="server" Text="0" /></b> người dùng
            </div>
            <div class="pag-controls">
                <asp:LinkButton ID="btnPrev" runat="server" CssClass="pag-btn" OnClick="btnPrev_Click"
                                CausesValidation="false">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="15,18 9,12 15,6"/>
                    </svg>
                </asp:LinkButton>
                <asp:Repeater ID="rptPager" runat="server" OnItemCommand="rptPager_ItemCommand">
                    <ItemTemplate>
                        <asp:LinkButton runat="server"
                                        CssClass='<%# (bool)Eval("IsCurrent") ? "pag-btn active" : "pag-btn" %>'
                                        CommandName="GoPage" CommandArgument='<%# Eval("PageNum") %>'
                                        CausesValidation="false"
                                        Enabled='<%# !(bool)Eval("IsCurrent") %>'>
                            <%# Eval("PageNum") %>
                        </asp:LinkButton>
                    </ItemTemplate>
                </asp:Repeater>
                <asp:LinkButton ID="btnNext" runat="server" CssClass="pag-btn" OnClick="btnNext_Click"
                                CausesValidation="false">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="9,18 15,12 9,6"/>
                    </svg>
                </asp:LinkButton>
            </div>
            <asp:DropDownList ID="ddlPageSize" runat="server" CssClass="pag-size"
                              AutoPostBack="true" OnSelectedIndexChanged="ddlPageSize_Changed">
                <asp:ListItem Text="10 / trang" Value="10" Selected="True" />
                <asp:ListItem Text="20 / trang" Value="20" />
                <asp:ListItem Text="50 / trang" Value="50" />
                <asp:ListItem Text="100 / trang" Value="100" />
            </asp:DropDownList>
        </div>
    </div>

    <%-- ═════════ MODAL: ADD/EDIT USER ═════════ --%>
    <asp:Panel ID="pnlModal" runat="server" CssClass="modal-overlay" Visible="false">
        <div class="modal-box">
            <div class="modal-head">
                <div>
                    <div class="modal-title"><asp:Literal ID="litModalTitle" runat="server" /></div>
                    <div class="modal-sub"><asp:Literal ID="litModalSub" runat="server" /></div>
                </div>
                <asp:LinkButton ID="btnCloseModal" runat="server" CssClass="modal-close"
                                OnClick="btnCloseModal_Click" CausesValidation="false">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                    </svg>
                </asp:LinkButton>
            </div>

            <div class="modal-body">
                <div class="m-row">
                    <div class="m-field">
                        <label class="m-label">Họ <span class="req">*</span></label>
                        <asp:TextBox ID="txtMFirstName" runat="server" CssClass="m-input" MaxLength="60" />
                    </div>
                    <div class="m-field">
                        <label class="m-label">Tên <span class="req">*</span></label>
                        <asp:TextBox ID="txtMLastName" runat="server" CssClass="m-input" MaxLength="60" />
                    </div>
                </div>

                <div class="m-row">
                    <div class="m-field">
                        <label class="m-label">Email công ty <span class="req">*</span></label>
                        <asp:TextBox ID="txtMEmail" runat="server" CssClass="m-input" MaxLength="190" />
                    </div>
                    <div class="m-field">
                        <label class="m-label">Mã nhân viên</label>
                        <asp:TextBox ID="txtMEmpCode" runat="server" CssClass="m-input mono" MaxLength="20" />
                    </div>
                </div>

                <div class="m-row">
                    <div class="m-field">
                        <label class="m-label">Số điện thoại</label>
                        <asp:TextBox ID="txtMPhone" runat="server" CssClass="m-input" MaxLength="20" />
                    </div>
                    <div class="m-field">
                        <label class="m-label">Chức danh</label>
                        <asp:TextBox ID="txtMJobTitle" runat="server" CssClass="m-input" MaxLength="120" />
                    </div>
                </div>

                <div class="m-row">
                    <div class="m-field">
                        <label class="m-label">Phòng ban</label>
                        <asp:DropDownList ID="ddlMDepartment" runat="server" CssClass="m-select" />
                    </div>
                    <div class="m-field">
                        <label class="m-label">Vai trò <span class="req">*</span></label>
                        <asp:DropDownList ID="ddlMRole" runat="server" CssClass="m-select" />
                    </div>
                </div>

                <asp:Panel ID="pnlMPassword" runat="server" CssClass="m-field">
                    <label class="m-label">Mật khẩu khởi tạo <span class="req">*</span></label>
                    <asp:TextBox ID="txtMPassword" runat="server" CssClass="m-input" TextMode="Password"
                                 placeholder="Tối thiểu 8 ký tự, có chữ HOA, số, ký tự đặc biệt" />
                </asp:Panel>

                <div class="m-field">
                    <asp:CheckBox ID="cbMIsActive" runat="server" Text=" Kích hoạt tài khoản ngay"
                                  Checked="true" CssClass="m-cb" />
                </div>
            </div>

            <div class="modal-foot">
                <asp:LinkButton ID="btnCancelModal" runat="server" CssClass="btn"
                                OnClick="btnCloseModal_Click" CausesValidation="false">
                    Huỷ
                </asp:LinkButton>
                <asp:Button ID="btnSaveUser" runat="server" CssClass="btn btn-primary"
                            Text="Lưu" OnClick="btnSaveUser_Click" />
            </div>
        </div>
    </asp:Panel>

    <%-- Hidden state --%>
    <asp:HiddenField ID="hfEditId" runat="server" Value="0" />
    <asp:HiddenField ID="hfStatusFilter" runat="server" Value="all" />
    <asp:HiddenField ID="hfPage" runat="server" Value="1" />
</asp:Content>

<asp:Content ID="cScripts" ContentPlaceHolderID="ScriptContent" runat="server">
</asp:Content>
