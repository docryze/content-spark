# 灵感笔 ContentSpark — 项目构建与运行指南

> **版本**：v2.0 | **更新日期**：2026-06-11 | **状态**：已验证通过

---

## 一、项目概览

| 项 | 值 |
|---|---|
| **项目名称** | 灵感笔 ContentSpark |
| **定位** | AI 社媒内容创作助手 — 一键生成符合各平台风格的爆款内容 |
| **仓库** | https://github.com/docryze/content-spark |
| **本地路径** | `~/workspace/hermes/content-spark-app/` |
| **目标平台** | iOS / Android / Web |
| **代码规模** | 25 个 Dart 文件，约 4,254 行代码 |

### 核心功能

| 功能 | 状态 | 说明 |
|------|------|------|
| 6 大平台内容生成 | ✅ | 小红书/抖音/公众号/B站/微博/快手 |
| 5 种内容类型 | ✅ | 图文/视频脚本/标题优化/选题灵感/多平台改写 |
| 🔄 跨平台自动改编 | ✅ V2 | 一篇内容 → 多平台自动适配 |
| 🧹 AI 去 AI 味 | ✅ V2 | 检测 AI 痕迹 + 人性化改写 |
| 🔥 热点实时追踪 | ✅ V2 | 微博/百度/知乎/抖音热搜 + 一键生成 |
| SSE 流式响应 | ✅ | 实时逐字生成，Web/Native 双端适配 |
| 暗色玻璃拟态 UI | ✅ | 差异化设计，6 平台品牌色 |
| 帖子预览渲染 | ✅ | 生成结果即预览，所见即所得 |

---

## 二、技术栈

| 层 | 技术 | 版本 |
|----|------|------|
| **框架** | Flutter | 3.38.5 (stable) |
| **语言** | Dart | 3.10.4 (stable) |
| **状态管理** | Riverpod | ^2.6.1 |
| **AI 引擎** | GLM API (Z.AI) | glm-4-flash |
| **网络** | Dio (Native) + dart:html (Web) | ^5.7.0 |
| **环境变量** | flutter_dotenv | ^5.2.1 |
| **本地存储** | SharedPreferences | ^2.3.4 |
| **版本控制** | Git + GitHub | git 2.50.1 / gh 2.83.2 |
| **云端构建** | Codemagic | 待配置 |

---

## 三、环境要求

### 3.1 硬件

| 要求 | 说明 |
|------|------|
| **开发机** | Intel Mac (x86_64) 或 Apple Silicon Mac 均可 |
| **测试环境** | Intel Mac 上使用 Chrome (Web) 调试，避开 iOS 模拟器卡顿 |
| **云端编译** | iOS/Android 通过 Codemagic 云端 M 系列 Mac 构建，本地无需 Xcode |

### 3.2 软件

