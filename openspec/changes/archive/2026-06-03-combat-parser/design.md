# Design: Combat Parser

## Technical Approach

Promote the working prototype at `tests/helpers/combat.lua` to a production module at `lua/lonelog/parsers/combat.lua`, extending it with action-line classification. Wire the result into `cache/init.lua::refresh()` as a `combat` passthrough field — same pattern as `scenes` and `sessions`. Migrate the existing 10 test scenarios from the helper path to the production path, adding action-level coverage.

## Architecture Decisions

### Decision: Module location — `parsers/` not `addons/combat/`

| Option | Tradeoff | Decision |
|--------|----------|----------|
| `parsers/combat.lua` | Separation of concerns — parsing is data extraction, not UI/behavior | ✅ |
| `addons/combat/parser.lua` | Co-locates with the combat addon but couples parsing to addon lifecycle | ❌ |

**Rationale**: The parser has zero consumer dependencies on the addon. Placing it in `parsers/` means the cache, pickers, and future consumers (dead roster, round markers, combat tracker) all depend on the same canonical parser. The addon can requre it like any other consumer.

### Decision: Actions array — new field absent from helper prototype

**Choice**: The production block object includes an `actions[]` field with classified entries: `{ type("action"|"dice"|"tag"|"narrative"|"note"), content, line }`.
**Rationale**: The helper prototype only extracts blocks, rounds, and combatants. The proposal's block shape specifies `actions[]`. Action classification unlocks consumers (round markers, action logs) that would otherwise re-parse the same lines. Same regex-based pattern as existing parsers.

### Decision: is_dead — computed, not stored

**Choice**: `is_dead` is a computed property derived from the combatant's stats field at query time, not a stored field on the combatant object. The existing `is_dead()` helper function lives inside the parser module as `M.is_dead(stats_field)`.
**Rationale**: Dead status changes as HP is updated across rounds. Storing it would require recomputation on every round parse. Computing on read keeps the cache entry stable across rounds. The 3 existing inline copies (helper, round.lua, addons/combat/combat.lua) are NOT consolidated — deferred by the proposal.

### Decision: Cache passthrough — same pattern as scenes/sessions

**Choice**: `cache.refresh()` calls `require("lonelog.parsers.combat").parse_blocks(bufnr)` and assigns the result to `data.combat`. No aggregation, no transformation.
**Rationale**: Matches the existing scenes/sessions passthrough pattern exactly. Combat data is consumed as an opaque array — consumers iterate and filter. No aggregation needed (unlike entity tags).

## Data Flow

```
cache.refresh(bufnr)
    │
    ├── parse_tags(bufnr)       → data.tags
    ├── parse_scenes(bufnr)     → data.scenes       (passthrough)
    ├── parse_all_sessions(bufnr) → data.sessions     (passthrough)
    └── parse_blocks(bufnr)     → data.combat        (NEW — passthrough)
                                   │
                                   ▼
                             array of CombatBlock:
                             { start_line, end_line, is_closed,
                               current_round, combatants[],
                               rounds[], actions[] }

Consumer reads cache.get(bufnr).combat
    │
    └── Dead Roster Detection, Round Markers,
        Combat Tracker (future)
```

### Block parsing algorithm

```
For each line in buffer:
  "[COMBAT]"         → open block, record start_line
  "[/COMBAT]"        → close block, record end_line
  "R<N> Roster: ..." → parse roster, add combatants, record round.roster_lines
  "R<N>"             → new round, update current_round
  other (inside block) → classify as action/dice/tag/narrative/note and append to block.actions[]
  blank              → skip

Combatant parsing:
  "[PC:<name>|<field>]"  → type="PC", name, stats=[field]
  "[F:<name>|<field>]"   → type="foe", name, stats=[field]
  First encounter creates combatant; subsequent same-name updates stats+line.

Action line classification:
  line matches "^@"      → type="narrative"
  line matches "^d:"     → type="dice"
  line matches "^%*"     → type="note"
  line matches "%[PC:" / "%[F:"  → type="tag" (also updates combatant)
  other                   → type="action"
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `lua/lonelog/parsers/combat.lua` | Create | Production parser: `parse_blocks(bufnr?)` → array of combat blocks with actions |
| `lua/lonelog/cache/init.lua` | Modify | Add `combat` require + field assignment in `refresh()`, add to `data` table |
| `tests/test_parsers_combat.lua` | Create | Migrated from `tests/helpers/combat.lua` path; add action-classification tests |
| `openspec/specs/parsed-elements-cache/spec.md` | Modify | Delta: add `combat` field requirement + scenario |
| `tests/helpers/combat.lua` | Keep | Existing file remains (no production callers removed yet) |

## Interfaces / Contracts

### New module: `lua/lonelog/parsers/combat.lua`

```lua
---@class CombatBlock
---@field start_line number
---@field end_line number|nil  nil for unclosed blocks
---@field is_closed boolean
---@field current_round number
---@field combatants Combatant[]
---@field rounds Round[]
---@field actions[] Action[]

---@class Combatant
---@field type "PC"|"foe"
---@field name string
---@field stats string[]
---@field is_dead fun():boolean  computed at read time from stats
---@field line number

---@class Round
---@field number number
---@field line number
---@field roster_lines number[]

---@class Action
---@field type "action"|"dice"|"tag"|"narrative"|"note"
---@field content string   raw line text
---@field line number

---Parse combat [COMBAT]..[/COMBAT] blocks from a buffer.
---@param bufnr? number  Buffer number (default: current)
---@return CombatBlock[]
function M.parse_blocks(bufnr) end

---Check if a stats field indicates death.
---@param field string
---@return boolean
function M.is_dead(field) end  -- internal helper, exported for testability
```

### Cache delta: `data.combat`

```lua
---@field combat CombatBlock[]  passthrough from combat parser
```

## Testing Strategy

| Layer | What to Test | Approach |
|-------|-------------|----------|
| Unit | Block boundaries (open, close, unclosed) | Migrate existing 10 test cases from helper path |
| Unit | Combatant parse + update (PC/foe) | Same tests, production path |
| Unit | Rounds + roster lines | Same tests, production path |
| Unit | Action classification (all 5 types) | New test cases in migrated file |
| Unit | `is_dead` helper (HP ≤ 0, "dead" string, alive) | New test cases |
| Unit | Empty buffer, no blocks | Same test, production path |
| Integration | `cache.get(bufnr).combat` returns expected data | Add test case to `test_cache.lua` |
| Integration | Cache passthrough identity (same reference as parser output) | Same pattern as scenes/sessions |

## No Migration Required

The parser is a new module with no prior callers. Existing `tests/helpers/combat.lua` continues to exist (no production callers removed — the addon's `round.lua` and `combat.lua` still reference their own `is_dead`). Rollback: delete `parsers/combat.lua`, revert the 5-line cache delta, delete migrated test file.

## Open Questions

- None — all decisions map the proposal to concrete Lua patterns proven in the existing parser modules.
