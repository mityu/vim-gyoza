let s:lines_count = 0
let s:callback_on_trigger_applicant = v:null

function s:init_for_buffer() abort
  call gyoza#observer#update_context()
endfunction

function s:did_newline() abort
  return line('$') > s:lines_count
endfunction

function s:on_TextChangedI() abort
  const did_newline = s:did_newline()
  call gyoza#observer#update_context()
  if did_newline
    call call(s:callback_on_trigger_applicant, [])
  endif
endfunction

function s:on_TextChanged() abort
  call gyoza#observer#update_context()
endfunction

function s:on_CmdwinEnter() abort
  " Disable gyoza.vim in cmdwin
  augroup plugin-gyoza-observer
    autocmd!
    autocmd CmdwinLeave * ++once call gyoza#observer#enable()
  augroup END
endfunction

function gyoza#observer#update_context() abort
  let s:lines_count = line('$')
endfunction

function gyoza#observer#set_callback_on_trigger_applicant(fn) abort
  let s:callback_on_trigger_applicant = a:fn
endfunction

function gyoza#observer#enable() abort
  augroup plugin-gyoza-observer
    autocmd!
    autocmd BufEnter * call s:init_for_buffer()
    autocmd TextChangedI * call s:on_TextChangedI()
    autocmd TextChanged * call s:on_TextChanged()
    autocmd CmdwinEnter * ++once call s:on_CmdwinEnter()
  augroup END
  call s:init_for_buffer()
endfunction

function gyoza#observer#disable() abort
  augroup plugin-gyoza-observer
    autocmd!
  augroup END
endfunction
