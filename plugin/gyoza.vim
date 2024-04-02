if exists('g:loaded_gyoza')
  finish
endif
let g:loaded_gyoza = 1

if !get(g:, 'gyoza_disable_auto_setup', 0)
  const s:load_builtin_rules = !get(g:, 'gyoza_disable_auto_loading_builtin_rules', 0)

  augroup plugin-gyoza-setup
    autocmd!
    autocmd FileType * call gyoza#config#load_rules_for_filetype(expand('<amatch>'))
    if s:load_builtin_rules
      autocmd FileType * call gyoza#builtin_rules#load_all_rules_for_filetype(expand('<amatch>'))
    endif
  augroup END

  " Initial loading.
  call gyoza#enable()
  call gyoza#config#load_rules_for_filetype('_')
  if s:load_builtin_rules
    call gyoza#builtin_rules#load_all_rules_for_filetype('_')
  endif

  unlet s:load_builtin_rules
endif
