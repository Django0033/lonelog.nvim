# Autocomplete con Metadatos

**Date:** 2026-06-01
**Requires:** `completion.lua`

## Objective

Show tag metadata (tags, progress, state) in the completion menu's second
column when typing `[TYPE:name`.

## Current state

`completion.lua` stores only names. Items are `{ word = name }` with no menu
text.

## Changes

### `refresh_completions()`

Store tag tags alongside names:
```lua
groups[tag.type][tag.name] = tag.tags
```

### `complete_tag()`

Build menu text from stored tags:
```lua
local tags = entry.all[matches[i]] or {}
local menu = #tags > 0 and table.concat(tags, ", ") or nil
table.insert(items, { word = matches[i], menu = menu })
```

## Visual result

```
[N:Jon         ]
[Jonah       ] friendly, wounded
[Jonathan    ] brave, lost

[E:Torch      ]
[Torch      ] 3/6

[Thread:Main ]
[Main Quest ] Open
```

## YAGNI

No `abbr`, `kind`, `info`, `icase` fields — only `word` + `menu`.
