" Vim additional syntax: fclojure problem
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

if exists('b:current_syntax')
  finish
endif

let s:save_cpoptions = &cpoptions
set cpoptions&vim



" Core {{{1

runtime syntax/**/*clojure.vim

syntax region fclojureNonCode start="^#\d\+" end="^=\{78}"
syntax region fclojureResult start="^\*\{78}" end="^\*\{78}"
highlight default link fclojureNonCode Normal
highlight default link fclojureResult WarningMsg





" Epilogue {{{1

let b:current_syntax = 'fclojure-problem'

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker
