<%@ Page Title="" Language="C#" MasterPageFile="~/AdminMaster.Master" 
    AutoEventWireup="true" CodeBehind="Dashboard.aspx.cs" 
    Inherits="Eventhub.Admin.dashboard" %>

<asp:Content ID="Content1" ContentPlaceHolderID="TitleContent" runat="server">
    Dashboard — EventHub Admin
</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Content/Dashboard.css") %>" rel="stylesheet" type="text/css" />
</asp:Content>

<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" runat="server">

    <!-- page header -->
    <div class="page-head">
        <div>
            <h1 class="page-title">Tổng quan <em>hệ thống</em></h1>
            <div class="page-sub">
                Cập nhật lần cuối:
                <asp:Literal ID="litLastUpdate" runat="server" />
            </div>
        </div>
        <asp:HyperLink ID="lnkCreateEvent" runat="server" 
            NavigateUrl="~/Admin/EventCreate.aspx" CssClass="btn-create">
            <svg viewBox="0 0 24 24" fill="none" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
            </svg>
            Tạo sự kiện mới
        </asp:HyperLink>
    </div>

    <!-- ── STATS ROW 1 ── -->
    <div class="stats-1">

        <!-- Card 1: Tổng sự kiện -->
        <div class="stat-card">
            <div class="stat-head">
                <div class="stat-icon-box amber">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M18 2H6v7a6 6 0 0012 0V2z"/><path d="M4 22h16"/>
                    </svg>
                </div>
                <span class="stat-trend">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="18,15 12,9 6,15"/>
                    </svg>
                    <asp:Literal ID="litEventsTrend" runat="server" />
                </span>
            </div>
            <div class="stat-value"><asp:Literal ID="litTotalEvents" runat="server" Text="0" /></div>
            <div class="stat-label">Tổng số sự kiện</div>
            <div class="stat-spark amber">
                <div class="bar" style="height: 30%"></div>
                <div class="bar" style="height: 50%"></div>
                <div class="bar" style="height: 35%"></div>
                <div class="bar" style="height: 60%"></div>
                <div class="bar" style="height: 45%"></div>
                <div class="bar" style="height: 70%"></div>
                <div class="bar peak" style="height: 95%"></div>
            </div>
            <div class="stat-foot">
                Tháng này: <b><asp:Literal ID="litEventsThisMonth" runat="server" Text="0" /> sự kiện</b> mới được tạo
            </div>
        </div>

        <!-- Card 2: Tổng người dùng -->
        <div class="stat-card">
            <div class="stat-head">
                <div class="stat-icon-box green">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/>
                    </svg>
                </div>
                <span class="stat-trend">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="18,15 12,9 6,15"/>
                    </svg>
                    +<asp:Literal ID="litUsersTrend" runat="server" Text="0" />%
                </span>
            </div>
            <div class="stat-value"><asp:Literal ID="litTotalUsers" runat="server" Text="0" /></div>
            <div class="stat-label">Tổng người dùng</div>
            <div class="stat-spark green">
                <div class="bar" style="height: 40%"></div>
                <div class="bar" style="height: 55%"></div>
                <div class="bar" style="height: 50%"></div>
                <div class="bar" style="height: 65%"></div>
                <div class="bar" style="height: 70%"></div>
                <div class="bar" style="height: 80%"></div>
                <div class="bar peak" style="height: 95%"></div>
            </div>
            <div class="stat-foot">
                Tháng này: <b>+<asp:Literal ID="litUsersThisMonth" runat="server" Text="0" /> tài khoản</b>
            </div>
        </div>

        <!-- Card 3: Tổng lượt đăng ký -->
        <div class="stat-card">
            <div class="stat-head">
                <div class="stat-icon-box blue">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/>
                        <polyline points="14,2 14,8 20,8"/>
                    </svg>
                </div>
                <span class="stat-trend">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="18,15 12,9 6,15"/>
                    </svg>
                    +<asp:Literal ID="litRegTrend" runat="server" Text="0" />%
                </span>
            </div>
            <div class="stat-value"><asp:Literal ID="litTotalRegistrations" runat="server" Text="0" /></div>
            <div class="stat-label">Tổng lượt đăng ký</div>
            <div class="stat-spark blue">
                <div class="bar" style="height: 35%"></div>
                <div class="bar" style="height: 50%"></div>
                <div class="bar" style="height: 45%"></div>
                <div class="bar" style="height: 60%"></div>
                <div class="bar" style="height: 70%"></div>
                <div class="bar" style="height: 85%"></div>
                <div class="bar peak" style="height: 95%"></div>
            </div>
            <div class="stat-foot">
                Tháng này: <b><asp:Literal ID="litRegThisMonth" runat="server" Text="0" /> lượt</b> đăng ký mới
            </div>
        </div>

        <!-- Card 4: Tỷ lệ tham dự -->
        <div class="stat-card">
            <div class="stat-head">
                <div class="stat-icon-box purple-bg">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22,4 12,14.01 9,11.01"/>
                    </svg>
                </div>
                <span class="stat-trend down">
                    <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                        <polyline points="6,9 12,15 18,9"/>
                    </svg>
                    <asp:Literal ID="litAttendTrend" runat="server" Text="0" />%
                </span>
            </div>
            <div class="stat-value"><asp:Literal ID="litAttendanceRate" runat="server" Text="0" />%</div>
            <div class="stat-label">Tỷ lệ tham dự thực tế</div>
            <div class="stat-spark purple">
                <div class="bar peak" style="height: 75%"></div>
                <div class="bar" style="height: 85%"></div>
                <div class="bar" style="height: 70%"></div>
                <div class="bar" style="height: 80%"></div>
                <div class="bar" style="height: 75%"></div>
                <div class="bar" style="height: 65%"></div>
                <div class="bar" style="height: 55%"></div>
            </div>
            <div class="stat-foot">
                So với <b><asp:Literal ID="litAttendPrev" runat="server" Text="0" />%</b> tháng trước
            </div>
        </div>
    </div>

    <!-- ── STATS ROW 2 ── -->
    <div class="stats-2">
        <div class="stat-mini">
            <div class="stat-mini-icon amber">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/>
                </svg>
            </div>
            <div>
                <div class="stat-mini-value"><asp:Literal ID="litPending" runat="server" Text="0" /></div>
                <div class="stat-mini-label">Chờ duyệt</div>
            </div>
        </div>

        <div class="stat-mini">
            <div class="stat-mini-icon green">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                    <polyline points="20,6 9,17 4,12"/>
                </svg>
            </div>
            <div>
                <div class="stat-mini-value"><asp:Literal ID="litOpenEvents" runat="server" Text="0" /></div>
                <div class="stat-mini-label">Đang mở đăng ký</div>
            </div>
        </div>

        <div class="stat-mini">
            <div class="stat-mini-icon red">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
                </svg>
            </div>
            <div>
                <div class="stat-mini-value"><asp:Literal ID="litAlmostFull" runat="server" Text="0" /></div>
                <div class="stat-mini-label">Sắp hết chỗ</div>
            </div>
        </div>

        <div class="stat-mini">
            <div class="stat-mini-icon dark">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/>
                </svg>
            </div>
            <div>
                <div class="stat-mini-value"><asp:Literal ID="litNextMonth" runat="server" Text="0" /></div>
                <div class="stat-mini-label">Sự kiện tháng tới</div>
            </div>
        </div>
    </div>

    <!-- ── MAIN GRID ── -->
    <div class="grid">
        <div class="col-left">
            <div class="card">
                <div class="card-head">
                    <div>
                        <div class="card-title">Lượt đăng ký theo tháng</div>
                        <div class="card-sub">So sánh đăng ký mới và tham dự thực tế</div>
                    </div>
                    <div class="seg-toggle">
                        <button type="button">3T</button>
                        <button type="button" class="active">6T</button>
                        <button type="button">1N</button>
                    </div>
                </div>

                <div class="bar-chart">
                    <asp:Repeater ID="rptMonthlyChart" runat="server">
                        <ItemTemplate>
                            <div class="bar-group">
                                <div class="bar-pair">
                                    <div class="bar signup" style='height: <%# Eval("SignupHeight") %>%'></div>
                                    <div class="bar attend" style='height: <%# Eval("AttendHeight") %>%'></div>
                                </div>
                                <div class="month-label"><%# Eval("MonthLabel") %></div>
                            </div>
                        </ItemTemplate>
                    </asp:Repeater>
                </div>

                <div class="chart-foot-row">
                    <div class="chart-legend">
                        <div><span class="dot ink"></span> Lượt đăng ký</div>
                        <div><span class="dot amber"></span> Tham dự thực tế</div>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-right">
            <div class="card">
                <div class="card-head" style="margin-bottom: 14px;">
                    <div class="card-title">Cần xử lý ngay</div>
                </div>
                <div class="task-list">
                    <asp:PlaceHolder ID="phTasks" runat="server" />
                </div>
            </div>

            <div class="quick-grid">
                <asp:HyperLink ID="lnkQuickCreate" runat="server" 
                    NavigateUrl="~/Admin/EventCreate.aspx" CssClass="quick-btn">
                    <div class="quick-icon dark">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
                            <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
                        </svg>
                    </div>
                    <div class="quick-label">Tạo sự kiện</div>
                </asp:HyperLink>

                <asp:HyperLink ID="lnkQuickApprove" runat="server" 
                    NavigateUrl="~/Admin/Approval.aspx" CssClass="quick-btn">
                    <div class="quick-icon green">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
                            <polyline points="20,6 9,17 4,12"/>
                        </svg>
                    </div>
                    <div class="quick-label">Xét duyệt</div>
                </asp:HyperLink>

                <asp:HyperLink ID="lnkQuickReport" runat="server" 
                    NavigateUrl="#" CssClass="quick-btn">
                    <div class="quick-icon blue">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/>
                        </svg>
                    </div>
                    <div class="quick-label">Xuất báo cáo</div>
                </asp:HyperLink>

                <asp:HyperLink ID="lnkQuickNotify" runat="server" 
                    NavigateUrl="#" CssClass="quick-btn">
                    <div class="quick-icon amber">
                        <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M3 11l18-8-8 18-2-8-8-2z"/>
                        </svg>
                    </div>
                    <div class="quick-label">Gửi thông báo</div>
                </asp:HyperLink>
            </div>
        </div>
    </div>

</asp:Content>

<asp:Content ID="Content4" ContentPlaceHolderID="ScriptContent" runat="server">
    <script>
        document.querySelectorAll('.seg-toggle').forEach(function (group) {
            group.querySelectorAll('button').forEach(function (btn) {
                btn.addEventListener('click', function () {
                    group.querySelectorAll('button').forEach(function (b) { b.classList.remove('active'); });
                    btn.classList.add('active');
                });
            });
        });
    </script>
</asp:Content>