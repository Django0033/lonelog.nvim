# Modular Addon System

**Date:** 2026-06-01
**Requires:** everything (refactor of existing structure)

## Objective

Allow users to use only the core of `lonelog.nvim` and selectively enable
addons (Combat, Dungeon, etc.) via `setup()` config. Addons are bundled in the
same repo but only load their code, commands, and keymaps when enabled.

## Current State

Everything is loaded unconditionally:

```
plugin/lonelog.lua          586 lines — defines ALL commands and keymaps inline
lua/lonelog/commands/        12 files — all required at startup
```

A user who only wants dice + oracle + session tracking still gets combat blocks,
dungeon status, room navigation, and round markers loaded into memory with all
their keymaps registered.

## Target State

```
plugin/lonelog.lua          ~350 lines — core commands + addon loader loop
lua/lonelog/addons/          2 subdirectories — loaded only when enabled
```

Core is always loaded. Addons opt-in. Backward compatible (all addons enabled by
default).

## File Structure

### Before

```
lua/lonelog/
├── commands/
│   ├── campaign.lua          core
│   ├── combat.lua            ADDON: combat
│   ├── dungeon_status.lua    ADDON: dungeon
│   ├── multiline_tag.lua     core
│   ├── narrative.lua         core
│   ├── note.lua              core
│   ├── progress.lua          core
│   ├── room_nav.lua          ADDON: dungeon
│   ├── room_state.lua        ADDON: dungeon
│   ├── round.lua             ADDON: combat
│   ├── session.lua           core
│   └── summary.lua           core
├── dice.lua
├── oracle.lua
├── roll_line.lua
├── completion.lua
├── init.lua
├── config.lua
└── ui/
```

### After

```
lua/lonelog/
├── commands/                 CORE (always loaded)
│   ├── campaign.lua
│   ├── multiline_tag.lua
│   ├── narrative.lua
│   ├── note.lua
│   ├── progress.lua
│   ├── session.lua
│   └── summary.lua
├── addons/
│   ├── combat/               ADDON: combat (opt-in)
│   │   ├── init.lua          registration + re-exports
│   │   ├── combat.lua        moved from commands/
│   │   └── round.lua         moved from commands/
│   └── dungeon/              ADDON: dungeon (opt-in)
│       ├── init.lua          registration + re-exports
│       ├── dungeon_status.lua  moved from commands/
│       ├── room_nav.lua      moved from commands/
│       └── room_state.lua    moved from commands/
├── dice.lua
├── oracle.lua
├── roll_line.lua
├── completion.lua
├── init.lua
├── config.lua
└── ui/
```

Tests remain in `tests/` — internal `require` paths are updated to point to the
new locations.

## Addon Registration Interface

Each `addons/<name>/init.lua` returns a standard registration table:

