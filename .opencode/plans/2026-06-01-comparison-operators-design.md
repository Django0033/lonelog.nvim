# Comparison Operators (`>=`, `<=`, `vs`)

**Date:** 2026-06-01
**Requires:** `dice.lua`

## Objective

Extend the dice engine to support additional comparison operators beyond `>`:
`>=`, `<=`, and `vs`. The display should show the actual operator used,
and success/fail should use the correct comparison logic.

## Current State

`parse_notation()` in `dice.lua` recognizes two comparison patterns:
- `>>N` — success counting (e.g., `6d6>>4`)
- `>N` — sum vs target (e.g., `2d6>7`)

The display hardcodes `>` in the notation string and uses `>=` internally
for the success check:

```
display: "2d6>7[4, 2] = 6 vs 7 -> Fail"
check:   sum >= target  (always >=)
```

Missing operators:
- `>=` — greater-or-equal (`1d20 >= 15`)
- `<=` — less-or-equal (`1d20 <= 10`)
- `vs` — semantic alias for `>=` (`d100 vs 50`)

## Changes

### `parse_notation()` in `dice.lua`

Add an `operator` field to the parsed object and check patterns in order
(to avoid `>` matching inside `>=`):

```lua
-- 1. Success counting (unchanged)
notation:match(">>%d+")  ->  target_mode = "successes"

-- 2. Greater-or-equal
notation:match(">=%d+")  ->  operator = ">=",  target_mode = "sum"

-- 3. Less-or-equal
notation:match("<=%d+")  ->  operator = "<=",  target_mode = "sum"

-- 4. Greater than (only if >= didn't match)
notation:match(">%d+")   ->  operator = ">",   target_mode = "sum"

-- 5. 'vs' (word-based)
notation:match("vs%s*%d+") -> operator = "vs", target_mode = "sum"
```

Each match removes the operator + target from the notation string via `gsub`.

### Result object

Add `operator` field (string or nil):
```lua
{
  operator = ">=",  -- ">=" | "<=" | ">" | "vs" | nil
}
```

### Display in `roll()`

Two places change:

1. **Display string** (line 159):
   Before: `dice_str .. ">" .. parsed.target`
   After:  `dice_str .. parsed.operator .. parsed.target`

2. **Result line** (lines 176-179):
   After:
   ```lua
   local op_map = { [">="] = ">=", ["<="] = "<=", [">"] = ">", ["vs"] = "vs" }
   local op_display = parsed.operator or ">"
   local ok = (parsed.operator == "<=" and sum <= parsed.target)
           or (parsed.operator == ">" and sum > parsed.target)
           or (sum >= parsed.target)
   string.format(" = %d %s %d -> %s", sum, op_display, parsed.target, ok and "Success" or "Fail")
   ```

   The `vs` operator uses `>=` semantics (same as `>=`).

### Edge cases

- `>=` must be checked before `>` to prevent `>=15` matching as `>15` with `=` left behind
- `>>` must remain first (before `>=`) since it starts with `>`
- `vs` may have optional whitespace: `"vs15"`, `"vs 15"`, `"vs  15"` all valid
- Empty operator string: `notation = "2d6"` -> `parsed.operator` remains `nil`

## Testing

New tests in `test_dice.lua`:

| Test | Notation | Expected |
|------|----------|----------|
| `>=` success | `1d20 >= 15` (seed gives 17) | `1d20>=15[17] = 17 >= 15 -> Success` |
| `>=` exact | `1d20 >= 15` (seed gives 15) | `1d20>=15[15] = 15 >= 15 -> Success` |
| `<=` fail | `1d20 <= 10` (seed gives 15) | `1d20<=10[15] = 15 <= 10 -> Fail` |
| `<=` exact | `1d20 <= 15` (seed gives 15) | `1d20<=15[15] = 15 <= 15 -> Success` |
| `vs` success | `d100 vs 50` (seed gives 60) | `d100vs50[60] = 60 vs 50 -> Success` |
| `>` exclusive | `1d20 > 15` (seed gives 15) | `1d20>15[15] = 15 > 15 -> Fail` |
| Regression: `>>` | `6d6>>4` | existing test still passes |
| Regression: `>N` | `2d6>7` | existing test still passes |

## YAGNI

- Fate dice (`4df`) -- separate feature
- Multiple comma-separated rolls -- separate feature
- S/F suffix flag -- separate feature
- Displaying operator in roll_line.lua output -- deferred
