# lonelog.nvim - Development Log

**Project:** lonelog.nvim  
**Author:** Eleazar Pequeno  
**Repository:** https://github.com/Django0033/lonelog.nvim  
**License:** MIT  

---

## Project Overview

lonelog.nvim is a Neovim plugin designed for solo tabletop RPG players. It provides an integrated toolkit for random outcome generation, dice rolling, and session log navigation using the Lonelog notation format.

The plugin operates as a pure Lua Neovim plugin with optional Telescope integration, requiring no external dependencies beyond Neovim 0.8+.

### Core Problem Solved

Solo RPG players often need to track NPCs, locations, events, and scenes across extensive session logs while also generating random outcomes and rolling dice. This plugin centralizes these workflows within the editor.

---

## Project Structure

```
lonelog.nvim/
├── lua/lonelog/              # Core modules
│   ├── init.lua              # Entry point and public API
│   ├── config.lua            # Configuration management
│   ├── dice.lua              # Dice rolling engine (220 lines)
│   ├── oracle.lua            # Oracle system (144 lines)
│   ├── parsers/              # Parsing modules
│   │   ├── tags.lua          # Tag parsing (246 lines)
│   │   └── scenes.lua        # Scene parsing (239 lines)
│   └── ui/                   # UI modules
│       ├── ui.lua            # Module index with exports (20 lines)
│       ├── floating.lua      # Floating windows (228 lines)
│       ├── picker.lua        # Picker abstraction (29 lines)
│       └── sidebar.lua       # Native picker (118 lines)
├── plugin/
│   └── lonelog.lua           # Vim commands and keybindings
├── tests/
│   ├── test_dice.lua        # 19 dice engine tests
│   ├── test_tags.lua        # 14 tag parser tests
│   ├── test_scenes.lua      # 8 scene parser tests
│   └── test_integration.lua # 17 integration tests
├── SPEC.md                  # Technical specification
├── REFACTORING.md           # Refactoring notes
├── DEVLOG.md               # Development log
└── README.md                # User documentation
```

---

## Git History

### Commit `05e93e1` - Initial Commit
**Date:** 2026-03-22  
**Files:** `.gitignore`, `LICENSE`  

Established project foundation with MIT license and comprehensive `.gitignore` for Neovim plugins.

---

### Commit `4c48dfa` - Initial Implementation
**Date:** 2026-03-22  
**Files:** 16 files, 2,358 insertions  

Full plugin implementation including:

| Module | Description |
|--------|-------------|
| `dice.lua` | Dice engine with standard notation, advantage/disadvantage, exploding dice, target numbers |
| `oracle.lua` | Fate, Binary, and Mythic oracle tables with weighted random selection |
| `parsers.lua` | Lonelog tag and scene parsing (NPC, Location, Event, PC, Thread, Clock, etc.) |
| `sidebar.lua` | Native picker as Telescope alternative |
| `ui.lua` | Floating windows and result insertion |
| `plugin/lonelog.lua` | Vim commands and keybindings |

**Documentation:** README.md, SPEC.md, REFACTORING.md  
**Testing:** 58 tests covering dice, tags, scenes, and integration

---

### Commit `d7dbdda` - Bug Fixes
**Date:** 2026-03-22  
**Files:** `.gitignore`, `README.md`  

- Added generated Reddit user files to `.gitignore`
- Fixed GitHub username in README installation example

---

### Commit `b50ac73` - Documentation Fix
**Date:** 2026-03-22  
**Files:** `README.md`  

- Corrected dice notation documentation (`6d6>>4` for success counting)
- Clarified distinction between sum notation (`6d6>4`) and success counting (`6d6>>4`)

---

### Commit `e2a0cce` - Add clipboard copy feature
**Date:** 2026-03-25  
**Files:** `lua/lonelog/ui.lua`  

- Add `M.copy_result()` function for clipboard operations
- Add 'y' and 'Y' keymaps in floating windows
- Copy to system clipboard using '+' register
- Update help messages in result windows

---

### Commit `0d401aa` - Simplify insert with copy+paste
**Date:** 2026-03-25  
**Files:** `lua/lonelog/ui.lua`  

- Refactor `M.insert_result()` to use copy+paste instead of complex position calculations
- `<CR>` now copies result to clipboard and pastes in target buffer
- Simplifies cursor position handling across different buffer states

---

### Commit `42170b9` - Module Refactoring
**Date:** 2026-03-25  
**Files:** Multiple files  

- Split monolithic `parsers.lua` into modular structure:
  - `lua/lonelog/parsers/tags.lua` - Tag parsing functions
  - `lua/lonelog/parsers/scenes.lua` - Scene parsing functions
  - `lua/lonelog/ui/parsers.lua` - Unified exports
- Split monolithic `ui.lua` into:
  - `lua/lonelog/ui/floating.lua` - Floating window management
  - `lua/lonelog/ui/picker.lua` - Picker abstraction layer
  - `lua/lonelog/ui.lua` - Clean index with exports
