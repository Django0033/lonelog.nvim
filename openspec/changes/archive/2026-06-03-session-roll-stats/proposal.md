# Proposal: Session Roll Statistics

## Intent

Summary window shows notation counts (`d:` lines in buffer) but has no breakdown of what dice were rolled, their totals, or oracle outcomes. Users see "5 dice rolls" but not "3x d20, 2x d6, average 12.4". Oracle results (100% ephemeral) are invisible to summary entirely.

## Scope

### In Scope
- Per-buffer in-memory roll history in `dice.lua` and `oracle.lua`
- Capture roll/oracle results at call site in `init.lua` (before float window)
- `rolls` field in `cache/init.lua` aggregating history + buffer `d:` lines
- Summary dice breakdown by type (not just count), oracle distribution
- New display sections in `format.lua` for roll stats and oracle results

### Out of Scope
- Persistent cross-session stats (history is per-Neovim-session only)
- Oracle buffer line persistence (no `o:` format exists)
- Roll history UI picker or navigation (summary-only)
- Real-time roll feed or notification changes

## Capabilities

### New Capabilities
- `roll-statistics`: Per-session dice and oracle statistics — breakdown by dice type, average, sum, totals per type; oracle result distribution (yes/no/but/maybe/etc.).

### Modified Capabilities
- `parsed-elements-cache`: Adding `rolls` field (aggregated from in-memory history + buffer `d:` lines) to the cached data shape returned by `get()`/`refresh()`.

## Approach

History buffer pattern — per-buffer `roll_history[bufnr]` table in each module with `get_history(bufnr)` and `clear_history(bufnr)`. `M.roll()` and `M.roll()` append to history before returning. `init.lua` capture step is the hook point (already calls the roll, adds capture line before UI). Cache `refresh()` aggregates both history entries and buffer `d:` lines into a unified `rolls` field. Summary `build_session_summary()` reads the field; `format_summary()` renders new sections.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lua/lonelog/dice.lua` | Modified | Add `roll_history`, `get_history()`, `clear_history()`. Append in `M.roll()`. |
| `lua/lonelog/oracle.lua` | Modified | Add `oracle_history`, `get_history()`. Append in `M.roll()`. |
| `lua/lonelog/init.lua` | Modified | Capture roll/oracle result to history before showing float window. |
| `lua/lonelog/cache/init.lua` | Modified | Aggregate history + `d:` lines into `rolls` field during `refresh()`. |
| `lua/lonelog/commands/summary/init.lua` | Modified | Extend `build_session_summary()` with dice breakdown by type, oracle distribution. |
| `lua/lonelog/commands/summary/format.lua` | Modified | New display sections for both dice breakdown and oracle distribution. |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| History lost on Neovim restart | High | Acceptable — stats are per-session by definition |
| Buffer `d:` lines from before this change not reflected | High | Starts collecting from install; no migration needed |
| History grows unbounded in long sessions | Low | Keep per-buffer, clear per-session — session boundary is natural GC |

## Rollback Plan

Remove history tables from `dice.lua` and `oracle.lua`, revert capture lines in `init.lua`, revert `rolls` field addition in `cache/init.lua`, revert summary builder and formatter changes. No data migration needed.

## Dependencies

- Parsed Elements Cache (`cache/init.lua`) — must exist for summary integration
- Existing summary module (`commands/summary/init.lua`, `format.lua`) — extension target

## Success Criteria

- [ ] `dice.roll()` appends to per-buffer history; `get_history(bufnr)` returns entries
- [ ] `oracle.roll()` appends to oracle history; `get_history()` returns entries
- [ ] `init.lua` captures roll/oracle result to history before float window
- [ ] `cache.refresh()` returns `rolls` field with aggregates from history + `d:` lines
- [ ] Summary window shows dice breakdown by type (e.g., "d20: 3 rolls, avg 12.4") and oracle distribution (e.g., "Yes: 2, No: 1, Maybe: 3")
- [ ] All existing dice/oracle/cache/summary tests still pass
