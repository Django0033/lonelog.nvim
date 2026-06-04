# Apply Progress — prose-parser

**Mode**: Strict TDD
**Date**: 2026-06-03

## Completed Tasks

### 1. Created `lua/lonelog/parsers/prose.lua`

Promoted from `tests/helpers/prose.lua` without the tokenizer dependency. Inline `classify()` function handles narrative marker detection with proper Lua pattern escaping (`%-` for literal dashes, `\\` for backslash).

- Added unclosed narrative block edge case: if `in_narrative` is true at end of input, the block is closed at `#lines`
- Follows project conventions: tab indentation, `local M = {}` pattern, snake_case

### 2. Updated `tests/test_prose.lua`

- Changed `require("tests.helpers.prose")` to `require("lonelog.parsers.prose")` (production path)
- Added test for unclosed narrative block

### 3. Modified `lua/lonelog/commands/summary/init.lua`

- Removed prose-related regexes from `count_notation()` (meta_notes, dialogues, narrative_blocks)
- Added `prose_parser.parse_prose(slines)` call in `build_session_summary()`
- Stored `summary.meta_notes`, `summary.dialogues`, `summary.narrative_blocks`

### 4. Modified `lua/lonelog/commands/summary/format.lua`

- Replaced `n.meta_notes` with `summary.meta_notes`
- Replaced `n.dialogues` with `summary.dialogues`
- Added `summary.narrative_blocks` display line

### 5. Updated `tests/test_summary.lua`

- Split prose count tests from notation count tests
- Added triangulation tests for empty session prose counts and format display

## TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|------------|-----|-------|-------------|----------|
| 1. Create prose parser | `tests/test_prose.lua` | Unit | N/A (new) | ✅ Written | ✅ Passed | ✅ 3 edge cases | ✅ Clean |
| 2. Port tests | `tests/test_prose.lua` | Unit | N/A (same file) | ✅ Path change | ✅ 12/12 | ✅ Unclosed block | ✅ Clean |
| 3. Modify init.lua | `tests/test_summary.lua` | Unit | ✅ 34/34 | ✅ Tests updated | ✅ 36/36 | ✅ 3 assertions | ✅ Clean |
| 4. Modify format.lua | `tests/test_summary.lua` | Unit | ✅ 34/34 | ✅ Test expectations | ✅ 37/37 | ✅ 3 assertions | ✅ Clean |
| 5. Update summary tests | `tests/test_summary.lua` | Unit | ✅ 34/34 | ✅ New prose tests fail | ✅ 37/37 | ✅ 3 edge cases | ✅ Clean |

## Test Summary

- **Total tests written/updated**: 3 new tests + 3 modified tests
- **Total tests passing**: 37 (summary) + 12 (prose) + all other suites
- **Layers used**: Unit (all)
- **Approval tests (refactoring)**: 0 (no approval tests needed, existing tests confirmed passing)
- **Pure functions created**: 1 (`classify`), 1 (`parse_prose` both pure)

## Deviations from Design

None — implementation matches design.

## Issues Found

- Lua pattern escaping: The `-` character is magic in Lua patterns (lazy repetition operator). All narrative marker patterns in the original helper/tokenizer had subtle bugs due to this — they would match any string because `^\-` was parsed as `^` (start) + `\` (char class) + `-` (0+ lazy operator), matching empty at position 0. Fixed by using `%-` for literal dashes.

## Remaining Tasks

None — all tasks complete.

## Files Changed

| File | Action | What Was Done |
|------|--------|---------------|
| `lua/lonelog/parsers/prose.lua` | Created | Production prose parser module, inlined classify, no tokenizer dependency |
| `tests/test_prose.lua` | Modified | Production path require, added unclosed narrative test |
| `lua/lonelog/commands/summary/init.lua` | Modified | Removed prose regexes from count_notation, added prose parser integration |
| `lua/lonelog/commands/summary/format.lua` | Modified | Replaced n.meta_notes/n.dialogues with summary fields, added narrative_blocks |
| `tests/test_summary.lua` | Modified | Prose count tests split out, triangulation tests added |

## Status

5/5 tasks complete. Ready for verify.
