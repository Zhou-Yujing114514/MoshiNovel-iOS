import SwiftUI

@main
struct MoshiNovelApp: App {
    @StateObject private var appState = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.isDayMode ? .light : .dark)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var showLogin = false
    @State private var showRegister = false
    
    var body: some View {
        ZStack {
            appState.bgColor.ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                SearchView(showLogin: $showLogin)
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("搜索")
                    }
                    .tag(0)
                
                DownloadView(showLogin: $showLogin)
                    .tabItem {
                        Image(systemName: "arrow.down.circle")
                        Text("下载")
                    }
                    .tag(1)
                
                MineView(showLogin: $showLogin, showRegister: $showRegister)
                    .tabItem {
                        Image(systemName: "person")
                        Text("我的")
                    }
                    .tag(2)
            }
            .accentColor(.vtAccent)
            .onAppear {
                updateTabBarAppearance()
            }
            .onChange(of: appState.isDayMode) { _ in
                updateTabBarAppearance()
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView(showLogin: $showLogin, showRegister: $showRegister)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showRegister) {
            RegisterView(showRegister: $showRegister, showLogin: $showLogin)
                .environmentObject(appState)
        }
        .task {
            await loadSiteConfig()
            await checkLogin()
        }
    }
    
    private func loadSiteConfig() async {
        do {
            let config = try await APIService.shared.fetchSiteConfig()
            appState.siteConfig = config
        } catch {
            print("加载站点配置失败: \(error)")
        }
    }
    
    private func checkLogin() async {
        do {
            if let user = try await APIService.shared.fetchMe() {
                appState.setUser(user)
            }
        } catch {
            print("检查登录状态失败: \(error)")
        }
    }
    
    private func updateTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(appState.cardColor)
        appearance.selectionIndicatorTintColor = UIColor(.vtAccent)
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor(appState.mutedColor)
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(appState.mutedColor)]
        itemAppearance.selected.iconColor = UIColor(.vtAccent)
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(.vtAccent)]
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(appState.mutedColor)
    }
}
