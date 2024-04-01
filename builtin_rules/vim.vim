let s:V = vital#gyoza#import('Vim.Vim9context')
let s:stack = gyoza#config#get_rules_for_filetype(expand('<sfile>:t:r'))

function s:_complete_if(lines) abort
  const curpos = getcurpos()
  try
    const prevline = prevnonblank(line('.') - 1)
    call cursor(prevline, strlen(matchstr(a:lines.previous, '^\s*')) + 1)
    const pos = searchpairpos('if', '', 'endif', 'n', '', prevline)
    if pos == [0, 0]
      return {'pair': 'endif'}
    else
      " Oneline if-statement like 'if ... | ... | endif'.
      return {'skip': 'this'}
    endif
  finally
    call setpos('.', curpos)
  endtry
endfunction

function s:_complete_heredoc(lines) abort
  const line = prevnonblank(line('.') - 1)
  if synIDattr(synID(line, 1, 1), 'name') ==# 'vimLetHereDoc'
    return {'skip': 'this'}
  endif
  return {'pair': matchstr(a:lines.previous, '\S\+\ze\s*$')}
endfunction

function s:_complete_brace(lines) abort
  let prefix = ''
  let cancelers = ['\=^\s*}']
  if s:V.get_context() == s:V.CONTEXT_VIM_SCRIPT
    let prefix = '\ '
    let cancelers = ['\=^\s*\\\s*}']
  endif

  let pos = searchpairpos('{', '', '}', 'cn', '', line('.'))
  if pos == [0, 0]
    if a:lines.current =~# '^[,)\]]'
      return {
        \ 'cursor_text': '',
        \ 'pair': prefix .. '}' .. a:lines.current,
        \ 'cancelers': cancelers,
        \}
    endif
    let cursor_text = a:lines.current
    if cursor_text !=# ''
      let cursor_text = prefix .. cursor_text
    endif
    return {
      \ 'cursor_text': cursor_text,
      \ 'pair': prefix .. '}',
      \ 'cancelers': cancelers,
      \}
  endif
  let idx = pos[1] - col('.')
  let cursor_text = strpart(a:lines.current, 0, idx)
  if cursor_text !=# ''
    let cursor_text = prefix .. cursor_text
  endif
  let pair = a:lines.current[idx :]
  return {
    \ 'cursor_text': cursor_text,
    \ 'pair': prefix .. pair,
    \ 'cancelers': cancelers,
    \ }
endfunction

function s:_complete_bracket(lines) abort
  let prefix = ''
  let cancelers = ['\=^\s*]']
  if s:V.get_context() == s:V.CONTEXT_VIM_SCRIPT
    let prefix = '\ '
    let cancelers = ['\=^\s*\\\s*]']
  endif

  let pos = searchpairpos('\[', '', ']', 'cn', '', line('.'))
  if pos == [0, 0]
    if a:lines.current =~# '^[,)}]'
      return {
        \ 'cursor_text': '',
        \ 'pair': prefix .. ']' .. a:lines.current,
        \ 'cancelers': cancelers,
        \}
    endif
    let cursor_text = a:lines.current
    if cursor_text !=# ''
      let cursor_text = prefix .. cursor_text
    endif
    return {
      \ 'cursor_text': cursor_text,
      \ 'pair': prefix .. ']',
      \ 'cancelers': cancelers,
      \}
  endif
  let idx = pos[1] - col('.')
  let cursor_text = strpart(a:lines.current, 0, idx)
  if cursor_text !=# ''
    let cursor_text = prefix .. cursor_text
  endif
  let pair = a:lines.current[idx :]
  return {
    \ 'cursor_text': cursor_text,
    \ 'pair': prefix .. pair,
    \ 'cancelers': cancelers,
    \ }
endfunction

function s:add_if_rule() abort
  call s:stack.add_rule(
    \ '^\s*if\>', function('s:_complete_if'), ['\=^\s*else\>', '\=^\s*elseif\>'])
endfunction

function s:add_while_rule() abort
  call s:stack.add_rule('^\s*while\>', 'endwhile')
endfunction

function s:add_for_rule() abort
  call s:stack.add_rule('^\s*for\>', 'endfor')
endfunction

function s:add_function_rule() abort
  call s:stack.add_rule('\v^\s*%(legacy\s)?\s*fu%[nction]!?\s+\S+\(.*\).*$',
    \ {lines -> {'pair': 'end' .. matchstr(lines.previous, '^.\{-}\<\zsfu\%[nction]\>')}},
    \ ['\=^\s*endf\%[unction]\>'])
endfunction

function s:add_def_rule() abort
  call s:stack.add_rule('\v^\s*%(export\s|legacy\s|static\s)?\s*def!?\s+\S+(.*).*$', 'enddef')
endfunction

function s:add_try_rule() abort
  call s:stack.add_rule('^\s*try\>', 'endtry', ['\=^\s*catch\>', '\=^\s*finally\>'])
endfunction

function s:add_augroup_rule() abort
  call s:stack.add_rule('^\s*augroup\>\%(\s\+END\>\)\@!', 'augroup END')
endfunction

function s:add_class_rule() abort
  call s:stack.add_rule('\v^\s*%(export\s+)?%(abstract\s+)?class>', 'endclass')
endfunction

function s:add_interface_rule() abort
  call s:stack.add_rule('\v^\s*%(export\s+)?interface>', 'endinterface')
endfunction

function s:add_enum_rule() abort
  call s:stack.add_rule('\v^\s*%(export\s+)?enum>', 'endenum')
endfunction

function s:add_echohl_rule() abort
  call s:stack.add_rule('^\s*echohl\>\%(\s\+None\)\@!', 'echohl None', ['\=^\s*echo'])
endfunction

function s:add_heredoc_rule() abort
  call s:stack.add_rule(
    \ '\v^\s*%(let|var|const|final)\s+%([gsltwb]:)?\w+\s*\=\<\<\s*%(%(trim|eval)\s+)*\s*\w+$',
    \ function('s:_complete_heredoc'))
endfunction

function s:add_brace_rule() abort
  call s:stack.add_rule(
    \ '{\s*$',
    \ function('s:_complete_brace'))
endfunction

function s:add_bracket_rule() abort
  call s:stack.add_rule(
    \ '[\s*$',
    \ function('s:_complete_bracket'))
endfunction