- Added `should_use_telescope()` helper to parsers modules
- Fixed parser paths in `init.lua` and `plugin/lonelog.lua`
- Updated tests with complete vim mocks
- Total: 58 tests passing

---

## Architecture

### Core Modules

```
┌─────────────────────────────────────────────────────────────┐
│                     plugin/lonelog.lua                       │
│              (Commands and keybindings)                     │
└──────────────────────────┬──────────────────────────────────┘
                           │
┌──────────────────────────▼──────────────────────────────────┐
│                      lua/lonelog/init.lua                     │
│                  (Public API entry point)                    │
└───────┬─────────────┬─────────────┬─────────────┬────────────┘
        │             │             │             │
┌───────▼────┐ ┌──────▼─────┐ ┌────▼────┐ ┌─────▼─────┐
│  config.lua │ │  dice.lua  │ │oracle.lua│ │    ui/    │
│             │ │            │ │          │ │           │
│ - defaults  │ │ - notation │ │ - tables │ │ - ui.lua  │
│ - setup()   │ │ - rolls    │ │ - chaos   │ │ - sidebar │
│ - get()     │ │ - helpers  │ │ - format  │ │ - parsers │
└─────────────┘ └────────────┘ └──────────┘ └───────────┘
```

### UI Abstraction Layer

The plugin implements a dual picker system:

1. **Telescope Picker** (optional) - Uses `telescope.nvim` if available
2. **Native Sidebar** - Custom floating window implementation

The `ui.pick()` function automatically selects the appropriate picker based on configuration and availability.

### Parsing System

The parsers directory handles two main parsing tasks:

1. **Tag Parsing** (`parsers/tags.lua`) - Extracts structured data from Lonelog tags
2. **Scene Parsing** (`parsers/scenes.lua`) - Identifies scene markers and builds navigation indices

The `ui/parsers.lua` module provides unified exports for both parsers.

---

## Features Implemented

### Dice Engine

**Supported Notation:**

| Type | Example | Description |
|------|---------|-------------|
| Basic | `2d6`, `1d20` | Standard dice notation |
| Modifiers | `2d6+3`, `1d10-2` | Add/subtract from roll |
| Exploding | `4d6!` | Reroll on max value |
| Advantage | `2d20kh1` | Keep highest die |
| Disadvantage | `2d20kl1` | Keep lowest die |
| Success Count | `6d6>>4` | Count rolls >= target |
| Sum vs Target | `2d6>7` | Success if sum >= target |

**Quick Roll Commands:** d4, d6, d8, d10, d12, d20, d100

---

### Oracle System

**Available Tables:**

| Table | Entries | Use Case |
|-------|---------|----------|
| **Fate** (default) | 7 outcomes | General yes/no questions |
| **Binary** | 2 outcomes | Simple yes/no |
| **Mythic** | 2d10 + chaos | Detailed narrative prompts |

**Mythic Chaos Factor:** Modifier range from -5 to +5, affecting roll outcomes.

---

### Tag System

**Supported Tag Types:**

| Key | Type | Example |
|-----|------|---------|
| `N` | NPC | `[N:Jonah|friendly|wounded]` |
| `L` | Location | `[L:Library|dark]` |
| `E` | Event | `[E:Alert 2/6]` |
| `PC` | Player Character | `[PC:Alex|HP 8]` |
| `THREAD` | Thread | `[Thread:Main Quest|Open]` |
| `CLOCK` | Clock | `[Clock:Ritual 1/8]` |
| `TRACK` | Track | `[Track:Escape 3/8]` |
| `TIMER` | Timer | `[Timer:Dawn 3]` |
| `INV` | Inventory | `[Inv:Slot 1|rifle]` |
| `R` | Room | `[R:1|active]` |
| `F` | Foe | `[F:Flesh blob|dead]` |

**Tag Features:**
- Reference tags: `[#N:Jonah]`
- Changes: `friendly → hostile`
- Additions: `+captured`
- Removals: `-wounded`

---

### Scene Navigation

**Scene Types:**

| Type | Format | Sort Order |
|------|--------|------------|
| Main | `S1`, `S2` | Chronological |
| Flashback | `S5a`, `S8b` | After main scenes |
| Sub-scene | `S7.1`, `S7.2` | Nested in parent |
| Thread | `T1-S1`, `T2-S1` | Parallel storylines |

---

### UI Features

- **Floating Windows** - Centered results display with rounded borders
- **Native Sidebar Picker** - Telescope alternative with keyboard navigation (j/k)
- **Clipboard Copy** - Press 'y' in result window to copy to system clipboard
- **Copy+Paste Insertion** - Press Enter in result window to copy and paste result
- **Markdown Integration** - Optimized for `.md` buffer targets

---

## Testing

**Test Suite:** 58 tests across 4 files

