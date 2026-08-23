import SwiftUI

struct SearchView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showLogin: Bool
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var searchError: String = ""
    @State private var isSearching = false
    @State private var selectedBook: SearchResult?
    @State private var showFormatModal = false
    @State private var searchTask: Task<Void, Never>?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // 顶部标题栏
                    headerView
                    
                    // 搜索框
                    searchBar
                    
                    // 内容区
                    if searchText.isEmpty {
                        homeView
                    } else {
                        searchResultsView
                    }
                }
                .padding()
            }
            .background(appState.bgColor)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showFormatModal) {
            if let book = selectedBook {
                FormatSelectView(book: book) {
                    showFormatModal = false
                }
                .environmentObject(appState)
            }
        }
    }
    
    // MARK: - 顶部标题
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(appState.siteConfig?.siteTitle ?? "摩柿小说下载站")
                    .font(.vt(size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(appState.textColor)
                Text("搜索书名或粘贴分享链接，排队自动下载")
                    .font(.vt(size: 12))
                    .foregroundColor(appState.mutedColor)
            }
            Spacer()
            // 状态标签
            HStack(spacing: 6) {
                statusPill(text: "下载中 \(appState.runningCount)", color: .vtAccent)
                statusPill(text: "排队 \(appState.queuedCount)", color: .vtAmber)
            }
        }
    }
    
    private func statusPill(text: String, color: Color) -> some View {
        Text(text)
            .font(.vt(size: 11))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.14))
            .cornerRadius(999)
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(color.opacity(0.4), lineWidth: 1)
            )
    }
    
    // MARK: - 搜索框
    private var searchBar: some View {
        HStack {
            TextField("搜索书名，或粘贴分享链接 / 书籍 ID", text: $searchText)
                .font(.vt(size: 15))
                .foregroundColor(appState.textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(appState.cardColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(appState.borderColor, lineWidth: 1)
                )
                .onChange(of: searchText) { newValue in
                    searchTask?.cancel()
                    guard !newValue.isEmpty else {
                        searchResults = []
                        return
                    }
                    searchTask = Task {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        await performSearch(newValue)
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchResults = []
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(appState.mutedColor)
                }
            }
        }
    }
    
    // MARK: - 首页内容
    private var homeView: some View {
        VStack(spacing: 20) {
            // 欢迎语
            VStack(alignment: .leading, spacing: 8) {
                Text(greetingText)
                    .font(.vt(size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(appState.textColor)
                
                if !appState.isLoggedIn {
                    Button(action: { showLogin = true }) {
                        Text("登录")
                            .font(.vt(size: 14))
                            .foregroundColor(appState.textColor)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(appState.cardColor)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(appState.borderColor, lineWidth: 1)
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)
            
            // 公告
            if let notice = appState.siteConfig?.siteNotice, !notice.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("公告")
                            .font(.vt(size: 15))
                            .fontWeight(.semibold)
                            .foregroundColor(appState.textColor)
                        Spacer()
                    }
                    Text(notice)
                        .font(.vt(size: 13))
                        .foregroundColor(appState.textColor)
                        .lineSpacing(4)
                }
                .padding(16)
                .background(appState.cardColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.vtGreen.opacity(0.45), lineWidth: 1)
                )
            }
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if appState.isLoggedIn, let name = appState.currentUser?.username {
            if hour < 6 { return "夜深了，\(name)" }
            if hour < 12 { return "早上好，\(name)" }
            if hour < 14 { return "中午好，\(name)" }
            if hour < 18 { return "下午好，\(name)" }
            return "晚上好，\(name)"
        }
        if hour < 6 { return "夜深了" }
        if hour < 12 { return "早上好" }
        if hour < 14 { return "中午好" }
        if hour < 18 { return "下午好" }
        return "晚上好"
    }
    
    // MARK: - 搜索结果
    private var searchResultsView: some View {
        VStack(spacing: 8) {
            if isSearching {
                ProgressView()
                    .padding()
            } else if !searchError.isEmpty {
                VStack(spacing: 8) {
                    Text("搜索出错")
                        .font(.vt(size: 14))
                        .foregroundColor(.vtRed)
                    Text(searchError)
                        .font(.vt(size: 12))
                        .foregroundColor(appState.mutedColor)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if searchResults.isEmpty {
                Text("未找到相关书籍")
                    .font(.vt(size: 14))
                    .foregroundColor(appState.mutedColor)
                    .padding()
            } else {
                ForEach(searchResults) { book in
                    resultItem(book)
                }
            }
        }
    }
    
    private func resultItem(_ book: SearchResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.vt(size: 14))
                    .fontWeight(.semibold)
                    .foregroundColor(appState.textColor)
                    .lineLimit(1)
                if let author = book.author {
                    Text(author)
                        .font(.vt(size: 12))
                        .foregroundColor(appState.mutedColor)
                }
                Text(book.id)
                    .font(.vt(size: 10))
                    .foregroundColor(appState.mutedColor.opacity(0.7))
            }
            Spacer()
            Button(action: {
                guard appState.isLoggedIn else {
                    showLogin = true
                    return
                }
                selectedBook = book
                showFormatModal = true
            }) {
                Text("下载")
                    .font(.vt(size: 12))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.vtAccent)
                    .cornerRadius(6)
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
    
    private func performSearch(_ query: String) async {
        isSearching = true
        searchError = ""
        defer { isSearching = false }
        
        do {
            let results = try await APIService.shared.searchBooks(query)
            // 检查是否已取消或 query 已变化，防止旧结果覆盖新结果
            if Task.isCancelled || query != searchText { return }
            await MainActor.run {
                self.searchResults = results
            }
        } catch {
            if Task.isCancelled { return }
            print("搜索失败: \(error)")
            await MainActor.run {
                self.searchError = error.localizedDescription
                self.searchResults = []
            }
        }
    }
}
