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

call fclojure#util#lock_constants(s:)




" Variables {{{1

let s:option_table = {}




" Interface {{{1

function! fclojure#option#get(name) " {{{2
  let not_exist = {}
  let option = get(s:option_table, a:name, not_exist)
  if option is not_exist
    throw fclojure#util#create_exception('IllegalArgument',
          \ printf('Option "%s" doesn''t exsist.', a:name))
  endif
  return option
endfunction


function! fclojure#option#init() " {{{2
  let user_option_table = get(g:, 'fclojure', {})
  call s:set_option('curl_command',
        \ get(user_option_table, 'curl_command', 'curl'))
  call s:set_option('data_dir',
        \ get(user_option_table, 'data_dir', '~/.fclojure'))
  call s:set_option('open_command',
        \ get(user_option_table, 'open_command', 'split'))
  call s:set_option('no_default_key_mappings',
        \ get(user_option_table, 'no_default_key_mappings', s:FALSE))
endfunction




" Core {{{1

function! s:set_option(var, val) " {{{2
  let s:option_table[a:var] = a:val
endfunction




" Epilogue {{{1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker
