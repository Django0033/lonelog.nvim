# Dead Roster Detection Design

**Date:** 2026-06-01
**Status:** Draft
**Requires:** Round marker feature (committed)

## Objective

Exclude dead characters from the round roster auto-generated inside `[COMBAT]` blocks.

## Context

`collect_roster()` scans `[PC:Name|field]` and `[F:Name|field]` tags within a
`[COMBAT]` block and includes all of them in the roster line. There is no way
to mark a combatant as dead — killed characters keep appearing in every
subsequent round's roster.

The user edits death manually (typing into the buffer), so detection is
read-only: look at the field value when collecting, exclude dead entries.

## Death Detection Rules

A combatant is excluded from the roster if any of these conditions is met,
checked **case-insensitively**:

| Condition | Pattern | Examples |
|-----------|---------|----------|
| Descriptive field starts with `dead` | `field:lower():match("^dead")` | `[F:arana|dead]`, `[F:Jefe|Dead]`, `[F:G|dead by fire]` |
| HP field ≤ 0 | Field matches `^HP (%-?%d+)` and number ≤ 0 | `[F:Jefe|HP 0]`, `[F:Goblin|HP -3]` |

### Ambiguity Notes

- `[F:something|deadly poison]` — starts with `dead` → **excluded**. This is
  acceptable: "deadly" implies fatal. Users who need the tag to stay in the
  roster should not use "dead" as a word boundary.
- `[F:something|not dead]` — starts with `not`, not `dead` → **included**. If
  the user wants it excluded they should edit to `[F:something|dead]`.

## Change Surface

**Single file:** `lua/lonelog/commands/round.lua`

### `collect_roster(lines, start, finish)`

Add a dead-check guard before `table.insert()`. Flow becomes:

```
for each line:
  match [PC:...] or [F:...]
  if matched and not is_dead(field) then
    insert into roster
  end
```

The `is_dead(field)` check is inline (not extracted as a separate function —
YAGNI, the logic is two lines).

### No other changes

- `build_roster_line()` — unchanged
- `insert_round()` — unchanged
- Keymaps/commands — unchanged

## Tests

Add **8 new tests** (34 → 42 total):

1. Descriptive `dead` excluded
2. Descriptive `Dead` (capital) excluded
3. HP `0` excluded
4. HP negative `-2` excluded
5. Descriptive alive (`guapo`) included
6. HP positive (`12`) included
7. Mixed: alive + dead → only alive in roster
8. Edge: `deadly poison` — excluded (starts with `dead`)

All existing tests must continue passing unchanged.

## Commits

1. Design doc (this file)
2. Implementation + tests
