# Frontmatter YAML Init + Auto-update

**Date:** 2026-06-01
**Requires:** `commands/campaign.lua`, `plugin/lonelog.lua`

## Objective

Improve campaign YAML frontmatter creation with a multi-field modal and
add automatic `last_update` date updates on buffer write.

## Changes

### 1. Multi-field campaign modal

Replace single `vim.ui.input` for title with a sequence of 5 prompts:
title, ruleset, genre, player, PCs. Optional fields default to empty.

### 2. Auto-update `last_update`

New `BufWritePre` autocmd in `plugin/lonelog.lua` that:
- Checks if buffer starts with `---` (frontmatter marker)
- Finds the `last_update:` line (within first 5 lines)
- Replaces it with today's date

### 3. Config defaults (optional)

Add `campaign` section to `config.lua`:
```lua
campaign = {
  default_ruleset = "",
  default_genre = "",
  default_player = "",
}
```

## Tests

~4 tests:
- build_campaign_header with all fields
- has_frontmatter detects existing YAML
- auto-update replaces last_update
- buffer without frontmatter no crash

## YAGNI

- Custom frontmatter fields
- YAML validation
- Multi-file support
