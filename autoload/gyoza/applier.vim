let s:rule_stack = []  " List of rules we should try.
let s:map_clearer =
  \ ['apply', 'check_state', 'do_input']
  \ ->map({-> printf("\<Cmd>iunmap <buffer> <Plug>(_gyoza_%s)\<CR>", v:val)})
  \ ->join('')


function gyoza#applier#trigger_applicant(all_rules) abort
  const prevlinenr = prevnonblank(line('.') - 1)
  const nextlinenr = nextnonblank(line('.') + 1)
  const prevline = getline(prevlinenr)

  " Do not apply rules when the next line has deeper indentation.
  if s:get_indent_width(getline(nextlinenr)) > s:get_indent_width(prevlinenr)
    return
  endif

  let s:rule_stack = a:all_rules->copy()->filter('prevline =~# v:val.pattern')

  imap <buffer> <silent> <expr> <Plug>(_gyoza_apply) <SID>do_apply()
  imap <buffer> <silent> <expr> <Plug>(_gyoza_check_state) <SID>check_apply_state()
  inoremap <buffer> <Plug>(_gyoza_do_input) <Nop>

  call feedkeys("\<Plug>(_gyoza_apply)", 'mi!')
endfunction

function s:do_apply() abort
  if empty(s:rule_stack)
    return s:map_clearer
  endif
  const rule = s:rule_stack->remove(0)

  execute 'inoremap <buffer> <Plug>(_gyoza_do_input)' rule.pair

  " I don't know why but the last input character will be disappared without
  " <Ignore> between these two mappings.
  return "\<Plug>(_gyoza_do_input)\<Ignore>\<Plug>(_gyoza_check_state)"
endfunction

function s:check_apply_state() abort
  const curline = getline('.')
  const nextline = getline(nextnonblank(line('.') + 1))

  if s:get_indent_width(curline) == s:get_indent_width(nextline) &&
      \ trim(curline) ==# trim(nextline)
    " Currently applied rule does not matches the requirements.  Remove the
    " pair temporally inserted and re-try other rules.
    inoremap <buffer> <Plug>(_gyoza_do_input) <C-u>
  else
    " The latest applied rule matched all the requirements.  Clear the rules
    " stack, create newline, and remove all the temporal plugin mappings.
    let s:rule_stack = []
    inoremap <buffer> <Plug>(_gyoza_do_input) <C-g>U<Up><C-g>U<End><CR>
  endif

  return "\<Plug>(_gyoza_do_input)\<Plug>(_gyoza_apply)"
endfunction

function s:replace_termcode(keys) abort
  return substitute(a:keys, '<[^<]\+>',
    \ '\=eval(printf(''"\%s"'', submatch(0)))', 'g')
endfunction

function s:get_indent_width(line) abort
  return a:line->matchstr('^\s*')->strdisplaywidth()
endfunction
