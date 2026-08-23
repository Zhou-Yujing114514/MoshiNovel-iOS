import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showLogin: Bool
    @Binding var showRegister: Bool
    @State private var username = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isLoading = false
    @State private var agreed = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Spacer()
                
                // 标题
                VStack(spacing: 4) {
                    Text("登录")
                        .font(.vt(size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(appState.textColor)
                }
                .padding(.bottom, 10)
                
                // 输入框
                TextField("用户名", text: $username)
                    .font(.vt(size: 15))
                    .foregroundColor(appState.textColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(appState.bgColor)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(appState.borderColor, lineWidth: 1)
                    )
                
                SecureField("密码", text: $password)
                    .font(.vt(size: 15))
                    .foregroundColor(appState.textColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(appState.bgColor)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(appState.borderColor, lineWidth: 1)
                    )
                
                // 消息
                if !message.isEmpty {
                    Text(message)
                        .font(.vt(size: 13))
                        .foregroundColor(.vtRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // 协议
                Button(action: { agreed.toggle() }) {
                    HStack(spacing: 8) {
                        Image(systemName: agreed ? "checkmark.square.fill" : "square")
                            .foregroundColor(agreed ? .vtAccent : appState.mutedColor)
                        Text("我已阅读并同意《用户协议》与《隐私政策》")
                            .font(.vt(size: 12))
                            .foregroundColor(appState.mutedColor)
                        Spacer()
                    }
                }
                
                // 登录按钮
                Button(action: {
                    Task { await doLogin() }
                }) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("登录")
                            .font(.vt(size: 15))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.vtAccent)
                .cornerRadius(8)
                .disabled(isLoading || !agreed)
                .opacity((isLoading || !agreed) ? 0.5 : 1)
                
                // 切换注册
                Button(action: {
                    showLogin = false
                    showRegister = true
                }) {
                    Text("没有账号？注册")
                        .font(.vt(size: 13))
                        .foregroundColor(.vtAccent)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .background(appState.cardColor)
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                Button(action: { showLogin = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(appState.mutedColor)
                        .padding(16)
                }
            }
        }
    }
    
    private func doLogin() async {
        guard !username.isEmpty, !password.isEmpty else {
            message = "请输入用户名和密码"
            return
        }
        
        isLoading = true
        message = ""
        defer { isLoading = false }
        
        do {
            let response = try await APIService.shared.login(username: username, password: password)
            if let user = response.user {
                await MainActor.run {
                    appState.setUser(user)
                    showLogin = false
                }
            } else {
                message = response.error ?? "登录失败"
            }
        } catch {
            message = error.localizedDescription
        }
    }
}

struct RegisterView: View {
    @EnvironmentObject var appState: AppState
    @Binding var showRegister: Bool
    @Binding var showLogin: Bool
    @State private var username = ""
    @State private var password = ""
    @State private var password2 = ""
    @State private var message = ""
    @State private var isLoading = false
    @State private var agreed = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 14) {
                Spacer()
                
                Text("注册")
                    .font(.vt(size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(appState.textColor)
                    .padding(.bottom, 10)
                
                TextField("用户名", text: $username)
                    .font(.vt(size: 15))
                    .foregroundColor(appState.textColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(appState.bgColor)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(appState.borderColor, lineWidth: 1)
                    )
                
                SecureField("密码（至少 4 位）", text: $password)
                    .font(.vt(size: 15))
                    .foregroundColor(appState.textColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(appState.bgColor)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(appState.borderColor, lineWidth: 1)
                    )
                
                SecureField("确认密码", text: $password2)
                    .font(.vt(size: 15))
                    .foregroundColor(appState.textColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(appState.bgColor)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(appState.borderColor, lineWidth: 1)
                    )
                
                if !message.isEmpty {
                    Text(message)
                        .font(.vt(size: 13))
                        .foregroundColor(.vtRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: { agreed.toggle() }) {
                    HStack(spacing: 8) {
                        Image(systemName: agreed ? "checkmark.square.fill" : "square")
                            .foregroundColor(agreed ? .vtAccent : appState.mutedColor)
                        Text("我已阅读并同意《用户协议》与《隐私政策》")
                            .font(.vt(size: 12))
                            .foregroundColor(appState.mutedColor)
                        Spacer()
                    }
                }
                
                Button(action: {
                    Task { await doRegister() }
                }) {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("注册")
                            .font(.vt(size: 15))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.vtAccent)
                .cornerRadius(8)
                .disabled(isLoading || !agreed)
                .opacity((isLoading || !agreed) ? 0.5 : 1)
                
                Button(action: {
                    showRegister = false
                    showLogin = true
                }) {
                    Text("已有账号？登录")
                        .font(.vt(size: 13))
                        .foregroundColor(.vtAccent)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .background(appState.cardColor)
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                Button(action: { showRegister = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundColor(appState.mutedColor)
                        .padding(16)
                }
            }
        }
    }
    
    private func doRegister() async {
        guard !username.isEmpty else { message = "请输入用户名"; return }
        guard password.count >= 4 else { message = "密码至少 4 位"; return }
        guard password == password2 else { message = "两次密码不一致"; return }
        
        isLoading = true
        message = ""
        defer { isLoading = false }
        
        do {
            let response = try await APIService.shared.register(username: username, password: password)
            if let user = response.user {
                await MainActor.run {
                    appState.setUser(user)
                    showRegister = false
                }
            } else {
                message = response.error ?? "注册失败"
            }
        } catch {
            message = error.localizedDescription
        }
    }
}
