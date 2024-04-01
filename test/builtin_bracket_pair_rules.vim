let s:assert = themis#helper('assert')

let s:tests = {}
let s:tests._ = {
  \ 'add_brace_rule': [
  \   [['{'], [1, '$'], ['{', '}']],
  \   [['{}'], {-> [1, match(getline(1), '{') + 1]}, ['{', '}']],
  \   [['{};'], {-> [1, match(getline(1), '{') + 1]}, ['{', '};']],
  \   [['{', '};'], [1, '$'], ['{', '', '};']],
  \   [['{foo}'], {-> [1, match(getline(1), '{') + 1]}, ['{', "\tfoo", '}']],
  \   [['F({, {2nd-arg})'], {-> [1, match(getline(1), '{') + 1]}, ['F({', "\t\t}, {2nd-arg})"]],
  \   [['[{]'], {-> [1, match(getline(1), '{') + 1]}, ['[{', '}]']],
  \   [['({)'], {-> [1, match(getline(1), '{') + 1]}, ['({', ' })']],
  \ ],
  \}
let s:tests.c = {
  \ 'add_brace_rule': [
  \   [['struct {'], [1, '$'], ['struct {', '};']],
  \   [['struct A {'], [1, '$'], ['struct A {', '};']],
  \   [['typedef struct {'], [1, '$'], ['typedef struct {', '};']],
  \   [['typedef struct {', 'public:'], [1, '$'], ['typedef struct {', '', 'public:']],
  \   [['typedef struct {', 'private:'], [1, '$'], ['typedef struct {', '', 'private:']],
  \   [['typedef struct {', 'protected:'], [1, '$'], ['typedef struct {', '', 'protected:']],
  \   [['enum {'], [1, '$'], ['enum {', '};']],
  \   [['enum A {'], [1, '$'], ['enum A {', '};']],
  \   [['typedef enum {'], [1, '$'], ['typedef enum {', '};']],
  \   [['typedef enum {', 'public:'], [1, '$'], ['typedef enum {', '', 'public:']],
  \   [['typedef enum {', 'private:'], [1, '$'], ['typedef enum {', '', 'private:']],
  \   [['typedef enum {', 'protected:'], [1, '$'], ['typedef enum {', '', 'protected:']],
  \   [['class A {'], [1, '$'], ['class A {', '};']],
  \   [['class A {', 'private:'], [1, '$'], ['class A {', '', 'private:']],
  \   [['class A {', 'protected:'], [1, '$'], ['class A {', '', 'protected:']],
  \   [['class A {', 'public:'], [1, '$'], ['class A {', '', 'public:']],
  \   [['switch (...) {'], [1, '$'], ['switch (...) {', '}']],
  \   [['switch (...) {', 'default:'], [1, '$'], ['switch (...) {', '', 'default:']],
  \   [['switch (...) {', 'case ...:'], [1, '$'], ['switch (...) {', '', 'case ...:']],
  \ ],
  \}
let s:tests.go = {
  \ 'add_brace_rule': [
  \   [['switch (...) {'], [1, '$'], ['switch (...) {', '}']],
  \   [['switch (...) {', 'default:'], [1, '$'], ['switch (...) {', '', 'default:']],
  \   [['switch (...) {', 'case ...:'], [1, '$'], ['switch (...) {', '', 'case ...:']],
  \   [['select {'], [1, '$'], ['select {', '}']],
  \   [['select {', 'default:'], [1, '$'], ['select {', '', 'default:']],
  \   [['select {', 'case ...:'], [1, '$'], ['select {', '', 'case ...:']],
  \   [['defer func(...) {'], [1, '$'], ['defer func(...) {', '}()']],
  \   [['go func(...) {'], [1, '$'], ['go func(...) {', '}()']],
  \  ],
  \ }
