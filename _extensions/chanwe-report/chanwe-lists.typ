// =============================================================
// chanwe-lists.typ — listas de tareas (`- [ ]` / `- [x]`)
//
// Compartido por el reporte y el memo, incluido como parcial después de la
// tabla `_t`. El filtro `chanwe-lists.lua` convierte una lista de tareas
// de markdown en `#task-list(((hecho, cuerpo), …))`: la casilla es la
// viñeta, no va una viñeta y además una casilla. Antes Pandoc escribía los
// glifos ☐ y ☒ dentro de una lista común y cada ítem salía con dos marcas.
// =============================================================

// The box is the bullet. `square` (the default since the kit and the formats
// were unified, 2026-11-18): a hairline square, filled obsidian with a white
// tick when done, and the done item struck through in `fg-subtle`. `round`:
// a circle in the control hairline, an orange disc when done.
// The document picks with `chanwe: task-style:` (cw-style, chanwe-v2.typ).
#let _task-tick = {
  place(top + left, line(start: (1.6pt, 3.7pt), end: (3.0pt, 5.2pt),
    stroke: (paint: _t.white, thickness: 0.9pt, cap: "round")))
  place(top + left, line(start: (3.0pt, 5.2pt), end: (5.7pt, 2.0pt),
    stroke: (paint: _t.white, thickness: 0.9pt, cap: "round")))
}
#let _task-box(done) = context {
  let round = cw-style("task-style", "square") == "round"
  box(
    width: 7.2pt, height: 7.2pt,
    radius: if round { 3.6pt } else { 1.8pt },
    stroke: if done { none } else if round { 0.7pt + _t.rule-cool } else { 0.7pt + _t.fg-muted },
    fill: if done { if round { _t.primary } else { _t.ink } } else { none },
    if done { _task-tick },
  )
}

// `items`: tupla de `(hecho, cuerpo)`. La casilla ocupa la columna de la
// viñeta y el cuerpo cuelga a su derecha; con `align: top` la casilla se
// apoya en la altura de las versales de la primera línea.
#let task-list(items, spacing: 0.7em, gutter: 5pt) = block(width: 100%, grid(
  columns: (auto, 1fr),
  column-gutter: gutter,
  row-gutter: spacing,
  align: (top, top),
  ..items.map(((done, body)) => (_task-box(done), if done { text(fill: _t.fg-subtle, strike(stroke: 0.5pt + _t.fg-subtle, body)) } else { body })).flatten(),
))
