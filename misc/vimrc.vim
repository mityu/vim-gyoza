if &compatible
  set nocompatible
endif
if !has('nvim')
  set noesckeys
endif

execute 'set runtimepath+=' . expand('<sfile>:h:h')

filetype indent plugin on
" set filetype=vim
set buftype=nofile noswapfile noundofile
set expandtab smarttab shiftwidth=2
set smartindent autoindent

nnoremap q <C-w>q

" call gyoza#enable()
" call gyoza#config#get_rules_for_filetype('vim').add_rule('^\s*if\>', 'endif', ['else', '\=^\s*elseif\>'])
let g:gyoza_disable_auto_setup = 1
call gyoza#enable()
call gyoza#builtin_rules#load_all_rules_for_filetype('_')

