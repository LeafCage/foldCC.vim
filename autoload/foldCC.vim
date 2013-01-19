let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let s:V = vital#of('foldCC')
let s:VLSt = s:V.import('Lclib.String')

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
function! foldCC#ret_navilist() "{{{
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
