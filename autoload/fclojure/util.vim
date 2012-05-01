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




" Interface {{{1

function! fclojure#util#create_exception(type, message) " {{{2
  return printf('%s: %s: %s', fclojure#name(), a:type, a:message)
endfunction


function! fclojure#util#print_error(message) " {{{2
  let head_messages = [printf('%s: %s', fclojure#name(), 'The error occurred.')]
  let main_messages = type(a:message) == type([]) ? copy(a:message) : [a:message]
  " Remove prefix string of exception.
  call map(main_messages,
        \  'matchstr(v:val, ''^\%('' . fclojure#name() . '': [^:]*:\)\=\s*\zs.*'')')

  echohl ErrorMsg
  for m in head_messages + main_messages
    echomsg m
  endfor
  echohl None
endfunction


function! fclojure#util#padding_left(str, max, ...) " {{{2
  let padding = get(a:000, 0, ' ')
  return repeat(padding, a:max - s:V.strchars(a:str)) . a:str
endfunction


function! fclojure#util#padding_right(str, max, ...) " {{{2
  let padding = get(a:000, 0, ' ')
  return a:str . repeat(padding, a:max - s:V.strchars(a:str))
endfunction


function! fclojure#util#split_by_length(str, length) " {{{2
  let ret = []
  let _ = a:str
  while strchars(_) > 0
    call add(ret, strpart(_, 0, a:length))
    let _ = strpart(_, a:length)
  endwhile
  return ret
endfunction


function! fclojure#util#vital() " {{{2
  return vital#of(fclojure#name())
endfunction


function! fclojure#util#provide_boolean(scope) " {{{2
  let a:scope.FALSE = 0
  let a:scope.TRUE = !a:scope.FALSE
endfunction


function! fclojure#util#lock_constants(scope) " {{{2
  for name in keys(a:scope)
    if name =~# '^\u'
      lockvar! a:scope[name]
    endif
  endfor
endfunction


function! fclojure#util#get_max_length(str_list) " {{{2
  let max = s:V.strchars(a:str_list[0])
  for s in a:str_list
    let max = s:V.strchars(s) > max ? s:V.strchars(s) : max
  endfor
  return max
endfunction


function! fclojure#util#get_problem_item_max_length_table(problem_list) " {{{2
  let max_length_table = map(copy(a:problem_list[0]), '0')
  for problem in a:problem_list[1:]
    let _ = map(copy(problem),
          \ 's:V.strchars(fclojure#util#string_value_of_problem_item(v:val))')
    call map(max_length_table, 'v:val > _[v:key] ? v:val : _[v:key]')
  endfor
  return max_length_table
endfunction


function! fclojure#util#string_value_of_problem_item(val) " {{{2
  if s:V.is_string(a:val) | return a:val | endif
  if s:V.is_numeric(a:val) | return string(a:val) | endif
  if s:V.is_list(a:val) | return join(a:val) | endif
  throw fclojure#util#create_exception('Argument', 'Variable type is incorrect.')
endfunction




" Init {{{1

" Vital
let s:V = fclojure#util#vital()

call fclojure#util#provide_boolean(s:)

call fclojure#util#lock_constants(s:)




" Epilogue {{{1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker
