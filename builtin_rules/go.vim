let s:stack = gyoza#config#get_rules_for_filetype(expand('<sfile>:t:r'))

function s:add_parenthesis_rule() abort
  call s:stack.add_rule('^\s*\%(var\|const\|import\)\s*($', ')')
endfunction

function s:add_brace_rule() abort
  call s:stack.add_rule(
    \ '\v^\s*%(select>|switch\s*\S*\s*)\s*\{$', '}', ['\=^\%(case\s*.*:\|default:\)'])
  call s:stack.add_rule(
    \ '\v^\s*%(defer|go)\s+func\s*\([^)]{-}\)\s*\{$', '}()', ['\=^}\s*('])
endfunction
