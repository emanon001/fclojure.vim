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

call fclojure#util#define_boolean(s:)

" Vital"{{{
let s:V = fclojure#util#vital()
"}}}

call fclojure#util#lock_constants(s:)




" Variables {{{1

let s:callback_table = {}




" Interface {{{1

function! fclojure#open_problem_list(use_cache) " {{{2
  try
    let problem_list = fclojure#core#get_problem_list(a:use_cache)
    call fclojure#viewer#open_problem_list(problem_list)
  catch /.*/
    call fclojure#util#print_error(fclojure#util#list(v:exception, v:throwpoint))
  endtry
endfunction


function! fclojure#open_problem(problem_no, use_cache) " {{{2
  try
    let problem = fclojure#core#get_problem(a:problem_no, a:use_cache)
    call fclojure#viewer#open_problem(problem)
  catch /.*/
    call fclojure#util#print_error(fclojure#util#list(v:exception, v:throwpoint))
  endtry
endfunction


function! fclojure#open_answer_column(problem_no) " {{{2
  try
    call fclojure#viewer#open_answer_column(a:problem_no)
  catch /.*/
    call fclojure#util#print_error(fclojure#util#list(v:exception, v:throwpoint))
  endtry
endfunction


function! fclojure#solve_problem(problem_no, answer) " {{{2
  try
    let result = fclojure#core#solve_problem(a:problem_no, a:answer)
    call s:notify_callbacks('solve-problem', a:problem_no, result)
  catch /.*/
    call fclojure#util#print_error(fclojure#util#list(v:exception, v:throwpoint))
  endtry
endfunction


function! fclojure#open_top_url() " {{{2
  try
    call s:open_url(fclojure#core#get_top_url())
  catch /.*/
    call fclojure#util#print_error(fclojure#util#list(v:exception, v:throwpoint))
  endtry
endfunction


function! fclojure#open_log_in_url() " {{{2
  try
    call s:open_url(fclojure#core#get_log_in_url())
  catch /.*/
    call fclojure#util#print_error(fclojure#util#list(v:exception, v:throwpoint))
  endtry
endfunction


function! fclojure#open_settings_url() " {{{2
  try
    call s:open_url(fclojure#core#get_settings_url())
  catch /.*/
    call fclojure#util#print_error(fclojure#util#list(v:exception, v:throwpoint))
  endtry
endfunction


function! fclojure#open_problem_list_url() " {{{2
  try
    call s:open_url(fclojure#core#get_problem_list_url())
  catch /.*/
    call fclojure#util#print_error(fclojure#util#list(v:exception, v:throwpoint))
  endtry
endfunction


function! fclojure#open_problem_url(problem_no) " {{{2
  try
    call s:open_url(fclojure#core#get_problem_url(a:problem_no))
  catch /.*/
    call fclojure#util#print_error(fclojure#util#list(v:exception, v:throwpoint))
  endtry
endfunction


function! fclojure#open_solve_url(problem_no) " {{{2
  try
    call s:open_url(fclojure#core#get_solve_url(a:problem_no))
  catch /.*/
    call fclojure#util#print_error(fclojure#util#list(v:exception, v:throwpoint))
  endtry
endfunction


function! fclojure#add_callback(event, callback) " {{{2
  if !has_key(s:callback_table, a:event)
    let s:callback_table[a:event] = []
  endif
  call add(s:callback_table[a:event], a:callback)
endfunction


function! fclojure#delete_callback(event, callback) " {{{2
  if !has_key(s:callback_table, a:event)
    return
  endif
  call filter(s:callback_table[a:event], 'v:val != a:callback')
endfunction




" Core {{{1

function! s:notify_callbacks(event, ...) " {{{2
  if !has_key(s:callback_table, a:event)
    return
  endif
  for C in s:callback_table[a:event]
    call call(C, a:000)
  endfor
endfunction


function! s:open_url(url) " {{{2
  call s:V.system(fclojure#option#get('open_url_command') . ' ' . a:url)
endfunction




" Epilogue {{{1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker
