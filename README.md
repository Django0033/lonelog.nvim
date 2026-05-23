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
- **Notation Insertion** — Insert Lonelog symbols (`@`, `?`, `d:`, `->`, `=>`), multiline action/oracle sequences, and tag snippets (`[N:Name|]`, `[#N:Name]`) directly into your session log
- **Tag Autocomplete** — Automatically suggests existing entity names when typing tags (`[N:`, `[L:`, `[PC:`, etc.) with relevance-based ordering
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
    -- Main features
    oracle    = "<leader>lO",  -- Open oracle picker
    dice      = "<leader>lD",  -- Interactive dice roll
    tags      = "<leader>lT",  -- Navigate tags
    scenes    = "<leader>lS",  -- Navigate scenes
    chaos     = "<leader>lC",  -- Chaos factor UI

    -- Insert notation symbols
    insert_action   = "<leader>lia",  -- Insert @
    insert_question = "<leader>liq",  -- Insert ?
    insert_dice     = "<leader>lid",  -- Insert d:
    insert_arrow    = "<leader>li-",  -- Insert ->
    insert_conseq   = "<leader>li=",  -- Insert =>
    action_seq      = "<leader>liA",  -- Action sequence template
    oracle_seq      = "<leader>liQ",  -- Oracle sequence template

    -- Insert tag snippets
    tag_npc      = "<leader>ltn",  -- Insert [N:Name|]
    tag_location = "<leader>ltl",  -- Insert [L:Name|]
    tag_pc       = "<leader>ltp",  -- Insert [PC:Name|]
    tag_thread   = "<leader>ltt",  -- Insert [Thread:Name|Open]
    tag_ref      = "<leader>ltr",  -- Insert [#N:Name]
    tag_foe      = "<leader>ltf",  -- Insert [F:Name|]

    insert_result = "<leader>lI",  -- Insert last result
    scene_marker  = "<leader>lm",  -- Scene marker

    -- Tag autocomplete (insert mode)
    complete_tag = "<C-l>c",

    -- Quick dice rolls
    d4   = "<leader>ld4",   d6  = "<leader>ld6",
    d8   = "<leader>ld8",   d10 = "<leader>lda",
    d12  = "<leader>ldb",   d20 = "<leader>ldw",
    d100 = "<leader>ldc",
  },
})
```

## Usage

### Notation Insertion

Lonelog uses a structured notation for solo RPG session logs. Insert symbols directly from normal or insert mode:

| Keymap (Normal) | Keymap (Insert) | Inserts |
|-----------------|-----------------|---------|
| `<leader>lia` | `<C-l>a` | `@ ` — Action marker |
| `<leader>liq` | `<C-l>q` | `? ` — Oracle question |
| `<leader>lid` | `<C-l>d` | `d: ` — Dice roll |
| `<leader>li-` | `<C-l>-` | ` -> ` — Result arrow |
| `<leader>li=` | `<C-l>=` | `\n=> ` — Consequence |

### Notation Sequences

Insert structured action and oracle sequences with a single keymap:

| Keymap | Inserts |
|--------|---------|
| `<leader>liA` | Action sequence — `@ [action]` / `d: [roll] -> [outcome]` / `=> [consequence]` |
| `<leader>liQ` | Oracle sequence — `? [question]` / `-> [answer]` / `=> [consequence]` |

Or use commands:

```vim
:LonelogSymbol @
:LonelogSymbol arrow
:LonelogSymbol conseq
:LonelogActionSequence
:LonelogOracleSequence
```

### Tag Autocomplete

When editing a tag like `[N:Jonah|`, `[L:Library|`, or `[PC:A`, the plugin automatically suggests matching entity names from your current buffer:

- **Auto-trigger** — Suggestions appear as you type after `[TYPE:`
- **Relevance sorting** — Exact matches first, then prefix matches, then alphabetical
- **Per-buffer cache** — Tag data refreshes only when the buffer changes

```vim
<C-l>c       " Manual trigger in insert mode
:LonelogCompleteTag
```

### Tag Snippets

Insert Lonelog tags with smart cursor positioning — the cursor lands right after the colon so you can type the name immediately:

| Keymap (Normal) | Keymap (Insert) | Inserts |
|-----------------|-----------------|---------|
| `<leader>ltn` | `<C-l>n` | `[N:\|]` — NPC |
| `<leader>ltl` | `<C-l>l` | `[L:\|]` — Location |
| `<leader>ltp` | `<C-l>p` | `[PC:\|]` — Player character |
| `<leader>ltt` | `<C-l>h` | `[Thread:\|Open]` — Thread |
| `<leader>ltr` | `<C-l>r` | `[#N:\|]` — Reference |
| `<leader>ltf` | `<C-l>f` | `[F:\|]` — Foe |

Or use the command:

```vim
:LonelogTag npc
:LonelogTag thread
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
<leader>lD       " Interactive: type '2d6+3'
:LonelogDiceRoll 2d6+3
:LonelogD20       " Quick roll 1d20
```

### Oracle System

Roll oracles for game master decisions:

| Oracle | Outcomes | Usage |
|--------|----------|-------|
| **Fate** | Exceptional Yes/No, Yes/No (but...), Maybe | `<leader>lO` |
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
<leader>lT       " Browse tags by type
:LonelogTags
```

### Scene Navigation

Navigate through your session outline:

```vim
<leader>lS       " Browse scenes by type
:LonelogScenes
```

Scenes are automatically sorted in chronological order, with support for:
- Main scenes (`S1`, `S2`), Flashbacks (`S5a`, `S8b`)
- Sub-scenes (`S7.1`, `S7.2`), Thread scenes (`T1-S5`, `T1+T2-S5`)

### Auto-Numbered Scene Markers

Insert a scene marker with automatic numbering — scans backwards from the cursor to find the last scene and increments it:

```vim
<leader>lm       " Insert ### S1 *context* (auto-numbered)
:LonelogSceneMarker
```

| Last scene | Inserts |
|------------|---------|
| `S1` | `S2` |
| `S5a` | `S5b` |
| `S7.1` | `S7.2` |
| `T1-S5` | `T1-S6` |
| `S5z` | `S6a` (wraps) |
| *(none)* | `S1` |

## Commands

| Command | Description |
|---------|-------------|
| `:Lonelog` | Open main action picker |
| `:LonelogOracle [table]` | Roll oracle (fate/binary/mythic) |
| `:LonelogDice` | Interactive dice roller |
| `:LonelogDiceRoll <notation>` | Roll specific dice notation |
| `:LonelogD4` through `:LonelogD100` | Quick dice rolls |
| `:LonelogSymbol <symbol>` | Insert notation symbol |
| `:LonelogCompleteTag` | Trigger tag autocomplete |
| `:LonelogTag <type>` | Insert tag snippet (npc/location/pc/thread/ref/foe) |
| `:LonelogActionSequence` | Insert action sequence template |
| `:LonelogOracleSequence` | Insert oracle sequence template |
| `:LonelogSceneMarker` | Insert auto-numbered scene marker |
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

-- Trigger tag completion programmatically
local completion = require("lonelog.completion")
completion.refresh_completions()  -- Force cache refresh for current buffer
completion.complete_tag()         -- Trigger completion popup
```

## Requirements

- Neovim **0.8+**
- (Optional) [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for enhanced picker
