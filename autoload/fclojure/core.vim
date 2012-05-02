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

call fclojure#util#provide_boolean(s:)

" URLs"{{{
let s:URLS = {
      \   'root': 'https://www.4clojure.com/',
      \   'log_in': 'https://www.4clojure.com/login',
      \   'settings': 'https://www.4clojure.com/settings',
      \   'problem_list': 'https://www.4clojure.com/problems',
      \   'problem': 'https://www.4clojure.com/problem',
      \   'solve': 'https://www.4clojure.com/rest/problem',
      \ }
"}}}

" Paths"{{{
let s:PATHS = {
      \   'cookie_dir': {
      \     'name': 'cookies',
      \   },
      \   'cookie': {
      \     'parent': 'cookie_dir',
      \     'name': 'cookie',
      \   },
      \   'cache_dir': {
      \     'name': 'caches',
      \   },
      \ }
"}}}

" Vital"{{{
let s:V = fclojure#util#vital()
let s:H = s:V.import('Web.Http')
let s:F = s:V.import('System.File')
call s:V.import('System.Filepath', s:F)
let s:C = s:V.import('System.Cache')
"}}}

call fclojure#util#lock_constants(s:)




" Variables {{{1

call fclojure#option#init()

let s:is_logged_in = s:FALSE
let s:problem_list = []
let s:problem_detail_table = {}
let s:problem_list_bufnr = -1
let s:curl_command = fclojure#option#get('curl_command')
let s:data_dir = s:F.remove_last_separator(expand(fclojure#option#get('data_dir')))




" Interface {{{1

function! fclojure#core#get_problem_list() " {{{2
  " Use the cache."{{{
  if !empty(s:problem_list)
    return s:problem_list
  endif
  "}}}
  " Check the log in."{{{
  if !s:logged_in_p() && !s:log_in()
    throw fclojure#util#create_exception('IllegalState', 'Log in failed.')
  endif
  "}}}

  let url = s:get_url('problem_list')
  let header = s:get_common_header()
  let response = s:H.get(url, {}, header)
  let problem_list = fclojure#parser#parse_problem_list(response)
  let s:problem_list = problem_list
  return problem_list
endfunction


function! fclojure#core#get_problem(problem_no) " {{{2
  " Use cache."{{{
  if has_key(s:problem_detail_table, a:problem_no)
    return s:problem_detail_table[a:problem_no]
  endif
  "}}}
  " Check the log in."{{{
  if !s:logged_in_p() && !s:log_in()
    throw fclojure#util#create_exception('IllegalState', 'Log in failed.')
  endif
  "}}}

  let url = s:get_problem_url(a:problem_no)
  let header = s:get_common_header()
  let response = s:H.get(url, {}, header)
  let problem = fclojure#parser#parse_problem(response)
  let s:problem_detail_table[a:problem_no] = problem
  return problem
endfunction


function! fclojure#core#solve_problem(problem_no, answer) " {{{2
  " Check the log in."{{{
  if !s:logged_in_p()
    call s:log_in()
  endif
  "}}}
  let url = s:get_solve_url(a:problem_no)
  " Param "{{{
  let param = {}
  let param.id = a:problem_no
  let param.code = a:answer
  "}}}
  let header = s:get_common_header()
  let response = s:H.post(url, param, header)
  return fclojure#parser#parse_result_of_solve(response)
endfunction




" Core {{{1

function! s:log_in() " {{{2
  if s:enabled_cookie_p()
    let s:is_logged_in = s:TRUE
    return s:TRUE
  endif

  try
    let is_successed = s:log_in_by_user_input()
  catch /^fclojure:/
    call fclojure#util#print_error(v:exception)
    return s:FALSE
  endtry
  if is_successed
    let s:is_logged_in = s:TRUE
    return s:TRUE
  endif

  return s:FALSE
endfunction


function! s:enabled_cookie_p() " {{{2
  let cookie_file = s:get_file_path('cookie')
  if filereadable(cookie_file)
    let url = s:get_url('settings')
    let cookie = s:get_cookie()
    let header = {'Cookie': cookie}
    let res = s:H.get(url, {}, header)
    if res.content !~# '<span [^>]*class="error"'
      return s:TRUE
    endif
  endif
  return s:FALSE
endfunction


function! s:log_in_by_user_input() " {{{2
  let user_name = s:V.input_safe('Input user name: ')
  " Check canceled."{{{
  if strchars(user_name) == 0
    throw fclojure#util#create_exception('Cancel',
          \ 'The input of the user name was canceled.')
  endif"}}}
  let password = s:V.input_helper('inputsecret', ['Input password: '])
  " Check canceled."{{{
  if strchars(password) == 0
    throw fclojure#util#create_exception('Cancel',
          \ 'The input of the password was canceled.')
  endif"}}}

  call s:create_cookie_dir()

  " Note: Using Vital.Web.Http.post(), implicit redirect is performed.
  "       *log-in url* -> [problem-list url] or [log-in url]
  "       *log-in url* response is required.
  let command = printf('%s %s -s -k -i -d user=%s -d pwd=%s -c "%s"',
        \              s:curl_command, s:get_url('log_in'),
        \              user_name, password,
        \              escape(s:get_file_path('cookie'), '"'))
  " Response is only a header.
  let header = s:V.system(command)
  if header =~# 'Location: /problems'
    return s:TRUE
  endif

  call delete(s:get_file_path('cookie'))
  return s:FALSE
endfunction


function! s:logged_in_p() " {{{2
  return s:is_logged_in
endfunction


function! s:get_cookie() " {{{2
  " XXX
  let [name, value] = matchlist(join(readfile(s:get_file_path('cookie'))),
        \                       '.*\(ring-session\)\s*\(\S*\)')[1:2]
  return printf('%s=%s', name, value)
endfunction


function! s:create_cookie_dir() " {{{2
  let cookie_dir = s:get_file_path('cookie_dir')
  if !isdirectory(cookie_dir)
    call s:F.mkdir_nothrow(cookie_dir, 'p')
  endif
endfunction


function! s:get_common_header() " {{{2
  let cookie = s:get_cookie()
  let header = {'Cookie': cookie}
  return header
endfunction




function! s:read_problem_list_cache() " {{{2
  return map(s:C.readfile(s:get_file_path('cache_dir'), 'problem_list'), 'eval(v:val)')
endfunction


function! s:write_problem_list_cache(problem_list) " {{{2
  call s:C.writefile(s:get_file_path('cache_dir'), 'problem_list',
        \            map(copy(a:problem_list), 'string(v:val)'))
endfunction


function! s:read_problem_details_cache() " {{{2
  let cache = s:C.readfile(s:get_file_path('cache_dir'), 'problem_details')
  let problems = {}
  for _ in cache
    let problem = eval(_)
    let problems[problem.no] = problem
  endfor
  return problems
endfunction


function! s:write_problem_details_cache(problem_details) " {{{2
  let cache = map(values(a:problem_details), 'string(v:val)')
  call s:C.writefile(s:get_file_path('cache_dir'), 'problem_details', cache)
endfunction




" Misc {{{1

function! s:get_url(name) " {{{2
  let url = get(s:URLS, a:name, '')
  if url == ''
    throw fclojure#util#create_exception('IllegalArgument',
          \ printf('URL of "%s" doesn''t exist.', a:name))
  endif
  return url
endfunction


function! s:get_file_path(name) " {{{2
  let file_info = get(s:PATHS, a:name, {})
  if empty(file_info)
    throw fclojure#util#create_exception('IllegalArgument',
          \ printf('Path of "%s" doesn''t exist.', a:name))
  endif
  if has_key(file_info, 'parent')
    return s:F.join(s:get_file_path(file_info.parent), file_info.name)
  else
    return s:F.join(s:data_dir, file_info.name)
  endif
endfunction


function! s:get_problem_url(problem_no) " {{{2
  let url = get(s:URLS, 'problem')
  return url . '/' . a:problem_no
endfunction


function! s:get_solve_url(problem_no) " {{{2
  let url = get(s:URLS, 'solve')
  return url . '/' . a:problem_no
endfunction




" Init {{{1

let s:problem_list = s:read_problem_list_cache()
let s:problem_detail_table = s:read_problem_details_cache()

augroup fclojure-core
  autocmd!
  autocmd VimLeavePre * call s:write_problem_list_cache(s:problem_list) |
        \               call s:write_problem_details_cache(s:problem_detail_table)
augroup END




" Epilogue {{{1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker
