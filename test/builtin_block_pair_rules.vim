let s:assert = themis#helper('assert')

let s:tests = {}
let s:tests.go = {
  \ 'add_parenthesis_rule': [
  \   [['var ('], [1, 1], ['var (', ')']],
  \   [['const ('], [1, 1], ['const (', ')']],
  \   [['import ('], [1, 1], ['import (', ')']],
  \ ],
  \}
let s:tests.objc = {
  \ 'add_interface_rule:no-indent': [
  \   [['@interface A'], [1, 1], ['@interface A', '@end']],
  \   [['@interface A', '-(void)Fn;'], [1, 1], ['@interface A', '', '-(void)Fn;']],
  \ ],
  \ 'add_implementation_rule:no-indent': [
  \   [['@implementation A'], [1, 1], ['@implementation A', '@end']],
  \   [['@implementation A', '-(void)Fn {'], [1, 1], ['@implementation A', '', '-(void)Fn {']],
  \   [['@implementation A {', '}'], [1, 1], ['@implementation A {', '', '}']],
  \ ],
  \}
let s:tests.sh = {
  \ 'add_do_rule': [
  \   [['do'], [1, 1], ['do', 'done']],
  \   [['for ...; do'], [1, 1], ['for ...; do', 'done']],
  \ ],
  \ 'add_if_rule': [
  \   [['if ...; then'], [1, 1], ['if ...; then', 'fi']],
  \   [['if ...; then', 'else'], [1, 1], ['if ...; then', '', 'else']],
  \   [['if ...; then', 'else # comment'], [1, 1], ['if ...; then', '', 'else # comment']],
  \   [['if ...; then', 'elif foo'], [1, 1], ['if ...; then', '', 'elif foo']],
  \ ],
  \ 'add_case_rule': [
  \   [['case ... in'], [1, 1], ['case ... in', 'esac']],
  \ ],
  \}
let s:tests.tex = {
  \ 'add_begin_rule': [
  \   [['\begin{foo}'], [1, 1], ['\begin{foo}', '\end{foo}']],
  \   [['\begin{bar}'], [1, 1], ['\begin{bar}', '\end{bar}']],
  \   [['\begin{baz*}'], [1, 1], ['\begin{baz*}', '\end{baz*}']],
  \ ],
  \}
let s:tests.vim = {
  \ 'add_if_rule': [
  \   [['if foo'], [1, 1], ['if foo', 'endif']],
  \   [['if foo', 'endif'], [1, 1], ['if foo', '', 'endif']],
  \   [['if foo', 'else'], [1, 1], ['if foo', '', 'else']],
  \   [['if foo', 'elseif bar'], [1, 1], ['if foo', '', 'elseif bar']],
  \   [['if foo | bar | endif'], [1, 1], ['if foo | bar | endif', '']],
  \   [['if foo | bar | else | baz | endif'], [1, 1], ['if foo | bar | else | baz | endif', '']],
  \   [['if', "\tif", 'endif'], [2, 1], ['if', "\tif", "\tendif", 'endif']],
  \ ],
  \ 'add_while_rule': [
  \   [['while foo'], [1, 1], ['while foo', 'endwhile']],
  \ ],
  \ 'add_for_rule': [
  \   [['for foo in bar'], [1, 1], ['for foo in bar', 'endfor']],
  \ ],
  \ 'add_function_rule': [
  \   [['function F()'], [1, 1], ['function F()', 'endfunction']],
  \   [['legacy function F()'], [1, 1], ['legacy function F()', 'endfunction']],
  \   [['func F()'], [1, 1], ['func F()', 'endfunc']],
  \   [['function F()', 'endfunction'], [1, 1], ['function F()', '', 'endfunction']],
  \   [['func F()', 'endfunction'], [1, 1], ['func F()', '', 'endfunction']],
  \ ],
  \ 'add_def_rule': [
  \   [['def F()'], [1, 1], ['def F()', 'enddef']],
  \   [['export def F()'], [1, 1], ['export def F()', 'enddef']],
  \   [['legacy def F()'], [1, 1], ['legacy def F()', 'enddef']],
  \   [['static def F()'], [1, 1], ['static def F()', 'enddef']],
  \ ],
  \ 'add_try_rule': [
  \   [['try'], [1, 1], ['try', 'endtry']],
  \   [['try', 'catch /.../'], [1, 1], ['try', '', 'catch /.../']],
  \   [['try', 'finally'], [1, 1], ['try', '', 'finally']],
  \ ],
  \ 'add_augroup_rule': [
  \   [['augroup foo'], [1, 1], ['augroup foo', 'augroup END']],
  \   [['augroup END'], [1, 1], ['augroup END', '']],
  \ ],
  \ 'add_class_rule': [
  \   [['class A'], [1, 1], ['class A', 'endclass']],
  \   [['export class A'], [1, 1], ['export class A', 'endclass']],
  \   [['abstract class A'], [1, 1], ['abstract class A', 'endclass']],
  \   [['export abstract class A'], [1, 1], ['export abstract class A', 'endclass']],
  \   [['abstract export class A'], [1, 1], ['abstract export class A', '']],
  \ ],
  \ 'add_interface_rule': [
  \   [['interface A'], [1, 1], ['interface A', 'endinterface']],
  \   [['export interface A'], [1, 1], ['export interface A', 'endinterface']],
  \ ],
  \ 'add_enum_rule': [
  \   [['enum A'], [1, 1], ['enum A', 'endenum']],
  \   [['export enum A'], [1, 1], ['export enum A', 'endenum']],
  \ ],
  \ 'add_echohl_rule': [
  \   [['echohl A'], [1, 1], ['echohl A', 'echohl None']],
  \   [['echohl A', 'echo foo'], [1, 1], ['echohl A', '', 'echo foo']],
  \   [['echohl A', 'echomsg foo'], [1, 1], ['echohl A', '', 'echomsg foo']],
  \   [['echohl A', 'echow foo'], [1, 1], ['echohl A', '', 'echow foo']],
  \   [['echohl A', 'echoerr foo'], [1, 1], ['echohl A', '', 'echoerr foo']],
  \ ],
  \ 'add_heredoc_rule': [
  \   [['let l =<< END'], [1, 1], ['let l =<< END', 'END']],
  \   [['let g:l =<< END'], [1, 1], ['let g:l =<< END', 'END']],
  \   [['let s:l =<< END'], [1, 1], ['let s:l =<< END', 'END']],
  \   [['let l:l =<< END'], [1, 1], ['let l:l =<< END', 'END']],
  \   [['let l =<< EOL'], [1, 1], ['let l =<< EOL', 'EOL']],
  \   [['let l =<< END', 'END'], [1, 1], ['let l =<< END', '', 'END']],
  \   [['const l =<< END'], [1, 1], ['const l =<< END', 'END']],
  \   [['var l =<< END'], [1, 1], ['var l =<< END', 'END']],
  \   [['final l =<< END'], [1, 1], ['final l =<< END', 'END']],
  \ ],
  \}
