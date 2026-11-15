" keybind2me が管理する Obsidian Vim 設定。
" 基準は Vim / Neovim の初期キー。編集のキーは上書きしない。
" 反映: obsidian/apply.sh のあと、Obsidian を再起動する。
"
" Vim と Neovim の初期キーはほぼ同じ。よく使う差は Y だけ。
" Vim の Y は行ヤンク（yy）。Neovim の Y は行末までヤンク（y$）。
"
" ノーマルモードの初期キー（両方）:
" h j k l     1文字 / 1行
" w b e       単語
" 0 ^ $       行頭 / 最初の非空白 / 行末
" gg G        ファイル先頭 / 末尾
" Ctrl-d/u    半ページ。Ctrl-f/b は1ページ。Ctrl-e/y は1行スクロール
" H M L       画面の上 / 中央 / 下
" f F t T     その行の文字へ移動
" / ? n N     検索
" i a o O     挿入。v V Ctrl-v は選択
" d c y       削除 / 変更 / ヤンク。x は1文字削除。p は貼り付け
" u Ctrl-r    元に戻す / やり直す
" J           行の結合
" gt gT       次のタブ / 前のタブ
" Ctrl-o/i    ジャンプリストを戻る / 進む
" Ctrl-w のあと h j k l   ウィンドウ移動
" m `         マーク
"
" よくあるカスタマイズで、ここにも入れてあるもの:
" Space       リーダー
" Space Space クイックスイッチャー（ファイルを開く）
" Space /     保管庫の検索
" jk          インサートモードを抜ける
" clipboard   ヤンクと貼り付けをシステムクリップボードと共有

set clipboard=unnamed

imap jk <Esc>

exmap nextTab obcommand workspace:next-tab
exmap prevTab obcommand workspace:previous-tab
nmap gt :nextTab
nmap gT :prevTab

exmap switcher obcommand switcher:open
nmap <Space><Space> :switcher

exmap searchNotes obcommand global-search:open
nmap <Space>/ :searchNotes
