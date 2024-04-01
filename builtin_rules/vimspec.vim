let s:stack = gyoza#config#get_rules_for_filetype(expand('<sfile>:t:r'))

function s:add_describe_rule() abort
  call s:stack.add_rule('^\s*Describe\>', 'End')
endfunction

function s:add_before_rule() abort
  call s:stack.add_rule('^\s*Before\>', 'End')
endfunction

function s:add_after_rule() abort
  call s:stack.add_rule('^\s*After\>', 'End')
endfunction

function s:add_context_rule() abort
  call s:stack.add_rule('^\s*Context\>', 'End')
endfunction

function s:add_it_rule() abort
  call s:stack.add_rule('^\s*It\>', 'End')
endfunction
