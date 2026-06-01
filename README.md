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

> [!TIP]
> Open a `.md` file, press `<leader>lO` to roll an oracle, then `<leader>lsm` to insert a scene marker.

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
require("lonelog").setup()
```
</details>

---

## What it looks like

A session log in a markdown buffer:

```markdown
## Session 5

### S1 *The abandoned mine*
@ Enter the darkness
? Is anyone here?
d: 2d6+3 -> 9  [N:Elara|waiting]
=> The tunnel is empty, but torchlight flickers ahead.
[E:Torch 3/6]

### S2 *Collapsed passage*
d: 1d20>=15 -> 17 >= 15 -> Success
@ Clear the rubble
[F:Goblin|HP 6|alerta]
```

Press `<leader>lR` on any `d:` line to roll and replace the result in-place:

```markdown
d: 1d20>=15 -> 1d20>=15[17] = 17 >= 15 -> Success
```

---

## Quick start

Press `<leader>` followed by these keys:

### Core actions

| Key | Action |
|-----|--------|
| `<leader>lO` | Roll an oracle (fate, binary, mythic) |
| `<leader>lD` | Interactive dice roller |
| `<leader>lR` | Roll dice/table on current line |
| `<leader>lT` | Browse all tags |
| `<leader>lS` | Browse all scenes |
| `<leader>lC` | Adjust Mythic chaos factor |
| `<leader>lI` | Insert last result |

### Session

| Key | Action |
|-----|--------|
| `<leader>lsh` | Insert session header |
| `<leader>lsc` | Insert campaign header |
| `<leader>lsm` | Insert scene marker |
| `<leader>lsn` | Insert narrative block |
| `<leader>lss` | Show session summary |
| `<leader>l[` / `<leader>l]` | Navigate scenes |

### Insert notation

| Normal | Insert | Inserts |
|--------|--------|---------|
| `<leader>lia` | `<C-l>a` | `@ ` — action |
| `<leader>liq` | `<C-l>q` | `? ` — question |
| `<leader>lid` | `<C-l>d` | `d: ` — dice |
| `<leader>liN` | `<C-l>N` | `@(Name) ` — actor |

### Entity tags

| Normal | Insert | Tag |
|--------|--------|-----|
| `<leader>ltn` | `<C-l>n` | `[N:\|]` — NPC |
| `<leader>ltl` | `<C-l>l` | `[L:\|]` — Location |
| `<leader>ltp` | `<C-l>p` | `[PC:\|]` — PC |
| `<leader>ltt` | `<C-l>h` | `[Thread:\|Open]` |
| `<leader>ltr` | `<C-l>r` | `[#N:\|]` — Reference |
| `<leader>ltf` | `<C-l>f` | `[F:\|]` — Foe |

### Progress

| Key | Element | Format |
|-----|---------|--------|
| `<leader>lpc` | Clock | `[E:Name 0/5]` |
| `<leader>lpt` | Track | `[Track:Name 0/5]` |
| `<leader>lpi` | Timer | `[Timer:Name 0]` |

---

## Configuration

```lua
require("lonelog").setup({
  use_telescope = "auto",         -- "auto" | true | false
  float = { border = "rounded", height = 0.4, width = 0.6 },
  oracle = { default_table = "fate", persist_chaos = true },
  dice = { max_dice = 100, max_sides = 1000 },
  prompt_for_scene_context = true,
  keymaps = { /* see :help lonelog-keymaps */ },
})
```

> [!TIP]
> Disable or rebind any keymap:
> ```lua
> keymaps = {
>   oracle = false,             -- disable entirely
>   scene_marker = "<leader>z", -- rebind
> }
> ```

---

## Add-ons

Bundled but disabled by default. Enable the ones you need:

```lua
require("lonelog").setup({
  addons = {
    combat  = true,   -- [COMBAT] blocks, round markers, auto-roster
    dungeon = true,   -- Dungeon Status block, room navigation, room states
  },
})
```

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
| `d: 2d6, 1d8` | — | Multiple rolls on one line |

---

## Commands

| Command | Description |
|---------|-------------|
| `:Lonelog` | Main action picker |
| `:LonelogOracle [table]` | Roll oracle |
| `:LonelogDiceRoll <notation>` | Roll specific dice |
| `:LonelogRollLine` | Roll current line |
| `:LonelogTags` / `:LonelogScenes` | Browse tags / scenes |
| `:LonelogSession` / `:LonelogCampaign` | Insert headers |
| `:LonelogSessionSummary` | Show session summary |

See `:help lonelog-commands` for the full list (30+ commands).

---

## Documentation

```vim
:help lonelog
```

Covers all keymaps, notation format, oracle probabilities, tag autocomplete, syntax highlighting, and session workflow tips.

## Requirements

- Neovim **0.8+** — requires `vim.ui.input`, `vim.ui.select`, `nvim_open_win`
- (Optional) [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) for enhanced picker
- Zero external dependencies — pure Lua
