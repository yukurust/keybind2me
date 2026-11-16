" keybind2me が管理する Obsidian Vim 設定。
" 基準は Vim / Neovim の初期キー。編集のキーは上書きしない。
" 反映: obsidian/apply.sh のあと、Obsidian を再起動する。
"
" Y は Neovim に合わせ、カーソルから行末までヤンクする。行全体は yy。
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
" Ctrl-q のあと h j k l   ペイン移動。WezTerm のリーダーと同じ
" Obsidian の Ctrl-q は初期状態で矩形選択なので、先に外す。矩形選択は Ctrl-v
" m `         マーク
"
" よくあるカスタマイズで、ここにも入れてあるもの:
" Space       リーダー
" Space Space クイックスイッチャー（ファイルを開く）
" Space /     保管庫の検索
" Space t     新しいタブ
" Space q     タブを閉じる
" Space Q     閉じたタブを戻す
" jk          インサートモードを抜ける
" clipboard   ヤンクと貼り付けをシステムクリップボードと共有

set clipboard=unnamed

imap jk <Esc>

" Space は初期状態で右へ1文字動く。外さないとリーダーにならない。
unmap <Space>
" Ctrl-q は初期状態で矩形選択。外さないとペイン移動にならない。
unmap <C-q>

exmap nextTab obcommand workspace:next-tab
exmap prevTab obcommand workspace:previous-tab
nmap gt :nextTab<CR>
nmap gT :prevTab<CR>

exmap switcher obcommand switcher:open
nmap <Space><Space> :switcher<CR>

exmap searchNotes obcommand global-search:open
nmap <Space>/ :searchNotes<CR>

exmap newTab obcommand workspace:new-tab
nmap <Space>t :newTab<CR>

exmap closeTab obcommand workspace:close
nmap <Space>q :closeTab<CR>

exmap reopenTab obcommand workspace:undo-close-pane
nmap <Space>Q :reopenTab<CR>

noremap Y y$

exmap focusLeft obcommand keybind2me-reading-vim:focus-left
exmap focusDown obcommand keybind2me-reading-vim:focus-down
exmap focusUp obcommand keybind2me-reading-vim:focus-up
exmap focusRight obcommand keybind2me-reading-vim:focus-right
nmap <C-q>h :focusLeft<CR>
nmap <C-q>j :focusDown<CR>
nmap <C-q>k :focusUp<CR>
nmap <C-q>l :focusRight<CR>
