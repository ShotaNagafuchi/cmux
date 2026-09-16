# cmux カスタム履歴

本家 manaflow-ai/cmux に対する自分用の変更の記録。ローカルの `custom` ブランチで管理（本家の更新は `git rebase origin/main` で取り込む）。
設定で直せるものは設定で直し、ソース変更が要るものだけ `custom` ブランチに積む。

| # | 日付 | 気になった点 | 対応 | 種別 | 状態 |
|---|---|---|---|---|---|
| 1 | 2026-09-17 | Cmd+Ctrl+F で別 Space にフルスクリーンになる（iTerm2 のように同じ画面で広げたい） | 未対応。2〜4 を試してから実装するか決める | ソース変更 | 保留 |
| 2 | 2026-09-17 | ターミナルを半透明にしたい | Ghostty 設定 `background-opacity` | 設定 | 適用済み |
| 3 | 2026-09-17 | タブ名・サイドバーでどのリポジトリか分からない | サイドバー設定＋zsh のタイトルフック | 設定 | 適用済み |
| 4 | 2026-09-17 | Claude Code の質問文がダーク表示で黒字になり読めない | Claude Code の `theme` を dark に | 設定（Claude Code 側） | 適用済み |

---

## 1. フルスクリーン（保留）

- 原因: Cmd+Ctrl+F は `NSWindow.toggleFullScreen`（macOS 標準＝別 Space）を呼ぶ。
  - `Sources/AppDelegate.swift`（ショートカット処理）、`Sources/cmuxApp.swift`（View メニュー）
- Ghostty の `macos-non-native-fullscreen` は cmux では読まれない（Ghostty の macOS アプリ側のコードで、cmux は取り込んでいない）。cmux.json にも該当設定なし。
- 実装する場合の注意: レイアウト・ウィンドウ位置の保存/復元・ディスプレイ変更時の処理が `styleMask.contains(.fullScreen)` を見ている。非ネイティブ方式ではこれが false のままなので、状態を自前で持って各所に渡す必要がある。参考実装は `ghostty/macos/Sources/Helpers/Fullscreen.swift` の `NonNativeFullscreen`。
- 当面の代替: タイトルバーのダブルクリックで同じ画面のまま最大化（メニューバーと Dock は残る）。

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

---

## 戻し方

変更前のファイルは `*.20260917-000832.bak` として同じ場所に保存してある。

```
~/.claude/settings.json.20260917-000832.bak
~/.zshrc.20260917-000832.bak
~/.config/cmux/cmux.json.20260917-000832.bak
~/Library/Application Support/com.mitchellh.ghostty/config.ghostty.20260917-000832.bak
```
