<p align="center">
<img src="./QuickRecorder/Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png" width="200" height="200" />
<h1 align="center">Kurip 🌰</h1>
<h3 align="center">最新の macOS 向け軽量画面収録アプリ<br><a href="./README.md">[English]</a> <a href="./README_zh.md">[中文]</a>
</p>

Kurip（栗 + クリップ）は、[@lihaoyun6](https://github.com/lihaoyun6) さんの [QuickRecorder](https://github.com/lihaoyun6/QuickRecorder) をベースに、最新の macOS に対応させたフォークです。

## スクリーンショット
<p align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="./img/preview_en_dark.png">
  <source media="(prefers-color-scheme: light)" srcset="./img/preview_en.png">
  <img alt="Kurip のスクリーンショット" src="./img/preview_en.png" width="840"/>
</picture>
</p>

## QuickRecorder との違い
- **メニューバー操作をネイティブ化**：停止・一時停止・再開・カメラオーバーレイを標準の macOS メニューに変更し、macOS 26 以降でも操作できるようにしました（元のメニューバー内ボタンはクリックに反応しなくなっていました）。
- メニューバーのパネルで収録モードを選ぶと、パネルが自動で閉じます。
- 画面収録の権限を正しく要求するため、**プライバシーとセキュリティ → 画面とシステムオーディオの収録**の一覧に表示されます。
- 初回起動時に、インストール済みの QuickRecorder の設定（保存先フォルダ、ショートカットなど）を自動で引き継ぎます。

## インストール
### 動作環境
- macOS 12.3 以降（macOS 27 で動作確認済み）

### ソースからビルド
1. このリポジトリをクローンし、Xcode で `Kurip.xcodeproj` を開きます。
2. *Signing & Capabilities* で自分の開発チームを選択します。
3. `Kurip` スキームをビルドして実行すると、`Kurip.app` が生成されます。
4. 初回起動後、**システム設定 → プライバシーとセキュリティ → 画面とシステムオーディオの収録**で Kurip を許可してください。

## 主な機能
- 画面全体・画面の一部・ウィンドウ・アプリ・モバイルデバイス・システム音声の収録
- ドライバ不要のシステム音声収録、マウスハイライト、画面拡大鏡など
- macOS 14 の **[プレゼンターオーバーレイ](https://support.apple.com/ja-jp/guide/facetime/fctm6333f4bd/mac)** に完全対応（macOS 12/13 ではカメラのフローティングウィンドウを利用可能）
- アルファチャンネルを保持する `HEVC with Alpha` 出力（iMovie と Final Cut Pro が対応）

## よくある質問
**1. メインパネルを閉じた後、どうやって再表示しますか？**
> Dock またはメニューバーの Kurip アイコンをクリックしてください。

**2. なぜサンドボックスアプリではないのですか？**
> App Store では配布しないため、サンドボックス化の必要がありません。

**3. システム音声とマイクの音量を編集時に別々に調整するには？**
> 設定で `Record Microphone to Main Track` をオフにすると、システム音声とマイクが別々のオーディオトラックに保存されます。

## 謝辞
Kurip は **[@lihaoyun6](https://github.com/lihaoyun6)** さんの **[QuickRecorder](https://github.com/lihaoyun6/QuickRecorder)** をもとに開発しています。素晴らしいアプリを作り、オープンソースとして公開してくださったことに心から感謝します。このリポジトリには元プロジェクトのコミット履歴をすべて残しています。

QuickRecorder が利用・参考にしているプロジェクト：
- [Azayaka](https://github.com/Mnpn/Azayaka) @Mnpn：着想元および収録エンジンの一部
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) @sindresorhus：グローバルショートカット
- [SwiftLAME](https://github.com/hidden-spectrum/SwiftLAME) @Hidden Spectrum：MP3 出力
- [Sparkle](https://github.com/sparkle-project/Sparkle)：アップデート機能

## ライセンス
元の QuickRecorder と同じく [AGPL-3.0](./LICENSE) です。原著作物 © 2024 lihaoyun6、変更部分 © 2026 inoxixi7。
