# keybind2me

> **Mac をキーボードだけで操る、自分専用のキーバインド環境**  
> AeroSpace (タイリングウィンドウマネージャー) + WezTerm + Dynamic Island 風ノッチ HUD

---

## ✨ Features

- **AeroSpace (Tiling Window Manager)**
  - 用途別ワークスペース（`Development`, `Browser`, `Note`, `Chat`, `1`）
  - キーボードショートカットで瞬時にアプリ・画面切り替え
  - アプリ自動ルーティング（Cursor, WezTerm, Linear, Obsidian, Slack, LINE など）
  - Finder のオーバーレイ（フローティング）表示
- **Dynamic Island 風 Notch HUD (Swift 自作)**
  - ワークスペース切り替え時に、MacBook のノッチからピル型バッジがニョキッとスプリングアニメーションで飛び出して通知
  - 外部ステータスバーツール不要（Mac 標準の Swift でネイティブ描画）
  - 横幅を固定した美しいピル（カプセル）デザイン
- **WezTerm**
  - キーボードドリブンなターミナル設定 & キーバインド

---

## 🚀 One-line Installation

ターミナルを開き、以下のコマンドを貼り付けるだけでセットアップが完了します：

```bash
curl -fsSL https://raw.githubusercontent.com/yukurust/keybind2me/main/install.sh | bash
```

### インストーラが行う処理
1. `~/repos/github/keybind2me` に本リポジトリを clone（または最新化）
2. `~/.aerospace.toml` および `~/.config/wezterm/` にシンボリックリンクを作成
3. `hud.swift` をネイティブコンパイルして `~/.config/aerospace/hud` を生成
4. AeroSpace の設定を即時リロード

---

## ⌨️ AeroSpace Keybindings

| キーバインド | 動作 |
| :--- | :--- |
| `Option + D` | **Development** へ移動 (Cursor, Antigravity, WezTerm, Linear, Orca) |
| `Option + B` | **Browser** へ移動 (Zen, Spotify, Google Chrome, Safari) |
| `Option + N` | **Note** へ移動 (Obsidian, Apple Notes) |
| `Option + C` | **Chat** へ移動 (Discord, LINE, Slack, ChatGPT, Grok Bot) |
| `Option + 1` | **1 (その他)** へ移動 (Bambu Studio, NordPass, NordVPN など未分類アプリ) |
| `Option + Shift + [D/B/N/C/1]` | フォーカス中のウィンドウを指定ワークスペースへ送る |
| `Option + H / J / K / L` | フォーカスを 左 / 下 / 上 / 右 へ移動 (Vim キーバインド) |
| `Option + Shift + H / J / K / L` | ウィンドウ位置を 左 / 下 / 上 / 右 へ入れ替え |
| `Option + F` | タイル ⇄ フローティング 切り替え |
| `Option + M` | フルスクリーン切り替え |

---

## 📁 Repository Structure

```
keybind2me/
├── aerospace/
│   ├── aerospace.toml   # AeroSpace 設定ファイル
│   └── hud.swift        # ノッチ HUD (Swift ソースコード)
├── wezterm/
│   ├── wezterm.lua      # WezTerm メイン設定
│   └── keybinds.lua     # WezTerm キーバインド設定
├── install.sh           # ワンライナー用セットアップスクリプト
└── README.md
```
