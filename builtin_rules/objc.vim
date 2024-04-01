let s:stack = gyoza#config#get_rules_for_filetype(expand('<sfile>:t:r'))

function s:_complete_implementation(lines) abort
  if stridx(a:lines.previous, '{') != -1 && a:lines.next =~# '^}'
    return {'skip': 'this'}
  endif
  return {'pair': '@end'}
endfunction

function s:add_interface_rule() abort
  call s:stack.add_rule('^@interface\>', '@end', ['\=^[+-]'])
endfunction

function s:add_implementation_rule() abort
  call s:stack.add_rule(
    \ '^\s*@implementation\>', function('s:_complete_implementation'), ['\=^[+-]'])
endfunction
