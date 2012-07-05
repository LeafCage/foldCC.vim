"au CursorHold * call MovedCC()
function! MovedCC()
  hi FoldTop gui=bold guibg=DarkBlue guifg=Red
  exe 'sy match FoldTop /\%'.v:foldstart.'l^./'
  hi FoldTop gui=bold guibg=DarkBlue guifg=Red
  exe 'sy match FoldTop /\%'.v:foldstart.'l.*/'
  exe 'sy match FoldTop /\%'.v:foldend.'l.*/'
  echo v:foldstart v:foldstart
endfunction

"au BufRead,BufNew * syn match FoldMarkerStart /{{{/ containedin=ALL "}}}
"au CursorHold * call Syntax_foldtop()
"au InsertEnter,InsertLeave,CmdwinEnter,FileType,BufWinEnter,BufHidden,BufWrite * call Syntax_foldtop()

"syn match FoldMarkerStart /{{{/ containedin=ALL "}}}
"hi FoldMarkerStart gui=bold guibg=LightRed guifg=LightBlue


function! Syntax_foldtop()
  if !exists('b:foldstarts')
    return
  endif
  hi FoldTop gui=bold guibg=DarkBlue guifg=Red
  for picked in b:foldstarts
    exe 'sy match FoldTop /^\%'.picked.'l\s*../'
  endfor
endfunction

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
  let linestr = s:rm_CmtAndFmr(v:foldstart)

  "切り詰めサイズをウィンドウに合わせる"{{{
  let regardMultibyte =strlen(linestr) -strdisplaywidth(linestr)

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


  "foldstartを強調表示させる（未完成）"{{{
"  if index(b:foldstarts, v:foldstart) == -1
"    call add(b:foldstarts, v:foldstart)
"  endif
"  "折り畳み行がずれたとき（気休め）
"  for picked in b:foldstarts
"    if picked +1 == v:foldstart || picked -1 == v:foldstart || foldlevel(picked) == 0
"      call remove(b:foldstarts, index(picked))
"    endif
"  endfor "}}}

  "redraw "タブページにFoldCCnaviを表示させているとき、カーソルの動きに合わせてリアルタイムに情報更新させる

  let linestr = s:arrange_multibyte_str(printf('%-'.alignment.'.'.alignment.'s', linestr))
  let linestr = substitute(linestr, '^\s*', '\0'.(v:foldlevel == 1 ? '' : v:folddashes), '')

  return printf('%s   %s'.    g:foldCCtext_printf.    '%s',
        \ linestr, v:folddashes,    v:foldend-v:foldstart+1, v:foldlevel,    v:folddashes)
endfunction
"}}}


function! s:picklist(list) "{{{
  "バッファ・ウィンドウを移ったときリセット
  let [stt,end] = [line('w0'),line('w$')]
  let list = a:list
  let cutedlist = []
  let oldpicked = 0
  for picked in list
    if picked < oldpicked
      call remove(list, index(list, picked))
      continue
    endif
    let oldpicked = picked
    "if picked <= end && picked >= stt
    "  call add(cutedlist,picked)
    "endif
  endfor
  return list
endfunction "}}}


function! FoldCCnavi() "{{{
  "wrk; 現在行の折り畳みナビゲート文字列を返す
  if foldlevel('.')
    let save_csr=winsaveview()
    let parentList=[]

    let ClosedFolding_firstline = foldclosed('.')
    "カーソル行が折り畳まれているとき"{{{
    if ClosedFolding_firstline != -1
      call insert(parentList, s:surgery_line(ClosedFolding_firstline) )
      if foldlevel('.') == 1
        call winrestview(save_csr)
        return join(parentList,' > ')
      endif

      normal! [z
      if foldclosed('.') ==ClosedFolding_firstline
        call winrestview(save_csr)
        return join(parentList,' > ')
      endif
    endif "}}}

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
    return join(parentList,' > ') "}}}

  else
    "折り畳みの中にいないとき
    return ''
  endif
endfunction
"}}}


function! s:rm_CmtAndFmr(lnum) "{{{
  "wrk; a:lnum行目の文字列を取得し、そこからcommentstringとfoldmarkersを除いたものを返す
  "rol; 折り畳みマーカー（とそれを囲むコメント文字）を除いた純粋な行の内容を得る
  let linestr = getline(a:lnum)

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

  let linestr = substitute(linestr,'\V\%('.comment[0].'\)\?\s\*'.foldmarkers[0].'\%(\d\+\)\?\s\*\%('.comment_end.'\)\?', '','')
  return linestr
endfunction "}}}


function! s:surgery_line(lnum) "{{{
  "wrk; a:lnum行目の内容を得て、マルチバイトも考慮しながら切り詰めを行ったものを返す
  let line = substitute(s:rm_CmtAndFmr(a:lnum),'\V\s','','g')
  let regardMultibyte = len(line) - strdisplaywidth(line)
  let alignment = g:foldCCnavi_shorten + regardMultibyte
  return s:arrange_multibyte_str(line[:alignment])
  "return s:arrange_multibyte_str(printf('%.'.alignment.'s', line) ) "違いは長い折り畳みの時末尾が表示されるか中央部が表示されるか
endfunction "}}}


"マルチバイト文字が途中で切れると発生する<83><BE>などの文字を除外させる
function! s:arrange_multibyte_str(str) "{{{
  return substitute(strtrans(a:str), '<\x\x>','','g')
endfunction "}}}





