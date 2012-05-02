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




" Variables {{{1

let s:callbacks_of_solve = []




" Interface {{{1

function! fclojure#open_problem_list(use_cache) " {{{2
  try
    let problem_list = fclojure#core#get_problem_list(a:use_cache)
  catch /^fclojure:/
    call fclojure#util#print_error(v:exception)
    return
  endtry
  call fclojure#viewer#open_problem_list(problem_list)
endfunction


function! fclojure#open_problem(problem_no, use_cache) " {{{2
  try
    let problem = fclojure#core#get_problem(a:problem_no, a:use_cache)
  catch /^fclojure:/
    call fclojure#util#print_error(v:exception)
    return
  endtry
  call fclojure#viewer#open_problem(problem)
endfunction


function! fclojure#solve_problem(problem_no, answer) " {{{2
  let result = fclojure#core#solve_problem(a:problem_no, a:answer)
  call s:notify_callbacks(a:problem_no, result)
endfunction


function! fclojure#add_callback_of_solve(callback) " {{{2
  call add(s:callbacks_of_solve, a:callback)
endfunction


function! fclojure#delete_callback_of_solve(callback) " {{{2
  call filter(s:callbacks_of_solve, 'v:val != a:callback')
endfunction


function! fclojure#name() " {{{2
  return s:PLUGIN_NAME
endfunction




" Core {{{1

function! s:notify_callbacks(...) " {{{2
  for C in s:callbacks_of_solve
    call call(C, a:000)
  endfor
endfunction




" Epilogue {{{1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker
