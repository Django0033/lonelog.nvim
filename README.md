<div align="center">

# lonelog.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=flat-square&logo=neovim)](https://neovim.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](/LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/Django0033/lonelog.nvim/ci.yml?style=flat-square)](https://github.com/Django0033/lonelog.nvim/actions)
![Lua](https://img.shields.io/badge/Lua-blue.svg?style=flat-square&logo=lua)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/Django0033/lonelog.nvim/pulls)

Solo tabletop RPG toolkit for Neovim — oracles, dice, structured notation, session management, and add-ons.

[Install](#installation) • [Quick start](#quick-start) • [Configuration](#configuration) • [Addon system](#addon-system) • [Commands](#commands) • [API](#api) • [:help](#documentation)

</div>

This plugin implements the [Lonelog notation standard](https://github.com/valgur/lonelog) (v1.4.1), a structured markdown format for solo RPG session logs. All features are pure Lua — zero external dependencies.

> [!TIP]
> After installing, open a `.md` file and run `:Lonelog` to get started. See `:help lonelog` for the full reference.

---

## Features

### Core

| | |
|---|---|
| **Dice engine** | `2d6+3`, `2d20kh1` (advantage), `4d6!` (exploding), `6d6>>4` (success counting), `2d6>7` (sum vs target). Configurable safety limits |
| **Oracles** | Fate (7 weighted outcomes), Binary (50/50), Mythic (2d10 + chaos factor). Persistent chaos factor with +/- UI |
| **Tag management** | NPCs `[N:]`, Locations `[L:]`, PCs `[PC:]`, Threads `[Thread:]`, Foes `[F:]`, Rooms `[R:]`, Inventory `[Inv:]`. Browse, filter, jump |
| **Tag autocomplete** | Suggestions when typing `[TYPE:` with relevance sorting. Triggered on `TextChangedI` |
| **Scene navigation** | Main scenes `S1`, flashbacks `S5a`, sub-scenes `S7.1`, thread scenes `T1-S5`. Chronological ordering, prev/next commands |
| **Inline tables** | Define tables with range entries or bracket shorthand `[A, B, C]`. Roll directly on the line |
| **Generator blocks** | Batch-process indented sub-lines under a `gen:` header |
| **Inline rolling** | `d:`, `tbl:`, `label:`, bare dice. Single line or visual selection |
| **Progress elements** | Clocks, tracks, timers with smart insert-or-increment logic |
| **Session headers** | Auto-numbered `## Session N` with date, Recap, Goals |
| **Scene markers** | Auto-numbered `### S3 *context*` with smart ID progression |
| **Campaign YAML** | Structured frontmatter with title, ruleset, genre, dates, themes |
| **Session summary** | Per-session stats: scenes, tags, notation, progress, dice. Export to markdown |
| **Floating results** | Colored windows with copy, paste, and insert-last result |

### Add-ons (opt-in)

Add-ons are bundled with the plugin but disabled by default. Enable them in
`setup()` to load their commands and keymaps.

| Add-on | Features | Enables |
|--------|----------|---------|
| **Combat** | `[COMBAT]` / `[/COMBAT]` tactical encounter delimiters. Auto-numbered `R#` round markers with auto-roster that excludes dead combatants | `:LonelogCombat`, `:LonelogRound` |
| **Dungeon** | `=== Dungeon Status ===` block with auto-collected room tags and ASCII exit map. Room navigation via exit picker. Room state toggling (cleared, looted, trapped, etc.) | `:LonelogDungeonStatus`, `:LonelogRoomGo`, `:LonelogRoomState` |

### Syntax highlighting

29 highlight groups covering all Lonelog elements: tags, dice notation, scenes, dialogue, progress elements, narrative blocks, and more. Loaded automatically in markdown buffers.

---

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

> [!NOTE]
> If you enable add-ons, add their commands to the `cmd` list for lazy loading:
> `"LonelogCombat"`, `"LonelogDungeonStatus"`, `"LonelogRoomGo"`,
> `"LonelogRoomState"`, `"LonelogRound"`. Or remove `cmd` entirely to load
> everything at startup.

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
<summary><strong>vim-pack (built-in)</strong></summary>

```bash
git clone https://github.com/Django0033/lonelog.nvim.git \
  ~/.local/share/nvim/site/pack/plugins/start/lonelog.nvim
```

```lua
-- init.lua
require("lonelog").setup()
```

</details>

---

## Quick start

| Key | Action |
|-----|--------|
| `<leader>lO` | Roll an oracle (fate, binary, mythic) |
| `<leader>lD` | Interactive dice roller |
| `<leader>lR` | Roll dice/table on current line |
| `<leader>lM` | Insert scene marker with auto-numbering |
| `<leader>lE` | Show session summary / export |
| `<leader>lH` | Insert session header |
| `<leader>lT` | Browse all Lonelog tags |
| `<leader>lS` | Browse all scenes |
| `<leader>lC` | Adjust Mythic chaos factor |

See `:help lonelog-keymaps` for the complete keymap reference.

---

## Configuration

`require("lonelog").setup(opts)` — all keys optional, defaults shown:

```lua
require("lonelog").setup({
  use_telescope = "auto",            -- "auto" | true | false

  sidebar = { width = 50 },

  float = {
    border = "rounded",
    height = 0.4,                   -- fraction of editor height
    width  = 0.6,
  },

  oracle = {
    default_table = "fate",
    persist_chaos = true,
    chaos_file = "chaos_factor.json",
  },

  dice = {
    max_dice  = 100,                -- safety limits
    max_sides = 1000,
  },

  prompt_for_scene_context = true,

  keymaps = { /* see :help lonelog-keymaps */ },

> [!TIP]
> Set any keymap to `false` to disable it without overriding:
> ```lua
> keymaps = { oracle = false }  -- disable oracle keymap
> ```
> Set it to a string to rebind:
> ```lua
> keymaps = { oracle = "<leader>zo" }
> ```
})
```

### Add-ons

Add-ons are disabled by default. Enable the ones you want:

```lua
require("lonelog").setup({
  addons = {
    combat  = true,   -- enable combat blocks and round markers
    dungeon = true,   -- enable dungeon status and room features
  },
})
```

> [!TIP]
> Set `use_telescope = "auto"` (default) to use Telescope when installed,
> falling back to the native sidebar. Use `true` to require Telescope or
> `false` to always use the sidebar.

---

## Commands

| Command | Description |
|---------|-------------|
| `:Lonelog` | Open main action picker |
| `:LonelogOracle [table]` | Roll oracle (fate/binary/mythic) |
| `:LonelogDice` | Interactive dice roller |
| `:LonelogDiceRoll <notation>` | Roll specific dice notation |
| `:LonelogD4` — `:LonelogD100` | Quick roll 1dN |
| `:LonelogSymbol <symbol>` | Insert notation symbol |
| `:LonelogActionSequence` | Insert 3-line action template |
| `:LonelogOracleSequence` | Insert 3-line oracle template |
| `:LonelogTag <type>` | Insert tag snippet |
| `:LonelogMultiTag <type>` | Insert multi-line tag |
| `:LonelogInsertClock [name]` | Insert or increment clock |
| `:LonelogInsertTrack [name]` | Insert or increment track |
| `:LonelogInsertTimer [name]` | Insert or decrement timer |
| `:LonelogSceneMarker` | Insert auto-numbered scene |
| `:LonelogScenePrev` / `:LonelogSceneNext` | Scene navigation |
| `:LonelogSession` | Insert session header |
| `:LonelogNarrative` | Insert narrative excerpt block |
| `:LonelogNote` | Insert meta note |
| `:LonelogCampaign` | Insert campaign header |
| `:LonelogSessionSummary` | Show session summary |
| `:LonelogExportSummary` | Export session summary to file |
| `:LonelogTags` | Browse tags |
| `:LonelogScenes` | Browse scenes |
| `:LonelogRollLine` | Roll dice/table on current line |
| `:LonelogCompleteTag` | Trigger tag autocomplete |
| `:LonelogInsert` | Insert last result at cursor |
| `:LonelogChaos` | Open chaos factor UI |

**Add-on commands** (enable the add-on in `setup()` to use them):

| Command | Add-on | Description |
|---------|--------|-------------|
| `:LonelogCombat` | combat | Insert `[COMBAT]` / `[/COMBAT]` block |
| `:LonelogRound` | combat | Insert round marker with optional roster |
| `:LonelogDungeonStatus` | dungeon | Insert/update dungeon status block with ASCII map |
| `:LonelogRoomGo` | dungeon | Navigate to a connected room |
| `:LonelogRoomState` | dungeon | Toggle room state |

---

## Dice notation

| Notation | Example | Description |
|----------|---------|-------------|
| `NdN` | `1d20` | Basic roll |
| `NdN+M` | `2d6+3` | With modifier |
| `NdN-M` | `1d20-2` | Subtract modifier |
| `NdN!` | `4d6!` | Exploding dice (reroll max) |
| `NdNkhK` | `2d20kh1` | Advantage (keep highest) |
| `NdNklK` | `2d20kl1` | Disadvantage (keep lowest) |
| `NdN>>T` | `6d6>>4` | Success counting |
| `NdN>T` | `2d6>7` | Sum vs target |

---

## Oracles

| Oracle | Outcomes | Command |
|--------|----------|---------|
| Fate | Exceptional Yes, Yes, Yes but..., Maybe, No but..., No, Exceptional No | `:LonelogOracle` |
| Binary | Yes / No (50/50) | `:LonelogOracle binary` |
| Mythic | 2d10 + chaos factor (1-9) | `:LonelogOracle mythic` |

Results display in colored floating windows.

---

## Tags and notation

### Tags

```
[N:Jonah|friendly|wounded]           — NPC
[L:Library|dark|quiet]               — Location
[PC:Alex|HP 8]                       — Player character
[Thread:Main Quest|Open]             — Thread/quest
[E:Alert 2/6]                        — Event clock
[F:Matón|HP 6|alerta]                — Foe
[R:3|cleared|library]                — Room
[Inv:Torch|3]                        — Inventory
[R:3|cleared,trapped|cavern|exits N:R1]  — Room with exits
```

### Scene markers

```
### S1 *Lighthouse tower*
### S5a *Flashback: Father's workshop*
### S7.1 *Day 1: Forest*
### T1-S5 *Thread scene*
```

### Inline tables & generators

```markdown
tbl: Forest Encounter (d6)
  1-3: Nothing happens
  4-5: A deer crosses
  6: Bandit ambush!

tbl: Weather [Sunny, Cloudy, Rain, Storm]

gen: Generate NPC
  Appearance: d3
  Personality: d6
  tbl: Equipment (d6)
```

---

## API

```lua
local ln = require("lonelog")

-- Dice
local result, err = ln.dice.roll("2d6+3")
print(result.display)     -- "2d6+3[4, 2] = 9"
print(result.total)       -- 9

-- Oracle
local oracle = ln.oracle.roll("fate")
print(oracle.display)     -- "Yes, but..."

-- Chaos factor
ln.oracle.get_chaos()     -- number (1-9)
ln.oracle.set_chaos(7)    -- boolean

-- Parsers
local tags   = ln.parsers.parse_tags()
local scenes = ln.parsers.parse_scenes()
local summary = ln.parsers.tags_summary(tags)

-- Inline rolling
local modified = require("lonelog.roll_line").process_line(line, tbls)
require("lonelog.roll_line").roll_current_line()

-- Tag completion
local comp = require("lonelog.completion")
comp.refresh_completions()
comp.complete_tag()
```

---

## Documentation

For the complete reference, run:

```vim
:help lonelog
```

The help file covers:
- All keymaps (normal, insert, floating window, sidebar)
- Notation format: tags, dice, scenes, tables, progress elements
- Oracle probabilities and chaos factor system
- Tag autocomplete and completion sorting
- Floating window keybindings
- Add-on system configuration
- Session workflow tips
- 29 syntax highlight groups with overrides

## Requirements

- Neovim **0.8+** — requires `vim.ui.input`, `vim.ui.select`, `nvim_open_win`
- (Optional) [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for enhanced picker
- Zero external dependencies — pure Lua