| Test File | Tests | Coverage |
|-----------|-------|----------|
| `test_dice.lua` | 19 | Dice notation parsing, rolling, edge cases |
| `test_tags.lua` | 14 | Tag parsing, references, changes, additions |
| `test_scenes.lua` | 8 | Scene detection, sorting, thread notation |
| `test_integration.lua` | 17 | Full picker flows, mock vim.ui.select |

**Test Strategy:** Full `vim` mock with `api`, `fn`, `o` modules for standalone execution.

---

## Future Possibilities

Features are ordered by implementation complexity, starting with the simplest.

### Low Complexity

These features require minimal changes and extend existing patterns.

---

**1. Dice Roll History**

Track the last N dice rolls and oracle results during a session, viewable via a command or sidebar view.

*Why it fits:* The UI module already tracks `active_windows` and `window_content`. Adding a history array follows existing patterns.

---

**2. Tag Search by Name**

Add a search/filter input when opening the tags picker, allowing users to type part of a tag name to filter before selecting.

*Why it fits:* The parsers already extract structured tag data. The sidebar can be extended with a filter prompt before showing results.

---

**3. Configurable Dice Notation**

Allow users to customize the dice notation format (e.g., use `d` instead of `D`, change the exploding symbol).

*Why it fits:* The dice parser already handles multiple formats case-insensitively. Adding config options requires minimal changes.

---

**4. Persistent Chaos Factor**

Save the Mythic oracle's chaos factor to a file and restore it on Neovim restart.

*Why it fits:* The chaos factor exists in module state. File persistence using `vim.fn.stdpath("data")` extends this cleanly.

---

**5. Custom Oracle Tables**

Allow users to define custom oracle tables with weighted entries in their config.

*Why it fits:* The oracle system uses weighted random selection. User tables would extend the `tables` table naturally.

---

### Medium Complexity

These features require new modules or significant UI changes.

---

**6. Dice Macro System**

Define named dice roll sequences in config (e.g., `attack = "2d6+3"`) that can be rolled via commands.

*Why it fits:* The dice engine already parses complex notation. A macro system would substitute definitions before passing to `dice.roll()`.

---

**7. Insertable Tag Templates**

Provide commands or keybindings that insert common tag templates at cursor (e.g., `<leader>ln` inserts `[N:Name|]`).

*Why it fits:* The `ui.insert_result()` function handles text insertion. A templates module would use the same mechanism.

---

**8. Session Roll Statistics**

Generate a session summary showing dice rolls by type, oracle result distribution, and tag/scene counts.

*Why it fits:* Parsers extract tags and scenes. A statistics aggregator would extend the parser infrastructure.

---

**9. Custom Random Tables Generator**

Allow users to define custom random tables in config and roll against them via command.

*Why it fits:* The oracle system provides a proven pattern for weighted random selection. A new `tables.lua` module would mirror this architecture.

---

**10. Scene Graph View**

Display scenes as a tree or hierarchical list in a floating window, showing relationships more clearly.

*Why it fits:* Scene parsing extracts type and context. A visualization module could render structure using ASCII art or virtual text.

---

### High Complexity

These features require new systems, significant architecture changes, or external integrations.

---

**11. Auto-completion de Tags**

Completion para nombres de tags mientras escribes en buffers markdown.

*Why it fits:* Omnicompletion or inline completion triggered in markdown buffers, suggesting NPC names, locations, and other tags from the current file.

**Complejidad:** ~100 líneas

---

**12. Chaos Factor UI**

Ajuste visual e interactivo del Chaos Factor (1-9) para el oráculo Mythic.

*Why it fits:* A floating window or status display showing the current chaos factor with +/- controls, persisted in config.

**Complejidad:** ~60 líneas

---

**13. Multi-File Campaign Navigation**

Extend tag and scene navigation to work across multiple session files, with a campaign-level index.

*Why it fits:* Parsers work on buffer content and could scan multiple files. This requires a new indexer module and campaign-scoped pickers.

---

**14. Character Sheet Integration**

Parse PC tags with stat blocks and provide a character sheet view that auto-updates based on parsed tags.

*Why it fits:* PC tag parsing already exists. A character sheet module would parse, render, and provide stat modification commands.

---

**15. Automated Dungeon/Room Generator**

Use configured generators to create dungeon maps or room sequences, outputting Lonelog format tags.

*Why it fits:* Session files show complex room tracking. A generator could combine random tables with room connection logic.

---

**16. Interactive Combat Tracker**

Track combat rounds, initiative order, and enemy HP using a dedicated buffer or floating window.

*Why it fits:* The Foe tag type exists. A combat tracker would extend this with round tracking, initiative sorting, and damage application.

---

**17. Campaign Archive/Export**

Export a campaign's session logs to a consolidated format (HTML, PDF, unified markdown) with cross-referenced tags.

*Why it fits:* Parser infrastructure extracts all campaign elements. An export module would aggregate and render this data.

---

## Contributing

Contributions are welcome. Please ensure all tests pass before submitting pull requests.

```bash
# Run tests (if test runner is configured)
make test
```

---

## License

MIT License - See LICENSE file for details.
