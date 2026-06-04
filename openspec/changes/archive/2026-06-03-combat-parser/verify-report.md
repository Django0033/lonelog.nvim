# Verification Report — Combat Parser

**Status**: PASS ✅

## Executive Summary

The combat-parser change implements a Lua module `lonelog.parsers.combat` that parses `[COMBAT]..[/COMBAT]` blocks from Neovim buffers into structured combat data, wired into `lonelog.cache` as `data.combat`. All 12 spec scenarios pass, all 24 test suites pass (702 tests, 0 failures).

## Spec Scenario Coverage

| # | Scenario | Status | Evidence |
|---|----------|--------|----------|
| 1 | Current buffer default | ✅ | `parse_combat_blocks()` defaults via `nvim_get_current_buf()`. Test 19 (test_parsers_combat.lua:406-415) |
| 2 | Well-formed block | ✅ | Block detects `[COMBAT]`/`[/COMBAT]`, sets start_line/end_line/is_closed. Test 1 (line 75-105) |
| 3 | Open block at EOF | ✅ | Missing `[/COMBAT]` → end_line=nil, is_closed=false. Test 4 (line 147-163) |
| 4 | Ascending rounds | ✅ | R1,R3 → 2 rounds with numbers 1 and 3, current_round=3. Test 3 (line 129-142) |
| 5 | PC and foe inline | ✅ | `[PC:Alex|...]` + `[F:Goblin|...]` → both in combatants. Test 2 (line 110-124) |
| 6 | Roster line adds combatants | ✅ | `R1 Roster: ...` adds Kael and Jefe. Test 7 (line 191-205) |
| 7 | Field says dead | ✅ | `dead` field → is_dead=true. Test 10 (line 260-270) |
| 8 | Zero HP | ✅ | `HP 0/5` → is_dead=true. Test 11 (line 275-285) |
| 9 | Positive HP | ✅ | `HP 10/10` → is_dead=false. Test 13 (line 305-315) |
| 10 | Action vs dice vs narrative | ✅ | `@`→narrative, `d:`→dice, plain→action, `*`→note, tag→tag. Test 9 (line 231-255) |
| 11 | Two blocks | ✅ | Two disjoint blocks → 2 entries with independent state. Test 8 (line 210-226) |
| 12 | Plain buffer | ✅ | No delimiters → `{}`. Test 5 (line 168-172) |

### Additional Edge Cases Verified

- Negative HP (`HP -3`) → is_dead=true ✅
- Roster excludes dead entries ✅
- Combatant dedup (same name+type updates stats) ✅
- Roster_lines tracked per round ✅
- Case-insensitive `dead` detection ✅
- Empty block (immediately closed) ✅
- `is_dead()` exported function with all variants ✅
- Both default and explicit bufnr ✅

## Test Results

| Test File | Type | Tests | Pass | Fail |
|-----------|------|-------|------|------|
| `tests/test_parsers_combat.lua` | Unit (new) | 57 | 57 | 0 |
| `tests/test_cache.lua` | Integration (modified) | 151 | 151 | 0 |
| All other suites (22 files) | Regression | 494 | 494 | 0 |
| **Total** | | **702** | **702** | **0** |

## Deviations from Spec (per apply-progress)

1. **Function name**: `M.parse_combat_blocks()` instead of `M.parse_blocks()`. Cache wire uses `combat_mod.parse_combat_blocks()`. Consistent across all call sites.
2. **Test file**: Created `tests/test_parsers_combat.lua` (new file per spec/design). Legacy `tests/test_combat_parser.lua` (28 tests) unchanged — confirmed via `git diff`.
3. **is_dead**: Computed boolean field (set on insert/update) instead of `:is_dead()` method. Semantically equivalent.
4. **Action classification**: 5 types (narrative, dice, action, tag, note) instead of spec's 3. Design artifact added `@`→narrative, `*`→note, tag→tag. All spec scenarios still pass.

None of these are breaking changes.

## Artifacts

| Artifact | Path | Role |
|----------|------|------|
| Production parser | `lua/lonelog/parsers/combat.lua` | 226 lines, 3 pure functions + 1 exported entry point |
| Cache wire | `lua/lonelog/cache/init.lua` | `M.refresh()` requires combat_mod, populates `data.combat` |
| New tests | `tests/test_parsers_combat.lua` | 57 test cases covering all spec scenarios + edge cases |
| Modified tests | `tests/test_cache.lua` | 3 combat passthrough tests (tests 23, 30, 31) |

## Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| `parse_combat_blocks()` name mismatch with spec `parse_blocks()` | Low | Documented deviation. Cache uses correct name. |
| Action classification differs from spec (5 types vs 3) | Low | Documented deviation. Superset behavior, no spec scenario broken. |
| `is_dead` as field vs method | Low | Equivalent semantics. No consumer expects `:is_dead()`. |
| No standalone `test_combat_parser.lua` modification | None | Spec explicitly says existing test should remain unchanged. Confirmed. |
