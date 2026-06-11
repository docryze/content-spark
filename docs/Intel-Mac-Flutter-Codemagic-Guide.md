# Intel Mac 替代方案：Flutter + Codemagic 云端打包开发 iOS 应用指南

本项目文档旨在解决 Intel 芯片 Mac 无法升级最新 macOS / Xcode，导致无法向 App Store 提交应用的问题。通过"本地轻量编写，云端高效编译"的隔离架构，完美压榨老旧硬件的剩余价值。

---

## 一、 技术栈选型 (Tech Stack)

核心原则：轻量化本地开发，现代化云端编译。

* 跨平台框架：Flutter (Dart) - UI 渲染不依赖系统原生组件，本地 Web 预览极快。
* 本地编辑器：VS Code - 配置 Flutter / Dart 插件，彻底替代笨重的 Xcode。
* 本地调试环境：Chrome 浏览器 / iPhone 真机 - 避开 Intel 架构运行 iOS 模拟器的严重卡顿。
* 版本控制：Git + GitHub (或 GitLab) - 代码托管与触发云端构建的纽带。
* 云端构建平台：Codemagic (CI/CD) - 提供最新 M 系列 Mac 虚拟环境与最新版 Xcode 编译器。

---

## 二、 全流程架构图

```
+--------------------------+      Git Push      +------------------------+
|   Intel Mac (本地开发)   | --------------> |  GitHub / GitLab 仓库  |
|  - VS Code 编写 Dart 代码  |                +------------------------+
|  - Chrome 浏览器进行 UI 调试|                            |
+--------------------------+                            | 自动/手动触发
                                                        v
+--------------------------+   上架 App Store   +------------------------+
|    苹果 App Store 后台   | <-------------- |  Codemagic (云端构建)  |
|  - TestFlight 灰度测试   |                  | - M 系列 Mac 虚拟环境    |
|  - 最终提交审核发布      |                  | - 最新版 Xcode 自动编译  |
+--------------------------+                  +------------------------+
```

---

## 三、 核心落地步骤

### 阶段一：本地环境准备与开发 (Intel Mac 侧)

1. 环境配置：
   * 下载并配置 Flutter SDK。
   * 安装 VS Code，并内嵌安装 Flutter 和 Dart 扩展插件。

2. 创建项目：
   * 打开终端执行以下命令创建新项目：
     ```
     flutter create my_awesome_app
     cd my_awesome_app
     ```

3. 本地低负载调试：
   * 在 VS Code 右下角将调试设备切换为 Chrome (web)。
   * 按 F5 启动，利用 Flutter 的 Hot Reload（热重载）边写边改。此时仅消耗极低的内存和 CPU，老机器运行流畅。

4. 源码托管：
   * 提交代码并推送到远程仓库：
     ```
     git init
     git add .
     git commit -m "feat: initial commit"
     git remote add origin <你的GitHub仓库地址>
     git push -u origin main
     ```

### 阶段二：准备苹果开发者凭证 (绕过本地 Xcode)

注意：此步骤需要已开通年费为 99 美元的 Apple 开发者账号。

1. 生成 CSR 文件：打开 Mac 自带的"钥匙串访问 (Keychain Access)" -> 证书助理 -> 从证书颁发机构请求证书，填写邮箱并选择"保存到磁盘"。
2. 创建发布证书 (Certificate)：登录 Apple Developer 官网，进入 Certificates, Identifiers & Profiles，上传刚才的 CSR 文件，生成并下载 iOS Distribution 证书。
3. 导出 P12 文件：双击下载的证书导入 Mac 钥匙串，在钥匙串中右键该证书选择"导出..."，格式选择 .p12，并设置一个独立密码。
4. 创建描述文件 (Provisioning Profile)：在 Apple 开发者后台，绑定你的 App ID（Bundle ID），关联上述发布证书，创建一个 App Store 类型的描述文件（.mobileprovision）并下载。

### 阶段三：配置 Codemagic 云端工作流

1. 注册与关联：
   * 登录 Codemagic 官网（使用 GitHub 账号授权登录）。
   * 点击 Add Application选项，选择你的项目仓库。

2. 配置构建基础环境 (Build Settings)：
   * Build platform：勾选 iOS。
   * Machine：选择 Mac mini M2 或更高配置（确保编译速度）。
   * Flutter/Xcode version：在下拉菜单中选择当前苹果 App Store 要求的最新稳定版 Xcode 及对应的 Flutter 版本。

3. 配置代码签名 (Code Signing)：
   * 展开设置中的 Distribution -> iOS code signing。
   * 将签名模式切换为 Manual (手动)。
   * 分别上传在阶段二中准备好的 .p12 文件（并输入密码）以及 .mobileprovision 描述文件。

4. 配置自动分发 (Distribution to App Store)：
   * 展开 Distribution -> App Store Connect。
   * 输入你的 Apple ID 以及在苹果账号后台生成的 App-Specific Password (应用专用密码)。
   * 勾选 Enable App Store Connect publishing，开启编译后自动提交。

### 阶段四：一键云端编译与上架

1. 触发构建：在本地修改完最终代码并执行 git push 后，进入 Codemagic 网页端，点击右侧的 Start new build。
2. 云端托管编译：Codemagic 的 M 芯片云端机器会自动接管：拉取代码 -> 补全依赖 -> 调用最新 Xcode 执行打包 -> 注入证书签名。
3. 自动交付：构建成功后，系统会自动将生成的 .ipa 包推送到苹果的 TestFlight / App Store Connect 后台，全程本地老机器无需承担任何编译压力。

---

## 四、 最终收尾上架

当 Codemagic 提示发布成功并收到邮件后：
1. 登录 App Store Connect 网页端。
2. 创建或选择你的应用版块，填写对应的 App 简介、截图、年龄分级等元数据。
3. 在 构建版本 一栏中，直接勾选刚才由 Codemagic 帮上传上来的最新版本。
4. 点击右上方 提交审核，静待苹果官方审核通过即可。
