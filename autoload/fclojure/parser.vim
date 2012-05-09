" 4Clojure for Vim.
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

" Vital"{{{
let s:V = vital#of(fclojure#name())
call s:V.import('Web.Html', s:V)
call s:V.import('Web.Json', s:V)
"}}}

call fclojure#util#lock_constants(s:)




" Interface {{{1

function! fclojure#parser#parse_problem_list(response) " {{{2
  let content = a:response.content
  let dom = s:V.parse(content)
  let _ = s:get_element_by_id(dom.find('body'), 'problem-table')
  let problem_tr_list = _.findAll('tr')[1:]
  return s:parse_problem_tr_list(problem_tr_list)
endfunction


function! fclojure#parser#parse_problem(response) " {{{2
  let content = a:response.content
  let dom = s:V.parse(content)
  let container = s:get_element_by_id(dom.find('body'), 'prob-container')

  let problem = {}
  " no"{{{
  let problem.no = s:get_element_by_id(container, 'prob-number').value()[1:]
  "}}}
  " title"{{{
  let problem.title = s:get_element_by_id(container, 'prob-title').value()
  "}}}
  " difficulty"{{{
  let tags_node = s:get_element_by_id(container, 'tags').findAll('tr')
  let problem.difficulty = tags_node[0].childNodes()[1].value()
  "}}}
  " topics"{{{
  let problem.topics = split(tags_node[1].childNodes()[1].value())
  "}}}
  " description"{{{
  let desc_node = s:get_element_by_id(container, 'prob-desc')
  let problem.description = ''
  for c in desc_node.child
    if s:V.is_dict(c) && get(c.attr, 'class', '')  =~# 'testcases'
      break
    endif
    let problem.description .= s:V.is_dict(c) ? c.value() : c
    unlet c
  endfor
  "}}}
  " test cases"{{{
  let test_cases_nodes = s:get_elements_by_class(desc_node, 'testcases')[0].findAll('tr')
  let problem.test_cases = map(copy(test_cases_nodes), 'v:val.value()')
  "}}}
  " restrictions"{{{
  let restrictions_node = s:get_element_by_id(desc_node, 'restrictions')
  let restrictions = []
  if !empty(restrictions_node)
    let _header = restrictions_node.find('u').value()
    let _body = map(copy(restrictions_node.findAll('li')), 'v:val.value()')
    let restrictions = [_header] + _body
  endif
  let problem.restrictions = restrictions
  "}}}
  return problem
endfunction




function! fclojure#parser#parse_result_of_solve(response) " {{{2
  let content = a:response.content
  let json = s:V.decode(content)
  let result = {}
  let result.failed_test_case_no = str2nr(json.failingTest)
  let result.message = s:V.parse('<div>' . json.message . '</div>').value()
  let result.error = s:V.parse('<div>' . json.error . '</div>').value()
  let result.golf_score = json.golfScore
  let result.golf_chart = json.golfChart
  return result
endfunction




" Core {{{1

function! s:parse_problem_tr_list(tr_list) " {{{2
  return map(deepcopy(a:tr_list), 's:parse_problem_tr(v:val)')
endfunction

function! s:parse_problem_tr(tr)"{{{
  let problem = {}
  let td_list = a:tr.findAll('td')
  " no
  let problem.no = matchstr(td_list[0].childNode().attr.href, '\d*$')
  " title
  let problem.title = td_list[0].childNode().child[0]
  " difficulty
  let problem.difficulty = td_list[1].child[0]
  " topics
  let problem.topics = map(td_list[2].findAll('span'), 'v:val.child[0]')
  " submitted by
  let problem.submitted_by = td_list[3].child[0]
  " times solved
  let problem.times_solved = str2nr(td_list[4].child[0])
  " solved?
  let problem.is_solved = td_list[5].childNode().attr.src =~# 'checkmark\.png$'
        \                                                     ? s:TRUE
        \                                                     : s:FALSE
  return problem
endfunction
"}}}




" Misc {{{1

function! s:get_element_by_id(node, id) " {{{2
  for child in a:node.childNodes()
    if has_key(child.attr, 'id') && a:id ==# child.attr.id
      return child
    else
      let _ = s:get_element_by_id(child, a:id)
      if !empty(_) | return _ | endif
    endif
  endfor
  return {}
endfunction




function! s:get_elements_by_class(node, class) " {{{2
  let elements = []
  for child in a:node.childNodes()
    if has_key(child.attr, 'class') && child.attr.class =~# '\<' . a:class .'\>'
      call add(elements, child)
    else
      let _ = s:get_elements_by_class(child, a:class)
      call extend(elements, _)
    endif
  endfor
  return elements
endfunction




" Epilogue {{{1

let &cpoptions = s:save_cpoptions
unlet s:save_cpoptions




" __END__ {{{1
" vim: foldmethod=marker
