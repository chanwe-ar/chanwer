// =============================================================
// chanwe-studio/chanwe-report - typst-template.typ
// Page setup, design tokens, and global show rules.
// =============================================================

// ---------- Design tokens ------------------------------------
#let chanwe-tokens = (
  paper:       rgb("#F8FAFC"),
  ink:         rgb("#111319"),
  // Surfaces that sit ON ink — dark panels and hairlines.
  ink-soft:    rgb("#37393F"),
  ink-fg:      rgb("#64748B"),
  ink-subtle:  rgb("#646464"),
  fg:          rgb("#111319"),
  fg-muted:    rgb("#475569"),
  fg-subtle:   rgb("#8A94A6"),
  // Texto corrido: un punto por encima de `fg`, que queda para titulares.
  body-fg:     rgb("#475569"),
  callout-surface: rgb("#F8FAFC"),
  // Barra de título del callout y su marco, en slate.
  callout-header: rgb("#EBF0F6"),
  border-cool: rgb("#CFD6DF"),
  // Filete sobre obsidiana.
  rule-ink: rgb("#434D5D"),
  // Slate medio paso bajo el papel: portadas de sección.
  surface-sunken: rgb("#F1F5F9"),
  // Dos pasos de slate por debajo de la hoja: la página del abstract.
  surface-slate:  rgb("#EBF0F6"),
  // Hairlines: `rule` warm on paper, `rule-cool` for lede panels.
  rule:        rgb("#E2E8F0"),
  rule-cool:   rgb("#C6CDD6"),
  emphasis:    rgb("#484848"),
  primary:     rgb("#FD3810"),
  neutral-300: rgb("#D4D4D4"),
  neutral-700: rgb("#525252"),
  border:      rgb("#1113191A"),
  // Blanco y negro puros (brand.yml `pure-white` / `pure-black`). El
  // blanco es todo lo que se dibuja sobre primary y sobre obsidiana; el
  // negro sólo tinta sombras y topes transparentes de degradado en la
  // portada. Ningún parcial escribe `white` ni `black` a secas.
  white:       rgb("#FFFFFF"),
  black:       rgb("#000000"),
  // Gris de la portada research (`research-muted`).
  research-muted: rgb("#99999E"),
  // Los ocho matices de la serie (`chart-*` + `primary`), calibrados sobre
  // la HIG de Apple. Son la paleta de `chanwe-charts.typ` y, a la vez, la de
  // los callouts de abajo: una sola familia para las dos cosas.
  chart-blue:   rgb("#007AFF"),
  chart-green:  rgb("#34C759"),
  chart-indigo: rgb("#5856D6"),
  chart-orange: rgb("#FF9500"),
  chart-red:    rgb("#FF3B30"),
  chart-teal:   rgb("#00C7BE"),
  chart-purple: rgb("#AF52DE"),
  // Los siete tipos de callout (`callout-*`). Cada uno es uno de los matices
  // de arriba; `important` es `primary` y no se mueve.
  callout-note:      rgb("#007AFF"),
  callout-tip:       rgb("#00C7BE"),
  callout-warning:   rgb("#FF9500"),
  callout-important: rgb("#FD3810"),
  callout-caution:   rgb("#AF52DE"),
  callout-do:        rgb("#34C759"),
  callout-dont:      rgb("#FF3B30"),
  // Semáforos: la ficha del KPI y el estado del resumen ejecutivo doble.
  kpi-green:           rgb("#147705"),
  kpi-red:             rgb("#CC1914"),
  exec-status-good:    rgb("#15803D"),
  exec-status-regular: rgb("#D97706"),
  exec-status-bad:     rgb("#CC1914"),
  // Pesos tipográficos por rol (brand.yml `meta.weights`). Cada `weight:`
  // del reporte lee uno de estos, nunca un número.
  weight-hairline:  100,
  weight-thin:      200,
  weight-body:      300,
  weight-body-plus: 350,
  weight-regular:   400,
  weight-medium:    500,
  weight-display:   600,
  weight-bold:      700,
  font-display: ("Schibsted Grotesk", "Helvetica Neue", "Arial"),
  font-serif:   ("Cormorant Garamond", "Georgia", "Times New Roman"),
  // La serif de display: numerales del índice y bajada de contratapa.
  // Distinta de font-serif, que es la itálica del cuerpo.
  font-serif-display:  ("Instrument Serif", "Georgia", "Times New Roman"),
  font-sans:    ("Inter", "Helvetica Neue", "Arial"),
  font-mono:    ("JetBrains Mono", "Menlo", "Courier New"),
)

// expose tokens as a global so partials and user code can use them
#let _t = chanwe-tokens

