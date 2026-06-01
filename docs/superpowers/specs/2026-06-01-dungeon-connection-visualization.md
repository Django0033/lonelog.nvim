# Dungeon Connection Visualization

**Date:** 2026-06-01
**Requires:** `dungeon_status.lua`, room tag `exits` field

## Objective

Annotate each room line in the `=== Dungeon Status ===` block with resolved
outgoing connections, converting raw `exits N:R3, S:R2` notation into readable
`→ N → R3 (armory) │ S → R2 (barracks)`.

## Behavior

- For each room tag in the block, parse the `exits` field (if present).
- Resolve each `DIR:RoomID` pair to the destination room's description by
  scanning the buffer.
- Append annotation after the raw tag on the same line.
- Rooms without exits get no annotation.
- Rooms with exits but all destinations absent from buffer → `(?)`.

### Example

Buffer contains:

```
[R:1|cleared,looted|entry cave|exits N:R3, S:R2]
[R:2|active|barracks]
[R:3|cleared|armory|exits S:R1]
```

After `:LonelogDungeonStatus`:

```
=== Dungeon Status ===
[R:1|cleared,looted|entry cave|exits N:R3, S:R2]  → N → R3 (armory) │ S → R2 (barracks)
[R:2|active|barracks]
[R:3|cleared|armory|exits S:R1]                    → S → R1 (entry cave)
===
```

## Module Changes

### `M.parse_tag_info(raw_tag)` — new function

- Input: raw tag string like `[R:3|active|almacen|exits N:R1]`
- Output: `{ id, states, desc, exits }` where `exits` is
  `{ {dir="N", dest="1"} }`
- Parses by splitting on `|` and extracting fields
- Used by both `collect_room_tags` and the annotation logic

### `M.collect_room_tags(lines)` — extended

- Now returns `{id, raw, desc, exits}[]` instead of just `{id, raw}[]`
- Uses `parse_tag_info` internally

### `M.build_annotation(raw_tag, desc_by_id)` — new function

- Input: raw tag string, lookup table `{ ["3"] = "armory", ... }`
- Parses exits from the tag
- Looks up each destination in `desc_by_id`
- Returns formatted string like `→ N → R3 (armory) │ S → R2 (barracks)`
- Returns empty string if no exits found

### `M.build_status_block(room_tags)` — modified

- Builds `desc_by_id` lookup from the collected tags
- For each tag with exits, calls `build_annotation`
- Appends annotation (with `  → ` prefix) to the room line

## Keymap / Command

No changes. `:LonelogDungeonStatus` (`<leader>lK`) picks up the new behavior
automatically.

## Edge Cases

- Destination room description empty → `(?)`
- Multiple exits → joined with ` │ ` (U+2502, box drawing vertical bar)
- Exits to non-existent rooms → `(?)` for each missing destination
- Very long lines: no truncation
- Partial data (tag with exits but no desc) handled gracefully

## Testing

- Single room with exits → annotation resolves destination name
- Room without exits → no annotation
- Multiple exits → all shown with `│` separator
- Destination room not found → `(?)`
- Existing tests unchanged and passing

## YAGNI

- Incoming connections (entrantes)
- Visual graph / topology map
- Interactive connection browser
- Editing exits from status block
- Multi-line room tags (already out of scope)
