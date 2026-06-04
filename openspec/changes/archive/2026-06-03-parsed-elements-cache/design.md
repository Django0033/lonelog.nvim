# Design: Parsed Elements Cache

## Technical Approach

Promote the working prototype at `tests/helpers/cache.lua` to a production module at `lua/lonelog/cache/init.lua` with an expanded entity set (add INV, WEALTH, R aggregation), raw tag passthrough for picker consumers, and changedtick-based invalidation matching the established pattern in `completion.lua`. All four consumer sites route through the cache instead of direct parser calls.

## Architecture Decisions

### Decision: Single flat cache module
**Choice**: One file at `lua/lonelog/cache/init.lua`, no sub-modules.
**Alternative**: Split entity aggregation vs. passthrough into separate files.
**Rationale**: ~100 lines total, full cohesion (get/refresh/invalidate are tightly coupled). Splitting would add require overhead for no benefit.

### Decision: Raw tags array stored alongside aggregated entities
**Choice**: Cache output includes `tags` (raw `parse_tags()` array) *plus* aggregated entity groups (`npcs`, `locations`, etc.).
**Alternative**: Consumers re-parse for picker views, using cache only for entity-specific lookups.
**Rationale**: The tags picker (`show_tags_picker`) needs ALL tag types including progress (E, CLOCK, TRACK, TIMER), not just aggregated entities. Storing raw tags avoids a second parse.

### Decision: First-occurrence tags are canonical for entities
**Choice**: When aggregating entity entries (N, L, PC, THREAD, F, INV, WEALTH, R), the `tags` field is captured from the first mention only. Subsequent mentions update `lines[]`, `last_seen`, and `mention_count` but do NOT override tags.
**Alternative**: Union tags across all mentions, or overwrite with latest.
**Rationale**: The first occurrence is the definition site — later mentions are just references. This matches the existing prototype behavior and user expectations for note-taking.

### Decision: INV, WEALTH, R aggregated as entities (new vs protoype)
**Choice**: Include INV/WEALTH/R in the entity aggregation set, producing `inventory`, `wealth`, `rooms` arrays.
**Alternative**: Keep as passthrough raw tags only.
**Rationale**: These tag types follow the same name+tags pattern as N/L/PC/THREAD/F. Aggregation gives consumers mention tracking and sorted browsing for free.

### Decision: Completion.lua NOT migrated
**Choice**: `completion.lua` keeps its own inline cache.
**Alternative**: Route through the shared cache.
**Rationale**: Completion needs a different data structure (name→tags lookup table, not entity entries). Merging would require cache to serve two schemas, increasing coupling. This is deferred as a future optional optimization.

## Data Flow

```
User triggers picker/navigation/summary
         │
         ▼
cache.get(bufnr)
         │
    ┌────┴────┐
    │         │
  tick match  tick miss
    │         │
    │    cache.refresh(bufnr)
    │         │
    │    ┌────┴────┐
    │    │         │
    │  parse_tags parse_scenes + parse_all_sessions
    │    │         │
    │    ├─ entities (N,L,PC,THREAD,F,INV,WEALTH,R)
    │    ├─ progress (E,CLOCK→E,TRACK,TIMER)
    │    └─ raw tags[]
    │    │
    └────┘
    return cached.data
         │
         ▼
   Consumer uses .npcs / .tags / .scenes / .sessions
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lua/lonelog/cache/init.lua` | Create | Production cache: get/refresh/invalidate |
| `tests/helpers/cache.lua` | Delete | Prototype replaced by production module |
| `tests/test_cache.lua` | Modify | Update require path to production module |
| `lua/lonelog/parsers/tags.lua` | Modify | `show_tags_picker` routes through cache |
| `lua/lonelog/parsers/scenes.lua` | Modify | `show_scenes_picker` + `navigate_scene` route through cache |
| `lua/lonelog/commands/summary/init.lua` | Modify | `get_current_buffer_data` + session parse route through cache |

## Interfaces / Contracts

```lua
---@class CacheEntry
---@field changedtick number
---@field data ParsedData

---@class ParsedData
---@field tags table[]   raw tags (passthrough from parse_tags)
---@field npcs table[]   entity entries sorted by name
---@field locations table[]
---@field pcs table[]
---@field threads table[]
---@field foes table[]
---@field inventory table[]
---@field wealth table[]
---@field rooms table[]
---@field progress table[]  normalized progress entries
---@field scenes table[]    passthrough from scenes parser
---@field sessions table[]  passthrough from sessions parser

---@class EntityEntry
---@field name string
---@field tags string[]   first-occurrence tags
---@field lines number[]  all occurrence line numbers
---@field first_seen number
---@field last_seen number
---@field mention_count number

---@class ProgressEntry
---@field type "E"|"TRACK"|"TIMER"
---@field name string
---@field current number|nil
---@field max number|nil
---@field line number

---Cache: get cached data, auto-refresh on changedtick miss
---@param bufnr? number
---@return ParsedData
function M.get(bufnr) end

---Cache: force re-parse and rebuild
---@param bufnr? number
---@return ParsedData
function M.refresh(bufnr) end

---Cache: clear buffer entry
---@param bufnr? number
function M.invalidate(bufnr) end
```

### Entity Type → Output Key Mapping

| Tag Type | Output Key |
|----------|-----------|
| N | `npcs` |
| L | `locations` |
| PC | `pcs` |
| THREAD | `threads` |
| F | `foes` |
| INV | `inventory` |
| WEALTH | `wealth` |
| R | `rooms` |

## Consumer Integration Plan

| Site | Current | After | Lines changed |
|------|---------|-------|---------------|
| `tags.lua:198` — `show_tags_picker` | `M.parse_tags(bufnr)` | `M.get(bufnr).tags` | +3 |
| `scenes.lua:217` — `show_scenes_picker` | `M.parse_scenes(bufnr)` | `M.get(bufnr).scenes` | +3 |
| `scenes.lua:310` — `navigate_scene` | `M.parse_scenes(bufnr)` | `M.get(bufnr).scenes` | +3 |
| `summary.lua:265-267` — `get_current_buffer_data` | 3 separate parser calls | `M.get()` one call | +4, -4 |
| `summary.lua:273` — `show_session_summary` | `M.parse_all_sessions()` | `M.get().sessions` | +3 |
| `summary.lua:313` — `export_session_summary` | `M.parse_all_sessions()` | `M.get().sessions` | +3 |

Each consumer adds a local `local cache = require("lonelog.cache")` at top of function/module.

## Testing Strategy

| Layer | What | How |
|-------|------|-----|
| Unit | Entity aggregation, progress normalization, changedtick invalidation | Migrate `tests/test_cache.lua` to `require("lonelog.cache")` |
| Unit | INV/WEALTH/R aggregation | Add test tags for new entity types |
| Integration | Consumer routes through cache | Each consumer site tested via existing test infrastructure |

The existing test suite already validates the core cache behavior. Migration is mechanical: change the require path from `tests.helpers.cache` to `lonelog.cache`, add test cases for INV/WEALTH/R.

## Migration / Rollout

No migration required. The cache is purely a query-layer optimization — no data format changes, no schema, no state to migrate. Rollback: revert consumer call sites and delete `lua/lonelog/cache/`.

## Open Questions

- None — prototype validated approach, decisions map to proven patterns.
