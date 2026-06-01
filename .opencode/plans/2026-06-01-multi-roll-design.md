# Multiple Comma-Separated Dice Notations

**Date:** 2026-06-01
**Requires:** `roll_line.lua`

## Objective

Support multiple dice notations separated by commas on a single `d:` line.
Each notation is rolled independently and results are joined with commas.

## Current State

`extract_d_notation()` and the `d:` processing branch in `process_line()`
assume a single notation per line:

```
d: 2d6, 1d8    ->  rolls only "2d6" (comma not in regex char class)
```

## Changes

### 1. `extract_d_notation()` — add comma to regex

Line 32: add `,` to the character class:

```lua
-- Before:
return line:match("^%s*d:%s*([%w%+%-%>%%%!%#%<%=\040%s]+)")
-- After:
return line:match("^%s*d:%s*([%w%+%-%>%%%!%#%<%=\040%s,]+)")
```

### 2. `d:` processing branch — split, roll, join

Replace lines 94-108 with a loop over comma-separated tokens:

```lua
if lower:match("^d:") then
  local raw = extract_d_notation(line)
  if not raw then return nil end

  local parts = {}
  for token in raw:gmatch("[^,]+") do
    local notation = token:match("^%s*(.-)%s*$")
    local dice = require("lonelog.dice")
    local result, err = dice.roll(notation)
    if not result then return nil, err end
    table.insert(parts, result.display)
  end

  local indent = line:match("^(%s*)")
  return indent .. "d: " .. table.concat(parts, ", ")
end
```

### Behavior

| Input | Output |
|-------|--------|
| `d: 2d6, 1d8` | `d: 2d6[4,2] = 6, 1d8[7] = 7` |
| `d: 2d6+3, 1d20>=15` | `d: 2d6+3[2,1] = 6, 1d20>=15[17] = 17 >= 15 -> Success` |
| `d: 2d6` (no comma) | `d: 2d6[4,2] = 6` (regression — unchanged) |

### Edge cases

- Consecutive commas: `d: 2d6,, 1d8` → empty token (gmatch skips it? No, Lua `gmatch` returns empty strings between consecutive delimiters. Actually in Lua, `string.gmatch("2d6,,1d8", "[^,]+")` returns `"2d6"`, `""`, `"1d8"`. The empty string trimmed would be `""`, and `dice.roll("")` returns an error. So this would fail. To avoid this, I should filter out empty tokens after trimming.)

Wait, actually in Lua, `string.gmatch("2d6,,1d8", "[^,]+")` would iterate over `"2d6"`, `""`, `"1d8"`. Hmm, I'm not sure about this. Let me check... Actually no, in Lua `gmatch` with the pattern `[^,]+` (one or more non-comma characters) would only match non-empty sequences. So `"2d6,,1d8"` would give `"2d6"` and `"1d8"`, skipping the empty match. So consecutive commas are handled gracefully.

- Whitespace handling: `"2d6, 1d8"` → tokens `"2d6"` and `" 1d8"` → trimmed to `"2d6"` and `"1d8"` ✓

### No comma operator ambiguity

None of the existing dice notations use commas:
- `2d6+3`, `1d20-2` — modifiers use `+`/`-`
- `2d20kh1`, `2d20kl1` — keep uses `kh`/`kl`
- `4d6!` — exploding uses `!`
- `6d6>>4` — success counting uses `>>`
- `2d6>7`, `1d20>=15`, `1d20<=10`, `d100 vs 50` — comparisons use `>`/`>=`/`<=`/`vs`

## YAGNI

- Mixed types: `d: 2d6, tbl: Forest (d6)` — not supported
- Text between notations: `d: 2d6 -> hit, 1d8 -> damage` — not supported
- Custom separator — comma is the only separator

## Testing

New tests in `test_roll_line.lua` (~3):

| Test | Line | Expected |
|------|------|----------|
| Two notations | `d: 2d6, 1d8` | Result starts with `d: ` and contains two `=` signs |
| With modifier | `d: 2d6+3, 1d20` | Both rolled, modifier applied to first |
| Regression: single | `d: 2d6+3` | Same result as before |
