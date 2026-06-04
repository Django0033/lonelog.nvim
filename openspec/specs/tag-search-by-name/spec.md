# Tag Search by Name Specification

## Purpose

Add case-insensitive substring filtering by tag name and metadata tags to the non-Telescope tags browser, using a `vim.fn.input()` prompt before displaying group contents.

## Requirements

### R1: Group Filter Option

`open_group_browser()` MUST accept an optional `opts.group_filter(items, group_name)` callback. When set, the `<CR>` handler MUST pass group items and name through the callback before opening the items browser.

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Filter applied | `opts.group_filter = fn`, group has 5 items | User presses `<CR>` on group | `fn(items, "Name")` is called; only matching items shown |
| No filter set | `opts.group_filter` is nil | User presses `<CR>` | All items shown unchanged |

### R2: Search Prompt Before Group

When calling `open_group_browser()`, `show_tags_browser()` MUST prompt the user with `vim.fn.input("Search " .. group.name .. ": ")` for any group with >0 items.

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Prompt shown | Group has >0 items | User selects group with `<CR>` | `vim.fn.input()` is called with the group name |
| Empty group | Group has 0 items | User selects group | Prompt skipped; empty browser opens directly |

### R3: Case-Insensitive Filter Match

The filter callback MUST include a tag if the query is a case-insensitive substring of `tag.name` OR any entry in `tag.tags[]`.

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Name match | Tag `{name="Jonah"}`, query `"jon"` | Filter runs | Tag included |
| Metadata tag match | Tag `{name="X", tags={"friendly","merchant"}}`, query `"frie"` | Filter runs | Tag included |
| Case insensitive | Tag `{name="Jonah"}`, query `"JON"` | Filter runs | Tag included |
| No match | Tag `{name="Jonah", tags={"friendly"}}`, query `"zebra"` | Filter runs | Tag excluded |

### R4: Empty Query Behavior

When the user submits an empty query (Enter or Esc), the filter MUST return all items unchanged.

| Scenario | Given | When | Then |
|----------|-------|------|------|
| Empty string | User sees prompt | User presses Enter | All items shown |
| Cancelled | User sees prompt | User presses Esc | All items shown |

### R5: No-Match Notification

When the filter produces zero matches, the system MUST call `vim.notify("No tags match")` and abort — it MUST NOT open the group browser.

| Scenario | Given | When | Then |
|----------|-------|------|------|
| No results | Query matches no items in group | Filter returns empty array | `vim.notify("No tags match")` called; no buffer opened |
