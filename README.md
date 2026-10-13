# ClipStack

免费、开源、本地的 macOS 剪贴板管理器。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey)](https://www.apple.com/macos/)

ClipStack 运行在菜单栏，自动记录剪贴板历史，支持搜索、固定与全局快捷键，所有数据仅保存在本机。

## 功能

| 功能 | 说明 |
|------|------|
| 剪贴板历史 | 文本、链接、图片、文件；代码块语法高亮 |
| 全局快捷键 | 自定义呼出历史面板 |
| 固定 | 常用内容钉在列表前面 |
| 搜索 | 全文搜索，支持 `type:` / `app:` / `pin:` 过滤与图片 OCR |
| 键盘导航 | `←→` 选择、`Enter` 复制、空格预览、`Delete` 删除、`Esc` 关闭 |
| 隐私 | 自选排除应用，无默认黑名单 |
| 帮助 | 系统帮助菜单（含搜索框）+ 内置帮助手册 |
| 存储 | 图片独立落盘，JSON 防抖写入 |

## 使用说明

完整指南见 [Docs/UserGuide.md](Docs/UserGuide.md)。安装后也可在应用中打开：

**帮助 → ClipStack 帮助**（菜单顶部有搜索框，可搜「快捷键」「固定」「搜索」等）。

### 常用操作

| 操作 | 方式 |
|------|------|
| 打开面板 | `⌘⇧X`（可改）或菜单栏图标 |
| 复制一条历史 | 点击卡片 / `Enter` |
| 预览 | 滑入卡片后按空格 |
| 固定 | 卡片图钉或右键菜单 |
| 搜索 | 面板顶部输入框，支持 `type:image`、`app:Safari`、`pin:` |

## 截图

> 运行应用后，从菜单栏打开历史面板即可使用。打开「设置」时，左上角会出现 ClipStack / 帮助菜单。

## 下载安装

在 [GitHub Releases](https://github.com/SkyierSeven/ClipStack/releases) 下载最新版：

| 文件 | 说明 |
|------|------|
| `ClipStack-*-macOS-arm64.zip` | 解压后将 `ClipStack.app` 拖入「应用程序」 |
| `ClipStack-*-macOS-arm64.dmg` | 打开磁盘映像，将 `ClipStack.app` 拖入「应用程序」 |

### 未签名版本如何安装

若提示「无法打开」或「来自身份不明的开发者」，任选其一：

1. **右键打开**：在 `ClipStack.app` 上右键 →「打开」→ 再点「打开」
2. **系统设置放行**：「系统设置 → 隐私与安全性」→ 找到被拦截提示 →「仍要打开」
3. **移除隔离标记**（终端）：

```bash
xattr -cr /Applications/ClipStack.app
open /Applications/ClipStack.app
```

> 正式发布版本会在配置 Apple 开发者证书后自动签名并公证，用户可直接双击安装。

### 发布新版本（维护者）

```bash
git tag v1.0.0
git push origin v1.0.0
```

推送 tag 后，GitHub Actions 会自动打包并上传到 Releases。也可在 Actions 页手动运行 **Release** 工作流。

## 从源码构建

```bash
git clone https://github.com/SkyierSeven/ClipStack.git
cd ClipStack
xcodebuild -scheme ClipStack -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/ClipStack.app
```

### 开发模式

```bash
./Scripts/dev-run.sh
```

日志输出：`/tmp/clipstack-dev.log`

### 首次使用

1. 应用位于**菜单栏**（日常无 Dock 图标；打开设置时会短暂出现）
2. 首次启动有引导：辅助功能授权、快捷键、登录时启动
3. 自动插入内容需授予**辅助功能**权限（系统设置 → 隐私与安全性 → 辅助功能）

## 快捷键

| 操作 | 默认 |
|------|------|
| 打开/关闭面板 | `⌘⇧X`（可在设置中修改） |
| 复制选中 | `Enter` |
| 预览 | `空格` |
| 切换卡片 | `←` `→` |
| 删除 | `Delete` |
| 关闭面板 | `Esc` |

## 数据存储

| 路径 | 内容 |
|------|------|
| `~/Library/Application Support/ClipStack/clipboard-data.json` | 元数据 |
| `~/Library/Application Support/ClipStack/images/` | 图片文件 |

数据不会上传云端。

## 项目结构

```
ClipStack/
├── ClipStack/              # 应用源码
│   ├── ClipStack.help/     # Apple 帮助手册（帮助菜单可搜索）
│   ├── Models/
│   ├── Services/
│   ├── Views/
│   └── Controllers/
├── Docs/                   # 使用指南与参考图
├── Scripts/
└── ClipStack.xcodeproj
```

## 参与贡献

欢迎提交 Issue 和 Pull Request，详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

[MIT](LICENSE) © SkyierSeven
