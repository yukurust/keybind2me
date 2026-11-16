# keybind2me

> **Mac をキーボードだけで操る、自分専用のキーバインド環境**  
> AeroSpace (タイリングウィンドウマネージャー) + JankyBorders + WezTerm + Dynamic Island 風ノッチ HUD + Liquid Glass チートシート

---

## ✨ Features

- **AeroSpace (Tiling Window Manager)**
  - 用途別ワークスペース（`Development`, `Browser`, `Note`, `Chat`, `AI`, `1`）
  - キーボードショートカットで瞬時にアプリ・画面切り替え
  - アプリ自動ルーティング（Cursor, WezTerm, Linear, Obsidian, Slack, LINE など）
  - Finder のオーバーレイ（フローティング）表示
  - **フォーカス時マウス自動追従**: `on-focus-changed` により、フォーカス移動先のウィンドウ中央へカーソルが自動で移動
- **JankyBorders (`borders`)**
  - 今フォーカスしているウィンドウの周囲にカラフルな枠線（シアン `0xff59c7fa` / 幅 `4.0`）を表示し、注目ウィンドウを一目で強調
  - AeroSpace 起動時に自動で立ち上がるよう `after-startup-command` へ組み込み済み
- **Dynamic Island 風 Notch HUD (Swift 自作)**
  - ワークスペース切り替え時に、MacBook のノッチからピル型バッジがニョキッとスプリングアニメーションで飛び出して通知
  - 外部ステータスバーツール不要（Mac 標準の Swift でネイティブ描画）
- **Liquid Glass チートシートウィジェット (Swift 自作)**
  - 画面左下（Dock の左側の空きスペース）に Dock と同じ高さ・位置で自動追従して常駐
  - macOS 26+ の純正 `NSGlassEffectView`（`.clear` スタイル）を採用し、OS の `システム設定 > 外観 > Liquid Glass` の強度設定にリアルタイム追従
- **WezTerm**
  - キーボードドリブンなターミナル設定 & キーバインド（Leader: `Ctrl + Q`）
- **Vimium (Zen)**
  - キー割り当てを [`vimium/key-mappings`](vimium/key-mappings) で管理
  - Zen を終了した状態で `vimium/apply.sh` を実行すると、その内容が Vimium に入る
- **Obsidian Vim**
  - 編集画面は Obsidian 標準の Vim モードと [`obsidian/.obsidian.vimrc`](obsidian/.obsidian.vimrc)
  - 閲覧画面と Hearth Home のスクロール、タブ、ペインは [`obsidian/reading-vim`](obsidian/reading-vim)
  - 文字の削除や挿入は閲覧画面には無い

---

## 🚀 One-line Installation

ターミナルを開き、以下のコマンドを貼り付けるだけでセットアップが完了します：

```bash
curl -fsSL https://raw.githubusercontent.com/yukurust/keybind2me/main/install.sh | bash
```

### インストーラが行う処理
1. `~/repos/github/keybind2me` に本リポジトリを clone（または最新化）
2. `~/.aerospace.toml` および `~/.config/wezterm/` にシンボリックリンクを作成
3. `hud.swift` / `cheatsheet.swift` をネイティブコンパイルして `~/.config/aerospace/` に配置
4. `JankyBorders` (`borders`) をインストール（Homebrew 失敗時はソースから自動ビルド）
5. AeroSpace の設定を即時リロードし、`borders` を起動
6. `vimium/key-mappings` を `~/.config/aerospace/vimium-key-mappings` にリンクし、Zen が終了していれば Vimium に書き込む
7. `obsidian/.obsidian.vimrc` を各保管庫の `.obsidian.vimrc` にリンクする

---

## 🛠️ 使い方・運用Tips

### 1. 注目ウィンドウの強調（JankyBorders & マウス追従）
- **枠線表示**: AeroSpace 起動時に `after-startup-command` 経由で自動起動します。手動で起動/停止・色を変更したい場合は以下を実行します：
  ```bash
  # 手動起動（例: アクティブ枠をシアン、非アクティブを非表示、太さ 4.0）
  nohup borders active_color=0xff59c7fa inactive_color=0x00000000 width=4.0 hidpi=on >/dev/null 2>&1 &

  # 停止したい場合
  killall borders
  ```
  色や太さを永続変更したい場合は [`aerospace/aerospace.toml`](aerospace/aerospace.toml) の `after-startup-command` を編集して `aerospace reload-config`（および `killall borders` 後に再起動）してください。
