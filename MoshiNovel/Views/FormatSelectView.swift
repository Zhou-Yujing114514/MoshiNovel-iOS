import SwiftUI

// MARK: - 格式选择弹窗
struct FormatSelectView: View {
    @EnvironmentObject var appState: AppState
    let book: SearchResult
    let onClose: () -> Void
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var submitted = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("选择下载格式")
                    .font(.vt(size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(appState.textColor)
                Spacer()
                Button(action: { onClose() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(appState.mutedColor)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            VStack(spacing: 4) {
                Text(book.title)
                    .font(.vt(size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(appState.textColor)
                    .multilineTextAlignment(.center)
                if let author = book.author {
                    Text(author)
                        .font(.vt(size: 13))
                        .foregroundColor(appState.mutedColor)
                }
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 10) {
                formatButton(title: "TXT 文本", format: "txt", icon: "doc.text")
                formatButton(title: "EPUB 电子书", format: "epub", icon: "book")
                formatButton(title: "PDF 文档", format: "pdf", icon: "doc.richtext")
            }
            .padding(.horizontal, 20)
            
            if !message.isEmpty {
                Text(message)
                    .font(.vt(size: 13))
                    .foregroundColor(message.contains("成功") || message.contains("已加入") ? .vtGreen : .vtRed)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if submitted {
                Button(action: { onClose() }) {
                    Text("关闭")
                        .font(.vt(size: 14))
                        .foregroundColor(.vtAccent)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 24)
                        .background(Color.vtAccent.opacity(0.15))
                        .cornerRadius(8)
                }
                .padding(.top, 10)
            }
            
            Spacer()
        }
        .background(appState.bgColor)
    }
    
    private func formatButton(title: String, format: String, icon: String) -> some View {
        Button(action: {
            Task { await submit(format) }
        }) {
            HStack(spacing: 12) {
                if isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.vtAccent)
                        .frame(width: 24)
                    Text(title)
                        .font(.vt(size: 15))
                        .fontWeight(.medium)
                        .foregroundColor(appState.textColor)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(appState.mutedColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(appState.cardColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(appState.borderColor, lineWidth: 1)
            )
        }
        .disabled(isSubmitting || submitted)
        .opacity((isSubmitting || submitted) ? 0.5 : 1)
    }
    
    private func submit(_ format: String) async {
        isSubmitting = true
        message = ""
        defer { isSubmitting = false }
        
        do {
            _ = try await APIService.shared.submitTask(bookId: book.id, format: format)
            await MainActor.run {
                message = "已加入下载队列，请在「下载」页面查看进度"
                submitted = true
            }
        } catch {
            await MainActor.run { message = error.localizedDescription }
        }
    }
}

// MARK: - 管理员视图（三面板）
struct AdminView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selectedPanel = 0
    
    @State private var adminInfo: AdminInfo?
    @State private var infoLoading = false
    
    @State private var settings: AdminSettings?
    @State private var settingsLoading = false
    @State private var settingsMessage = ""
    @State private var siteTitle = ""
    @State private var siteVersion = ""
    @State private var siteOwner = ""
    @State private var siteNotice = ""
    @State private var maxQueueLen = ""
    @State private var rateLimitPerIp = ""
    @State private var rateLimitWindowMin = ""
    @State private var downloadTtlHours = ""
    @State private var disabled = false
    @State private var maintenance = false
    
    @State private var users: [User] = []
    @State private var usersLoading = false
    @State private var usersMessage = ""
    @State private var showTitleAlert = false
    @State private var titleInput = ""
    @State private var targetUser: User?
    @State private var showDeleteConfirm = false
    @State private var showPasswordModal = false
    @State private var passwordInput = ""
    @State private var showCreateUserModal = false
    @State private var newUsername = ""
    @State private var newPassword = ""
    
    private var isAdmin: Bool { appState.currentUser?.isAdmin == true }
    private var isHighRank: Bool { appState.currentUser?.highRank == true }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Text("站长管理")
                        .font(.vt(size: 20))
                        .fontWeight(.bold)
                        .foregroundColor(appState.textColor)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(appState.mutedColor)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                HStack(spacing: 0) {
                    panelTab(title: "网站信息", index: 0)
                    panelTab(title: "网站设置", index: 1)
                    panelTab(title: "用户列表", index: 2)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                
                ScrollView {
                    if selectedPanel == 0 {
                        infoPanel
                    } else if selectedPanel == 1 {
                        settingsPanel
                    } else {
                        usersPanel
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(appState.bgColor)
            .navigationBarHidden(true)
        }
        .alert("设置头衔", isPresented: $showTitleAlert) {
            TextField("头衔名称（留空则撤销）", text: $titleInput)
            Button("确定") {
                if let user = targetUser {
                    Task { await setTitle(user: user, title: titleInput) }
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            if let user = targetUser {
                Text("为「\(user.username)」设置头衔")
            }
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("删除", role: .destructive) {
                if let user = targetUser {
                    Task { await deleteUser(user: user) }
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            if let user = targetUser {
                Text("确定删除账户「\(user.username)」？该操作不可恢复。")
            }
        }
        .sheet(isPresented: $showPasswordModal) {
            passwordModal
        }
        .sheet(isPresented: $showCreateUserModal) {
            createUserModal
        }
    }
    
    private func panelTab(title: String, index: Int) -> some View {
        Button(action: {
            selectedPanel = index
            if index == 0 { Task { await loadInfo() } }
            else if index == 1 { Task { await loadSettings() } }
            else { Task { await loadUsers() } }
        }) {
            Text(title)
                .font(.vt(size: 13))
                .fontWeight(selectedPanel == index ? .semibold : .regular)
                .foregroundColor(selectedPanel == index ? .vtAccent : appState.mutedColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedPanel == index ? Color.vtAccent.opacity(0.12) : Color.clear)
                .cornerRadius(8)
        }
    }
    
    private var infoPanel: some View {
        VStack(spacing: 12) {
            if infoLoading {
                ProgressView().padding()
            } else if let info = adminInfo {
                infoRow(label: "排队任务", value: "\(info.queued ?? 0)")
                infoRow(label: "下载中", value: "\(info.running ?? 0)")
                infoRow(label: "任务总数", value: "\(info.tasks ?? 0)")
                infoRow(label: "用户总数", value: "\(info.users ?? 0)")
                infoRow(label: "站点标题", value: info.siteTitle ?? "-")
                infoRow(label: "站长署名", value: info.siteOwner ?? "-")
                infoRow(label: "队列上限", value: "\(info.maxQueueLen ?? 0)")
                infoRow(label: "每IP限流", value: "\(info.rateLimitPerIp ?? 0) 次 / \(info.rateLimitWindowMin ?? 0) 分钟")
                infoRow(label: "下载有效期", value: "\(info.downloadTtlHours ?? 0) 小时")
                infoRow(label: "引擎地址", value: info.tomatoAddr ?? "-")
                infoRow(label: "数据目录", value: info.dataDir ?? "-")
                infoRow(label: "监听地址", value: info.appAddr ?? "-")
                
                if isAdmin {
                    Button(action: {
                        Task { await clearRecords() }
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.white)
                            Text("清空所有下载记录")
                                .font(.vt(size: 14))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.vtRed)
                        .cornerRadius(8)
                    }
                    .padding(.top, 8)
                }
            } else {
                Text("加载失败，点击刷新")
                    .font(.vt(size: 14))
                    .foregroundColor(appState.mutedColor)
                    .padding()
                Button("刷新") { Task { await loadInfo() } }
                    .font(.vt(size: 14))
                    .foregroundColor(.vtAccent)
            }
        }
        .padding(.bottom, 20)
        .onAppear { Task { await loadInfo() } }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.vt(size: 13))
                .foregroundColor(appState.mutedColor)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.vt(size: 13))
                .foregroundColor(appState.textColor)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(.vertical, 6)
    }
    
    private var settingsPanel: some View {
        VStack(spacing: 16) {
            if settingsLoading {
                ProgressView().padding()
            } else {
                Toggle(isOn: $disabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("禁用本站")
                            .font(.vt(size: 14))
                            .foregroundColor(appState.textColor)
                        Text("开启后，除站长外的所有用户都无法提交下载")
                            .font(.vt(size: 11))
                            .foregroundColor(appState.mutedColor)
                    }
                }
                .padding(12)
                .background(appState.cardColor)
                .cornerRadius(8)
                
                Toggle(isOn: $maintenance) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("启用网站维护")
                            .font(.vt(size: 14))
                            .foregroundColor(appState.textColor)
                        Text("开启后，所有人进入首页只看到维护提示")
                            .font(.vt(size: 11))
                            .foregroundColor(appState.mutedColor)
                    }
                }
                .padding(12)
                .background(appState.cardColor)
                .cornerRadius(8)
                
                settingField(title: "站点标题", text: $siteTitle)
                settingField(title: "版本号", text: $siteVersion)
                settingTextEditor(title: "站长署名", text: $siteOwner)
                settingTextEditor(title: "公告栏", text: $siteNotice)
                settingField(title: "全局排队上限", text: $maxQueueLen, keyboard: .numberPad)
                settingField(title: "每IP每窗口最大提交次数", text: $rateLimitPerIp, keyboard: .numberPad)
                settingField(title: "限流窗口（分钟）", text: $rateLimitWindowMin, keyboard: .numberPad)
                settingField(title: "下载链接有效期（小时）", text: $downloadTtlHours, keyboard: .numberPad)
                
                if !settingsMessage.isEmpty {
                    Text(settingsMessage)
                        .font(.vt(size: 13))
                        .foregroundColor(settingsMessage.contains("成功") ? .vtGreen : .vtRed)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: { Task { await saveSettings() } }) {
                    Text("保存设置")
                        .font(.vt(size: 15))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.vtAccent)
                        .cornerRadius(8)
                }
            }
        }
        .padding(.bottom, 20)
        .onAppear { Task { await loadSettings() } }
    }
    
    private func settingField(title: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.vt(size: 12))
                .foregroundColor(appState.mutedColor)
            TextField(title, text: text)
                .font(.vt(size: 14))
                .foregroundColor(appState.textColor)
                .keyboardType(keyboard)
                .padding(10)
                .background(appState.cardColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(appState.borderColor, lineWidth: 1)
                )
        }
    }
    
