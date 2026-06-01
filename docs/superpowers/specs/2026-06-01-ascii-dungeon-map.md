# ASCII Dungeon Map

**Date:** 2026-06-01
**Requires:** `dungeon_status.lua`, room tag `exits` field, `room_nav.parse_exits`

## Objective

Add a `--- Map ---` section to the `=== Dungeon Status ===` block that
renders the room graph as ASCII art — each room appearing once with directed
arrows labeled by compass direction.

## Location

Between the room tag list and the closing `===`:

```
=== Dungeon Status ===
[R:1|cleared|entry cave|exits N:R3]
[R:2|active|barracks]
[R:3|cleared|armory|exits S:R1, E:R4]
[R:4|unexplored|storage|exits W:R3]

--- Map ---
R1 (entry cave) -- N --> R3 (armory) -- E --> R4 (storage)
R3 <-- S -- R1
R2 (barracks)
===
```

## Layout Algorithm

Each room appears exactly once in the map, at its first encounter when
iterating rooms in numeric ID order.

1. Sort rooms by numeric ID.
2. Maintain a `placed` set of room IDs already rendered.
3. For each room (in order):
   - If not placed and has no outgoing exits → single line: `R2 (barracks)`
   - If not placed and has exits → walk forward through unvisited destinations:
     `R1 -- N --> R3 -- E --> R4`
   - For each exit whose destination is already placed → emit a back-ref line:
     `R3 <-- S -- R1`

### Forward walk

For a room being rendered for the first time:
- Print `R<N> (<desc>)`
- For each exit in order:
  - If destination is not placed → print ` -- <dir> --> R<dest> (<dest-desc>)`
    and mark destination as placed. Recurse into destination's own exits
    (continue the forward walk).
  - If destination is already placed → collect as a back-ref (see below).

### Back-ref lines

After the forward walk is done, emit one line per back-ref:
`R<source> <-- <dir> -- R<dest> (<dest-desc>)`

### Isolated rooms

Rooms with no exits get printed as:
`R<N> (<desc>)`

Rooms whose only destinations are already placed (all exits are back-refs)
print as:
`R<N> (<desc>)`  followed by back-ref lines.

### Missing destinations

If an exit references a room ID not found in the buffer:
`R<N> (<desc>) -- <dir> --> ??? (R<dest> not found)`

## Module Changes

### `dungeon_status.lua`

**New function `M.build_ascii_map(room_tags, room_info)`**
- Input: `room_tags` (sorted `{id, raw}[]`), `room_info` (keyed by ID,
  `{desc, exits}`)
- Output: array of strings (lines for the map section)
- Implements the layout algorithm above

**Extended `M.build_status_block(room_tags)`**
- Calls `build_ascii_map` after listing room tags
- Inserts `"--- Map ---"` header and map lines before the closing `===`

**New helper `M.get_room_info(room_tags)`**
- Parses each tag to extract `{desc, exits}`
- Returns lookup table keyed by room ID

### Data flow

```
insert_status_block()
  → collect_room_tags(lines)    # unchanged
  → get_room_info(room_tags)     # new
  → build_ascii_map(tags, info)  # new
  → build_status_block(tags, map_lines)  # extended
  → buffer replace/insert
```

## Edge Cases

- No rooms with exits → `--- Map ---` followed by just isolated rooms list
- No rooms at all → `--- Map ---` (empty section, or skip it)
- All rooms isolated → list of `R<N> (desc)` lines
- Single room with exits → forward walk renders it; no back-refs
- Deep chain (R1→R2→R3→...→R10) → single long line
- Branching (R1→R2, R1→R3) → R1's first exit determines the forward walk;
  the other exit becomes a separate root line `R1 -- <dir> --> R<dest>`

## Testing

New tests in `test_dungeon_status.lua` (~10):

- Linear chain → single forward walk line
- Isolated room → single line without arrows
- Bidirectional → forward + back-ref line
- Missing destination → `???` in output
- Multiple branches from same room
- Empty map section (no rooms)
- Mixed: forward chain + back-ref + isolated
- Full `build_status_block` output with map included

## YAGNI

- Interactive map (navigation, click-to-jump)
- Multi-line room tags
- Room coordinates / grid positioning
- Bidirectional arrow optimization (e.g. `R1 ↔ R3`)
- Color / syntax highlighting for map lines
