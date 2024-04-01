let s:stack = gyoza#config#get_rules_for_filetype(expand('<sfile>:t:r'))

function s:add_begin_rule() abort
  call s:stack.add_rule('^\s*\\begin{\w\+\*\?}', {lines ->
    \ {'pair': printf('\end{%s}', matchstr(lines.previous, '^\s*\\begin{\zs\w\+\*\?\ze}'))}})
endfunction
