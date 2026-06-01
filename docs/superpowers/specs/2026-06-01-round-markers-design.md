# Round Markers — Design Spec

**Date:** 2026-06-01
**Status:** Approved
**Feature:** Insert round markers `R#` with optional auto-generated roster line inside combat blocks

## Overview

Add commands to insert auto-incremented round markers inside `[COMBAT]` / `[/COMBAT]` blocks. Two variants: simple `R#` and `R# Roster:` with live `[PC:Name|HP N]` / `[F:Name|HP N]` tags from the current combat block.

## Syntax

```
R1                              ← simple round
@(Matón A) Ataca
d: 1d6+2 vs AC -> Fallo

R2 Roster: [PC:Kael|HP 12] [F:Matón|HP 3]   ← round with roster
```

## Module: `lua/lonelog/commands/round.lua`

### Exported functions

- `M.find_highest_round(lines, start, finish)` — scans lines from `start` to `finish`, finds the maximum `R#` value. Returns 0 if none found, or the integer N.
- `M.collect_roster(lines, start, finish)` — scans for `[PC:Name|HP N]` and `[F:Name|HP N]` patterns. Returns a table of `{ {type="PC", name="Kael", hp=12}, ... }`.
- `M.build_roster_line(round_num, roster)` — `string.format("R%d Roster: %s", n, tags_str)`.
- `M.find_combat_block(lines, cursor_row)` — locates the `[COMBAT]`...`[/COMBAT]` block containing `cursor_row`. Returns `start_line, end_line` or `nil, nil`.
- `M.insert_round(with_roster)` — main orchestrator.

### Flow: `insert_round(with_roster)`

1. Read current buffer lines into `lines`
2. Call `find_combat_block(lines, cursor_row)`
3. If no block found → `vim.notify("lonelog: No combat block found")` → return
4. Call `find_highest_round(lines, start, finish)` → `current_max`
5. New round number: `current_max + 1`
6. If `with_roster`:
   a. Call `collect_roster()` → roster table
   b. Build roster string and call `build_roster_line()`
   c. Insert roster line at cursor
7. Else: insert `R{N+1}` at cursor
8. Enter insert mode at end of inserted line

### Picker integration

`insert_round` uses `vim.ui.select` with two options:
1. `"Ronda simple"` → inserts `R{N+1}`
2. `"Ronda con roster"` → inserts `R{N+1} Roster: ...`

## Config

```lua
insert_round = "<leader>lr",
```

In `config.lua` under `keymaps` → Main actions (uppercase) group. `r` for "round".

## Plugin Wiring (`plugin/lonelog.lua`)

- Normal mode keymap: `<leader>lr` → round picker with `vim.ui.select`
- User command: `:LonelogRound` → picks via selector (same flow)

## Syntax Highlighting

`lonelogRound` already exists at `lonelog.vim:86` for `^R\d+\s`. Roster line highlighted by existing `lonelogTag` / `lonelogTagType` / `lonelogProgressNum` — no changes needed.

## Tests: `tests/test_round.lua`

- `find_highest_round: no rounds → 0`
- `find_highest_round: single round R3 → 3`
- `find_highest_round: multiple rounds R1,R3,R7 → 7`
- `find_highest_round: consecutive R1,R2,R3 → 3`
- `find_highest_round: only outside block → 0`
- `collect_roster: PC with HP → {type="PC", name="Kael", hp=12}`
- `collect_roster: Foe with HP → {type="F", name="Matón", hp=6}`
- `collect_roster: mixed PCs and foes`
- `collect_roster: no relevant tags → empty table`
- `build_roster_line: formats correctly`
- `find_combat_block: cursor inside → returns bounds`
- `find_combat_block: cursor outside → nil,nil`
- `find_combat_block: no combat block → nil,nil`

## Help File (`doc/lonelog.txt`)

- Add section 4.17 (Round markers)
- Keymap `<leader>lr` and command `:LonelogRound`
- API entry for `insert_round`

## README

- Add `round markers` to feature list
- Add `:LonelogRound` to commands table
