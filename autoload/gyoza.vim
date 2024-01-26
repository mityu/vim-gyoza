vim9script

def GetOneIndent(): string
  # TODO: 'smarttab' support
  if &l:expandtab || strdisplaywidth("\t") != shiftwidth()
    return repeat(' ', shiftwidth())
  else
    return "\t"
  endif
enddef

def GetIndentDepth(line: number): number
  var indent = getline(line)->matchstr('^\s*')->strdisplaywidth()
  return indent / shiftwidth()
enddef

def GetIndentStr(depth: number): string
  return repeat(GetOneIndent(), depth)
enddef

def Error(msg: string)
  echohl ErrorMsg
  for m in msg->split("\n")
    echomsg '[gyoza]' m
  endfor
  echohl NONE
enddef

class Rule
  var pattern: string
  var pair: any  # string or func
  # var canceler_literal: list<string>
  # var canceler_regexp: list<string>
endclass

# Holds configurations for one filetype
class Config
  var rules: list<Rule>

  def new()
    this.rules = []
  enddef

  def ClearRule(): any
    this.rules = []
    return this
  enddef

  def AddRule(pattern: string, pair: any): any
    this.rules->add(Rule.new(pattern, pair))
    return this
  enddef

  def ExtendRules(configGiven: any): any
    const config: Config = configGiven
    this.rules->extend(config.rules->copy())
    return this
  enddef
endclass

# Watch buffer and detect newline.
# Note that this class is singleton class.
class Observer
  # Holds a Observer instance to call class methods via autocmd because
  # unfortunately `autocmd ... call this.Fn()` doesn't work.
  # This makes this class singleton.
  static var instance: any

  var _linesCount: number
  const CallbackOnTriggerAppication: func()

  def new(CallbackOnTriggerAppication: func())
    Observer.instance = this
    this.CallbackOnTriggerAppication = CallbackOnTriggerAppication
    this.InitForBuffer()
  enddef

  def Enable()
    augroup plugin-gyoza-observer
      autocmd!
      autocmd BufEnter * Observer.instance.InitForBuffer()
      autocmd TextChangedI * Observer.instance.OnTextChangedI()
      autocmd TextChanged * Observer.instance.OnTextChanged()
      autocmd CmdwinEnter * ++once Observer.instance.OnCmdwinEnter()
    augroup END

    # `this.InitForBuffer()` fails with E685 error.  As a workaround call via
    # 'instance' class variable.
    const obj: Observer = Observer.instance
    obj.InitForBuffer()
  enddef

  def Disable()
    augroup plugin-gyoza-observer
      autocmd!
    augroup END
  enddef

  def InitForBuffer()
    this._linesCount = line('$')
  enddef

  def OnTextChangedI()
    const didNewline = this._didNewline()
    this._updateContext()
    if didNewline
      call(this.CallbackOnTriggerAppication, [])
    endif
  enddef

  def OnTextChanged()
    this._updateContext()
  enddef

  def OnCmdwinEnter()
    # Disable gyoza.vim in cmdwin
    augroup plugin-gyoza-observer
      autocmd!
      autocmd CmdwinLeave * ++once Observer.instance.Enable()
    augroup END
  enddef

  def _didNewline(): bool
    return line('$') > this._linesCount
  enddef

  def _updateContext()
    this._linesCount = line('$')
  enddef
endclass

class Applier
  static var _ruleStack: list<Rule> = []
  static const _mapClearer = "\<Cmd>iunmap <buffer> <Plug>(_gyoza-do-apply)\<CR>\<Cmd>iunmap <buffer> <Plug>(_gyoza-do-check)\<CR>\<Cmd>iunmap <buffer> <Plug>(_gyoza-input)\<CR>"

  def TriggerApplication(allRules: list<Rule>)
    const prevlinenr = prevnonblank(line('.') - 1)
    const nextlinenr = nextnonblank(line('.') + 1)
    const prevline = getline(prevlinenr)
    const nextline = getline(nextlinenr)

    if Applier._getIndentWidth(nextline) > Applier._getIndentWidth(prevline)
      return
    endif

    Applier._ruleStack =
      allRules->copy()->filter((_: number, r: Rule): bool => prevline =~# r.pattern)

    imap <buffer> <silent> <expr> <Plug>(_gyoza-do-apply) Applier.DoApply()
    imap <buffer> <silent> <expr> <Plug>(_gyoza-do-check) Applier.CheckApplyState()
    inoremap <buffer> <silent> <Plug>(_gyoza-input) <Nop>

    this._feedkeys('<Plug>(_gyoza-do-apply)', 'mi!')
  enddef

  static def DoApply(): string
    if empty(Applier._ruleStack)
      return Applier._mapClearer
    endif
    const rule = Applier._ruleStack->remove(0)
    execute 'inoremap <buffer> <Plug>(_gyoza-input)' rule.pair

    # I don't know why but the last input character will be disappared without
    # <Ignore> between these two mappings.
    return "\<Plug>(_gyoza-input)\<Ignore>\<Plug>(_gyoza-do-check)"
  enddef

  static def CheckApplyState(): string
    const curline = getline('.')
    const nextline = getline(nextnonblank(line('.') + 1))

    if Applier._getIndentWidth(curline) == Applier._getIndentWidth(nextline) &&
        trim(curline) ==# trim(nextline)
      inoremap <buffer> <Plug>(_gyoza-input) <C-u>
    else
      Applier._ruleStack = []
      inoremap <buffer> <Plug>(_gyoza-input) <C-g>U<Up><C-g>U<End><CR>
    endif

    return "\<Plug>(_gyoza-input)\<Plug>(_gyoza-do-apply)"
  enddef

  static def _getIndentWidth(line: string): number
    return line->matchstr('^\s*')->strdisplaywidth()
  enddef

  def _feedkeys(keys: string, flags: string = 'nix!')
    feedkeys(Applier._replaceTermcode(keys), flags)
  enddef

  static def _replaceTermcode(keys: string): string
    return substitute(keys, '<[^<]\+>',
      '\=eval(printf(''"\%s"'', submatch(0)))', 'g')
  enddef
endclass

# For testing
def GetClasses(): dict<any>
  return {
    Config: (): Config => Config.new(),
    Observer: (Fn: any): Observer => Observer.new(Fn),
    Applier: (): Applier => Applier.new(),
  }
enddef

defcompile
