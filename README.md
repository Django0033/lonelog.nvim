<div align="center">

# lonelog.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=flat-square&logo=neovim)](https://neovim.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](/LICENSE)
[![Lua](https://img.shields.io/badge/Lua-blue.svg?style=flat-square&logo=lua)](https://www.lua.org)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/Django0033/lonelog.nvim/pulls)

Solo tabletop RPG toolkit for Neovim — oracles, dice, notation, and session management.

[Features](#features) • [Quick start](#quick-start) • [Installation](#installation) • [Configuration](#configuration) • [Documentation](#documentation)

</div>

lonelog.nvim implements the [Lonelog notation standard](https://github.com/valgur/lonelog) (v1.4.1), a structured markdown format for solo RPG session logs. All features are pure Lua with zero external dependencies.

```markdown
## Session 5

### S1 *The abandoned mine*
@ Enter the darkness
? Is anyone here?
d: 2d6+3[4, 2] = 10  => The tunnel is empty, but torchlight flickers ahead.
[E:Torch 3/6]

### S2 *Collapsed passage*
d: 1d20>=15[17] = 17 >= 15 -> Success
[F:Goblin|HP 6|alert]
```

Press `<leader>lR` on any `d:` line to roll and replace the result in-place.

> [!TIP]
> Open a `.md` file, press `<leader>lO` to roll an oracle, then `<leader>lsm` to insert a scene marker.

## Features

**Dice engine** — Standard notation (`2d6+3`), advantage (`2d20kh1`), exploding (`4d6!`), success counting (`6d6>>4`), Fate dice (`4df`), comparison operators (`>=`, `<=`, `vs`), and multi-roll on one line.

**Oracle system** — Fate (7 weighted outcomes), Binary (50/50), and Mythic (2d10 + chaos factor) oracles with persistent chaos factor and interactive adjustment.

**Tag navigation** — Browse tags by type (NPCs, locations, PCs, threads, foes, inventory, rooms) with search filtering in the native browser. Jump to any tag's line instantly.

**Scene navigation** — Navigate main scenes, flashbacks, sub-scenes, and thread scenes. Auto-numbering for scene markers.

**Progress elements** — Insert and increment clocks (`[E:Name 0/5]`), tracks (`[Track:Name 0/5]`), and timers (`[Timer:Name 0]`) with smart auto-increment.

**Session management** — Auto-numbered session headers, campaign YAML frontmatter with auto-updating dates, and a session summary with scene/tag/dice breakdown and oracle result distribution.

**Inline rolling** — Roll dice, resolve table lookups, and process generator blocks directly on the current line with a single keypress.

**Tag autocomplete** — Automatic name completion when editing tags, with relevance-based sorting.

**Add-on system** — Optional modules for combat blocks with round markers, dungeon status with room state editor and ASCII maps, and resource tracking with supply dice and slot-based inventory.

**Telescope integration** — Auto-detected; falls back to a built-in vertical split browser with search filtering when Telescope is not available.

**Zero dependencies** — Pure Lua, requires only Neovim 0.8+.

## Quick start

Press `<leader>` followed by these keys:

### Core

| Key | Action |
|-----|--------|
| `<leader>lO` | Roll an oracle |
| `<leader>lD` | Interactive dice roller |
| `<leader>lR` | Roll current line |
| `<leader>lT` | Browse tags (with search in native browser) |
| `<leader>lS` | Browse scenes |
| `<leader>lC` | Adjust chaos factor |
| `<leader>lI` | Insert last result |

### Session

| Key | Action |
|-----|--------|
| `<leader>lsh` | Insert session header |
| `<leader>lsc` | Insert campaign header |
| `<leader>lsm` | Insert scene marker |
| `<leader>lsn` | Insert narrative block |
| `<leader>lss` | Show session summary |
| `<leader>l[` / `<leader>l]` | Previous / next scene |

### Notation

| Normal | Insert | Inserts |
|--------|--------|---------|
| `<leader>lia` | `<C-l>a` | `@ ` — action |
| `<leader>liq` | `<C-l>q` | `? ` — question |
| `<leader>lid` | `<C-l>d` | `d: ` — dice |
| `<leader>liN` | `<C-l>N` | `@(Name) ` — actor |

### Entity tags

| Normal | Insert | Tag |
|--------|--------|-----|
| `<leader>ltn` | `<C-l>n` | `[N:\|]` — NPC |
| `<leader>ltl` | `<C-l>l` | `[L:\|]` — Location |
| `<leader>ltp` | `<C-l>p` | `[PC:\|]` — PC |
| `<leader>ltt` | `<C-l>h` | `[Thread:\|Open]` |
| `<leader>ltr` | `<C-l>r` | `[#N:\|]` — Reference |
| `<leader>ltf` | `<C-l>f` | `[F:\|]` — Foe |
| `<leader>ltm` | — | `[R:\|]` — Room |
| `<leader>lti` | — | `[Inv:\|]` — Inventory |
| `<leader>ltw` | — | `[Wealth:Gold 0]` |

### Progress

| Key | Element | Format |
|-----|---------|--------|
| `<leader>lpc` | Clock | `[E:Name 0/5]` |
| `<leader>lpt` | Track | `[Track:Name 0/5]` |
| `<leader>lpi` | Timer | `[Timer:Name 0]` |

### Session summary

| Key | Action |
|-----|--------|
| `<leader>lss` | Show session overview |

The summary includes:
- Scenes list with context
- Tags grouped by type (NPCs, locations, threads, etc.)
- Notation counts (actions, questions, dice, notes, dialogues)
- Progress elements (clocks, tracks, timers)
- Dice breakdown by notation type (counts, sums, averages per notation)
- Oracle result distribution

See `:help lonelog-keymaps` for the complete keymap reference (45+ keymaps).

## Installation

<details open>
<summary><strong>lazy.nvim</strong></summary>

```lua
{
  "Django0033/lonelog.nvim",
  cmd = { "Lonelog", "LonelogOracle", "LonelogDice", "LonelogTags",
          "LonelogScenes", "LonelogRollLine" },
  config = function()
    require("lonelog").setup()
  end,
}
```

> If you enable add-ons, add their commands to `cmd`: `"LonelogCombat"`,
> `"LonelogRound"`, `"LonelogDungeonStatus"`, `"LonelogRoomGo"`,
> `"LonelogRoomState"`, `"LonelogResourcesBlock"`, `"LonelogSupplyRoll"`,
> `"LonelogWealthDelta"`, `"LonelogInvDelta"`, `"LonelogItemState"`,
> `"LonelogSlotInsert"`, `"LonelogSlotSummary"`.

</details>

<details>
<summary><strong>packer.nvim</strong></summary>

```lua
use {
  "Django0033/lonelog.nvim",
  config = function()
    require("lonelog").setup()
  end,
}
```

</details>

<details>
<summary><strong>vim.pack.add (Neovim 0.11+)</strong></summary>

```lua
-- init.lua
vim.pack.add({ 'https://github.com/Django0033/lonelog.nvim' })
require("lonelog").setup()
```

</details>

<details>
<summary><strong>git clone (built-in)</strong></summary>

```bash
git clone https://github.com/Django0033/lonelog.nvim.git \
  ~/.local/share/nvim/site/pack/plugins/start/lonelog.nvim
```

```lua
require("lonelog").setup()
```

</details>

## Configuration

```lua
require("lonelog").setup({
  use_telescope = "auto",         -- "auto" | true | false
  sidebar = { width = 50 },
  float = { border = "rounded", height = 0.4, width = 0.6 },
  oracle = { default_table = "fate", persist_chaos = true, custom_tables = {} },
  dice = { max_dice = 100, max_sides = 1000 },
  prompt_for_scene_context = true,
  keymaps = { /* see :help lonelog-keymaps */ },
  highlight = {
    lonelogAction = { fg = "#ff6600", bold = true },
  },
  campaign = {
    default_ruleset = "",
    default_genre = "",
    default_player = "",
  },
  addons = {
    combat = false,
    dungeon = false,
    resources = false,
  },
})
```

> [!TIP]
> Define custom oracle tables with weighted or equal-probability entries:
> ```lua
> oracle = {
>   custom_tables = {
>     Weather = { "Sunny", "Cloudy", "Rain" },        -- equal weight
>     NPC_Reaction = { Hostile = 1, Neutral = 2, Friendly = 1 },  -- weighted
>   },
> }
> ```
> They appear in the `:LonelogOracle` picker alongside the built-in tables.

> [!TIP]
> Set `use_telescope = "auto"` (default) to use Telescope when installed.
> When Telescope is not available, a vertical split browser with search
> filtering is used for tag and scene navigation. Other pickers (oracles,
> main menu) fall back to the native sidebar.

> [!TIP]
> Disable or rebind any keymap:
> ```lua
> keymaps = {
>   oracle = false,             -- disable entirely
>   scene_marker = "<leader>z", -- rebind
> }
> ```

## Add-ons

Bundled but disabled by default. Enable the ones you need:

```lua
require("lonelog").setup({
  addons = {
    combat  = true,   -- [COMBAT] blocks, round markers, auto-roster
    dungeon = true,   -- dungeon status, room nav, room state editor
    resources = true, -- inventory, wealth, supply dice, resources block
  },
})
```

### Combat add-on keymaps

| Key | Action |
|-----|--------|
| `<leader>lxc` | Insert `[COMBAT]` block |
| `<leader>lxv` | Show combat status overview |
| `<leader>lxr` | Insert round marker |

### Dungeon add-on keymaps

| Key | Action |
|-----|--------|
| `<leader>lxd` | Insert/update dungeon status block |
| `<leader>lxg` | Navigate to connected room |
| `<leader>lxs` | Toggle room state |

### Resources add-on keymaps

| Key | Action |
|-----|--------|
| `<leader>lrr` | Insert resources status block |
| `<leader>lwd` | Add/subtract wealth |
| `<leader>lwi` | Add/subtract inventory |
| `<leader>lws` | Change item properties |
| `<leader>lts` | Insert inventory slot |

## Dice notation

| Notation | Example | Description |
|----------|---------|-------------|
| `NdN` | `1d20` | Basic roll |
| `NdN+M` | `2d6+3` | Add modifier |
| `NdN-M` | `1d20-2` | Subtract modifier |
| `NdN!` | `4d6!` | Exploding dice |
| `NdNkhK` | `2d20kh1` | Keep highest |
| `NdNklK` | `2d20kl1` | Keep lowest |
| `NdN>>T` | `6d6>>4` | Success counting |
| `4df` | `4df` | Fate dice (+, 0, -) |
| `NdN>=T` | `1d20>=15` | Greater-or-equal |
| `NdN<=T` | `1d20<=10` | Less-or-equal |
| `NdN vs T` | `1d100 vs 50` | Versus (alias for >=) |
| `NdN>T` | `2d6>7` | Sum vs target |
| `d: 2d6, 1d8` | — | Multiple rolls on one line |

## Commands

| Command | Description |
|---------|-------------|
| `:Lonelog` | Main action picker |
| `:LonelogOracle [table]` | Roll oracle |
| `:LonelogDiceRoll <notation>` | Roll specific dice |
| `:LonelogRollLine` | Roll current line |
| `:LonelogTags` | Browse tags (with search in native browser) |
| `:LonelogScenes` | Browse scenes |
| `:LonelogSessionSummary` | Show session overview with roll stats |
| `:LonelogExportSummary` | Export summary to markdown file |
| `:LonelogCombatStatus` | Show combat status (requires add-on) |
| `:LonelogSession` / `:LonelogCampaign` | Insert headers |

See `:help lonelog-commands` for the full list (30+ commands).

## Documentation

```vim
:help lonelog
```

Covers all keymaps, notation format, oracle probabilities, tag autocomplete, syntax highlighting, add-on configuration, and session workflow tips.

## Requirements

- Neovim **0.8+** — requires `vim.ui.input`, `vim.ui.select`, `nvim_open_win`
- (Optional) [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for enhanced picker
- Zero external dependencies — pure Lua
