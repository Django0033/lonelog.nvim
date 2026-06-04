# Proposal: Combat Parser

## Intent

Combat blocks (`[COMBAT]`..`[/COMBAT]`) are written but never parsed into
structured data. The cache ignores them, the addon only inserts, and
`round.lua` duplicates `is_dead()` and roster logic inline. A formal parser
unlocks Dead Roster Detection, Round Markers, and Combat Tracker without
further duplication.

## Scope

### In Scope

1. Production parser at `lua/lonelog/parsers/combat.lua` — extracts blocks,
   rounds, combatants (PC/foe), roster lines, dead status
2. Wire `combat` field into `cache.get(bufnr).combat` — array of parsed combat
   blocks per buffer
3. Delta to `parsed-elements-cache` spec for the new field
4. Remove `is_dead` duplication — consolidate into the new parser module
5. Migrate `tests/helpers/combat.lua` tests to `tests/test_parsers_combat.lua`
   against the production path
6. Watch: `round.lua` continues using its inline `is_dead` — consolidation is
   not in scope (see below)

### Out of Scope

- Dead Roster Detection, Round Markers, Combat Tracker UI — these are
  **consumers** that get unlocked, not delivered here
- Consolidating `round.lua`'s inline `is_dead` — it is called from addon keymap
  hot paths under `startinsert!`; changing its require path now adds risk
- Syntax highlighting for combat tags in `after/syntax/`

## Capabilities

### New Capabilities

- `combat-parser`: Parse `[COMBAT]`..`[/COMBAT]` blocks into structured
  combat data: boundaries, rounds, combatants, death status. Exposed as
  `cache.get(bufnr).combat`.

### Modified Capabilities

- `parsed-elements-cache`: Add `combat` field to cache output. Requirements
  delta: data table SHALL contain a `combat` key whose value is the array
  returned by `parsers.combat.parse_blocks(bufnr)`.

## Approach

1. **New module** at `lua/lonelog/parsers/combat.lua` — mirrors
   `tests/helpers/combat.lua` + `parse_combat_blocks` already tested there.
   Same `{start_line, end_line, current_round, is_closed, combatants[],
   rounds[]}` shape. Exports `parse_blocks(bufnr?)`.
2. **Wire into cache**: `cache/init.lua:refresh()` calls
   `require("lonelog.parsers.combat").parse_blocks(bufnr)` and assigns to
   `data.combat`. Added to `M.refresh()` and `M.get()` return.
3. **Tests**: Copy `test_combat_parser.lua` — update require to production
   path. Keep the existing test as-is; add a new test file.
4. **Estimated**: ~210 lines parser, ~15 lines cache delta, ~170 lines test.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lua/lonelog/parsers/combat.lua` | New | Production combat parser |
| `lua/lonelog/cache/init.lua` | Modified | Add `combat` field to refresh/get return |
| `tests/test_parsers_combat.lua` | New | Migrated from tests/helpers |
| `openspec/specs/parsed-elements-cache/spec.md` | Modified | Delta spec for `combat` field |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Shape mismatch between test helper and prod needs | Low | Prod parser mirrors test helper API verified by 10 existing tests |
| Cache perf regression from full-buffer combat scan | Low | Combat scan is a single pass on refresh; same pattern as tags/scenes |
| `round.lua` roster logic diverging from parser | Med | No consolidation now; accept duplication, dedupe in a follow-up specifically scoped to round.lua refactor |

## Rollback Plan

Revert the two file changes: delete `parsers/combat.lua`, revert
`cache/init.lua` to remove the `combat` require and field assignment. Tests
remain but are harmless (require orphans with no prod callers).

## Dependencies

- Neovim `vim.api.nvim_buf_get_lines` (already used by cache)

## Success Criteria

- [ ] `lua tests/test_parsers_combat.lua` — all 10+ existing combat parser
      scenarios pass against production path
- [ ] `cache.get(bufnr).combat` returns the expected block array for a buffer
      with `[COMBAT]` blocks, and `nil`/`{}` for buffers without
- [ ] All 22+ existing tests still pass (no regressions)
- [ ] `is_dead` lives in exactly one production module
