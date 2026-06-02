# Resource Tracking Addon

**Date:** 2026-06-01
**Requires:** `parsers/tags.lua`, `addons/` structure

## Objective

Implement the third official Lonelog addon: inventory items, wealth
tracking, supply dice, and the `--- RESOURCES ---` status block.

## Structure

```
lua/lonelog/addons/resources/
├── init.lua
├── resources.lua    — --- RESOURCES --- block
└── supply.lua       — Supply dice roll + degrade
```

## Components

### 1. Parser: add WEALTH to TAG_TYPES

`parsers/tags.lua`:
```lua
WEALTH = "Wealth",
```

### 2. Config keys

```lua
keymaps = {
  tag_inv       = "<leader>lti",
  tag_wealth    = "<leader>ltw",
  resources_block = "<leader>lrr",
}
```

### 3. addons/resources/init.lua

Registration: commands and keymaps following the same pattern as
combat and dungeon addons.

### 4. addons/resources/resources.lua

Insert a `--- RESOURCES ---` block that scans the buffer for `[Inv:]`
and `[Wealth:]` tags and lists them:

```
--- RESOURCES ---
[Inv:Torch|3]
[Inv:Rope|1]
[Wealth:Gold 50|Silver 12]
---
```

### 5. addons/resources/supply.lua

Supply dice are tracked as fields inside `[PC:]` tags:
`[PC:Kael|Supply d8|Ammo d6]`.

`M.roll_supply()`:
- Find PC tag on current line
- Extract `Supply dN` field
- Roll `1dN`
- If 1-2, degrade to next step (d8→d6→d4→exhausted)
- Update tag in buffer

Degradation chain: `d8 -> d6 -> d4 -> exhausted`

## Tests

~6 tests: insert resources block, supply roll degrades correctly,
keymaps registration, empty inventory list, wealth tag format,
supply roll no degrade (roll 3+).
