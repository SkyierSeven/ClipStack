# 贡献指南

感谢你对 ClipStack 的关注！

## 开发环境

- macOS 14+
- Xcode 15+（推荐最新稳定版）
- Swift 5

## 本地构建

```bash
git clone https://github.com/SkyierSeven/ClipStack.git
cd ClipStack
xcodebuild -scheme ClipStack -configuration Debug -derivedDataPath build build
open build/Build/Products/Debug/ClipStack.app
```

开发调试：

```bash
./Scripts/dev-run.sh
```

## 提交规范

- 一个 PR 聚焦一个功能或修复
- 提交前确保能成功编译
- 提交信息使用中文或英文均可，描述清楚「为什么」

## 报告问题

请在 [Issues](https://github.com/SkyierSeven/ClipStack/issues) 中说明：

1. macOS 版本
2. ClipStack 版本或 commit
3. 复现步骤
4. 期望行为与实际行为
