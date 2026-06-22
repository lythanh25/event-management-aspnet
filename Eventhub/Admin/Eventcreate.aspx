<%@ Page Title="Tạo sự kiện mới" Language="C#" MasterPageFile="~/AdminMaster.Master"
    AutoEventWireup="true" CodeBehind="EventCreate.aspx.cs"
    Inherits="Eventhub.Admin.eventcreate" %>

<asp:Content ID="cTitle" ContentPlaceHolderID="TitleContent" runat="server">
    <asp:Literal ID="litPageTitle" runat="server" Text="Tạo sự kiện mới — EventHub Admin" />
</asp:Content>

<asp:Content ID="cHead" ContentPlaceHolderID="HeadContent" runat="server">
    <link href="<%= ResolveUrl("~/Content/EventCreate.css") %>" rel="stylesheet" type="text/css" />
</asp:Content>

<asp:Content ID="cMain" ContentPlaceHolderID="MainContent" runat="server">

    <%-- Thông báo alert --%>
    <asp:Panel ID="pnlAlert" runat="server" Visible="false" CssClass="alert">
        <asp:Literal ID="litAlertMsg" runat="server" />
    </asp:Panel>

    <%-- ─── PAGE HEAD ─── --%>
    <div class="page-head">
        <div>
            <h1 class="page-title">
                <asp:Literal ID="litHeading" runat="server" Text="Tạo " />
                <em><asp:Literal ID="litHeadingEm" runat="server" Text="sự kiện mới" /></em>
            </h1>
            <div class="page-sub">
                Mã sự kiện:
                <span class="mono"><asp:Literal ID="litEventCode" runat="server" Text="(sẽ được tạo tự động)" /></span>
                <span class="sep">•</span>
                <asp:Literal ID="litStatusLabel" runat="server" Text="Bản nháp" />
            </div>
        </div>
        <div class="head-actions">
            <asp:HyperLink ID="lnkBack" runat="server" CssClass="btn btn-ghost"
                           NavigateUrl="~/Admin/EventsManagement.aspx">
                <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="19" y1="12" x2="5" y2="12"/><polyline points="12,19 5,12 12,5"/>
                </svg>
                Quay lại
            </asp:HyperLink>
            <asp:Button ID="btnSaveDraftTop" runat="server" Text="Lưu nháp"
                        CssClass="btn btn-ghost" OnClick="btnSaveDraft_Click"
                        CausesValidation="false" />
            <asp:Button ID="btnPublishTop" runat="server" Text="Đăng sự kiện"
                        CssClass="btn btn-primary" OnClick="btnPublish_Click" />
        </div>
    </div>

    <%-- ─── GRID ─── --%>
    <div class="grid">

        <%-- ── LEFT COLUMN ── --%>
        <div class="col-main">

            <%-- 01 BANNER ── --%>
            <div class="card">
                <div class="card-head">
                    <div>
                        <div class="card-title">Hình ảnh <em>banner</em></div>
                        <div class="card-sub">Khuyến nghị tỉ lệ 16:9, tối thiểu 1280×720, dung lượng dưới 5MB.</div>
                    </div>
                    <div class="card-step">01 / 05</div>
                </div>

                <div class="uploader">
                    <asp:Panel ID="pnlBannerPreview" runat="server" CssClass="uploader-preview"
                               Visible="true">
                        <asp:Image ID="imgBanner" runat="server" CssClass="uploader-image" />
                        <span class="preview-tag">
                            <asp:Literal ID="litBannerTag" runat="server" Text="Chưa có banner — gradient mặc định" />
                        </span>
                    </asp:Panel>

                    <div class="uploader-controls">
                        <asp:FileUpload ID="fuBanner" runat="server" CssClass="file-input" />
                        <asp:HiddenField ID="hfBannerUrl" runat="server" />
                        <asp:LinkButton ID="btnRemoveBanner" runat="server" CssClass="btn btn-ghost btn-sm"
                                        OnClick="btnRemoveBanner_Click" CausesValidation="false">
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
                            </svg>
                            Xoá ảnh
                        </asp:LinkButton>
                    </div>
                </div>
            </div>

            <%-- 02 BASIC INFO --%>
            <div class="card">
                <div class="card-head">
                    <div>
                        <div class="card-title">Thông tin <em>cơ bản</em></div>
                        <div class="card-sub">Tiêu đề rõ ràng và mô tả hấp dẫn sẽ giúp tăng lượt đăng ký.</div>
                    </div>
                    <div class="card-step">02 / 05</div>
                </div>

                <div class="field">
                    <label class="label">
                        Tên sự kiện <span class="req">*</span>
                        <span class="hint" id="titleHint">0 / 120</span>
                    </label>
                    <asp:TextBox ID="txtTitle" runat="server" CssClass="input"
                                 MaxLength="120"
                                 placeholder="Ví dụ: Hội thảo Chuyển đổi số 2025" />
                    <asp:RequiredFieldValidator ID="rfvTitle" runat="server"
                        ControlToValidate="txtTitle"
                        ErrorMessage="Vui lòng nhập tên sự kiện"
                        CssClass="field-error" Display="Dynamic" />
                </div>

                <div class="row">
                    <div class="field">
                        <label class="label">Chủ đề <span class="req">*</span></label>
                        <asp:DropDownList ID="ddlCategory" runat="server" CssClass="select" />
                        <asp:RequiredFieldValidator ID="rfvCategory" runat="server"
                            ControlToValidate="ddlCategory" InitialValue="0"
                            ErrorMessage="Vui lòng chọn chủ đề"
                            CssClass="field-error" Display="Dynamic" />
                    </div>
                    <div class="field">
                        <label class="label">Hình thức tổ chức</label>
                        <asp:DropDownList ID="ddlFormat" runat="server" CssClass="select">
                            <asp:ListItem Value="offline" Text="Trực tiếp (Offline)" Selected="True" />
                            <asp:ListItem Value="online"  Text="Trực tuyến (Online)" />
                            <asp:ListItem Value="hybrid"  Text="Kết hợp (Hybrid)" />
                        </asp:DropDownList>
                    </div>
                </div>

                <div class="field" style="margin-bottom:0;">
                    <label class="label">
                        Mô tả ngắn
                        <span class="hint">Hiển thị trên thẻ sự kiện ở trang chủ</span>
                    </label>
                    <asp:TextBox ID="txtSubtitle" runat="server" CssClass="textarea"
                                 TextMode="MultiLine" Rows="3" MaxLength="200"
                                 placeholder="Tóm tắt nội dung sự kiện trong 2–3 câu..." />
                </div>
            </div>

            <%-- 03 DESCRIPTION --%>
            <div class="card">
                <div class="card-head">
                    <div>
                        <div class="card-title">Mô tả <em>chi tiết</em></div>
                        <div class="card-sub">Trình bày timeline, nội dung chính, diễn giả và thông tin liên quan.</div>
                    </div>
                    <div class="card-step">03 / 05</div>
                </div>

                <asp:TextBox ID="txtDescription" runat="server" CssClass="textarea textarea-lg"
                             TextMode="MultiLine" Rows="10"
                             placeholder="Mô tả chi tiết về sự kiện, có thể dùng HTML cơ bản: <h2>, <p>, <ul>, <li>, <b>, <i>, <blockquote>..." />
            </div>

            <%-- 04 TIME & LOCATION --%>
            <div class="card">
                <div class="card-head">
                    <div>
                        <div class="card-title">Thời gian &amp; <em>địa điểm</em></div>
                        <div class="card-sub">Múi giờ mặc định: GMT+7 (Hà Nội).</div>
                    </div>
                    <div class="card-step">04 / 05</div>
                </div>

                <div class="field">
                    <label class="label">Thời gian diễn ra <span class="req">*</span></label>
                    <div class="datetime-row">
                        <div class="datetime-pair">
                            <div class="input-with-icon">
                                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="3" y="4" width="18" height="18" rx="2"/>
                                    <line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/>
                                    <line x1="3" y1="10" x2="21" y2="10"/>
                                </svg>
                                <asp:TextBox ID="txtStartDate" runat="server" CssClass="input"
                                             TextMode="Date" />
                            </div>
                            <div class="input-with-icon">
                                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/>
                                </svg>
                                <asp:TextBox ID="txtStartTime" runat="server" CssClass="input"
                                             TextMode="Time" />
                            </div>
                        </div>
                        <div class="datetime-arrow">
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <line x1="5" y1="12" x2="19" y2="12"/><polyline points="12,5 19,12 12,19"/>
                            </svg>
                        </div>
                        <div class="datetime-pair">
                            <div class="input-with-icon">
                                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <rect x="3" y="4" width="18" height="18" rx="2"/>
                                    <line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/>
                                    <line x1="3" y1="10" x2="21" y2="10"/>
                                </svg>
                                <asp:TextBox ID="txtEndDate" runat="server" CssClass="input"
                                             TextMode="Date" />
                            </div>
                            <div class="input-with-icon">
                                <svg class="icon" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                    <circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/>
                                </svg>
                                <asp:TextBox ID="txtEndTime" runat="server" CssClass="input"
                                             TextMode="Time" />
                            </div>
                        </div>
                    </div>
                    <div class="datetime-foot">
                        <span>BẮT ĐẦU → KẾT THÚC</span>
                        <span id="duration-foot">Thời lượng: <b id="duration-value">—</b></span>
                    </div>
                </div>

                <div class="row">
                    <div class="field">
                        <label class="label">Địa điểm <span class="req">*</span></label>
                        <div class="input-with-icon">
                            <svg class="icon" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/>
                                <circle cx="12" cy="10" r="3"/>
                            </svg>
                            <asp:TextBox ID="txtLocation" runat="server" CssClass="input"
                                         MaxLength="200"
                                         placeholder="Trung tâm Hội nghị Quốc gia" />
                        </div>
                    </div>
                    <div class="field">
                        <label class="label">Phòng / Tầng</label>
                        <asp:TextBox ID="txtRoom" runat="server" CssClass="input"
                                     MaxLength="120"
                                     placeholder="Hội trường A — Tầng 2" />
                    </div>
                </div>

                <div class="field">
                    <label class="label">Địa chỉ chi tiết</label>
                    <asp:TextBox ID="txtAddress" runat="server" CssClass="input"
                                 MaxLength="255"
                                 placeholder="57 Phạm Hùng, Mễ Trì, Nam Từ Liêm, Hà Nội" />
                </div>

                <div class="field" style="margin-bottom:0;">
                    <label class="label">URL trực tuyến (nếu là Online / Hybrid)</label>
                    <div class="input-with-icon">
                        <svg class="icon" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                            <path d="M10 13a5 5 0 007.54.54l3-3a5 5 0 00-7.07-7.07l-1.72 1.71"/>
                            <path d="M14 11a5 5 0 00-7.54-.54l-3 3a5 5 0 007.07 7.07l1.71-1.71"/>
                        </svg>
                        <asp:TextBox ID="txtOnlineUrl" runat="server" CssClass="input"
                                     MaxLength="500"
                                     placeholder="https://meet.google.com/abc-defg-hij" />
                    </div>
                </div>
            </div>

            <%-- 05 CAPACITY & REGISTRATION --%>
            <div class="card">
                <div class="card-head">
                    <div>
                        <div class="card-title">Đăng ký &amp; <em>giới hạn</em></div>
                        <div class="card-sub">Cài đặt số lượng người tham gia và phương thức xét duyệt.</div>
                    </div>
                    <div class="card-step">05 / 05</div>
                </div>

                <div class="field">
                    <label class="label">
                        Giới hạn số người tham gia <span class="req">*</span>
                        <span class="hint" id="capValueLabel">— người</span>
                    </label>
                    <div class="cap-row">
                        <div class="slider-box">
                            <input id="capSlider" class="slider-track" type="range"
                                   min="10" max="1000" step="10" value="100" />
                            <div class="slider-marks">
                                <span>10</span><span>250</span><span>500</span><span>750</span><span>1000</span>
                            </div>
                        </div>
                        <asp:TextBox ID="txtCapacity" runat="server" CssClass="input cap-input"
                                     TextMode="Number" Text="100" />
                    </div>
                </div>

                <div class="row">
                    <div class="field">
                        <label class="label">Hạn chót đăng ký</label>
                        <div class="input-with-icon">
                            <svg class="icon" viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="3" y="4" width="18" height="18" rx="2"/>
                                <line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/>
                                <line x1="3" y1="10" x2="21" y2="10"/>
                            </svg>
                            <asp:TextBox ID="txtDeadline" runat="server" CssClass="input"
                                         TextMode="Date" />
                        </div>
                    </div>
                    <div class="field">
                        <label class="label">Ban tổ chức <span class="req">*</span></label>
                        <asp:DropDownList ID="ddlDepartment" runat="server" CssClass="select" />
                        <asp:RequiredFieldValidator ID="rfvDept" runat="server"
                            ControlToValidate="ddlDepartment" InitialValue="0"
                            ErrorMessage="Vui lòng chọn ban tổ chức"
                            CssClass="field-error" Display="Dynamic" />
                    </div>
                </div>

                <div class="field">
                    <label class="label">
                        Thẻ sự kiện
                        <span class="hint">Mỗi thẻ cách nhau bằng dấu phẩy</span>
                    </label>
                    <asp:TextBox ID="txtTags" runat="server" CssClass="input"
                                 placeholder="Chuyển đổi số, AI, 2025, Hội thảo" />
                </div>

                <div class="field" style="margin-bottom:0;">
                    <label class="label">Tùy chọn nâng cao</label>
                    <div class="toggles">
                        <div class="toggle-row">
                            <div>
                                <div class="toggle-info-title">Yêu cầu Admin xét duyệt</div>
                                <div class="toggle-info-sub">Người dùng cần được phê duyệt sau khi đăng ký.</div>
                            </div>
                            <asp:CheckBox ID="cbRequireApproval" runat="server" Checked="true"
                                          CssClass="switch-cb" />
                        </div>
                        <div class="toggle-row">
                            <div>
                                <div class="toggle-info-title">Cho phép danh sách chờ (waitlist)</div>
                                <div class="toggle-info-sub">Khi đủ số lượng, người đăng ký sau sẽ vào hàng chờ.</div>
                            </div>
                            <asp:CheckBox ID="cbAllowWaitlist" runat="server" Checked="true"
                                          CssClass="switch-cb" />
                        </div>
                        <div class="toggle-row">
                            <div>
                                <div class="toggle-info-title">Mở cho toàn công ty</div>
                                <div class="toggle-info-sub">Tắt nếu chỉ một số phòng ban được phép tham gia.</div>
                            </div>
                            <asp:CheckBox ID="cbOpenAll" runat="server" Checked="true"
                                          CssClass="switch-cb" />
                        </div>
                    </div>
                </div>
            </div>

        </div>

        <%-- ── RIGHT COLUMN ── --%>
        <aside class="col-side">

            <%-- PREVIEW --%>
            <div class="preview-card">
                <div class="preview-head">
                    <div class="preview-head-title">Xem trước thẻ</div>
                    <span class="preview-head-tag">LIVE</span>
                </div>
                <div class="preview-banner">
                    <span class="preview-pill" id="previewCategory">Sự kiện</span>
                </div>
                <div class="preview-body">
                    <div class="preview-event-title" id="previewTitle">Tên sự kiện…</div>
                    <div class="preview-meta">
                        <div>
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <rect x="3" y="4" width="18" height="18" rx="2"/>
                                <line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/>
                                <line x1="3" y1="10" x2="21" y2="10"/>
                            </svg>
                            <span id="previewDate">—</span>
                        </div>
                        <div>
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <circle cx="12" cy="12" r="10"/><polyline points="12,6 12,12 16,14"/>
                            </svg>
                            <span id="previewTime">—</span>
                        </div>
                        <div>
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/>
                                <circle cx="12" cy="10" r="3"/>
                            </svg>
                            <span id="previewLocation">Chưa có địa điểm</span>
                        </div>
                        <div>
                            <svg viewBox="0 0 24 24" fill="none" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                                <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/>
                                <circle cx="9" cy="7" r="4"/>
                            </svg>
                            Tối đa <b id="previewCap" style="color:var(--ink);font-weight:600;">100</b> người
                        </div>
                    </div>
                    <div class="preview-cta">Đăng ký tham gia</div>
                </div>
            </div>

            <%-- CHECKLIST --%>
            <div class="checklist-card">
                <div class="checklist-head">
                    <div class="checklist-head-title">Tiến độ <em>hoàn thành</em></div>
                </div>
                <div class="checklist" id="checklist">
                    <div class="check-row" data-check="banner">
                        <div class="check-tick">1</div>
                        <div class="check-text">Banner sự kiện<small>Khuyến nghị tỉ lệ 16:9</small></div>
                    </div>
                    <div class="check-row" data-check="title">
                        <div class="check-tick">2</div>
                        <div class="check-text">Tên sự kiện<small>Rõ ràng, tối đa 120 ký tự</small></div>
                    </div>
                    <div class="check-row" data-check="desc">
                        <div class="check-tick">3</div>
                        <div class="check-text">Mô tả chi tiết<small>Timeline, nội dung, diễn giả</small></div>
                    </div>
                    <div class="check-row" data-check="time">
                        <div class="check-tick">4</div>
                        <div class="check-text">Thời gian &amp; địa điểm<small>Bắt đầu, kết thúc, địa chỉ</small></div>
                    </div>
                    <div class="check-row" data-check="cap">
                        <div class="check-tick">5</div>
                        <div class="check-text">Giới hạn người tham gia<small>Số lượng, hạn chót đăng ký</small></div>
                    </div>
                </div>
            </div>

            <%-- TIP --%>
            <div class="tip-card">
                <div class="tip-tag">MẸO TỪ EVENTHUB</div>
                <div class="tip-title">Sự kiện có <em>banner</em> tăng <b>3.2×</b> lượt đăng ký.</div>
                <div class="tip-body">
                    Sử dụng banner sắc nét, có thông điệp rõ ràng và thời gian sự kiện ngay trên ảnh.
                    Tránh dùng quá 2 phông chữ trong cùng một banner.
                </div>
            </div>
        </aside>
    </div>

    <%-- ─── STICKY ACTION BAR ─── --%>
    <div class="actionbar">
        <div class="actionbar-info">
            <span class="save-status">
                <asp:Literal ID="litSaveStatus" runat="server" Text="Chưa lưu" />
            </span>
        </div>
        <div class="head-actions">
            <asp:Button ID="btnSaveDraft" runat="server" Text="Lưu nháp"
                        CssClass="btn btn-ghost" OnClick="btnSaveDraft_Click"
                        CausesValidation="false" />
            <asp:Button ID="btnPublish" runat="server" Text="Đăng sự kiện"
                        CssClass="btn btn-primary" OnClick="btnPublish_Click" />
        </div>
    </div>

    <asp:HiddenField ID="hfEventId" runat="server" />
