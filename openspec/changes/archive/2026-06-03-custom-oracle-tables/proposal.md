# Proposal: Custom Oracle Tables

## Intent

Users running solo TTRPG sessions need table-specific oracles (e.g., "What faction is this?", "What loot type?"). Currently lonelog only exposes 3 built-in oracles (Fate, Binary, Mythic). Adding a `custom_tables` config option lets users define weighted tables in their Neovim config without modifying plugin source.

## Scope

### In Scope
- `oracle.custom_tables` config option (dict of name → {entry → weight} mappings)
- `M.init(custom_tables)` merge function called from `setup()`
- Custom tables appear alongside built-in ones in the `:LonelogOracle` picker
- Same weighted random selection as built-in tables (via existing `weighted_random()`)
- Updated tests: dynamic table count, custom table roll, unknown custom table

### Out of Scope
- Custom Mythic-style oracles (2d10 + chaos) — deferred
- Per-table configuration beyond weights (flags, metadata) — defer to future spec
- UI for creating/modifying tables at runtime
- Removal or modification of built-in tables

## Capabilities

### New Capabilities
- `custom-oracle-tables`: User-defined weighted oracle tables merged at setup time, selectable and rollable via the same picker and `M.roll()` path as built-in tables

### Modified Capabilities
- None — no existing specs define oracle table behavior at the spec level

## Approach

1. Add `oracle.custom_tables` field to config defaults (empty table `{}`)
2. Implement `M.init(custom_tables)` in oracle.lua that:
   - Validates custom table format (dict `{value = weight}`)
   - Converts each to internal `{value, display, weight}` entries format
   - Inserts into the local `tables` table (lowercased key, capitalized name)
3. Call `M.init(custom)` from `init.lua`'s `M.setup()` after `M.oracle.load_chaos()`
4. `list_tables()` and `roll()` need **zero changes** — they already iterate `tables` and call `weighted_random()` generically
5. Update `test_oracle.lua` to test custom table registration and weighted roll

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lua/lonelog/config.lua` | Modified | Add `custom_tables = {}` to oracle defaults |
| `lua/lonelog/oracle.lua` | Modified | Add `M.init()` merge function (~15 lines) |
| `lua/lonelog/init.lua` | Modified | Add `M.oracle.init()` call after chaos load |
| `tests/test_oracle.lua` | Modified | Add custom table tests, update count assertion |
| `doc/lonelog.txt` | Modified | Document `oracle.custom_tables` option |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Custom table name collides with built-in | Low | `M.init()` skips names matching built-in keys with warning |
| Invalid weight format (non-integer, zeros) | Low | Validate each weight > 0; skip and warn on bad entries |
| Merge order: user overrides after init | Low | `M.init()` is called once from setup; config is frozen |

## Rollback Plan

Revert the 4 file changes above. No migration needed — custom tables are a pure additive config feature with no persisted state.

## Dependencies

None — uses only existing `weighted_random()` and `M.roll()` infrastructure.

## Success Criteria

- [ ] Custom table rolled via `M.roll("mytable")` returns correct weighted result
- [ ] Custom table appears in `M.list_tables()` output
- [ ] All existing oracle tests still pass
- [ ] Invalid config (empty table, zero weights) handled gracefully with warning
