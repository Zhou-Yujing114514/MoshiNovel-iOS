# 摩柿小说下载站 (MoshiNovel)

摩拉克斯牌洋柿子小说下载站的 iOS 原生客户端，基于 SwiftUI 开发。

## 功能

- 🔍 搜索小说（书名 / 分享链接 / 书籍 ID）
- 📥 选择格式下载（TXT / EPUB / PDF）
- 📋 任务队列（排队中 / 下载中 / 已完成 / 失败）
- 👤 用户登录 / 注册
- 🌙 日间 / 夜间模式切换
- 🔧 站长管理功能

## 技术栈

- Swift 5.9+
- SwiftUI
- iOS 15.0+
- 异步/等待 (async/await)

## 项目结构

```
MoshiNovel/
├── MoshiNovelApp.swift      # 应用入口
├── Info.plist                # 应用配置
├── Models/
│   ├── Models.swift          # 数据模型
│   └── AppState.swift        # 应用状态与主题
├── Services/
│   └── APIService.swift      # API 服务
├── Views/
│   ├── SearchView.swift      # 搜索页
│   ├── DownloadView.swift    # 下载页
│   ├── MineView.swift        # 我的页
│   ├── LoginView.swift       # 登录/注册
│   └── FormatSelectView.swift # 格式选择
└── Assets.xcassets/          # 资源文件
```

## 构建

使用 GitHub Actions 自动构建 IPA，或本地用 Xcode 打开 `MoshiNovel.xcodeproj` 构建。

## 相关项目

- 网页版：https://morax.kdns.fr
- 虚空终端 iOS：https://github.com/Zhou-Yujing114514/VoidTerminal-iOS