</asp:Content>

<asp:Content ID="cScripts" ContentPlaceHolderID="ScriptContent" runat="server">
    <script>
        (function () {
            // ─── Capacity slider ↔ input ───
            var slider = document.getElementById('capSlider');
            var capInput = document.getElementById('<%= txtCapacity.ClientID %>');
            var capLabel = document.getElementById('capValueLabel');
            var prevCap = document.getElementById('previewCap');

            function syncCap(v) {
                v = Math.max(10, Math.min(1000, parseInt(v) || 10));
                slider.value = v;
                capInput.value = v;
                var p = ((v - 10) / 990) * 100;
                slider.style.setProperty('--p', p + '%');
                capLabel.textContent = v.toLocaleString('vi-VN') + ' người';
                if (prevCap) prevCap.textContent = v.toLocaleString('vi-VN');
            }
            slider.addEventListener('input', function (e) { syncCap(e.target.value); });
            capInput.addEventListener('input', function (e) { syncCap(e.target.value); });
            syncCap(capInput.value || 100);

            // ─── Title counter + preview ───
            var titleInput = document.getElementById('<%= txtTitle.ClientID %>');
            var titleHint = document.getElementById('titleHint');
            var prevTitle = document.getElementById('previewTitle');

            function syncTitle() {
                titleHint.textContent = titleInput.value.length + ' / 120';
                prevTitle.textContent = titleInput.value || 'Tên sự kiện…';
                updateChecklist('title', titleInput.value.trim().length >= 5);
            }
            titleInput.addEventListener('input', syncTitle);
            syncTitle();

            // ─── Category preview ───
            var ddlCat = document.getElementById('<%= ddlCategory.ClientID %>');
            var prevCat = document.getElementById('previewCategory');
            function syncCat() {
                if (ddlCat.selectedIndex > 0 && prevCat) {
                    prevCat.textContent = ddlCat.options[ddlCat.selectedIndex].text;
                }
            }
            ddlCat.addEventListener('change', syncCat);
            syncCat();

            // ─── Date/Time preview + duration ───
            var sd = document.getElementById('<%= txtStartDate.ClientID %>');
            var st = document.getElementById('<%= txtStartTime.ClientID %>');
            var ed = document.getElementById('<%= txtEndDate.ClientID %>');
            var et = document.getElementById('<%= txtEndTime.ClientID %>');
            var prevDate = document.getElementById('previewDate');
            var prevTime = document.getElementById('previewTime');
            var durEl = document.getElementById('duration-value');

            function buildDt(d, t) {
                if (!d) return null;
                return new Date(d + 'T' + (t || '00:00') + ':00');
            }
            function formatVnDate(d) {
                var days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
                return days[d.getDay()] + ', ' +
                    String(d.getDate()).padStart(2, '0') + '/' +
                    String(d.getMonth() + 1).padStart(2, '0') + '/' + d.getFullYear();
            }
            function syncDateTime() {
                var s = buildDt(sd.value, st.value);
                var e = buildDt(ed.value, et.value);
                if (s) {
                    prevDate.textContent = formatVnDate(s);
                    prevTime.textContent = (st.value || '--:--') + ' – ' + (et.value || '--:--') + ' (GMT+7)';
                }
                if (s && e && e > s) {
                    var mins = Math.round((e - s) / 60000);
                    var h = Math.floor(mins / 60), m = mins % 60;
                    durEl.textContent = (h > 0 ? h + ' giờ ' : '') + (m > 0 ? m + ' phút' : (h > 0 ? '' : '0 phút'));
                    updateChecklist('time', true);
                } else {
                    durEl.textContent = '—';
                    updateChecklist('time', false);
                }
            }
            [sd, st, ed, et].forEach(function (el) { el.addEventListener('input', syncDateTime); });
            syncDateTime();

            // ─── Location preview ───
            var loc = document.getElementById('<%= txtLocation.ClientID %>');
            var prevLoc = document.getElementById('previewLocation');
            function syncLoc() {
                prevLoc.textContent = loc.value || 'Chưa có địa điểm';
            }
            loc.addEventListener('input', syncLoc);
            syncLoc();

            // ─── Description checklist ───
            var desc = document.getElementById('<%= txtDescription.ClientID %>');
            desc.addEventListener('input', function () {
                updateChecklist('desc', desc.value.trim().length >= 30);
            });
            updateChecklist('desc', desc.value.trim().length >= 30);

            // ─── Banner checklist ───
            var fu = document.getElementById('<%= fuBanner.ClientID %>');
            var hfBn = document.getElementById('<%= hfBannerUrl.ClientID %>');
            fu.addEventListener('change', function () {
                updateChecklist('banner', fu.files && fu.files.length > 0);
            });
            updateChecklist('banner', !!(hfBn && hfBn.value));

            // ─── Capacity checklist ───
            updateChecklist('cap', parseInt(capInput.value) > 0);
            capInput.addEventListener('input', function () {
                updateChecklist('cap', parseInt(capInput.value) > 0);
            });

            // ─── Checklist util ───
            function updateChecklist(key, done) {
                var row = document.querySelector('[data-check="' + key + '"]');
                if (!row) return;
                var tick = row.querySelector('.check-tick');
                if (done) {
                    tick.classList.add('done');
                    tick.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20,6 9,17 4,12"/></svg>';
                } else {
                    tick.classList.remove('done');
                    tick.textContent = tick.dataset.num || (tick.textContent || '•');
                }
            }
            // Lưu số gốc của tick
            document.querySelectorAll('.check-tick').forEach(function (t, i) {
                t.dataset.num = (i + 1).toString();
            });
        })();
    </script>
</asp:Content>
