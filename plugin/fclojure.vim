" 4Clojure client for Vim.
" Author:  emanon001 <emanon001@gmail.com>
" License: DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE, Version 2 {{{
"     This program is free software. It comes without any warranty, to
"     the extent permitted by applicable law. You can redistribute it
"     and/or modify it under the terms of the Do What The Fuck You Want
"     To Public License, Version 2, as published by Sam Hocevar. See
"     http://sam.zoy.org/wtfpl/COPYING for more details.
" }}}

" Prologue {{{1

scriptencoding utf-8

if exists('g:loaded_fclojure')
  finish
endif

let s:save_cpoptions = &cpoptions
set cpoptions&vim




" Commands {{{1

command! -nargs=0 -bang FClojureOpenProblemList
      \ call fclojure#open_problem_list('<bang>' == '')

command! -nargs=1 -bang FClojureOpenProblem
      \ call fclojure#open_problem(<args>, '<bang>' == '')

command! -nargs=1 FClojureOpenAnswerColumn
      \ call fclojure#open_answer_column(<args>)




" Epilogue {{{1

let g:loaded_fclojure = 1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker
