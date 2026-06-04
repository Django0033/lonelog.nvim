# Proposal: Parsed Elements Cache

## Intent

Eliminate redundant buffer re-parsing every time a picker (tags, scenes),
navigation (scene prev/next), or session summary is triggered. The cache
prototype at `tests/helpers/cache.lua` already works — this change promotes
it to production and wires consumers to use it.

## Scope

### In Scope
- Production cache module at `lua/lonelog/cache/init.lua`
- All 11 tag types: N, L, PC, THREAD, F, E, CLOCK, TRACK, TIMER, INV, WEALTH, R
- Entity aggregation with line tracking, mention counting, tag collection
- Progress normalization (CLOCK/TRACK/TIMER → current/max, CLOCK→E)
- Scenes and sessions passthrough from their existing parsers
- Per-buffer changedtick invalidation (same pattern as completion.lua)
- Consumer conversion: pickers, navigation, summary route through cache
- Migrate existing test for production module path

### Out of Scope
- Cross-buffer dependency tracking
- LRU eviction or persistent cache (Neovim sessions have ~1-5 buffers)
- Cache warming on BufRead/BufWrite
- Table parser (tables.lua) caching — separate parser, different concern

## Capabilities

> No existing specs in `openspec/specs/` — this is the first capability spec for the project.

### New Capabilities
- `parsed-elements-cache`: Central cache with get/refresh/invalidate for all
  parsed lonelog elements, keyed by buffer with changedtick validation

### Modified Capabilities
- None (first capability spec for this project)

## Approach

Single module exposing three functions:

- `M.get(bufnr)` → returns cached data or auto-refresh on changedtick mismatch
- `M.refresh(bufnr)` → force full re-parse from 3 parsers, rebuild entity groups
- `M.invalidate(bufnr)` → clear buffer cache entry

Cache key: `cache[bufnr] = { changedtick, data }` — exact pattern from completion.lua.

Entity types (N, L, PC, THREAD, F, INV, WEALTH, R) get deduplicated by name
into sorted arrays. Each entry tracks lines seen, first/last occurrence, tags,
and mention count.

Progress types (E, CLOCK, TRACK, TIMER) get normalized with current/max.
CLOCK is mapped to type "E" for API consistency.

Scenes and sessions pass through unchanged from their parsers.

Consumer conversion: each caller replaces `parser.parse_*(bufnr)` with
`cache.get(bufnr).{key}`.

## Output Structure

```lua
{
  npcs = { { name, tags, lines[], first_seen, last_seen, mention_count }, ... },
  locations = { ... },
  pcs = { ... },
  threads = { ... },
  foes = { ... },
  inventory = { ... },
  wealth = { ... },
  rooms = { ... },
  progress = { { type, name, current, max, line }, ... },
  scenes = {},   -- passthrough from scenes parser
  sessions = {}, -- passthrough from sessions parser
}
```

## Consumers

| Consumer | Current | After |
|---|---|---|
| `parsers/tags.lua` — picker/browser | `parse_tags(bufnr)` | `cache.get().npcs/locations/...` |
| `parsers/scenes.lua` — navigate/picker | `parse_scenes(bufnr)` | `cache.get().scenes` |
| `commands/summary/init.lua` | calls all 3 parsers | `cache.get()` |
| `completion.lua` | own inline cache | unchanged (optional merge later) |

## Affected Areas

| Area | Impact | Est. Lines |
|---|---|---|
| `lua/lonelog/cache/init.lua` | New | 80-100 |
| `tests/test_cache.lua` | Modified | update require path |
| `tests/helpers/cache.lua` | Removed | archive prototype |
| 4 consumer sites in 3 modules | Modified | ~2-3 lines each |

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Stale cache on external buffer edits | Low | Changedtick is Neovim-native; same as completion.lua |
| Changedtick integer wrap at 2^32 | Low | Same pattern already in production use |
| Cache growth on many buffers | Low | Neovim has ~1-5; easy BufDelete handler if needed |

## Rollback Plan

Revert consumer call sites to direct parser API calls. Delete
`lua/lonelog/cache/`. Restore `tests/helpers/cache.lua` from git. No schema,
migrations, or side effects — pure code reorganization.

## Dependencies

- `parsers/tags.parse_tags(bufnr)`
- `parsers/scenes.parse_scenes(bufnr)`
- `commands/summary.parse_all_sessions(bufnr)`

## Success Criteria

- [ ] `cache.get()` returns same data shape as current prototype
- [ ] Changedtick hit returns same table reference (no re-parse)
- [ ] Changedtick miss triggers full re-parse
- [ ] All 11 tag types aggregated into correct entity groups
- [ ] Existing test_cache.lua passes against production module
- [ ] No performance regression on picker/navigation/summary triggers