```lua
return {
  name = "combat",
  description = "Combat blocks, round markers, auto-roster",

  commands = {
    {
      name = "LonelogCombat",
      command = function()
        require("lonelog.addons.combat.combat").insert_combat_block()
      end,
      opts = { desc = "Insert combat block" },
    },
    {
      name = "LonelogRound",
      command = function()
        require("lonelog.addons.combat.round").insert_round()
      end,
      opts = { desc = "Insert round marker" },
    },
  },

  keymaps = {
    { mode = "n", lhs = "<leader>lc", rhs = ":LonelogCombat<CR>",
      opts = { desc = "Insert combat block" } },
    { mode = "n", lhs = "<leader>lr", rhs = ":LonelogRound<CR>",
      opts = { desc = "Insert round marker" } },
  },

  requires = {},
  setup = function(addon_config) end,
}
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | `string` | yes | Unique addon identifier |
| `description` | `string` | yes | Human-readable description |
| `commands` | `table[]` | no | List of command definitions |
| `keymaps` | `table[]` | no | List of keymap definitions |
| `requires` | `string[]` | no | Addon names this depends on |
| `setup` | `function` | no | Called once at plugin init |

Each command entry is passed directly to `vim.api.nvim_create_user_command`:

```lua
{ name = "...", command = fn, opts = { desc = "...", bang = true, ... } }
```

Each keymap entry is passed directly to `vim.keymap.set`:

```lua
{ mode = "n", lhs = "...", rhs = "...", opts = { desc = "...", ... } }
```

## Config Changes

New optional `addons` field in `setup()`:

```lua
require("lonelog").setup({
  keymaps = { ... },    -- unchanged
  addons = {
    combat = true,      -- default: true, set false to disable
    dungeon = true,     -- default: true, set false to disable
  },
})
```

**Default behavior:** `config.lua` defines all bundled addons as enabled by
default. If the user does not specify `addons` in `setup()`, all addons load.
This is backward compatible — existing `setup()` calls continue to work
unchanged.

```lua
-- config.lua defaults (conceptual)
addons = {
  combat = true,
  dungeon = true,
}
```

**Explicit disable:** a user who wants minimal lonelog sets:

```lua
addons = {
  combat = false,
  dungeon = false,
}
```

**Future addons:** an `addons.resources = true` entry would enable the Resource
Tracking addon once implemented.

## plugin/lonelog.lua Refactor

### Current (586 lines)

The file does everything unconditionally:
1. Defines all `:Lonelog*` commands inline (session, campaign, narrative, note,
   combat, dungeon, round, room-nav, room-state, summary, etc.)
2. Defines all normal-mode keymaps inline
3. Defines template data (QUICK_DICE, ACTION_TEMPLATE)
4. Defines helpers (`do_insert_progress`)
5. Registers `TextChangedI` autocmd for completion

### Target (~350 lines)

1. Core commands/keymaps defined inline (session, campaign, narrative, note,
   multiline_tag, summary, progress)
2. Template data stays (QUICK_DICE, ACTION_TEMPLATE)
3. Helpers stay (`do_insert_progress`)
4. Autocmd stays
5. **Addon loader loop** — after core registration, iterates `config.addons`
   and loads each enabled addon's `init.lua`:

```lua
-- plugin/lonelog.lua (conceptual)
local config = require("lonelog.config").get()

-- 1. Core commands (always)
vim.api.nvim_create_user_command("LonelogSession", ...)
vim.api.nvim_create_user_command("LonelogCampaign", ...)
-- ... etc

-- 2. Core keymaps (always)
vim.keymap.set("n", "<leader>ls", ":LonelogSession<CR>", ...)
-- ... etc

-- 3. Addon loader
local addons_config = config.addons or {}
for name, enabled in pairs(addons_config) do
  if enabled then
    local ok, addon = pcall(require, "lonelog.addons." .. name)
    if ok and addon then
      for _, cmd in ipairs(addon.commands or {}) do
        vim.api.nvim_create_user_command(cmd.name, cmd.command, cmd.opts)
      end
      for _, km in ipairs(addon.keymaps or {}) do
        vim.keymap.set(km.mode, km.lhs, km.rhs, km.opts)
      end
      if addon.setup then
        addon.setup(addons_config[name] or {})
      end
    end
  end
