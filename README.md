<div align="center">

# lonelog.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=flat-square&logo=neovim)](https://neovim.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](/LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/Django0033/lonelog.nvim/ci.yml?style=flat-square)](https://github.com/Django0033/lonelog.nvim/actions)
![Lua](https://img.shields.io/badge/Lua-blue.svg?style=flat-square&logo=lua)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/Django0033/lonelog.nvim/pulls)

Solo tabletop RPG toolkit for Neovim — oracles, dice, structured notation, tags, scenes, and session management.

[Installation](#installation) • [Quick start](#quick-start) • [Configuration](#configuration) • [Add-ons](#add-ons) • [Commands](#commands) • [Documentation](#documentation)

</div>

lonelog.nvim implements the [Lonelog notation standard](https://github.com/valgur/lonelog) (v1.4.1), a structured markdown format for solo RPG session logs. All features are pure Lua — zero external dependencies.

> [!TIP]
> Open a `.md` file, press `<leader>lO` to roll an oracle, then `<leader>lM` to insert a scene marker. See `:help lonelog` for the full reference.

```markdown
### S1 *Entering the forest*
@ Follow the trail
? Is it safe?
d: 2d6+3 -> 9  [N:Elara|waiting]
=> The path is clear, but you hear wolves in the distance.
[E:Wolf Encounter 1/4]
```

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
> If you enable add-ons (combat, dungeon), add their commands to `cmd`:
> `"LonelogCombat"`, `"LonelogRound"`, `"LonelogDungeonStatus"`,
> `"LonelogRoomGo"`, `"LonelogRoomState"`. Or remove `cmd` entirely to load
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

Press `<leader>` followed by a key sequence to trigger actions. All keymaps
are customizable — set any to `false` to disable it (see [Configuration](#configuration)).

### Core actions

| Key | Action |
|-----|--------|
| `<leader>lO` | Roll an oracle (fate, binary, mythic) |
| `<leader>lD` | Interactive dice roller |
| `<leader>lR` | Roll dice/table on current line |
| `<leader>lT` | Browse all tags |
| `<leader>lS` | Browse all scenes |
| `<leader>lC` | Adjust Mythic chaos factor |
| `<leader>lI` | Insert last result from floating window |

### Session structure

| Key | Action |
|-----|--------|
| `<leader>lsh` | Insert session header with date |
| `<leader>lsc` | Insert campaign YAML header |
| `<leader>lsm` | Insert scene marker with auto-numbering |
| `<leader>lsn` | Insert narrative excerpt block |
| `<leader>lss` | Show or export session summary |
| `<leader>l[` / `<leader>l]` | Previous / next scene |

### Notation symbols (insert)

| Normal | Insert | Inserts | Description |
|--------|--------|---------|-------------|
| `<leader>lia` | `<C-l>a` | `@ ` | Action marker |
| `<leader>liq` | `<C-l>q` | `? ` | Oracle question |
| `<leader>lid` | `<C-l>d` | `d: ` | Dice prefix |
| `<leader>lin` | — | `(note:)` | Meta note |
| `<leader>li-` | `<C-l>-` | ` -> ` | Result arrow |
| `<leader>li=` | `<C-l>=` | `=> ` | Consequence |
| `<leader>liN` | `<C-l>N` | `@(Name) ` | Actor action |

### Entity tags

| Normal | Insert | Result |
|--------|--------|--------|
| `<leader>ltn` | `<C-l>n` | `[N:\|]` — NPC |
| `<leader>ltl` | `<C-l>l` | `[L:\|]` — Location |
| `<leader>ltp` | `<C-l>p` | `[PC:\|]` — Player character |
| `<leader>ltt` | `<C-l>h` | `[Thread:\|Open]` |
| `<leader>ltr` | `<C-l>r` | `[#N:\|]` — Reference |
| `<leader>ltf` | `<C-l>f` | `[F:\|]` — Foe |

### Progress elements

| Keymap | Element | Format |
|--------|---------|--------|
| `<leader>lpc` | Clock | `[E:Name 0/5]` |
| `<leader>lpt` | Track | `[Track:Name 0/5]` |
| `<leader>lpi` | Timer | `[Timer:Name 0]` |

---

## Configuration

```lua
require("lonelog").setup({
  use_telescope = "auto",            -- "auto" | true | false

  sidebar = { width = 50 },

  float = {
    border = "rounded",
    height = 0.4,                    -- fraction of editor height
    width  = 0.6,
  },

  oracle = {
    default_table = "fate",
    persist_chaos = true,
    chaos_file = "chaos_factor.json",
  },

  dice = {
    max_dice  = 100,
    max_sides = 1000,
  },

  prompt_for_scene_context = true,

  keymaps = { /* see :help lonelog-keymaps */ },
})
```

> [!TIP]
> Set any keymap to `false` to disable it, or to a string to rebind:
> ```lua
> keymaps = {
>   oracle = false,             -- disable
>   scene_marker = "<leader>z", -- rebind
> }
> ```

> [!TIP]
> Set `use_telescope = "auto"` (default) to use Telescope when installed,
> falling back to the native sidebar. Use `true` to require Telescope or
> `false` to always use the built-in sidebar.

---

## Add-ons

Add-ons provide optional features for combat and dungeon crawling. They are
bundled but disabled by default — enable the ones you need:

```lua
require("lonelog").setup({
  addons = {
    combat  = true,   -- combat blocks and round markers
    dungeon = true,   -- dungeon status, room navigation, room states
  },
})
```

When disabled, the add-on's commands and keymaps are not registered.

| Add-on | Commands | Features |
|--------|----------|----------|
| **Combat** | `:LonelogCombat`, `:LonelogRound` | `[COMBAT]` / `[/COMBAT]` delimiters, `R#` round markers, auto-roster that excludes dead combatants |
| **Dungeon** | `:LonelogDungeonStatus`, `:LonelogRoomGo`, `:LonelogRoomState` | Auto-collected room tags with ASCII exit map, navigation via picker, state toggling (cleared, looted, trapped, etc.) |

---

## Features

### Dice engine

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

```vim
:help lonelog-notation-dice
```

### Oracles

| Oracle | Outcomes | Command |
|--------|----------|---------|
| **Fate** | Exceptional Yes, Yes, Yes but..., Maybe, No but..., No, Exceptional No | `:LonelogOracle` |
| **Binary** | Yes / No (50/50) | `:LonelogOracle binary` |
| **Mythic** | 2d10 + chaos factor (1-9) | `:LonelogOracle mythic` |

```vim
:help lonelog-oracle
```

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

```vim
:help lonelog-notation
```

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
| `:LonelogCampaign` | Insert campaign YAML header |
| `:LonelogSessionSummary` | Show session summary |
| `:LonelogExportSummary` | Export session summary to file |
| `:LonelogTags` | Browse tags |
| `:LonelogScenes` | Browse scenes |
| `:LonelogRollLine` | Roll dice/table on current line |
| `:LonelogCompleteTag` | Trigger tag autocomplete |
| `:LonelogInsert` | Insert last result at cursor |
| `:LonelogChaos` | Open chaos factor UI |

**Add-on commands** (require the add-on to be enabled in `setup()`):

| Command | Add-on | Description |
|---------|--------|-------------|
| `:LonelogCombat` | combat | Insert `[COMBAT]` / `[/COMBAT]` block |
| `:LonelogRound` | combat | Insert round marker with optional roster |
| `:LonelogDungeonStatus` | dungeon | Insert/update dungeon status block |
| `:LonelogRoomGo` | dungeon | Navigate to a connected room |
| `:LonelogRoomState` | dungeon | Toggle room state |

```vim
:help lonelog-commands
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

-- Inline rolling
require("lonelog.roll_line").roll_current_line()

-- Tag completion
require("lonelog.completion").complete_tag()
```

```vim
:help lonelog-api
```

---

## Documentation

```vim
:help lonelog
```

The help file covers:
- All keymaps (normal, insert, floating window, sidebar)
- Notation format: tags, dice, scenes, tables, progress elements
- Oracle probabilities and chaos factor system
- Tag autocomplete with relevance sorting
- Floating window keybindings
- Add-on system configuration
- Session workflow tips
- 29 syntax highlight groups with overrides

## Requirements

- Neovim **0.8+** — requires `vim.ui.input`, `vim.ui.select`, `nvim_open_win`
- (Optional) [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for enhanced picker
- Zero external dependencies — pure Lua
