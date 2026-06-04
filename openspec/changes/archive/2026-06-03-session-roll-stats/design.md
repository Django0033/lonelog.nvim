# Design: Session Roll Statistics

## Technical Approach

Per-buffer roll history tables (`dice.roll_history`, `oracle.roll_history`) collect raw result objects at each roll call. A new `rolls` field in the cache aggregates history entries with parsed `d:` buffer lines, deduplicating by line number. The summary builder uses this unified list to produce dice-type breakdowns and oracle-result distributions, rendered as new sections in the summary floating window and markdown export.

## Architecture Decisions

### D1: History keyed by bufnr (not filename)

| Option | Tradeoff | Decision |
|--------|----------|----------|
| **bufnr** | Survives buffer reuse; consistent with `cache[bufnr]` pattern | ✅ Chosen |
| filename | Survives buffer close/reopen; requires path-relative lookup | ❌ Rejected — inconsistent with existing cache pattern |

### D2: History entries store raw `M.roll()` return values

| Option | Tradeoff | Decision |
|--------|----------|----------|
| **Raw result** | Includes all parsed data (count, sides, rolls, total, display) — future-proof | ✅ Chosen |
| Minimal subset | Saves memory; loses detail needed for type breakdown | ❌ Rejected — type breakdown needs `sides`, oracle distribution needs `value` |

### D3: Roll entries augmented with `line` and `bufnr` at capture

Each history item gets `line` (cursor line at roll time) and `bufnr` appended by `init.lua`'s capture step before appending to history. This enables session-range filtering and deduplication with `d:` buffer lines.

### D4: Cache aggregation unions + deduplicates by line number

| Source | Line number | Dedup behavior |
|--------|-------------|----------------|
| `dice_history[bufnr]` | Captured at roll time | If same line exists in `d:` line parse → dedup (use parsed version for richer data) |
| `oracle_history[bufnr]` | Captured at roll time | No `o:` buffer format → no dedup |
| `d:` buffer lines (parsed) | From buffer | Lines matching a history entry are discarded during union |

### D5: Oracle—history only

No `o:` notation format exists in the buffer. All oracle results flow through history alone.

### D6: Session filtering by line range

Rolls with `line` in `[session.start_line, session.end_line)` are attributed to that session. Rolls without a valid line (nil/0) are excluded from session summaries (a possible future enhancement could assign them to the current session heuristically).

## Data Flow

```
init.lua: M.roll_dice("2d6+3")
  │
  ├── dice.roll("2d6+3") → result
  │
  └── capture: dice.append_history(bufnr, line, result)
       │
       └── dice_history[bufnr] = dice_history[bufnr] or {}
           dice_history[bufnr][#+1] = { line, bufnr, result }

cache.refresh(bufnr)
  │
  ├── parse buffer d: lines → dice_line_entries[]  (via existing parse_dice_line)
  │
  ├── read dice_history[bufnr] → history_dice[]
  │
  ├── read oracle_history[bufnr] → history_oracle[]
  │
  └── aggregate():
        1. Start with dice_line_entries[] (has line, notation, rolls, total)
        2. Add history_dice[] entries whose line NOT in dice_line_entries (no buffer match)
        3. Add all history_oracle[] entries
        → data.rolls = { {type, line, source, result}, ... }

build_session_summary(session, lines, tags, scenes, progress, rolls)
  │
  ├── filter rolls: rolls where roll.line in [session.start_line, session.end_line)
  │
  ├── dice_by_type(rolls):
  │     group by sides, compute count, sum, average per type
  │
  └── oracle_distribution(rolls):
        group by result.value, count per value

format_summary(summary)
  └── render "Dice by Type" table and "Oracle Results" section
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lua/lonelog/dice.lua` | Modify | Add `roll_history`, `append_history()`, `get_history()`, `clear_history()` |
| `lua/lonelog/oracle.lua` | Modify | Add `oracle_history`, `append_history()`, `get_history()` |
| `lua/lonelog/init.lua` | Modify | Capture bufnr+line+result to both histories before float UI |
| `lua/lonelog/cache/init.lua` | Modify | `refresh()` aggregates history + `d:` lines into `data.rolls` |
| `lua/lonelog/commands/summary/init.lua` | Modify | `build_session_summary()` filters `rolls` by session, computes breakdowns; accept `rolls` param |
| `lua/lonelog/commands/summary/format.lua` | Modify | Add "Dice by Type" table and "Oracle Distribution" section to both `format_summary` and `export_summary` |

## Interfaces / Contracts

### History entry (both dice and oracle)

```lua
{
  line = 42,          -- buffer line number (1-indexed), captured at roll time
  bufnr = 1,          -- buffer where roll was triggered
  result = { ... },   -- full M.roll() return value (includes .sides, .total, etc. for dice;
                      -- or .table, .value, .display for oracle)
}
```

### Cache data.rolls entry

```lua
{
  type = "dice",      -- "dice" | "oracle"
  line = 42,          -- buffer line; nil for no matching buffer line
  source = "history", -- "history" | "buffer"
  notation = "2d6+3", -- dice notation string, or oracle table name
  result = { ... },   -- rolled result object
}
```

### Summary additions

```lua
summary.roll_stats = {
  dice = {
    { type = "d6", count = 3, sum = 27, avg = 9.0 },
    { type = "d20", count = 2, sum = 28, avg = 14.0 },
  },
  oracle = {
    { value = "yes", display = "Yes", count = 4 },
    { value = "no", display = "No", count = 2 },
  },
}
```

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | `dice.append_history` / `get_history` | Standalone test (`test_dice_history.lua`): mock `roll_history`, verify append+retrieve+clear |
| Unit | `oracle.append_history` / `get_history` | Standalone test (`test_oracle.lua`): same pattern |
| Unit | Cache `refresh()` roll aggregation | Extend `test_cache.lua`: seed `dice_history` table mock, verify `data.rolls` contains combined history + `d:` line entries with dedup |
| Integration | `build_session_summary` with rolls | Extend `test_summary.lua`: pass mock `rolls` array, verify filtered breakdown by dice type and oracle distribution |
| Integration | `format_summary` new sections | Extend `test_summary.lua`: format lines contain "Dice by Type" and oracle distribution text |
| Integration | `export_summary` new sections | Verify markdown output includes oracle distribution table |
| Integration | init.lua capture flow | Test that `M.roll_dice` captures to history before UI call |

All tests follow the existing standalone Lua pattern with `_G.vim` mocks. New test entries seed `dice_history` / `oracle_history` tables (or mock the append function) to verify aggregation without requiring actual roll execution.

## Migration / Rollout

No migration required. History starts empty on first load, grows per session, and is naturally garbage-collected when Neovim exits. The `rolls` field defaults to `{}` in cache data for buffers where no rolls exist.

New OpenSpec test files:
- `tests/test_dice_history.lua` — dice history append/get/clear
- No separate oracle history file needed; extend `test_oracle.lua`

Existing test files to extend:
- `tests/test_cache.lua` — roll aggregation + dedup
- `tests/test_summary.lua` — session-filtered breakdowns + format sections
