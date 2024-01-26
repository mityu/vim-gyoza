" Holds configurations for one filetype
let s:rule_stack = #{
  \ _rules: [],
  \}

function s:clear_rules() dict abort
  let self._rules = []
  return self
endfunction
let s:rule_stack.clear_rules = function('s:clear_rules')

function s:add_rule(pattern, pair) dict abort
  call add(self._rules, #{
    \ pattern: a:pattern,
    \ pair: a:pair,
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
