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
let s:F = s:V.import('System.Filepath')
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
  else
    call s:create_problem_list_buffer(a:problem_list)
  endif
endfunction


function! fclojure#viewer#open_problem(problem) " {{{2
  let bufnr = get(get(s:problem_view_table, a:problem.no, {}), 'bufnr', -1)
  if bufexists(bufnr)
    call s:move_to_buffer(bufnr)
  else
    call s:create_problem_buffer(a:problem)
  endif
endfunction


function! fclojure#viewer#open_answer_column(problem_no) " {{{2
  let bufnr = get(get(s:answer_column_view_table, a:problem_no, {}), 'bufnr', -1)
  if bufexists(bufnr)
    call s:move_to_buffer(bufnr)
  else
    call s:create_answer_dir()
    call s:create_answer_buffer(a:problem_no)
  endif
endfunction


" Key mappings {{{2

nnoremap <silent> <Plug>(fclojure-select-problem)
      \ :<C-u>call fclojure#open_problem(str2nr(matchstr(getline('.'), '^#\zs\d\+')), 1)<CR>

nnoremap <silent> <Plug>(fclojure-quit-problem-list)
      \ :<C-u>quit<CR>

nnoremap <silent> <Plug>(fclojure-open-problem-list-url)
      \ :<C-u>call fclojure#open_problem_list_url()<CR>

nnoremap <silent> <Plug>(fclojure-open-answer-column)
      \ :<C-u>call fclojure#open_answer_column(b:fclojure_problem_no)<CR>

nnoremap <silent> <Plug>(fclojure-quit-problem)
      \ :<C-u>quit<CR>

nnoremap <silent> <Plug>(fclojure-open-problem-url)
      \ :<C-u>call fclojure#open_problem_url(b:fclojure_problem_no)<CR>

nnoremap <silent> <Plug>(fclojure-solve-problem-with-file)
      \ :<C-u>call fclojure#solve_problem(b:fclojure_problem_no, join(getline(1, '$'), "\n"))<CR>

nnoremap <silent> <Plug>(fclojure-solve-problem-with-a-block)
      \ :<C-u>call fclojure#solve_problem(b:fclojure_problem_no, <SID>get_a_block())<CR>

nnoremap <silent> <Plug>(fclojure-quit-answer-column)
      \ :<C-u>quit<CR>


" Signs {{{2

sign define fclojure-failed-test-case text=> linehl=ErrorMsg texthl=ErrorMsg




" Core {{{1

function! s:create_problem_list_buffer(problem_list) " {{{2
  call s:create_buffer('Problem-List', s:problem_list_setter)
  call setline(1, s:problem_list_to_lines(a:problem_list))
  let s:problem_list_bufnr = bufnr('%')
  setlocal nomodifiable readonly
endfunction

