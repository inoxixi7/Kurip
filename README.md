<p align="center">
<img src="./img/icon.png" width="180" height="180" />
<h1 align="center">Kurip 🌰</h1>
<h3 align="center">A lightweight screen recorder for modern macOS<br><a href="./README_zh.md">[中文]</a> <a href="./README_ja.md">[日本語]</a></h3>
</p>

Kurip (栗 *kuri*, "chestnut", + clip) lives in your menu bar and records your screen, a window, an app, an area or just audio, with a few clicks. It started as a fork of [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) by [@lihaoyun6](https://github.com/lihaoyun6) and has been redesigned for macOS 26 and later.

<p align="center">
<img alt="Kurip settings and menu bar panel" src="./img/preview_en.png" width="840"/>
</p>

## Features
- **Record anything**: full screen, an area, windows, apps, an iPhone or iPad, or system audio only.
- **One panel in the menu bar**: pick a mode, set the options in the bar that appears, and press the red button.
- **Audio**: app audio and microphone without extra drivers, echo cancellation, separate tracks for editing later.
- **While recording**: pause and resume, save the current frame, camera overlay, screen magnifier, highlighted cursor, all from the menu bar or with your own shortcuts.
- **After recording**: a card shows the clip with Show in Finder, Trim and Share.
- **Output**: H.264 / HEVC, HDR, and `HEVC with Alpha` that keeps transparency (works in iMovie and Final Cut Pro).
- **Settings in the System Settings style**, with search.
- **Languages**: English, 简体中文, 繁體中文, 日本語, Deutsch, Italiano, switchable in Settings.

## What's new compared with QuickRecorder
- Works again on macOS 26 and later: the menu bar controls are a standard macOS menu, and Kurip appears correctly under Screen & System Audio Recording.
- New main panel, recording bars and option bars, with one consistent set of buttons.
- Audio-only recording from its own popover; quitting asks first.
- A recording that can't start explains why instead of crashing.
- Japanese and German translations, Italian completed.
- Settings from an existing QuickRecorder install are imported on first launch.

## Installation
**Requirements**: macOS 12.3 or later. Developed and tested on macOS 27.

1. Download the latest `Kurip-x.y.z.zip` from [Releases](https://github.com/inoxixi7/Kurip/releases), unzip it and move `Kurip.app` to Applications.
2. Kurip is not notarized by Apple, so the first launch is blocked. Open **System Settings → Privacy & Security**, scroll down and click **Open Anyway** next to the Kurip message, then confirm with your password.
   Or run this once in Terminal:
   ```bash
   xattr -dr com.apple.quarantine /Applications/Kurip.app
   ```
3. Allow Kurip in **System Settings → Privacy & Security → Screen & System Audio Recording** when asked.

To update, use *Check for Updates…* in Settings → General, or turn on automatic checks there.

### Build from source
1. Clone this repository and open `Kurip.xcodeproj` in Xcode.
2. In *Signing & Capabilities*, choose your own team.
3. Build and run the `Kurip` scheme.

## Q&A
**Where do I reopen the main panel?**
> Click the Kurip icon in the menu bar (or in the Dock, if you turned it on in Settings).

**Why isn't Kurip sandboxed?**
> It isn't distributed through the App Store, so it doesn't need to be.

**How do I edit system audio and microphone volume separately?**
> Turn off *Record Microphone to Main Track* in Settings → Audio. System audio and microphone are then saved as two tracks.

**Why is there a purple "sharing" pill in my window recordings?**
> macOS draws it into any screen capture of a window. Apps can't hide it.

## Made with Claude Code
The Kurip redesign, the new translations, the fixes and this README were built together with [Claude Code](https://claude.com/claude-code), Anthropic's AI coding agent, which wrote and tested the changes in the running app under the maintainer's direction.

## Acknowledgements
Kurip is built on **[QuickRecorder](https://github.com/lihaoyun6/QuickRecorder)** by **[@lihaoyun6](https://github.com/lihaoyun6)**. Huge thanks for creating such a great app and releasing it as open source. The full commit history of the original project is preserved in this repository.

Projects QuickRecorder itself builds on:
- [Azayaka](https://github.com/Mnpn/Azayaka) @Mnpn: inspiration and part of the screen recording engine
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) @sindresorhus: global shortcuts
- [SwiftLAME](https://github.com/hidden-spectrum/SwiftLAME) @Hidden Spectrum: MP3 output
- [Sparkle](https://github.com/sparkle-project/Sparkle): app updates

## License
[AGPL-3.0](./LICENSE), the same as the original QuickRecorder. Original work © 2024 lihaoyun6; modifications © 2026 inoxixi7.
