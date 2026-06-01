# Room Navigation Design

## Summary

Navigate between connected dungeon rooms by jumping from a room tag to its connected rooms via a picker.

## User Flow

1. User places cursor on or near a line containing `[R:ID|...]`
2. User presses `<leader>lG` or runs `:LonelogRoomGo`
3. If the room tag has an `exits` field (e.g. `exits N:R3, S:R5`), a picker shows each exit with direction and destination room info
4. User selects an exit → cursor jumps to the destination room's line in the buffer

## Module: `lua/lonelog/commands/room_nav.lua`

### `M.parse_exits(raw_tag)`
- Input: raw tag string like `[R:3|active|almacen|exits N:R1, S:R2]`
- Output: table of `{dir, id}` entries, e.g. `{ {dir="N", id="1"}, {dir="S", id="2"} }`
- Parsing: split on `|`, find field starting with `exits `, parse `DIR:ID` pairs separated by `,`
- Empty/nil tag → empty table `{}`
- Tag without `exits` field → empty table `{}`

### `M.find_room_tag_on_line(line)`
- Input: a single string (buffer line)
- Output: the raw `[R:...]` string if found, or `nil`
- Uses pattern match — finds the first `[R:...]` on the line

### `M.collect_room_data(lines)`
- Scans all lines for `[R:ID|...]` tags
- Returns table keyed by ID: `{ id = { line = N, raw = "[R:...]", exits = {...} } }`
- Reuses `parse_exits` for each tag found

### `M.navigate_to_room()`
- Neovim-side function (uses `vim.api`)
- Gets current line from cursor
- Calls `find_room_tag_on_line` on current line
- If none found, notify "No room tag found at cursor" and return
- Parses exits from the tag
- If no exits, notify "No exits defined for this room" and return
- Collects room data from buffer to build lookup of ID → line number + state
- Builds picker choices: `"N → R1 (cleared, entrance hall)"`
- Calls `vim.ui.select` with those choices
- On select, jumps cursor to destination room's line, centers with `zz`
- If destination room not found in buffer, it still shows in picker but selection notifies "Room RX not found in buffer"

## Commands and Keymaps

- New config key: `room_go = "<leader>lG"`
- New user command: `:LonelogRoomGo`

## Error Messages

| Condition | Message |
|-----------|---------|
| No `[R:...]` on current line | "lonelog: No room tag found at cursor" |
| Tag found but no exits field | "lonelog: No exits defined for this room" |
| Destination room not in buffer | "lonelog: Room R:X not found in buffer" |

## Testing

- `tests/test_room_nav.lua` — pure Lua tests (no `vim` stubs needed)
- Tests for `parse_exits`:
  - Normal case with multiple exits
  - No exits field
  - Empty tag
  - Multiple directions (N, S, E, W, NE, NW, etc.)
  - Spaces around commas
- Tests for `find_room_tag_on_line`:
  - Line with room tag
  - Line without room tag
  - Line with other tag types
- Tests for `collect_room_data`:
  - Multiple rooms in buffer
  - Mixed with other content
- No tests for `navigate_to_room` (requires Neovim vim.api — integration test only)

## TODOs for Future

- Visualize connections in `=== Dungeon Status ===` block (show exits per room)
- Command to add/edit/remove exits on a room tag
- ASCII map generation from room connections
