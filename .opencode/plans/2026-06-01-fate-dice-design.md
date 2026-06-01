# Fate Dice (4df)

**Date:** 2026-06-01
**Requires:** `dice.lua`

## Objective

Support Fate/Fudge dice notation (`4df`). Each die produces `+`, `0`, or `-`
with equal probability (2 of each per 6-sided die). Results range from -4 to +4.

## Changes

### `parse_notation()` — detect Fate dice

Insert Fate check after the standard `^(%d+)[dD](%d+)` pattern fails:

```lua
local fc = notation:match("^(%d+)[dD][Ff]")
if fc then
  p.count = tonumber(fc)
  p.is_fate = true
end
```

### `roll()` — early return for Fate dice

When `parsed.is_fate` is true, roll each die from `{"-", "-", "0", "0", "+", "+"}`,
sum +1/0/-1, build display with modifier:

```
4df[+, +, 0, -] = +1
4df+1[+, -, 0, 0] = 0
2df[-, 0] = -1
```

### Result object

```lua
{
  is_fate = true,
  count = 4,
  modifier = 0,
  rolls = {"+", "0", "0", "-"},
  total = 0,
  display = "4df[+, 0, 0, -] = 0",
}
```

## Testing

3 tests: basic 4df, 4df with modifier, 2df count.
