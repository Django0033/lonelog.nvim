# Slot-Based Inventory

**Date:** 2026-06-02
**Requires:** `addons/resources/`

## Objective

Add slot-based inventory management: insert `[Inv:Slot N|item]` tags and summarize slot occupancy.

## Changes

### 1. Config key

```lua
slot_insert = "<leader>lts",
```

### 2. SlotInsert command

`:LonelogSlotInsert`:
- Prompt for slot number (e.g. `1` or `5-10`)
- Prompt for contents (e.g. `Sword`, `Torch×3`, `empty`)
- Insert `[Inv:Slot N|contents]` at cursor

### 3. SlotSummary command

`:LonelogSlotSummary`:
- Scan buffer for all `[Inv:Slot N|...]` tags
- Analyze occupancy: used slots, empty ranges, highest slot
- Display summary in notification

### 4. Registration

Both commands registered in `addons/resources/init.lua`.
Functions in `addons/resources/resources.lua`.

## Testing

~4 tests: slot insert format, summary parsing, no slots found, range slots.