end
```

### Code removed from plugin/lonelog.lua

The following move into `addons/combat/init.lua` and
`addons/dungeon/init.lua`:

**Combat addon:**
- `:LonelogCombat` command definition
- `:LonelogRound` command definition
- `<leader>lc` keymap (Insert combat block)
- `<leader>lr` keymap (Insert round marker)

**Dungeon addon:**
- `:LonelogDungeonStatus` command definition
- `:LonelogRoomGo` command definition
- `:LonelogRoomState` command definition
- `<leader>lK` keymap (Insert dungeon status)
- `<leader>lg` keymap (Go to room)
- `<leader>lR` keymap (Toggle room state)

## Migration

### Internal requires

All internal `require("lonelog.commands.*")` calls are updated to point to the
new addon paths. Specifically:

| Old path | New path |
|----------|----------|
| `lonelog.commands.combat` | `lonelog.addons.combat.combat` |
| `lonelog.commands.round` | `lonelog.addons.combat.round` |
| `lonelog.commands.dungeon_status` | `lonelog.addons.dungeon.dungeon_status` |
| `lonelog.commands.room_nav` | `lonelog.addons.dungeon.room_nav` |
| `lonelog.commands.room_state` | `lonelog.addons.dungeon.room_state` |

Core commands (`campaign`, `multiline_tag`, `narrative`, `note`, `progress`,
`session`, `summary`) stay at `lonelog.commands.*`.

### Where these requires appear

- `plugin/lonelog.lua` — addon commands are now registered via the registration
  table, not by direct require. Remove the direct requires for addon modules.
- `tests/test_combat.lua` — update require paths
- `tests/test_round.lua` — update require paths
- `tests/test_dungeon_status.lua` — update require paths
- `tests/test_room_nav.lua` — update require paths
- `tests/test_room_state.lua` — update require paths

### Public API

No changes. All `:Lonelog*` commands keep their names. All keymaps keep their
default bindings. `require("lonelog").setup()` keeps its signature. The public
API exported by `init.lua` (`M.dice`, `M.oracle`, `M.ui`, etc.) is unchanged.

### Config

Existing `setup()` calls without `addons` field continue to work. All addons are
enabled by default. No config migration needed.

## Testing

### Tests to update (require paths only)

| Test file | Requires changed |
|-----------|------------------|
| `tests/test_combat.lua` | `lonelog.commands.combat` → `lonelog.addons.combat.combat` |
| `tests/test_round.lua` | `lonelog.commands.round` → `lonelog.addons.combat.round` |
| `tests/test_dungeon_status.lua` | `lonelog.commands.dungeon_status` → `lonelog.addons.dungeon.dungeon_status` |
| `tests/test_room_nav.lua` | `lonelog.commands.room_nav` → `lonelog.addons.dungeon.room_nav` |
| `tests/test_room_state.lua` | `lonelog.commands.room_state` → `lonelog.addons.dungeon.room_state` |

### Tests to add

**`tests/test_addon_loader.lua`** (~15 tests):
- Loader skips nil addon config gracefully
- Loader skips false addon config gracefully
- Loader registers commands from a mock addon registration table
- Loader registers keymaps from a mock addon registration table
- Loader calls setup() on the addon
- Loader handles missing addon module gracefully (pcall)
- Core commands always registered regardless of addon config
- Core keymaps always registered regardless of addon config

Note: These tests require a Neovim instance for `vim.api.nvim_create_user_command`
and `vim.keymap.set`, so they should run only when `vim.in_fast_each()` test
environment or via a `--headless` Neovim test runner.

### Existing tests

All 17 existing test files must continue to pass. Total test count after
changes: ~390 (17 existing files + 1 new file).

## YAGNI

The following are explicitly out of scope:

- **External/community addons** — no third-party addon discovery system. This
  design only supports bundled addons. When external addons become desired, a
  separate spec should cover RTP scanning.
- **Resource Tracking addon** — not implemented yet. The `addons/resources/`
  directory is reserved for future work.
- **Per-addon config** — no per-addon `setup({combat = {opt = val}})` nesting.
  Each addon receives its own config value (`true`/`false` or a table), but the
  addon defines its own options. This is deferred until needed.
- **Addon hooks/events** — no `LonelogAddonLoaded` autocmd or callback system.
- **Dynamic enable/disable** — no runtime toggling of addons. Addons are
  determined at `setup()` time.
- **Refactoring core modules** — no movement of `dice.lua`, `oracle.lua`,
  `roll_line.lua`, `completion.lua`, `ui/`, `parsers/`, or `init.lua`/`config.lua`.
  Only `commands/` addon modules move.
- **SPEC.md / DEVLOG.md update** — deferred to a separate docs pass.
