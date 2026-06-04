# Combat Parser Specification

## Purpose

Parse `[COMBAT]..[/COMBAT]` blocks from a buffer into structured combat data — block boundaries, round markers, combatants (PC/foe), roster lines, and death status. Exposed via `cache.get(bufnr).combat`.

## Requirements

### Requirement: Module API — parse_blocks

The module MUST export a single function `parse_blocks(bufnr?)` that returns an array of parsed combat block objects. When `bufnr` is omitted, it MUST default to the current buffer via `nvim_get_current_buf()`.

#### Scenario: Current buffer default
- GIVEN no buffer argument
- WHEN `parse_blocks()` is called
- THEN it MUST use `nvim_get_current_buf()` internally

### Requirement: Block Detection

The parser MUST scan all lines and detect `[COMBAT]` as a block start and `[/COMBAT]` as a block end. Each block MUST be represented as an object with `{start_line, end_line, is_closed, current_round, combatants[], rounds[]}`.

#### Scenario: Well-formed block
- GIVEN lines `[COMBAT]`, content, `[/COMBAT]`
- WHEN parsed
- THEN `start_line` and `end_line` SHALL be set, `is_closed` SHALL be `true`

### Requirement: Unclosed Blocks

A block that reaches end-of-buffer without `[/COMBAT]` MUST have `end_line = nil` and `is_closed = false`.

#### Scenario: Open block at EOF
- GIVEN `[COMBAT]` on line 5 with no closing delimiter before end of buffer
- WHEN parsed
- THEN the block SHALL have `end_line = nil`, `is_closed = false`

### Requirement: Round Extraction

Lines matching `^R(\d+)` MUST be extracted as round markers. Each round SHALL be an object `{number, line, roster_lines[]}`. `current_round` SHALL be the highest round number seen.

#### Scenario: Ascending rounds
- GIVEN lines `R1`, `R3` within a block
- WHEN parsed
- THEN `rounds` SHALL contain 2 entries with numbers 1 and 3, `current_round` SHALL be 3

### Requirement: Combatant Extraction

Inline tags `[PC:Name|field]` and `[F:Name|field]` SHALL be parsed into combatant entries. Each entry: `{type, name, stats[], line}`. Duplicate names of the same type SHALL update stats/line. Roster lines (`^R\d+ Roster:`) SHALL also contribute combatants, excluding entries marked dead.

#### Scenario: PC and foe inline
- GIVEN `[PC:Alex|HP 10/10]` and `[F:Goblin|HP 5/5]`
- WHEN parsed
- THEN combatants array SHALL contain both entries with correct type and name

#### Scenario: Roster line adds combatants
- GIVEN `R1 Roster: [PC:Kael|HP 8] [F:Jefe|HP 12]`
- WHEN parsed
- THEN Kael and Jefe SHALL appear in combatants

### Requirement: Death Status

A combatant SHALL be considered dead if its field matches `^dead` (case-insensitive) or `^HP -?\d+` where the HP value is ≤ 0. The parser SHALL compute an `is_dead` boolean per combatant.

#### Scenario: Field says dead
- GIVEN `[F:Goblin|dead]`
- THEN `is_dead` SHALL be `true`

#### Scenario: Zero HP
- GIVEN `[F:Goblin|HP 0/5]`
- THEN `is_dead` SHALL be `true`

#### Scenario: Positive HP
- GIVEN `[F:Goblin|HP 10/10]`
- THEN `is_dead` SHALL be `false`

### Requirement: Action Line Classification

Non-tag, non-round, non-delimiter lines within a block SHALL be classified by first token: `@` → `action`, `d:` → `dice`, otherwise → `narrative`. Each classified line SHALL be recorded in a `lines[]` array per round with `{type, text, line_num}`.

#### Scenario: Action vs dice vs narrative
- GIVEN `@ Goblin attacks!`, `d: 1d8+2 -> 5`, `A narrative line`
- WHEN parsed within a round
- THEN each SHALL have the correct `type` classification

### Requirement: Multiple Blocks

The parser MUST handle multiple disjoint `[COMBAT]` blocks in a single buffer, returning one entry per block.

#### Scenario: Two blocks
- GIVEN two separate `[COMBAT]..[/COMBAT]` blocks
- WHEN parsed
- THEN the returned array SHALL have 2 entries with independent state

### Requirement: No Blocks

A buffer with no `[COMBAT]` delimiter SHALL return an empty array.

#### Scenario: Plain buffer
- GIVEN lines with no combat delimiters
- WHEN parsed
- THEN result SHALL be `{}`

## Testing Expectations

New file `tests/test_parsers_combat.lua` SHALL test the production path `lonelog.parsers.combat`. Existing `tests/test_combat_parser.lua` (targeting `tests.helpers.combat`) SHALL remain unchanged.

| Area | Test | Priority |
|------|------|----------|
| Block detection | Well-formed, unclosed, empty blocks | MUST |
| Round extraction | Ascending, non-sequential, no rounds | MUST |
| Combatants | Inline PC/foe, roster line, dedup, death filter | MUST |
| Death status | `dead` keyword, HP ≤ 0, positive HP | MUST |
| Action classification | `@` action, `d:` dice, text narrative | MUST |
| Multiple blocks | Two disjoint blocks | MUST |
| Empty buffer | No `[COMBAT]` markers | MUST |
