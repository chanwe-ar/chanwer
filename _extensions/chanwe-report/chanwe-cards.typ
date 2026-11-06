// =============================================================
// chanwe-cards.typ — tarjetas destacadas (`.card-highlight`)
//
// Un panel slate con una barra de color a la izquierda. Solo, a todo el
// ancho, lleva sólo el cuerpo (la bajada de un memo); dentro de un
// `.card-highlight-set` cada tarjeta suma un rótulo en mono y un título, y
// todas las tarjetas de una fila miden lo mismo.
//
// El archivo es compartido: el reporte y el memo lo incluyen como parcial
// después de su tabla `_t`, así lee los mismos tokens en los dos formatos.
// La barra es una celda pintada, no un `stroke`: el trazo de un borde se
// dibuja centrado en el canto y asoma medio grosor por arriba y por abajo
// del panel; dos celdas en la misma fila miden exactamente lo mismo.
// =============================================================

#let _ch-bar-w = 1.6pt

// A card is a pane, so `white` is the default since 2026-11-05 (it was
// `light`, the slate tint, which on a memo's first page —lede plus four
// cards— read as a grey block); `light` is still there for grouping.
// Esquema por variante: white · light · dark · primary, como el resto de los
// Divs del reporte. La barra usa el mismo vocabulario que el panel: `accent`
// toma `primary`, `light` (slate) o `dark` (obsidiana), resuelto contra el
// fondo para que siempre se vea.
#let _ch-scheme(color) = if color == "dark" {
  (bg: _t.ink, eyebrow: _t.fg-subtle, title: _t.rule-cool, body: _t.rule-cool,
   bar-primary: _t.primary, bar-light: _t.rule-cool, bar-dark: _t.rule-ink)
} else if color == "primary" {
  (bg: _t.primary, eyebrow: _t.white.transparentize(30%), title: _t.white, body: _t.white,
   bar-primary: _t.white, bar-light: _t.white.transparentize(55%), bar-dark: _t.ink)
} else if color == "white" {
  (bg: _t.white, eyebrow: _t.fg-muted, title: _t.ink, body: _t.fg-muted,
   bar-primary: _t.primary, bar-light: _t.rule-cool, bar-dark: _t.ink)
} else {
  (bg: _t.tint, eyebrow: _t.fg-muted, title: _t.ink, body: _t.fg-muted,
   bar-primary: _t.primary, bar-light: _t.rule-cool, bar-dark: _t.ink)
}

// Sin `accent`, la tarjeta suelta lleva la barra `light`; en un set, la
// primera va en `primary` y el resto en `dark`.
// (En llaves: a nivel de archivo un `else` en la línea siguiente ya no es
// parte de la expresión y Typst lo imprime como texto.)
#let _ch-bar(accent, s, index) = {
  if accent == "primary" { s.bar-primary }
  else if accent == "light" { s.bar-light }
  else if accent == "dark" { s.bar-dark }
  else if index == none { s.bar-light }
  else if index == 0 { s.bar-primary }
  else { s.bar-dark }
}

#let _ch-cell(eyebrow, title, body, s, wide: false, dot: none) = block(
  width: 100%,
  inset: if wide { (left: 5mm, right: 5mm, top: 3.4mm, bottom: 3.4mm) }
         else { (left: 4mm, right: 4mm, top: 3.4mm, bottom: 3.4mm) },
)[
  #set block(spacing: 0pt)
  #set par(leading: 0.68em, spacing: 0.7em)
  #if eyebrow != none {
    if dot != none { cw-dot(dot, size: 4.5pt, baseline: -0.6pt); h(1.6mm) }
    text(font: _t.font-mono, size: 5.9pt, weight: _t.weight-medium, tracking: 0.18em,
         fill: s.eyebrow, upper(eyebrow))
    v(2.2mm)
  }
  #if title != none {
    text(font: _t.font-display, size: 9.2pt, weight: _t.weight-display, tracking: -0.05em,
         fill: s.title, title)
    v(1.8mm)
  }
  #set text(font: _t.font-sans, size: if wide { 0.97em } else { 7.4pt },
            weight: _t.weight-regular, fill: s.body)
  #body
]

// La tarjeta suelta: a todo el ancho, cuerpo al tamaño del texto corrido.
// v2-print: a card is a pane with 16px corners (hairline on the white and
// light schemes), and its accent is a dot before the eyebrow instead of the
// side bar of v1.
#let _ch-card(s, accent, index, wide, eyebrow, title, body) = block(
  width: 100%, fill: s.bg, radius: _t.radius-surface, clip: true, breakable: false,
  stroke: if s.bg == _t.ink or s.bg == _t.primary { none } else { cw-hairline + _t.rule },
  inset: 0pt,
  _ch-cell(eyebrow, title, body, s, wide: wide, dot: _ch-bar(accent, s, index)),
)

#let card-highlight(eyebrow: none, title: none, accent: none, color: "white", body) = {
  let s = _ch-scheme(color)
  block(width: 100%, above: 5mm, below: 5mm, breakable: false,
    _ch-card(s, accent, none, true, eyebrow, title, body))
}

#let card-highlight-set(color: "white", cols: none, items) = {
  let s = _ch-scheme(color)
  let n = if cols == none { items.len() } else { cols }
  let n = calc.max(1, calc.min(n, items.len()))
  block(width: 100%, above: 6mm, below: 6mm, grid(
    columns: range(n).map(_ => 1fr),
    column-gutter: 4mm,
    row-gutter: 4mm,
    ..items.enumerate().map(((i, c)) => _ch-card(s, c.at("accent", default: none), i, false,
      c.at("eyebrow", default: none), c.at("title", default: none), c.at("body", default: []))),
  ))
}
