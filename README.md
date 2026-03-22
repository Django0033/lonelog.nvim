# lonelog.nvim

A Neovim plugin for solo tabletop RPG players. Provides oracles, dice rolling, and Lonelog navigation (tags, scenes).

## Features

- **Dice Engine**: Standard notation (`2d6+3`), advantage/disadvantage, exploding dice, target numbers
- **Oracle System**: Multiple oracle tables (Fate, Binary, Mythic) with weighted outcomes
- **Lonelog Tags**: Parse and navigate tags like `[N:Name|tags]`, `[L:Location|tags]`, `[E:Event X/Y]`
- **Lonelog Scenes**: Navigate scenes like `S1`, `S2`, `S5a`, `T1-S1`, `S7.1`
- **Offline Support**: Works without Telescope using native sidebar picker
- **Insert Results**: Press `<CR>` in result window to insert into your markdown file

## Installation

Using lazy.nvim:

```lua
{
  "Django0033/lonelog.nvim",
  config = function()
    require("lonelog").setup({
      use_telescope = false,  -- Set to true or "auto" to use Telescope picker
      sidebar = { width = 50 },  -- Sidebar width when Telescope is disabled
    })
  end,
}
```

## Configuration

```lua
require("lonelog").setup({
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

  -- Picker mode: "auto" (default), true (always Telescope), false (always native sidebar)
  use_telescope = "auto",

  -- Sidebar settings (used when use_telescope = false)
  sidebar = { width = 50 },

  -- Floating window settings
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
})
```

## Commands

| Command | Description |
| ------- | ----------- |
| `:LonelogOracle` | Open oracle picker |
| `:LonelogOracle fate` | Roll specific oracle |
| `:LonelogDice` | Interactive dice roller |
| `:LonelogDiceRoll 2d6+3` | Roll dice directly |
| `:LonelogD4` | Quick roll 1d4 |
| `:LonelogD6` | Quick roll 1d6 |
| `:LonelogD8` | Quick roll 1d8 |
| `:LonelogD10` | Quick roll 1d10 |
| `:LonelogD12` | Quick roll 1d12 |
| `:LonelogD20` | Quick roll 1d20 |
| `:LonelogD100` | Quick roll 1d100 |
| `:LonelogTags` | Navigate Lonelog tags |
| `:LonelogScenes` | Navigate Lonelog scenes |
| `:Lonelog` | Open main picker |
| `:LonelogInsert` | Insert last result |

## Keymaps

| Keymap | Action |
| ------ | ------ |
| `<leader>lo` | Open oracle |
| `<leader>ldr` | Roll dice (custom) |
| `<leader>lt` | Navigate tags |
| `<leader>ls` | Navigate scenes |
| `<leader>li` | Insert last result |
| `q` | Close floating window |
| `<CR>` | Insert result into buffer |

### Quick Dice Rolls

| Keymap | Action |
| ------ | ------ |
| `<leader>ld4` | Roll 1d4 |
| `<leader>ld6` | Roll 1d6 |
| `<leader>ld8` | Roll 1d8 |
| `<leader>lda` | Roll 1d10 |
| `<leader>ldb` | Roll 1d12 |
| `<leader>ldw` | Roll 1d20 |
| `<leader>ldc` | Roll 1d100 |

## Native Sidebar Picker

When Telescope is disabled (`use_telescope = false`), the plugin uses a native sidebar picker:

- Opens on the right side of the editor
- `j/k` to navigate
- `Enter` to select
- `q` or `Esc` to close

## Lonelog Tags

The plugin parses and navigates [Lonelog notation](https://github.com/valgur/lonelog) tags:

| Tag Type | Format | Description |
| -------- | ------ | ----------- |
| NPC | `[N:Name|tags]` | Non-player characters |
| Location | `[L:Name|tags]` | Locations |
| Event | `[E:Name X/Y]` | Events and clocks |
| PC | `[PC:Name|stats]` | Player characters |
| Thread | `[Thread:Name|state]` | Story threads |
| Clock | `[Clock:Name X/Y]` | Clocks |
| Track | `[Track:Name X/Y]` | Progress tracks |
| Timer | `[Timer:Name X]` | Countdown timers |
| Inventory | `[Inv:Name|tags]` | Inventory items |
| Room | `[R:Name|tags]` | Rooms |
| Foe | `[F:Name|tags]` | Foes/enemies |

**Variants supported:**
- `[N:Name|tag1 → tag2]` - Change tracking
- `[N:Name|+tag]` - Addition
- `[N:Name|-tag]` - Removal
- `[#N:Name]` - Reference tag

## Lonelog Scenes

Navigate scenes in your play log:

| Scene Type | Format | Example |
| ---------- | ------ | ------- |
| Main | `S#` | `S1`, `S2`, `S3` |
| Flashback | `S#a`, `S#b` | `S5a`, `S8a` |
| Sub-scene | `S#.1`, `S#.2` | `S7.1`, `S7.2` |
| Thread | `T#-S#` | `T1-S1`, `T2-S1` |
| Combined | `T1+T2-S5` | Multi-thread |

## Dice Notation

- Basic: `2d6`, `1d20`
- Modifiers: `2d6+3`, `1d10-2`
- Advantage: `2d20kh1` (keep highest)
- Disadvantage: `2d20kl1` (keep lowest)
- Exploding: `4d6!` (reroll on max)
- Success: `6d6>>4` (count dice >= target)
- Target: `6d6>4` (sum vs target)

## Oracle Tables

- **fate**: Yes, but... / No, but... / Maybe / Exceptional outcomes
- **binary**: Simple Yes/No
- **mythic**: Mythic Game oracle format

## API Usage

```lua
local ln = require("lonelog")

-- Roll dice
local result = ln.dice.roll("2d6+3")
print(result.display)  -- "2d6+3: [4, 2] + 3 = 9"

-- Oracle
local oracle = ln.oracle.roll("fate")
print(oracle.display)  -- "Yes, but..."

-- Parse tags from current buffer
local tags = ln.parsers.parse_tags()

-- Parse scenes from current buffer
local scenes = ln.parsers.parse_scenes()
```

## Requirements

- Neovim 0.8+
- (Optional) telescope.nvim for enhanced picker UI

## License

MIT