- **マウス追従**: `Option + H/J/K/L` などでフォーカスを移動すると、マウスカーソルが自動で移動先ウィンドウの中央（`move-mouse window-lazy-center`）へ追従します。

### 2. チートシートウィジェットの起動・終了
Dock の左右に、同じガラス枠でキーバインド一覧を表示します。左が AeroSpace / WezTerm、右が Vimium です。

```bash
# 起動
nohup ~/.config/aerospace/cheatsheet >/dev/null 2>&1 &

# 終了
killall cheatsheet
```
※ Dock のアイコン数やサイズ変更、`システム設定 > 外観 > Liquid Glass` の透明度変更に自動で追従します。右側の文言は `vimium/key-mappings` 先頭の `sheet:` 行です。

### 3. Vimium のキーを変える
[`vimium/key-mappings`](vimium/key-mappings) を編集します。`unmapAll` より下に書いた割り当てだけが有効です。反映するには Zen を終了してから次を実行します。

```bash
vimium/apply.sh
```

### 4. Obsidian の Vim を変える
[`obsidian/.obsidian.vimrc`](obsidian/.obsidian.vimrc) を編集してから次を実行し、Obsidian を再起動します。標準の Vim モードと Vimrc Support がオンである必要があります。

```bash
obsidian/apply.sh
```

基準は Vim / Neovim の初期キーです。半ページは `Ctrl-d` / `Ctrl-u`、タブ移動は `gt` / `gT`、タブの開閉は `Space t` / `Space q` / `Space Q`、履歴は `Ctrl-o` / `Ctrl-i` です。ペイン移動は WezTerm と同じ `Ctrl-q` のあとの `hjkl` です。閲覧画面、Hearth Home、Terminal のコンソールでも、ペイン移動は `Ctrl-q` のあとの `hjkl` です。コンソールのペインでは、葉を選んだあと Terminal 自身の入力へフォーカスを移します。コンソールでは、その移動以外のキーはシェルに渡します。`x` や `d` のような文字の編集は、編集画面だけです。

---

## ⌨️ AeroSpace Keybindings

| キーバインド | 動作 |
| :--- | :--- |
| `Option + D` | **Development** へ移動 (Cursor, Antigravity, WezTerm, Linear, Orca) |
| `Option + B` | **Browser** へ移動 (Zen, Spotify, Google Chrome, Safari) |
| `Option + N` | **Note** へ移動 (Obsidian, Apple Notes) |
| `Option + C` | **Chat** へ移動 (Discord, LINE, Slack) |
| `Option + A` | **AI** へ移動 (ChatGPT, Muse, Grok Bot, Gemini) |
| `Option + 1` | **1 (その他)** へ移動 (Bambu Studio, NordPass, NordVPN など未分類アプリ) |
| `Option + Shift + [D/B/N/C/A/1]` | フォーカス中のウィンドウを指定ワークスペースへ送る |
| `Option + H / J / K / L` | フォーカスを 左 / 下 / 上 / 右 へ移動 (Vim キーバインド) |
| `Option + Shift + H / J / K / L` | ウィンドウ位置を 左 / 下 / 上 / 右 へ入れ替え |
| `Option + - / ;` | フォーカス中のウィンドウを 縮小 / 拡大 |
| `Option + Shift + -` | ワークスペース内のウィンドウサイズを等倍に戻す |
| `Option + F` | タイル ⇄ フローティング 切り替え |
| `Option + Shift + F` | タイル ⇄ 横アコーディオン 切り替え |
| `Option + M` | フルスクリーン切り替え |

---

## 📁 Repository Structure

```
keybind2me/
├── aerospace/
│   ├── aerospace.toml   # AeroSpace 設定ファイル（JankyBorders・マウス追従含む）
│   └── hud.swift        # ノッチ HUD (Swift ソースコード)
├── cheatsheet/
│   └── cheatsheet.swift # Dock 左右の Liquid Glass チートシート (Swift ソースコード)
├── vimium/
│   ├── key-mappings    # Vimium のキー割り当てと、右側チートシートの文言
│   └── apply.sh        # Zen 終了時に key-mappings を Vimium へ書き込む
├── obsidian/
│   ├── .obsidian.vimrc # 編集画面の追加割り当て
│   ├── reading-vim/    # 閲覧画面と Hearth Home のスクロール、タブ、ペイン
│   └── apply.sh        # 保管庫へ vimrc と閲覧用プラグインをリンクする
├── wezterm/
│   ├── wezterm.lua      # WezTerm メイン設定
│   └── keybinds.lua     # WezTerm キーバインド設定
├── install.sh           # ワンライナー用セットアップスクリプト
└── README.md
```
