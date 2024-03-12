let s:rule_stack = []  " List of rules we should try.
let s:current_rule = {}  " Currently applied rule.
let s:state_after_newline = {}  " Some cursor/buffer states after completing block.
let s:callback_on_finish_applicant = v:null

function gyoza#applier#set_callback_on_finish_applicant(fn) abort
  let s:callback_on_finish_applicant = a:fn
endfunction

function gyoza#applier#trigger_applicant(all_rules) abort
  const prevlinenr = prevnonblank(line('.') - 1)
  const nextlinenr = nextnonblank(line('.') + 1)
  const prevline = getline(prevlinenr)

  " Do not apply rules when the next line has deeper indentation.
  if s:get_indent_width(getline(nextlinenr)) > s:get_indent_width(prevlinenr)
    call call(s:callback_on_finish_applicant, [])
    return
  endif

  let s:rule_stack = a:all_rules->copy()->filter('prevline =~# v:val.pattern')

  imap <buffer> <silent> <expr> <Plug>(_gyoza_apply) <SID>do_apply()
  imap <buffer> <silent> <expr> <Plug>(_gyoza_check_state) <SID>check_apply_state()
  inoremap <buffer> <Plug>(_gyoza_do_input) <Nop>
  inoremap <buffer> <expr> <Plug>(_gyoza_setup_newline_removal)
    \ <SID>setup_newline_removal()
  inoremap <buffer> <expr> <Plug>(_gyoza_clear_temporal_mappings)
    \ <SID>clear_temporal_mappings()

  call feedkeys("\<Plug>(_gyoza_apply)", 'mi!')
endfunction

function s:do_apply() abort
  if empty(s:rule_stack)
    call call(s:callback_on_finish_applicant, [])
    return "\<Plug>(_gyoza_clear_temporal_mappings)"
  endif
  let s:current_rule = s:rule_stack->remove(0)

  execute 'inoremap <buffer> <Plug>(_gyoza_do_input)' s:current_rule.pair

  " I don't know why but the last input character will be disappared without
  " <Ignore> between these two mappings.
  return "\<Plug>(_gyoza_do_input)\<Ignore>\<Plug>(_gyoza_check_state)"
endfunction

function s:check_apply_state() abort
  const curline = getline('.')
  const nextline = getline(nextnonblank(line('.') + 1))
  const nextline_text = trim(nextline)

  if s:get_indent_width(curline) == s:get_indent_width(nextline) &&
      \ (trim(curline) ==# nextline_text || s:should_skip_rule(nextline_text))
    " Currently applied rule does not match the requirements.  Remove the pair
    " temporally inserted and re-try other rules.
    inoremap <buffer> <Plug>(_gyoza_do_input) <C-u>
    return "\<Plug>(_gyoza_do_input)\<Plug>(_gyoza_apply)"
  else
    " The latest applied rule matched all the requirements.  Clear the rules
    " stack, create newline, and remove all the temporal plugin mappings.
    let s:rule_stack = []
    inoremap <buffer> <Plug>(_gyoza_do_input) <C-g>U<Up><C-g>U<End><CR>
    return "\<Plug>(_gyoza_do_input)\<Plug>(_gyoza_setup_newline_removal)"
      \ . "\<Plug>(_gyoza_clear_temporal_mappings)"
  endif
endfunction

function s:should_skip_rule(text) abort
  if index(s:current_rule.canceler_literal, a:text) != -1
    return v:true
  endif

  for p in s:current_rule.canceler_regexp
    if a:text =~# p
      return v:true
    endif
  endfor

  return v:false
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
    autocmd CursorMovedI <buffer> call s:invalidate_newline_removal()
    autocmd InsertLeave <buffer> ++once call s:remove_newline()
  augroup END
  let s:state_after_newline = {
    \ 'curpos': getcurpos(),
    \ 'curline': getline('.'),
    \ 'line_count': line('$'),
    \ 'undo_seq': undotree().seq_cur,
    \ }
  call call(s:callback_on_finish_applicant, [])
  return ''
endfunction

" Cancel newline removal operation.  Plus, make a new undo block for the pair
" completion.
function s:invalidate_newline_removal() abort
  " I don't know why but some CursorMovedI event may happen before leaving
  " insert mode.  It seems buffer state is not mostly changed so check the
  " buffer state and ignore this CursorMovedI event if the state is still
  " same.
  if s:state_after_newline.curpos == getcurpos() &&
      \ s:state_after_newline.curline ==# getline('.') &&
      \ s:state_after_newline.line_count == line('$')
    return
  endif

  let prev_curline = s:state_after_newline.curpos[1]
  let undo_seq = s:state_after_newline.undo_seq

  let s:state_after_newline = {}
  augroup plugin-gyoza-applier
    autocmd!
  augroup END

  if line('.') != prev_curline || undotree().seq_cur != undo_seq
    " Cursor moved to another line or new undo block is made by user.  Give up
    " making undo separation point.
    return
  endif

  " Make a new undo block for the buffer state where just completed the pair.
  " Firstly remove the current line and restore the previous buffer state,
  " then make a undo separation point, and lastly restore the buffer.
  const curpos = getcurpos()
  const curline = getline('.')
  try
    delete _
    normal! $
    let &g:undolevels = &g:undolevels
    call setline('.', getline('.'))
  finally
    call append(line('.') - 1, curline)
    call setpos('.', curpos)
  endtry
endfunction

function s:remove_newline() abort
  augroup plugin-gyoza-applier
    autocmd!
  augroup END
  let s:state_after_newline = {}

  if getline('.')->trim() ==# ''
    delete _
  endif
endfunction

function s:clear_temporal_mappings() abort
  iunmap <buffer> <Plug>(_gyoza_apply)
  iunmap <buffer> <Plug>(_gyoza_check_state)
  iunmap <buffer> <Plug>(_gyoza_do_input)
  iunmap <buffer> <Plug>(_gyoza_setup_newline_removal)
  iunmap <buffer> <Plug>(_gyoza_clear_temporal_mappings)
  return ''
endfunction

function s:replace_termcode(keys) abort
  return substitute(a:keys, '<[^<]\+>',
    \ '\=eval(printf(''"\%s"'', submatch(0)))', 'g')
endfunction

function s:get_indent_width(line) abort
  return a:line->matchstr('^\s*')->strdisplaywidth()
endfunction
