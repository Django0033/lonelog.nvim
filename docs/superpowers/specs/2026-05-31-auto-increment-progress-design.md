# Auto-Incremento de Progress Elements

**Fecha:** 2026-05-31
**Estado:** Design approved, pending implementation
**Basado en:** `../lonelog/src/commands/notation.ts` (Obsidian plugin v1.4.0)

## Resumen

Progreso (clocks, tracks, timers) se actualizan constantemente durante una
sesión de solo TTRPG. Editar `[E:Alert 2/6 →3/6]` a mano es tedioso. Este
feature permite incrementar/decrementar con un solo comando.

## Comportamiento

Cada comando busca en el buffer un tag existente del mismo tipo+nombre.
Si existe y no está completo, modifica su valor en el lugar.
Si no existe o está completo, inserta uno fresco en la línea actual.

### Tabla de comportamiento

| Comando | Tag | Si existe e incompleto | Si no existe o completo |
|---------|-----|----------------------|------------------------|
| `InsertClock [Name]` | `[E:Name X/Y]` o `[Clock:Name X/Y]` | Reemplaza X→X+1 (cap en Y) | Inserta `[E:Name 0/6]` |
| `InsertTrack [Name]` | `[Track:Name X/Y]` | Reemplaza X→X+1 (cap en Y) | Inserta `[Track:Name 0/6]` |
| `InsertTimer [Name]` | `[Timer:Name X]` | Reemplaza X→X-1 (cap en 0) | Inserta `[Timer:Name 0]` |

### Reglas de completitud

- Clock/Track: se considera **completo** si X >= Y (no se incrementa más).
- Timer: se considera **completo** si X <= 0 (no se decrementa más).
- Si se invoca un clock/track completo, se inserta uno fresco.
  El usuario puede renombrarlo para empezar uno nuevo.

## Archivos a modificar/crear

### 1. `lua/lonelog/commands/progress.lua` (nuevo, ~50 líneas)

**Dependencias:** `lonelog.parsers.tags` (no, en realidad es autónomo)

```lua
-- Busca un progress tag por tipo y nombre en el buffer.
-- Devuelve { line_num, line_text, current, max } o nil.
local function find_progress(bufnr, type_pattern, name)

-- Incrementa o inserta un progress element.
-- type_key: uno de "E", "CLOCK", "TRACK", "TIMER"
-- name: nombre a buscar (case-insensitive)
-- max_default: default si se inserta fresco (6 para clocks/tracks)
function M.increment_progress(type_key, name, max_default)
```

**Lógica de `find_progress()`:**

1. Obtiene `nvim_buf_get_lines(bufnr, 0, -1, false)`
2. Para cada línea, busca con regex: `%[(%w+):([^%]]+)%]`
   - Valida que el tipo coincida con type_pattern (case-insensitive):
     `E`, `Clock` (alias de `E`), `Track`, `Timer`
3. Del contenido capturado (todo entre `:` y `]`):
   a. Divide por `|` y toma el primer segmento
   b. Del segmento, parsea `(.-)%s+(%d+/?%d*)$` para extraer
      nombre y valor numérico
4. Coincidencia de nombre **case-insensitive**
5. Parsea la cadena numérica:
   - `"2/6"` → current=2, max=6
   - `"3"` → current=3, max=nil (timer)

**Lógica de `increment_progress()`:**

1. Llama a `find_progress()` con el type_key y name dados
2. Si encontró un tag existente:
   - Clock/Track: si current < max, reemplaza línea con current+1/max
   - Timer: si current > 0, reemplaza línea con current-1
   - Si ya está completo, cae al caso "insert fresco"
3. Si no encontró o está completo:
   - Inserta línea nueva debajo del cursor
   - Clock: `[E:Name 0/6]` (o `max_default` si se proveyó)
   - Track: `[Track:Name 0/6]`
   - Timer: `[Timer:Name 0]`
   - Cursor posicionado dentro del nombre para editar inmediato

### 2. `plugin/lonelog.lua` (~30 líneas nuevas)

Comandos:

