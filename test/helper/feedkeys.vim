function s:replace_termcodes(from) abort
  return substitute(a:from, '<[^<]\+>',
   \ '\=eval(printf(''"\%s"'', submatch(0)))', 'g')
endfunction

command -nargs=* Feedkeys call feedkeys(s:replace_termcodes(<q-args>), 'nix')
