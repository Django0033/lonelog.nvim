# Code Deletion Log

## [2026-06-01] Refactor Session — Dead Code Cleanup & Consolidation

### Unused Exports Removed
- `lua/lonelog/dice.lua` — `M.quick_dice` table (never accessed; `plugin/lonelog.lua` had its own local copy)
- `lua/lonelog/ui.lua` — 6 unused backward-compat aliases: `show_result`, `show_colored_result`, `copy_result`, `can_insert_here`, `open`, `close` (all accessed directly via `M.floating.*`)

### Unused Imports Removed
- `lua/lonelog/ui/picker.lua` — `local sidebar` and `local config` (both modules were re-required inline)

### Duplicate Code Consolidated
- `lua/lonelog/parsers/tags.lua` + `lua/lonelog/parsers/scenes.lua` — Identical `should_use_telescope` local function removed; both now call `require("lonelog.config").should_use_telescope()` directly
- `plugin/lonelog.lua` — Quick dice data defined twice (once for keymaps, once for commands) consolidated into a single `QUICK_DICE` table at module level
- `lua/lonelog/commands/summary.lua` — Duplicated session picker item-building logic extracted into `build_session_items()` helper; duplicated buffer data fetching extracted into `get_current_buffer_data()` helper

### Duplicate Code Consolidated (Round 2)
- `lua/lonelog/oracle.lua` — `show_chaos_ui()` had 3 identical buffer content blocks and 2 identical confirm keymap handlers. Extracted `build_chaos_content()` helper, `update_buffer()` local, `close_win()` local, and `confirm_and_close()` local. Also fixed typo: "Rango" → "Range"

### Impact
- Files modified: 8
- Lines removed: 71
- Lines added: 52 (helpers + shared table + extracted locals)
- **Net reduction: 19 lines**

### Testing
- All 173 tests passing (19 dice + 10 oracle + 22 tags + 14 scenes + 2 note + 28 progress + 24 summary + 3 session + 5 narrative + 31 roll_line + 20 integration + 27 tables)

## [2026-06-01] Refactor Session — Dead Code Cleanup (Round 2)

### Unused Exports Removed
- `lua/lonelog/dice.lua` — Removed dynamically-created quick dice helper functions (`M.d4`, `M.d6`, `M.d8`, `M.d10`, `M.d12`, `M.d20`, `M.d100`). These were generated via a loop (lines 283-296) but never called from any production code or tests.
- `lua/lonelog/init.lua` — Removed `M.roll_line` alias. The `roll_line` module is always accessed directly via `require("lonelog.roll_line")` in `plugin/lonelog.lua`, never through the `lonelog` module table.

### Unused Files (Marked with Comments)
These files are only used by test code, NOT required in any production source under `/lua/`:

| File | Production Usage | Test Coverage |
|------|-----------------|---------------|
| `lua/lonelog/parsers/prose.lua` | None | test_prose.lua (11 tests) |
| `lua/lonelog/parsers/tokenizer.lua` | None (only used by prose.lua) | test_tokenizer.lua (30 tests) |
| `lua/lonelog/parsers/combat.lua` | None | test_combat_parser.lua (28 tests) |

### Duplicate Code Noted
- `is_dead()` function exists in TWO files:
  - `lua/lonelog/parsers/combat.lua` (line 3)
  - `lua/lonelog/addons/combat/round.lua` (line 3)
  
  Both have identical logic (8 lines). A `TODO` comment was added to `round.lua` suggesting extraction if both paths ever become active in production simultaneously.

### Impact
- Files modified: 6
- Lines of code removed: ~14
- Lines of comments added: ~15
- Test files left in place: 3

### Testing
- All 22 test suites passing (0 failures)
- Test files for the marked-unused modules still pass
- No production API surface changed
