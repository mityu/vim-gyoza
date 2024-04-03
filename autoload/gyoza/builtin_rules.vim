let s:plugin_root = expand('<sfile>:p:h:h:h')

function s:find_sid(filetype, scriptpath) abort
  let script_list =
    \ execute(printf('filter ;builtin_rules[\\/]%s.vim; scriptnames', a:filetype))
    \->split("\n")
    \->map({_, v -> matchlist(v, '^\s*\(\d\+\)\%(\s\+A\)\?:\s\+\(.*\)$')[1 : 2]})
    \->filter({_, v -> v[1]->fnamemodify(':p') ==# a:scriptpath})
  if empty(script_list)
    " Script is not loaded yet.
    return -1
  endif
  return str2nr(script_list[0][0])
endfunction

if has('win32')
  function s:normalize_path(path) abort
    return a:path->substitute('/', '\\', 'g')
  endfunction
else
  function s:normalize_path(path) abort
    return a:path
  endfunction
endif

let s:cache = {}
function gyoza#builtin_rules#get_rules_for_filetype(filetype) abort
  if has_key(s:cache, a:filetype)
    return s:cache[a:filetype]
  endif
  const scriptpath =
    \ printf('%s/builtin_rules/%s.vim', s:plugin_root, a:filetype)
    \ ->s:normalize_path()
    \ ->resolve()
  if !filereadable(scriptpath)
    let s:cache[a:filetype] = {}
    return {}
  endif
  let sid = s:find_sid(a:filetype, scriptpath)
  if sid == -1
    source `=scriptpath`
    let sid = s:find_sid(a:filetype, scriptpath)
    if sid == -1
      echohl Error
      echomsg '[gyoza] Internal error: couldn''t get SID:' scriptpath
      echohl None
      return {}
    endif
  endif
  let pattern = printf('^function\s<SNR>%d_\zs[^(]*\ze(', sid)
  let prefix = '<SNR>' .. sid .. '_'
  let fn_names = execute(printf('function /%s%d_\a', "\<SNR>", sid))
    \->split("\n")
    \->map({_, v -> matchstr(v, pattern)})
  let cache = {}
  for name in fn_names
    let cache[name] = function(prefix .. name)
  endfor
  let s:cache[a:filetype] = cache
  return cache
endfunction

let s:loaded_filetypes = {}
function gyoza#builtin_rules#load_all_rules_for_filetype(filetype, force_load = 0) abort
  if has_key(s:loaded_filetypes, a:filetype) && !a:force_load
    return
  endif
  let s:loaded_filetypes[a:filetype] = 1
  let rules = gyoza#builtin_rules#get_rules_for_filetype(a:filetype)
  for l:F in values(rules)
    call call(l:F, [])
  endfor
endfunction
