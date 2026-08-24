import SwiftUI
import WebKit

// HTML 渲染视图
struct HTMLView: UIViewRepresentable {
    let html: String
    let isDayMode: Bool
    let fontSize: CGFloat
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let bgColor = isDayMode ? "#ffffff" : "#0f1117"
        let textColor = isDayMode ? "#1f2430" : "#e6e9f0"
        let linkColor = "#4f8cff"
        
        // 提取 body 内容，避免整页 HTML 冲突
        let bodyMatch = html.range(of: "<body[^>]*>([\\s\\S]*)</body>", options: .regularExpression)
        let content: String
        if let match = bodyMatch {
            content = String(html[match])
        } else {
            content = html
        }
        
        let wrappedHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    background-color: \(bgColor);
                    color: \(textColor);
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                    font-size: \(fontSize)px;
                    line-height: 1.8;
                    padding: 16px;
                    margin: 0;
                }
                h1, h2, h3 { color: \(textColor); margin-top: 20px; }
                p { margin-bottom: 16px; }
                a { color: \(linkColor); }
                img { max-width: 100%; height: auto; }
            </style>
        </head>
        <body>
            \(content)
        </body>
        </html>
        """
        
        webView.loadHTMLString(wrappedHTML, baseURL: nil)
    }
}

// 在线阅读视图
struct ReaderView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) private var presentationMode
    let taskId: Int
    @State private var bookMeta: BookMeta?
    @State private var chapters: [Chapter] = []
    @State private var currentIndex = 0
    @State private var chapterContent = ""
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showToc = false
    @State private var fontSize: CGFloat = 17
    @State private var pollingTimer: Timer?
    @State private var showUI = true
    
    var body: some View {
        ZStack {
            appState.bgColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 顶部导航栏
                topBar
                    .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0)
                
                // 下载进度提示
                if let meta = bookMeta, meta.downloading == true {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                            .foregroundColor(.vtAmber)
                        Text("下载中，已可阅读前 \(meta.chapterCount ?? 0) 章 / 共 \(meta.total ?? 0) 章")
                            .font(.vt(size: 12))
                            .foregroundColor(.vtAmber)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.vtAmber.opacity(0.08))
                }
                
                // 内容区
                if isLoading {
                    Spacer()
                    ProgressView("加载中...")
                        .foregroundColor(appState.textColor)
                    Spacer()
                } else if !errorMessage.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Text(errorMessage)
                            .font(.vt(size: 14))
                            .foregroundColor(.vtRed)
                            .multilineTextAlignment(.center)
                        Button("重试") {
                            Task { await loadChapter(currentIndex) }
                        }
                        .font(.vt(size: 14))
                        .foregroundColor(.vtAccent)
                    }
                    .padding()
                    Spacer()
                } else {
                    HTMLView(html: chapterContent, isDayMode: appState.isDayMode, fontSize: fontSize)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                // 底部控制栏
                bottomBar
                    .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $showToc) {
            tocView
                .environmentObject(appState)
        }
        .onAppear {
            // 隐藏底部 TabBar
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                findTabBar(in: window)?.isHidden = true
            }
            Task { await initReader() }
        }
        .onDisappear {
            // 恢复底部 TabBar
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                findTabBar(in: window)?.isHidden = false
            }
            pollingTimer?.invalidate()
            pollingTimer = nil
        }
    }
    
    // MARK: - 顶部栏
    private var topBar: some View {
        HStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.vt(size: 16))
                    .foregroundColor(appState.textColor)
            }
            
            Text(bookMeta?.title ?? "在线阅读")
                .font(.vt(size: 16))
                .fontWeight(.semibold)
                .foregroundColor(appState.textColor)
                .lineLimit(1)
            
            Spacer()
            
            Button(action: { showToc = true }) {
                Image(systemName: "list.bullet")
                    .font(.vt(size: 16))
                    .foregroundColor(appState.textColor)
            }
            
            Button(action: {
                fontSize = fontSize >= 22 ? 14 : fontSize + 2
            }) {
                Text("A")
                    .font(.vt(size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(appState.textColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(appState.cardColor)
    }
    
    // MARK: - 底部栏
    private var bottomBar: some View {
        HStack {
            Button(action: {
                if currentIndex > 0 {
                    currentIndex -= 1
                    Task { await loadChapter(currentIndex) }
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("上一章")
                }
                .font(.vt(size: 14))
                .foregroundColor(currentIndex > 0 ? .vtAccent : appState.mutedColor.opacity(0.4))
            }
            
            Spacer()
            
            Text("\(currentIndex + 1) / \(chapters.count)")
                .font(.vt(size: 13))
                .foregroundColor(appState.mutedColor)
            
            Spacer()
            
            Button(action: {
                if currentIndex < chapters.count - 1 {
                    currentIndex += 1
                    Task { await loadChapter(currentIndex) }
                }
            }) {
                HStack(spacing: 4) {
                    Text("下一章")
                    Image(systemName: "chevron.right")
                }
                .font(.vt(size: 14))
                .foregroundColor(currentIndex < chapters.count - 1 ? .vtAccent : appState.mutedColor.opacity(0.4))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(appState.cardColor)
    }
    
    // MARK: - 目录视图
    private var tocView: some View {
        NavigationView {
            List {
                ForEach(Array(chapters.enumerated()), id: \.element.id) { index, chapter in
                    Button(action: {
                        currentIndex = index
                        showToc = false
                        Task { await loadChapter(index) }
                    }) {
                        HStack {
                            Text(chapter.title)
                                .font(.vt(size: 14))
                                .foregroundColor(index == currentIndex ? .vtAccent : appState.textColor)
                            Spacer()
                            if index == currentIndex {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.vtAccent)
                            }
                        }
                    }
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("目录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { showToc = false }
                }
            }
        }
    }
    
    // MARK: - 初始化
    private func initReader() async {
        isLoading = true
        errorMessage = ""
        
        do {
            // 轮询 meta，直到任务开始下载
            for attempt in 0..<40 {
                do {
                    let meta = try await APIService.shared.fetchBookMeta(taskId: taskId)
                    bookMeta = meta
                    break
                } catch {
                    // 404 表示任务还在排队，继续轮询
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    continue
                }
            }
            
            guard bookMeta != nil else {
                errorMessage = "任务加载超时，请稍后重试"
                isLoading = false
                return
            }
            
            // 加载章节列表
            let loadedChapters = try await APIService.shared.fetchChapters(taskId: taskId)
            
            // 按章节数字排序（服务器返回的顺序可能混乱）
            chapters = sortChapters(loadedChapters)
            
            if chapters.isEmpty {
                errorMessage = "暂无章节"
                isLoading = false
                return
            }
            
            // 加载第一章
            await loadChapter(0)
            
            // 开始轮询进度
            startProgressPolling()
            
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // MARK: - 加载章节
    private func loadChapter(_ index: Int) async {
        guard index >= 0 && index < chapters.count else { return }
        
        isLoading = true
        errorMessage = ""
        
        do {
            let html = try await APIService.shared.fetchChapterContent(taskId: taskId, index: index)
            chapterContent = html
            isLoading = false
        } catch {
            errorMessage = "本章尚未下载完成，请等待下载继续后重试"
            isLoading = false
        }
    }
    
    // MARK: - 轮询进度
    private func startProgressPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            Task {
                do {
                    let meta = try await APIService.shared.fetchBookMeta(taskId: taskId)
                    await MainActor.run {
                        bookMeta = meta
                    }
                    // 重新加载章节列表（可能有新章节缓存完成）
                    let newChapters = try await APIService.shared.fetchChapters(taskId: taskId)
                    let sortedChapters = sortChapters(newChapters)
                    await MainActor.run {
                        if sortedChapters.count > chapters.count {
                            chapters = sortedChapters
                        }
                    }
                } catch {
                    // 忽略轮询错误
                }
            }
        }
    }
}

// 遍历视图查找 UITabBar
func findTabBar(in view: UIView) -> UITabBar? {
    for subview in view.subviews {
        if let tabBar = subview as? UITabBar {
            return tabBar
        }
        if let found = findTabBar(in: subview) {
            return found
        }
    }
    return nil
}

// 按章节数字排序，提取不到数字的保持原顺序排在后面
func sortChapters(_ chapters: [Chapter]) -> [Chapter] {
    return chapters.enumerated().sorted { a, b in
        let numA = extractChapterNumber(from: a.element.title) ?? Int.max
        let numB = extractChapterNumber(from: b.element.title) ?? Int.max
        if numA == numB {
            return a.offset < b.offset
        }
        return numA < numB
    }.map { $0.element }
}

// 从章节标题中提取数字，例如 "第1684章 xxx" -> 1684
func extractChapterNumber(from title: String) -> Int? {
    let pattern = "第(\\d+)章"
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
          let match = regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)),
          let range = Range(match.range(at: 1), in: title) else {
        return nil
    }
    return Int(title[range])
}