// El tamaño de hoja del formato. Vive en una sola constante porque las
// páginas a sangre (portadas, contratapa, divisores, citas a página
// completa) tienen que declararlo aparte: un `set page` con margen 0 no
// hereda el papel del documento. Los parciales de abajo la leen.
#let _chanwe-paper = "a4"

// Las medidas de la hoja, explícitas. La portada research venía con la
// geometría clavada a US Letter (215.9 x 279.4mm): al pasar el formato a A4
// se desbordaba a lo ancho y quedaba corta a lo alto. Ahora todo lo que
// dependía del papel se deriva de estas dos, y el reparto de columnas
// (74 / 26, el de la referencia) se expresa como fracción en vez de en
// milímetros. La banda de arte de la portada ya era `1fr`, asi que el alto
// extra de A4 lo absorbe ella sola.
#let _chanwe-page-w = 210mm
#let _chanwe-page-h = 297mm

// assets path — override with chanwe-assets: in document YAML if the
// extension installed to a different path (e.g. _extensions/chanwe-report/)
#let _chanwe-assets = "$chanwe-assets$".replace("\\_", "_")

// ---------- Small primitives ---------------------------------
#let chanwe-glyph(size: 7pt, color: _t.primary) = box(
  width: size, height: size, baseline: 1pt,
)[
  #place(center + horizon, rotate(45deg, square(size: size * 0.72, fill: color)))
]

#let chanwe-eyebrow(body, color: _t.primary, with-rule: false, size: 8.5pt) = {
  if with-rule {
    box(width: 22pt, height: 0.75pt, fill: color, baseline: -3pt)
    h(8pt)
  }
  text(
    font: _t.font-mono,
    size: size,
    weight: _t.weight-medium,
    tracking: 0.18em,
    fill: color,
    upper(body),
  )
}

#let chanwe-section-eyebrow(body) = chanwe-eyebrow(body, with-rule: true)

// El `---` de markdown. Pandoc lo escribe como `#horizontalrule`, que Quarto
// define en su `definitions.typ` (cargado antes que este archivo) como una
// línea negra al ancho del medio. Se vuelve a definir acá, y gana ésta:
// misma geometría, filete fino en naranja.
#let horizontalrule = block(above: 11mm, below: 11mm, width: 100%,
  line(start: (25%, 0%), end: (75%, 0%), stroke: 0.5pt + _t.primary))

#let chanwe-meta-row(label, value, sub: none) = {
  grid(
    columns: (18mm, 1fr),
    column-gutter: 4mm,
    align: (left + top, left + top),
    text(font: _t.font-mono, size: 7pt, tracking: 0.20em, fill: _t.fg-subtle, upper(label)),
    block(spacing: 0pt)[
      #set par(spacing: 0pt, leading: 0.9em)
      #text(font: _t.font-display, tracking: -0.05em, size: 10pt, weight: _t.weight-display, fill: _t.fg, value)
      #if sub != none {
        linebreak()
        text(font: _t.font-sans, size: 8.5pt, fill: _t.fg-muted, sub)
      }
    ],
  )
}

// ---------- Running header / footer --------------------------
// La paleta del renglón de servicio. `inverse` es `none` sobre la hoja y
// "dark" o "primary" en las páginas que pintan la hoja entera. Sobre naranja
// todo pasa a blanco —texto, acento, logo—; sobre obsidiana el texto y el
// acento se quedan como están y sólo el wordmark cambia al corte gris de la
// portada (rule-cool), que es el que se lee sobre tinta.
#let _hf-palette(inverse) = if inverse == "primary" {
  (text: _t.white, accent: _t.white, rule: _t.white.transparentize(60%), logo: "Logo_Blanco.svg")
} else if inverse == "dark" {
  (text: _t.fg-subtle, accent: _t.primary, rule: _t.rule-ink, logo: "Logo_Gris.svg")
} else {
  (text: _t.fg-subtle, accent: _t.primary, rule: _t.border, logo: "Logo_Negro.svg")
}

#let chanwe-header(section, topic, inverse: none) = context {
  let c = _hf-palette(inverse)
  block(height: 100%, width: 100%)[
    #grid(
      rows: (1fr, auto),
      align(horizon, {
        set text(font: _t.font-mono, size: 6pt, tracking: 0.14em)
        grid(
          columns: (1fr, auto),
          align: (left + horizon, right + horizon),
          [
            #text(weight: _t.weight-bold, fill: c.accent, "//")
            #h(5pt)
            #text(fill: c.text, upper(section))
            #if topic != "" [#text(fill: c.text, upper(" · " + topic))]
          ],
          image(_chanwe-assets + c.logo, height: 3.5mm, fit: "contain"),
        )
      }),
      // Mismo filete que separa los renglones del índice.
      pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + c.rule)),
    )
  ]
}

