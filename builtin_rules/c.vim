let s:stack = gyoza#config#get_rules_for_filetype(expand('<sfile>:t:r'))

function s:add_brace_rule() abort
  call s:stack.add_rule('\v^\s*%(%(typedef\s+)?%(struct|enum)|class)>.*\{$',
    \ {-> {'pair': '};', 'skip': 'rest'}},
    \ ['\=^}', '\=^\%(protected\|private\|public\)\s*:'])
  call s:stack.add_rule('\v^\s*switch\s*\(.*\)\s*\{$',
    \ {-> {'pair': '}', 'skip': 'rest'}},
    \ ['\=^\%(case\s*.*:\|default:\)'])
endfunction
