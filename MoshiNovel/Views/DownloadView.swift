import SwiftUI
import UIKit

struct DownloadView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showLogin: Bool
    @State private var selectedList = 0 // 0=我的, 1=全站
    @State private var myTasks: [DownloadTask] = []
    @State private var allTasks: [DownloadTask] = []
    @State private var isLoading = false
    @State private var timer: Timer?
    @State private var downloadingTaskId: Int?
    @State private var downloadProgress: Double = 0
    
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
                        Text(task.title ?? "未知书籍")
                            .font(.vt(size: 14))
                            .fontWeight(.semibold)
                            .foregroundColor(appState.textColor)
                            .lineLimit(1)
                        Text(task.bookId ?? "")
                            .font(.vt(size: 11))
                            .foregroundColor(appState.mutedColor)
                    }
                    if let author = task.author, !author.isEmpty {
                        Text(author)
                            .font(.vt(size: 11))
                            .foregroundColor(appState.mutedColor)
                    }
                    Text(task.format?.uppercased() ?? "")
                        .font(.vt(size: 12))
                        .foregroundColor(appState.mutedColor)
                }
                Spacer()
                statusBadge(task.state ?? .queued)
            }
            
            // 进度条
            if task.state == .running, let progress = task.progress {
                VStack(alignment: .leading, spacing: 4) {
                    let total = progress.chapterTotal ?? 0
                    let done = progress.savedChapters ?? 0
                    let pct = total > 0 ? Double(done) / Double(total) : 0
                    ProgressView(value: pct)
                        .tint(.vtAccent)
                    let label = progress.phase == "audiobook" ? "生成音频中 \(done)/\(total)" : "已下载 \(done)/\(total) 章"
                    Text(label)
                        .font(.vt(size: 11))
                        .foregroundColor(appState.mutedColor)
                }
            }
            
            // 排队位置
            if task.state == .queued, let position = task.position, position > 0 {
                Text("排队中 · 第 \(position) 位")
                    .font(.vt(size: 11))
                    .foregroundColor(appState.mutedColor)
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
                    if let urlStr = task.downloadUrl, !urlStr.isEmpty, task.expired != true {
                        if downloadingTaskId == task.id {
                            // 下载中
                            VStack(alignment: .leading, spacing: 4) {
                                ProgressView(value: downloadProgress)
                                    .tint(.vtGreen)
                                Text("正在下载... \(Int(downloadProgress * 100))%")
                                    .font(.vt(size: 11))
                                    .foregroundColor(appState.mutedColor)
                            }
                        } else {
                            Button(action: {
                                Task { await downloadFile(task: task, urlStr: urlStr) }
                            }) {
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
    
    private func downloadFile(task: DownloadTask, urlStr: String) async {
        // 处理相对路径
        let fullUrl: String
        if urlStr.hasPrefix("http") {
            fullUrl = urlStr
        } else {
            fullUrl = "https://morax.kdns.fr" + (urlStr.hasPrefix("/") ? urlStr : "/" + urlStr)
        }
        
        guard let url = URL(string: fullUrl) else {
            print("无效的下载链接: \(fullUrl)")
            return
        }
        
        await MainActor.run {
            downloadingTaskId = task.id
            downloadProgress = 0
        }
        
        defer {
            Task { @MainActor in
                downloadingTaskId = nil
            }
        }
        
        do {
            // 下载文件
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("下载失败: HTTP 状态码错误")
                return
            }
            
            // 保存到临时文件
            let fileName = url.lastPathComponent.isEmpty ? "download.\(task.format ?? "txt")" : url.lastPathComponent
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            
            print("下载完成: \(fileURL.path), 大小: \(data.count) 字节")
            
            // 弹出分享/保存面板
            await MainActor.run {
                let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
                
                // 获取当前窗口的 rootViewController
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    // iPad 需要设置 popoverPresentationController
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = rootVC.view
                        popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                        popover.permittedArrowDirections = []
                    }
                    rootVC.present(activityVC, animated: true)
                }
            }
            
        } catch {
            print("下载失败: \(error)")
        }
    }
}
