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

## 更新日志

### v2.2.1（服务端 v1.0.0 → v2.2.1）
- 书源大幅扩充：mix_sources.json 由 13 个源（8 启用）增至 33 个源（23 启用 / 10 禁用），新增 20 个 legado 格式书源（壁落小说、蚂蚁阅读、顶点中文、天域小说、黑岩阅读网、笔趣阁8 等）
- 杂源引擎重构（mix.go 20KB→36KB）：集成 legado 书源格式支持；新增书名 / 作者从 li 块提取、搜索结果评分排序；新增硬过滤（分类名 / 章节名 / 标签名 / 色情内容拦截）；新增标题归一化、中文数字转整数、广告行识别与过滤统计
- 杂源下载并行化：worker 数 1 → 3，同一时间可处理 3 本不同书
- 14 个书源正则修复：book_url_pattern 精确锚定，解决分类名 / 章节名误收录问题
- 前端新增杂源工具：工具切换（番茄 / 杂源）、SSE 流式搜索（搜到一本显示一本）、杂源下载队列与番茄队列分离、搜索结果带源标签
- 新增 API：GET /api/mix/search（SSE 流式）、POST /api/mix/tasks、GET /dl-mix/{path}
- 新增工具：convert_legado.py（legado 书源转换脚本）、legado_work/（书源测试工作区）
- 页脚新增四生万物工作室官网链接
- 限流调整：每 IP 15 次 / 5 分钟（原 5 次 / 15 分钟）
- app 镜像已于 2026-09-16 07:29 重建

### v1.1.0
- 服务端书源扩充，可检索 / 可下载的书籍来源进一步增多
- 杂源搜索优化，提升杂源结果的相关性与响应稳定性
- 修复在线阅读章节接口，解决章节内容偶发解析失败
- Release 构建不再打印请求/响应日志，避免账号密码等敏感信息写入系统日志

