import SwiftUI

struct FormatSelectView: View {
    @EnvironmentObject var appState: AppState
    let book: SearchResult
    let onClose: () -> Void
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var submitted = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // 书籍信息
                VStack(spacing: 4) {
                    Text(book.title)
                        .font(.vt(size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(appState.textColor)
                        .multilineTextAlignment(.center)
                    if let author = book.author {
                        Text(author)
                            .font(.vt(size: 13))
                            .foregroundColor(appState.mutedColor)
                    }
                }
                .padding(.top, 20)
                
                Text("选择格式")
                    .font(.vt(size: 15))
                    .foregroundColor(appState.mutedColor)
                    .padding(.top, 10)
                
                // 格式选项
                VStack(spacing: 10) {
                    formatButton(title: "TXT 文本", format: "txt")
                    formatButton(title: "EPUB 电子书", format: "epub")
                    formatButton(title: "PDF 文档", format: "pdf")
                }
                .padding(.horizontal, 20)
                
                if !message.isEmpty {
                    Text(message)
                        .font(.vt(size: 13))
                        .foregroundColor(message.contains("成功") ? .vtGreen : .vtRed)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                if submitted {
                    Button(action: { onClose() }) {
                        Text("关闭")
                            .font(.vt(size: 14))
                            .foregroundColor(.vtAccent)
                    }
                    .padding(.top, 10)
                }
                
                Spacer()
            }
            .background(appState.cardColor)
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                Button(action: { onClose() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(appState.mutedColor)
                        .padding(16)
                }
            }
        }
    }
    
    private func formatButton(title: String, format: String) -> some View {
        Button(action: {
            Task { await submit(format) }
        }) {
            HStack {
                if isSubmitting {
                    ProgressView().tint(.white)
                } else {
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
            .background(appState.bgColor)
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
            message = error.localizedDescription
        }
    }
}

// MARK: - 管理视图
struct AdminView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var message = ""
    @State private var showTitleAlert = false
    @State private var titleInput = ""
    @State private var targetUser: User?
    @State private var showDeleteConfirm = false
    
    private var isAdmin: Bool { appState.currentUser?.isAdmin == true }
    private var isHighRank: Bool { appState.currentUser?.highRank == true }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("管理")
                    .font(.vt(size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(appState.textColor)
                    .padding(.top, 20)
                
                // 清空记录
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
                    .padding(.horizontal)
                }
                
                if !message.isEmpty {
                    Text(message)
                        .font(.vt(size: 13))
                        .foregroundColor(.vtGreen)
                }
                
                // 用户列表
                HStack {
                    Text("注册用户 (\(users.count))")
                        .font(.vt(size: 15))
                        .fontWeight(.semibold)
                        .foregroundColor(appState.textColor)
                    Spacer()
                    if isLoading {
                        ProgressView()
                    }
                    Button(action: {
                        Task { await loadUsers() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.vtAccent)
                    }
                }
                .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(users) { user in
                            userRow(user)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .background(appState.bgColor)
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(appState.mutedColor)
                        .padding(16)
                }
            }
            .onAppear {
                Task { await loadUsers() }
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
        }
    }
    
    private func userRow(_ user: User) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(user.username)
                        .font(.vt(size: 14))
                        .foregroundColor(appState.textColor)
                    if user.isAdmin == true {
                        Text("站长")
                            .font(.vt(size: 10))
                            .foregroundColor(.vtAmber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.vtAmber.opacity(0.2))
                            .cornerRadius(4)
                    } else if let title = user.title, !title.isEmpty {
                        Text(title)
                            .font(.vt(size: 10))
                            .foregroundColor(.vtAccent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.vtAccent.opacity(0.15))
                            .cornerRadius(4)
                    }
                    if user.highRank == true {
                        Text("高权")
                            .font(.vt(size: 10))
                            .foregroundColor(.vtGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.vtGreen.opacity(0.2))
                            .cornerRadius(4)
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
                // 设头衔（仅站长）
                if isAdmin && user.isAdmin != true {
                    Button(action: {
                        targetUser = user
                        titleInput = user.title ?? ""
                        showTitleAlert = true
                    }) {
                        Text(user.title?.isEmpty == false ? "改头衔" : "设头衔")
                            .font(.vt(size: 11))
                            .foregroundColor(appState.textColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(appState.bgColor)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(appState.borderColor, lineWidth: 1)
                            )
                    }
                }
                // 删除用户（站长可删非站长，高权可删普通用户）
                let canDelete = (isAdmin && user.isAdmin != true) ||
                                (isHighRank && user.isAdmin != true && user.highRank != true)
                if canDelete {
                    Button(action: {
                        targetUser = user
                        showDeleteConfirm = true
                    }) {
                        Text("删除")
                            .font(.vt(size: 11))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.vtRed)
                            .cornerRadius(6)
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
    
    private func formatTime(_ timestamp: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func loadUsers() async {
        isLoading = true
        message = ""
        defer { isLoading = false }
        do {
            let list = try await APIService.shared.fetchUsers()
            await MainActor.run { users = list }
        } catch {
            await MainActor.run { message = error.localizedDescription }
        }
    }
    
    private func setTitle(user: User, title: String) async {
        do {
            try await APIService.shared.setUserTitle(username: user.username, title: title)
            await MainActor.run {
                message = "已设置「\(user.username)」的头衔"
                targetUser = nil
            }
            await loadUsers()
        } catch {
            await MainActor.run { message = error.localizedDescription }
        }
    }
    
    private func deleteUser(user: User) async {
        do {
            try await APIService.shared.deleteUser(username: user.username)
            await MainActor.run {
                message = "已删除「\(user.username)」"
                targetUser = nil
            }
            await loadUsers()
        } catch {
            await MainActor.run { message = error.localizedDescription }
        }
    }
    
    private func clearRecords() async {
        do {
            try await APIService.shared.clearRecords()
            await MainActor.run { message = "已清空下载记录" }
        } catch {
            await MainActor.run { message = error.localizedDescription }
        }
    }
}
