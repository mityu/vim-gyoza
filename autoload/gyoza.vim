let s:skip_applicant = v:false

function gyoza#enable() abort
  call gyoza#observer#enable()
endfunction

function gyoza#disable() abort
  call gyoza#observer#disable()
endfunction

function s:trigger_applicant() abort
  if !s:skip_applicant
    let s:skip_applicant = v:true
    let rules =
      \ gyoza#config#get_rules_for_filetype(&l:filetype)._rules +
      \ gyoza#config#get_rules_for_filetype('_')._rules
    call gyoza#applier#trigger_applicant(rules)
  endif
endfunction

function s:on_finish_applicant() abort
  let s:skip_applicant = v:false
endfunction

call gyoza#observer#set_callback_on_trigger_applicant(function('s:trigger_applicant'))
call gyoza#applier#set_callback_on_finish_applicant(function('s:on_finish_applicant'))