if &compatible
  set nocompatible
endif

unlet! g:skip_defaults_vim
source $VIMRUNTIME/defaults.vim
set packpath^=~/.cache/vim
packadd! autoplay.vim
packadd! gyoza

colorscheme retrobox

set buftype=nofile noswapfile noundofile nobackup
set expandtab smarttab shiftwidth=2
set smartindent autoindent

call autoplay#reserve({
  \ 'wait': 60,
  \ 'spell_out': v:true,
  \ 'remap': v:false,
  \ 'scripts': [
  \   ":set filetype=vim\<CR>",
  \   "ifunction FizzBuzz(num) abort\<CR>",
  \   "for n in range(1, a:num)\<CR>",
  \   "if n % 15 == 0\<CR>",
  \   "elseif n % 5 == 0",
  \   "\<CR>elseif n % 3 == 0",
  \   "\<CR>else\<ESC>",
  \   'kkko',
  \   "echomsg 'FizzBuzz'\<ESC>",
  \   'jo',
  \   "echomsg 'Buzz'\<ESC>",
  \   'jo',
  \   "echomsg 'Fizz'\<ESC>",
  \   'jo',
  \   "echohl Constant\<CR>",
  \   "echomsg n\<ESC>",
  \   "Go\<CR>augroup fizzbuzz\<CR>",
  \   "autocmd!\<CR>",
  \   "autocmd CursorHold * call FizzBuzz(20)\<ESC>",
  \ ]->map('[v:val, {"wait": 500}]')->flatten(),
  \})

nnoremap @ <Cmd>call autoplay#run()<CR>
