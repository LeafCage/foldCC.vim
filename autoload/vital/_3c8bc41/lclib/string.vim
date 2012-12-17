
"マルチバイト文字列をぶった切ったとき発生するゴミ文字を除去する
function! s:remove_multibyte_garbage(str)  "{{{
  return substitute(strtrans(a:str), '^\V\(<\x\x>\)\+\|\(<\x\x>\)\+\$', '', 'g')
endfunction "}}}

"strの末からwordcollectionにある文字を繋げてwordとして返す
function! s:gs_backmake_word(str, wordcollection) "{{{
  let strfoot = matchstr(a:str, '\V\'. a:wordcollection. '\$')
  let l = 0
  while l < len(strfoot)
    let l = len(strfoot)
    let strfoot = matchstr(a:str, '\V\'. a:wordcollection. '\?'. strfoot. '\$')
  endwhile
  return strfoot
endfunction
"}}}

"path名をドライブレターを消して/からはじまるように変換
function! s:gs_bufnamerize(path) "{{{
  return submatch(fnamemodify(a:path, ':p'), '^\u:', '', '')
endfunction
"}}}

