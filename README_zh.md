<p align="center">
<img src="./QuickRecorder/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="200" height="200" />
<h1 align="center">Kurip 🌰</h1>
<h3 align="center">面向新版 macOS 的轻量化录屏工具<br><a href="./README.md">[English]</a> <a href="./README_ja.md">[日本語]</a>
</p>

Kurip（栗 *kuri* + clip）基于 [@lihaoyun6](https://github.com/lihaoyun6) 的 [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) 修改而来，主要针对最新版 macOS 做适配和维护。

## 运行截图
<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./img/preview_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="./img/preview.png">
  <img alt="Kurip 截图" src="./img/preview.png" width="840"/>
</picture>
</p>

## 与 QuickRecorder 的区别
- **原生菜单栏控制**：停止、暂停、继续、摄像头浮窗改为标准的 macOS 菜单，在 macOS 26 及以后的系统上恢复可用（原版嵌在菜单栏里的按钮已经点不动了）。
- 从菜单栏面板选择录制模式后，面板会自动收起。
- Kurip 会正确地向系统申请权限，能在**隐私与安全性 → 录屏与系统录音**列表里找到。
- 首次启动时自动导入已安装的 QuickRecorder 的设置（保存目录、快捷键等）。

## 安装
### 系统要求
- macOS 12.3 及以上（已在 macOS 27 上测试）

### 从源码编译
1. 克隆本仓库，用 Xcode 打开 `QuickRecorder.xcodeproj`。
2. 在 *Signing & Capabilities* 中选择你自己的开发者团队。
3. 编译并运行 `QuickRecorder` scheme，生成的应用为 `Kurip.app`。
4. 首次启动后，在**系统设置 → 隐私与安全性 → 录屏与系统录音**中允许 Kurip。

## 功能
- 支持录制屏幕、屏幕区域、窗口、App、移动设备和系统声音。
- 支持免驱动内录系统声音、鼠标高亮、屏幕放大镜等功能。
- 完整支持 macOS 14 新增的 **[演讲者前置](https://support.apple.com/zh-cn/guide/facetime/fctm6333f4bd/mac)**（macOS 12/13 可使用摄像头悬浮窗）。
- 支持 `HEVC with Alpha` 输出，保留 Alpha 通道（iMovie 与 Final Cut Pro 支持）。

## 常见问题
**1. 主面板关闭之后在哪里重新打开？**
> 单击 Kurip 的程序坞图标或菜单栏图标即可。

**2. 为什么 Kurip 不是沙盒 App？**
> Kurip 不通过 App Store 分发，因此不需要做成沙盒 App。

**3. 如何在后期剪辑中分别调整系统声音和麦克风的音量？**
> 在设置中关闭 `将麦克风录制到主音轨`，系统声音和麦克风就会分别录制为两条音轨。

## 致谢
Kurip 基于 **[@lihaoyun6](https://github.com/lihaoyun6)** 的 **[QuickRecorder](https://github.com/lihaoyun6/QuickRecorder)** 开发。非常感谢原作者打造了这么好用的录屏工具并将其开源。本仓库完整保留了原项目的提交历史。

QuickRecorder 本身使用或参考了以下项目：
- [Azayaka](https://github.com/Mnpn/Azayaka) @Mnpn：灵感来源及部分录屏引擎代码
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) @sindresorhus：全局快捷键
- [SwiftLAME](https://github.com/hidden-spectrum/SwiftLAME) @Hidden Spectrum：MP3 输出
- [Sparkle](https://github.com/sparkle-project/Sparkle)：应用更新

## 许可证
[AGPL-3.0](./LICENSE)，与原版 QuickRecorder 相同。原作品 © 2024 lihaoyun6；修改部分 © 2026 inoxixi7。
