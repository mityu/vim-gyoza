let s:stack = gyoza#config#get_rules_for_filetype(expand('<sfile>:t:r'))

function s:_complete_brace(lines) abort
  let pos = searchpairpos('{', '', '}', 'cn', '', line('.'))
  if pos == [0, 0]
    if a:lines.current =~# '^[,)\]]'
      return {'pair': '}' .. a:lines.current, 'cursor_text': ''}
    endif
    return {'pair': '}'}
  endif
  let idx = pos[1] - col('.')
  let cursor_text = strpart(a:lines.current, 0, idx)
  let pair = a:lines.current[idx :]
  return {'pair': pair, 'cursor_text': cursor_text}
endfunction

function s:add_brace_rule()
  call s:stack.add_rule('{\s*$', function('s:_complete_brace'), ['\=^\s*}'])
endfunction
