let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
"Variables

"foldtextが長すぎるときこの値に切り詰め（既定:78）
let g:foldCCtext_maxchars =
  \ exists('g:foldCCtext_maxchars') ? g:foldCCtext_maxchars : 78


"foldheadの前に表示される内容
"評価されるので文字列を指定したい場合は'"文字列"'という形などにする
let g:foldCCtext_head =
  \ exists('g:foldCCtext_head') ? g:foldCCtext_head : 'v:folddashes'


"foldheadの後ろに表示される内容
"評価されるので文字列を指定したい場合は'"文字列"'という形などにする
let g:foldCCtext_tail =
  \ exists('g:foldCCtext_tail') ? g:foldCCtext_tail :
  \ 'printf("   %s[%4d lines  Lv%-2d]%s",'.
  \ ' v:folddashes, v:foldend-v:foldstart+1, v:foldlevel, v:folddashes)'


"foldが深いとき、自動で'foldcolumn'の値を調整する機能を使うかどうか
let g:foldCCtext_enable_autofdc_adjuster =
  \ exists('g:foldCCtext_enable_autofdc_adjuster') ? g:foldCCtext_enable_autofdc_adjuster : 0


"折畳表示が長すぎるときこの値で切り詰め（既定:60）
let g:foldCCnavi_maxchars =
  \ exists('g:foldCCnavi_maxchars') ? g:foldCCnavi_maxchars : 60


"=============================================================================
let s:V = vital#of('foldCC')
let s:VLSt = s:V.import('Lclib.String')

"USAGE: :set foldtext=foldCC#foldtext()
function! foldCC#foldtext()
  if g:foldCCtext_enable_autofdc_adjuster && v:foldlevel > &fdc-1
    call setwinvar(0, '&fdc', v:foldlevel+1)
  endif
  let foldhead = foldCC#__remove_commentstring_and_foldmarkers(getline(v:foldstart))
  let head = g:foldCCtext_head == '' ? '' : eval(g:foldCCtext_head)
  let tail = g:foldCCtext_tail == '' ? '' : eval(g:foldCCtext_tail)

  let truncate_num = s:__get_truncate_num(foldhead, head, tail)
  let foldhead = printf('%-'. truncate_num. '.'. truncate_num. 's', foldhead)
  let foldhead = s:VLSt.remove_multibyte_garbage(foldhead)
  let foldhead = substitute(foldhead, '\^I', '	', 'g')
  let foldhead = substitute(foldhead, '^\s*\ze\S\|^', '\0'. head, '')

  return foldhead. tail
endfunction "}}}


"=============================================================================
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
endfunction "}}}


"=============================================================================
"USAGE: :echo foldCC#navilist()
function! foldCC#navilist() "{{{
  "wrk; 現在行の折り畳みナビゲート文字列を返す
  let foldheads = s:get_navilist()
  if empty(foldheads)
    return ''
  endif
  return join(foldheads, ' > ')
endfunction "}}}


"=============================================================================
function! foldCC#__remove_commentstring_and_foldmarkers(str) "{{{
  let cmss = split(&cms, '%s')
  if &cms =~? '^%s' "コメント文字が定義されてない時の対応
    call insert(cmss,'')
  endif
  let cmss[0] = substitute(cmss[0],'\s','','g') "コメント文字に空白文字が含まれているときの対応

  let cms_end =''
  if len(cmss) > 1
    let cms_end = cmss[1]
  endif
  let foldmarkers = split(&foldmarker, ',')

  return substitute(a:str,'\V\%('.cmss[0].'\)\?\s\*'.foldmarkers[0].'\%(\d\+\)\?\s\*\%('.cms_end.'\)\?', '','')
endfunction "}}}


"=============================================================================
function! s:get_navilist() "{{{
  let foldheads = []
  if !foldlevel('.') "折り畳みにいない
    return foldheads
  endif
  let save_view = winsaveview()

  if s:__cv_add_crr_closedfoldhead(foldheads)
    call winrestview(save_view)
    return foldheads
  endif

  call s:__cv_collect_foldheads(foldheads)

  call winrestview(save_view)
  return foldheads
endfunction
"}}}

function! s:__cv_add_crr_closedfoldhead(foldheads) "{{{
  let foldc_num = foldclosed('.')
  if foldc_num == -1
    return 0
  endif

  call insert(a:foldheads, s:___surgery_line(getline(foldc_num)))
  if foldlevel('.') == 1
    return 1
  endif

  "閉じた折り畳みの中の、途中の行にいた場合
  keepj normal! [z
  if foldclosed('.') == foldc_num
    return 1
  endif
endfunction
"}}}
function! s:__cv_collect_foldheads(foldheads) "{{{
  if mode() =~ '[sS]' "FIXME:selectmodeでnormal!コマンドを使うとE523が出る問題の暫定的解消
    return
  endif

  "折畳を再帰的に戻れるとき
  let i = 0
  try
    while 1
      keepj normal! [z
      if i == line('.') "FIXME:同一行にFoldingMarkerが重なってると無限ループになる問題の暫定的解消
        break
      endif

      call insert(a:foldheads, s:___surgery_line(getline('.')))
      if foldlevel('.') == 1
        break
      endif
      let i = line('.')
    endwhile
  catch
    ec 'foldCCnavi: 何かしらのエラーが起こりました g:foldCC_err参照'
    let g:foldCC_err = v:exception
  endtry
endfunction
"}}}

function! s:___surgery_line(str) "{{{
  let foldhead = foldCC#__remove_commentstring_and_foldmarkers(a:str)
  let foldhead = substitute(substitute(foldhead, '^\s*\|\s$', '', 'g'), '\s\+', ' ', 'g')

  let multibyte_width_diff = len(foldhead) - strdisplaywidth(foldhead)
  let truncate_num = g:foldCCnavi_maxchars + multibyte_width_diff
  return s:VLSt.remove_multibyte_garbage(foldhead[:truncate_num])
  "return s:VLSt.remove_multibyte_garbage(printf('%.'.alignment.'s', foldhead) ) "違いは長い折り畳みの時末尾が表示されるか中央部が表示されるか
endfunction "}}}
"=============================================================================
let &cpo = s:save_cpo| unlet s:save_cpo
