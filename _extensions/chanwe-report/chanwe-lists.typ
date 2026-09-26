// =============================================================
// chanwe-lists.typ — listas de tareas (`- [ ]` / `- [x]`)
//
// Compartido por el reporte y el memo, incluido como parcial después de la
// tabla `_t`. El filtro `chanwe-lists.lua` convierte una lista de tareas
// de markdown en `#task-list(((hecho, cuerpo), …))`: la casilla es la
// viñeta, no va una viñeta y además una casilla. Antes Pandoc escribía los
// glifos ☐ y ☒ dentro de una lista común y cada ítem salía con dos marcas.
// =============================================================

// La casilla, a canto vivo, del cuerpo de una versal chica: vacía para lo
// pendiente, llena con la tilde blanca para lo hecho.
#let _task-box(done) = box(
  width: 7.2pt, height: 7.2pt, radius: 0pt,
  stroke: 0.7pt + _t.primary,
  fill: if done { _t.primary } else { none },
  if done {
    place(top + left, line(start: (1.6pt, 3.7pt), end: (3.0pt, 5.2pt),
      stroke: (paint: _t.white, thickness: 0.9pt, cap: "round")))
    place(top + left, line(start: (3.0pt, 5.2pt), end: (5.7pt, 2.0pt),
      stroke: (paint: _t.white, thickness: 0.9pt, cap: "round")))
  },
)

// `items`: tupla de `(hecho, cuerpo)`. La casilla ocupa la columna de la
// viñeta y el cuerpo cuelga a su derecha; con `align: top` la casilla se
// apoya en la altura de las versales de la primera línea.
#let task-list(items, spacing: 0.7em, gutter: 5pt) = block(width: 100%, grid(
  columns: (auto, 1fr),
  column-gutter: gutter,
  row-gutter: spacing,
  align: (top, top),
  ..items.map(((done, body)) => (_task-box(done), body)).flatten(),
))
