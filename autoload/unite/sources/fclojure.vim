" unite source: fclojure
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

let s:source = {
      \   'name': 'fclojure',
      \   'description': 'candidates from fclojure problem list',
      \ }




" Interface {{{1

function! unite#sources#fclojure#define()
  return s:source
endfunction




" Core {{{1

function! s:source.gather_candidates(args, context) " {{{2
  let problem_list = fclojure#core#get_problem_list(s:TRUE)
  let max_length_table = fclojure#util#get_problem_item_max_length_table(problem_list)
  return map(copy(problem_list),
        \ '{
        \   "word": s:problem_to_line(v:val, max_length_table),
        \   "kind": "fclojure",
        \   "source": self.name,
        \   "action__problem_no": v:val.no,
        \ }')
endfunction


function! s:problem_to_line(problem, max_length_table) " {{{2
  let p = map(copy(a:problem), 'fclojure#util#padding_right(
          \   fclojure#util#string_value_of_problem_item(v:val),
          \   a:max_length_table[v:key] + 1)')
  return printf('%s #%s %s %s %s', a:problem.is_solved ? '*' : ' ',
        \ p.no, p.title, p.difficulty, p.topics)
endfunction




" Epilogue {{{1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker
