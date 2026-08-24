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
        
        // 非 2xx 状态码，先尝试解析通用错误结构
        if !(200...299).contains(httpResponse.statusCode) {
            if let errorResp = try? JSONDecoder().decode(BasicResponse.self, from: data),
               let errorMsg = errorResp.error, !errorMsg.isEmpty {
                throw APIError.httpStatus(httpResponse.statusCode, errorMsg)
            }
            throw APIError.httpStatus(httpResponse.statusCode, "服务器错误 (\(httpResponse.statusCode))")
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
    
    // 获取纯文本/HTML 响应
    func requestString(_ path: String, method: String = "GET") async throws -> String {
        guard let url = URL(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }
        
        guard let text = String(data: data, encoding: .utf8) else {
            throw APIError.decodeError(NSError(domain: "APIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法解码文本"]))
        }
        
        return text
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
    func fetchTasks(bookId: String? = nil) async throws -> TaskListResponse {
        if let bookId = bookId, !bookId.isEmpty {
            let encoded = bookId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? bookId
            return try await request("/api/tasks?book_id=\(encoded)")
        }
        return try await request("/api/tasks")
    }
    
    func submitTask(bookId: String, format: String) async throws -> SubmitResponse {
        return try await request("/api/tasks", method: "POST", body: ["book_id": bookId, "format": format])
    }
    
    // 查找可复用的 epub 任务（同一本书同一格式），直接按 book_id 查，不受50条限制
    func findReusableTask(bookId: String) async throws -> Int? {
        let tasks = try await fetchTasks(bookId: bookId)
        // 优先复用已完成的 epub 任务（有完整章节索引）
        if let done = tasks.items?.first(where: { $0.format?.lowercased() == "epub" && $0.state == .done }) {
            return done.id
        }
        // 其次复用进行中的 epub 任务
        if let active = tasks.items?.first(where: { $0.format?.lowercased() == "epub" && ($0.state == .queued || $0.state == .running) }) {
            return active.id
        }
        return nil
    }
    
    // 取消任务
    func cancelTask(taskId: Int) async {
        _ = try? await request("/api/tasks/\(taskId)", method: "DELETE") as BasicResponse
    }
    
    // MARK: - 在线阅读
    func fetchBookMeta(taskId: Int) async throws -> BookMeta {
        return try await request("/api/book/\(taskId)/meta")
    }
    
    func fetchChapters(taskId: Int) async throws -> [Chapter] {
        return try await request("/api/book/\(taskId)/chapters")
    }
    
    func fetchChapterContent(taskId: Int, index: Int) async throws -> String {
        return try await requestString("/api/book/\(taskId)/chapter/\(index)")
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
    case httpStatus(Int, String)  // 带状态码的错误，用于区分404/500等
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的URL"
        case .invalidResponse: return "无效的响应"
        case .unauthorized: return "未登录或登录已过期"
        case .decodeError(let e): return "数据解析失败: \(e.localizedDescription)"
        case .serverError(let msg): return msg
        case .httpStatus(_, let msg): return msg
        }
    }
}
