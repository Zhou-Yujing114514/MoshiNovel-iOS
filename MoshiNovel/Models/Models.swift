import Foundation

// MARK: - 站点配置
struct SiteConfig: Codable {
    let siteTitle: String?
    let siteOwner: String?
    let siteNotice: String?
    let siteVersion: String?
    let disabled: Bool?
    let maintenance: Bool?
    
    enum CodingKeys: String, CodingKey {
        case siteTitle = "site_title"
        case siteOwner = "site_owner"
        case siteNotice = "site_notice"
        case siteVersion = "site_version"
        case disabled, maintenance
    }
}

// MARK: - 用户（用 username 作为唯一标识，服务器不返回 id）
struct User: Codable, Identifiable {
    var id: String { username }
    let username: String
    let isAdmin: Bool?
    let highRank: Bool?
    let title: String?
    let createdAt: TimeInterval?
    
    enum CodingKeys: String, CodingKey {
        case username
        case isAdmin = "is_admin"
        case highRank = "high_rank"
        case title
        case createdAt = "created_at"
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
struct LoginResponse: Codable {
    let ok: Bool?
    let error: String?
    let user: User?
    let token: String?
}

struct MeResponse: Codable {
    let user: User?
}

struct SubmitResponse: Codable {
    let ok: Bool?
    let error: String?
    let id: String?
}

struct BasicResponse: Codable {
    let ok: Bool?
    let error: String?
}

// MARK: - 管理员信息
struct AdminInfo: Codable {
    let queued: Int?
    let running: Int?
    let tasks: Int?
    let users: Int?
    let siteTitle: String?
    let siteOwner: String?
    let maxQueueLen: Int?
    let rateLimitPerIp: Int?
    let rateLimitWindowMin: Int?
    let downloadTtlHours: Int?
    let tomatoAddr: String?
    let dataDir: String?
    let appAddr: String?
    
    enum CodingKeys: String, CodingKey {
        case queued, running, tasks, users
        case siteTitle = "site_title"
        case siteOwner = "site_owner"
        case maxQueueLen = "max_queue_len"
        case rateLimitPerIp = "rate_limit_per_ip"
        case rateLimitWindowMin = "rate_limit_window_min"
        case downloadTtlHours = "download_ttl_hours"
        case tomatoAddr = "tomato_addr"
        case dataDir = "data_dir"
        case appAddr = "app_addr"
    }
}

// MARK: - 管理员设置
struct AdminSettings: Codable {
    let siteTitle: String?
    let siteVersion: String?
    let siteOwner: String?
    let siteNotice: String?
    let maxQueueLen: Int?
    let rateLimitPerIp: Int?
    let rateLimitWindowMin: Int?
    let downloadTtlHours: Int?
    let disabled: Bool?
    let maintenance: Bool?
    
    enum CodingKeys: String, CodingKey {
        case siteTitle = "site_title"
        case siteVersion = "site_version"
        case siteOwner = "site_owner"
        case siteNotice = "site_notice"
        case maxQueueLen = "max_queue_len"
        case rateLimitPerIp = "rate_limit_per_ip"
        case rateLimitWindowMin = "rate_limit_window_min"
        case downloadTtlHours = "download_ttl_hours"
        case disabled, maintenance
    }
}

struct TaskListResponse: Codable {
    let items: [DownloadTask]?
    let running: Int?
    let queued: Int?
}

struct SearchResponse: Codable {
    let items: [SearchResult]?
}

struct UserListResponse: Codable {
    let items: [User]?
    let error: String?
}