#let chanwe-footer(doc-id, edition, inverse: none) = context {
  let c = _hf-palette(inverse)
  // line pins to top; text row grows to fill space → text centers
  block(height: 100%, width: 100%)[
    #grid(
      rows: (auto, 1fr),
      // Mismo filete que cierra el encabezado.
      pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + c.rule)),
      align(horizon, {
        // Mismo tono que el encabezado: el pie es la otra mitad del mismo
        // renglón de servicio. Un solo tono para todo el renglón, el que ya
        // tenía la edición; los `fill` por tramo desaparecieron con eso.
        set text(font: _t.font-mono, size: 6pt, tracking: 0.14em, fill: c.text)
        grid(
          columns: (1fr, auto),
          align: (left + horizon, right + horizon),
          [#upper[#doc-id #h(8pt) #edition]],
          [#text(size: 6.9pt, upper(str(counter(page).get().first()) + " / " + str(counter(page).final().first())))],
        )
      }),
    )
  ]
}

// Global state - set by chanwe-report() and read by components
#let _chanwe-doc = state("chanwe-doc", (
  doc-id:    "CHW · DOC",
  edition:   "",
  taggy:     "CW- MACRO LAB",
  meta-rows: (),
  section:   "",
  topic:     "",
))

// El renglón de servicio leído del estado del documento, para las páginas
// que vuelven a fijar `page` (resumen ejecutivo, resumen doble) y necesitan
// el encabezado y el pie en su versión invertida.
#let chanwe-header-auto(inverse: none) = context {
  let d = _chanwe-doc.get()
  chanwe-header(d.section, d.topic, inverse: inverse)
}
#let chanwe-footer-auto(inverse: none) = context {
  let d = _chanwe-doc.get()
  // El estado ya guarda doc-id y edición limpios del escape de Pandoc.
  chanwe-footer(d.doc-id, d.edition, inverse: inverse)
}
#let _chanwe-inverse-of(color) = if color == "dark" { "dark" } else if color == "primary" { "primary" } else { none }

// Tracks the active chapter-divider section (set in chanwe-chapter-divider)
#let _chanwe-cur-part = state("chanwe-cur-part", none)

// =============================================================
// PARTIAL INCLUDES (qr, cover, elements, pages)
// Each file uses _t which is defined above.
// =============================================================
$chanwe-qr.typ()$
$chanwe-cover.typ()$
$chanwe-elements.typ()$
$chanwe-cards.typ()$
$chanwe-lists.typ()$
$chanwe-pages.typ()$
$chanwe-charts.typ()$

