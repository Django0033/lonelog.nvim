# Apply Progress — custom-oracle-tables

## Completed Tasks

1. **oracle.lua**: Added `M.init(custom_tables)` that accepts custom oracle tables in array (equal weight) or dict (weighted) format and merges into `M.tables`. Handles name collision (custom overrides built-in), weight of 0, single-entry tables, and empty input.

2. **config.lua**: Added `custom_tables = {}` to `defaults.oracle` table.

3. **init.lua**: Added `M.oracle.init(cfg.oracle.custom_tables)` call in `M.setup()` after config is loaded.

4. **tests/test_oracle.lua**: Added 7 tests covering all edge cases.

## Files Changed

- `lua/lonelog/oracle.lua` — Added `M.init()` (~37 lines)
- `lua/lonelog/config.lua` — Added `custom_tables = {}` default
- `lua/lonelog/init.lua` — Added `oracle.init()` call
- `tests/test_oracle.lua` — Added 7 custom table tests

## Deviations

None. All spec requirements met exactly.

## Edge Cases Covered

- Empty custom_tables: no-op
- Table with one entry: always returns that entry
- Custom table name overriding built-in ("binary"): user table wins
- Weight of 0: excluded from weighted selection
- Array format: equal weights
- Dict format: explicit weights preserved

## Issues

None.

## TDD Cycle Evidence

| Task | Test File | Layer | Safety Net | RED | GREEN | TRIANGULATE | REFACTOR |
|------|-----------|-------|------------|-----|-------|-------------|----------|
| 1. `M.init()` | `tests/test_oracle.lua` | Unit | ✅ 14/14 | ✅ Written | ✅ Passed | ✅ 7 cases | ✅ Config/init wiring |
| 2. `config.lua` default | — | Structural | N/A | N/A (structural) | N/A | ➖ Single (pure config) | ✅ Added |
| 3. `init.lua` wiring | — | Structural | N/A | N/A (structural) | N/A | ➖ Single (pure wiring) | ✅ Added |

## Test Summary

- **Total tests written**: 7 (new) + 14 (existing) = 21
- **Total tests passing**: 21
- **Layers used**: Unit (21)
- **Approval tests**: None — new feature, no refactoring
- **Pure functions created**: `M.init()` — deterministic, no side effects on state beyond the module table
