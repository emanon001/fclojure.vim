" unite kind: fclojure
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

call fclojure#util#provide_boolean(s:)

call fclojure#util#lock_constants(s:)









" Variables {{{1

let s:kind = {
      \   'name': 'fclojure',
      \   'default_action': 'open',
      \   'action_table': {},
      \   'parents': ['openable'],
      \ }




" Interface {{{1

function! unite#kinds#fclojure#define()
  return s:kind
endfunction




" Core {{{1

let s:kind.action_table.open = {
      \   'is_selectable': s:TRUE,
      \   'description': 'open problems',
      \ }

function! s:kind.action_table.open.func(candidates) "{{{
  for c in a:candidates
    call fclojure#open_problem(c.action__problem_no, s:TRUE)
  endfor
endfunction
"}}}




" Epilogue {{{1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker
