# Delta for Parsed Elements Cache

## ADDED Requirements

### Requirement: Roll Statistics in Cache Output

`refresh()` SHALL aggregate roll statistics from two sources into a `rolls` field on the returned data table: (a) the per-buffer in-memory roll_history from dice.lua, (b) the per-buffer oracle_history from oracle.lua, (c) `d:` lines parsed from the buffer contents. The `rolls` field SHALL follow the shape defined in the Roll Statistics spec (by_type array, total_rolls, fate_rolls, success_counting, oracle_results array).

#### Scenario: Cache rolls from in-memory history

- GIVEN a buffer with dice_history entries for "2d6" and "1d20" and oracle_history entries for "fate"
- WHEN `refresh(bufnr)` is called
- THEN `data.rolls` SHALL include both dice breakdown (by matching notation across history and d: lines) and oracle distribution from history

#### Scenario: Cache rolls from buffer d: lines

- GIVEN a buffer with a `d: 2d6[4,3] = 7` line that was written before dice_history was available
- WHEN `refresh()` is called
- THEN that d: line SHALL be included in the roll statistics aggregation alongside history entries

#### Scenario: Empty rolls when no history or d: lines

- GIVEN a buffer with no dice_history, no oracle_history, and no d: lines
- WHEN `refresh()` is called
- THEN `data.rolls` SHALL be `{ by_type={}, total_rolls=0, fate_rolls=0, success_counting=0, oracle_results={} }`

## MODIFIED Requirements

### Requirement: Entity Aggregation

Tags of types N, L, PC, THREAD, F, INV, WEALTH, R MUST be aggregated by name into sorted arrays. Duplicate names across lines MUST be merged into a single entry with running line tracking.

Output keys: `npcs`, `locations`, `pcs`, `threads`, `foes`, `inventory`, `wealth`, `rooms`, `rolls`. Each entity entry: `{name, tags, lines[], first_seen, last_seen, mention_count}`. The `rolls` key is an aggregate object (not an entity array), defined by the Roll Statistics spec.
(Previously: output keys did not include `rolls`)

#### Scenario: NPC aggregation with dedup

- GIVEN `[N:Elara|friendly]` on lines 6, 7, and 18
- WHEN inspected
- THEN `npcs` MUST have 1 entry: name="Elara", lines={6,7,18}, mention_count=3, first_seen=6, last_seen=18

#### Scenario: Case-insensitive sort

- GIVEN entities "Zara" and "Alpha" of same type
- WHEN inspected
- THEN they MUST appear as "Alpha" then "Zara" (lowercase comparison)

#### Scenario: Rolls field in cache output

- GIVEN a buffer with dice history and d: lines
- WHEN `get()` or `refresh()` returns cached data
- THEN the data table SHALL contain a `rolls` key with the aggregated roll statistics object
