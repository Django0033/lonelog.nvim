# ParsedElements Cache

**Date:** 2026-06-01
**Requires:** `parsers/tags.lua`, `parsers/scenes.lua`, `commands/summary.lua`

## Objective

Unified cache that aggregates all parsed entities (NPCs, locations, threads,
PCs, foes, progress, scenes, sessions) with mention tracking. Serves as
infrastructure for future features (dashboard, navigation, richer autocomplete).

## Location

New file: `lua/lonelog/parsers/cache.lua`

## Design: Orchestrator pattern

Reuses existing parsers and adds aggregation + caching layer:

1. Call `tags.parse_tags()` for all entity tags
2. Call `scenes.parse_scenes()` for scene markers
3. Call `summary.parse_all_sessions()` for session headers
4. Aggregate entities by type with mention tracking
5. Extract progress elements with current/max values
6. Cache result keyed by buffer `changedtick`

### Output structure

```lua
{
  npcs = {      -- [N:] tags
    { name = "Jonah", tags = {"friendly"}, lines = {12, 45}, first_seen = 12, last_seen = 45, mention_count = 2 },
  },
  locations = { ... },   -- [L:] tags
  threads = { ... },     -- [Thread:] tags
  pcs = { ... },         -- [PC:] tags
  foes = { ... },        -- [F:] tags
  progress = {           -- [E:], [Clock:], [Track:], [Timer:]
    { type = "E", name = "Alert", current = 2, max = 6, line = 30 },
  },
  scenes = { ... },      -- from scenes.parse_scenes()
  sessions = { ... },    -- from summary.parse_all_sessions()
}
```

### Public API

```lua
M.get(bufnr)      -- Returns cached data, refreshes if changed
M.refresh(bufnr)  -- Force refresh
M.invalidate(bufnr) -- Clear cache
```

### Mention tracking

Each tag entity (N, L, PC, THREAD, F) collects every line number where it
appears across the buffer. The parsed tags already include a `line` field;
multiple occurrences of the same entity name across different lines are grouped.

### Progress extraction

Tags with types E, CLOCK, TRACK, TIMER carry progress info. The tag parser
already extracts name + progress string (e.g. "2/6"). The cache parses this
into structured `{current, max}` fields.

### Caching strategy

Same pattern as `completion.lua`: store `{changedtick, data}` per buffer.
`get()` compares current `changedtick` with cached entry; if unchanged,
returns cached data. `refresh()` always re-scans.

## Testing

~6 tests:
- Buffer with NPC + Location → correct groups and mention counts
- Thread with multiple mentions → mention_count > 1
- Progress element → current/max parsed
- Cache hit → no re-scan if changedtick unchanged
- Invalidate → forces re-scan
- Empty buffer → empty structure
