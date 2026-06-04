# Proposal: Tag Search by Name

## Intent

Non-Telescope tags browser (used when Telescope is disabled) has no search. Users scroll through every tag to find one. Add a case-insensitive search prompt that filters tags by name and metadata tags before displaying the group browser.

## Scope

### In Scope
- `vim.fn.input()` prompt in the tags browser path, matching existing codebase pattern (`plugin/helpers.lua:26`)
- Case-insensitive match on tag name AND tag metadata (e.g. `tags = {"friendly", "merchant"}`)
- Optional `opts.group_filter` callback in `buffer.lua` `open_group_browser()` so it stays general-purpose
- Empty query → show all. No matches → `vim.notify("No tags match")`. Empty group → skip prompt.

### Out of Scope
- Telescope-style fuzzy search or Telescope integration changes
- Re-parsing or cache invalidation logic
- Search history or persistent state

## Capabilities

### New Capabilities
- `tag-search-by-name`: Filter tags by name (and metadata tags) via input prompt before opening the group browser. Case-insensitive substring match.

### Modified Capabilities
- None. The parsed-elements-cache spec is unaffected — this is UI-only filtering over cached data.

## Approach

1. Pass `group_filter` option to `open_group_browser()` — if set, the `<CR>` handler filters items through it before displaying.
2. In `show_tags_browser()`, prompt the user with `vim.fn.input("Search tags: ")` before calling `open_group_browser()`.
3. If query is empty, pass all items through. If no items match, `vim.notify` and return.
4. Filter matches case-insensitively against `tag.name` AND each `tag.tags[]` entry.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lua/lonelog/ui/buffer.lua` | Modified | Add `opts.group_filter` check inside `open_group_browser()` `<CR>` handler (~10 lines) |
| `lua/lonelog/parsers/tags.lua` | Modified | Add `group_filter` callback + prompt in `show_tags_browser()` (~15 lines) |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Prompt dismissed (empty input) breaks flow | Low | Treat empty string as "show all" — no-op |
| User hits `<Esc>` on prompt | Low | `vim.fn.input()` returns empty string on cancel — same empty-string path |

## Rollback Plan

Revert the two files (`buffer.lua`, `tags.lua`) via git checkout. The change touches only these files and has no schema, config, or dependency impact.

## Dependencies

- None. Pure UI filtering over already-cached data.

## Success Criteria

- [ ] Typing a name substring filters group items to only matching tags
- [ ] Search matches tag name AND tag metadata (e.g. `tags` array entries)
- [ ] Empty query returns all items (no filtering)
- [ ] No-match query shows `vim.notify("No tags match")` and returns to caller
- [ ] All existing tests pass
