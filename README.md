<div align="center">

# lonelog.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=flat-square&logo=neovim)](https://neovim.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/Django0033/lonelog.nvim/pulls)

Solo tabletop RPG toolkit for Neovim — oracles, dice, notation, and session management.

[Features](#features) • [Installation](#installation) • [Configuration](#configuration) • [Usage](#usage) • [Commands](#commands) • [API](#api) • [:help lonelog](#documentation)

</div>

Run solo RPG sessions directly in Neovim. This plugin implements the [Lonelog notation standard](https://github.com/valgur/lonelog) (v1.4.1), a structured markdown format for solo roleplaying session logs. All features are written in pure Lua with zero external dependencies.

> [!TIP]
> New to [Lonelog notation](https://github.com/valgur/lonelog)? It's a set of conventions for tracking actions, dice rolls, oracles, NPCs, scenes, and progress in a markdown journal. This plugin inserts symbols, manages tags, rolls dice, and highlights everything for you.

---

## Features

- **Dice engine** — `2d6+3`, `2d20kh1` (advantage), `4d6!` (exploding), `6d6>>4` (success counting), `2d6>7` (sum vs target)
- **Oracle system** — Fate (7 weighted outcomes), Binary (50/50), Mythic (2d10 + chaos factor). Persistent chaos factor
- **Tag management** — Browse, filter, and jump to NPCs (`[N:]`), locations (`[L:]`), PCs (`[PC:]`), threads (`[Thread:]`), foes (`[F:]`), rooms (`[R:]`), inventory (`[Inv:]`)
- **Tag autocomplete** — Automatic suggestions when typing `[TYPE:` with relevance sorting. Per-buffer cache
- **Scene navigation** — Navigate main scenes (`S1`), flashbacks (`S5a`), sub-scenes (`S7.1`), and thread scenes (`T1-S5`) with chronological ordering. Previous/next commands
- **Auto-numbered session headers** — Insert `## Session N` with date, recap, and goals. Auto-increments
- **Auto-numbered scene markers** — Insert `### S1 *context*` with automatic ID generation from last scene
- **Campaign YAML frontmatter** — Insert structured campaign metadata (title, ruleset, genre, dates, themes)
- **Progress elements** — Smart insert-or-increment for clocks (`[E:Name 0/5]`), tracks, and timers. Interactive mode prompts only on fresh insert
- **Inline tables** — Define tables inline (`tbl: Name (d6)`) with range entries or bracket shorthand (`[A, B, C]`). Roll directly on the line
- **Generator blocks** — Batch-roll indented sub-lines under a `gen:` header
- **Inline rolling** — Roll `d:`, `tbl:`, `label:`, and bare dice on any line. Works in visual mode
- **Narrative excerpt blocks** — Insert `\---` / `---\` delimiters for in-fiction prose
- **Multi-line tags** — Insert `[TYPE:Name\n  | content\n]` blocks for detailed entity descriptions
- **Meta notes** — Insert `(note: ...)` or `(nota: ...)` annotations
- **Actor markers** — Insert `@(Name)` for actions by NPCs or allies
- **Floating results** — Colored windows for dice and oracle results. Copy with `y`, paste with `<CR>`
- **Syntax highlighting** — 24+ highlight groups for all lonelog notation (tags, scenes, dice, dialogue, progress, etc.)
- **Telescope integration** — Optional, auto-detected
- **Zero dependencies** — Pure Lua. Neovim 0.8+ required

---

## Installation

<details open>
<summary>lazy.nvim</summary>

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

After installing, open a `.md` file and run `:Lonelog` to see the main action picker. Run `:help lonelog` for the full reference.

---

## Configuration

`require("lonelog").setup()` accepts an optional table. All keys are optional; defaults shown below:

```lua
require("lonelog").setup({
  use_telescope = "auto",            -- "auto" | true | false

  oracle = {
    default_table = "fate",          -- "fate" | "binary" | "mythic"
    persist_chaos = true,            -- save chaos factor to disk
    chaos_file = "chaos_factor.json",
  },

  dice = {
    max_dice = 100,                  -- safety limit
    max_sides = 1000,
  },

  sidebar = { width = 50 },

  float = {
    border = "rounded",
    height = 0.4,                    -- fraction of editor height
    width  = 0.6,
  },

  prompt_for_scene_context = true,   -- prompt for context on <leader>lM

  keymaps = {
    -- See :help lonelog-keymaps for the full keymap table
  },
})
```

The `use_telescope` option:
- `"auto"` — Use Telescope if installed, native sidebar otherwise
- `true` — Always use Telescope (errors if not installed)
- `false` — Always use built-in sidebar picker

---

## Usage

### Notation insertion

| Normal mode | Insert mode | Inserts |
|---|---|---|
| `<leader>lia` | `<C-l>a` | `@ ` — action marker |
| `<leader>liq` | `<C-l>q` | `? ` — oracle question |
| `<leader>lid` | `<C-l>d` | `d: ` — dice roll |
| `<leader>li-` | `<C-l>-` | ` -> ` — result arrow |
| `<leader>li=` | `<C-l>=` | `=> ` — consequence |
| `<leader>liN` | `<C-l>N` | `@(Name) ` — actor action |
| `<leader>lin` | — | `(note: )` — meta note |
| `<leader>liA` | — | 3-line action sequence |
| `<leader>liQ` | — | 3-line oracle sequence |

### Tag snippets

| Normal | Insert | Result |
|---|---|---|
| `<leader>ltn` | `<C-l>n` | `[N:\|]` — NPC |
| `<leader>ltl` | `<C-l>l` | `[L:\|]` — Location |
| `<leader>ltp` | `<C-l>p` | `[PC:\|]` — PC |
| `<leader>ltt` | `<C-l>h` | `[Thread:\|Open]` |
| `<leader>ltr` | `<C-l>r` | `[#N:\|]` — Reference |
| `<leader>ltf` | `<C-l>f` | `[F:\|]` — Foe |

### Multi-line tags

| Normal | Result |
|---|---|
| `<leader>lmn` | `[N:Name\n  \| ...\n]` |
| `<leader>lml` | `[L:Name\n  \| ...\n]` |
| `<leader>lmp` | `[PC:Name\n  \| ...\n]` |
| `<leader>lmt` | `[Thread:Name\n  \| ...\n]` |
| `<leader>lmr` | `[#N:Name\n  \| ...\n]` |
| `<leader>lmf` | `[F:Name\n  \| ...\n]` |

### Progress elements

Clocks, tracks, and timers use smart insert-or-increment logic. If an incomplete tag exists, it increments in place. If complete or missing, a fresh tag is inserted.

| Keymap | Element | Format |
|---|---|---|
| `<leader>lpc` | Clock | `[E:Name current/max]` |
| `<leader>lpt` | Track | `[Track:Name current/max]` |
| `<leader>lpi` | Timer | `[Timer:Name current]` |

Timers decrement toward 0; clocks and tracks increment toward max.

### Session headers

```
<leader>lH    :LonelogSession
```

Inserts an auto-numbered `## Session N` with today's date, Recap, and Goals sections. The cursor lands on the Recap bullet.

```
## Session 3
2026-05-31

### Recap
-

### Goals
-
```

### Scene markers

```
<leader>lM    :LonelogSceneMarker
```

Inserts `### S3 *context*` with auto-numbering:
- `S1` → `S2`, `S5a` → `S5b`, `S7.1` → `S7.2`
- `T1-S5` → `T1-S6`, `S5z` → `S6a`
- Empty buffer → `S1`

Prompts for context text (configurable via `prompt_for_scene_context`).

### Scene navigation

```
<leader>lS    :LonelogScenes    — browse all scenes
<leader>l[    :LonelogScenePrev — go to previous scene
<leader>l]    :LonelogSceneNext — go to next scene
```

### Narrative blocks

```
<leader>lN    :LonelogNarrative
```

Inserts `\---` / `---\` delimiters for in-fiction prose, with cursor in insert mode between them.

### Campaign header

```
<leader>lA    :LonelogCampaign
```

Inserts YAML frontmatter at the top of the buffer with campaign metadata fields. Prompts for the title. Refuses if a header already exists (`---` at line 1).

```yaml
---
title: My Campaign
ruleset:
genre:
player:
pcs:
start_date: 2026-05-31
last_update: 2026-05-31
tools:
themes:
tone:
notes:
---
```

### Meta notes

```
<leader>lin    :LonelogNote
```

Inserts `(note: )` at cursor. Both English and Spanish prefixes are recognized:
```
(note: testing alternate stealth rule)
(nota: esta escena se sintió tensa)
```

### Dice rolling

| Notation | Example | Description |
|---|---|---|
| `NdN` | `1d20` | Basic roll |
| `NdN+M` | `2d6+3` | With modifier |
| `NdN-M` | `1d20-2` | Subtract modifier |
| `NdN!` | `4d6!` | Exploding dice |
| `NdNkhK` | `2d20kh1` | Advantage |
| `NdNklK` | `2d20kl1` | Disadvantage |
| `NdN>>T` | `6d6>>4` | Success counting |
| `NdN>T` | `2d6>7` | Sum vs target |

```
<leader>lD             :LonelogDice         — interactive prompt
:LonelogDiceRoll 2d6+3                     — direct roll
:LonelogD20                                — quick roll 1d20
:LonelogD4  :LonelogD6  :LonelogD8         — quick dice
:LonelogD10 :LonelogD12 :LonelogD100
```

### Oracles

| Oracle | Outcomes | Usage |
|---|---|---|
| Fate | Exceptional Yes, Yes, Yes but..., Maybe, No but..., No, Exceptional No | `<leader>lO` or `:LonelogOracle` |
| Binary | Yes / No (50/50) | `:LonelogOracle binary` |
| Mythic | 2d10 + chaos factor (1-9) | `:LonelogOracle mythic` |

Results display in colored floating windows. Adjust the Mythic chaos factor interactively with `<leader>lC`.

### Inline tables

Define random tables and roll them directly:

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

Place cursor on any `tbl:`/`d:`/bare dice line and press `<leader>lR`:

```markdown
Before:  tbl: Forest Encounter (d6)
After:   tbl: Forest Encounter d6=4 -> A deer crosses

Before:  d: 2d6+3
After:   d: 2d6+3[4, 2] = 10

Before:  Apariencia: d3
After:   Apariencia: d3=2 -> Normal
```

### Generator blocks

```markdown
Before:
gen: Generate NPC
  Apariencia: d3
  Personalidad: d6
  tbl: Equipment (d6)

After:
gen: Generate NPC
  Apariencia: d3=2 -> Normal
  Personalidad: d6=4
  tbl: Equipment d6=3 -> Rusty sword
```

### Tag navigation

```
<leader>lT    :LonelogTags
```

Browse all tags in the buffer. Filter by type, press Enter to jump.

```
[N:Jonah|friendly|wounded]           — NPC
[L:Library|dark|quiet]               — Location
[PC:Alex|HP 8]                       — PC
[Thread:Main Quest|Open]             — Thread
[E:Alert 2/6]                        — Event/clock
[F:Matón|HP 6]                       — Foe
[R:3|cleared|library]                — Room
[Inv:Torch|3]                        — Inventory
```

### Tag autocomplete

When typing after `[TYPE:` in a markdown buffer, matching entity names are suggested automatically. Manual trigger:

```
<C-l>c        :LonelogCompleteTag
```

### Floating results

Dice and oracle results appear in a floating window:

| Key | Action |
|---|---|
| `q` | Close window |
| `y` / `Y` | Copy to system clipboard |
| `<CR>` | Paste into `.md` buffer |

`<leader>lI` inserts the most recent result at the cursor.

---

## Commands

| Command | Description |
|---|---|
| `:Lonelog` | Open main action picker |
| `:LonelogOracle [table]` | Roll oracle (fate/binary/mythic) |
| `:LonelogDice` | Interactive dice roller |
| `:LonelogDiceRoll <notation>` | Roll specific dice notation |
| `:LonelogD4` – `:LonelogD100` | Quick roll 1dN |
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
| `:LonelogSession` | Insert auto-numbered session header |
| `:LonelogNarrative` | Insert narrative excerpt block |
| `:LonelogNote` | Insert meta note |
| `:LonelogCampaign` | Insert campaign header |
| `:LonelogTags` | Browse tags |
| `:LonelogScenes` | Browse scenes |
| `:LonelogRollLine` | Roll dice/table on current line |
| `:LonelogCompleteTag` | Trigger tag autocomplete |
| `:LonelogInsert` | Insert last result at cursor |
| `:LonelogChaos` | Chaos factor UI |

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
print(ln.oracle.get_chaos())  -- number (1-9)
ln.oracle.set_chaos(7)        -- boolean

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

---

## Documentation

See `:help lonelog` for the complete reference including:
- All keymaps (normal, insert, floating window)
- Tag format and multi-line tag syntax
- Dice notation grammar
- Oracle probabilities and chaos factor system
- Progress element behavior
- Syntax highlighting groups (24+)
- Lonelog spec add-ons (combat, dungeons, resources)
- Session workflow tips

---

## Requirements

- Neovim **0.8+** (requires `vim.ui.input`, `vim.ui.select`, `nvim_open_win`)
- (Optional) [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for enhanced picker
- No external dependencies (pure Lua)
