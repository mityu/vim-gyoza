" Holds configurations for one filetype
let s:rule_stack = {
  \ '_rules': [],
  \}

function s:clear_rules() dict abort
  let self._rules = []
  return self
endfunction
let s:rule_stack.clear_rules = function('s:clear_rules')

function s:add_rule(pattern, pair, cancelers = []) dict abort
  let canceler_literal = []
  let canceler_regexp = []

  for canceler in a:cancelers
    if canceler =~# '^\\='
      if strlen(canceler) > 2
        call add(canceler_regexp, strpart(canceler, 2))
      endif
    else
      if canceler !=# ''
        call add(canceler_literal, canceler)
      endif
    endif
  endfor

  call add(self._rules, {
    \ 'pattern': a:pattern,
    \ 'pair': a:pair,
    \ 'canceler_literal': canceler_literal,
    \ 'canceler_regexp': canceler_regexp,
    \ })
  return self
endfunction
let s:rule_stack.add_rule = function('s:add_rule')

function s:extend_rules(rule_stack) dict abort
  call extend(self._rules, deepcopy(a:rule_stack._rules))
  return self
endfunction
let s:rule_stack.extend_rules = function('s:extend_rules')


function s:new_rule_stack() abort
  return deepcopy(s:rule_stack)
endfunction


" Holds configurations for all functions
let s:config = {}

function gyoza#config#get_rules_for_filetype(filetype) abort
  if !has_key(s:config, a:filetype)
    let s:config[a:filetype] = s:new_rule_stack()
  endif
  return s:config[a:filetype]
endfunction

" For testing.
function s:get_all_rules() abort
  return s:config
endfunction
