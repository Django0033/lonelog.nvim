# Combat Parser

**Date:** 2026-06-01
**Requires:** `parsers/tokenizer.lua`

## Objective

Parse existing `[COMBAT]` / `[/COMBAT]` blocks from the buffer into
structured data: rounds, combatants (PCs/foes), action lines, and
block boundaries.

## Location

New file: `lua/lonelog/parsers/combat.lua`

## API

```lua
M.parse_combat_blocks(bufnr) -> CombatBlock[]
M.parse_combat_block(lines, start_line, end_line) -> CombatBlock
```

## Output

```lua
{
  {
    start_line = 10,
    end_line = 28,            -- nil if block not closed
    current_round = 3,
    is_closed = true,
    combatants = {
      { type = "PC", name = "Alex", stats = {"HP 10/10"}, line = 12 },
      { type = "foe", name = "Goblin", stats = {"HP 5/5", "AC 12"}, line = 13 },
    },
    rounds = {
      { number = 1, line = 11, roster_lines = {} },
      { number = 2, line = 18, roster_lines = {} },
    },
  },
}
```

## Detection

1. Scan lines for `[COMBAT]` / `[/COMBAT]`
2. Inside each block:
   - Lines matching `R%d` → round markers
   - Lines matching `R%d Roster:` → roster lines
   - Lines matching `[PC:...]` or `[F:...]` → combatants
   - `@` lines → actions
   - `d:` lines → dice rolls
3. Track current round number
4. Combatants persist across rounds (updated by roster lines)
5. Dead detection uses same logic as `round.lua`

## Reuses

- Tokenizer for classifying lines
- `round.lua:collect_roster()` for extracting combatants from a range
- `round.lua:is_dead()` for filtering dead combatants

## YAGNI

- Nested combat blocks — not supported by Lonelog spec
- Combat block with no `[/COMBAT]` — allowed, `is_closed = false`

## Testing

~8 tests: single block, multiple blocks, unclosed block, PCs + foes,
round progression, roster lines, dead combatants excluded, empty block.