```lua
-- Clock: recibe name opcional. Si no se da, usa "Name" (placeholder editable).
vim.api.nvim_create_user_command("LonelogInsertClock", function(o)
  local name = o.args ~= "" and o.args or "Name"
  require("lonelog.commands.progress").increment_progress("E", name, 6)
end, { nargs = "?", desc = "Insert or increment event clock" })

-- Track: recibe name opcional. Si no se da, pide con input().
vim.api.nvim_create_user_command("LonelogInsertTrack", function(o)
  if o.args and o.args ~= "" then
    require("lonelog.commands.progress").increment_progress("TRACK", o.args, 6)
  else
    vim.ui.input({ prompt = "Track name: " }, function(name)
      if name and name ~= "" then
        require("lonelog.commands.progress").increment_progress("TRACK", name, 6)
      end
    end)
  end
end, { nargs = "?", desc = "Insert or increment progress track" })

-- Timer: recibe name opcional.
vim.api.nvim_create_user_command("LonelogInsertTimer", function(o)
  local name = o.args ~= "" and o.args or "Name"
  require("lonelog.commands.progress").increment_progress("TIMER", name, nil)
end, { nargs = "?", desc = "Insert or decrement timer" })
```

Keymaps en `setup_keymaps()`:

```lua
map("n", cfg.get().keymaps.tag_clock, function()
  vim.cmd("LonelogInsertClock")
end, { desc = "Insert/increment clock" })
map("n", cfg.get().keymaps.tag_track, function()
  vim.cmd("LonelogInsertTrack")
end, { desc = "Insert/increment track" })
map("n", cfg.get().keymaps.tag_timer, function()
  vim.cmd("LonelogInsertTimer")
end, { desc = "Insert/decrement timer" })
```

### 3. `lua/lonelog/config.lua` (~5 líneas)

```lua
tag_clock = "<leader>ltc",
tag_track = "<leader>ltk",
tag_timer = "<leader>lti",
```

## Tests

Crear `tests/test_progress.lua` (~80 líneas, ~8 tests):

1. **clock: incrementa existente** — buffer tiene `[E:Alert 2/6]`, invoca
   `increment_progress("E", "Alert", 6)`, verifica que la línea cambió a
   `[E:Alert 3/6]`
2. **clock: no incrementa si completo** — buffer tiene `[E:Alert 6/6]`,
   invoca, verifica que inserta fresco (línea nueva)
3. **clock: inserta fresco si no existe** — buffer vacío, invoca, verifica
   que se insertó `[E:Name 0/6]`
4. **clock: match case-insensitive** — buffer tiene `[E:alert 2/6]`,
   invoca con `"Alert"`, verifica que incrementa
5. **track: incrementa existente** — buffer tiene `[Track:Escape 3/8]`,
   invoca, verifica cambio a 4/8
6. **timer: decrementa existente** — buffer tiene `[Timer:Dawn 3]`,
   invoca, verifica cambio a `[Timer:Dawn 2]`
7. **timer: no decrementa si en 0** — buffer tiene `[Timer:Dawn 0]`,
   invoca, verifica que no cambia
8. **track con pipe y tags** — buffer tiene
   `[Track:Ritual 2/6|urgent]`, invoca con `"Ritual"`, verifica que cambia
   a `[Track:Ritual 3/6|urgent]`

## Casos borde

- **Múltiples matches:** Si hay dos clocks con el mismo nombre, modifica el
  primero (orden de líneas ascendente).
- **Nombre con espacios:** `[E: camp ritual 3/6]` — el nombre completo
  antes del espacio-número es "camp ritual".
- **Clock con alias `Clock:`**: `[Clock:Ritual 2/8]` se reconoce igual que
  `[E:Ritual 2/8]`.
- **Timer sin max**: `[Timer:Dawn 3]` no tiene denominador, current=3,
  max=nil. Decrementa a 2, 1, 0.

## No incluido (YAGNI)

- Modal para elegir qué clock incrementar cuando hay múltiples. Por ahora
  se modifica siempre el primero.
- Modal para pedir `max` en tracks. Usa default 6. El usuario edita a mano
  si quiere otro valor.
- Actualización de tags en el picker (el picker ya refleja cambios al
  re-parsear).
