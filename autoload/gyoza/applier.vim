let s:rule_stack = []  " List of rules we should try.

let s:temporal_map_clearer =
  \ ['apply', 'check_state', 'do_input', 'setup_newline_removal']
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
  inoremap <buffer> <Plug>(_gyoza_setup_newline_removal) <Nop>

  call feedkeys("\<Plug>(_gyoza_apply)", 'mi!')
endfunction

function s:do_apply() abort
  if empty(s:rule_stack)
    return s:temporal_map_clearer
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
    return "\<Plug>(_gyoza_do_input)\<Plug>(_gyoza_apply)"
  else
    " The latest applied rule matched all the requirements.  Clear the rules
    " stack, create newline, and remove all the temporal plugin mappings.
    let s:rule_stack = []
    " TODO: Split undo sequence here?
    inoremap <buffer> <Plug>(_gyoza_do_input) <C-g>U<Up><C-g>U<End><CR>
    inoremap <buffer> <Plug>(_gyoza_setup_newline_removal)
      \ <Cmd>call <SID>setup_newline_removal()<CR>
    return "\<Plug>(_gyoza_do_input)\<Plug>(_gyoza_setup_newline_removal)"
      \ . s:temporal_map_clearer
  endif
endfunction

" When user left insert mode just after newline, remove the current line.
" E.g.
"
"   if ...|
"
"      | Type <CR>
"      v
"
"   if ...       Leave insert mode       if ...
"     |        -------------------->     endif
"   endif
"
" But, user did some operation after newline, do not remove the current line.
function s:setup_newline_removal() abort
  augroup plugin-gyoza-applier
    autocmd!
    autocmd TextChangedI,CursorMovedI <buffer> ++once
      \ call s:cancel_removeing_newline()
    autocmd InsertLeave <buffer> ++once call s:remove_newline()
  augroup END
endfunction

function s:remove_newline() abort
  augroup plugin-gyoza-applier
    autocmd!
  augroup END

  if getline('.')->trim() ==# ''
    delete _
  endif
endfunction

function s:cancel_removeing_newline() abort
  augroup plugin-gyoza-applier
    autocmd!
  augroup END
endfunction

function s:replace_termcode(keys) abort
  return substitute(a:keys, '<[^<]\+>',
    \ '\=eval(printf(''"\%s"'', submatch(0)))', 'g')
endfunction

function s:get_indent_width(line) abort
  return a:line->matchstr('^\s*')->strdisplaywidth()
endfunction
