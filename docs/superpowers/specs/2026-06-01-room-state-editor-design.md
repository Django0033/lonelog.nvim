# Room State Editor Design

## Summary

Toggle room states on `[R:ID|...]` tags via a picker, replacing manual text edits.

## User Flow

1. Place cursor on/near a line containing `[R:ID|state|...]`
2. Press `<leader>lR` or run `:LonelogRoomState`
3. Picker shows all 8 dungeon states with checkmarks for active ones
4. Select a state → it toggles (add if absent, remove if present) → tag is rewritten in buffer
5. Run again to toggle more states

## Module: `lua/lonelog/commands/room_state.lua`

### `M.parse_states(raw_tag)`
- Input: raw tag string like `[R:3|cleared,looted|almacen|exits N:R1]`
- Output: table of state strings, e.g. `{"cleared", "looted"}`
- Parsing: extract the first field after `R:ID|`, split on `,`
- Empty state field → `{"unexplored"}`
- No `[R:...]` match → `nil`

### `M.build_tag(raw_tag, new_states)`
- Input: original raw tag + table of state strings
- Output: rewritten tag string with updated state field
- Replace the first `|`-delimited field after `R:ID`
- Empty states list → writes `unexplored`

### `M.edit_room_state()`
- Neovim-side function (uses `vim.api`)
- Gets current line, finds `[R:...]`
- If none: notify "No room tag found at cursor"
- Parse current states
- Show `vim.ui.select` with 8 options, each prefixed `[✓]` or `[ ]`
- On selection: toggle that state, rebuild tag, replace line in buffer

## States

```
unexplored, active, cleared, looted, locked, trapped, safe, collapsed
```

## Keymaps and Commands

- Config key: `room_state = "<leader>lR"`
- User command: `:LonelogRoomState`

## Error Messages

| Condition | Message |
|-----------|---------|
| No `[R:...]` on current line | "lonelog: No room tag found at cursor" |

## Testing

- `tests/test_room_state.lua` — pure Lua tests
- `parse_states`: normal case, single state, no states, empty, not a tag
- `build_tag`: single state, multiple states, all states toggled off, exits field present
- No tests for `edit_room_state` (requires Neovim)
