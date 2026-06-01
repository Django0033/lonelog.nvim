<div align="center">

# lonelog.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=flat-square&logo=neovim)](https://neovim.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](/LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/Django0033/lonelog.nvim/ci.yml?style=flat-square)](https://github.com/Django0033/lonelog.nvim/actions)
![Lua](https://img.shields.io/badge/Lua-blue.svg?style=flat-square&logo=lua)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/Django0033/lonelog.nvim/pulls)

Solo tabletop RPG toolkit for Neovim — oracles, dice, tags, scenes, and session management.

[Installation](#installation) • [Quick start](#quick-start) • [Configuration](#configuration) • [Add-ons](#add-ons) • [Documentation](#documentation)

</div>

lonelog.nvim implements the [Lonelog notation standard](https://github.com/valgur/lonelog) (v1.4.1), a structured markdown format for solo RPG session logs. All features are pure Lua with zero external dependencies.

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

## Features

| | |
|---|---|
| **Dice engine** | `2d6+3`, `2d20kh1` (advantage), `4d6!` (exploding), `6d6>>4` (success counting), `2d6>7` (sum vs target), `>=`, `<=`, `vs` operators. Configurable safety limits |
| **Oracles** | Fate (7 weighted outcomes), Binary (50/50), Mythic (2d10 + chaos factor). Persistent chaos factor with +/- UI |
| **Tag management** | NPCs `[N:]`, Locations `[L:]`, PCs `[PC:]`, Threads `[Thread:]`, Foes `[F:]`, Rooms `[R:]`, Inventory `[Inv:]`. Browse, filter, jump to line |
| **Scene navigation** | Main scenes `S1`, flashbacks `S5a`, sub-scenes `S7.1`, thread scenes `T1-S5`. Chronological ordering with prev/next commands |
| **Inline tables & generators** | Range tables, bracket shorthand `[A, B, C]`, generator blocks with `gen:` header. Roll with `<leader>lR` |
| **Progress elements** | Clocks, tracks, timers with smart insert-or-increment. If the tag exists and is incomplete, it increments; if complete or missing, a fresh one is inserted |
| **Tag autocomplete** | Suggestions when typing `[TYPE:` with relevance sorting. Triggered on `TextChangedI` |
| **Floating results** | Colored windows with copy, paste, and insert-last result |
| **Syntax highlighting** | 29 highlight groups for all Lonelog elements, loaded automatically in markdown buffers |
| **Telescope integration** | Optional, auto-detected. Falls back to native sidebar |

**Add-ons** (disabled by default, enable via config):

| Add-on | Features |
|--------|----------|
| **Combat** | `[COMBAT]` / `[/COMBAT]` blocks, `R#` round markers, auto-roster that excludes dead combatants |
| **Dungeon** | `=== Dungeon Status ===` block with ASCII exit map, room navigation via picker, state toggling (cleared, looted, trapped, etc.) |

---

## Quick start

Press `<leader>` followed by a key sequence. All keymaps are customizable.

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

### Insert notation

| Normal | Insert | Inserts |
|--------|--------|---------|
| `<leader>lia` | `<C-l>a` | `@ ` — action marker |
| `<leader>liq` | `<C-l>q` | `? ` — oracle question |
| `<leader>lid` | `<C-l>d` | `d: ` — dice prefix |
| `<leader>lin` | — | `(note:)` — meta note |
| `<leader>li-` | `<C-l>-` | ` -> ` — result arrow |
| `<leader>li=` | `<C-l>=` | `=> ` — consequence |
| `<leader>liN` | `<C-l>N` | `@(Name) ` — actor action |

### Entity tags

| Normal | Insert | Result |
|--------|--------|--------|
| `<leader>ltn` | `<C-l>n` | `[N:\|]` — NPC |
| `<leader>ltl` | `<C-l>l` | `[L:\|]` — Location |
| `<leader>ltp` | `<C-l>p` | `[PC:\|]` — Player character |
| `<leader>ltt` | `<C-l>h` | `[Thread:\|Open]` |
| `<leader>ltr` | `<C-l>r` | `[#N:\|]` — Reference |
| `<leader>ltf` | `<C-l>f` | `[F:\|]` — Foe |

### Progress

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
    height = 0.4,
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
> Disable or rebind any keymap:
> ```lua
> keymaps = {
>   oracle = false,             -- disable entirely
>   scene_marker = "<leader>z", -- rebind to different key
> }
> ```

## Add-ons

Add-ons are bundled but disabled by default. Enable them in `setup()`:

```lua
require("lonelog").setup({
  addons = {
    combat  = true,   -- combat blocks and round markers
    dungeon = true,   -- dungeon status, room navigation, room states
  },
})
```

---

## Commands

| Command | Description |
|---------|-------------|
| `:Lonelog` | Open main action picker |
| `:LonelogOracle [table]` | Roll oracle |
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
| `:LonelogNarrative` | Insert narrative excerpt |
| `:LonelogNote` | Insert meta note |
| `:LonelogCampaign` | Insert campaign YAML |
| `:LonelogSessionSummary` | Show session summary |
| `:LonelogExportSummary` | Export session summary |
| `:LonelogTags` | Browse tags |
| `:LonelogScenes` | Browse scenes |
| `:LonelogRollLine` | Roll dice/table on current line |
| `:LonelogCompleteTag` | Trigger tag autocomplete |
| `:LonelogInsert` | Insert last result |
| `:LonelogChaos` | Open chaos factor UI |

**Add-on commands** (require the add-on to be enabled):

| Command | Add-on | Description |
|---------|--------|-------------|
| `:LonelogCombat` | combat | Insert `[COMBAT]` / `[/COMBAT]` |
| `:LonelogRound` | combat | Insert round marker with roster |
| `:LonelogDungeonStatus` | dungeon | Insert/update dungeon status |
| `:LonelogRoomGo` | dungeon | Navigate to a room |
| `:LonelogRoomState` | dungeon | Toggle room state |

---

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
| `NdN>=T` | `1d20>=15` | Greater-or-equal |
| `NdN<=T` | `1d20<=10` | Less-or-equal |
| `NdN vs T` | `1d100 vs 50` | Versus (alias for `>=`) |
| `NdN>T` | `2d6>7` | Sum vs target |

## API

```lua
local ln = require("lonelog")

-- Dice
local result, err = ln.dice.roll("2d6+3")
print(result.display)    -- "2d6+3[4, 2] = 9"
print(result.total)      -- 9

-- Oracle
local oracle = ln.oracle.roll("fate")
print(oracle.display)    -- "Yes, but..."

-- Chaos factor
ln.oracle.get_chaos()    -- number (1-9)
ln.oracle.set_chaos(7)

-- Parsers
local tags   = ln.parsers.parse_tags()
local scenes = ln.parsers.parse_scenes()
```

---

## Documentation

```vim
:help lonelog
```

The help file covers all keymaps, notation format, oracle probabilities, tag autocomplete, floating window keybindings, add-on configuration, syntax highlighting, and session workflow tips.

## Requirements

- Neovim **0.8+** — `vim.ui.input`, `vim.ui.select`, `nvim_open_win`
- (Optional) [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for enhanced picker
- Zero external dependencies — pure Lua
