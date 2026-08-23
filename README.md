# ClipStack

免费、开源、本地的 macOS 剪贴板管理器。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey)](https://www.apple.com/macos/)

ClipStack 运行在菜单栏，自动记录剪贴板历史，支持搜索、固定、队列插入与全局快捷键，所有数据仅保存在本机。

## 功能

| 功能 | 说明 |
|------|------|
| 剪贴板历史 | 文本、链接、图片、文件；代码块语法高亮 |
| 全局快捷键 | 自定义呼出面板；`⌘1`–`⌘9` 快速插入 |
| 固定板 | 常用内容长期保存 |
| 搜索 | 全文搜索，支持 `type:` / `app:` / `固定:` 过滤与图片 OCR |
| 插入队列 | 多条内容排队，依次插入 |
| 键盘导航 | `←→` 选择、`Enter` 插入、`Delete` 删除、`Esc` 关闭 |
| 隐私 | 自选排除应用，无默认黑名单 |
| 存储 | 图片独立落盘，JSON 防抖写入 |

## 截图

> 运行应用后，从菜单栏打开历史面板即可使用。

## 快速开始

### 下载构建

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

1. 应用位于**菜单栏**（无 Dock 图标）
2. 首次启动有引导：辅助功能授权、快捷键、登录时启动
3. 自动插入内容需授予**辅助功能**权限（系统设置 → 隐私与安全性 → 辅助功能）

## 快捷键

| 操作 | 默认 |
|------|------|
| 打开/关闭面板 | `⌘⇧X`（可在设置中修改） |
| 插入最近 9 条 | `⌘1` … `⌘9` |
| 避免冲突 | 设置中可开启 `⌘⌥1` … `⌘⌥9` |

## 数据存储

| 路径 | 内容 |
|------|------|
| `~/Library/Application Support/ClipStack/clipboard-data.json` | 元数据 |
| `~/Library/Application Support/ClipStack/images/` | 图片文件 |

数据不会上传云端。

## 项目结构

```
ClipStack/
├── ClipStack/           # 应用源码
│   ├── Models/        # 数据模型
│   ├── Services/      # 剪贴板监听、存储、快捷键
│   ├── Views/         # SwiftUI 界面
│   └── Controllers/   # 面板控制器
├── Scripts/           # 开发脚本
└── ClipStack.xcodeproj
```

## 参与贡献

欢迎提交 Issue 和 Pull Request，详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

[MIT](LICENSE) © SkyierSeven
