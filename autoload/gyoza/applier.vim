let s:cursor_text = ''  " The text after cursor.
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

  " Do not apply rules when
  " - the next line has deeper indentation
  " - some text exists before cursor
  if s:get_indent_width(getline(nextlinenr)) > s:get_indent_width(prevline) ||
    \ strpart(getline('.'), 0, col('.') - 1)->trim() !=# ''
    call call(s:callback_on_finish_applicant, [])
    return
  endif

  let s:rule_stack = a:all_rules->deepcopy()->filter('prevline =~# v:val.pattern')
  let s:cursor_text = getline('.')[col('.') - 1 :]

  inoremap <buffer> <silent> <expr> <Plug>(_gyoza_apply) <SID>do_apply()
  inoremap <buffer> <silent> <expr> <Plug>(_gyoza_check_state) <SID>check_apply_state()
  inoremap <buffer> <Plug>(_gyoza_do_input) <Nop>
  inoremap <buffer> <expr> <Plug>(_gyoza_setup_newline_removal)
    \ <SID>setup_newline_removal()
  inoremap <buffer> <expr> <Plug>(_gyoza_clear_temporal_mappings)
    \ <SID>clear_temporal_mappings()

  if s:cursor_text ==# ''
    inoremap <buffer> <Plug>(_gyoza_restore_cursor_text) <Nop>
    inoremap <buffer> <Plug>(_gyoza_remove_cursor_text) <Nop>
  else
    const restore_text = s:escape_text_for_mapping(s:cursor_text)
    execute 'inoremap <buffer> <silent> <Plug>(_gyoza_restore_cursor_text)'
      \ restore_text .. repeat('<C-g>U<Left>', strchars(s:cursor_text))
    execute 'inoremap <buffer> <silent> <Plug>(_gyoza_remove_cursor_text)'
      \ repeat('<Del>', strchars(s:cursor_text))
  endif
  call feedkeys("\<Plug>(_gyoza_apply)", 'mi!')
endfunction

function s:do_apply() abort
  if empty(s:rule_stack)
    call call(s:callback_on_finish_applicant, [])
    return "\<Plug>(_gyoza_clear_temporal_mappings)"
  endif
  let s:current_rule = s:rule_stack->remove(0)

  if type(s:current_rule.pair) == v:t_func
    const prevline = getline(prevnonblank(line('.') - 1))
    const nextline = getline(nextnonblank(line('.') + 1))
    const curline = getline('.')[col('.') - 1 :]
    const config = call(s:current_rule.pair, [{
      \ 'previous': prevline,
      \ 'current': curline,
      \ 'next': nextline,
      \}])

    const skip = get(config, 'skip', '')
    if skip ==# 'all'
      call call(s:callback_on_finish_applicant, [])
      return "\<Plug>(_gyoza_clear_temporal_mappings)"
    elseif skip ==# 'this'
      return "\<Plug>(_gyoza_apply)"
    endif

    if !has_key(config, 'pair')
      echohl ErrorMsg
      echomsg '[gyoza] "pair" or "skip" is required.'
        \ .. ' See :h gyoza-rule-stack-add_rule-functional-pair for the details.'
      echohl NONE
      call call(s:callback_on_finish_applicant, [])
      return "\<Plug>(_gyoza_clear_temporal_mappings)"
    endif

    let s:current_rule.pair = config.pair

    if has_key(config, 'cancelers')
      for c in config.cancelers
        if c =~# '^\\='
          if strlen(c) > 2
            call add(s:current_rule.canceler_regexp, c[2 :])
          endif
        else
          call add(s:current_rule.canceler_literal, c)
        endif
      endfor
    endif

    if has_key(config, 'cursor_text')
      let s:current_rule.cursor_text = config.cursor_text
    endif
  endif

  execute 'inoremap <buffer> <Plug>(_gyoza_do_input)' s:current_rule.pair

  " I don't know why but the last input character will be disappared without
  " <Ignore> between these two mappings.
  return "\<Plug>(_gyoza_remove_cursor_text)\<Plug>(_gyoza_do_input)" ..
    \ "\<Ignore>\<Plug>(_gyoza_check_state)"
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
    return "\<Plug>(_gyoza_do_input)\<Plug>(_gyoza_restore_cursor_text)\<Plug>(_gyoza_apply)"
  else
    " The latest applied rule matched all the requirements.  Clear the rules
    " stack, create newline, and remove all the temporal plugin mappings.
    let s:rule_stack = []

    if has_key(s:current_rule, 'cursor_text')
      let s:cursor_text = s:current_rule.cursor_text
    endif
    let rhs_do_input = '<C-g>U<Up><C-g>U<End><CR>'
    if s:cursor_text !=# ''
      const restore_text = s:escape_text_for_mapping(s:cursor_text)
      let rhs_do_input ..= restore_text .. repeat('<C-g>U<Left>', strchars(s:cursor_text))
    endif

    execute 'inoremap <buffer> <Plug>(_gyoza_do_input)' rhs_do_input
    return "\<Plug>(_gyoza_do_input)\<Plug>(_gyoza_setup_newline_removal)" ..
      \ "\<Plug>(_gyoza_clear_temporal_mappings)"
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
  iunmap <buffer> <Plug>(_gyoza_remove_cursor_text)
  iunmap <buffer> <Plug>(_gyoza_restore_cursor_text)
  iunmap <buffer> <Plug>(_gyoza_clear_temporal_mappings)
  return ''
endfunction

function s:replace_termcode(keys) abort
  return substitute(a:keys, '<[^<]\+>',
    \ '\=eval(printf(''"\%s"'', submatch(0)))', 'g')
endfunction

function s:escape_text_for_mapping(text) abort
  return a:text
    \->substitute('<', '\<lt>', 'g')
    \->substitute('|', '<bar>', 'g')
endfunction

function s:get_indent_width(line) abort
  return a:line->matchstr('^\s*')->strdisplaywidth()
endfunction
