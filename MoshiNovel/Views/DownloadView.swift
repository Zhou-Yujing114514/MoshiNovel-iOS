import SwiftUI

struct DownloadView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showLogin: Bool
    @State private var selectedList = 0 // 0=我的, 1=全站
    @State private var myTasks: [DownloadTask] = []
    @State private var allTasks: [DownloadTask] = []
    @State private var isLoading = false
    @State private var timer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 顶部标签
                HStack(spacing: 10) {
                    tabButton(title: "我的提取", index: 0)
                    tabButton(title: "全站提取", index: 1)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 14)
                
                // 任务列表
                ScrollView {
                    if isLoading {
                        ProgressView()
                            .padding()
                    } else {
                        let tasks = selectedList == 0 ? myTasks : allTasks
                        if tasks.isEmpty {
                            VStack(spacing: 12) {
                                if selectedList == 0 && !appState.isLoggedIn {
                                    Text("登录后查看")
                                        .font(.vt(size: 14))
                                        .foregroundColor(appState.mutedColor)
                                    Button(action: { showLogin = true }) {
                                        Text("登录")
                                            .font(.vt(size: 14))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 10)
                                            .background(Color.vtAccent)
                                            .cornerRadius(8)
                                    }
                                } else {
                                    Text("暂无任务")
                                        .font(.vt(size: 14))
                                        .foregroundColor(appState.mutedColor)
                                }
                            }
                            .padding(.vertical, 40)
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(tasks) { task in
                                    taskItem(task)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .background(appState.bgColor)
            }
            .background(appState.bgColor)
            .navigationBarHidden(true)
        }
        .onAppear {
            startAutoRefresh()
            Task { await loadTasks() }
        }
        .onDisappear {
            stopAutoRefresh()
        }
    }
    
    private func tabButton(title: String, index: Int) -> some View {
        Button(action: {
            selectedList = index
            Task { await loadTasks() }
        }) {
            Text(title)
                .font(.vt(size: 14))
                .fontWeight(.medium)
                .foregroundColor(selectedList == index ? .vtAccent : appState.mutedColor)
                .padding(.horizontal, 18)
                .padding(.vertical, 7)
                .background(selectedList == index ? Color.vtAccent.opacity(0.14) : appState.cardColor)
                .cornerRadius(999)
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(selectedList == index ? Color.vtAccent.opacity(0.45) : appState.borderColor, lineWidth: 1)
                )
        }
    }
    
    private func taskItem(_ task: DownloadTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(task.bookTitle)
                            .font(.vt(size: 14))
                            .fontWeight(.semibold)
                            .foregroundColor(appState.textColor)
                            .lineLimit(1)
                        Text(task.bookId)
                            .font(.vt(size: 11))
                            .foregroundColor(appState.mutedColor)
                    }
                    Text(task.format.uppercased())
                        .font(.vt(size: 12))
                        .foregroundColor(appState.mutedColor)
                }
                Spacer()
                statusBadge(task.state)
            }
            
            // 进度条
            if task.state == .running {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: Double(task.progress ?? 0), total: 100)
                        .tint(.vtAccent)
                    if let total = task.totalChapters, let downloaded = task.downloadedChapters {
                        Text("\(downloaded)/\(total) 章")
                            .font(.vt(size: 11))
                            .foregroundColor(appState.mutedColor)
                    }
                }
            }
            
            // 错误信息
            if task.state == .failed, let error = task.error {
                Text(error)
                    .font(.vt(size: 12))
                    .foregroundColor(.vtRed)
                    .lineLimit(2)
            }
            
            // 下载按钮
            if task.state == .done {
                HStack {
                    if let url = task.downloadUrl, !url.isEmpty, task.expired != true {
                        Link(destination: URL(string: url)!) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                Text("下载文件")
                            }
                            .font(.vt(size: 13))
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "06120d"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.vtGreen)
                            .cornerRadius(8)
                        }
                    } else if task.expired == true {
                        Text("下载链接已过期")
                            .font(.vt(size: 12))
                            .foregroundColor(appState.mutedColor)
                    }
                    Spacer()
                }
            }
            
            // 提交者（全站列表）
            if selectedList == 1, let username = task.username {
                Divider()
                    .background(appState.borderColor)
                Text("提交者: \(username)")
                    .font(.vt(size: 11))
                    .foregroundColor(appState.mutedColor)
            }
        }
        .padding(14)
        .background(appState.cardColor)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(appState.borderColor, lineWidth: 1)
        )
    }
    
    private func statusBadge(_ status: TaskStatus) -> some View {
        let color: Color
        switch status {
        case .queued: color = .vtAmber
        case .running: color = .vtAccent
        case .done: color = .vtGreen
        case .failed, .canceled: color = .vtRed
        }
        
        return Text(status.displayName)
            .font(.vt(size: 11))
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(color.opacity(0.14))
            .cornerRadius(999)
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )
    }
    
    private func startAutoRefresh() {
        stopAutoRefresh()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task { await loadTasks() }
        }
    }
    
    private func stopAutoRefresh() {
        timer?.invalidate()
        timer = nil
    }
    
    private func loadTasks() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await APIService.shared.fetchTasks()
            let allItems = response.items ?? []
            await MainActor.run {
                appState.runningCount = response.running ?? 0
                appState.queuedCount = response.queued ?? 0
                // 我的任务：按用户名过滤
                if let currentUser = appState.currentUser {
                    myTasks = allItems.filter {
                        $0.username?.lowercased() == currentUser.username.lowercased()
                    }
                } else {
                    myTasks = []
                }
                // 全站任务：只显示未完成的
                allTasks = allItems.filter { $0.state != .done }
            }
        } catch {
            print("加载任务失败: \(error)")
        }
    }
}
