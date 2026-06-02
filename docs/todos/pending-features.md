# Pending Features

## Phase 2 — Obsidian parity

| # | Feature | Effort | Notes |
|---|---------|--------|-------|
| 1 | Campaign header modal (5 fields) | ~30 lines | ✅ Done |
| 2 | Tokenizer unificado | ~70 lines | ✅ Done |
| 3 | Parser de prosa (meta, dialogue, narrative) | ~50 lines | ✅ Done |
| 4 | Parser de combate completo | ~120 lines | ✅ Done |
| 5 | Autocomplete con metadatos | ~80 lines | ✅ Done |
| 6 | Frontmatter YAML init + auto-update | ~80 lines | ✅ Done |
| 7 | Resaltado de sintaxis configurable | ~30 lines | ✅ Done |
| 8 | i18n EN/ES | ~200 lines | Full translation of all UI strings |
| 9 | ParsedElements Cache | ~100 lines | ✅ Done |

## Phase 3 — Lonelog spec addons

| # | Feature | Effort | Notes |
|---|---------|--------|-------|
| 10 | Resource Tracking addon | ~200 lines | ✅ Done |

## Insert commands faltantes

| # | Feature | Effort | Notes |
|---|---------|--------|-------|
| 11 | PC stat update keymap | ~10 lines | Insert `[PC:Name\|HP-2]` |
| 12 | NPC status update keymap | ~10 lines | Insert `[N:Name\|+tag]` / `[N:Name\|-tag]` / `[N:Name\|old→new]` |
| 13 | Wealth delta commands | ~20 lines | `[Wealth:Gold+15]` / `[Wealth:Gold-8]` |
| 14 | Inventory delta commands | ~20 lines | `[Inv:Torch-1]` / `[Inv:Torch+2]` / `[Inv:Item\|depleted]` |
| 15 | Item state change commands | ~10 lines | `[Inv:Sword\|rusty→repaired]` / `[Inv:Sword\|+enchanted]` |
| 16 | Roll context insertion | ~10 lines | Insert `[tags]` inside `d:` lines |
| 17 | Session duration/scenes prompt | ~5 lines | Add Duration and Scenes fields to session header |
| 18 | Supply track commands | ~30 lines | `[PC:Name\|Supply 4/5]` inc/dec |
| 19 | Qualitative supply commands | ~20 lines | `[PC:Name\|Supplies:abundant→low]` |
| 20 | Abstract wealth commands | ~20 lines | `[PC:Name\|Wealth d8]` / `[PC:Name\|Resources 3/5]` |
| 21 | Combat movement notation | ~20 lines | `[Far->Close]` / zone tracking |
| 22 | Combat encounter snapshot | ~20 lines | Pre-R1 battlefield encounter listing |
| 23 | Initiative note command | ~10 lines | `R1 (Init: Name N, ...)` |
| 24 | Trade/barter notation | ~10 lines | Record item-for-item exchanges |
| 25 | Slot-based inventory | ~50 lines | `[Inv:Slot N\|Item]` with encumbrance |
| 26 | Bulk/container items | ~30 lines | `[Inv:Arrow×20]` / container contents |

## Deferred / descartados

| Feature | Reason |
|---------|--------|
| Insert Dialogue | Postponed, format TBD |
| Toggle code block (`` ```lonelog ``) | Low utility in Neovim |
| Forced S/F flag | Explicitly removed by user |
| Sidebar views (Dashboard, Progress, etc.) | Not applicable — Neovim uses pickers |
| 3D dice animation | Not applicable — terminal |
| Settings UI | Neovim uses `setup({})` |
