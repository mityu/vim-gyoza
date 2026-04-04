let s:stack = gyoza#config#get_rules_for_filetype(expand('<sfile>:t:r'))

function s:_complete_struct_brace(lines) abort
  " When closing brace is already written, move it to the next line with
  " adding semicolon if it's missing.
  if a:lines.current =~# '^}' && stridx(a:lines.current, '}', 1) == -1 &&
    \ count(a:lines.previous, '{') == 1 && a:lines.current =~# '^}\s*[[:alnum:]_]*\s*;\?'
    let components = matchlist(a:lines.current, '\(^}\s*[[:alnum:]_]*\s*\)\(;\?\)\(.*\)')[1 : 3]
    let components[1] = ';'
    const pair = join(components, '')
    return {
      \ 'pair': pair,
      \ 'cursor_text': '',
      \ }
  endif
  return {'pair': '};', 'skip': 'rest'}
endfunction

function s:add_brace_rule() abort
  call s:stack.add_rule('\v^\s*%(%(typedef\s+)?%(struct|enum)|class)>.*\{$',
    \ function('s:_complete_struct_brace'),
    \ ['\=^}', '\=^\%(protected\|private\|public\)\s*:'])
  call s:stack.add_rule('\v^\s*switch\s*\(.*\)\s*\{$',
    \ {-> {'pair': '}', 'skip': 'rest'}},
    \ ['\=^\%(case\s*.*:\|default:\)'])
endfunction
