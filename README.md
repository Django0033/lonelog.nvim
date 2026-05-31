<div align="center">

# lonelog.nvim

[![Neovim](https://img.shields.io/badge/Neovim-0.8+-green.svg?style=flat-square&logo=neovim)](https://neovim.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](/LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://github.com/Django0033/lonelog.nvim/pulls)

> Solo tabletop RPG toolkit for Neovim — oracles, dice, notation, and session navigation.

[Features](#features) • [Installation](#installation) • [Configuration](#configuration) • [Usage](#usage) • [Commands](#commands) • [API](#api) • [:help lonelog](#documentation)

</div>

Solo RPG players can run full sessions directly in Neovim using this plugin. It implements the [Lonelog notation standard](https://github.com/valgur/lonelog) (v1.4.1), a structured markdown format for solo roleplaying session logs.

All features are written in pure Lua with zero external dependencies. [Telescope](https://github.com/nvim-telescope/telescope.nvim) is optionally supported and auto-detected.

> [!TIP]
> New to [Lonelog notation](https://github.com/valgur/lonelog)? It's a set of conventions for tracking actions, dice rolls, oracles, NPCs, scenes, and progress in a markdown journal. The plugin inserts symbols, manages tags, and rolls dice for you.

## Features

- **Dice engine** — `2d6+3`, `2d20kh1` (advantage), `4d6!` (exploding), `6d6>>4` (success counting), `2d6>7` (sum vs target)
- **Oracle system** — Fate (7 weighted outcomes), Binary (50/50), Mythic (2d10 + chaos factor). Chaos factor persists across sessions
- **Progress elements** — Smart insert-or-increment for clocks (`[E:Name 0/5]`), tracks (`[Track:Name 0/5]`), and timers (`[Timer:Name 0]`). Interactive mode prompts only when a fresh insert is needed
- **Tag navigation** — Browse NPCs, locations, threads, PCs, foes, rooms, and inventory. Filter by type, jump to any tag
- **Tag autocomplete** — Automatic suggestions when typing `[TYPE:` with relevance sorting (exact match > prefix > alphabetical). Per-buffer cache
- **Scene navigation** — Navigate main scenes (`S1`), flashbacks (`S5a`), sub-scenes (`S7.1`), and thread scenes (`T1-S5`) with chronological ordering
- **Auto-numbered scene markers** — Insert `### S1 *Tavern*` with automatic ID generation. Prompts for context via `vim.fn.input()` (configurable)
- **Inline tables** — Define tables inline (`tbl: Name (d6)`) with range entries or bracket shorthand (`[A, B, C]`). Roll directly on the line
- **Generator blocks** — Batch-roll indented sub-lines under a `gen:` header with label-to-table resolution
- **Inline rolling** — Roll `d:`, `tbl:`, `label:` and bare dice notation on any line. Works in visual mode
- **Notation insertion** — Insert `@`, `?`, `d:`, `->`, `=>` and full action/oracle sequences with a single keymap
- **Tag snippets** — Insert `[N:Name|]`, `[L:Name|]`, `[PC:Name|]`, `[Thread:Name|Open]`, `[#N:Name]`, `[F:Name|]` with cursor at the right position
- **Floating results** — Colored floating windows for dice and oracle results. Copy with `y`, paste into buffer with `<CR>`
- **Zero dependencies** — Pure Lua. Neovim 0.8+ required. Telescope optional

## Installation

<details open>
<summary>lazy.nvim</summary>

```lua
{
  "Django0033/lonelog.nvim",
  cmd = { "Lonelog", "LonelogOracle", "LonelogDice", "LonelogTags", "LonelogScenes", "LonelogRollLine" },
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

## Configuration

`require("lonelog").setup()` accepts a table. All keys are optional; defaults shown below:

```lua
require("lonelog").setup({
  use_telescope = "auto",            -- "auto" | true | false

  oracle = {
    default_table = "fate",          -- "fate" | "binary" | "mythic"
    persist_chaos = true,            -- save chaos factor to disk
    chaos_file = "chaos_factor.json",
  },

  dice = {
    max_dice = 100,                  -- maximum dice per roll
    max_sides = 1000,                -- maximum sides per die
  },

  sidebar = { width = 50 },          -- native sidebar width
  float = {
    border = "rounded",
    height = 0.4,                    -- fraction of editor height
    width  = 0.6,                    -- fraction of editor width
  },

  prompt_for_scene_context = true,   -- prompt for context on <leader>lM

  keymaps = {
    -- Main actions (uppercase)
    oracle    = "<leader>lO",
    dice      = "<leader>lD",
    tags      = "<leader>lT",
    scenes    = "<leader>lS",
    chaos     = "<leader>lC",
    insert_result = "<leader>lI",
    scene_marker  = "<leader>lM",
    roll_line     = "<leader>lR",

    -- Insert notation symbols
    insert_action   = "<leader>lia",
    insert_question = "<leader>liq",
    insert_dice     = "<leader>lid",
    insert_arrow    = "<leader>li-",
    insert_conseq   = "<leader>li=",
    actor_action    = "<leader>liN",
    action_seq      = "<leader>liA",
    oracle_seq      = "<leader>liQ",

    -- Entity tags
    tag_npc      = "<leader>ltn",
    tag_location = "<leader>ltl",
    tag_pc       = "<leader>ltp",
    tag_thread   = "<leader>ltt",
    tag_ref      = "<leader>ltr",
    tag_foe      = "<leader>ltf",

    -- Progress elements
    progress_clock = "<leader>lpc",
    progress_track = "<leader>lpt",
    progress_timer = "<leader>lpi",

    -- Quick dice
    d4   = "<leader>ld4",   d6  = "<leader>ld6",
    d8   = "<leader>ld8",   d10 = "<leader>lda",
    d12  = "<leader>ldb",   d20 = "<leader>ldw",
    d100 = "<leader>ldc",

    -- Tag completion (insert mode)
    complete_tag  = "<C-l>c",
  },
})
```

## Usage

### Notation insertion

Lonelog uses a structured notation for solo RPG session logs. Insert symbols from normal or insert mode:

| Normal mode | Insert mode | Inserts |
|---|---|---|
| `<leader>lia` | `<C-l>a` | `@ ` — action marker |
| `<leader>liq` | `<C-l>q` | `? ` — oracle question |
| `<leader>lid` | `<C-l>d` | `d: ` — dice roll |
| `<leader>li-` | `<C-l>-` | ` -> ` — result arrow |
| `<leader>li=` | `<C-l>=` | `=> ` — consequence |
| `<leader>liN` | `<C-l>N` | `@(Name) ` — actor action |
| `<leader>liA` | | 3-line action sequence (`@ [action]` / `d: [roll] -> [outcome]` / `=> [consequence]`) |
| `<leader>liQ` | | 3-line oracle sequence (`? [question]` / `-> [answer]` / `=> [consequence]`) |

### Tag snippets

| Keymap (Normal) | Keymap (Insert) | Inserts |
|---|---|---|
| `<leader>ltn` | `<C-l>n` | `[N:\|]` — NPC |
| `<leader>ltl` | `<C-l>l` | `[L:\|]` — Location |
| `<leader>ltp` | `<C-l>p` | `[PC:\|]` — Player character |
| `<leader>ltt` | `<C-l>h` | `[Thread:\|Open]` — Thread |
| `<leader>ltr` | `<C-l>r` | `[#N:\|]` — Reference |
| `<leader>ltf` | `<C-l>f` | `[F:\|]` — Foe |

```
:LonelogTag npc
:LonelogTag thread
```

### Progress elements

Clocks, tracks, and timers use smart insert-or-increment logic. On first use, you are prompted for the element name and (for clocks and tracks) the max value (default 5). On subsequent uses, if an incomplete tag exists, it is incremented in-place. If the tag is complete or missing, a fresh one is inserted.

```
<leader>lpc   — insert or increment clock   [E:Name 0/5]
<leader>lpt   — insert or increment track   [Track:Name 0/5]
<leader>lpi   — insert or decrement timer   [Timer:Name 0]
```

Timers always decrement toward 0 and never prompt for max (no max field).

```
:LonelogInsertClock           " prompts for name and max (on fresh insert)
:LonelogInsertClock Alarm     " uses "Alarm" as name, prompts for max if needed
:LonelogInsertTrack Escape 8  " uses "Escape" with max 8 directly
```

### Dice rolling

| Notation | Example | Description |
|---|---|---|
| `NdN` | `1d20` | Basic roll |
| `NdN+M` | `2d6+3` | With modifier |
| `NdN!` | `4d6!` | Exploding dice (reroll on max) |
| `NdNkhK` | `2d20kh1` | Advantage (keep highest K) |
| `NdNklK` | `2d20kl1` | Disadvantage (keep lowest K) |
| `NdN>>T` | `6d6>>4` | Success counting (count dice >= T) |
| `NdN>T` | `2d6>7` | Sum vs target |

```
<leader>lD             " interactive prompt
:LonelogDiceRoll 2d6+3
:LonelogD20            " quick roll 1d20
```

### Oracles

| Oracle | Outcomes | Roll |
|---|---|---|
| Fate | Exceptional Yes, Yes, Yes but..., Maybe, No but..., No, Exceptional No | `<leader>lO` |
| Binary | Yes / No | `:LonelogOracle binary` |
| Mythic | 2d10 + chaos factor (1-9) | `:LonelogOracle mythic` |

Results display in colored floating windows. Adjust the Mythic chaos factor interactively with `<leader>lC`.

### Tag navigation

Browse all entities in your session log. Filter by type and jump directly to any tag.

```
[N:Jonah|friendly|wounded]          — NPC
[L:Library|dark|quiet]              — Location
[PC:Alex|HP 8]                      — Player character
[Thread:Main Quest|Open]            — Thread
[E:Alert 2/6]                       — Event/clock
[F:Matón|HP 6]                      — Foe
[R:3|cleared|biblioteca]            — Room
[Inv:Antorcha|3]                    — Inventory
```

```
<leader>lT    " browse tags by type
:LonelogTags
```

### Tag autocomplete

When typing after `[TYPE:` in a markdown buffer, matching entity names are suggested automatically.

```
<C-l>c        " manual trigger (insert mode)
:LonelogCompleteTag
```

### Scene navigation

Scenes are identified by ID (main, flashback, sub-scene, thread) and sorted chronologically.

```
<leader>lS    " browse scenes
:LonelogScenes
```

### Auto-numbered scene markers

Insert a scene marker with the next ID automatically computed from the last scene in the buffer. When `prompt_for_scene_context` is enabled (default), you are prompted for a context description. If left empty, no context is added.

```
<leader>lM    " insert scene marker (with context prompt if enabled)
:LonelogSceneMarker

  S1 -> S2     S5a -> S5b     S7.1 -> S7.2
  T1-S5 -> T1-S6   S5z -> S6a   (none) -> S1
```

### Inline tables

Define random tables inline and roll them directly:

```markdown
tbl: Forest Encounter (d6)
  1-3: Nothing happens
  4-5: A deer crosses
  6: Bandit ambush!
```

Or use bracket shorthand for equal-probability options:

```markdown
tbl: Weather [Sunny, Cloudy, Rain, Storm]
```

Place the cursor on any `tbl:`, `d:`, or bare dice line and press `<leader>lR`:

```
Before:  tbl: Forest Encounter (d6)
After:   tbl: Forest Encounter d6=4 -> A deer crosses

Before:  d: 2d6+3
After:   d: 2d6+3[4, 2] = 10

Before:  Apariencia: d3
After:   Apariencia: d3=2 -> Normal
```

### Generator blocks

Batch-roll entire sections with a `gen:` header. Place cursor on the `gen:` line and press `<leader>lR`:

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

All indented sub-lines are processed independently. Non-indented lines and empty lines act as delimiters.

### Floating results

Dice and oracle results open in a floating window:

| Key | Action |
|---|---|
| `q` | Close window |
| `y` / `Y` | Copy to system clipboard |
| `<CR>` | Paste result into target `.md` buffer |

`<leader>lI` inserts the most recent result at the cursor.

## Commands

| Command | Description |
|---|---|
| `:Lonelog` | Open main action picker |
| `:LonelogOracle [table]` | Roll an oracle (fate / binary / mythic) |
| `:LonelogDice` | Interactive dice roller |
| `:LonelogDiceRoll <notation>` | Roll specific dice notation |
| `:LonelogD4` through `:LonelogD100` | Quick roll 1dN |
| `:LonelogSymbol <symbol>` | Insert notation symbol (@ ? d arrow conseq) |
| `:LonelogActionSequence` | Insert 3-line action template |
| `:LonelogOracleSequence` | Insert 3-line oracle template |
| `:LonelogTag <type>` | Insert tag snippet (npc/location/pc/thread/ref/foe) |
| `:LonelogInsertClock [name]` | Insert or increment clock |
| `:LonelogInsertTrack [name]` | Insert or increment track |
| `:LonelogInsertTimer [name]` | Insert or decrement timer |
| `:LonelogSceneMarker` | Insert auto-numbered scene marker |
| `:LonelogTags` | Browse Lonelog tags |
| `:LonelogScenes` | Browse Lonelog scenes |
| `:LonelogRollLine` | Roll dice/table on current line |
| `:LonelogCompleteTag` | Trigger tag autocomplete |
| `:LonelogInsert` | Insert last result at cursor |
| `:LonelogChaos` | Open chaos factor UI |

## API

```lua
local ln = require("lonelog")

-- Dice
local result, err = ln.dice.roll("2d6+3")
print(result.display)     -- "2d6+3[4, 2] + 3 = 9"
print(result.total)       -- 9

-- Oracle
local oracle = ln.oracle.roll("fate")
print(oracle.display)     -- "Yes, but..."
print(ln.oracle.get_chaos())  -- number (1-9)
ln.oracle.set_chaos(7)        -- boolean

-- Parse current buffer
local tags   = ln.parsers.parse_tags()
local scenes = ln.parsers.parse_scenes()
local summary = ln.parsers.tags_summary(tags)

-- Inline tables
local tbls = require("lonelog.parsers.tables").parse_tables(lines)
local entry = require("lonelog.parsers.tables").resolve_entry(tbl, value)

-- Tag completion
local comp = require("lonelog.completion")
comp.refresh_completions()
comp.complete_tag()

-- Inline rolling
local modified = require("lonelog.roll_line").process_line(line, tbls)
require("lonelog.roll_line").roll_current_line()
```

## Documentation

See `:help lonelog` for the complete reference including all keymaps, tag formats, dice notation grammar, oracle probabilities, progress element behavior, and the Lonelog spec add-ons (combat, dungeons, resources).

## Requirements

- Neovim **0.8+**
- (Optional) [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for enhanced picker
