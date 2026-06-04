# TODO — lonelog.nvim

Lista unificada de features pendientes, consolidada desde `DEVLOG.md`,
`docs/superpowers/specs/` y `.opencode/plans/`.

## S — Small (~60–120 líneas)

- [ ] **Tag Search by Name** — filtro de búsqueda al abrir el tags picker
- [ ] **Dice Roll History** — historial de últimas N tiradas en la sesión, visible vía comando
- [ ] **Dice Macro System** — secuencias con nombre en config (ej. `attack = "2d6+3"`)
- [ ] **Custom Oracle Tables** — tablas de oráculo personalizadas con entradas ponderadas
- [ ] **Dead Roster Detection** — excluir muertos del roster automático en bloques `[COMBAT]`
- [ ] **Round Markers** — insertar marcadores `R#` auto-incrementados en bloques `[COMBAT]`

## M — Medium (~120–300 líneas)

- [ ] **Session Roll Statistics** — resumen de tiradas por tipo, distribución de oráculos
- [ ] **Scene Graph View** — árbol de escenas en ventana flotante
- [ ] **Custom Random Tables Generator** — tablas aleatorias configurables
- [ ] **Parsed Elements Cache** — cache unificado de entidades parseadas (NPCs, locaciones, etc.)
- [ ] **Prose Parser** — parser de producción para notas meta, diálogos y bloques narrativos
- [ ] **Combat Parser** — parser completo de bloques `[COMBAT]` (rounds, combatientes, acciones)
- [ ] **ASCII Dungeon Map** — mapa de dungeon renderizado en ASCII

## L — Large (~300–500+ líneas)

- [ ] **Campaign Archive/Export** — exportar campaña a HTML/markdown unificado con referencias cruzadas
- [ ] **Character Sheet Integration** — hoja de personaje con stats que se auto-actualizan
- [ ] **Multi-File Campaign Navigation** — navegación de tags/escenas entre múltiples archivos de sesión
- [ ] **Interactive Combat Tracker** — seguimiento de combate con iniciativa, HP, rondas
- [ ] **Automated Dungeon/Room Generator** — generador de mazmorras/habitaciones en formato Lonelog
