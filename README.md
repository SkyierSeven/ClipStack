# ClipStack

免费、开源、本地的 macOS 剪贴板管理器。

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey)](https://www.apple.com/macos/)

ClipStack 运行在菜单栏，自动记录剪贴板历史，支持搜索、固定与全局快捷键。所有数据仅保存在本机，不会上传云端。

**完整使用说明 → [Docs/UserGuide.md](Docs/UserGuide.md)**  
安装后也可：**设置 → 帮助 → ClipStack 帮助**（菜单顶部有搜索框）。

## 功能一览

| 功能 | 说明 |
|------|------|
| 剪贴板历史 | 文本、链接、图片、文件；代码块语法高亮 |
| 一键复制 | 点击卡片写回系统剪贴板，可选复制后自动收起面板 |
| 固定 | 常用内容钉在列表前，清空/上限不会误删 |
| 搜索 | 关键词 + `type:` / `app:` / `pin:` 过滤，图片支持 OCR |
| 快捷键 | 自定义呼出面板；面板内方向键 / Enter / 空格 / Delete |
| 预览 | 空格 Quick Look |
| 隐私 | 自选排除应用；无默认黑名单、无云同步 |
| 帮助 | 系统帮助菜单（含搜索）+ 内置帮助手册 |

## 30 秒上手

1. 从 [Releases](https://github.com/SkyierSeven/ClipStack/releases) 安装到「应用程序」
2. 菜单栏出现剪贴板图标（无 Dock 图标是正常的）
3. 按 <kbd>⌘⇧X</kbd> 打开历史面板
4. 复制任意内容 → 面板出现卡片 → **点击卡片即可再复制**

插到当前输入框（模拟 ⌘V）需要辅助功能权限，详见[使用指南](Docs/UserGuide.md#辅助功能权限可选但推荐)。

### 常用操作

| 你想… | 怎么做 |
|------|------|
| 打开面板 | <kbd>⌘⇧X</kbd> 或菜单栏图标 |
| 复制一条历史 | 点击卡片 / <kbd>Enter</kbd> |
| 预览 | 滑入卡片后按 <kbd>空格</kbd> |
| 固定 | 图钉或右键 → 固定 |
| 搜索图片里的字 | 搜索框直接输入；或 `type:image 关键词` |
| 只看固定项 | 搜索 `pin:` |
| 打开设置 | 菜单栏 → 设置… |

### 搜索示例

```text
发票
type:image
app:Safari 登录
类型:文本 pin:
```

## 下载安装

| 文件 | 说明 |
|------|------|
| `ClipStack-*-macOS-arm64.zip` | 解压后将 `ClipStack.app` 拖入「应用程序」 |
| `ClipStack-*-macOS-arm64.dmg` | 打开磁盘映像后拖入「应用程序」 |

### 未签名版本打不开时

1. 右键 `ClipStack.app` →「打开」→「打开」
2. 或：「系统设置 → 隐私与安全性」→「仍要打开」
3. 或终端：`xattr -cr /Applications/ClipStack.app`

> 配置 Apple 开发者证书并公证后，正式版可直接双击安装。

### 发布新版本（维护者）

```bash
git tag v1.0.0
git push origin v1.0.0
```

推送 tag 后 GitHub Actions 会打包上传到 Releases；也可在 Actions 里手动跑 **Release**。

## 从源码构建

```bash
git clone https://github.com/SkyierSeven/ClipStack.git
cd ClipStack
xcodebuild -scheme ClipStack -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/ClipStack.app
```

开发热重载：

```bash
./Scripts/dev-run.sh   # 日志：/tmp/clipstack-dev.log
```

要求：macOS 14+、Xcode 15+。

## 快捷键

| 操作 | 默认 |
|------|------|
| 打开/关闭面板 | <kbd>⌘⇧X</kbd>（设置里可改） |
| 复制选中 | <kbd>Enter</kbd> |
| 预览 | <kbd>空格</kbd> |
| 切换卡片 | <kbd>←</kbd> <kbd>→</kbd> |
| 删除 | <kbd>Delete</kbd> |
| 关闭面板 | <kbd>Esc</kbd> |

更多说明见 [使用指南 · 快捷键](Docs/UserGuide.md#快捷键一览)。

## 数据与隐私

| 路径 | 内容 |
|------|------|
| `~/Library/Application Support/ClipStack/clipboard-data.json` | 元数据与设置 |
| `~/Library/Application Support/ClipStack/images/` | 图片文件 |

- 无账号、无云同步、无分析上报  
- 可在设置中排除指定应用  
- 卸载后如需清数据，删除上述目录即可  

## 项目结构

```
ClipStack/
├── ClipStack/           # 应用源码
│   ├── ClipStack.help/  # Apple 帮助手册（可被帮助菜单搜索）
│   ├── Models/
│   ├── Services/
│   ├── Views/
│   └── Controllers/
├── Docs/                # 使用指南与资源
│   ├── UserGuide.md
│   └── assets/
├── Scripts/
└── ClipStack.xcodeproj
```

## 文档索引

| 文档 | 用途 |
|------|------|
| [Docs/UserGuide.md](Docs/UserGuide.md) | 用户使用指南（推荐先看） |
| [Docs/README.md](Docs/README.md) | 文档目录 |
| [CONTRIBUTING.md](CONTRIBUTING.md) | 如何参与开发 |
| 应用内帮助 | 设置 → 帮助 → ClipStack 帮助 |

## 参与贡献

欢迎 Issue / PR，详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 许可证

[MIT](LICENSE) © SkyierSeven
