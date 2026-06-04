# Design: Tag Search by Name

## Technical Approach

Add an `opts.group_filter` callback to `open_group_browser()` that filters group items before the sub-list opens — the window only closes if there are results. In `show_tags_browser()`, prompt with `vim.fn.input("Search tags: ")` and pass a filter closure that matches case-insensitively against `tag.name` AND each entry in `tag.tags[]`. Empty query → skip filter (no callback), no matches → `vim.notify("No tags match")` and stay in browser.

## Architecture Decisions

### Decision: Filter callback contracts

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Closure-only capture | Simple but can't reuse | ❌ |
| `fun(items, query)` + `opts.filter_query` | General-purpose, caller controls both filter logic AND query string | ✅ |

**Rationale**: Separating callback from query string means `open_group_browser()` stays general-purpose — any caller can use the same filter function with different queries. The `<CR>` handler passes `opts.group_filter(items, opts.filter_query or "")`.

### Decision: Filter before close

| Option | Tradeoff | Decision |
|--------|----------|----------|
| Filter after `nvim_win_close` | Browser gone on no-match | ❌ |
| Filter before `nvim_win_close` | User stays in browser, retry another group | ✅ |

**Rationale**: If no items match, the user stays in the group browser and can try a different group or press `q` to exit. The window only closes on a successful match.

### Decision: `string.find` plain match (not fuzzy)

**Choice**: `string.find(haystack, needle, 1, true)` — Lua's plain substring match.
**Rationale**: Matches the proposal scope ("case-insensitive substring match"). No Telescope-style fuzzy search. `true` as 4th arg disables Lua pattern magic chars.

## Data Flow

```
show_tags_browser(all_tags)
  │
  ▼
vim.fn.input("Search tags: ") → query
  │
  ├── query == "" → no-op, show all groups unchanged
  │
  └── query ≠ "" → build group_filter(items, q):
  │                   for each item:
  │                     item.name:lower():find(q:lower(), 1, true)  OR
  │                     any tag in item.tags[]:lower():find(q:lower(), 1, true)
  │                   → result or nil
  │
  ▼
open_group_browser({groups, group_filter, filter_query=query, ...})
  │
  ▼
<CR> pressed on group
  │
  ├── #group.items == 0 → skip filter (empty group guard)
  │
  ├── group_filter exists → filtered = group_filter(group.items, filter_query)
  │     ├── filtered == nil or #filtered == 0 → notify + return (stay in browser)
  │     └── filtered has items → proceed
  │
  └── no group_filter → use group.items as-is
  │
  ▼
nvim_win_close + open_items(filtered_items, ...)
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lua/lonelog/ui/buffer.lua` | Modify | Add `group_filter`/`filter_query` handling in `<CR>` handler (~10 lines) |
| `lua/lonelog/parsers/tags.lua` | Modify | Add `group_filter` closure + prompt in `show_tags_browser()` (~20 lines); extract pure filter helper for testing |

## Interfaces

### Modified: `buffer.open_group_browser(opts)`

New optional fields on `opts`:

```lua
---@field group_filter? fun(items: table[], query: string): table[]|nil
---@field filter_query? string
```

### New: `tags._filter_by_query(items, query)`

Pure function, extracted for testability:

```lua
---@param items table[]  Array of {name: string, tags: string[], ...}
---@param query string   Lower-case search string
---@return table[]|nil   Filtered items or nil if no matches
function M._filter_by_query(items, query)
  local result = {}
  local q = query:lower()
  for _, item in ipairs(items) do
    if item.name:lower():find(q, 1, true) then
      table.insert(result, item)
    else
      for _, tag in ipairs(item.tags or {}) do
        if tag:lower():find(q, 1, true) then
          table.insert(result, item)
          break
        end
      end
    end
  end
  return #result > 0 and result or nil
end
```

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | `tags._filter_by_query` — pure function | `tests/test_tags.lua`: add cases for name match, tags match, case-insensitive, no match, empty query, empty items |
| Unit | Empty group guard (buffer.lua) | `tests/test_buffer.lua` if created, or manual verification |
| Integration | Full flow `show_tags_browser` → filtered `open_group_browser` | Manual in Neovim (no e2e harness). Test by opening browser, typing query, verifying filtered groups |

The filter logic is pure data transformation — hit the extracted function with 6-8 test cases in the existing `test_tags.lua` file. No mocking needed for the filter itself.

## Open Questions

None. All design decisions align with the proposal.

## Migration / Rollout

No migration required. Pure UI change. The new `opts.group_filter` field is optional — existing callers of `open_group_browser()` are unaffected.
