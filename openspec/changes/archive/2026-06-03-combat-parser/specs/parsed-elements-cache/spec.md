# Delta for Parsed Elements Cache

## MODIFIED Requirements

### Requirement: Entity Aggregation

Tags of types N, L, PC, THREAD, F, INV, WEALTH, R MUST be aggregated by name into sorted arrays. Duplicate names across lines MUST be merged into a single entry with running line tracking.

Output keys: `npcs`, `locations`, `pcs`, `threads`, `foes`, `inventory`, `wealth`, `rooms`, `rolls`, `combat`. Each entity entry: `{name, tags, lines[], first_seen, last_seen, mention_count}`. The `rolls` key is an aggregate object (not an entity array), defined by the Roll Statistics spec. The `combat` key is the array returned by `parsers.combat.parse_blocks(bufnr)`.

(Previously: output keys did not include `combat`)

#### Scenario: NPC aggregation with dedup
- GIVEN `[N:Elara|friendly]` on lines 6, 7, and 18
- WHEN inspected
- THEN `npcs` MUST have 1 entry: name="Elara", lines={6,7,18}, mention_count=3, first_seen=6, last_seen=18

#### Scenario: Case-insensitive sort
- GIVEN entities "Zara" and "Alpha" of same type
- WHEN inspected
- THEN they MUST appear as "Alpha" then "Zara" (lowercase comparison)

#### Scenario: Combat field in cache output
- GIVEN a buffer with `[COMBAT]..[/COMBAT]` blocks
- WHEN `get()` or `refresh()` returns cached data
- THEN the data table SHALL contain a `combat` key whose value is an array
- AND each entry SHALL match the `parse_blocks()` output shape

#### Scenario: No combat blocks returns empty array
- GIVEN a buffer with no `[COMBAT]` delimiters
- WHEN `get()` returns cached data
- THEN `data.combat` SHALL be an empty array `{}`

## MODIFIED Requirements

### Requirement: Changedtick Invalidation

The cache entry for a buffer MUST store `{ changedtick, data }`. On `get()`, the current `nvim_buf_get_changedtick(bufnr)` MUST be compared against the stored value. Match returns the cached data (same table reference). Mismatch triggers `refresh()`.

#### Scenario: Cache hit returns same reference
- GIVEN a buffer unchanged since last refresh
- WHEN `get()` is called twice
- THEN both calls MUST return the identical table reference (zero copy)

#### Scenario: Cache miss re-parses
- GIVEN a buffer whose changedtick differs from cache
- WHEN `get()` is called
- THEN it MUST re-parse all parsers (including combat) and return fresh data

#### Scenario: Invalidate forces re-parse
- GIVEN a cached buffer entry is invalidated
- WHEN `get()` is called next
- THEN it MUST re-parse (cache entry is nil)

(Previously: re-parse description mentioned "all three parsers")

## ADDED Requirements

### Requirement: Combat Parsing on Refresh

`refresh()` SHALL call `parsers.combat.parse_blocks(bufnr)` and assign the result to `data.combat`. This SHALL happen after tag parsing but before returning the data table.

#### Scenario: Refresh includes combat
- GIVEN a buffer with a `[COMBAT]` block
- WHEN `refresh(bufnr)` is called
- THEN `data.combat` SHALL equal the return value of `parsers.combat.parse_blocks(bufnr)`
