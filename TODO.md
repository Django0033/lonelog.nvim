# TODO — lonelog.nvim

Lista unificada de features pendientes.

## S — Small (~60–120 líneas)

- [x] **Tag Search by Name** — filtro de búsqueda al abrir el tags picker
- [ ] **Dice Roll History** — UI para ver historial de tiradas (infraestructura ya implementada)
- [ ] **Dice Macro System** — secuencias con nombre en config (ej. `attack = "2d6+3"`)
- [x] **Custom Oracle Tables** — tablas de oráculo personalizadas con entradas ponderadas
- [ ] **Dead Roster Detection** — excluir muertos del roster automático en bloques `[COMBAT]`
- [ ] **Round Markers** — insertar marcadores `R#` auto-incrementados en bloques `[COMBAT]`

## M — Medium (~120–300 líneas)

- [x] **Session Roll Statistics** — resumen de tiradas por tipo, distribución de oráculos
- [ ] **Scene Graph View** — árbol de escenas en ventana flotante
- [ ] **Custom Random Tables Generator** — tablas aleatorias configurables
- [x] **Parsed Elements Cache** — cache unificado de entidades parseadas
- [x] **Prose Parser** — parser de producción para notas meta, diálogos y bloques narrativos
- [x] **Combat Parser** — parser completo de bloques `[COMBAT]`
- [ ] **ASCII Dungeon Map** — mapa de dungeon renderizado en ASCII

## L — Large (~300–500+ líneas)

- [ ] **Campaign Archive/Export** — exportar campaña a HTML/markdown unificado
- [ ] **Character Sheet Integration** — hoja de personaje con stats auto-actualizados
- [ ] **Multi-File Campaign Navigation** — navegación entre múltiples archivos de sesión
- [ ] **Interactive Combat Tracker** — seguimiento de combate con iniciativa, HP, rondas
- [ ] **Automated Dungeon/Room Generator** — generador de mazmorras/habitaciones
