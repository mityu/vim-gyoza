let s:stack = gyoza#config#get_rules_for_filetype(expand('<sfile>:t:r'))

function s:add_do_rule() abort
  call s:stack.add_rule('\%(^\|;\)\s*do\>', 'done')
endfunction

function s:add_if_rule() abort
  call s:stack.add_rule('^\s*if\>', 'fi', ['\=^elif\>', '\=^else\>'])
endfunction

function s:add_case_rule() abort
  call s:stack.add_rule('^\s*case\>.*\<in\>', 'esac')
endfunction
