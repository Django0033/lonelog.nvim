# Pending Features

## Phase 2 — Obsidian parity

| # | Feature | Effort | Notes |
|---|---------|--------|-------|
| 1 | Campaign header modal (5 fields) | ~30 lines | `:LonelogCampaign` currently asks title only |
| 2 | Tokenizer unificado | ~70 lines | Classify lines by prefix for future features |
| 3 | Parser de prosa (meta, dialogue, narrative) | ~50 lines | Parse `(note:)`, `Name: "text"`, `---` blocks |
| 4 | Parser de combate completo | ~120 lines | Parse `[COMBAT]` blocks with rounds, combatants |
| 5 | Autocomplete con metadatos | ~80 lines | Show tags/progress in completion menu column |
| 6 | Frontmatter YAML init + auto-update | ~80 lines | Initialize note properties, update `last_modified` |
| 7 | Resaltado de sintaxis configurable | ~200 lines | 16 customizable colors (Obsidian parity) |
| 8 | i18n EN/ES | ~200 lines | Full translation of all UI strings |
| 9 | ParsedElements Cache | ~100 lines | ✅ Done |

## Phase 3 — Lonelog spec addons

| # | Feature | Effort | Notes |
|---|---------|--------|-------|
| 10 | Resource Tracking addon | ~200 lines | `[Inv:]`, `[Wealth:]`, Supply dice, `--- RESOURCES ---` |

## Deferred / descartados

| Feature | Reason |
|---------|--------|
| Insert Dialogue | Postponed, format TBD |
| Toggle code block (`` ```lonelog ``) | Low utility in Neovim |
| Forced S/F flag | Explicitly removed by user |
| Sidebar views (Dashboard, Progress, etc.) | Not applicable — Neovim uses pickers |
| 3D dice animation | Not applicable — terminal |
| Settings UI | Neovim uses `setup({})` |