" Skip vimspec tests because vimspec ftplugin needs themis.vim.
" let s:tests.vimspec = {
"  \ 'add_describe_rule': [
"  \   [['Describe ...'], [1, 1], ['Describe ...', 'End']],
"  \ ],
"  \ 'add_before_rule': [
"  \   [['Before all'], [1, 1], ['Before all', 'End']],
"  \   [['Before each'], [1, 1], ['Before each', 'End']],
"  \ ],
"  \ 'add_after_rule': [
"  \   [['After all'], [1, 1], ['After all', 'End']],
"  \   [['After each'], [1, 1], ['After each', 'End']],
"  \ ],
"  \ 'add_context_rule': [
"  \   [['Context ...'], [1, 1], ['Context ...', 'End']],
"  \ ],
"  \ 'add_it_rule': [
"  \   [['It ...'], [1, 1], ['It ...', 'End']],
"  \ ],
"  \}

function s:do_test_for_block_pair_rule(filetype, rule_name, lines, curpos, expected)
  if a:filetype !=# '_'
    execute 'set filetype=' .. a:filetype
  endif
  call gyoza#config#get_rules_for_filetype(a:filetype).clear_rules()
  call call(gyoza#builtin_rules#get_rules_for_filetype(a:filetype)[a:rule_name], [])
  call setline(1, a:lines)
  call call('cursor', a:curpos)
  call feedkeys("o\<ESC>", 'nx')
  call s:assert.equals(GetAllLines(), a:expected)
endfunction

let s:suite = themis#suite('builtin-rules')

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
  call gyoza#enable()  " Restore state
endfunction

function s:suite.after_each()
  call gyoza#config#get_rules_for_filetype('_').clear_rules()
endfunction

function s:suite.__test_block_pair_rules__()
  for [filetype, ft_tests] in items(s:tests)
    let suite = themis#suite(filetype)
    for [rule_name, cases] in items(ft_tests)
      let no_indent = rule_name =~# ':no-indent$'
      let rule_name = substitute(rule_name, ':no-indent$', '', '')

      for [idx, c] in copy(cases)->map('[v:key, v:val]')
        let test_name = printf('%s - %d', rule_name, idx)

        " Test without indentations.
        let suite[test_name .. ': without indentations'] =
        \ function('s:do_test_for_block_pair_rule', [filetype, rule_name] + c)

        if !no_indent
          " Test with indentations.
          let c = deepcopy(c)
          call map(c[0], 'empty(v:val) ? v:val : "\t" .. v:val')
          call map(c[2], 'empty(v:val) ? v:val : "\t" .. v:val')
          let suite[test_name .. ': with indentations'] =
          \ function('s:do_test_for_block_pair_rule', [filetype, rule_name] + c)
        endif
      endfor
    endfor
  endfor
endfunction
