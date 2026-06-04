# Tasks: Session Roll Statistics

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~250 (150 production + ~100 test) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR |
| Delivery strategy | single-pr |
| Chain strategy | size-exception |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: Low

## Phase 1: Foundation — History Tables

- [ ] 1.1 `dice.lua` — Add `roll_history = {}` table, `append_history(bufnr, line, result)`, `get_history(bufnr)`, `clear_history(bufnr)`. Append in `M.roll()` after successful return.
- [ ] 1.2 `oracle.lua` — Add `oracle_history = {}`, `append_history(bufnr, result)`, `get_history(bufnr)`. Append in `M.roll()` after success.

## Phase 2: Core Implementation — Capture and Aggregation

- [ ] 2.1 `init.lua` — In `M.roll_dice()`, capture `{line, bufnr, result}` to `dice.append_history()` before `show_dice_result`. Same for `M.roll_oracle()` — capture to `oracle.append_history()` before `show_oracle_result`.
- [ ] 2.2 `cache/init.lua` — Add `aggregate_rolls()`: read `dice_history[bufnr]` + `oracle_history[bufnr]`, parse buffer `d:` lines via existing `parse_dice_line`, union/dedup by line. Emit `rolls` field in `refresh()` data with shape `{by_type={}, total_rolls=N, fate_rolls=N, success_counting=N, oracle_results={}}`.

## Phase 3: Summary Integration

- [x] 3.1 `commands/summary/init.lua` — Extend `build_session_summary()`: accept `roll_stats` param (from cache), embed `by_type`, `total_rolls`, `oracle_results` in `summary.roll_stats`. Wire callers to pass `data.rolls`.
- [x] 3.2 `commands/summary/format.lua` — Add "Dice by Type" section in `format_summary()`: per-notation count, avg, min, max. Add "### Oracle Results" section in `export_summary()` as markdown sub-heading.

## Phase 4: Testing

- [ ] 4.1 New `tests/test_dice_history.lua` — standalone test for `append_history` / `get_history` / `clear_history` with mocked `roll_history` table.
- [ ] 4.2 Extend `tests/test_oracle.lua` — add oracle `append_history` / `get_history` tests.
- [ ] 4.3 Extend `tests/test_cache.lua` — seed `dice_history` mock, verify `data.rolls` contains combined history + `d:` lines with dedup.
- [x] 4.4 Extend `tests/test_summary.lua` — pass mock `roll_stats` to `build_session_summary`, verify breakdown by dice type and oracle distribution; verify `format_summary`/`export_summary` includes new sections. (Covered by TDD in Phase 3.)

## Dependency Order

1 → 2 → 3 → 4 (strict). Phase 1 must ship before Phase 2 can use history. Phase 2's cache aggregation is prerequisite to Phase 3 summary integration. Phase 4 tests each layer.
