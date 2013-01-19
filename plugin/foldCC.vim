let s:save_cpo = &cpo| set cpo&vim




"=============================================================================
"NOTE: 互換性のため残してある。
"      foldCC#foldtext()を使うこと。
"USAGE: :set foldtext=foldCC#foldtext()
function! FoldCCtext() "{{{
  return foldCC#foldtext()
endfunction
"}}}


"=============================================================================
"NOTE: 互換性のため残してある。
"      foldCC#navi()を使うこと。
"USAGE: :echo foldCC#navi()
function! FoldCCnavi() "{{{
  return foldCC#navi()
endfunction "}}}


"=============================================================================
let &cpo = s:save_cpo| unlet s:save_cpo
