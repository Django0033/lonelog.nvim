# lonelog.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=flat-square&logo=neovim)](https://neovim.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/Django0033/lonelog.nvim/pulls)

> Solo tabletop RPG toolkit for Neovim — oracles, dice, notation, and session navigation.

[Features](#features) • [Installation](#installation) • [Configuration](#configuration) • [Usage](#usage) • [Commands](#commands) • [API](#api)

---

## Features

- **Dice Engine** — Standard notation (`2d6+3`), advantage/disadvantage (`2d20kh1`), exploding dice (`4d6!`), success counting (`6d6>>4`), and sum-vs-target (`2d6>7`)
- **Oracle System** — Weighted outcomes from Fate, Binary, and Mythic tables with persistent chaos factor
- **Notation Insertion** — Insert Lonelog symbols (`@`, `?`, `d:`, `->`, `=>`) and tags (`[N:Name|]`, `[#N:Name]`) directly into your session log
- **Tag Navigation** — Parse and browse NPCs, locations, threads, clocks, tracks, and more from your play log
- **Scene Navigation** — Navigate main scenes, flashbacks, sub-scenes, and thread scenes with proper chronological ordering
- **Telescope Integration** — Uses Telescope when available, falls back to a native sidebar picker automatically
- **Zero Dependencies** — Pure Lua, no external packages required

> [!TIP]
> New to [Lonelog notation](https://github.com/valgur/lonelog)? It's a structured markdown format designed for solo RPG session logs, with tags for NPCs, locations, events, and more.

## Installation

<details>
<summary>lazy.nvim</summary>

```lua
{
  "Django0033/lonelog.nvim",
  cmd = { "Lonelog", "LonelogOracle", "LonelogDice", "LonelogTags", "LonelogScenes" },
  config = function()
    require("lonelog").setup()
  end,
}
```
</details>

<details>
<summary>packer.nvim</summary>

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
<summary>vim-pack (Neovim built-in)</summary>

```bash
git clone https://github.com/Django0033/lonelog.nvim.git \
  ~/.local/share/nvim/site/pack/plugins/start/lonelog.nvim
```

```lua
-- init.lua
require("lonelog").setup()
```
</details>

## Configuration

`require("lonelog").setup()` accepts a table with all optional keys shown below with their defaults:

```lua
require("lonelog").setup({
  -- Picker mode: "auto" (detect Telescope), true (always), false (native sidebar)
  use_telescope = "auto",

  -- Oracle defaults
  oracle = {
    default_table = "fate",       -- Default oracle table
    persist_chaos = true,          -- Persist Mythic chaos factor to file
    chaos_file = "chaos_factor.json",
  },

  -- Dice limits
  dice = {
    max_dice = 100,               -- Maximum dice per roll
    max_sides = 1000,             -- Maximum sides per die
  },

  -- UI customization
  sidebar = { width = 50 },       -- Native sidebar width
  float = {
    border = "rounded",           -- Floating window border
    height = 0.4,                 -- Height as fraction of editor
    width = 0.6,                  -- Width as fraction of editor
  },

  -- All keymaps are customizable:
  keymaps = {
    oracle       = "<leader>lo",  -- Open oracle picker
    dice         = "<leader>ldr", -- Interactive dice roll
    tags         = "<leader>lt",  -- Navigate tags
    scenes       = "<leader>ls",  -- Navigate scenes
    chaos        = "<leader>lC",  -- Chaos factor UI
    insert_action   = "<leader>la",  -- Insert @
    insert_question = "<leader>lq",  -- Insert ?
    insert_dice     = "<leader>ldd", -- Insert d:
    insert_arrow    = "<leader>l-",  -- Insert ->
    insert_conseq   = "<leader>l=",  -- Insert =>
    d4   = "<leader>ld4",         -- Quick roll 1d4
    d6   = "<leader>ld6",         -- Quick roll 1d6
    d8   = "<leader>ld8",         -- Quick roll 1d8
    d10  = "<leader>lda",         -- Quick roll 1d10
    d12  = "<leader>ldb",         -- Quick roll 1d12
    d20  = "<leader>ldw",         -- Quick roll 1d20
    d100 = "<leader>ldc",         -- Quick roll 1d100
  },
})
```

## Usage

### Notation Insertion

Lonelog uses a structured notation for solo RPG session logs. Insert symbols directly from normal or insert mode:

| Keymap (Normal) | Keymap (Insert) | Inserts |
|-----------------|-----------------|---------|
| `<leader>la` | `<C-l>a` | `@ ` — Action marker |
| `<leader>lq` | `<C-l>q` | `? ` — Oracle question |
| `<leader>ldd` | `<C-l>d` | `d: ` — Dice roll |
| `<leader>l-` | `<C-l>-` | ` -> ` — Result arrow |
| `<leader>l=` | `<C-l>=` | `\n=> ` — Consequence |

Or use commands:

```vim
:LonelogSymbol @
:LonelogSymbol arrow
:LonelogSymbol conseq
```

### Dice Rolling

Supports standard RPG dice notation and advanced modifiers:

| Notation | Example | Description |
|----------|---------|-------------|
| `NdN` | `1d20` | Basic roll |
| `NdN+M` | `2d6+3` | With modifier |
| `NdN!` | `4d6!` | Exploding dice (reroll on max) |
| `NdNkh1` | `2d20kh1` | Advantage (keep highest) |
| `NdNkl1` | `2d20kl1` | Disadvantage (keep lowest) |
| `NdN>>T` | `6d6>>4` | Success counting |
| `NdN>T` | `2d6>7` | Sum vs target |

```vim
<leader>ldr       " Interactive: type '2d6+3'
:LonelogDiceRoll 2d6+3
:LonelogD20       " Quick roll 1d20
```

### Oracle System

Roll oracles for game master decisions:

| Oracle | Outcomes | Usage |
|--------|----------|-------|
| **Fate** | Exceptional Yes/No, Yes/No (but...), Maybe | `<leader>lo` |
| **Binary** | Yes / No | `:LonelogOracle binary` |
| **Mythic** | 2d10 + chaos factor | `:LonelogOracle mythic` |

The Mythic chaos factor persists between sessions and can be adjusted via `<leader>lC`.

### Tag Navigation

Browse all Lonelog entities in your session log:

```
[N:Jonah|friendly|wounded]     — NPC
[L:Library|dark|quiet]         — Location
[Thread:Main Quest|Open]       — Thread
[E:Alert 2/6]                  — Event/Clock
[Clock:Ritual 4/8]             — Progress clock
[PC:Alex|HP 8]                 — Player character
```

```vim
<leader>lt       " Browse tags by type
:LonelogTags
```

### Scene Navigation

Navigate through your session outline:

```vim
<leader>ls       " Browse scenes by type
:LonelogScenes
```

Scenes are automatically sorted in chronological order, with support for:
- Main scenes (`S1`, `S2`), Flashbacks (`S5a`, `S8b`)
- Sub-scenes (`S7.1`, `S7.2`), Thread scenes (`T1-S5`, `T1+T2-S5`)

## Commands

| Command | Description |
|---------|-------------|
| `:Lonelog` | Open main action picker |
| `:LonelogOracle [table]` | Roll oracle (fate/binary/mythic) |
| `:LonelogDice` | Interactive dice roller |
| `:LonelogDiceRoll <notation>` | Roll specific dice notation |
| `:LonelogD4` through `:LonelogD100` | Quick dice rolls |
| `:LonelogSymbol <symbol>` | Insert notation symbol |
| `:LonelogTags` | Browse Lonelog tags |
| `:LonelogScenes` | Browse Lonelog scenes |
| `:LonelogInsert` | Insert last result at cursor |
| `:LonelogChaos` | Open chaos factor UI |

## API

```lua
local ln = require("lonelog")

-- Roll dice programmatically
local result, err = ln.dice.roll("2d6+3")
print(result.display)     -- e.g. "2d6+3[4, 2] + 3 = 9"
print(result.total)       -- e.g. 9

-- Roll oracle
local oracle = ln.oracle.roll("fate")
print(oracle.display)     -- e.g. "Yes, but..."

-- Parse current buffer
local tags = ln.parsers.tags.parse_tags()
local scenes = ln.parsers.scenes.parse_scenes()
```

## Requirements

- Neovim **0.8+**
- (Optional) [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for enhanced picker
