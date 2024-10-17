let s:stack = gyoza#config#get_rules_for_filetype(expand('<sfile>:t:r'))

function s:_complete_end(lines) abort
  const env = matchstr(a:lines.previous, '^\s*\\begin{\zs\w\+\*\?\ze}')
  if env ==# 'document' && search('\S', 'nzW') != 0
    " Complete `\end{document}` only when no text appears after the current
    " line.
    return {'skip': 'this'}
  endif
  return {'pair': printf('\end{%s}', env)}
endfunction

function s:add_begin_rule() abort
  call s:stack.add_rule('^\s*\\begin{\w\+\*\?}', function('s:_complete_end'))
endfunction
