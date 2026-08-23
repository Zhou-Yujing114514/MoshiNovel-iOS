import SwiftUI

// MARK: - 主题颜色
extension Color {
    // 深色模式
    static let vtBg = Color(hex: "0f1117")
    static let vtCard = Color(hex: "171a23")
    static let vtBorder = Color(hex: "262b38")
    static let vtText = Color(hex: "e6e9f0")
    static let vtMuted = Color(hex: "8b93a7")
    static let vtAccent = Color(hex: "4f8cff")
    static let vtGreen = Color(hex: "34c98a")
    static let vtRed = Color(hex: "ff5c6c")
    static let vtAmber = Color(hex: "f5b64c")
    
    // 日间模式
    static let vtDayBg = Color(hex: "f5f5f0")
    static let vtDayCard = Color(hex: "ffffff")
    static let vtDayBorder = Color(hex: "e0e0e0")
    static let vtDayText = Color(hex: "333333")
    static let vtDayMuted = Color(hex: "666666")
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - 应用状态
class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var siteConfig: SiteConfig?
    @Published var isLoggedIn = false
    @Published var isDayMode = false
    @Published var runningCount = 0
    @Published var queuedCount = 0
    
    static let shared = AppState()
    
    private init() {
        // 读取主题偏好
        isDayMode = UserDefaults.standard.bool(forKey: "moshi_day_mode")
    }
    
    func setUser(_ user: User?) {
        currentUser = user
        isLoggedIn = user != nil
    }
    
    func toggleDayMode() {
        isDayMode.toggle()
        UserDefaults.standard.set(isDayMode, forKey: "moshi_day_mode")
    }
    
    var bgColor: Color { isDayMode ? .vtDayBg : .vtBg }
    var cardColor: Color { isDayMode ? .vtDayCard : .vtCard }
    var borderColor: Color { isDayMode ? .vtDayBorder : .vtBorder }
    var textColor: Color { isDayMode ? .vtDayText : .vtText }
    var mutedColor: Color { isDayMode ? .vtDayMuted : .vtMuted }
}

// MARK: - 字体
extension Font {
    static func vt(size: CGFloat) -> Font {
        let multiplier = UserDefaults.standard.double(forKey: "moshi_font_scale")
        let scale = multiplier > 0 ? multiplier : 1.0
        return .system(size: size * scale)
    }
}
