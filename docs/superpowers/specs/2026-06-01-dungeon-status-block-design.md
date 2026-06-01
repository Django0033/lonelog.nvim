# Dungeon Status Block Design

**Date:** 2026-06-01
**Status:** Draft
**Requires:** Core Lonelog plugin (any version with tag support)

## Objective

Insert or replace a `=== Dungeon Status ===` block in the current buffer,
collecting all `[R:ID|...]` tags from the buffer and grouping them for a
quick at-a-glance dungeon state snapshot.

Based on the [Lonelog Dungeon Crawling Add-on v1.0.0](https://github.com/valgur/lonelog)
by Roberto Bisceglie.

## Behavior

- Scan the entire buffer for all `[R:ID|...]` tags (single-line only).
- If the same room ID appears multiple times, keep the *last* occurrence
  (most recent state).
- Sort rooms by numeric ID ascending.
- If `=== Dungeon Status ===` already exists in the buffer, replace its
  content lines (keep the header line, update everything after it until the
  next `===` line or end of buffer).
- If no `=== Dungeon Status ===` exists, insert the block at the beginning of
  the buffer (line 1).

### Example

Buffer contains:

```
[COMBAT]
R1
@ Attack
R2 Roster: [PC:Kael|HP 8] [F:Jefe|HP 12]
[/COMBAT]

[R:1|cleared,looted|entry cave]
[R:2|active|barracks]
[R:1|cleared,looted|entry cave|exits N:R3]
```

After `:LonelogDungeonStatus`:

```
=== Dungeon Status ===
[R:1|cleared,looted|entry cave|exits N:R3]
[R:2|active|barracks]

[COMBAT]
R1
...
```

Room 1 appears twice: only the last version (with exits) is kept.

## Change Surface

### New file: `lua/lonelog/commands/dungeon_status.lua`

```
local M = {}

function M.collect_room_tags(lines)     -- scans lines, returns [R:...] tags deduped by ID
function M.find_existing_block(lines)    -- returns (start_line, end_line) or nil
function M.build_status_block(tags)      -- returns array of lines for the block
function M.insert_status_block()         -- main entry point (no args, works on current buffer)

return M
```

### Modified files

| File | Change |
|------|--------|
| `lua/lonelog/config.lua` | Add `dungeon_status` keymap entry (default `<leader>lK`) |
| `plugin/lonelog.lua` | Wire keymap and `:LonelogDungeonStatus` command |
| `doc/lonelog.txt` | Add section 4.18 |
| `README.md` | Add to features list and commands table |

### Keymap and command

| Component | Value |
|-----------|-------|
| Keymap (normal) | `<leader>lK` |
| Insert mode | none (block is a structural element) |
| Command | `:LonelogDungeonStatus` |
| Config key | `dungeon_status` |

## Tag collection specifics

- Match single-line `[R:...]` tags.
- Multi-line `[R:Name\n | ...]` are out of scope (YAGNI for dungeon rooms).
- Extract room ID (first field after `R:`).
- Keep tag text as-is for display.
- Sort: split on `|`, take first field after `R:`, convert to number, sort
  ascending. Alphanumeric IDs fall back to string sort.
- Dedup: build a table keyed by room ID, taking the last encounter.

## Block replacement details

1. Scan lines for `=== Dungeon Status ===`.
2. If found, scan forward to find next `=== ` line or end of buffer.
   The block range is `(match_line, end_line - 1)` (exclusive of next header).
3. Replace lines in that range with just the room tags (the header line stays).
4. If not found, insert at line 0 (beginning of buffer).

## Tests

New file: `tests/test_dungeon_status.lua` (~15 tests)

- Single `[R:ID|...]` collected
- Multiple rooms, scrambled order → sorted by ID
- Duplicate room ID → last occurrence kept
- No `[R:]` in buffer → empty block
- `[N:]`, `[PC:]`, `[F:]` ignored (only `[R:]`)
- `[R:]` inside other blocks (e.g. prose) still collected
- `[#R:ID]` ignored (reference, not room definition)
- Block replacement: existing block updated
- Block replacement: rooms inside block included in collection
- Block insertion: no existing block → inserts at line 1
- `build_status_block()` output format

## Fuera de alcance (YAGNI)

- Parseo de `exits` field (se muestra tal cual)
- `===` de cierre (el bloque termina en el próximo `===` o EOF)
- `[#R:ID]` como referencia (ya funciona como tag)
- Multi-line room tags
- Interacción con `[COMBAT]` blocks
