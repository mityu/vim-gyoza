let s:skip_applicant = v:false

function gyoza#enable() abort
  call gyoza#observer#enable()
endfunction

function gyoza#disable() abort
  call gyoza#observer#disable()
endfunction

function gyoza#enable_for_buffer() abort
  let b:gyoza_enable = 1
  let s:skip_applicant = v:false
endfunction

function gyoza#disable_for_buffer() abort
  let b:gyoza_enable = 0
  let s:skip_applicant = v:false
endfunction

function s:trigger_applicant() abort
  if !s:skip_applicant && get(b:, 'gyoza_enable', 1)
    let s:skip_applicant = v:true
    let rules =
      \ gyoza#config#get_rules_for_filetype(&l:filetype)._rules +
      \ gyoza#config#get_rules_for_filetype('_')._rules
    call gyoza#applier#trigger_applicant(rules)
  endif
endfunction

function s:on_finish_applicant() abort
  let s:skip_applicant = v:false
  call gyoza#observer#update_context()
endfunction

call gyoza#observer#set_callback_on_trigger_applicant(function('s:trigger_applicant'))
call gyoza#applier#set_callback_on_finish_applicant(function('s:on_finish_applicant'))
