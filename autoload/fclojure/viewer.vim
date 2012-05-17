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

" TODO: Set optional max line length.
let s:MAX_LINE_LENGTH = 78

" Vital"{{{
let s:V = fclojure#util#vital()
"}}}

call fclojure#util#lock_constants(s:)




" Variables {{{1

let s:problem_list_bufnr = -1
let s:problem_view_table =  {}
let s:answer_column_view_table = {}




" Interface {{{1

function! fclojure#viewer#open_problem_list(problem_list) " {{{2
  let bufnr = s:problem_list_bufnr
  if bufexists(bufnr)
    call s:move_to_buffer(bufnr)
    return
  endif
  call s:create_problem_list_buffer(a:problem_list)
endfunction


function! fclojure#viewer#open_problem(problem) " {{{2
  let bufnr = get(get(s:problem_view_table, a:problem.no, {}), 'bufnr', -1)
  if bufexists(bufnr)
    call s:move_to_buffer(bufnr)
    return
  endif
  call s:create_problem_buffer(a:problem)
endfunction


function! fclojure#viewer#open_answer_column(problem_no) " {{{2
  let bufnr = get(get(s:answer_column_view_table, a:problem_no, {}), 'bufnr', -1)
  if bufexists(bufnr)
    call s:move_to_buffer(bufnr)
    return
  endif
  call s:create_answer_buffer(a:problem_no)
endfunction


" Key mappings {{{2


nnoremap <silent> <Plug>(fclojure-select-problem)
      \ :<C-u>call fclojure#open_problem(str2nr(matchstr(getline('.'), '^#\zs\d\+')), 1)<CR>

nnoremap <silent> <Plug>(fclojure-quit-problem-list)
      \ :<C-u>quit<CR>

nnoremap <silent> <Plug>(fclojure-open-answer-column)
      \ :<C-u>call fclojure#viewer#open_answer_column(b:fclojure_problem_no)<CR>

nnoremap <silent> <Plug>(fclojure-quit-problem)
      \ :<C-u>quit<CR>

nnoremap <silent> <Plug>(fclojure-solve-problem-by-answer-column)
      \ :<C-u>call fclojure#solve_problem(b:fclojure_problem_no, join(getline(1, '$'), "\n"))<CR>

nnoremap <silent> <Plug>(fclojure-quit-answer-column)
      \ :<C-u>quit<CR>


" Signs {{{2

sign define fclojure-failed-test-case text=> linehl=ErrorMsg texthl=ErrorMsg




" Core {{{1

function! s:create_problem_list_buffer(problem_list) " {{{2
  let setter = {}
  let setter.set_options = function('s:set_problem_list_buffer_options')
  let setter.set_key_mappings = function('s:set_problem_list_buffer_key_mappings')
  call s:create_buffer('Problem-List', setter)
  call setline(1, s:problem_list_to_lines(a:problem_list))
  let s:problem_list_bufnr = bufnr('%')
  setlocal nomodifiable readonly
endfunction

function! s:set_problem_list_buffer_options() dict "{{{
   setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted
   setfiletype fclojure-problem-list
endfunction
"}}}

function! s:set_problem_list_buffer_key_mappings() dict "{{{
  nmap <buffer> o <Plug>(fclojure-select-problem)
  nmap <buffer> q <Plug>(fclojure-quit-problem-list)
endfunction
"}}}

function! s:problem_list_to_lines(problem_list)"{{{
  let max_length_table = fclojure#util#get_problem_item_max_length_table(a:problem_list)
  let problem_lines = []
  for problem in a:problem_list
    let _ = map(copy(problem), 'fclojure#util#padding_right(
          \   fclojure#util#string_value_of_problem_item(v:val),
          \   max_length_table[v:key] + 1)')
    let line = '#' . _.no . _.title . _.difficulty . _.topics . _.submitted_by .
          \    _.times_solved . _.is_solved
    call add(problem_lines, line)
  endfor
  return problem_lines
endfunction
"}}}


function! s:create_problem_buffer(problem) " {{{2
  let setter = {}
  let setter.set_options = function('s:set_problem_buffer_options')
  let setter.set_key_mappings = function('s:set_problem_buffer_key_mappings')
  call s:create_buffer(printf('Problem #%s', a:problem.no), setter)
  let info = s:problem_to_lines_info(a:problem)
  call setline(1, info.lines)
  let info.bufnr = bufnr('%')
  let s:problem_view_table[a:problem.no] = info
  let b:fclojure_problem_no = a:problem.no
  setlocal nomodifiable readonly
endfunction

function! s:set_problem_buffer_options() dict "{{{
  setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted
  setfiletype fclojure-problem
endfunction
"}}}

function! s:set_problem_buffer_key_mappings() dict "{{{
  nmap <buffer> o <Plug>(fclojure-open-answer-column)
  nmap <buffer> q <Plug>(fclojure-quit-problem)
endfunction
"}}}

function! s:problem_to_lines_info(problem)"{{{
  let info = {}
  let lines = []
  let signs = {}
  " Title"{{{
  call s:add_line(lines, printf('#%s %s', a:problem.no, a:problem.title),
        \         s:MAX_LINE_LENGTH)
  "}}}
  " Difficulty"{{{
  call s:add_line(lines, printf('Difficulty: %s', a:problem.difficulty),
        \         s:MAX_LINE_LENGTH)
  "}}}
  " Topics"{{{
  call s:add_line(lines, printf('Topics: %s', join(a:problem.topics)),
        \         s:MAX_LINE_LENGTH)
  "}}}
  call add(lines, repeat('-', s:MAX_LINE_LENGTH))
  " Descripton"{{{
  call s:add_line(lines, a:problem.description, s:MAX_LINE_LENGTH)
  "}}}
  call add(lines, repeat('-', s:MAX_LINE_LENGTH))
  " Restrictions"{{{
  call s:add_line(lines, 'Special Restrictions', s:MAX_LINE_LENGTH)
  call s:add_line(lines, join(a:problem.restrictions), s:MAX_LINE_LENGTH)
  "}}}
  call add(lines, repeat('=', s:MAX_LINE_LENGTH))
  " Test cases"{{{
  let signs.test_cases = []
  let idx = 0
  for test_case in a:problem.test_cases
    call add(signs.test_cases, len(lines) + 1)
    for _ in split(test_case, '\n')
      call s:add_line(lines, _, s:MAX_LINE_LENGTH)
    endfor
    let idx += 1
  endfor
  "}}}
  let signs.result_message = len(lines) + 1
  let info.lines = lines
  let info.signs = signs
  return info
endfunction
"}}}

function! s:add_line(lines, line, max_length)"{{{
  call extend(a:lines,
        \ fclojure#util#split_by_length(a:line, a:max_length))
endfunction
"}}}


function! s:create_answer_buffer(problem_no) " {{{2
  let setter = {}
  let setter.set_options = function('s:set_answer_buffer_options')
  let setter.set_key_mappings = function('s:set_answer_buffer_key_mappings')
  call s:create_buffer(printf('Answer-Column #%s', a:problem_no), setter)
  let s:answer_column_view_table[a:problem_no] = {'bufnr': bufnr('%')}
  let b:fclojure_problem_no = a:problem_no
endfunction

function! s:set_answer_buffer_options() dict "{{{
  setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted
  setfiletype clojure
endfunction
"}}}

function! s:set_answer_buffer_key_mappings() dict "{{{
  nmap <buffer> <LocalLeader>s <Plug>(fclojure-solve-problem-by-answer-column)
  nmap <buffer> q <Plug>(fclojure-quit-answer-column)
endfunction
"}}}


function! s:create_buffer(bufname, setter) " {{{2
  let open_command = fclojure#option#get('open_command')
  execute open_command
  edit `=a:bufname`
  call a:setter.set_options()
  if s:use_default_key_mappings_p()
    call a:setter.set_key_mappings()
  endif
endfunction


function! s:move_to_buffer(bufnr) " {{{2
  if !bufexists(a:bufnr)
    throw fclojure#util#create_exception('IllegalState',
          \                  printf('Buffer number %s does''t exist.', bufnr)
  endif
  let winnr = bufwinnr(a:bufnr)
  if winnr == -1
    let open_command = fclojure#option#get('open_command')
    execute open_command
    execute a:bufnr . 'buffer'
  else
    execute winnr . 'wincmd w'
  endif
endfunction






function! s:callback_of_solve(problem_no, result) " {{{2
  let bufnr = get(get(s:problem_view_table, a:problem_no, {}), 'bufnr', -1)
  if !bufexists(bufnr)
    throw fclojure#util#create_exception('IllegalState',
          \ printf('Problem No.%s hasn''t been opened.', a:problem_no)
  endif
  call s:set_result_message_in_problem_buffer(a:problem_no, a:result)
  call s:sign_place_in_problem_buffer(a:problem_no, a:result)
endfunction

function! s:set_result_message_in_problem_buffer(problem_no, result)"{{{
  let info = s:problem_view_table[a:problem_no]
  let signs = info.signs
  let message = strchars(a:result.message) > 0 ? a:result.message
        \                                      : a:result.error
  call s:move_to_buffer(info.bufnr)
  let lines = getline(1, signs.result_message - 1)
  let lines += ['']
  let lines += [repeat('*', s:MAX_LINE_LENGTH)]
  let lines += fclojure#util#split_by_length(message, s:MAX_LINE_LENGTH)
  let lines += [repeat('*', s:MAX_LINE_LENGTH)]
  setlocal modifiable noreadonly
  silent! 1,$delete
  call setline(1, lines)
  setlocal nomodifiable readonly
  silent! wincmd p
endfunction
"}}}

function! s:sign_place_in_problem_buffer(problem_no, result)"{{{
  let info = s:problem_view_table[a:problem_no]
  let signs = info.signs
  let failed_test_case_id = 1

  " Unplace the sign.
  execute printf('sign unplace %d buffer=%d', failed_test_case_id, info.bufnr)

  " failed_test_case_no is 0 origin.
  let failed_test_case_no = a:result.failed_test_case_no
  if failed_test_case_no < len(signs.test_cases)
    " Failed test case.
    execute printf('sign place %d line=%d name=%s buffer=%d',
          \        failed_test_case_id, signs.test_cases[failed_test_case_no],
          \        'fclojure-failed-test-case', info.bufnr)
  endif
endfunction
"}}}




" Misc {{{1

function! s:use_default_key_mappings_p() " {{{2
  return fclojure#option#get('no_default_key_mappings') == s:FALSE
endfunction


function! s:snr() " {{{2
  return str2nr(matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_snr$'))
endfunction


function! s:sid() " {{{2
  return printf('<SNR>%d_', s:snr())
endfunction






" Init {{{1

call fclojure#add_callback('solve-problem', function(s:sid() . 'callback_of_solve'))




" Epilogue {{{1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker
