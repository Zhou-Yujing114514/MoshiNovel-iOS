import SwiftUI

struct MineView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showLogin: Bool
    @Binding var showRegister: Bool
    @State private var showAbout = false
    @State private var showAdmin = false
    @State private var showFeedback = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    if appState.isLoggedIn {
                        loggedInView
                    } else {
                        loggedOutView
                    }
                }
                .padding()
                .padding(.top, 30)
            }
            .background(appState.bgColor)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showAdmin) {
            AdminView()
                .environmentObject(appState)
        }
        .alert("反馈问题", isPresented: $showFeedback) {
            Button("我确认", role: .default) {
                if let url = URL(string: "https://buer.kdns.fr") {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("您将进入本站的同级网站，此站专注于聊天和反馈问题。账号密码并不同步，当您第一次进入时，请务必注册一个新账号，并牢牢记住您的账户和密码。")
        }
    }
    
    private var loggedOutView: some View {
        VStack(spacing: 14) {
            Text("请先登录")
                .font(.vt(size: 16))
                .foregroundColor(appState.mutedColor)
            
            Button(action: { showLogin = true }) {
                Text("登录 / 注册")
                    .font(.vt(size: 15))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.vtAccent)
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 60)
    }
    
    private var loggedInView: some View {
        VStack(spacing: 12) {
            // 用户信息
            VStack(spacing: 4) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.vtAccent)
                Text(appState.currentUser?.username ?? "用户")
                    .font(.vt(size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(appState.textColor)
                if let title = appState.currentUser?.title, !title.isEmpty {
                    Text(title)
                        .font(.vt(size: 12))
                        .foregroundColor(.vtAmber)
                }
            }
            .padding(.vertical, 20)
            
            // 功能按钮
            if appState.currentUser?.isAdmin == true {
                menuButton(title: "管理", icon: "gearshape.fill", color: .vtAmber) {
                    showAdmin = true
                }
            }
            
            menuButton(title: "关于本站", icon: "info.circle.fill", color: .vtAccent) {
                showAbout = true
            }
            
            menuButton(title: "反馈问题", icon: "exclamationmark.bubble.fill", color: .vtGreen) {
                showFeedback = true
            }
            
            menuButton(title: "日间/夜间模式", icon: appState.isDayMode ? "moon.fill" : "sun.max.fill", color: .vtAccent) {
                appState.toggleDayMode()
            }
            
            menuButton(title: "退出登录", icon: "rectangle.portrait.and.arrow.right", color: .vtRed) {
                Task {
                    await APIService.shared.logout()
                    await MainActor.run {
                        appState.setUser(nil)
                    }
                }
            }
            
            Spacer(minLength: 20)
            
            // 页脚
            VStack(spacing: 4) {
                Text(appState.siteConfig?.siteOwner ?? "本站站长：黑厄势力")
                    .font(.vt(size: 11))
                    .foregroundColor(appState.mutedColor)
                    .multilineTextAlignment(.center)
                Text("下载内容仅供个人学习研究使用")
                    .font(.vt(size: 10))
                    .foregroundColor(appState.mutedColor.opacity(0.7))
            }
            .padding(.top, 20)
        }
    }
    
    private func menuButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .frame(width: 24)
                Text(title)
                    .font(.vt(size: 15))
                    .foregroundColor(appState.textColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(appState.mutedColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(appState.cardColor)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(appState.borderColor, lineWidth: 1)
            )
        }
    }
}

// MARK: - 关于视图
struct AboutView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Image(systemName: "book.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.vtAccent)
                    .padding(.top, 40)
                
                Text(appState.siteConfig?.siteTitle ?? "摩柿小说下载站")
                    .font(.vt(size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(appState.textColor)
                
                VStack(spacing: 8) {
                    aboutRow(label: "版本号", value: appState.siteConfig?.version ?? "v1.0.0")
                    aboutRow(label: "联系方式", value: "QQ 941029753")
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
            }
            .background(appState.bgColor)
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundColor(appState.mutedColor)
                        .padding(16)
                }
            }
        }
    }
    
    private func aboutRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.vt(size: 14))
                .foregroundColor(appState.mutedColor)
            Spacer()
            Text(value)
                .font(.vt(size: 14))
                .foregroundColor(appState.textColor)
        }
        .padding(.vertical, 6)
    }
}
