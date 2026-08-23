import Foundation

class APIService {
    static let shared = APIService()
    
    // 服务器地址 - 摩柿小说下载站
    private let baseURL = "https://morax.kdns.fr"
    
    // 使用共享 session
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - 通用请求
    private func request<T: Codable>(_ path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> T {
        let urlString = "\(baseURL)\(path)"
        guard let url = URL(string: urlString) else {
            print("[API] 无效URL: \(urlString)")
            throw APIError.invalidURL
        }
        
        print("[API] 请求: \(method) \(urlString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            print("[API] 请求体: \(String(data: request.httpBody!, encoding: .utf8) ?? "")")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("[API] 无效响应")
            throw APIError.invalidResponse
        }
        
        print("[API] 响应状态码: \(httpResponse.statusCode)")
        print("[API] 响应数据: \(String(data: data, encoding: .utf8) ?? "(空)")")
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        let decoder = JSONDecoder()
        // 注意：不使用 convertFromSnakeCase，所有模型都用自定义 CodingKeys 显式映射
        
        do {
            let result = try decoder.decode(T.self, from: data)
            print("[API] 解码成功")
            return result
        } catch {
            print("[API] 解码失败: \(error)")
            print("[API] 原始数据: \(String(data: data, encoding: .utf8) ?? "")")
            throw APIError.decodeError(error)
        }
    }
    
    // MARK: - 站点信息
    func fetchSiteConfig() async throws -> SiteConfig {
        return try await request("/api/site")
    }
    
    // MARK: - 用户
    func fetchMe() async throws -> User? {
        let response: MeResponse = try await request("/api/me")
        return response.user
    }
    
    func login(username: String, password: String) async throws -> LoginResponse {
        return try await request("/api/login", method: "POST", body: ["username": username, "password": password])
    }
    
    func register(username: String, password: String) async throws -> LoginResponse {
        return try await request("/api/register", method: "POST", body: ["username": username, "password": password])
    }
    
    func logout() async {
        _ = try? await request("/api/logout", method: "POST", body: [:]) as BasicResponse
    }
    
    // MARK: - 搜索
    func searchBooks(_ query: String) async throws -> [SearchResult] {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let response: SearchResponse = try await request("/api/search?q=\(encoded)")
        return response.items ?? []
    }
    
    // MARK: - 任务
    func fetchTasks(list: String = "mine") async throws -> TaskListResponse {
        return try await request("/api/tasks?list=\(list)")
    }
    
    func submitTask(bookId: String, format: String) async throws -> SubmitResponse {
        return try await request("/api/submit", method: "POST", body: ["book_id": bookId, "format": format])
    }
    
    // MARK: - 管理
    func fetchUsers() async throws -> [User] {
        let response: UserListResponse = try await request("/api/admin/users")
        return response.items ?? []
    }
    
    func setUserTitle(username: String, title: String) async throws {
        _ = try await request("/api/admin/set-title", method: "POST", body: ["username": username, "title": title]) as BasicResponse
    }
    
    func deleteUser(username: String) async throws {
        _ = try await request("/api/admin/delete-user", method: "POST", body: ["username": username]) as BasicResponse
    }
    
    func clearRecords() async throws {
        _ = try await request("/api/admin/clear", method: "POST", body: [:]) as BasicResponse
    }
    
    // MARK: - 管理员信息和设置
    func fetchAdminInfo() async throws -> AdminInfo {
        return try await request("/api/admin/info")
    }
    
    func fetchAdminSettings() async throws -> AdminSettings {
        return try await request("/api/admin/settings")
    }
    
    func saveAdminSettings(_ settings: [String: Any]) async throws -> BasicResponse {
        return try await request("/api/admin/settings", method: "POST", body: settings)
    }
    
    func createUser(username: String, password: String) async throws -> BasicResponse {
        return try await request("/api/admin/create-user", method: "POST", body: ["username": username, "password": password])
    }
    
    func setUserPassword(username: String, password: String) async throws -> BasicResponse {
        return try await request("/api/admin/set-password", method: "POST", body: ["username": username, "password": password])
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case decodeError(Error)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的URL"
        case .invalidResponse: return "无效的响应"
        case .unauthorized: return "未登录或登录已过期"
        case .decodeError(let e): return "数据解析失败: \(e.localizedDescription)"
        case .serverError(let msg): return msg
        }
    }
}