let s:tests.vim = {
  \ 'add_brace_rule': [
  \   [['{'], [1, '$'], ['{', "\t\t\t\\ }"]],
  \   [['{', "\t\t\t\\ }"], [1, '$'], ['{', '', "\t\t\t\\ }"]],
  \   [['{', "\t\t\t\\}"], [1, '$'], ['{', '', "\t\t\t\\}"]],
  \   [['{foo}'], {-> [1, match(getline(1), '{') + 1]}, ['{', "\t\t\t\\ foo", "\t\t\t\\ }"]],
  \   [['({)'], {-> [1, match(getline(1), '{') + 1]}, ['({', "\t\t\t\\ })"]],
  \   [['[{]'], {-> [1, match(getline(1), '{') + 1]}, ['[{', "\t\t\t\\ }]"]],
  \   [['vim9script', '{'], {-> [2, match(getline(2), '{') + 1]}, ['vim9script', '{', "\t}"]],
  \ ],
  \ 'add_bracket_rule': [
  \   [['['], [1, '$'], ['[', "\t\t\t\\ ]"]],
  \   [['[foo]'], {-> [1, match(getline(1), '[') + 1]}, ['[', "\t\t\t\\ foo", "\t\t\t\\ ]"]],
  \   [['([)'], {-> [1, match(getline(1), '[') + 1]}, ['([', "\t\t\t\\ ])"]],
  \   [['{[}'], {-> [1, match(getline(1), '[') + 1]}, ['{[', "\t\t\t\\ ]}"]],
  \   [['vim9script', '['], {-> [2, match(getline(2), '[') + 1]}, ['vim9script', '[', ']']],
  \   [['vim9script', '[]'], {-> [2, match(getline(2), '[') + 1]}, ['vim9script', '[', ']']],
  \ ],
  \}

function s:get_curpos(curpos) abort
  if type(a:curpos) ==# v:t_func
    return call(a:curpos, [])
  endif

  let line = a:curpos[0]
  if type(line) ==# v:t_string
    let line = line(line)
  endif

  let col = a:curpos[1]
  if type(col) ==# v:t_list
    let col = call('col', col)
  elseif type(col) ==# v:t_string
    let col = call('col', [[line, col]])
  endif

  return [line, col]
endfunction

function s:do_test_for_bracket_pair_rule(filetype, rule_name, lines, curpos, expected)
  if a:filetype !=# '_'
    execute 'set filetype=' .. a:filetype
  endif
  call gyoza#config#get_rules_for_filetype(a:filetype).clear_rules()
  call call(gyoza#builtin_rules#get_rules_for_filetype(a:filetype)[a:rule_name], [])
  call setline(1, a:lines)
  call call('cursor', s:get_curpos(a:curpos))
  call feedkeys("a\<CR>\<ESC>", 'nx')
  call s:assert.equals(GetAllLines(), a:expected)
endfunction

let s:suite = themis#suite('default-rules')

function s:suite.before()
  runtime autoload/gyoza.vim  " Reset callback.
  call test_override('char_avail', 1)
  filetype indent on
endfunction

function s:suite.after()
  for filetype in keys(s:tests)
    call gyoza#config#get_rules_for_filetype(filetype).clear_rules()
  endfor
  call gyoza#disable()
  filetype indent off
  call test_override('char_avail', 0)
  %bwipeout!
endfunction

function s:suite.before_each()
  %bwipeout!
  setlocal cindent
  call gyoza#enable()  " Restore state
endfunction

function s:suite.after_each()
  call gyoza#config#get_rules_for_filetype('_').clear_rules()
endfunction

function s:suite.__test_bracket_pair_rules__()
  for [filetype, ft_tests] in items(s:tests)
    let suite = themis#suite(filetype)
    for [rule_name, cases] in items(ft_tests)
      let no_indent = rule_name =~# ':no-indent$'
      let rule_name = substitute(rule_name, ':no-indent$', '', '')

      for [idx, c] in copy(cases)->map('[v:key, v:val]')
        let test_name = printf('%s - %d', rule_name, idx)

        " Test without indentations.
        let suite[test_name .. ': without indentations'] =
        \ function('s:do_test_for_bracket_pair_rule', [filetype, rule_name] + c)

        if !no_indent
          " Test with indentations.
          let c = deepcopy(c)
          call map(c[0], 'empty(v:val) ? v:val : "\t" .. v:val')
          call map(c[2], 'empty(v:val) ? v:val : "\t" .. v:val')
          let suite[test_name .. ': with indentations'] =
          \ function('s:do_test_for_bracket_pair_rule', [filetype, rule_name] + c)
        endif
      endfor
    endfor
  endfor
endfunction
