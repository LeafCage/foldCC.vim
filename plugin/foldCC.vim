if expand('<sfile>:p')!=#expand('%:p') && exists('g:loaded_foldCC')| finish| endif| let g:loaded_foldCC = 1
let s:save_cpo = &cpo| set cpo&vim
scriptencoding utf-8
"=============================================================================
let g:foldCCtext_maxchars = get(g:, 'foldCCtext_maxchars', 78)
let g:foldCCtext_head = get(g:, 'foldCCtext_head', 'v:folddashes. " "')
let g:foldCCtext_tail = get(g:, 'foldCCtext_tail', 'v:foldend - v:foldstart+1')
let g:foldCCtext_enable_autofdc_adjuster = get(g:, 'foldCCtext_enable_autofdc_adjuster', 0)
let g:foldCCnavi_maxchars = get(g:, 'foldCCnavi_maxchars', 60)


"=============================================================================
"Main:
function! FoldCCtext() "{{{
  if g:foldCCtext_enable_autofdc_adjuster && v:foldlevel > &fdc-1
    let &fdc = v:foldlevel + 1
  endif
  let headline = getline(v:foldstart)
  let head = g:foldCCtext_head=='' ? '' : eval(g:foldCCtext_head)
  let tail = g:foldCCtext_tail=='' ? '' : ' '. eval(g:foldCCtext_tail)
  let headline = s:_adjust_headline(headline, strlen(head)+strlen(tail))
  return substitute(headline, '^\s*\ze', '\0'. head, ''). tail
endfunction
"}}}

function! FoldCCnavi() "{{{
  let foldheads = FoldCCnavi_get_headlines()
  if empty(foldheads)
    return ''
  endif
  return join(foldheads, ' > ')
endfunction
"}}}
function! FoldCCnavi_get_headlines() "{{{
  if !foldlevel('.')
    return []
  endif
  let save_view = winsaveview()
  let gatherer = s:newFoldGatherer()
  try
    call gatherer.gather_headlines()
    return gatherer.get_headlines()
  finally
    call winrestview(save_view)
  end
endfunction
"}}}


"=============================================================================
"Misc:
function! s:_remove_commentstring_and_foldmarkers(str) "{{{
  let cms = matchlist(&cms, '\(.\{-}\)%s\(.\{-}\)')
  let [cmsbgn, cmsend] = cms==[] ? ['', ''] : [substitute(cms[1], '\s', '', 'g'), cms[2]]
  let foldmarkers = split(&foldmarker, ',')
  return substitute(a:str, '\%('.cmsbgn.'\)\?\s*'.foldmarkers[0].'\%(\d\+\)\?\s*\%('.cmsend.'\)\?', '','')
endfunction "}}}
function! s:_get_colwidth() "{{{
  return winwidth(0) - &foldcolumn - (!&number ? 0 : max([&numberwidth, len(line('$'))]))
endfunction
"}}}
function! s:_remove_multibyte_garbage(str) "{{{
  return substitute(substitute(strtrans(a:str), '^\%(<\x\x>\)\+\|\%(<\x\x>\)\+$', '', 'g'), '\^I', "\t", 'g')
endfunction
"}}}
function! s:_adjust_headline(headline, reducelen) "{{{
  let headline = s:_remove_commentstring_and_foldmarkers(a:headline)
  let colwidth = s:_get_colwidth()
  let truncatelen = (colwidth < g:foldCCtext_maxchars ? colwidth : g:foldCCtext_maxchars) - a:reducelen
  let dispwidth = strdisplaywidth(headline)
  if dispwidth < truncatelen
    let multibyte_widthgap = strlen(headline) - dispwidth
    let headlinewidth = truncatelen + multibyte_widthgap
    return printf('%-*s', headlinewidth, headline)
  end
  let ret = ''
  let len = 0
  for char in split(headline, '\zs')
    let len += strdisplaywidth(char)
    if len > truncatelen
      break
    end
    let ret .= char
  endfor
  return strdisplaywidth(ret)==truncatelen ? ret : ret.' '
endfunction
"}}}

let s:FoldGatherer = {}
function! s:newFoldGatherer() "{{{
  let obj = copy(s:FoldGatherer)
  let obj.headlines = []
  return obj
endfunction
"}}}
function! s:FoldGatherer._register_headline(headline) "{{{
  let headline = s:_remove_commentstring_and_foldmarkers(a:headline)
  let headline = substitute(substitute(line, '^\s*\|\s$', '', 'g'), '\s\+', ' ', 'g')
  let multibyte_widthgap = len(headline) - strdisplaywidth(headline)
  let truncatelen = g:foldCCnavi_maxchars + multibyte_widthgap
  let headline = s:_remove_multibyte_garbage(headline[:truncatelen])
  call insert(self.headlines, headline)
endfunction
"}}}
function! s:FoldGatherer._gather_outer_headlines() "{{{
  if mode() =~ '[sS]' "FIXME:selectmodeでnormal!コマンドを使うとE523が出る問題の暫定的解消
    return
  endif
  let row = 0
  try
    while 1
      keepj normal! [z
      if row == line('.') "FIXME:同一行にFoldingMarkerが重なってると無限ループになる問題の暫定的解消
        break
      endif
      call self._register_headline(getline('.'))
      if foldlevel('.') == 1
        break
      endif
      let row = line('.')
    endwhile
  catch
    ec 'foldCCnavi: 何かしらのエラーが起こりました g:foldCC_err参照'
    let g:foldCC_err = v:exception
  endtry
endfunction
"}}}
function! s:FoldGatherer.gather_headlines() "{{{
  let closed_row = foldclosed('.')
  if closed_row == -1
    call self._gather_outer_headlines()
    return
  endif
  call self._register_headline(getline(closed_row))
  if foldlevel('.') == 1
    return
  endif
  "閉じた折り畳みの中の、途中の行にいた場合
  keepj normal! [z
  if foldclosed('.') == closed_row
    return
  endif
  call self._gather_outer_headlines()
  return
endfunction
"}}}
function! s:FoldGatherer.get_headlines() "{{{
  return self.headlines
endfunction
"}}}

"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
