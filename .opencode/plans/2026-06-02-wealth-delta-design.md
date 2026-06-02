# Wealth Delta Commands

**Date:** 2026-06-02
**Requires:** `addons/resources/init.lua`, `addons/resources/resources.lua`

## Objective

Add command and keymap to increment/decrement wealth values in `[Wealth:Gold N]` tags.

## Changes

### 1. Config key

In `config.lua`:
```lua
wealth_delta = "<leader>lwd",
```

### 2. Function in `resources.lua`

`M.wealth_delta()`:
- Find `[Wealth:]` tag on current line
- Parse currency name and current value
- Prompt for amount (positive = add, negative = subtract)
- Update tag in-place

### 3. Registration in `init.lua`

Add command and keymap to the resources addon registration.

## Testing

~2 tests: parse wealth tag and apply delta, negative value.
