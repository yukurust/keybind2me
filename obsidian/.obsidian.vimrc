" keybind2me が管理する Obsidian Vim 設定。
" Vimrc Support が保管庫直下の .obsidian.vimrc として読む。
" 反映: obsidian/apply.sh のあと、Obsidian を再起動する。
"
" Vimium（vimium/key-mappings）と同じ文字でも、ここでは文章編集の Vim である。
" 下の表はノーマルモード。編集を壊すキーは割り当てない。
"
" キー    Vimium                         Obsidian（標準の Vim モード）
" j/k     上下スクロール                  上下の行へ移動
" h/l     左右スクロール                  左右の文字へ移動
" gg / G  ページ先頭 / 末尾               ファイル先頭 / 末尾
" d / u   半ページ下 / 上                 削除オペレータ / 元に戻す
" Ctrl-d / Ctrl-u                         半ページ下 / 上（こちらが Vimium の d / u に近い）
" f / F   リンクヒント                    文字検索 / 逆方向の文字検索
" o / O   ページを開く                    下 / 上に行を挿入
" H / L   履歴を戻る / 進む               画面の上端 / 下端へ
" J / K   前のタブ / 次のタブ             行の結合 / （標準では未使用に近い）
" x / X   タブを閉じる / 復元             カーソル位置の文字を削除
" r       再読み込み                      1文字置換
" t       新しいタブ                      文字まで移動（till）
" yy      URL をコピー                    行をヤンク
" p / P   コピーした URL を開く           貼り付け
" / n N   ページ内検索                    ノート内検索（動作は近い）
" i v V   モード切替                      同じ
" gt / gT 次のタブ / 前のタブ             標準ではタブ移動しない。下で Vimium に揃える
" [[ ]]   前のページ / 次のページ         前の見出し / 次の見出し（Vimrc Support が割り当て済み）
" gf      次のフレーム                    カーソル下のリンクを開く（Vimrc Support が割り当て済み）
" ?       ヘルプ                          逆方向検索

" タブ。Vimium の gt / gT と同じ。J / K は行結合に使われているので触らない。
exmap nextTab obcommand workspace:next-tab
exmap prevTab obcommand workspace:previous-tab
nmap gt :nextTab
nmap gT :prevTab
