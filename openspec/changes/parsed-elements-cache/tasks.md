# Tasks: Parsed Elements Cache

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~240 (±20) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending |

```
Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: Low
```

## Phase 1: Core Module

- [ ] 1.1 Create `lua/lonelog/cache/init.lua` (~90 lines) with `get()`, `refresh()`, `invalidate()` exposing `ParsedData` (npcs, locations, pcs, threads, foes, inventory, wealth, rooms, progress, tags, scenes, sessions). ENTITY_TYPES: N, L, PC, THREAD, F, INV, WEALTH, R. PROGRESS_TYPES: E, CLOCK, TRACK, TIMER (CLOCK→E remap). Changedtick per-buffer invalidation matching `completion.lua` pattern. Sort entities by lowercase name.
- [ ] 1.2 Add `tags` (raw `parse_tags()` array) passthrough to cache output alongside aggregated entities. Required by tags picker consumer.

## Phase 2: Testing

- [x] 2.1 Migrate `tests/test_cache.lua`: change `require("tests.helpers.cache")` → `require("lonelog.cache")`, update `package.path` to remove `tests/helpers/` dependency. All existing 12 tests must pass unchanged.
- [x] 2.2 Expand tests: add INV aggregation test (e.g., `[INV:Gold|10 coins]`), WEALTH test (`[WEALTH:Wealth|15g]`), Room test (`[R:Tavern|cozy]`), raw `tags` passthrough test, cache isolation test (two mock buffers with independent data).

## Phase 3: Consumer Integration

- [x] 3.1 Wire `lua/lonelog/parsers/tags.lua`: `show_tags_picker()` replaces `M.parse_tags(bufnr)` with `require("lonelog.cache").get(bufnr).tags`. Kept `tags_summary()` argument-based — no change needed.
- [x] 3.2 Wire `lua/lonelog/parsers/scenes.lua`: `show_scenes_picker()` and `navigate_scene()` replace `M.parse_scenes(bufnr)` with `require("lonelog.cache").get(bufnr).scenes`. Inline `require` in both functions (equivalent to single top require since Lua caches `require`).
- [x] 3.3 Wire `lua/lonelog/commands/summary/init.lua`: `get_current_buffer_data()` replaces 3 parser calls with single `require("lonelog.cache").get()`. Added `cached_progress` param to `build_session_summary()` with `progress_from_cache()` converter. `parse_all_sessions()` left as direct call — cheap header scan, not a performance concern.

## Phase 4: Cleanup

- [x] 4.1 Delete `tests/helpers/cache.lua` — prototype replaced by production module. Verified no remaining references.

## Dependencies

```
Phase 1 ──→ Phase 2 ──→ Phase 4
    │
    └──→ Phase 3
```

Phase 1 has no upstream dependency. Phases 2 and 3 both depend on Phase 1 (module must exist). Phase 4 depends on Phase 2 (tests must pass before deleting old code). Phases 2 and 3 can be done in parallel.

## Risks

- `summary/init.lua` `parse_all_sessions()` is a method on `M` — the cache must require the full module, creating a circular reference risk. Mitigation: cache requires summary module during `refresh()` only (lazy require, same as prototype). Verify no cycle before merge.
- Test mock `nvim_buf_get_changedtick` returns constant `5` — cache isolation test needs mock to return different ticks per buffer. Mitigation: store per-buffer tick in a mock table.

## Artifact Paths

| File | Action |
|------|--------|
| `lua/lonelog/cache/init.lua` | Create |
| `tests/test_cache.lua` | Modify |
| `tests/helpers/cache.lua` | Delete |
| `lua/lonelog/parsers/tags.lua` | Modify |
| `lua/lonelog/parsers/scenes.lua` | Modify |
| `lua/lonelog/commands/summary/init.lua` | Modify |

## Skill Resolution

paths-injected: 3 skills (`sdd-tasks`, `_shared/sdd-phase-common`, `_shared/persistence-contract`)
