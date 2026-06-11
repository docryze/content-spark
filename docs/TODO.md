# 灵感笔 ContentSpark — 项目 TODO

## 📋 后续云端配置（待完成）

- [ ] **Codemagic 云端构建注册**
  - 用 GitHub 账号登录 https://codemagic.io 注册
  - 添加 content-spark 仓库
  - Build platform 勾选 iOS
  - Machine 选择 Mac mini M2+
  - Flutter/Xcode 选择最新稳定版

- [ ] **Apple 开发者证书（需年费 $99 账号）**
  - 钥匙串访问 → 证书助理 → 从证书颁发机构请求证书（CSR）
  - Apple Developer 后台 → Certificates → 上传 CSR → 下载 iOS Distribution 证书
  - 导入钥匙串 → 导出 .p12 文件（设独立密码）
  - 创建 App ID（Bundle ID: com.contentspark.contentSpark）
  - 创建 App Store 类型描述文件（.mobileprovision）

- [ ] **Codemagic 代码签名配置**
  - Distribution → iOS code signing → Manual 模式
  - 上传 .p12 文件 + .mobileprovision
  - Distribution → App Store Connect → Apple ID + App-Specific Password

- [ ] **App Store Connect 元数据**
  - App 简介、截图、年龄分级
  - 构建版本勾选 Codemagic 上传的版本
  - 提交审核

- [ ] **Android 发布配置**
  - Google Play 开发者账号注册（$25 一次性）
  - 签名密钥生成
  - Google Play Console 创建应用并上传

---

## 🔧 本地优化（进行中）

- [x] GLM API Key 配置（.env）
- [x] CocoaPods 安装
- [x] GitHub CLI 登录 + 代码推送
- [x] Web Release 构建通过
- [ ] debug 模式修复（objective_c 编译问题）
- [ ] AI 生成功能端到端测试
- [ ] UI 细节优化
- [ ] 错误处理完善
- [ ] Android 本地构建测试