" Problem list setter"{{{
let s:problem_list_setter = {}

function! s:problem_list_setter.set_options()
   setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted
   setfiletype fclojure-problem-list
endfunction

function! s:problem_list_setter.set_key_mappings()
  nmap <buffer> o <Plug>(fclojure-select-problem)
  nmap <buffer> q <Plug>(fclojure-quit-problem-list)
  nmap <buffer> u <Plug>(fclojure-open-problem-list-url)
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
  call s:create_buffer(printf('Problem #%s', a:problem.no), s:problem_setter)
  let info = s:problem_to_lines_info(a:problem)
  call setline(1, info.lines)
  let info.bufnr = bufnr('%')
  let s:problem_view_table[a:problem.no] = info
  let b:fclojure_problem_no = a:problem.no
  setlocal nomodifiable readonly
endfunction

" Problem setter"{{{
let s:problem_setter = {}

function! s:problem_setter.set_options()
  setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted
  setfiletype fclojure-problem
endfunction

function! s:problem_setter.set_key_mappings()
  nmap <buffer> o <Plug>(fclojure-open-answer-column)
  nmap <buffer> q <Plug>(fclojure-quit-problem)
  nmap <buffer> u <Plug>(fclojure-open-problem-url)
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
  call s:create_buffer(s:get_answer_file_path(a:problem_no), s:answer_setter)
  let s:answer_column_view_table[a:problem_no] = {'bufnr': bufnr('%')}
  let b:fclojure_problem_no = a:problem_no
endfunction

" Answer setter"{{{
let s:answer_setter = {}

function! s:answer_setter.set_options()
  setlocal bufhidden=hide nobuflisted
  setfiletype clojure
endfunction

function! s:answer_setter.set_key_mappings()
  nmap <buffer> <LocalLeader>sf <Plug>(fclojure-solve-problem-with-file)
  nmap <buffer> <LocalLeader>sb <Plug>(fclojure-solve-problem-with-a-block)
  nmap <buffer> q <Plug>(fclojure-quit-answer-column)
endfunction

"}}}

function! s:create_answer_dir()"{{{
  let answer_dir = fclojure#option#get('answer_dir')
  if !isdirectory(answer_dir)
    call mkdir(answer_dir, 'p')
  endif
endfunction
"}}}

function! s:get_answer_file_path(problem_no)"{{{
  return s:F.join(fclojure#option#get('answer_dir'),
        \         printf(fclojure#option#get('answer_file_format'), a:problem_no))
endfunction
"}}}


function! s:create_buffer(bufname, setter) " {{{2
  let setter = extend(s:default_setter, a:setter)
  let open_command = fclojure#option#get('open_buffer_command')
  execute open_command
  silent! edit `=a:bufname`
  call setter.set_options()
  call setter.set_auto_commands()
  if s:use_default_key_mappings_p()
    call setter.set_key_mappings()
  endif
endfunction

" Default setter."{{{
let s:default_setter = {}

function! s:default_setter.set_options()
endfunction

function! s:default_setter.set_key_mappings()
endfunction

function! s:default_setter.set_auto_commands()
endfunction
"}}}


function! s:move_to_buffer(bufnr) " {{{2
  if !bufexists(a:bufnr)
    throw fclojure#util#create_exception('IllegalState',
          \                  printf('Buffer number %s does''t exist.', bufnr)
  endif
  let winnr = bufwinnr(a:bufnr)
  if winnr == -1
    let open_command = fclojure#option#get('open_buffer_command')
    execute open_command
    silent! execute a:bufnr . 'buffer'
  else
    execute winnr . 'wincmd w'
  endif
endfunction


function! s:callback_of_solve(problem_no, result) " {{{2
  let bufnr = get(get(s:problem_view_table, a:problem_no, {}), 'bufnr', -1)
  if !bufexists(bufnr) || bufwinnr(bufnr) == -1
    redraw!
    echohl WarningMsg | echo s:get_result_message(a:result) | echohl None
    return
  endif
  call s:set_result_message_in_problem_buffer(a:problem_no, a:result)
  call s:sign_place_in_problem_buffer(a:problem_no, a:result)
endfunction

function! s:get_result_message(result)"{{{
  return strchars(a:result.message) > 0 ? a:result.message
        \                               : a:result.error
endfunction
"}}}

function! s:set_result_message_in_problem_buffer(problem_no, result)"{{{
  let info = s:problem_view_table[a:problem_no]
  let signs = info.signs
  let message = s:get_result_message(a:result)
  call s:move_to_buffer(info.bufnr)
  let lines = getline(1, signs.result_message - 1)
  let lines += ['']
  let lines += [repeat('*', s:MAX_LINE_LENGTH)]
  let lines += fclojure#util#split_by_length(message, s:MAX_LINE_LENGTH)
  let lines += [repeat('*', s:MAX_LINE_LENGTH)]
  setlocal modifiable noreadonly
  silent! 1,$delete _
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


function! s:get_a_block() "{{{2
  let pos = getpos(".")
  let [r_, r_t] = [@@, getregtype('"')]

  silent! normal! yab

  let block = @@

  call setreg('"', r_, r_t)
  call setpos(".", pos)

  return s:align_indent(block)
endfunction

let s:align_indent_bufnr = -1

function! s:align_indent(src)"{{{
  if bufexists(s:align_indent_bufnr)
    call s:move_to_buffer(s:align_indent_bufnr)
  else
    call s:create_buffer('fclojure-align-indent', s:align_indent_setter)
    let s:align_indent_bufnr = bufnr('%')
  endif

  silent! 1,$delete _
  call setline(1, split(a:src, '\n'))
  silent! normal! gg=G
  quit

  return join(getbufline(s:align_indent_bufnr, 1, '$'), "\n")
endfunction
"}}}

" Align indent setter"{{{
let s:align_indent_setter = {}

function! s:align_indent_setter.set_options()
  setlocal bufhidden=hide buftype=nofile noswapfile nobuflisted
  setfiletype clojure
endfunction
"}}}




" Init {{{1

call fclojure#add_callback('solve-problem', function(s:sid() . 'callback_of_solve'))




" Epilogue {{{1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker
