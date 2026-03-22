# lonelog.nvim - Specification

A Neovim plugin for solo tabletop RPG players: oracles, dice rolling, and Lonelog tag/scene navigation.

## Overview

**Goal**: Help solo RPG players with random tables, fate oracles, dice mechanics, and Lonelog notation navigation.

**Target users**: Solo tabletop RPG players who use Neovim as their creative writing tool.

## Project Structure

```
lonelog.nvim/
├── lua/lonelog/
│   ├── init.lua           # Entry point, public API
│   ├── config.lua         # Configuration handling
│   ├── oracle.lua         # Oracle system
│   ├── dice.lua           # Dice rolling engine
│   └── ui/
│       ├── ui.lua         # Floating windows, result display
│       ├── sidebar.lua    # Native picker (Telescope alternative)
│       └── parsers.lua    # Lonelog tags and scenes parser
├── plugin/
│   └── lonelog.lua        # Commands and keymaps
├── README.md
└── SPEC.md
```

## Configuration

### Default Options

```lua
{
  -- Keybindings
  keymaps = {
    oracle = "<leader>lo",
    dice = "<leader>ldr",
    tags = "<leader>lt",
    scenes = "<leader>ls",
    d4 = "<leader>ld4",
    d6 = "<leader>ld6",
    d8 = "<leader>ld8",
    d10 = "<leader>lda",
    d12 = "<leader>ldb",
    d20 = "<leader>ldw",
    d100 = "<leader>ldc",
  },

  -- Picker mode: "auto" | true | false
  use_telescope = "auto",

  -- Sidebar picker settings (when use_telescope = false)
  sidebar = { width = 50 },

  -- Floating window options
  float = {
    border = "rounded",
    height = 0.4,
    width = 0.6,
  },

  -- Oracle settings
  oracle = {
    default_table = "fate",
  },

  -- Dice settings
  dice = {
    max_dice = 100,
    max_sides = 1000,
  },
}
```

### use_telescope Options

| Value | Behavior |
|-------|----------|
| `"auto"` | Use Telescope if available, native sidebar otherwise |
| `true` | Always use Telescope picker |
| `false` | Always use native sidebar picker |

## Core Modules

### 1. Dice Engine (`dice.lua`)

#### Supported Notation

- Basic: `NdN` (e.g., `2d6`, `1d20`)
- Modifiers: `NdN+M` or `NdN-M` (e.g., `2d6+3`)
- Exploding dice: `NdN!` (reroll on max, e.g., `4d6!`)
- Success roll: `NdN>>T` (count dice >= target, e.g., `6d6>>4`)
- Sum vs target: `NdN>T` (e.g., `2d6+3>7`)

#### API

```lua
-- Parse and roll dice notation
lonelog.dice.roll(notation: string): DiceResult | nil, error

-- Result table structure
{
  original = "2d6+3",
  rolls = {5, 2},
  modifier = 3,
  total = 10,
  display = "2d6+3[5, 2] = 10",
}
```

### 2. Oracle System (`oracle.lua`)

#### Oracle Tables

**Fate Oracle (default)**

| Result | Probability |
|--------|-------------|
| Exceptional Yes | 8% |
| Yes | 23% |
| Yes, but... | 15% |
| Maybe | 28% |
| No, but... | 15% |
| No | 8% |
| Exceptional No | 3% |

**Binary Oracle**: Yes (50%), No (50%)

**Mythic Oracle**: Uses 2d10 + chaos factor (1-9)

#### API

```lua
-- Roll oracle with table name or default
lonelog.oracle.roll(table?: string): OracleResult | nil, error

-- Get/set chaos factor for Mythic oracle
lonelog.oracle.get_chaos(): number
lonelog.oracle.set_chaos(value: number): boolean

-- List available tables
lonelog.oracle.list_tables(): string[]

-- Result structure
{
  table = "fate",
  table_name = "Fate Oracle",
  value = "yes_but",
  display = "Yes, but...",
}
```

### 3. UI Module

#### Sidebar Picker (`ui/sidebar.lua`)

Native picker when Telescope is disabled.

```lua
-- Open sidebar with items
lonelog.ui.sidebar.open(title, items, opts): bufnr, win_id

-- opts:
--   format_item: fun(item, idx): string
--   on_select: fun(item)
--   data: original data objects

-- Close sidebar
lonelog.ui.sidebar.close()

-- Check if open
lonelog.ui.sidebar.is_open(): boolean
```

**Keybindings:**
- `j/k`: Navigate
- `Enter`: Select
- `q/Esc`: Close

#### Floating Windows (`ui.lua`)

```lua
-- Show result in floating window
lonelog.ui.show_result(title, lines, opts)
lonelog.ui.show_dice_result(result)
lonelog.ui.show_oracle_result(result)

-- Insert result at cursor
lonelog.ui.insert_result(win_id)

-- Get last result for insertion
lonelog.ui.get_latest_content(): win_id, content

-- Check if can insert (must be .md file)
lonelog.ui.can_insert_here(): boolean
```

### 4. Parsers (`ui/parsers.lua`)

#### Tags

```lua
-- Parse all tags from buffer
lonelog.parsers.parse_tags(bufnr?: number): Tag[]

-- Format tag for display
lonelog.parsers.format_tag_display(tag): string

-- Count tags by type
lonelog.parsers.tags_summary(tags): Summary

-- Show tags picker
lonelog.parsers.show_tags_picker()
lonelog.parsers.show_tags_picker_native(tags)  -- Native version
```

**Tag Structure:**
```lua
{
  type = "N",
  type_label = "NPC",
  name = "Jonah",
  tags = {"friendly", "wounded"},
  changes = {"friendly → hostile"},
  additions = {"+captured"},
  removals = {"-wounded"},
  is_reference = false,
  line = 42,
  raw = "[N:Jonah|friendly|wounded]",
}
```

#### Scenes

```lua
-- Parse all scenes from buffer
lonelog.parsers.parse_scenes(bufnr?: number): Scene[]

-- Format scene for display
lonelog.parsers.format_scene_display(scene): string

-- Count scenes by type
lonelog.parsers.scenes_summary(scenes): Summary

-- Sort scenes by ID
lonelog.parsers.sort_scenes(scenes): Scene[]

-- Show scenes picker
lonelog.parsers.show_scenes_picker()
lonelog.parsers.show_scenes_picker_native(scenes)  -- Native version
```

**Scene Structure:**
```lua
{
  type = "main",
  type_label = "Main",
  scene_id = "S1",
  context = "Meeting the stranger",
  location = "Tavern",
  line = 15,
  raw = "S1 *Meeting the stranger* [L:Tavern]",
  sort_key = "000001.000000",
}
```

## Commands

| Command | Description |
|---------|-------------|
| `:LonelogOracle` | Open oracle picker |
| `:LonelogOracle fate` | Roll specific oracle |
| `:LonelogDice` | Interactive dice roller |
| `:LonelogDiceRoll <notation>` | Roll dice directly |
| `:LonelogD4` | Quick roll 1d4 |
| `:LonelogD6` | Quick roll 1d6 |
| `:LonelogD8` | Quick roll 1d8 |
| `:LonelogD10` | Quick roll 1d10 |
| `:LonelogD12` | Quick roll 1d12 |
| `:LonelogD20` | Quick roll 1d20 |
| `:LonelogD100` | Quick roll 1d100 |
| `:LonelogTags` | Navigate tags |
| `:LonelogScenes` | Navigate scenes |
| `:Lonelog` | Open main picker |
| `:LonelogInsert` | Insert last result |

## Keymaps (Default)

| Keymap | Action |
|--------|--------|
| `<leader>lo` | Open oracle |
| `<leader>ldr` | Roll dice |
| `<leader>lt` | Navigate tags |
| `<leader>ls` | Navigate scenes |
| `<leader>li` | Insert last result |
| `<leader>ld4` | Roll 1d4 |
| `<leader>ld6` | Roll 1d6 |
| `<leader>ld8` | Roll 1d8 |
| `<leader>lda` | Roll 1d10 |
| `<leader>ldb` | Roll 1d12 |
| `<leader>ldw` | Roll 1d20 |
| `<leader>ldc` | Roll 1d100 |
| `q` | Close floating window (when focused) |
| `<CR>` | Insert result into .md buffer |

## Dependencies

- **Required**: None (pure Lua)
- **Optional**: `telescope.nvim` (for enhanced picker UI)

## Compatibility

- Neovim 0.8+
- Lua 5.1+ (LuaJIT in Neovim)

## License

MIT
