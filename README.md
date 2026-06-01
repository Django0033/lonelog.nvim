<div align="center">

# lonelog.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=flat-square&logo=neovim)](https://neovim.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](/LICENSE)
[![Build](https://img.shields.io/github/actions/workflow/status/Django0033/lonelog.nvim/ci.yml?style=flat-square)](https://github.com/Django0033/lonelog.nvim/actions)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/Django0033/lonelog.nvim/pulls)

Solo tabletop RPG toolkit for Neovim — oracles, dice, structured notation, and session management.

[Features](#features) • [Installation](#installation) • [Configuration](#configuration) • [Dice rolling](#dice-rolling) • [Oracles](#oracles) • [Tags & scenes](#tags--scenes) • [Commands](#commands) • [API](#api) • [:help lonelog](#documentation)

</div>

> This plugin implements the [Lonelog notation standard](https://github.com/valgur/lonelog) (v1.4.1), a structured markdown format for solo RPG session logs. All features are pure Lua — zero external dependencies.

---

## Features

- **Dice engine** — `2d6+3`, `2d20kh1` (advantage), `4d6!` (exploding), `6d6>>4` (success counting), `2d6>7` (sum vs target). Configurable safety limits
- **Oracles** — Fate (7 weighted outcomes), Binary (50/50), Mythic (2d10 + chaos factor). Persistent chaos factor with +/- UI
- **Tag management** — NPCs `[N:]`, Locations `[L:]`, PCs `[PC:]`, Threads `[Thread:]`, Foes `[F:]`, Rooms `[R:]`, Inventory `[Inv:]`. Browse, filter, jump
- **Tag autocomplete** — Suggestions when typing `[TYPE:` with relevance sorting. Triggered on `TextChangedI`
- **Scene navigation** — Main scenes `S1`, flashbacks `S5a`, sub-scenes `S7.1`, thread scenes `T1-S5`. Chronological ordering, prev/next commands
- **Progress elements** — Clocks, tracks, timers with smart insert-or-increment. Prompt once, increment automatically
- **Inline tables** — Define tables with range entries or bracket shorthand `[A, B, C]`. Roll directly on the line
- **Generator blocks** — Batch-process indented sub-lines under `gen:` header
- **Inline rolling** — `d:`, `tbl:`, `label:`, bare dice. Single line or visual selection
- **Session headers** — Auto-numbered `## Session N` with date, Recap, Goals
- **Scene markers** — Auto-numbered `### S3 *context*` with smart ID progression
- **Campaign YAML** — Structured frontmatter with title, ruleset, genre, dates, themes
- **Narrative blocks** — `\---` / `---\` delimiters for in-fiction prose
- **Combat blocks** — `[COMBAT]` / `[/COMBAT]` tactical encounter delimiters with `R#` round markers and auto-roster that excludes dead combatants
- **Dungeon status** — `=== Dungeon Status ===` block with auto-collected room tags, insert or update at `<leader>lK`
- **Multi-line tags** — `[TYPE:Name\n  | content\n]` for detailed descriptions
- **Meta notes** — `(note: ...)` / `(nota: ...)` inline annotations
- **Session summary** — Per-session stats: scenes, tags, notation, progress, dice. Export to markdown
- **Actor markers** — `@(Name)` for NPC/ally actions
- **Floating results** — Colored windows with copy (`y`), paste (`<CR>`), insert last (`<leader>lI`)
- **Syntax highlighting** — 29 highlight groups for all Lonelog elements (tags, dice, scenes, dialogue, progress, etc.)
- **Telescope integration** — Optional, auto-detected
- **Zero dependencies** — Pure Lua, Neovim 0.8+

---

## Installation

<details open>
<summary>lazy.nvim</summary>

```lua
{
  "Django0033/lonelog.nvim",
  cmd = { "Lonelog", "LonelogOracle", "LonelogDice", "LonelogTags",
          "LonelogScenes", "LonelogRollLine", "LonelogCombat",
          "LonelogDungeonStatus" },
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
<summary>vim-pack (built-in)</summary>

```bash
git clone https://github.com/Django0033/lonelog.nvim.git \
  ~/.local/share/nvim/site/pack/plugins/start/lonelog.nvim
```

```lua
-- init.lua
require("lonelog").setup()
```
</details>

After installing, open a `.md` file and run `:Lonelog`. See `:help lonelog` for the full reference.

---

## Configuration

`require("lonelog").setup(opts)` — all keys optional, defaults shown:

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
    default_table = "fate",          -- "fate" | "binary" | "mythic"
    persist_chaos = true,
    chaos_file = "chaos_factor.json",
  },

  dice = {
    max_dice = 100,                  -- safety limit
    max_sides = 1000,
  },

  prompt_for_scene_context = true,   -- prompt for context on scene markers

  keymaps = { /* see :help lonelog-keymaps */ },
})
```

> [!TIP]
> Set `use_telescope = "auto"` (default) to use Telescope when installed, falling back to the native sidebar. Use `true` to require Telescope or `false` to always use the sidebar.

---

## Quick start

Open a markdown file and press any of these:

| Key | What it does |
|-----|-------------|
| `<leader>lO` | Roll an oracle (fate, binary, mythic) |
| `<leader>lD` | Interactive dice roller |
| `<leader>lR` | Roll dice/table on current line |
| `<leader>lM` | Insert scene marker with auto-numbering |
| `<leader>lE` | Show session summary / export to markdown |
| `<leader>lH` | Insert session header with date |
| `<leader>lK` | Insert/update dungeon status block |
| `<leader>lG` | Navigate to connected room |
| `<leader>lJ` | Toggle room state |
| `<leader>lT` | Browse all Lonelog tags |
| `<leader>lS` | Browse all scenes |
| `<leader>lC` | Adjust Mythic chaos factor |

### Notation insertion

| Normal | Insert | Inserts |
|--------|--------|---------|
| `<leader>lia` | `<C-l>a` | `@ ` — action marker |
| `<leader>liq` | `<C-l>q` | `? ` — oracle question |
| `<leader>lid` | `<C-l>d` | `d: ` — dice roll |
| `<leader>li-` | `<C-l>-` | ` -> ` — result arrow |
| `<leader>li=` | `<C-l>=` | `=> ` — consequence |
| `<leader>liN` | `<C-l>N` | `@(Name) ` — actor action |
| `<leader>liA` | — | 3-line action template |
| `<leader>liQ` | — | 3-line oracle template |

### Entity tags

| Normal | Insert | Result |
|--------|--------|--------|
| `<leader>ltn` | `<C-l>n` | `[N:\|]` — NPC |
| `<leader>ltl` | `<C-l>l` | `[L:\|]` — Location |
| `<leader>ltp` | `<C-l>p` | `[PC:\|]` — PC |
| `<leader>ltt` | `<C-l>h` | `[Thread:\|Open]` |
| `<leader>ltr` | `<C-l>r` | `[#N:\|]` — Reference |

### Multi-line tags

| Normal | Result |
|--------|--------|
| `<leader>lmn` | `[N:Name\n  \| ...\n]` |
| `<leader>lml` | `[L:Name\n  \| ...\n]` |
| `<leader>lmp` | `[PC:Name\n  \| ...\n]` |
| `<leader>lmr` | `[#N:Name\n  \| ...\n]` |

### Progress elements

Clocks, tracks, and timers use smart insert-or-increment logic. If the tag exists and is incomplete, it increments. If complete or missing, a fresh tag is inserted.

| Keymap | Element | Format |
|--------|---------|--------|
| `<leader>lpc` | Clock | `[E:Name 0/5]` |
| `<leader>lpt` | Track | `[Track:Name 0/5]` |
| `<leader>lpi` | Timer | `[Timer:Name 0]` |

Timers tick down toward 0; clocks and tracks tick up toward max.

### Quick dice

| Key | Roll |
|-----|------|
| `<leader>ld4` | 1d4 |
| `<leader>ld6` | 1d6 |
| `<leader>ldw` | 1d20 |
| `<leader>ldc` | 1d100 |

All quick-dice results appear in floating windows. Use `q` to close, `y` to copy, `<CR>` to paste into the buffer.

---

## Dice rolling

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

---

## Oracles

| Oracle | Outcomes | Key | Command |
|--------|----------|-----|---------|
| Fate | Exceptional Yes, Yes, Yes but..., Maybe, No but..., No, Exceptional No | `<leader>lO` | `:LonelogOracle` |
| Binary | Yes / No (50/50) | | `:LonelogOracle binary` |
| Mythic | 2d10 + chaos factor (1-9) | | `:LonelogOracle mythic` |

Results display in colored floating windows. Use `<leader>lC` to adjust the Mythic chaos factor interactively.

```vim
:help lonelog-oracle
```

---

## Tags & scenes

### Tag format

```
[N:Jonah|friendly|wounded]           — NPC
[L:Library|dark|quiet]               — Location
[PC:Alex|HP 8]                       — Player character
[Thread:Main Quest|Open]             — Thread/quest
[E:Alert 2/6]                        — Event/clock
[F:Matón|HP 6|alerta]                — Foe
[R:3|cleared|library]                — Room
[Inv:Torch|3]                        — Inventory
```

Tag metadata supports changes (`friendly → hostile`), additions (`+captured`), and removals (`-wounded`).

### Scene markers

```
### S1 *Lighthouse tower*
### S5a *Flashback: Father's workshop*
### S7.1 *Day 1: Forest*
### T1-S5 *Thread scene*
```

Auto-numbering: `S1 → S2`, `S5a → S5b`, `S7.1 → S7.2`, `T1-S5 → T1-S6`.

```vim
:help lonelog-notation
```

---

## Inline tables & generator blocks

Define random tables inline and roll them with `<leader>lR`:

```markdown
tbl: Forest Encounter (d6)
  1-3: Nothing happens
  4-5: A deer crosses
  6: Bandit ambush!
```

Bracket shorthand for equal-probability options:

```markdown
tbl: Weather [Sunny, Cloudy, Rain, Storm]
```

Generator blocks batch-process indented sub-lines:

```markdown
gen: Generate NPC
  Apariencia: d3
  Personalidad: d6
  tbl: Equipment (d6)
```

After rolling with `<leader>lR` on the `gen:` line:

```markdown
gen: Generate NPC
  Apariencia: d3=2 -> Normal
  Personalidad: d6=4
  tbl: Equipment d6=3 -> Rusty sword
```

```vim
:help lonelog-notation-tables
:help lonelog-notation-gen
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
| `:LonelogScenePrev` | Go to previous scene |
| `:LonelogSceneNext` | Go to next scene |
| `:LonelogSession` | Insert session header |
| `:LonelogNarrative` | Insert narrative excerpt block |
| `:LonelogCombat` | Insert combat block `[COMBAT]` / `[/COMBAT]` |
| `:LonelogDungeonStatus` | Insert/update `=== Dungeon Status ===` block with room tags |
| `:LonelogRoomGo` | Navigate to a connected room via exit picker |
| `:LonelogRoomState` | Toggle room states via picker |
| `:LonelogRound` | Insert round marker with optional auto-roster (excludes dead combatants) |
| `:LonelogNote` | Insert meta note |
| `:LonelogCampaign` | Insert campaign header |
| `:LonelogSessionSummary` | Show session summary in floating window |
| `:LonelogExportSummary` | Export session summary to markdown file |
| `:LonelogTags` | Browse tags |
| `:LonelogScenes` | Browse scenes |
| `:LonelogRollLine` | Roll dice/table on current line |
| `:LonelogCompleteTag` | Trigger tag autocomplete |
| `:LonelogInsert` | Insert last result at cursor |
| `:LonelogChaos` | Chaos factor UI |

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
print(ln.oracle.get_chaos())       -- number (1-9)
ln.oracle.set_chaos(7)             -- boolean

-- List oracle tables
ln.oracle.list_tables()            -- string[]

-- Parsers
local tags   = ln.parsers.parse_tags()
local scenes = ln.parsers.parse_scenes()
local summary = ln.parsers.tags_summary(tags)

-- Inline tables
local tbls = require("lonelog.parsers.tables").parse_tables(lines)
local entry = require("lonelog.parsers.tables").resolve_entry(tbl, value)

-- Inline rolling
local modified = require("lonelog.roll_line").process_line(line, tbls)
require("lonelog.roll_line").roll_current_line()

-- Tag completion
local comp = require("lonelog.completion")
comp.refresh_completions()
comp.complete_tag()
```

```vim
:help lonelog-api
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
- Add-ons: combat, dungeon, resources
- Session workflow tips
- 29 syntax highlight groups with overrides

---

## Requirements

- Neovim **0.8+** — requires `vim.ui.input`, `vim.ui.select`, `nvim_open_win`
- (Optional) [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for enhanced picker
- No external dependencies — pure Lua
