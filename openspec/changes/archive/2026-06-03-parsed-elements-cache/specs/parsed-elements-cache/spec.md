# Parsed Elements Cache Specification

## Purpose

Cache parsed lonelog elements per-buffer with changedtick invalidation (same pattern as completion.lua). Avoids redundant full-buffer re-parsing on every picker/navigation/summary trigger.

## Requirements

### Requirement: Module API — get/refresh/invalidate

The module MUST expose three functions: `get(bufnr?)`, `refresh(bufnr?)`, `invalidate(bufnr?)`. All three MUST default to the current buffer when `bufnr` is omitted.

#### Scenario: Default to current buffer
- GIVEN no buffer argument
- WHEN `cache.get()` is called
- THEN it MUST use `nvim_get_current_buf()` internally

#### Scenario: Buffer-scoped isolation
- GIVEN buffers 1 and 2 with different content
- WHEN both are cached
- THEN `cache.get(1)` and `cache.get(2)` MUST return independent data

### Requirement: Changedtick Invalidation

The cache entry for a buffer MUST store `{ changedtick, data }`. On `get()`, the current `nvim_buf_get_changedtick(bufnr)` MUST be compared against the stored value. Match returns the cached data (same table reference). Mismatch triggers `refresh()`.

#### Scenario: Cache hit returns same reference
- GIVEN a buffer unchanged since last refresh
- WHEN `get()` is called twice
- THEN both calls MUST return the identical table reference (zero copy)

#### Scenario: Cache miss re-parses
- GIVEN a buffer whose changedtick differs from cache
- WHEN `get()` is called
- THEN it MUST re-parse all three parsers and return fresh data

#### Scenario: Invalidate forces re-parse
- GIVEN a cached buffer entry is invalidated
- WHEN `get()` is called next
- THEN it MUST re-parse (cache entry is nil)

### Requirement: Entity Aggregation

Tags of types N, L, PC, THREAD, F, INV, WEALTH, R MUST be aggregated by name into sorted arrays. Duplicate names across lines MUST be merged into a single entry with running line tracking.

Output keys: `npcs`, `locations`, `pcs`, `threads`, `foes`, `inventory`, `wealth`, `rooms`. Each entry: `{name, tags, lines[], first_seen, last_seen, mention_count}`.

#### Scenario: NPC aggregation with dedup
- GIVEN `[N:Elara|friendly]` on lines 6, 7, and 18
- WHEN inspected
- THEN `npcs` MUST have 1 entry: name="Elara", lines={6,7,18}, mention_count=3, first_seen=6, last_seen=18

#### Scenario: Case-insensitive sort
- GIVEN entities "Zara" and "Alpha" of same type
- WHEN inspected
- THEN they MUST appear as "Alpha" then "Zara" (lowercase comparison)

### Requirement: Progress Normalization

Tags of types E, CLOCK, TRACK, TIMER MUST be normalized into a `progress` array. Each entry: `{type, name, current, max, line}`. CLOCK type MUST be remapped to "E" for API consistency.

Current/max MUST be extracted from tag content: `"N/M"` → both set, `"N"` → current only, max=nil.

#### Scenario: Clock with fraction
- GIVEN `[Clock:Alert 2/5]`
- THEN progress entry: type="E", name="Alert", current=2, max=5

#### Scenario: Timer with current-only
- GIVEN `[Timer:Burnout 3]`
- THEN progress entry: type="TIMER", name="Burnout", current=3, max=nil

### Requirement: Scenes and Sessions Passthrough

Scenes and sessions MUST pass through unchanged from their respective parsers. The cache SHALL NOT transform, deduplicate, or reorder these arrays.

#### Scenario: Scenes identity
- GIVEN 3 scenes from `parse_scenes()`
- THEN `cache.get().scenes` MUST be the same array reference as the parser output

### Requirement: Default Buffer Fallback

When called without a `bufnr` argument, all three functions MUST resolve to `vim.api.nvim_get_current_buf()`.

## Testing Expectations

Existing `tests/test_cache.lua` MUST be migrated from `tests/helpers/cache.lua` to production path `lua/lonelog/cache/init.lua`. All existing tests MUST pass with the new require path.

### New tests

| Area | Test | Priority |
|------|------|----------|
| Cache miss | Verify changedtick mismatch triggers refresh | MUST |
| Invalidated buffer | Verify `invalidate()` + `get()` re-parses | MUST |
| Entity aggregation | Verify all 8 entity types aggregated correctly | MUST |
| Progress normalization | Verify CLOCK→E remap, current/max parsing | MUST |
| Inventory/Wealth/Room | Verify INV, WEALTH, R appear as entity groups | SHOULD |
| Cache isolation | Verify two buffers have independent cache entries | SHOULD |
