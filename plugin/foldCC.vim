let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let s:V = vital#of('foldCC')
let s:VLSt = s:V.import('Lclib.String')

"=============================================================================
"Variables

"foldheadが長すぎるときこの値に切り詰め（既定:78）
let g:foldCCtext_maxchars =
  \ exists('g:foldCCtext_maxchars') ? g:foldCCtext_maxchars : 78


"foldtextの前に表示される内容
"評価されるので文字列を指定したい場合は'"文字列"'という形などにする
let g:foldCCtext_head =
  \ exists('g:foldCCtext_head') ? g:foldCCtext_head : 'v:folddashes'


"foldtextの後ろに表示される内容
"評価されるので文字列を指定したい場合は'"文字列"'という形などにする
let g:foldCCtext_tail =
  \ exists('g:foldCCtext_tail') ? g:foldCCtext_tail :
  \ 'printf("   %s[%4d lines  Lv%-2d]%s",'.
  \ ' v:folddashes, v:foldend-v:foldstart+1, v:foldlevel, v:folddashes)'


"折畳表示が長すぎるときこの値で切り詰め（既定:60）
let g:foldCCnavi_maxchars =
  \ exists('g:foldCCnavi_maxchars') ? g:foldCCnavi_maxchars : 60




"=============================================================================
"USAGE: :set foldtext=FoldCCtext()
function! FoldCCtext() "{{{
  let foldhead = foldCC#__remove_commentstring_and_foldmarkers(getline(v:foldstart))
  let head = g:foldCCtext_head == '' ? '' : eval(g:foldCCtext_head)
  let tail = g:foldCCtext_tail == '' ? '' : eval(g:foldCCtext_tail)

  let truncate_num = s:__get_truncate_num(foldhead, head, tail)
  let foldhead = printf('%-'. truncate_num. '.'. truncate_num. 's', foldhead)
  let foldhead = s:VLSt.remove_multibyte_garbage(foldhead)
  let foldhead = substitute(foldhead, '\^I', '	', 'g')
  let foldhead = substitute(foldhead, '^\s*\ze\S\|^', '\0'. head, '')

  return foldhead. tail
endfunction
"}}}

function! s:__get_truncate_num(str, head, tail) "{{{
  let col_len = winwidth(0) - &foldcolumn
  if &number
    let col_len -= max([&numberwidth, len(line('$'))])
  endif
  if col_len > g:foldCCtext_maxchars
    let col_len = g:foldCCtext_maxchars
  endif

  let multibyte_width_diff = strlen(a:str) - strdisplaywidth(a:str)

  return col_len - strlen(a:head) - strlen(a:tail) + multibyte_width_diff
    "issue:multibyte_width_diffで足される分が多い （61桁をオーバーして切り詰められてる場合
endfunction
"}}}


"=============================================================================
"USAGE: :echo FoldCCnavi()
function! FoldCCnavi() "{{{
  "wrk; 現在行の折り畳みナビゲート文字列を返す
  let foldheads = foldCC#ret_navilist()
  if empty(foldheads)
    return ''
  endif
  return join(foldheads, ' > ')
endfunction
"}}}


"=============================================================================
let &cpo = s:save_cpo| unlet s:save_cpo
