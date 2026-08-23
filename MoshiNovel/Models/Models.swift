import Foundation

// MARK: - 站点配置
struct SiteConfig: Codable {
    let siteTitle: String?
    let siteOwner: String?
    let notice: String?
    let disabled: Bool?
    let version: String?
    
    enum CodingKeys: String, CodingKey {
        case siteTitle = "site_title"
        case siteOwner = "site_owner"
        case notice, disabled, version
    }
}

// MARK: - 用户
struct User: Codable, Identifiable {
    let id: String
    let username: String
    let isAdmin: Bool?
    let title: String?
    
    enum CodingKeys: String, CodingKey {
        case id, username
        case isAdmin = "is_admin"
        case title
    }
}

// MARK: - 搜索结果
struct SearchResult: Codable, Identifiable {
    let id: String
    let title: String
    let author: String?
    let cover: String?
    let intro: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "book_id"
        case title, author, cover, intro
    }
}

// MARK: - 下载任务
struct DownloadTask: Codable, Identifiable {
    let id: String
    let bookId: String
    let bookTitle: String
    let format: String
    let status: TaskStatus
    let progress: Int?
    let totalChapters: Int?
    let downloadedChapters: Int?
    let downloadUrl: String?
    let error: String?
    let createdAt: TimeInterval?
    let username: String?
    let expired: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case bookId = "book_id"
        case bookTitle = "book_title"
        case format, status, progress
        case totalChapters = "total_chapters"
        case downloadedChapters = "downloaded_chapters"
        case downloadUrl = "download_url"
        case error
        case createdAt = "created_at"
        case username, expired
    }
}

enum TaskStatus: String, Codable {
    case queued = "queued"
    case running = "running"
    case done = "done"
    case failed = "failed"
    case canceled = "canceled"
    
    var displayName: String {
        switch self {
        case .queued: return "排队中"
        case .running: return "下载中"
        case .done: return "已完成"
        case .failed: return "失败"
        case .canceled: return "已取消"
        }
    }
}

// MARK: - API 响应
struct APIResponse<T: Codable>: Codable {
    let ok: Bool?
    let error: String?
    let data: T?
}

struct LoginResponse: Codable {
    let ok: Bool?
    let error: String?
    let user: User?
    let token: String?
}

struct TaskListResponse: Codable {
    let items: [DownloadTask]?
    let running: Int?
    let queued: Int?
}

struct SearchResponse: Codable {
    let items: [SearchResult]?
}
