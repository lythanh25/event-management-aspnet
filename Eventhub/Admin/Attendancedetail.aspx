<%@ Page Title="Điểm danh sự kiện" Language="C#" MasterPageFile="~/AdminMaster.Master"
    AutoEventWireup="true" CodeBehind="AttendanceDetail.aspx.cs"
    Inherits="Eventhub.Admin.Attendancedetail" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <asp:Literal ID="litPageTitle" runat="server" Text="Điểm danh — EventHub Admin" />
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Content/AttendanceDetail.css") %>" rel="stylesheet" type="text/css" />
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <%-- Alert --%>
    <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="alert">
        <asp:Literal ID="litAlert" runat="server" />
    </asp:Panel>

    <%-- Back link --%>
    <div class="back-row">
        <asp:HyperLink ID="lnkBack" runat="server" CssClass="back-link"
                       NavigateUrl="~/Admin/AttendanceHub.aspx">
            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <line x1="19" y1="12" x2="5" y2="12"/><polyline points="12,19 5,12 12,5"/>
            </svg>
            Quay lại Hub điểm danh
        </asp:HyperLink>
    </div>

    <%-- ═════════ LIVE BANNER ═════════ --%>
    <div class="live-banner">
        <div class="live-banner-left">
            <span runat="server" id="spanLivePill" class="live-pill">
                <asp:Literal ID="litLivePill" runat="server" Text="SỰ KIỆN" />
            </span>
            <h2 class="live-title">
                Điểm danh — <em><asp:Literal ID="litEventTitle" runat="server" /></em>
            </h2>
            <div class="live-meta">
                <div>
                    <strong><asp:Literal ID="litEventDate" runat="server" /></strong>
                </div>
                <span class="live-meta-divider">·</span>
                <div>Bắt đầu lúc <strong><asp:Literal ID="litEventStart" runat="server" /></strong></div>
                <span class="live-meta-divider">·</span>
                <div><asp:Literal ID="litEventLocation" runat="server" /></div>
                <span class="live-meta-divider">·</span>
                <div>Phụ trách: <strong><asp:Literal ID="litOrganizer" runat="server" /></strong></div>
            </div>
        </div>

        <div class="live-banner-right">
            <div class="live-ring-num">
                <asp:Literal ID="litRingPresent" runat="server" Text="0" />
                <small>/ <asp:Literal ID="litRingTotal" runat="server" Text="0" /></small>
            </div>
            <div class="live-ring-lbl">ĐÃ CÓ MẶT</div>
        </div>
    </div>

    <%-- ═════════ STATS ═════════ --%>
    <div class="stats">
        <div class="stat">
            <div class="stat-icon dark">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/>
                    <circle cx="9" cy="7" r="4"/>
                </svg>
            </div>
            <div class="stat-body">
                <div class="stat-label">Đã được duyệt</div>
                <div class="stat-value"><asp:Literal ID="litStatApproved" runat="server" Text="0" /></div>
                <div class="stat-sub">Tổng người dự kiến</div>
            </div>
        </div>

        <div class="stat">
            <div class="stat-icon green">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="20,6 9,17 4,12"/>
                </svg>
            </div>
            <div class="stat-body">
                <div class="stat-label">Đã có mặt</div>
                <div class="stat-value"><asp:Literal ID="litStatPresent" runat="server" Text="0" /> <small>người</small></div>
                <div class="stat-progress">
                    <div class="green" id="divPresentBar" runat="server"></div>
                </div>
            </div>
        </div>

        <div class="stat">
            <div class="stat-icon amber">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/>
                    <line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/>
                </svg>
            </div>
            <div class="stat-body">
                <div class="stat-label">Chưa đến</div>
                <div class="stat-value"><asp:Literal ID="litStatAbsent" runat="server" Text="0" /> <small>người</small></div>
                <div class="stat-progress">
                    <div class="amber" id="divAbsentBar" runat="server"></div>
                </div>
            </div>
        </div>

        <div class="stat">
            <div class="stat-icon red">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="13" r="8"/><path d="M12 9v4l2 2"/>
                </svg>
            </div>
            <div class="stat-body">
                <div class="stat-label">Đến muộn</div>
                <div class="stat-value"><asp:Literal ID="litStatLate" runat="server" Text="0" /> <small>người</small></div>
                <div class="stat-sub">Sau giờ bắt đầu</div>
            </div>
        </div>
    </div>

    <%-- ═════════ QUICK BAR ═════════ --%>
    <div class="quickbar">
        <div class="quick-search-card">
            <div class="qs-row">
                <div class="qs-icon">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <polygon points="13,2 3,14 12,14 11,22 21,10 12,10 13,2"/>
                    </svg>
                </div>
                <div class="qs-content">
                    <div class="qs-title">Điểm danh <em>nhanh</em></div>
                    <div class="qs-sub">Gõ tên / mã NV / email rồi bấm Enter để tự động đánh dấu có mặt</div>
                </div>
            </div>
            <div class="qs-input-wrap">
                <asp:TextBox ID="txtQuick" runat="server" placeholder="Tên hoặc mã EMP-..."
                             AutoPostBack="true" OnTextChanged="txtQuick_TextChanged" />
                <kbd>Enter</kbd>
            </div>
        </div>

        <div class="qr-card">
            <div class="qr-icon-wrap">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/>
                    <rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/>
                </svg>
            </div>
            <div class="qr-content">
                <div class="qr-title">Quét mã QR</div>
                <div class="qr-sub">Mở camera, quét vé sự kiện</div>
            </div>
        </div>
    </div>

    <%-- ═════════ GRID ═════════ --%>
    <div class="grid">

        <%-- ─── LEFT: LIST ─── --%>
        <div class="panel">
            <%-- Tabs --%>
            <div class="tabs">
                <asp:HyperLink ID="tabAll" runat="server" CssClass="tab">
                    Tất cả <span class="tab-count"><asp:Literal ID="litCntAll" runat="server" Text="0" /></span>
                </asp:HyperLink>
                <asp:HyperLink ID="tabPresent" runat="server" CssClass="tab green">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="20,6 9,17 4,12"/>
                    </svg>
                    Đã có mặt <span class="tab-count"><asp:Literal ID="litCntPresent" runat="server" Text="0" /></span>
                </asp:HyperLink>
                <asp:HyperLink ID="tabAbsent" runat="server" CssClass="tab amber">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/>
                    </svg>
                    Chưa đến <span class="tab-count"><asp:Literal ID="litCntAbsent" runat="server" Text="0" /></span>
                </asp:HyperLink>
                <asp:HyperLink ID="tabLate" runat="server" CssClass="tab">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="12" cy="13" r="8"/><path d="M12 9v4l2 2"/>
                    </svg>
                    Đến muộn <span class="tab-count"><asp:Literal ID="litCntLate" runat="server" Text="0" /></span>
                </asp:HyperLink>
            </div>

            <%-- Toolbar --%>
            <div class="toolbar">
                <div class="search-inline">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>
                    </svg>
                    <asp:TextBox ID="txtSearch" runat="server" placeholder="Tìm trong danh sách..."
                                 AutoPostBack="true" OnTextChanged="txtSearch_TextChanged" />
                </div>
                <asp:DropDownList ID="ddlDepartment" runat="server" CssClass="filter-chip-ddl"
                                  AutoPostBack="true" OnSelectedIndexChanged="ddlDepartment_Changed" />
                <asp:DropDownList ID="ddlSort" runat="server" CssClass="filter-chip-ddl"
                                  AutoPostBack="true" OnSelectedIndexChanged="ddlSort_Changed">
                    <asp:ListItem Value="name"      Text="Sắp xếp: A → Z" Selected="True" />
                    <asp:ListItem Value="checkin"   Text="Theo giờ check-in" />
                    <asp:ListItem Value="dept"      Text="Theo phòng ban" />
                </asp:DropDownList>
            </div>

            <%-- Attendance list --%>
            <div class="attlist">
                <asp:Repeater ID="rptList" runat="server" OnItemCommand="rptList_ItemCommand">
                    <ItemTemplate>
                        <div class='<%# Eval("RowClass") %>'>
                            <div class="att-num"><%# (Container.ItemIndex + 1).ToString("000") %></div>
                            <div class="att-user">
                                <div class='<%# "att-avatar av-" + Eval("ColorIndex") %>'>
                                    <%# Eval("Initial") %>
                                    <div class="check-dot">
                                        <svg viewBox="0 0 24 24" fill="none" stroke-width="3" stroke-linecap="round" stroke-linejoin="round">
                                            <polyline points="20,6 9,17 4,12"/>
                                        </svg>
                                    </div>
                                </div>
                                <div>
                                    <div class="att-name"><%# Eval("FullName") %></div>
                                    <div class="att-info">
                                        <span class="dept-tag"><%# Eval("Department") %></span>
                                        <span class="mono"><%# Eval("EmpId") %></span>
                                    </div>
                                </div>
                            </div>
                            <div class="att-time">
                                <span class='<%# Eval("TimePillClass") %>'><%# Eval("TimeText") %></span>
                            </div>
                            <asp:LinkButton runat="server" CssClass='<%# (string)Eval("Status") == "present" || (string)Eval("Status") == "late" ? "toggle on" : "toggle" %>'
                                            CommandName="Toggle"
                                            CommandArgument='<%# Eval("RegistrationId") + "|" + Eval("UserId") %>'
                                            CausesValidation="false"
                                            ToolTip='<%# (string)Eval("Status") == "present" || (string)Eval("Status") == "late" ? "Bấm để bỏ điểm danh" : "Bấm để điểm danh" %>'>
                            </asp:LinkButton>
                        </div>
                    </ItemTemplate>
                </asp:Repeater>

                <asp:Panel ID="pnlEmpty" runat="server" Visible="false" CssClass="att-empty">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/>
                        <circle cx="9" cy="7" r="4"/>
                    </svg>
                    <div class="att-empty-title">Không có người đăng ký nào phù hợp</div>
                    <div class="att-empty-sub">Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm</div>
                </asp:Panel>
            </div>
        </div>

        <%-- ─── RIGHT: ACTIVITY FEED + DEPT ─── --%>
        <aside class="side">

            <%-- Activity feed --%>
            <div class="feed-card">
                <div class="feed-card-head">
                    <div class="feed-card-title">Hoạt động <em>gần nhất</em></div>
                    <span class="feed-card-tag">LIVE</span>
                </div>
                <div class="feed-list">
                    <asp:Repeater ID="rptFeed" runat="server">
                        <ItemTemplate>
                            <div class="feed-item">
                                <div class='<%# "feed-avatar av-" + Eval("ColorIndex") %>'>
                                    <%# Eval("Initial") %>
                                </div>
                                <div class="feed-content">
                                    <div class="feed-name"><%# Eval("FullName") %></div>
                                    <div class="feed-meta">
                                        <%# Eval("Department") %> · <%# Eval("TimeAgo") %>
                                    </div>
                                </div>
                                <span class="feed-time"><%# Eval("CheckedInAt", "{0:HH:mm}") %></span>
                            </div>
                        </ItemTemplate>
                    </asp:Repeater>

                    <asp:PlaceHolder ID="phFeedEmpty" runat="server" Visible="false">
                        <div class="feed-empty">Chưa có ai check-in</div>
                    </asp:PlaceHolder>
                </div>
            </div>

            <%-- Dept progress --%>
            <div class="dept-card">
                <div class="dept-card-title">Theo phòng ban</div>
                <div class="dept-card-sub">Tỉ lệ có mặt theo bộ phận</div>

                <asp:Repeater ID="rptDept" runat="server">
                    <ItemTemplate>
                        <div class="dept-bar">
                            <div class="dept-bar-head">
                                <span class="dept-bar-name"><%# Eval("Name") %></span>
                                <span class="dept-bar-value">
                                    <b><%# Eval("PresentCount") %></b>
                                    / <%# Eval("ApprovedCount") %> · <%# Eval("Percent") %>%
                                </span>
                            </div>
                            <div class="dept-bar-track">
                                <div class="dept-bar-fill" style='width: <%# Eval("Percent") %>%'></div>
                            </div>
                        </div>
                    </ItemTemplate>
                </asp:Repeater>
            </div>

            <%-- Action: Đóng phiên (kết thúc sự kiện) --%>
            <asp:LinkButton ID="btnCloseSession" runat="server" CssClass="close-session"
                            OnClick="btnCloseSession_Click" CausesValidation="false"
                            OnClientClick="return confirm('Bạn có chắc muốn ĐÓNG phiên điểm danh? Sự kiện sẽ chuyển sang trạng thái Đã kết thúc.');">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <rect x="3" y="11" width="18" height="11" rx="2"/>
                    <path d="M7 11V7a5 5 0 0110 0v4"/>
                </svg>
                Đóng phiên điểm danh
            </asp:LinkButton>

        </aside>
    </div>

    <asp:HiddenField ID="hfTabFilter" runat="server" Value="all" />
</asp:Content>

<asp:Content ID="cScripts" ContentPlaceHolderID="ScriptContent" runat="server">
    <script>
        (function () {
            var qi = document.getElementById('<%= txtQuick.ClientID %>');
            if (qi) qi.focus();
        })();
    </script>
</asp:Content>
