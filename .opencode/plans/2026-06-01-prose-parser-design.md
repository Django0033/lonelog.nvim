# Prose Parser

**Date:** 2026-06-01
**Requires:** `parsers/tokenizer.lua`

## Objective

Parse prose elements from the buffer: meta notes `(note:)`, dialogue
`Name: "text"`, and narrative block boundaries (`---` / `\---` / `---\`).

## Location

New file: `lua/lonelog/parsers/prose.lua`

## API

```lua
M.parse_prose(lines) -> { meta_notes[], dialogues[], narrative_blocks[] }
```

## Detection rules

### Meta notes
Lines starting with `(` containing a matching `)`:
```
(note: something important)   -> content = "note: something important"
```

### Dialogue
Lines matching `Name: "text"` or `Context (Name): "text"`:
```
Alex: "Hello there"           -> speaker = "Alex", text = "Hello there"
PC (Kael): "I investigate"    -> speaker = "PC (Kael)", text = "I investigate"
N: "Watch out"                -> speaker = "N", text = "Watch out"
```

### Narrative blocks
Lines matching start (`\---` or standalone `---`) and end (`---\`):
```
\---                          -> boundary = "start", line = 20
---\                          -> boundary = "end", line = 25
```

## Implementation

Uses `tokenizer.tokenize()` to classify each line, then applies specific
parsing logic for `meta`, `dialogue`, and `narrative` types.

## Output

```lua
{
  meta_notes = {
    { content = "note: something important", line = 12 },
  },
  dialogues = {
    { speaker = "Alex", text = "Hello there", line = 15 },
    { speaker = "N", text = "Watch out", line = 16 },
    { speaker = "PC (Kael)", text = "I investigate", line = 18 },
  },
  narrative_blocks = {
    { start_line = 20, end_line = 25 },
  },
}
```

## Testing

~6 tests:
- Meta note simple
- Dialogue simple
- Dialogue PC
- Narrative start
- Narrative end
- Plain text returns nil