// =============================================================
// MAIN TEMPLATE FUNCTION (called by typst-show.typ)
// =============================================================
#let chanwe-report(
  // metadata
  title: "Untitled",
  subtitle: none,
  author: "Chanwe Studio",
  date: "",
  lang: "en",           // Quarto's `lang:` — hyphenation, smart quotes; crossref labels follow it too
  doc-id: "SERIES-A #0934",
  edition: "Edition 01 / 2026",
  volume: "Confidential",
  chapter: "Chapter",
  section: "",
  topic: "",
  rail-eyebrow: "SEC.01",
  taggy: "CW- MACRO LAB",
  // Las tres filas del masthead: las usan la portada y la contratapa.
  hero-caption-1: "32°53'24.8\"S  68°50'45.6\"W",
  hero-caption-2: "ELEV: 6967M // CERRO ACONCAGUA",
  hero-caption-3: "CORDILLERA PRINCIPAL · MENDOZA, AR",
  cover-eyebrow: none,      // overrides rail-eyebrow on the cover page only
  // assets
  hero-image: none,
  hero-img-position: none,  // 1–10 (left→right); none = fit:cover (centered)
  wordmark: none,
  stamp: ("VOL", "I", "2026"),
  hero-date: "",
  meta-rows: (
    ("Author", "Chanwe Studio", "Estrategia Activa"),
  ),
  // toggles
  cover: true,
  // toc
  toc-eyebrow: "Document map",
  toc-title: "Agenda",
  toc-lede: none,
  toc: true,
  // abstract
  abstract: true,
  abstract-eyebrow: "Abstract",
  abstract-title: none,
  abstract-text: none,
  abstract-keywords: (),
  abstract-status: none,
  abstract-show: (),
  abstract-takeaway: none,   // string — first letter gets drop-cap treatment
  // back cover
  back-cover: true,
  back-cover-tagline-1: "Less template,",
  back-cover-tagline-2: "more report.",
  back-cover-cols: (),
  // edge label (vertical text on right side of cover + back cover)
  cover-edge: none,
  cover-edge-color: none,
  // ── portada ──────────────────────────────────────────────────
  // "research" (default) es la portada de la vieja chanwe-publications;
  // "hero" es la que traia chanwe-report: panel hero, riel y losa de
  // wordmark al pie. `cover-dark` solo aplica a la variante "hero".
  cover-variant: "research",
  cover-dark: false,
  // publication cover
  publication-period: none,
  publication-edition: none,
  publication-art: none,
  publication-audience: "PÚBLICO",
  publication-series: "CHANWE / RESEARCH",
  publication-location: "MENDOZA / ARGENTINA",
  publication-copyright: "PROHIBIDA SU REPRODUCCIÓN SIN AUTORIZACIÓN | TODOS LOS DERECHOS RESERVADOS",
  // page
  page-bg: _t.paper,
  second-page-bg: _t.paper,   // fill for the TOC/abstract page (metallic default)
  // body text
  body-size:    none,   // e.g. 10pt — overrides default 11pt
  body-leading: none,   // e.g. 0.9em — overrides default 0.85em
  body-justify: none,   // true / false — overrides default false
  body-color:   none,   // rgb color — overrides default _t.fg
  body-spacing: none,   // e.g. 2.4em — space between body paragraphs
  // body
  body,
) = {
  // ---- store metadata in global state -----------------------
  _chanwe-doc.update((doc-id: _chanwe-clean-str(doc-id), edition: _chanwe-clean-str(edition), taggy: taggy, meta-rows: meta-rows, section: section, topic: topic))

  // ---- global text + page defaults ---------------------------
  set page(fill: page-bg)
  set text(font: _t.font-sans, size: 11pt, weight: _t.weight-body, fill: _t.body-fg, lang: lang)
  set par(leading: 0.85em, justify: false, spacing: 1.0em)
  // El código lo colorea Typst con el tema de marca (assets/chanwe.tmTheme):
  // palabras clave en naranja, cadenas y nombres en obsidiana, comentarios en
  // fg-subtle. El texto base hereda body-fg, como la prosa.
  set raw(theme: _chanwe-assets + "chanwe.tmTheme")
  set heading(numbering: "1.1.1.")

  // ---- inline rules (apply to entire document) ---------------
  // La cursiva cambia de familia —Inter a Cormorant Garamond—, y la serif
  // tiene una altura de x mucho menor: 0.386em contra 0.546em. Al mismo
  // cuerpo se leia mas chica que el texto que la rodea. El factor iguala esas
  // dos alturas (0.546 / 0.386).
  show emph: it => text(font: _t.font-serif, style: "italic", weight: _t.weight-body,
                        size: 1.414em, fill: _t.body-fg, it.body)
  show strong: it => text(weight: _t.weight-display, fill: _t.body-fg, it.body)
  // La matemática en línea va en el negro de los titulares, no en el slate
  // del cuerpo, y un décimo más grande: Computer Modern tiene la x más baja
  // que Inter y a cuerpo igual se veía chica. La de bloque conserva su panel
  // y su gris apagado.
  show math.equation.where(block: false): set text(fill: _t.fg, size: 1.1em)
  // Superíndice y subíndice un poco más grandes que el 0.6em de fábrica.
  set super(size: 0.68em)
  set sub(size: 0.68em)
  show math.equation.where(block: true): it => block(
    width: 100%,
    fill: _t.callout-header,
    stroke: 0.5pt + _t.neutral-300,
    radius: 4pt,
    inset: (x: 10mm, y: 8mm),
  )[
    #set text(fill: _t.fg-muted, weight: _t.weight-thin)
    #align(center, it)
  ]
  show link: it => underline(stroke: 0.6pt + _t.primary, offset: 2pt, text(fill: _t.primary, it))
  // El chip de codigo en linea. Un `box` inline no conserva la base de su
  // contenido: el inset vertical la empuja hacia arriba, asi que la mono
  // quedaba flotando sobre la base del cuerpo. `baseline` la baja 1 a 1, y
  // este valor sale de medir el PDF: depende del inset y del cuerpo, asi que
  // si se toca cualquiera de los dos hay que volver a medirlo.
  //
  // El alto de la pastilla (12.48pt) queda por debajo del alto de linea del
  // cuerpo, asi que un renglon con chip no separa mas que uno sin chip.
  // Medido: 17.64pt de interlineado en ambos casos. Subir mas el inset o el
  // cuerpo rompe esa paridad.
  show raw.where(block: false): it => box(
    fill: _t.surface-slate,
    stroke: 0.5pt + _t.border-cool,
    inset: (x: 5.5pt, y: 4.2pt),
    radius: 2pt,
    baseline: 4.20pt,
    text(font: _t.font-mono, size: 1.035em, fill: _t.fg-muted, it),
  )
  // El panel de código va con el mismo marco slate que el chip en línea y el
  // callout —un filete fino a todo el contorno, no un canto naranja— y con
  // las esquinas a 4pt, que es el radio de todos los paneles del reporte.
  // Entero o a la página siguiente: partido, el rótulo "# python · N lines"
  // quedaba solo al pie de una página y el código arrancaba en la otra con un
  // marco nuevo, como si fueran dos paneles.
  show raw.where(block: true): it => block(
    fill: _t.surface-slate,
    stroke: 0.5pt + _t.border-cool,
    radius: 4pt,
    inset: (x: 4mm, y: 3mm),
    width: 100%,
    breakable: false,
  )[
    #set block(fill: none)
    // Sin el espaciado de párrafo del cuerpo (2.6em): se sumaba al `v` y
    // dejaba un centímetro entre el rótulo y la primera línea.
    #set block(spacing: 0pt)
    #set par(spacing: 0pt)
    #if it.lang != none {
      text(
        font: _t.font-mono, size: 7.5pt, fill: _t.fg-subtle,
        "# " + it.lang + " · " + str(it.lines.len()) + " lines",
      )
      v(2.5mm)
    }
    #text(font: _t.font-mono, size: 9pt, weight: _t.weight-body, it)
  ]

  // ---- notas al pie -------------------------------------------
  // Typst las deja en negro y con un filete negro al 30%. La nota es material
  // de servicio, como el pie de pagina: mismo tono (`ink-fg`) y un filete
  // slate en vez del negro.
  set footnote.entry(separator: line(length: 38%, stroke: 0.5pt + _t.rule))
  show footnote.entry: it => {
    set text(font: _t.font-sans, size: 8pt, weight: _t.weight-body, fill: _t.fg-subtle)
    it
  }

  // ---- headings ----------------------------------------------
  // Un encabezado sin numerar (`{.unnumbered}` → `numbering: none`) no
  // muestra el contador: en el lugar del numeral va un filete corto en
  // naranja, centrado en la altura de mayúsculas del titular y a la escala
  // del numeral que reemplaza —largo 1.5× su cuerpo, grosor con él—, así el
  // H1 lo lleva grande y el H4 chico. Antes el numeral salía igual y
  // mostraba el valor del último encabezado numerado.
  let _h-mark(it, numeral, size) = if it.numbering != none {
    (align: left + bottom, body: numeral)
  } else {
    (align: left + horizon,
     body: box(width: size * 1.5, height: 0.5pt + size * 0.03, fill: _t.primary))
  }
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    // Typst deja el encabezado un 30% del margen superior por encima del
    // cuerpo (15mm x 0.3 = 4.5mm): se recupera ese aire para que la losa
    // quede pegada al filete del header.
    v(-4.5mm)
    // La cabecera de capítulo va sobre una losa de obsidiana que sangra de
    // orilla a orilla: el eyebrow, el titular y el filete quedan adentro.
    context move(dx: -18mm, block(
      width: page.width,
      fill: _t.ink,
      // La losa arranca pegada al encabezado; el aire va por dentro, así que
      // el eyebrow y el titular bajan sin mover el borde del rectángulo.
      inset: (left: 18mm, right: 18mm, top: 14mm, bottom: 14.5mm),
      clip: true,
    )[
      // La misma trama de puntos de la contratapa, plana y recortada por la
      // losa. Se corre por el inset para cubrir el rectángulo entero.
      #place(top + left, dx: -18mm, dy: -14mm,
        _chanwe-dot-field(width: page.width, height: 140mm,
                          ramp: (88%, 58%)))
      #block(above: 0pt, below: 0pt, rect(width: 50pt, height: 0.9pt, fill: _t.primary, stroke: none))
      #v(12mm)
      #let mark = _h-mark(it, text(font: _t.font-serif-display, style: "italic",
        weight: _t.weight-body, size: 50pt, fill: _t.primary,
        _pad2(counter(heading).get().first())), 50pt)
      #grid(
        columns: (auto, 1fr),
        column-gutter: 8mm,
        align: (mark.align, left + bottom),
        mark.body,
        block()[
          #set par(leading: 0.18em)
          // Mismo peso que el titular de portada.
          #text(font: _t.font-display, size: 33pt, weight: _t.weight-display,
               tracking: -0.05em, fill: _t.rule-cool, it.body)
        ],
      )
      #v(1.5mm)
      // Mismo filete que parte la portadilla, en clave oscura.
      #line(length: 100%, stroke: 0.5pt + _t.rule-ink.transparentize(50%))
    ])
    // El `below` del bloque no sobrevive al `move`, así que el aire que separa
    // la losa del primer párrafo se pone acá.
    v(14.4mm)
  }
  show heading.where(level: 2): it => block(above: 12mm, below: 6mm)[
    #set par(leading: 0.2em)
    #let mark = _h-mark(it, text(font: _t.font-serif-display, style: "italic",
      weight: _t.weight-body, size: 21pt, fill: _t.primary, counter(heading).display("1.1")), 21pt)
    #grid(
      columns: (auto, 1fr),
      column-gutter: 6mm,
      align: (mark.align, left + bottom),
      mark.body,
      text(font: _t.font-display, size: 19pt, weight: _t.weight-display,
           tracking: -0.05em, fill: _t.fg, it.body),
    )
    #v(0mm)
    #line(length: 100%, stroke: 0.5pt + _t.neutral-300)
  ]
  // H3 y H4 son el H2 a menor cuerpo: mismo numeral serif en cursiva, mismo
  // peso del titular, y el numeral a la misma proporción del titular que en
  // el H2 (18.75 sobre 19). Antes el H3 llevaba el numeral en mono y el H4 en
  // Cormorant y a peso 700, y la escala se rompía a cada nivel.
  show heading.where(level: 3): it => block(above: 10mm, below: 5.5mm)[
    #set par(leading: 0.2em)
    #let mark = _h-mark(it, text(font: _t.font-serif-display, style: "italic",
      weight: _t.weight-body, size: 14.8pt, fill: _t.primary, counter(heading).display("1.1.1")), 14.8pt)
    #grid(
      columns: (auto, 1fr),
      column-gutter: 4.7mm,
      align: (mark.align, left + bottom),
      mark.body,
      text(font: _t.font-display, size: 15pt, weight: _t.weight-display,
           tracking: -0.05em, fill: _t.fg, it.body),
    )
  ]
  show heading.where(level: 4): it => block(above: 8mm, below: 4mm)[
    #set par(leading: 0.2em)
    // Dos puntos por debajo del titular: a cuatro cifras el numeral ya
    // pesa bastante y a la proporción del H2 se comía el título.
    #let mark = _h-mark(it, text(font: _t.font-serif-display, style: "italic",
      weight: _t.weight-body, size: 11.8pt, fill: _t.primary, counter(heading).display("1.1.1.1")), 11.8pt)
    #grid(
      columns: (auto, 1fr),
      column-gutter: 4.4mm,
      align: (mark.align, left + bottom),
      mark.body,
      text(font: _t.font-display, size: 14pt, weight: _t.weight-display,
           tracking: -0.05em, fill: _t.fg, it.body),
    )
  ]
  // H5 y H6 son rótulos de bloque: punto y versalita en mono, sin filete.
  // El punto y el texto van en una grilla a `horizon`: el cuadro del texto
  // corre de la línea base a la altura de mayúsculas (los bordes por
  // defecto de Typst), así que el centro del punto cae exactamente en el
  // centro de las versales. Con un `box` en línea y `baseline` a mano
  // quedaba medio punto bajo. El H6 es el mismo rótulo con el punto en slate.
  let _label-heading(body, dot: _t.primary) = grid(
    columns: (auto, 1fr),
    column-gutter: 6pt,
    align: (horizon, horizon),
    circle(radius: 2.5pt, fill: dot),
    text(font: _t.font-mono, size: 8pt, weight: _t.weight-medium,
         tracking: 0.18em, fill: _t.fg, upper(body)),
  )
  show heading.where(level: 5): it => block(above: 10mm, below: 4mm,
    _label-heading(it.body))
  show heading.where(level: 6): it => block(above: 10mm, below: 4mm,
    _label-heading(it.body, dot: _t.fg-muted))

  // ---- lists -------------------------------------------------
  set list(marker: ([•], [◦], [–]))

  // ---- quote (Pandoc/Quarto blockquotes) ---------------------
  // Panel en el slate hundido con el canto naranja: la cita de terceros se
  // lee como un aparte, no como un renglón con un filete al lado. El aire
  // vertical triplica el alto de una sola línea.
  // El panel va un paso de slate más claro que el abstract y el código
  // (`surface-sunken`, no `surface-slate`): la cita es un aparte, no un
  // bloque de interfaz. Vale igual para `> …` y para `#pullquote`, que
  // emite este mismo `quote`.
  show quote: it => block(
    above: 6mm, below: 6mm,
    width: 100%,
    fill: _t.surface-sunken,
    inset: (left: 6mm, right: 6mm, top: 5mm, bottom: 5mm),
    stroke: (left: 1.4pt + _t.primary),
  )[
    // El aire de párrafo del cuerpo (2.6em) se colaba entre la cita y su
    // atribución y las separaba un renglón entero; adentro del panel baja a
    // medio cuerpo, que también es lo que separa dos párrafos de una cita.
    #set par(leading: 0.425em, spacing: 0.5em)
    #text(font: _t.font-serif, size: 13.2pt, weight: _t.weight-body, style: "italic", fill: _t.fg-muted, it.body)
    #if it.attribution != none {
      v(1.5mm)
      text(font: _t.font-serif, size: 8.75pt, weight: _t.weight-body, style: "italic", fill: _t.fg-subtle, [— #it.attribution])
    }
  ]

  // ---- tables -----------------------------------------------
  // Los dos filetes que encierran el encabezado van en slate, no en el negro
  // de la rampa: la tabla se lee con el mismo peso de línea que la banda de
  // hallazgos y el marco del callout.
  set table(
    fill: none,
    stroke: (col, row) => (
      top:    if row == 0 { 0.5pt + _t.border-cool } else { none },
      bottom: if row == 0 { 0.5pt + _t.border-cool } else { 0.4pt + _t.border },
    ),
    inset: (x: 4mm, y: 3.5mm),
  )
  show table.cell: set text(
    size: 7pt, weight: _t.weight-thin, fill: _t.fg,
  )
  // Los nombres de columna en mono y negrita: son rótulos, no prosa. Un punto
  // por debajo del cuerpo, así el peso los distingue sin que el cuerpo mande.
  show table.cell.where(y: 0): set text(
    font: _t.font-mono, size: 6pt, weight: _t.weight-bold,
    tracking: 0.02em, fill: _t.ink,
  )
  show figure.where(kind: table): it => {
    v(12mm, weak: true)
    it.body
    v(-0.25pt)
    // El filete de cierre acompaña a los del encabezado: si se quedaba en
    // obsidiana, la tabla tenía una línea negra y tres slate.
    line(length: 100%, stroke: 0.5pt + _t.border-cool)
    v(2mm)
    it.caption
    v(12mm, weak: true)
  }
  show figure.where(kind: image): it => {
    v(14mm, weak: true)
    line(length: 100%, stroke: 0.3pt + _t.ink)
    v(4mm)
    it.body
    v(3mm)
    line(length: 100%, stroke: 0.3pt + _t.ink)
    v(1.5mm)
    it.caption
    v(12mm, weak: true)
  }
  // Las figuras y tablas nativas de Quarto (las que llevan pie, con o sin
  // identificador) salen con el marco de `.chanwe-figure-frame`: rótulo y pie
  // arriba, sello de la serie abajo. Quarto las emite con `kind:
  // "quarto-float-fig"` / `"quarto-float-tbl"`, no como `image` / `table`,
  // así que las dos reglas de arriba no las alcanzan.
  let _native-stamp = _chanwe-clean-str(publication-series)
  show figure.where(kind: "quarto-float-fig"): it => chanwe-native-figure(it, stamp: _native-stamp)
  show figure.where(kind: "quarto-float-tbl"): it => chanwe-native-figure(it, stamp: _native-stamp)
  // Keep 3× more clear space after a figure or table footer before prose resumes.
  show figure: set block(above: 11mm, below: 12mm)
  show figure.caption: it => align(left, text(
    font: _t.font-mono, size: 5.5pt, weight: _t.weight-hairline, tracking: 0.10em,
    fill: _t.ink, upper(it.supplement) + " " + it.counter.display() + "  ·  " + upper(it.body),
  ))

  // ---- COVER (optional) -------------------------------------
  if cover and cover-variant == "hero" {
    // La portada que traia chanwe-report antes de la fusion. No recibe las
    // claves `publication-*`: esas son de la research.
    chanwe-hero-cover-page(
      title: title,
      subtitle: subtitle,
      doc-id: doc-id,
      edition: edition,
      volume: volume,
      rail-eyebrow: if cover-eyebrow != none { cover-eyebrow } else { rail-eyebrow },
      hero-image: hero-image,
      hero-img-position: hero-img-position,
      wordmark: wordmark,
      stamp: stamp,
      hero-caption-1: hero-caption-1,
      hero-caption-2: hero-caption-2,
      hero-date: hero-date,
      meta-rows: meta-rows,
      date: date,
      cover-edge: cover-edge,
      cover-edge-color: cover-edge-color,
      dark: cover-dark,
    )
  } else if cover {
    chanwe-cover-page(
      badge: taggy,
      hero-caption-1: hero-caption-1,
      hero-caption-2: hero-caption-2,
      hero-caption-3: hero-caption-3,
      title: title,
      subtitle: subtitle,
      doc-id: doc-id,
      edition: edition,
      volume: volume,
      rail-eyebrow: if cover-eyebrow != none { cover-eyebrow } else { rail-eyebrow },
      hero-image: hero-image,
      hero-img-position: hero-img-position,
      wordmark: wordmark,
      stamp: stamp,
      hero-date: hero-date,
      meta-rows: meta-rows,
      date: date,
      cover-edge: cover-edge,
      cover-edge-color: cover-edge-color,
      publication-period: publication-period,
      publication-edition: publication-edition,
      publication-art: publication-art,
      publication-audience: publication-audience,
      publication-series: publication-series,
      publication-location: publication-location,
      publication-copyright: publication-copyright,
    )
  }

  // ---- body pages -------------------------------------------
  set page(
    paper: _chanwe-paper,
    margin: (top: 15mm, bottom: 15mm, x: 18mm),
    header: chanwe-header(section, topic),
    footer: chanwe-footer(_chanwe-clean-str(doc-id), _chanwe-clean-str(edition)),
  )

  // ---- auto TOC (optional) ----------------------------------
  if toc {
    {
      set page(fill: second-page-bg)
      chanwe-agenda(
        eyebrow: toc-eyebrow,
        title: toc-title,
        lede: toc-lede,
      )
      pagebreak()
    }
  }

  // ---- auto abstract (optional) ----------------------------
  if abstract and abstract-text != none {
    // La página del abstract va sobre slate, como la del índice: el `set`
    // vive en este bloque y solo alcanza a la página que abre aquí.
    set page(fill: _t.surface-slate)
    // Todos estos llegan como argumento, no como contenido, asi que arrastran
    // el escape de Pandoc: sin limpiar, `SERIES-A #0934` sale `SERIES-A \#0934`.
    let all-meta = (
      "document": ("Document", _chanwe-clean-str(doc-id), none),
      "edition":  ("Edition",  _chanwe-clean-str(edition), none),
      "author":   ("Author",   _chanwe-clean-str(author),  none),
      "status":   ("Status",   if abstract-status != none { _chanwe-clean-str(abstract-status) } else { "" }, none),
      // Los keywords viajan como lista: el riel les da un chip a cada uno.
      "keywords": ("Keywords", abstract-keywords.map(_chanwe-clean-str), none),
    )
    let fields = if abstract-show.len() > 0 { abstract-show } else { all-meta.keys() }
    let meta-items = fields
      .filter(k => all-meta.at(k, default: none) != none)
      .map(k => all-meta.at(k))
      // Descarta tanto el valor vacio como la lista vacia.
      .filter(((_, v, ..)) => if type(v) == array { v.len() > 0 } else { v != "" })
    chanwe-abstract(
      eyebrow: abstract-eyebrow,
      title: abstract-title,
      meta: meta-items,
      takeaway: _chanwe-clean-str(abstract-takeaway),
      abstract-text,
    )
    pagebreak()
  }

  // ---- user body (paragraph overrides scoped here only) ----
  {
    set text(
      size: if body-size  != none { body-size  } else { 10pt    },
      fill: if body-color != none { body-color } else { _t.body-fg },
    )
    let _body-spacing = if body-spacing != none { body-spacing } else { 2.6em }
    set par(
      leading: if body-leading != none { body-leading } else { 0.85em },
      justify: if body-justify != none { body-justify } else { false  },
      spacing: _body-spacing,
    )
    // Listas de definición. Quarto trae en su `definitions.typ` una regla
    // `show terms.item` que apila el término y, en un bloque aparte, la
    // definición: ese bloque hereda el aire de párrafo del cuerpo (2.6em) y
    // el término quedaba a un renglón entero de su definición. Esta regla,
    // definida después, gana: mismo término en negrita y misma sangría, con
    // la definición a medio cuerpo del término. El aire entre ítems sigue
    // siendo el del cuerpo.
    set terms(spacing: _body-spacing, separator: h(0.6em))
    show terms.item: it => block(breakable: false)[
      #text(weight: _t.weight-bold, it.term)
      #block(above: 0.9em, inset: (left: 1.5em), it.description)
    ]
    body
  }

  // ---- back cover (optional) --------------------------------
  if back-cover {
    chanwe-back-cover-page(
      tagline-1: back-cover-tagline-1,
      tagline-2: back-cover-tagline-2,
      back-cols: back-cover-cols,
      cover-edge: cover-edge,
      caption-1: hero-caption-1,
      caption-2: hero-caption-2,
      caption-3: hero-caption-3,
      series: publication-series,
      doc-ref: doc-id,
      place-label: publication-location,
    )
  }
}

// chanwe-publications se fusiono aca: este formato es el de aquella, en A4,
// con la portada del viejo chanwe-report conservada como variante "hero".
#let chanwe = chanwe-report
