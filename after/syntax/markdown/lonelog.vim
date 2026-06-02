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
  \ start='\v\[(N|L|PC|E|THREAD|CLOCK|TRACK|TIMER|INV|WEALTH|R|F|TAG|#N):'
  \ end='\]'
  \ contains=lonelogTagBracket,lonelogTagType,lonelogTagSep
  \ keepend
  \ oneline

syn match lonelogTagBracket '\v\[|\]' contained
syn match lonelogTagType '\v(N|L|PC|E|THREAD|CLOCK|TRACK|TIMER|INV|WEALTH|R|F|TAG|#N):' contained
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

" === Roll context tags inside d: lines ===
syn region lonelogDiceContext matchgroup=lonelogDiceContextBracket
  \ start='\v(^d:\s.{-})\zs\['
  \ end='\v\]'
  \ keepend

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

" === Multi-line tags (span lines, close with ] on its own line) ===
syn region lonelogTagML
  \ start='\v\[(N|L|PC|E|THREAD|CLOCK|TRACK|TIMER|INV|WEALTH|R|F|TAG|#N):'
  \ end='^\s*\]'
  \ contains=lonelogTagMLBracket,lonelogTagMLType,lonelogTagMLSep,lonelogTagMLContent
  \ keepend

syn match lonelogTagMLBracket '\v\[|\]' contained
syn match lonelogTagMLType '\v(N|L|PC|E|THREAD|CLOCK|TRACK|TIMER|INV|WEALTH|R|F|TAG|#N):' contained
syn match lonelogTagMLSep '|' contained
syn match lonelogTagMLContent '.*' contained contains=lonelogModArrow,lonelogModPlus,lonelogModMinus,lonelogProgressNum

" === Block delimiters [COMBAT] [/COMBAT] ===
syn match lonelogBlock '\v\[/?[A-Z]+\]'

" === Round markers (R1, R2, etc.) ===
syn match lonelogRound '\v^R\d+\s'

" === Narrative block delimiters (\--- and ---\) ===
syn match lonelogNarrativeDelim '\v^\\---$'
syn match lonelogNarrativeDelim '\v^---\\$'

" === Dialogue lines N (Name): "..." / PC [action] "..." ===
syn match lonelogDialogueTag '\v^(N|PC)' contained
syn match lonelogDialogueActor '\v\([^)]+\)' contained
syn match lonelogDialogueColon ':' contained
syn match lonelogDialogueString '\v".{-}"' contained

syn match lonelogDialogue
  \ '\v^(N|PC)\s*(\([^)]+\))?:\s*(\[.{-}\]\s*)?".{-}"'
  \ contains=lonelogDialogueTag,lonelogDialogueActor,lonelogDialogueColon,lonelogDialogueString

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
hi def link lonelogDiceContext Identifier
hi def link lonelogDiceContextBracket Delimiter
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
hi def link lonelogDialogue Normal
hi def link lonelogDialogueTag Type
hi def link lonelogDialogueActor Function
hi def link lonelogDialogueColon Delimiter
hi def link lonelogDialogueString String
hi def link lonelogTagML Normal
hi def link lonelogTagMLBracket Delimiter
hi def link lonelogTagMLType Type
hi def link lonelogTagMLSep Delimiter
hi def link lonelogTagMLContent String
