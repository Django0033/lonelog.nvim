# Apply Progress: tag-search-by-name

**Status**: Complete
**Date**: 2026-06-03

## Completed Tasks

1. **buffer.lua** — Added `group_filter`/`group_filter` support in `open_group_browser()`'s `<CR>` handler
   - Filter runs BEFORE window close (per design: stay in browser on no-match)
   - Prompts user with `vim.fn.input("Search <group name>: ")` when `opts.group_filter` is set
   - Empty/no query → skip filter, show all items
   - No matches → `vim.notify("No tags match")`, stay in browser
   - Existing callers unaffected (optional field)

2. **tags.lua** — Added `group_filter` callback to `show_tags_browser()` opts
   - Case-insensitive substring match against `tag.name` AND each entry in `tag.tags[]`
   - Uses `string.find(q, 1, true)` for plain match (no pattern-magic interference)

## Files Changed

| File | Action | Description |
|------|--------|-------------|
| `lua/lonelog/ui/buffer.lua` | Modified | Added group filter logic in `<CR>` handler (lines 70-81) |
| `lua/lonelog/parsers/tags.lua` | Modified | Added `group_filter` callback to `open_group_browser()` opts (lines 289-302) |

## Deviations

- **Filter before close**: The apply instructions' code snippet showed the filter appended after `nvim_win_close`, but the design's "Filter before close" decision is authoritative — the window only closes after the filter passes. Implemented per design.
- **No `_filter_by_query` extraction**: The design suggested extracting a pure `_filter_by_query` helper for testability, but the apply instructions specified inline definition. Since no new tests were required per the spec, inlined the filter.

## Issues

None. All tests pass with 0 failures.

## TDD Cycle Evidence

| Phase | Evidence |
|-------|----------|
| RED | N/A — no new test needed (apply instructions: `vim.fn.input` can't be mocked in standalone Lua) |
| GREEN | `lua tests/test_tags.lua` — 22/22 passed, 0 failed |
| REGRESSION | All 22 test suites: 0 failures across ~400 tests |