    private func settingTextEditor(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.vt(size: 12))
                .foregroundColor(appState.mutedColor)
            TextEditor(text: text)
                .font(.vt(size: 14))
                .foregroundColor(appState.textColor)
                .frame(minHeight: 80)
                .padding(8)
                .background(appState.cardColor)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(appState.borderColor, lineWidth: 1)
                )
        }
    }
    
    private var usersPanel: some View {
        VStack(spacing: 12) {
            if isAdmin {
                Button(action: {
                    newUsername = ""
                    newPassword = ""
                    showCreateUserModal = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.white)
                        Text("新建用户")
                            .font(.vt(size: 14))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.vtAccent)
                    .cornerRadius(8)
                }
            }
            
            if usersLoading {
                ProgressView().padding()
            } else if !usersMessage.isEmpty {
                Text(usersMessage)
                    .font(.vt(size: 13))
                    .foregroundColor(.vtRed)
                    .padding()
            } else {
                Text("共 \(users.count) 个用户")
                    .font(.vt(size: 12))
                    .foregroundColor(appState.mutedColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(users) { user in
                    userRow(user)
                }
            }
            
            Button("刷新") { Task { await loadUsers() } }
                .font(.vt(size: 13))
                .foregroundColor(.vtAccent)
                .padding(.top, 4)
        }
        .padding(.bottom, 20)
        .onAppear { Task { await loadUsers() } }
    }
    
    private func userRow(_ user: User) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(user.username)
                        .font(.vt(size: 14))
                        .foregroundColor(appState.textColor)
                    if user.isAdmin == true {
                        tagText("站长", color: .vtAmber)
                    }
                    if let title = user.title, !title.isEmpty {
                        tagText(title, color: .vtAccent)
                    }
                    if user.highRank == true {
                        tagText("高权", color: .vtGreen)
                    }
                }
                if let createdAt = user.createdAt {
                    Text(formatTime(createdAt) + " 注册")
                        .font(.vt(size: 11))
                        .foregroundColor(appState.mutedColor)
                }
            }
            Spacer()
            HStack(spacing: 6) {
                if isAdmin && user.isAdmin != true {
                    smallButton(title: user.title?.isEmpty == false ? "改头衔" : "设头衔", color: appState.bgColor, textColor: appState.textColor, border: true) {
                        targetUser = user
                        titleInput = user.title ?? ""
                        showTitleAlert = true
                    }
                }
                let canChangePwd = (isAdmin && user.isAdmin != true) ||
                                    (isHighRank && user.isAdmin != true && user.highRank != true)
                if canChangePwd {
                    smallButton(title: "改密码", color: appState.bgColor, textColor: appState.textColor, border: true) {
                        targetUser = user
                        passwordInput = ""
                        showPasswordModal = true
                    }
                }
                let canDelete = (isAdmin && user.isAdmin != true) ||
                                (isHighRank && user.isAdmin != true && user.highRank != true)
                if canDelete {
                    smallButton(title: "删除", color: .vtRed, textColor: .white, border: false) {
                        targetUser = user
                        showDeleteConfirm = true
                    }
                }
            }
        }
        .padding(12)
        .background(appState.cardColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(appState.borderColor, lineWidth: 1)
        )
    }
    
    private func tagText(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.vt(size: 10))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .cornerRadius(4)
    }
    
    private func smallButton(title: String, color: Color, textColor: Color, border: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.vt(size: 11))
                .foregroundColor(textColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color)
                .cornerRadius(6)
                .overlay(
                    Group {
                        if border {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(appState.borderColor, lineWidth: 1)
                        }
                    }
                )
        }
    }
    
    private var passwordModal: some View {
        VStack(spacing: 16) {
            Text("修改密码")
                .font(.vt(size: 18))
                .fontWeight(.bold)
                .foregroundColor(appState.textColor)
            if let user = targetUser {
                Text("为「\(user.username)」设置新密码")
                    .font(.vt(size: 13))
                    .foregroundColor(appState.mutedColor)
            }
            SecureField("新密码（至少4位）", text: $passwordInput)
                .font(.vt(size: 14))
                .foregroundColor(appState.textColor)
                .padding(10)
                .background(appState.cardColor)
                .cornerRadius(8)
            HStack(spacing: 12) {
                Button("取消") { showPasswordModal = false }
                    .font(.vt(size: 14))
                    .foregroundColor(appState.mutedColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(appState.cardColor)
                    .cornerRadius(8)
                Button("确定") {
                    if let user = targetUser {
                        Task { await changePassword(user: user, password: passwordInput) }
                    }
                }
                .font(.vt(size: 14))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.vtAccent)
                .cornerRadius(8)
            }
            Spacer()
        }
        .padding(20)
        .background(appState.bgColor)
    }
    
    private var createUserModal: some View {
        VStack(spacing: 16) {
            Text("新建用户")
                .font(.vt(size: 18))
                .fontWeight(.bold)
                .foregroundColor(appState.textColor)
            TextField("用户名（最多32字符）", text: $newUsername)
                .font(.vt(size: 14))
                .foregroundColor(appState.textColor)
                .padding(10)
                .background(appState.cardColor)
                .cornerRadius(8)
            SecureField("密码（至少4位）", text: $newPassword)
                .font(.vt(size: 14))
                .foregroundColor(appState.textColor)
                .padding(10)
                .background(appState.cardColor)
                .cornerRadius(8)
            HStack(spacing: 12) {
                Button("取消") { showCreateUserModal = false }
                    .font(.vt(size: 14))
                    .foregroundColor(appState.mutedColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(appState.cardColor)
                    .cornerRadius(8)
                Button("创建") {
                    Task { await createUser() }
                }
                .font(.vt(size: 14))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.vtAccent)
                .cornerRadius(8)
            }
            Spacer()
        }
        .padding(20)
        .background(appState.bgColor)
    }
    
    private func formatTime(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func loadInfo() async {
        infoLoading = true
        defer { infoLoading = false }
        do {
            let info = try await APIService.shared.fetchAdminInfo()
            await MainActor.run { adminInfo = info }
        } catch {
            print("加载网站信息失败: \(error)")
        }
    }
    
    private func loadSettings() async {
        settingsLoading = true
        settingsMessage = ""
        defer { settingsLoading = false }
        do {
            let s = try await APIService.shared.fetchAdminSettings()
            await MainActor.run {
                settings = s
                siteTitle = s.siteTitle ?? ""
                siteVersion = s.siteVersion ?? ""
                siteOwner = s.siteOwner ?? ""
                siteNotice = s.siteNotice ?? ""
                maxQueueLen = s.maxQueueLen != nil ? "\(s.maxQueueLen!)" : ""
                rateLimitPerIp = s.rateLimitPerIp != nil ? "\(s.rateLimitPerIp!)" : ""
                rateLimitWindowMin = s.rateLimitWindowMin != nil ? "\(s.rateLimitWindowMin!)" : ""
                downloadTtlHours = s.downloadTtlHours != nil ? "\(s.downloadTtlHours!)" : ""
                disabled = s.disabled ?? false
                maintenance = s.maintenance ?? false
            }
        } catch {
            await MainActor.run { settingsMessage = error.localizedDescription }
        }
    }
    
    private func saveSettings() async {
        settingsMessage = "保存中..."
        var body: [String: Any] = [:]
        body["site_title"] = siteTitle
        body["site_version"] = siteVersion
        body["site_owner"] = siteOwner
        body["site_notice"] = siteNotice
        if let v = Int(maxQueueLen) { body["max_queue_len"] = v }
        if let v = Int(rateLimitPerIp) { body["rate_limit_per_ip"] = v }
        if let v = Int(rateLimitWindowMin) { body["rate_limit_window_min"] = v }
        if let v = Int(downloadTtlHours) { body["download_ttl_hours"] = v }
        body["disabled"] = disabled
        body["maintenance"] = maintenance
        
        do {
            _ = try await APIService.shared.saveAdminSettings(body)
            await MainActor.run { settingsMessage = "保存成功" }
        } catch {
            await MainActor.run { settingsMessage = error.localizedDescription }
        }
    }
    
    private func loadUsers() async {
        usersLoading = true
        usersMessage = ""
        defer { usersLoading = false }
        do {
            let list = try await APIService.shared.fetchUsers()
            await MainActor.run { users = list }
        } catch {
            await MainActor.run { usersMessage = error.localizedDescription }
        }
    }
    
    private func setTitle(user: User, title: String) async {
        do {
            try await APIService.shared.setUserTitle(username: user.username, title: title)
            await MainActor.run { targetUser = nil }
            await loadUsers()
        } catch {
            await MainActor.run { usersMessage = error.localizedDescription }
        }
    }
    
    private func changePassword(user: User, password: String) async {
        guard password.count >= 4 else {
            await MainActor.run { usersMessage = "密码至少4位" }
            return
        }
        do {
            try await APIService.shared.setUserPassword(username: user.username, password: password)
            await MainActor.run {
                showPasswordModal = false
                targetUser = nil
                usersMessage = "密码修改成功"
            }
        } catch {
            await MainActor.run { usersMessage = error.localizedDescription }
        }
    }
    
    private func deleteUser(user: User) async {
        do {
            try await APIService.shared.deleteUser(username: user.username)
            await MainActor.run {
                targetUser = nil
                usersMessage = "已删除「\(user.username)」"
            }
            await loadUsers()
        } catch {
            await MainActor.run { usersMessage = error.localizedDescription }
        }
    }
    
    private func createUser() async {
        guard !newUsername.isEmpty, newPassword.count >= 4 else {
            return
        }
        do {
            _ = try await APIService.shared.createUser(username: newUsername, password: newPassword)
            await MainActor.run {
                showCreateUserModal = false
                usersMessage = "用户创建成功"
            }
            await loadUsers()
        } catch {
            await MainActor.run { usersMessage = error.localizedDescription }
        }
    }
    
    private func clearRecords() async {
        do {
            try await APIService.shared.clearRecords()
            await MainActor.run { adminInfo = nil }
            await loadInfo()
        } catch {
            print("清空记录失败: \(error)")
        }
    }
}
