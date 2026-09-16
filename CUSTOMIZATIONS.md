# cmux カスタム履歴

本家 manaflow-ai/cmux に対する自分用の変更の記録。ローカルの `custom` ブランチで管理（本家の更新は `git rebase origin/main` で取り込む）。
設定で直せるものは設定で直し、ソース変更が要るものだけ `custom` ブランチに積む。

| # | 日付 | 気になった点 | 対応 | 種別 | 状態 |
|---|---|---|---|---|---|
| 1 | 2026-09-17 | Cmd+Ctrl+F で別 Space にフルスクリーンになる（iTerm2 のように同じ画面で広げたい） | 非ネイティブフルスクリーンを実装 | ソース変更 | 実装済み・確認待ち |
| 2 | 2026-09-17 | ターミナルを半透明にしたい | Ghostty 設定 `background-opacity` | 設定 | 適用済み |
| 3 | 2026-09-17 | タブ名・サイドバーでどのリポジトリか分からない | サイドバー設定＋zsh のタイトルフック | 設定 | 適用済み |
| 4 | 2026-09-17 | Claude Code の質問文がダーク表示で黒字になり読めない | Claude Code の `theme` を dark に | 設定（Claude Code 側） | 適用済み |
| 5 | 2026-09-17 | Claude Code 実行中はタイトルがセッション名になり、リポジトリ名が消える | タイトルの頭にフォルダ名を付ける（`cmux / ○○`） | ソース変更 | 実装済み・確認待ち |

---

## 1. フルスクリーン（ソース変更）

- 原因: Cmd+Ctrl+F は `NSWindow.toggleFullScreen`（macOS 標準＝別 Space）を呼ぶ。Ghostty の `macos-non-native-fullscreen` は cmux では読まれない。
- 変更: Cmd+Ctrl+F と View > Toggle Full Screen を `cmuxToggleFullScreen()` に置換。メインウィンドウは同じ画面のまま `screen.frame` に広げ、メニューバーと Dock を自動非表示にする。もう一度押すと元のサイズに戻る。
  - `Sources/App/CmuxMainWindow.swift`: 状態保持・入退出・`setFrame`/`constrainFrameRect` の制限解除
  - `Sources/AppDelegate.swift`, `Sources/cmuxApp.swift`: 呼び出し元
  - `Sources/AppDelegate+MonitorMemory.swift`, `Sources/AppDelegate.swift`（セッション保存）: 広げている間の画面サイズをウィンドウ位置として保存しない
  - `Sources/WindowDecorationsController.swift`: 広げている間は信号機ボタンを隠す
- 挙動: 緑ボタンは従来どおり標準フルスクリーン。標準フルスクリーン中に Cmd+Ctrl+F を押すとそこから抜ける。ウィンドウを閉じる・別ディスプレイへ移ると自動で解除。

## 2. 半透明

`~/Library/Application Support/com.mitchellh.ghostty/config.ghostty`（元は空）

```
theme = light:Apple System Colors Light,dark:Apple System Colors
background-opacity = 0.65
```

- Ghostty 設定に1行でも書くと cmux の自動ライト/ダーク配色が切れるため、cmux の既定と同じテーマ名を `theme` で明示している。
- 透明度は `background-opacity` を変えて `cmux reload-config`。
- 2026-09-17 調整: 0.8 → 0.65（もう少し薄く）、ぼかし（`background-blur = 20`）は不要なので削除。

## 3. リポジトリ名が見えない

原因: 名前が末尾から切られる（`~/Documents/GitHub/cmux` → `~/Documents/Git…`）。

- `~/.config/cmux/cmux.json`: `"sidebar": { "pathLastSegmentOnly": true }`
  （設定画面の Sidebar > Truncate Path From Start。スキーマには未記載だがアプリは読む）
- Ghostty 設定: `shell-integration-features = no-title`（Ghostty の自動タイトルが後から上書きするため止める）
- `~/.zshrc`:
  - `DISABLE_AUTO_TITLE="true"`（oh-my-zsh の自動タイトルを止める）
  - 末尾に `_cmux_title_precmd` / `_cmux_title_preexec` を追加。プロンプト中はフォルダ名、コマンド実行中は `フォルダ名: コマンド` をタイトルにする。

## 4. Claude Code の質問文が読めない

- 原因: `~/.claude/settings.json` の `"theme"` が `"light"`（黒字前提）で、macOS と cmux はダーク。
- 対応: `"theme": "dark"`。macOS をライトに切り替えたときは `/config` で戻す。

## 5. Claude Code 実行中のタイトル（ソース変更）

- 原因: Claude Code などのプログラムは自分でタイトルを送る（例 `✳ cmuxアプリのカスタマイズ`）。実行中は zsh のフックが動かないので、フォルダ名が出ない。
- 変更: `Sources/Workspace+TitleOwnership.swift` の `updatePanelTitle` で、ターミナルの現在ディレクトリ名を頭に付ける（`titlePrefixedWithDirectoryName`）。
  - `✳ cmuxアプリのカスタマイズ` → `✳ cmux / cmuxアプリのカスタマイズ`（先頭の記号1文字は前に残す）
  - zsh フックのタイトル（`cmux`、`cmux: コマンド`、`~`）はそのまま
- 制約: タイトルが送られた時点のディレクトリで付く。Claude Code 実行中に cwd は変わらないので実用上は問題ない。

---

## 戻し方

変更前のファイルは `*.20260917-000832.bak` として同じ場所に保存してある。

```
~/.claude/settings.json.20260917-000832.bak
~/.zshrc.20260917-000832.bak
~/.config/cmux/cmux.json.20260917-000832.bak
~/Library/Application Support/com.mitchellh.ghostty/config.ghostty.20260917-000832.bak
```
