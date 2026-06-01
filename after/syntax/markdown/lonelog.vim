" Lonelog notation syntax highlighting for markdown buffers
" Sourced automatically after syntax/markdown.vim

" === Session headers ===
syn match lonelogSessionHeader '\v^## Session \d+$'

" === Date stamps (standalone YYYY-MM-DD line) ===
syn match lonelogDateStamp '\v^\d{4}-\d{2}-\d{2}$'

" === Scene markers (ID after ###) ===
syn match lonelogSceneId '\v^###\s+\zs(S\d+([a-z])?(\.\d+)?|T\d+(\+T\d+)?(-S\d+)?)\ze'

" === Entity tags [TYPE:...] ===
syn region lonelogTag
  \ start='\v\[(N|L|PC|E|THREAD|CLOCK|TRACK|TIMER|INV|R|F|TAG|#N):'
  \ end='\]'
  \ contains=lonelogTagBracket,lonelogTagType,lonelogTagSep
  \ keepend

syn match lonelogTagBracket '\v\[|\]' contained
syn match lonelogTagType '\v(N|L|PC|E|THREAD|CLOCK|TRACK|TIMER|INV|R|F|TAG|#N):' contained
syn match lonelogTagSep '|' contained

" === Tag modifiers (inside tags after pipe) ===
syn match lonelogModArrow '→' contained containedin=lonelogTag
syn match lonelogModPlus '\v\+[^|]+' contained containedin=lonelogTag
syn match lonelogModMinus '\v\-[^|]+' contained containedin=lonelogTag

" === Progress numbers (N/M inside tags) ===
syn match lonelogProgressNum '\v\d+/\d+' contained containedin=lonelogTag

" === Action markers (magic mode: @ is literal) ===
syn match lonelogAction '^@\(\s\|$\)'
syn match lonelogActor '@([^)]*)'

" === Oracle questions ===
syn match lonelogQuestion '^?\s'

" === Dice prefix ===
syn match lonelogDicePrefix '^d:\s'

" === Dice notation (inline) ===
syn match lonelogDiceNotation '\v<\d+d\d+([+-]\d+)?(!)?(kh\d+)?(kl\d+)?(>>\d+)?(>\d+)?'

" === Result arrows (magic mode: -> and => are literal) ===
syn match lonelogArrow '->'
syn match lonelogArrow '=>'

" === Inline table references [[...]] ===
syn region lonelogTableRef matchgroup=lonelogTableBracket
  \ start='\v\[\['
  \ end='\v\]\]'

" === Generator headers ===
syn match lonelogGen '\v^gen:'

" === Meta notes (note: ... / nota: ...) ===
syn region lonelogNota matchgroup=lonelogNotaParen
  \ start='\v\((nota|note):'
  \ end='\v\)'
  \ keepend

" === Multi-line tags [TYPE:Name| ... |] ===
syn region lonelogTagML
  \ start='\v\[(N|L|PC|E|THREAD|CLOCK|TRACK|TIMER|INV|R|F|TAG|#N):[^]]*\|$'
  \ end='\v^\s*\|\]'
  \ contains=lonelogTagMLBracket,lonelogTagMLType,lonelogTagMLContent
  \ keepend

syn match lonelogTagMLBracket '\v\[|\|\]' contained
syn match lonelogTagMLType '\v(N|L|PC|E|THREAD|CLOCK|TRACK|TIMER|INV|R|F|TAG|#N):' contained
syn match lonelogTagMLContent '.*' contained contains=lonelogModArrow,lonelogModPlus,lonelogModMinus,lonelogProgressNum

" === Block delimiters [COMBAT] [/COMBAT] ===
syn match lonelogBlock '\v\[/?[A-Z]+\]'

" === Round markers (R1, R2, etc.) ===
syn match lonelogRound '\v^R\d+\s'

" === Narrative block delimiters (\--- and ---\) ===
syn match lonelogNarrativeDelim '\v^\\---$'
syn match lonelogNarrativeDelim '\v^---\\$'

" ============================================================
" Highlight links (default to standard groups for colorscheme compatibility)
" ============================================================
hi def link lonelogSessionHeader Title
hi def link lonelogDateStamp Constant
hi def link lonelogSceneId Identifier
hi def link lonelogTag Normal
hi def link lonelogTagBracket Delimiter
hi def link lonelogTagType Type
hi def link lonelogTagSep Delimiter
hi def link lonelogModArrow Special
hi def link lonelogModPlus Special
hi def link lonelogModMinus Special
hi def link lonelogProgressNum Number
hi def link lonelogAction Function
hi def link lonelogActor Function
hi def link lonelogQuestion Question
hi def link lonelogDicePrefix PreProc
hi def link lonelogDiceNotation Number
hi def link lonelogArrow Operator
hi def link lonelogTableRef String
hi def link lonelogTableBracket Delimiter
hi def link lonelogGen PreProc
hi def link lonelogNota Comment
hi def link lonelogNotaParen Comment
hi def link lonelogBlock WarningMsg
hi def link lonelogRound Constant
hi def link lonelogNarrativeDelim Comment
hi def link lonelogTagML Normal
hi def link lonelogTagMLBracket Delimiter
hi def link lonelogTagMLType Type
hi def link lonelogTagMLContent String
