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

let s:NONE = {}

" Vital"{{{
let s:V = fclojure#util#vital()
let s:F = s:V.import('System.Filepath')
"}}}

call fclojure#util#lock_constants(s:)




" Variables {{{1

let s:option_table = {}




" Interface {{{1

function! fclojure#option#get(name) " {{{2
  let option = get(s:option_table, a:name, s:NONE)
  if option is s:NONE
    throw fclojure#util#create_exception('IllegalArgument',
          \ printf('Option "%s" doesn''t exist.', a:name))
  endif
  return option
endfunction




" Core " {{{1

function! s:get_open_url_command() " {{{2
  " XXX
  if s:V.is_windows()
    return 'cmd /c start'
  elseif s:V.is_cygwin()
    return 'cygstart'
  elseif s:V.is_mac()
    return 'open'
  else
    return 'xdg-open'
  endif
endfunction


function! s:get_full_path(path) " {{{2
  return fnamemodify(expand(a:path), ':p')
endfunction




" Init {{{1

function! s:init_options() " {{{2
  let user_option_table = get(g:, 'fclojure', {})
  call s:set_option('curl_command',
        \ get(user_option_table, 'curl_command', 'curl'))
  call s:set_option('data_dir',
        \ s:get_full_path(get(user_option_table, 'data_dir', '~/.fclojure')))
  call s:set_option('answer_dir',
        \ s:get_full_path(get(user_option_table, 'answer_dir',
        \                     s:F.join(fclojure#option#get('data_dir'), 'answers'))))
  call s:set_option('open_buffer_command',
        \ get(user_option_table, 'open_buffer_command', 'split'))
  call s:set_option('no_default_key_mappings',
        \ get(user_option_table, 'no_default_key_mappings', s:FALSE))
  call s:set_option('open_url_command',
        \ get(user_option_table, 'open_url_command', s:get_open_url_command()))
endfunction


function! s:set_option(var, val) " {{{2
  let s:option_table[a:var] = a:val
endfunction

call s:init_options()




" Epilogue {{{1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker
