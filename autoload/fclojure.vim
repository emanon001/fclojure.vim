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

let s:save_cpoptions = &cpoptions
set cpoptions&vim




" Constants {{{1

let s:PLUGIN_NAME = expand('<sfile>:t:r')

lockvar! s:PLUGIN_NAME




" Interface {{{1

function! fclojure#open_problem_list() " {{{2
  try
    let problem_list = fclojure#core#get_problem_list()
  catch /^fclojure:/
    call fclojure#util#print_error(v:exception)
    return
  endtry
  call fclojure#viewer#open_problem_list(problem_list)
endfunction


function! fclojure#open_problem(problem_no) " {{{2
  try
    let problem = fclojure#core#get_problem(a:problem_no)
  catch /^fclojure:/
    call fclojure#util#print_error(v:exception)
    return
  endtry
  call fclojure#viewer#open_problem(problem)
endfunction


function! fclojure#solve_problem(problem_no, answer, ...) " {{{2
  let F = get(a:000, 0, function('s:default_callback_of_solve'))
  let result = fclojure#core#solve_problem(a:problem_no, a:answer)
  call F(a:problem_no, result)
endfunction


function! fclojure#name() " {{{2
  return s:PLUGIN_NAME
endfunction




" Core {{{1

function! s:default_callback_of_solve(problem_no, result) " {{{2
  call fclojure#viewer#notify_result_of_solve(a:problem_no, a:result)
endfunction




" Epilogue {{{1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker
