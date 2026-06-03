# Apply Progress: Parsed Elements Cache — Phase 1 + Phase 2 + Phase 3

**Status**: Complete
**Mode**: Strict TDD (RED → GREEN → verified)

## Phase 1 Completed Tasks

### 1.1 Create `lua/lonelog/cache/init.lua` with get/refresh/invalidate

**API Surface:**
- `M.get(bufnr?)` — returns cached data, refreshes on changedtick mismatch
- `M.refresh(bufnr?)` — force full re-parse
- `M.invalidate(bufnr?)` — clear buffer cache entry
- All default to current buffer when bufnr omitted

**Entity Aggregation (8 types):**
- N → `npcs[]`, L → `locations[]`, PC → `pcs[]`, THREAD → `threads[]`
- F → `foes[]`, INV → `inventory[]`, WEALTH → `wealth[]`, R → `rooms[]`
- Each entity: `{ name, tags, lines[], first_seen, last_seen, mention_count }`
- Tags captured from first occurrence (definition site), not overwritten on re-mention

**Progress Normalization:**
- E, CLOCK, TRACK, TIMER → `progress[]`
- CLOCK → type "E" (remapped)
- Format: `{ type, name, current, max, line }`
- "N/M" → current=N, max=M; "N" → current=N, max=nil

**Passthrough:**
- `tags` — raw `parse_tags()` array (identity pass)
- `scenes` — `parse_scenes()` output (identity pass)
- `sessions` — `parse_all_sessions()` output (identity pass)

**Caching:**
- Pattern: `cache[bufnr] = { changedtick, data }` (same as completion.lua)
- `get()`: compare current changedtick with cached; hit = return cached, miss = refresh

**Sorting:**
- Entity arrays sorted by name (case-insensitive via `name:lower()`)

## Phase 2 Completed Tasks

### 2.1 Migrate `tests/test_cache.lua` to use production module

- Changed `require("tests.helpers.cache")` → `require("lonelog.cache")`
- Updated `package.path` to include `./lua/?/init.lua` for directory module resolution
- Removed `./tests/helpers/?.lua` from `package.path` (no longer needed)
- Switched from simple constant-changedtick mock to per-buffer mock data table supporting three isolated buffers
- Consolidated `test_cache_module.lua` content into `tests/test_cache.lua` (single comprehensive test file)

### 2.2 Expanded test coverage

- **INV entity aggregation**: Ancient Key (first_seen: 12), Rusty Sword (first_seen: 25)
- **WEALTH entity aggregation**: Gold Coins (first_seen: 13), Silver Ring (first_seen: 26)
- **R (room) entity aggregation**: Throne Room (first_seen: 14), Dungeon Cell (first_seen: 27)
- **TRACK progress type**: Journey 3/10 with type "TRACK"
- **Cache isolation**: buf 1 (Elara/Marcus) and buf 2 (Zara) verified independent via explicit bufnr parameter, with cached reference identity preserved per buffer
- **Cache invalidation on changedtick miss**: changedtick change from 5→6 confirmed to produce a new data reference
- **Empty buffer**: buf 3 (empty lines) confirmed returns table with all fields as empty arrays (0 count), not nil
- **Raw tags passthrough**: verified raw tag count >= 19, Elara tag type=N line=6

### 4.1 Delete old helper (early)

- Deleted `tests/helpers/cache.lua` — no remaining references in any source/test file
- Deleted `tests/test_cache_module.lua` — consolidated into `tests/test_cache.lua`

## Phase 3 Completed Tasks

### 3.1 Wire `parsers/tags.lua` — `show_tags_picker()`

- **Location**: `show_tags_picker()` line 198
- **Change**: `M.parse_tags(bufnr)` → `require("lonelog.cache").get(bufnr).tags`
- **Why**: Uses cache passthrough (`.tags` = raw `parse_tags()` output) instead of direct parser call
- **Preserved**: Telescope type-filter picker, browser fallback, tag display formatting — all identical

### 3.2 Wire `parsers/scenes.lua` — `show_scenes_picker()` + `navigate_scene()`

- **Location**: `show_scenes_picker()` line 217 and `navigate_scene()` line 310
- **Change**: `M.parse_scenes(bufnr)` → `require("lonelog.cache").get(bufnr).scenes` (both sites)
- **Why**: Uses cache passthrough (`.scenes` = raw `parse_scenes()` output)
- **Test adaptation**: Added `nvim_buf_get_changedtick` mock to `test_scenes.lua` and `;./lua/?/init.lua` to `package.path` so cache module resolves in test environment

### 3.3 Wire `commands/summary/init.lua` — 3 call sites

**Site 1 — tags**: `get_current_buffer_data()` now uses `cache.get().tags` instead of direct `parse_tags()` call
**Site 2 — scenes**: `get_current_buffer_data()` now uses `cache.get().scenes` instead of direct `parse_scenes()` call
**Site 3 — progress**: Added `cached_progress` optional parameter to `build_session_summary()`. When provided (from `cache.get().progress`), uses `progress_from_cache()` helper to convert cached progress items to summary format. Falls back to `build_progress_summary(slines)` when nil (backward-compatible with existing tests).

### 3.4 Test infrastructure

- Added `;./lua/?/init.lua` to `test_scenes.lua` `package.path` — required for `require("lonelog.cache")` to resolve the directory module at `lua/lonelog/cache/init.lua`
- Added `nvim_buf_get_changedtick` mock (returns 0) to `test_scenes.lua` — required for `cache.get()` call in `navigate_scene()`

## Files Changed

| File | Action | Notes |
|------|--------|-------|
| `lua/lonelog/cache/init.lua` | Create (Phase 1) | 186 lines |
| `tests/test_cache.lua` | Rewrite (Phase 2) | Comprehensive: 111 assertions, 3-buffer mock |
| `tests/test_cache_module.lua` | Delete (Phase 2) | Consolidated into test_cache.lua |
| `tests/helpers/cache.lua` | Delete (Phase 2) | No longer referenced |
| `lua/lonelog/parsers/tags.lua` | Modify (Phase 3) | 1 line: `M.parse_tags()` → `cache.get().tags` |
| `lua/lonelog/parsers/scenes.lua` | Modify (Phase 3) | 2 lines: `M.parse_scenes()` → `cache.get().scenes` |
| `lua/lonelog/commands/summary/init.lua` | Modify (Phase 3) | `get_current_buffer_data()` uses cache; added `progress_from_cache()` + `cached_progress` param |
| `tests/test_scenes.lua` | Modify (Phase 3) | Added `nvim_buf_get_changedtick` mock + `;./lua/?/init.lua` to package.path |
| `openspec/changes/parsed-elements-cache/tasks.md` | Update | Mark Phase 3 as complete |

## Deviations from Design

None. Implementation matches design.md spec and tasks.md exactly.

## Issues Found

- **`test_scenes.lua` module resolution**: The cache module at `lua/lonelog/cache/init.lua` requires `;./lua/?/init.lua` in `package.path` — `test_scenes.lua` was missing this, causing `require("lonelog.cache")` to fail when `navigate_scene()` was called. Fixed by adding the path.
- **`nvim_buf_get_changedtick` mock**: `cache.get()` calls `vim.api.nvim_buf_get_changedtick()` on every access — missing in `test_scenes.lua` mock. Fixed by adding mock returning 0.

## TDD Cycle Evidence

### Phase 2 TDD Cycles

| Step | Evidence | Result |
|------|----------|--------|
| **RED** | `tests/test_cache.lua` with `require("lonelog.cache")` before module existed | FAIL (expected in Phase 1) |
| **GREEN** | Phase 1: `lua tests/test_cache_module.lua` — all 89 tests pass | PASS |
| **GREEN** | Phase 2: `lua tests/test_cache.lua` — all 111 tests pass | PASS |
| **REGRESSION** | All 22 `tests/test_*.lua` suites run consecutively | 0 failures across all suites |

### Phase 3 TDD Cycles

| Step | Evidence | Result |
|------|----------|--------|
| **GREEN** | Baseline: `test_tags.lua` (22), `test_scenes.lua` (14), `test_summary.lua` (24), `test_cache.lua` (111) | All PASS |
| **GREEN** | After wiring: `test_tags.lua` (22), `test_scenes.lua` (14), `test_summary.lua` (24), `test_cache.lua` (111) | All PASS |
| **GREEN** | `test_scenes.lua` — initial failure (missing `nvim_buf_get_changedtick` + `package.path` fix) → re-run | 14/14 PASS after fix |
| **REGRESSION** | All 22 `tests/test_*.lua` suites run consecutively | 22/22 PASS, 0 failures |

### Cumulative Test Assertions

| File | Assertions | Status |
|------|-----------|--------|
| `tests/test_cache.lua` | 111 | All PASS |
| `tests/test_tags.lua` | 22 | All PASS |
| `tests/test_scenes.lua` | 14 | All PASS |
| `tests/test_summary.lua` | 24 | All PASS |
| All other 18 test suites | ~480 | All PASS |

## Remaining Tasks

Phase 3 is the final consumer-wiring phase. No remaining tasks.