| 软件 | 最低版本 | 安装方式 |
|------|---------|---------|
| **Flutter SDK** | 3.38.5 (stable) | [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install) |
| **Dart SDK** | 3.10.4 | Flutter 自带 |
| **VS Code** | 最新 | [code.visualstudio.com](https://code.visualstudio.com/) |
| **VS Code 插件** | Flutter + Dart | 扩展商店搜索安装 |
| **Chrome** | 最新 | 系统自带或 Google 官网下载 |
| **Git** | 2.x | `xcode-select --install` 或 `brew install git` |
| **GitHub CLI** | 2.x | `brew install gh` |
| **CocoaPods** | 1.16+ | `brew install cocoapods`（iOS 构建需要） |

### 3.3 Intel Mac 专属配置

Intel 芯片 Mac 运行 Flutter 时需要禁用 native assets 编译（避免 `objective_c` 崩溃）：

```bash
flutter config --no-enable-native-assets
```

验证：
```bash
flutter config --list | grep native-assets
# 输出：enable-native-assets: false
```

---

## 四、快速开始（首次克隆）

### 4.1 克隆项目

```bash
cd ~/workspace/hermes
git clone https://github.com/docryze/content-spark.git content-spark-app
cd content-spark-app
```

### 4.2 安装依赖

```bash
flutter pub get
```

### 4.3 配置环境变量

```bash
# 复制示例文件
cp .env.example .env

# 编辑 .env，填入你的 GLM API Key
# 必填项：
#   GLM_API_KEY=你的API密钥
# 可选项：
#   GLM_BASE_URL=https://api.z.ai/api/paas/v4
#   GLM_MODEL=glm-4-flash
#   DISABLE_QUOTA=true   （本地测试关闭配额限制）
```

`.env` 文件内容示例：
```properties
# GLM API 配置
GLM_API_KEY=你的49位API密钥
GLM_BASE_URL=https://api.z.ai/api/paas/v4
GLM_MODEL=glm-4-flash

# 关闭配额限制（本地测试用，生产环境设为 false）
DISABLE_QUOTA=true
```

> ⚠️ `.env` 文件已在 `.gitignore` 中排除，不会被提交到 Git。API Key 不会泄露。

### 4.4 验证编译

```bash
flutter analyze
# 预期输出：0 error, 0 warning
```

### 4.5 启动开发服务器（Web）

```bash
flutter run -d chrome
```

首次启动会编译 Dart → JavaScript，约 30-60 秒。后续使用 Hot Reload（`r`）即时生效。

### 4.6 构建 Release（Web）

```bash
flutter build web --release --no-tree-shake-icons
```

> `--no-tree-shake-icons` 防止图标字体被 tree shaking 误删。

构建产物在 `build/web/`，可本地预览：

```bash
cd build/web
python3 -m http.server 9999
# 打开 http://localhost:9999
```

---

## 五、项目结构

```
content-spark-app/
├── .env                        # 环境变量（不入 Git）
├── .env.example                # 环境变量模板
├── .gitignore
├── pubspec.yaml                # 依赖配置
├── docs/                       # 文档
│   ├── PRD-Product-Requirements.md    # 产品需求文档
│   ├── Intel-Mac-Flutter-Codemagic-Guide.md  # Intel Mac 开发指南
│   └── TODO.md                        # 待办事项
├── lib/
│   ├── main.dart               # 入口：4 Tab 导航
│   ├── config/
│   │   ├── app_config.dart     # 环境变量读取 + 颜色常量
│   │   ├── app_theme.dart      # 暗色玻璃拟态主题
│   │   └── studio_colors.dart  # 颜色定义
│   ├── constants/
│   │   └── app_enums.dart      # 枚举：平台/类型/模式/品类/订阅方案
│   ├── models/
│   │   └── app_models.dart     # 数据模型：GenerationResult / UserProfile
│   ├── providers/
│   │   └── app_providers.dart  # Riverpod 状态管理
│   ├── screens/
│   │   ├── home_screen.dart          # 首页：三模式切换
│   │   ├── hot_topics_screen.dart    # 热点中心
│   │   ├── history_screen.dart       # 历史记录
│   │   ├── profile_screen.dart       # 个人中心
│   │   └── result_screen.dart        # 结果详情
│   ├── services/
│   │   ├── glm_stream_service.dart   # GLM SSE 流式服务
│   │   ├── glm_api_service.dart      # GLM 非流式服务
│   │   ├── platform_style_engine.dart # 6 平台 Prompt 模板
│   │   ├── adapt_engine.dart         # 跨平台改编引擎
│   │   ├── deai_engine.dart          # AI 去 AI 味引擎
│   │   ├── hot_topics_service.dart   # 热点数据服务
│   │   ├── stream_content_parser.dart # 流式 JSON 增量解析器
│   │   ├── storage_service.dart      # 本地持久化
│   │   └── sse/                      # SSE 跨平台条件导入
│   │       ├── sse_client.dart       #   入口（条件导出）
│   │       ├── sse_client_web.dart   #   Web: dart:html + XMLHttpRequest
│   │       └── sse_client_native.dart #  Native: Dio ResponseBody
│   └── widgets/
│       ├── post_preview.dart         # 社交平台帖子预览卡片
│       └── common_widgets.dart       # 通用小组件
└── build/web/                  # Web 构建产物
```

---

## 六、核心架构说明

### 6.1 SSE 流式通信（跨平台）

```
┌─────────────────────────────────────────────────┐
│                  Flutter App                     │
│                                                  │
│  GlmStreamService                                │
│       ↓ 调用                                      │
│  SseClient ← 条件导入（编译时自动选择）             │
│       ├─ Web:    dart:html HttpRequest + onProgress │
│       └─ Native: Dio ResponseBody stream         │
│       ↓                                          │
│  StreamChunk 逐字增量                             │
│       ↓                                          │
│  StreamContentParser（正则提取不完整 JSON 字段）    │
│       ↓                                          │
│  PostPreviewCard（实时帖子预览渲染）               │
└─────────────────────────────────────────────────┘
```

### 6.2 三模式创作流程

```
首页模式切换
├── ✍️ 创作模式
│   选平台 → 选类型 → 输入 → 生成 → PostPreviewCard
│
├── 🔄 改编模式
│   选源平台 → 粘贴原文 → 多选目标平台 → 改编 → PostPreviewCard
│
└── 🧹 去AI味模式
    粘贴文本 → 检测AI痕迹（评分+高亮） → 人性化改写 → 前后对比
```

### 6.3 配额管理

| 环境变量 | 效果 |
|---------|------|
| `DISABLE_QUOTA=true` | 🔓 关闭配额限制（本地测试） |
| `DISABLE_QUOTA=false` | 🔒 按订阅方案限制（生产环境） |

订阅方案：

| 方案 | 月价 | 每日次数 | 改编 | 去AI味 | 热点 |
|------|------|---------|------|--------|------|
| 免费版 | ¥0 | 5 次 | ❌ | ❌ | ❌ |
| 基础版 | ¥19.9 | 无限 | ❌ | ❌ | ❌ |
| 专业版 | ¥39.9 | 无限 | ✅ | ✅ | ✅ |
| 团队版 | ¥199 | 无限 | ✅ | ✅ | ✅ |

---

## 七、常见问题排查

### Q1: `flutter run -d chrome` 崩溃

```
Error: objective_c native asset compilation failed
```

**解决**：
```bash
flutter config --no-enable-native-assets
flutter clean
flutter pub get
flutter run -d chrome
```

### Q2: `flutter build web` 图标消失

**解决**：加 `--no-tree-shake-icons` 参数：
```bash
flutter build web --release --no-tree-shake-icons
```

### Q3: SSE 流式在 Web 端不工作

**原因**：Dio 的 `ResponseType.stream` 在 Web 端不支持真正的流式读取。

**已解决**：项目使用条件导入，Web 端自动切换为 `dart:html` 的 `HttpRequest` + `onProgress` 事件。

```
sse/sse_client.dart       ← 入口（条件导出）
sse/sse_client_web.dart   ← Web: XMLHttpRequest + onProgress
sse/sse_client_native.dart ← Native: Dio ResponseBody stream
```

### Q4: GLM API 返回 ` ```json ``` ` 包裹

**已解决**：`GlmStreamService._filterDisplay()` 和 `_stripMarkdown()` 双层过滤，自动剥离 markdown 代码块。

### Q5: SSE chunk 跨 TCP 包分割

**已解决**：`sse_client_web.dart` 使用 `lineBuffer` 累积不完整的 SSE 行，确保 `data: {...}\n\n` 完整后触发。

### Q6: API Key 如何获取

1. 访问 [Z.AI 开放平台](https://open.z.ai/)
2. 注册账号 → 开通 Coding Plan 订阅
3. 在 API Key 管理页面创建密钥
4. 将密钥填入 `.env` 文件的 `GLM_API_KEY` 字段

---

## 八、Git 工作流

### 8.1 日常开发

```bash
# 拉取最新
git pull

# 创建功能分支
git checkout -b feature/xxx

# 开发完成后提交
git add .
git commit -m "feat: 简短描述"

# 推送到远程
git push origin feature/xxx

# 合并到主分支（通过 GitHub PR）
gh pr create --title "feat: 简短描述" --body ""
```

### 8.2 GitHub CLI 快捷操作

```bash
# 查看状态
gh repo view docryze/content-spark

# 查看最近提交
gh api repos/docryze/content-spark/commits?per_page=5

# 创建 release
gh release create v2.0 --title "V2.0" --notes "三模式首页+热点中心"
```

---

## 九、云端构建（iOS/Android）

> ⚠️ Intel Mac 无法本地编译 iOS 应用。使用 Codemagic 云端构建。

### 9.1 前置条件

- [ ] Apple 开发者账号（$99/年）
- [ ] Codemagic 账号（GitHub 授权登录）
- [ ] iOS Distribution 证书 (.p12)
- [ ] Provisioning Profile (.mobileprovision)

### 9.2 配置步骤

1. 登录 [Codemagic](https://codemagic.io/) → Add App → 选择 `content-spark`
2. Build Settings → Platform: iOS → Machine: Mac mini M2
3. Code Signing → Manual → 上传 .p12 + .mobileprovision
4. Distribution → App Store Connect → 填入 Apple ID + App-Specific Password
5. 点击 Start new build → 等待编译完成 → 自动上传 TestFlight

### 9.3 详细指南

参见 [Intel-Mac-Flutter-Codemagic-Guide.md](./Intel-Mac-Flutter-Codemagic-Guide.md)

---

## 十、发布清单

### Web 发布

```bash
flutter build web --release --no-tree-shake-icons
# 产物：build/web/
# 部署到任意静态托管（GitHub Pages / Vercel / Netlify）
```

### iOS 发布（通过 Codemagic）

```bash
git push origin master
# → Codemagic 自动触发构建
# → 编译成功后自动上传 TestFlight
# → App Store Connect 提交审核
```

### Android 发布（通过 Codemagic 或本地）

```bash
# 本地构建（需要 Android SDK）
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk
```

---

## 十一、性能指标

| 指标 | 数值 |
|------|------|
| Web 构建时间 | ~45 秒 |
| SSE 首 Token 延迟 | < 1 秒 |
| 单次 API Token 消耗 | ~350 tokens |
| 单次 API 成本 | ~¥0.01 |
| 编译错误 | 0 |
| 编译警告 | 0 |
| Dart 文件数 | 25 |
| 代码总行数 | 4,254 |
