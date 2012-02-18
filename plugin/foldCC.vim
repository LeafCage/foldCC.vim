
"各種変数 "{{{
"g:foldCCtext_shorten foldtextが長すぎるときこの値に切り詰め（規定:77）
if !exists('g:foldCCtext_shorten')
  let g:foldCCtext_shorten = 77
endif

"g:foldCCtext_printf foldtextの後ろに表示される内容（規定:'[%4d lines  Lv%-2d]'）
if !exists('g:foldCCtext_printf')
  let g:foldCCtext_printf = '[%4d lines  Lv%-2d]'
endif

"g:foldCCtext_printf_strlen g:foldCCtext_printfで表示される文字数（規定:21）
" g:foldCCtext_printfを変更したときには数え直して変更してください
" 将来スクリプトローカル化して自動で数えるようにしたいなぁ（願望）
if !exists('g:foldCCtext_printf_strlen')
  let g:foldCCtext_printf_strlen = 18
endif

"g:foldCCnavi_shorten 折畳表示が長すぎるときこの値で切り詰め（規定:60）
if !exists('g:foldCCnavi_shorten')
  let g:foldCCnavi_shorten = 60
endif
 "}}}


"折り畳み関数"{{{
function! FoldCCtext()
  "rol; set foldtext=FoldCCtext()に設定して折り畳んだときのテキスト生成

  "表示するテキストの作成（折り畳みマーカーを除去）
  let line = s:rm_CmtAndFmr(v:foldstart)

  "切り詰めサイズをウィンドウに合わせる"{{{
  let regardMultibyte =strlen(line) -strdisplaywidth(line)

  let line_width = winwidth(0) - &foldcolumn
  if &number == 1 "行番号表示オンのとき
      let line_width -= max([&numberwidth, len(line('$'))])
  endif

  if line_width > g:foldCCtext_shorten
    let line_width = g:foldCCtext_shorten
  endif

  let alignment = line_width - g:foldCCtext_printf_strlen+3 - 6 + regardMultibyte
    "g:foldCCtext_printf_strlenはprintf()で消費する分、3はつなぎの空白文字、6はfolddasesを使うための余白
    "issue:regardMultibyteで足される分が多い （61桁をオーバーして切り詰められてる場合
  "}}} obt; alignment

  return printf('%-'.alignment.'.'.alignment.'s   %s'.    g:foldCCtext_printf.    '%s',
        \ line,v:folddashes,    v:foldend-v:foldstart+1,v:foldlevel,    v:folddashes)
endfunction
"}}}


function! FoldCCnavi() "{{{
  "wrk; 現在行の折り畳みナビゲート文字列を返す
  if foldlevel('.')
    let save_csr=winsaveview()
    let parentList=[]

    "カーソル行が折り畳まれているとき"{{{
    let whtrClosed = foldclosed('.')
    if whtrClosed !=-1
      call insert(parentList, s:surgery_line(whtrClosed) )
      if foldlevel('.') == 1
        call winrestview(save_csr)
        return join(parentList,' > ')
      endif

      normal! [z
      if foldclosed('.') ==whtrClosed
        call winrestview(save_csr)
        return join(parentList,' > ')
      endif
    endif"}}}

    "折畳を再帰的に戻れるとき"{{{
    let geted_linenr = 0
    while 1
      normal! [z
      if geted_linenr == line('.') "同一行にFoldingMarkerが重なってると無限ループになる問題の暫定的解消
        break
      endif

      call insert(parentList, s:surgery_line('.') )
      if foldlevel('.') == 1
        break
      endif
      let geted_linenr = line('.')
    endwhile
    call winrestview(save_csr)
    return join(parentList,' > ')"}}}

  else
    "折り畳みの中にいないとき
    return ''
  endif
endfunction
"}}}


function! s:rm_CmtAndFmr(lnum)"{{{
  "wrk; a:lnum行目の文字列を取得し、そこからcommentstringとfoldmarkersを除いたものを返す
  "rol; 折り畳みマーカー（とそれを囲むコメント文字）を除いた純粋な行の内容を得る
  let line = getline(a:lnum)

  let comment = split(&commentstring, '%s')
  if &commentstring =~? '^%s' "コメント文字が定義されてない時の対応
    call insert(comment,'')
  endif
  let comment[0] = substitute(comment[0],'\s','','g') "コメント文字に空白文字が含まれているときの対応

  let comment_end =''
  if len(comment) > 1
    let comment_end = comment[1]
  endif
  let foldmarkers = split(&foldmarker, ',')

  let line = substitute(line,'\V\%('.comment[0].'\)\?\s\*'.foldmarkers[0].'\%(\d\+\)\?\s\*\%('.comment_end.'\)\?', '','')
  return line
endfunction"}}}


function! s:surgery_line(lnum)"{{{
  "wrk; a:lnum行目の内容を得て、マルチバイトも考慮しながら切り詰めを行ったものを返す
  let line = substitute(s:rm_CmtAndFmr(a:lnum),'\V\s','','g')
  let regardMultibyte = len(line) - strdisplaywidth(line)
  let alignment = g:foldCCnavi_shorten + regardMultibyte
  return line[:alignment]
endfunction"}}}


