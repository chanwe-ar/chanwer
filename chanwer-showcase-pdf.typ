// Simple numbering for non-book documents
#let equation-numbering = "(1)"
#let callout-numbering = "1"
#let subfloat-numbering(n-super, subfloat-idx) = {
  numbering("1a", n-super, subfloat-idx)
}

// Theorem configuration for theorion
// Simple numbering for non-book documents (no heading inheritance)
#let theorem-inherited-levels = 0

// Theorem numbering format (can be overridden by extensions for appendix support)
// This function returns the numbering pattern to use
#let theorem-numbering(loc) = "1.1"

// Default theorem render function
#let theorem-render(prefix: none, title: "", full-title: auto, body) = {
  if full-title != "" and full-title != auto and full-title != none {
    strong[#full-title.]
    h(0.5em)
  }
  body
}
// Some definitions presupposed by pandoc's typst output.
#let content-to-string(content) = {
  if content.has("text") {
    content.text
  } else if content.has("children") {
    content.children.map(content-to-string).join("")
  } else if content.has("body") {
    content-to-string(content.body)
  } else if content == [ ] {
    " "
  }
}

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms.item: it => block(breakable: false)[
  #text(weight: "bold")[#it.term]
  #block(inset: (left: 1.5em, top: -0.4em))[#it.description]
]

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let fields = old_block.fields()
  let _ = fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => {
          let subfloat-idx = quartosubfloatcounter.get().first() + 1
          subfloat-numbering(n-super, subfloat-idx)
        })
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => block({
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          })

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let children = old_title_block.body.body.children
  let old_title = if children.len() == 1 {
    children.at(0)  // no icon: title at index 0
  } else {
    children.at(1)  // with icon: title at index 1
  }

  // TODO use custom separator if available
  // Use the figure's counter display which handles chapter-based numbering
  // (when numbering is a function that includes the heading counter)
  let callout_num = it.counter.display(it.numbering)
  let new_title = if empty(old_title) {
    [#kind #callout_num]
  } else {
    [#kind #callout_num: #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block,
    block_with_new_content(
      old_title_block.body,
      if children.len() == 1 {
        new_title  // no icon: just the title
      } else {
        children.at(0) + new_title  // with icon: preserve icon block + new title
      }))

  align(left, block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1)))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color,
        width: 100%,
        inset: 8pt)[#if icon != none [#text(icon_color, weight: 900)[#icon] ]#title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}



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
#let _chanwe-assets = "\_extensions/chanwe-report/assets/".replace("\\_", "_")

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
// =================================================================
// chanwe-qr.typ — El QR de contacto, enmarcado.
//
// Componente compartido, como `chanwe-cards.*` y `chanwe-lists.*`: se
// incluye por ruta padre —`- ../chanwe-report/chanwe-qr.typ` bajo
// `template-partials`, y la llamada al parcial después de la tabla `_t` del
// formato. (No se escribe acá con su sintaxis real: el motor de plantillas
// de Pandoc la expandiría dentro de este mismo comentario.)
// Lo usan la portada research y la contratapa del reporte, el memo, la
// propuesta y el fondo de pantalla de reMarkable. No se copia.
//
// El marco es el de la contratapa, punto por punto: filete de 0.5pt,
// esquina exterior de 1.4mm, y adentro una tarjeta clara con esquina de
// 0.8mm. El código queda siempre oscuro sobre claro, que es lo único que
// los lectores levantan de forma confiable.
//
// Ningún trazo escribe un color: `edge` y `card` los pasa el formato desde
// su propia tabla de tokens, y por eso no tienen default. Sobre obsidiana
// el filete es blanco al 16% (`_t.white.transparentize(84%)`); sobre papel
// es el 16% del negro de marca (`_t.ink.transparentize(84%)`) —la misma
// presencia visual con la polaridad dada vuelta, porque un blanco al 16%
// sobre papel no se ve.
//
// El asset por defecto es `assets/contact-qr.svg`, que codifica
// https://chanwe.com.ar (v3, nivel H, máscara 4). Lo genera
// `scripts/make-qr-svg.mjs`; no se edita a mano.
// =================================================================

#let chanwe-qr-frame(
  path,
  size:         11.4mm,   // lado del código, sin contar marco ni tarjeta
  edge:         none,     // color del filete exterior — lo pasa el formato
  card:         none,     // color de la tarjeta interior — idem
  pad-outer:    2mm,      // aire entre el filete y la tarjeta
  pad-inner:    0.8mm,    // zona tranquila de la tarjeta alrededor del código
  radius-outer: 1.4mm,
  radius-inner: 0.8mm,
) = box(
  stroke: 0.5pt + edge,
  radius: radius-outer,
  inset: pad-outer,
  box(
    fill: card,
    radius: radius-inner,
    inset: pad-inner,
    image(path, width: size, fit: "contain"),
  ),
)// =============================================================
// chanwe-cover.typ — portadas de Chanwe Report
// =============================================================
// Dos portadas: la research (por defecto) y la "hero" del viejo
// chanwe-report, al final del archivo.
//
// La research sigue la geometría de reports-covers.pdf:
//   532 px editorial field | 34 px legal gutter | 250 px black rail
//   700 px artwork/title header | 304 px title slab | 52 px footer
// at a 96 dpi, 816 x 1056 px US Letter canvas.
// =============================================================

// Pandoc/Quarto escapes underscores and hyphens in YAML values.
#let _chanwe-clean-path(p) = if p == none { none } else { p.replace("\\_", "_").replace("\\-", "-") }

// Pandoc's typst writer escapes markup characters inside YAML metadata
// strings (@ → \@, _ → \_, # → \#, / → \/); strip those so they never
// print literally.
#let _chanwe-clean-str(s) = if s == none { none } else if type(s) == str {
  s.replace("\\@", "@").replace("\\_", "_").replace("\\-", "-").replace("\\#", "#").replace("\\/", "/")
} else { s }

// Los tonos de la portada research, todos leídos de la tabla de tokens.
// Antes había tres constantes más —un papel de arte #FAF9F7, un naranja
// #F4380F y un metálico #AFAFAF— que ningún trazo usaba; se fueron.
#let _publication-paper = _t.callout-surface
#let _publication-ink = _t.ink
#let _publication-rule = _t.rule
#let _publication-muted = _t.research-muted

// Decorative bar pattern for the footer's series stamp. Not a scannable
// code — a print-editorial flourish, same spirit as the rotated legal rail.
#let _publication-barcode(height: 2.6mm) = {
  let widths = (1.4pt, 0.7pt, 0.7pt, 2.1pt, 0.7pt, 1.4pt, 0.7pt, 2.1pt, 1.4pt, 0.7pt, 0.7pt, 2.1pt, 0.7pt, 1.4pt, 0.7pt)
  box(height: height, stack(
    dir: ltr,
    spacing: 0.6pt,
    // En el slate del texto de servicio que lo acompaña, no en tinta: es un
    // sello decorativo, no un dato.
    ..widths.map(w => rect(width: w, height: 100%, fill: _t.fg-muted, stroke: none)),
  ))
}

#let _publication-meta-row(label, value, sub: none) = block(
  width: 100%,
  height: 7.673mm,
  stroke: (top: 0.5pt + _publication-rule),
)[
  #align(horizon, grid(
    columns: (32mm, 1fr),
    align: (left + horizon, left + horizon),
    text(
      font: _t.font-mono,
      size: 6.6pt,
      weight: _t.weight-medium,
      tracking: 0.15em,
      fill: _publication-muted,
      upper(_chanwe-clean-str(label)),
    ),
    block(spacing: 0pt)[
      #set par(leading: 0.78em)
      // Toda la losa de datos en JetBrains Mono: rótulo, valor y bajada.
      #text(font: _t.font-mono, size: 9pt, weight: _t.weight-regular, fill: _publication-ink, _chanwe-clean-str(value))
      #if sub != none and sub != "" {
        h(4pt)
        text(fill: _publication-muted, sym.dot.c)
        h(4pt)
        text(font: _t.font-mono, size: 6pt, tracking: 0.05em, fill: _publication-muted, upper(_chanwe-clean-str(sub)))
      }
    ],
  ))
]

// Campo de puntos de contratapa: trama pareja sobre obsidiana y un foco donde
// los mismos puntos se encienden. El foco se dibuja punto por punto — un
// tiling no se puede enmascarar con un degradado.
#let _chanwe-dot-field(
  width: _chanwe-page-w,
  height: _chanwe-page-h,
  step: 3.8mm,
  dot: 0.55pt,
  focus: (0.74, 0.40),
  focus-radius: 0.34,
  peak: 75%,
  base: 72%,
  color: _t.ink-fg,
  // (izquierda, derecha) en transparencia: la trama se va abriendo de un lado
  // al otro. Con `ramp` no sirve el tiling, que es parejo por definición.
  ramp: none,
) = {
  if ramp != none {
    let (l, r) = ramp
    let s = step / 1mm
    for i in range(int(width / step)) {
      let x = (i + 0.5) * s
      let t = x * 1mm / width
      let a = l + (r - l) * t
      for j in range(int(height / step)) {
        place(top + left, dx: x * 1mm, dy: (j + 0.5) * s * 1mm,
          circle(radius: dot, fill: color.transparentize(a)))
      }
    }
    return
  }

  place(top + left, rect(
    width: width, height: height, stroke: none,
    fill: tiling(size: (step, step))[
      #place(dx: step / 2, dy: step / 2, circle(radius: dot, fill: color.transparentize(base)))
    ],
  ))

  let fx = focus.at(0) * width / 1mm
  let fy = focus.at(1) * height / 1mm
  let r = focus-radius * width / 1mm
  let s = step / 1mm
  for i in range(int(width / step)) {
    for j in range(int(height / step)) {
      let x = (i + 0.5) * s
      let y = (j + 0.5) * s
      let d = calc.sqrt(calc.pow(x - fx, 2) + calc.pow(y - fy, 2))
      if d >= r { continue }
      // Caída suave: encendido en el centro, apagado en el borde.
      let t = calc.pow(1 - d / r, 1.5)
      place(top + left, dx: x * 1mm, dy: y * 1mm,
        circle(radius: dot, fill: color.transparentize(100% - t * peak)))
    }
  }
}


#let chanwe-cover-page(
  title: "Untitled",
  subtitle: none,
  doc-id: "SERIES-A #0934",
  edition: "Edition 01 / 2026",
  volume: "PÚBLICO",
  rail-eyebrow: "SEC.01",
  hero-image: none,
  hero-img-position: none,
  wordmark: none,
  stamp: ("est.", "mdz", "2026"),
  hero-caption-1: "32°53'24.8\"S  68°50'45.6\"W",
  hero-caption-2: "ELEV: 6967M // CERRO ACONCAGUA",
  hero-caption-3: "CORDILLERA PRINCIPAL · MENDOZA, AR",
  hero-date: "",
  meta-rows: (),
  date: "",
  show-date-strip: false,
  cover-edge: none,
  cover-edge-color: none,
  publication-period: none,
  // Lo que dice la pastilla del masthead.
  badge: "CW- MACRO LAB",
  publication-edition: none,
  publication-art: none,
  publication-audience: "PÚBLICO",
  publication-series: "CHANWE / RESEARCH",
  publication-location: "MENDOZA / ARGENTINA",
  publication-qr: none,
  publication-copyright: "PROHIBIDA SU REPRODUCCIÓN SIN AUTORIZACIÓN | TODOS LOS DERECHOS RESERVADOS",
) = {
  let art = if publication-art != none {
    _chanwe-clean-path(publication-art)
  } else if hero-image != none {
    _chanwe-clean-path(hero-image)
  } else {
    _chanwe-assets + "cover-snow-ridge.jpg"
  }
  let period = if publication-period != none { publication-period } else { date }
  let edition-label = if publication-edition != none { publication-edition } else { edition }
  let copyright = if cover-edge != none { cover-edge } else { publication-copyright }
  let rail-wordmark = if wordmark == none {
    // Gris frío sobre la obsidiana: el blanco puro pesaba demasiado.
    _chanwe-assets + "Logo_Gris.svg"
  } else {
    _chanwe-clean-path(wordmark)
  }
  let qr = if publication-qr == none {
    _chanwe-assets + "contact-qr.svg"
  } else {
    _chanwe-clean-path(publication-qr)
  }

  // La serie y la ubicación llevan la barra en bermellón, así que se parten
  // por ella: "CHANWE / RESEARCH" y "MENDOZA / ARGENTINA".
  let split-slash(value, fallback) = {
    let parts = _chanwe-clean-str(value).split("/")
    if parts.len() >= 2 { (parts.at(0).trim(), parts.at(1).trim()) } else { (parts.at(0).trim(), fallback) }
  }
  let (series-1, series-2) = split-slash(publication-series, "")
  let (rail-location-1, rail-location-2) = split-slash(publication-location, "")

  // Geometría en cuatro bandas: masthead 26.6mm, campo de arte `1fr`, losa
  // de datos y titular `auto`, pie 13.758mm. Masthead y pie son bandas de
  // contenido y quedan en milímetros; el arte es elástico y se come la
  // diferencia de alto entre un papel y otro. El reparto de columnas es
  // 74 / 26, el de la referencia, ahora como fracción del ancho de hoja.
  let field-w = _chanwe-page-w * 0.74
  let rail-w = _chanwe-page-w * 0.26
  let pad = 10.583mm
  let content-w = field-w - pad * 2

  set page(
    paper: _chanwe-paper,
    margin: 0pt,
    header: none,
    footer: none,
    fill: _publication-paper,
    background: none,
    foreground: none,
  )
  set block(spacing: 0pt)

  block(width: 100%, height: _chanwe-page-h, breakable: false)[
    #grid(
      columns: (field-w, rail-w),
      rows: (_chanwe-page-h,),
      column-gutter: 0pt,

      // ══ Campo editorial ═════════════════════════════════════
      block(width: 100%, height: _chanwe-page-h)[

        // ── Masthead: período y edición a la izquierda, la posición
        // del observatorio a la derecha, repartida en la altura.
        #let masthead-h = 11.4mm
        #grid(
          rows: (26.6mm, 1fr, auto, 13.758mm),
          row-gutter: 0pt,

          block(
          width: 100%,
          height: 26.6mm,
          stroke: (bottom: 0.5pt + _publication-rule),
          inset: (left: pad, right: pad, top: 7.6mm, bottom: 7.6mm),
        )[
          #grid(
            columns: (1fr, auto),
            block(width: 100%, height: masthead-h)[
              // El período va en pastilla gris. El cuerpo baja para que la
              // pastilla entera ocupe el espacio que ocupaba el texto solo.
              #place(bottom + left,
                // Misma pastilla que la serie del pie, en tinta y con el
                // texto en blanco.
                box(
                  stroke: 0.5pt + _publication-muted,
                  radius: 2pt,
                  inset: (x: 3.06mm, y: 1.44mm),
                  text(
                    font: _t.font-mono, size: 6.5pt, weight: _t.weight-regular,
                    tracking: 0.18em, fill: _publication-muted, upper(_chanwe-clean-str(badge)),
                  ),
                ))
              #place(top + left,
                box(
                  fill: _publication-ink,
                  radius: 2pt,
                  inset: (x: 3.06mm, y: 1.44mm),
                  // Texto sobre tinta en rule-cool, no en blanco.
                  text(
                    font: _t.font-mono, size: 6.5pt, weight: _t.weight-regular,
                    tracking: 0.18em, fill: _t.rule-cool, upper(edition-label),
                  ),
                ))
            ],
            // Ancho fijo: el contenido va posicionado, así que no aporta
            // ancho intrínseco y la columna colapsaría.
            block(width: 60mm, height: masthead-h)[
              // Las tres filas comparten exactamente el mismo estilo: una
              // sola declaración, aplicada a las tres.
              #set text(
                font: _t.font-mono, size: 5.4pt, weight: _t.weight-body,
                tracking: 0.18em, fill: _publication-muted,
              )
              // Las tres filas como un bloque compacto, centrado contra la
              // columna de la izquierda: antes se estiraban de borde a borde.
              #place(horizon + right, block(spacing: 0pt)[
                #set align(right)
                #text(upper(hero-caption-1))
                #v(0.5mm)
                #text(upper(hero-caption-2))
                #v(0.5mm)
                #text(upper(hero-caption-3))
              ])
            ],
          )
        ],

          // ── Campo de arte: la fila elástica. El radar sangra de lado a
          // lado, sin caja blanca que lo encierre.
          block(width: 100%, height: 100%, clip: true)[
          // El arte entra un 30% más grande y centrado: la banda recorta el
          // sobrante por los cuatro lados.
          // 190% deja 45% de sobrante por lado; el corrimiento no puede
          // pasar de eso sin destapar el papel por abajo.
          #place(center + horizon, dy: -39%,
                 image(art, width: 190%, height: 190%, fit: "cover"))
          // Velo de papel al 80% sobre el arte: Typst no expone opacidad
          // sobre imágenes, así que la tinta rebajada se consigue con el
          // papel encima a esa opacidad. Subir el velo baja la imagen: al
          // 80% (antes 75%) el arte queda un 5% más transparente.
          #place(top + left, rect(width: 100%, height: 100%, stroke: none,
                                  fill: _publication-paper.transparentize(20%)))
        ],

          // ── Losa: ledger de datos y, debajo, el titular con su línea
          // bermellón. De alto automático: crece con el titular.
          block(width: 100%, inset: (left: pad, right: pad, top: 0mm, bottom: 7.5mm))[
          #if meta-rows.len() > 0 {
            // Los filetes van de orilla a orilla del campo —de la hoja al
            // riel negro—, así que el bloque sale del margen y lo devuelve
            // como inset para que el texto no se mueva.
            move(dx: -pad, block(
              width: field-w,
              stroke: (top: 0.5pt + _publication-rule, bottom: 0.5pt + _publication-rule),
              inset: (left: pad, right: pad, top: 8.4mm, bottom: 8.4mm),
              spacing: 0pt,
            )[
              #grid(
                columns: (34.6mm, 1fr),
                row-gutter: 3.4mm,
                column-gutter: 0pt,
                align: (left + horizon, left + horizon),
                ..meta-rows.map(((label, value, sub)) => (
                  text(
                    font: _t.font-mono, size: 6.6pt, weight: _t.weight-regular,
                    tracking: 0.18em, fill: _publication-muted,
                    upper(_chanwe-clean-str(label)),
                  ),
                  {
                    // Mismo tono que la bajada del titular, un escalón más
                    // fino y 10% más chico; en JetBrains Mono como el resto
                    // de la losa de datos.
                    text(font: _t.font-mono, size: 7.3pt, weight: _t.weight-body,
                         fill: _t.fg-muted, _chanwe-clean-str(value))
                    if sub != none and sub != "" {
                      h(2.4mm)
                      box(baseline: -0.6pt, circle(radius: 0.75pt, fill: _publication-rule, stroke: none))
                      h(2.4mm)
                      text(font: _t.font-mono, size: 5.2pt, tracking: 0.05em,
                           fill: _publication-muted, upper(_chanwe-clean-str(sub)))
                    }
                  },
                )).flatten()
              )
            ])
            v(14mm)
          }

          // La línea de datum es el filete izquierdo del bloque, no un
            // rectángulo de alto fijo: así mide exactamente lo que mide el
            // texto. Y el texto mide de altura de mayúscula a línea de base
            // (top-edge / bottom-edge), así que el filete arranca en el tope
            // de la "R" y termina en la base de la última línea de la bajada.
            #block(
              width: content-w,
              spacing: 0pt,
              stroke: (left: 0.8mm + _t.primary),
              inset: (left: 6.4mm),
            )[
              #set text(top-edge: "cap-height", bottom-edge: "baseline")
              #block(width: 100%, spacing: 0pt)[
                #set par(leading: 0.74em, spacing: 0pt)
                #text(
                  font: _t.font-display, size: 34pt, weight: _t.weight-display,
                  tracking: -0.05em, fill: _publication-ink, title,
                )#box(baseline: -1pt, {
                  h(3.5pt)
                  circle(radius: 3.9pt, fill: _t.primary, stroke: none)
                })
              ]
              #v(5.2mm)
              #block(width: 100%, spacing: 0pt)[
                #set par(leading: 0.62em, spacing: 0pt)
                #text(
                  font: _t.font-sans, size: 12.6pt, weight: _t.weight-thin,
                  style: "italic", fill: _t.fg-muted, subtitle,
                )
              ]
            ]
        ],

          // ── Pie del campo: la pastilla de serie y, a la derecha, el doc-id
          // con su sello. Comparte banda con el pie del riel.
          block(
          width: 100%,
          height: 13.758mm,
          fill: _publication-paper,
          stroke: (top: 0.5pt + _publication-rule),
          inset: (left: pad, right: 11.112mm),
        )[
          #align(horizon, grid(
            columns: (1fr, auto),
            align: (left + horizon, right + horizon),
            box(fill: _t.primary, radius: 2pt, inset: (x: 3.4mm, y: 1.6mm))[
              #set text(font: _t.font-mono, size: 7.2pt, weight: _t.weight-medium, tracking: 0.18em, fill: _t.white)
              #text(weight: _t.weight-bold, "//")
              #h(3.2mm)
              #upper(series-1)
              #text(fill: _t.white.transparentize(35%), " / ")
              #upper(series-2)
            ],
            grid(
              columns: (auto, auto),
              column-gutter: 4.5mm,
              align: horizon,
              text(font: _t.font-mono, size: 6.4pt, weight: _t.weight-regular, tracking: 0.1em,
                   fill: _publication-muted, upper(_chanwe-clean-str(doc-id))),
              _publication-barcode(),
            ),
          ))
        ],
        )
      ],

      // ══ Riel obsidiana ══════════════════════════════════════
      block(width: 100%, height: _chanwe-page-h, fill: _publication-ink, clip: true)[

        // ── QR: tarjeta blanca arriba, con el dominio debajo.
        // El QR va centrado en el riel. Llevaba 3mm a la derecha para caer
        // sobre el centro óptico del wordmark rotado —que no es el de su
        // caja, porque el ® cuelga a un costado—, pero el corrimiento se
        // leía como un error de alineación contra los bordes del riel, que
        // es con lo que el ojo lo compara. Manda el riel.
        // El marco es el del QR de la contratapa —filete blanco al 16%,
        // tarjeta blanca adentro—, al tamaño del riel: el código de 20.5mm
        // de la contratapa pesaba demasiado en una columna de 55mm.
        #place(top + center, dy: 7.3mm)[
          #chanwe-qr-frame(
            qr,
            size: 11.4mm,
            edge: _t.white.transparentize(84%),
            card: _t.white,
          )
        ]

        // ── Legal rotado, pegado al borde izquierdo.
        #place(center + horizon, dx: -22mm,
          rotate(-90deg, origin: center + horizon,
            box(width: 175mm)[
              #set align(center)
              #text(
                font: _t.font-mono, size: 6.2pt, weight: _t.weight-regular,
                tracking: 0.24em, fill: _t.ink-fg.transparentize(40%), upper(copyright),
              )
            ]
          )
        )

        // ── El wordmark, rotado y grande.
        #place(center + horizon,
          rotate(-90deg, origin: center + horizon,
            image(rail-wordmark, width: 55.5mm, fit: "contain")
          )
        )

        // ── Pie del riel, con su filete.
        #place(bottom + left, dy: 0mm,
          block(
            width: rail-w,
            height: 13.5mm,
            stroke: (top: 0.5pt + _t.white.transparentize(82%)),
          )[
            #align(center + horizon, {
              set text(font: _t.font-mono, size: 5.6pt, weight: _t.weight-regular, tracking: 0.16em)
              // En rule-cool, la regla de la marca para texto sobre tinta.
              text(fill: _t.rule-cool, upper(rail-location-1))
              text(fill: _t.primary, " / ")
              text(fill: _t.rule-cool, upper(rail-location-2))
            })
          ])
      ],
    )
  ]

  // ---- Blank interstitial page (same behavior as chanwe-report)
  set page(
    paper: _chanwe-paper, margin: 0pt, header: none, footer: none,
    fill: _publication-paper, foreground: none,
    background: _chanwe-dot-field(color: _publication-muted, base: 74%, focus-radius: 0),
  )
  set block(spacing: 0pt)
  block(width: 100%, height: _chanwe-page-h)[]
}

// =============================================================
// BACK COVER — retained from chanwe-report, sized to US Letter
// =============================================================
#let _chanwe-blank-interstitial() = {
  set page(paper: _chanwe-paper, margin: 0pt, header: none, footer: none, fill: _publication-paper,
           foreground: none,
           background: _chanwe-dot-field(color: _publication-muted, base: 74%, focus-radius: 0))
  set block(spacing: 0pt)
  block(width: 100%, height: _chanwe-page-h)[]
}

#let chanwe-back-cover-page(
  wordmark-light: none,
  tagline-1: "Less template,",
  tagline-2: "more report.",
  back-cols: (),
  cover-edge: none,
  // Las mismas tres filas que el masthead de la portada.
  caption-1: "",
  caption-2: "",
  caption-3: "",
  // Pie de contratapa.
  series: "CHANWE · RESEARCH & ADVISORY",
  doc-ref: "SERIES-A #0934",
  place-label: "MENDOZA · ARGENTINA",
  qr-art: none,
) = {
  // Sobre la obsidiana el wordmark va en slate, no en blanco puro.
  let wl = if wordmark-light != none { _chanwe-clean-path(wordmark-light) } else { _chanwe-assets + "Logo_Gris.svg" }
  let qr = if qr-art != none { _chanwe-clean-path(qr-art) } else { _chanwe-assets + "contact-qr.svg" }

  _chanwe-blank-interstitial()

  set page(
    paper: _chanwe-paper, margin: 0pt, header: none, footer: none, fill: _t.ink,
    background: _chanwe-dot-field(),
    foreground: if cover-edge != none {
      place(right + top, dx: -3mm, dy: 14mm,
        rotate(-90deg, origin: right + horizon,
          text(font: _t.font-mono, size: 7pt, weight: _t.weight-thin, tracking: 0.5em,
               fill: _t.white.transparentize(25%), upper(cover-edge))
        )
      )
    },
  )
  set block(spacing: 0pt)

  block(
    width: 100%, height: _chanwe-page-h, breakable: false,
    inset: (x: 16mm, top: 14mm, bottom: 14mm),
  )[
    #grid(
      rows: (auto, 1fr, auto),
      row-gutter: 0pt,

      align(left + top, block(width: 100%, spacing: 0pt)[
        // Wordmark a la izquierda y, enfrentadas, las tres filas del
        // masthead de la portada. Mismo estilo, en tono claro sobre tinta.
        #grid(
          columns: (1fr, auto),
          align: (left + bottom, right + bottom),
          if wl != none {
            image(wl, height: 10.1mm, fit: "contain")
          } else {
            text(font: _t.font-display, size: 36pt, weight: _t.weight-display,
                 tracking: -0.05em, fill: _t.white, "chanwe")
          },
          block(spacing: 0pt)[
            // La fila del medio manda: más clara y un punto más grande. Las
            // otras dos se corren atrás, como en la referencia.
            #set align(right)
            #set text(font: _t.font-mono, weight: _t.weight-body, tracking: 0.16em)
            #text(size: 5.9pt, fill: _t.ink-subtle, upper(caption-1))
            #v(0.9mm)
            #text(size: 5.9pt, weight: _t.weight-regular, fill: _t.rule-cool, upper(caption-2))
            #v(0.9mm)
            #text(size: 5.9pt, fill: _t.ink-subtle, upper(caption-3))
          ],
        )
          #v(11mm)
          // Filete de acento bajo el masthead, del mismo grosor que el
          // eyebrow de la portada.
          #rect(width: 100%, height: 0.4pt, fill: _t.primary, stroke: none)
      ]),

      [],

      block[
        // Bajada a la izquierda y el QR enmarcado a la derecha, apoyados en
        // la misma línea de base.
        #grid(
          columns: (1fr, auto),
          align: (left + bottom, right + bottom),
          block(spacing: 0pt)[
            #set par(leading: 0.8em, justify: false)
            #text(font: _t.font-serif-display, style: "italic", size: 43.4pt,
                  weight: _t.weight-regular, tracking: -0.02em, fill: _t.rule-cool, tagline-1)
            #linebreak()
            #text(font: _t.font-serif-display, style: "italic", size: 43.4pt,
                  weight: _t.weight-regular, tracking: -0.02em, fill: _t.primary, tagline-2)
          ],
          // El marco imita la referencia; el código queda oscuro sobre claro,
          // que es lo único que los lectores levantan de forma confiable.
          chanwe-qr-frame(
            qr,
            size: 20.5mm,
            edge: _t.white.transparentize(84%),
            card: _t.white,
            pad-outer: 2.6mm,
            pad-inner: 1mm,
          ),
        )
        #v(18mm)
        #line(length: 100%, stroke: 0.5pt + _t.white.transparentize(84%))
        #v(4.5mm)
        // Pie en tres partes: serie, referencia del documento y plaza.
        #grid(
          columns: (1fr, 1fr, 1fr),
          align: (left + horizon, center + horizon, right + horizon),
          {
            set text(font: _t.font-mono, size: 6pt, weight: _t.weight-body, tracking: 0.12em)
            text(fill: _t.primary, "//")
            h(2.2mm)
            // Mismo gris que la referencia y la plaza: un solo tono en el renglón.
            text(fill: _t.ink-subtle, upper(_chanwe-clean-str(series)))
          },
          text(font: _t.font-mono, size: 6pt, weight: _t.weight-body, tracking: 0.08em,
               fill: _t.ink-subtle, _chanwe-clean-str(doc-ref)),
          text(font: _t.font-mono, size: 6pt, weight: _t.weight-body, tracking: 0.12em,
               fill: _t.ink-subtle, upper(_chanwe-clean-str(place-label))),
        )
        #if back-cols.len() > 0 {
          v(8mm)
          grid(
            columns: back-cols.map(_ => 1fr),
            column-gutter: 8mm,
            // Primera columna a la izquierda, última a la derecha, las del
            // medio centradas: las tres apoyan en los bordes del pie.
            ..back-cols.enumerate().map(((i, col)) => {
              let (label, value, sub) = col
              let al = if i == 0 { left } else if i == back-cols.len() - 1 { right } else { center }
              block(spacing: 0pt, width: 100%)[
                #set align(al)
                // Las tres líneas en JetBrains Mono, en versalita, al mismo
                // cuerpo y peso y con el mismo aire entre una y otra: rótulo,
                // valor y bajada son un solo renglón de servicio.
                #set par(spacing: 0pt, leading: 0pt)
                // Mismo cuerpo y peso que la referencia del pie (6pt / 300);
                // rótulo y bajada en su mismo gris (ink-subtle), el valor en
                // rule-cool.
                #text(font: _t.font-mono, size: 6pt, weight: _t.weight-body, tracking: 0.20em,
                      fill: _t.ink-subtle, upper(_chanwe-clean-str(label)))
                #v(3mm)
                #text(font: _t.font-mono, size: 6pt, weight: _t.weight-body, tracking: 0.12em,
                      fill: _t.rule-cool, upper(_chanwe-clean-str(value)))
                #if sub != none and sub != "" {
                  v(3mm)
                  text(font: _t.font-mono, size: 6pt, weight: _t.weight-body, tracking: 0.12em,
                       fill: _t.ink-subtle, upper(_chanwe-clean-str(sub)))
                }
              ]
            })
          )
        }
      ],
    )
  ]
}

// =================================================================
// VARIANTE DE PORTADA: "hero"
// La portada que traia chanwe-report antes de la fusion: panel hero a la
// derecha, riel rotado y losa de wordmark al pie, con `dark` para pasar esa
// losa a tinta. Se conserva entera como variante; la portada research de
// arriba (`chanwe-cover-page`) es la que manda por defecto.
// `chanwe-texture` solo la usa esta portada.
// =================================================================

#let chanwe-texture(w, h, mode: "paper", radials: true) = {
  let on-ink = mode == "ink"
  let base = if on-ink { _t.ink } else { _t.paper }
  let stroke-ink = if on-ink { _t.white } else { _t.ink }
  // trama opacities: paper .036 / .022 — ink .05 / .03
  let (a147, a57) = if on-ink { (95%, 97%) } else { (96.4%, 97.8%) }
  let u = w / 1080                    // one story-px at this width
  // One trama = a tiling whose single hairline runs corner-to-corner, so
  // adjacent tiles continue it seamlessly. (Repeated hard-stop gradients
  // get resampled into smooth ramps by PDF shading — real vector lines
  // stay hairlines at any zoom.) `ang` is the line direction on the page;
  // `step` is the perpendicular spacing in story-px.
  let trama(ang, step, alpha) = {
    let s = step * u
    let px = s / calc.abs(calc.sin(ang))
    let py = s / calc.abs(calc.cos(ang))
    let downhill = calc.cos(ang) * calc.sin(ang) < 0
    tiling(size: (px, py), place(top + left, line(
      start: if downhill { (px, 0pt) } else { (0pt, 0pt) },
      end: if downhill { (0pt, py) } else { (px, py) },
      stroke: (paint: stroke-ink.transparentize(alpha), thickness: u, cap: "butt"),
    )))
  }
  let light = gradient.radial(
    (_t.white.transparentize(if on-ink { 90% } else { 10% }), 0%),
    (_t.white.transparentize(100%), 58%),
    (_t.white.transparentize(100%), 100%),
    center: (82%, 8%), radius: 95%,
  )
  let shadow-ink = if on-ink { _t.black } else { _t.ink }
  let shadow = gradient.radial(
    (shadow-ink.transparentize(if on-ink { 45% } else { 95% }), 0%),
    (shadow-ink.transparentize(100%), 60%),
    (shadow-ink.transparentize(100%), 100%),
    center: (12%, 96%), radius: 80%,
  )
  box(width: w, height: h, clip: true, {
    place(top + left, rect(width: w, height: h, fill: base))
    // the 15-step trama runs along 57° (its CSS gradient axis is 147°),
    // the 26-step counter-trama runs perpendicular to it
    place(top + left, rect(width: w, height: h, fill: trama(147deg, 26, a57)))
    place(top + left, rect(width: w, height: h, fill: trama(57deg, 15, a147)))
    if radials {
      place(top + left, rect(width: w, height: h, fill: shadow))
      place(top + left, rect(width: w, height: h, fill: light))
    }
  })
}


#let chanwe-hero-cover-page(
  title: "Untitled",
  subtitle: none,
  doc-id: "CHW · DOC · 2026 · 01",
  edition: "Edition 01 / 2026",
  volume: "Vol. II",
  rail-eyebrow: "Quarto · Style Guide",
  hero-image: none,
  hero-img-position: none,  // 1–10 (left→right); none = fit:cover (centered)
  wordmark: none, // defaults to wordmark-only logo below
  stamp: ("est.", "mdz", "2026"),
  hero-caption-1: "S 32°53′ · W 68°50′",
  hero-caption-2: "Cordón del Plata · ARG",
  hero-date: "17 · 04 · 2026",
  meta-rows: (),
  date: "",
  show-date-strip: false,
  cover-edge: none,
  cover-edge-color: none,
  dark: false,  // dark wordmark slab: the bottom band goes ink with the white wordmark
) = {
  let hero-image = if hero-image == none {
    _chanwe-assets + "hero-img.svg"
  } else {
    _chanwe-clean-path(hero-image)
  }
  let _edge-color = if cover-edge-color != none { cover-edge-color } else { _t.primary }
  let wordmark = if wordmark == none {
    _chanwe-assets + (if dark { "Logo_Blanco.svg" } else { "Logo_Negro.svg" })
  } else {
    _chanwe-clean-path(wordmark)
  }
  let _slab-bg = if dark { _t.ink } else { _t.paper }
  set page(
    paper: _chanwe-paper, margin: 0pt, header: none, footer: none, fill: _t.paper,
    background: place(top + left, chanwe-texture(210mm, 297mm)),
    foreground: {
      place(top + left, dx: 50mm, dy: -50mm,
        circle(radius: 110mm,
          fill: gradient.radial(_t.primary.transparentize(78%), _t.black.transparentize(100%)),
          stroke: none,
        )
      )
      if cover-edge != none {
        place(right + top, dx: -3mm, dy: 14mm,
          rotate(-90deg, origin: right + horizon,
            text(font: _t.font-mono, size: 7pt, weight: _t.weight-thin, tracking: 0.5em,
                 fill: _edge-color, upper(_chanwe-clean-str(cover-edge)))
          )
        )
      }
    },
  )
  set block(spacing: 0pt)

  // ---- 1. TOP METADATA BAR (10mm) ---------------------------
  // Transparent over the page texture; the doc id sits in the
  // story-covers accent tab (solid FD3810, white mono caps).
  block(
    width: 100%, height: 10mm,
    fill: none,
    stroke: (bottom: 0.5pt + _t.ink),
    inset: (x: 16mm, y: 0pt),
  )[
    #set align(horizon)
    #grid(
      columns: (1fr, 1fr),
      align: (left + horizon, right + horizon),
      // doc id (left) — accent tab
      box(
        fill: _t.primary,
        inset: (x: 7pt, y: 3.5pt),
        text(font: _t.font-mono, size: 6.5pt, weight: _t.weight-medium, tracking: 0.16em,
             fill: _t.white, upper(_chanwe-clean-str(doc-id))),
      ),
      // edition · volume (right)
      {
        set text(font: _t.font-mono, size: 7pt, tracking: 0.16em)
        upper[#text(weight: _t.weight-display, fill: _t.fg, _chanwe-clean-str(edition))]
        h(16pt)
        upper[#text(fill: _t.fg-muted, _chanwe-clean-str(volume))]
      },
    )
  ]

  // ---- 2. HERO REGION (237mm) -------------------------------
  block(width: 100%, height: 237mm, breakable: false)[
    #grid(
      columns: (136.5mm, 73.5mm),
      rows: (237mm,),
      column-gutter: 0pt,

      // ---------- LEFT RAIL ----------
      block(
        width: 100%, height: 237mm,
        fill: none,
        stroke: (right: 1pt + _t.ink),
        inset: (left: 16mm, right: 9mm, top: 14mm, bottom: 12mm),
      )[
        // eyebrow with rule
        #chanwe-eyebrow(rail-eyebrow, with-rule: true)

        #v(8mm)

        // big display title — emph parts keep title type, only turning orange
        #set par(leading: 0.8em, justify: false)
        #show emph: it => text(fill: _t.primary, it.body)
        #block[
          #text(
            font: _t.font-display, size: 36pt, weight: _t.weight-display,
            tracking: -0.05em, fill: _t.fg,
            title,
          )#box(baseline: -2pt, {
            // no glue between title and box: the terminal dot must never
            // wrap to its own line, so the 3pt gap lives inside the box
            h(3pt)
            circle(radius: 4pt, fill: _t.primary, stroke: none)
          })
        ]

        #if subtitle != none {
          v(8mm)
          set par(leading: 0.55em)
          set text(font: _t.font-serif, size: 14pt, weight: _t.weight-body, style: "italic", fill: _t.emphasis)
          subtitle
        }

        #v(1fr)
        #line(length: 100%, stroke: 0.5pt + _t.border)
        #v(6mm)

        // stack of label / value / sub rows
        #stack(
          spacing: 9mm,
          ..meta-rows.map(((label, value, sub)) => chanwe-meta-row(label, value, sub: sub))
        )
      ],

      // ---------- RIGHT HERO PANEL ----------
      box(
        width: 100%, height: 237mm,
        fill: _t.ink,
        clip: true,
      )[
        // hero image fills the panel
        #if hero-img-position == none {
          place(top + left,
            image(hero-image, width: 100%, height: 237mm, fit: "cover"))
        } else {
          // An image with only `height:` set resolves its width to the
          // available 73.5mm and center-crops (fit: "cover"), so the pan
          // must draw at the true scaled width: measure the natural size
          // in context, scale to 237mm tall, then shift by the excess.
          place(top + left,
            context {
              let pos-frac = calc.clamp((hero-img-position - 1) / 9, 0, 1)
              let nat = measure(image(hero-image))
              let w = 237mm * (nat.width / nat.height)
              let excess = calc.max(w - 73.5mm, 0pt)
              move(dx: -pos-frac * excess,
                image(hero-image, width: w, height: 237mm))
            }
          )
        }


        // Bottom-right caption (geographic coords)
        #place(bottom + right, dx: -16mm, dy: -16mm)[
          #box(
            inset: (x: 8pt, y: 4pt),
            fill: _t.white.transparentize(50%),
            stroke: 0.5pt + _t.ink.transparentize(90%),
          )[
            #set align(right)
            #set par(leading: 0.4em)
            #text(
              font: _t.font-mono, size: 6.5pt, weight: _t.weight-medium, tracking: 0.20em,
              fill: _t.ink.transparentize(35%),
              [
                #upper(hero-caption-1) \
                #upper(hero-caption-2)
              ],
            )
          ]
        ]
      ],
    )
  ]

  // ---- 3. BOTTOM SLAB (50mm) - huge wordmark ----------------
  // Paper slab is transparent so the page texture runs through it as one
  // sheet; the dark slab keeps its own ink texture (tramas only — the
  // radials are composition-level and don't belong on a 50mm strip).
  block(
    width: 100%, height: 50mm,
    fill: if dark { _t.ink } else { none },
    stroke: (top: 0.5pt + _t.ink),
    inset: (x: 14mm, top: 0mm, bottom: 0mm),
  )[
    #if dark {
      place(top + left, dx: -14mm,
        chanwe-texture(210mm, 50mm, mode: "ink", radials: false))
    }
    #set align(center + horizon)
    #align(center + horizon, image(wordmark, height: 45mm, fit: "contain"))
  ]

  // ---- BLANK INTERSTITIAL PAGE ------------------------------
  set page(paper: _chanwe-paper, margin: 0pt, header: none, footer: none, fill: _t.paper,
    background: place(top + left, chanwe-texture(210mm, 297mm)), foreground: none)
  set block(spacing: 0pt)


  // full-height spacer keeps the page a full blank sheet
  block(width: 100%, height: 297mm)[]
}

// =============================================================
// BACK COVER — full-bleed black page
// =============================================================
// Campo de puntos de contratapa: trama pareja sobre obsidiana y un foco donde
// los mismos puntos se encienden. El foco se dibuja punto por punto — un
// tiling no se puede enmascarar con un degradado.// =============================================================
// chanwe-elements.typ — callouts, pull quotes, great quote pages
// Available to authors as #callout, #pullquote, #great-quote
// =============================================================

// La ficha de rótulo: marco slate, fondo transparente, mono en versalita. La
// llevan el tema del hallazgo y la procedencia del KPI, así que vive en un solo
// lugar —son el mismo objeto y no tienen por qué separarse con el tiempo—.
// `tone` pinta marco y texto del mismo color, para las superficies donde el
// slate del marco y el fg-muted del texto no se leen: border-cool sobre
// obsidiana, blanco sobre naranja.
#let _chip-label(body, tone: none, size: 5.2pt, inset: (x: 1.5mm, y: 1.2mm)) = box(
  stroke: 0.3pt + (if tone != none { tone } else { _t.border-cool }),
  radius: 0pt,
  inset: inset,
  text(font: _t.font-mono, size: size, weight: _t.weight-medium, tracking: 0.1em,
       fill: if tone != none { tone } else { _t.fg-muted }, upper(body)),
)

// Stubs for Quarto's font-awesome callout icon calls
#let fa-info() = []
#let fa-lightbulb() = []
#let fa-exclamation() = []
#let fa-exclamation-triangle() = []
#let fa-fire() = []

// Accepts both our API (#callout(kind: "note")[body]) and
// Quarto's generated API (#callout(body: [...], icon: fa-info(), ...))
#let callout(
  kind: "note",
  eyebrow: none,
  title: none,
  body: none,
  background_color: none,
  icon_color: none,
  icon: none,
  body_background_color: none,
  ..args,
) = {
  let content = if body != none { body } else if args.pos().len() > 0 { args.pos().first() } else { [] }

  // Derive accent color + type label from icon_color (Quarto native) or kind (our API)
  let (accent, auto-label) = if icon_color != none {
    let lbl = if icon_color == _t.callout-note      { "NOTE" }
         else if icon_color == _t.callout-tip       { "TIP" }
         else if icon_color == _t.callout-warning       { "WARNING" }
         else if icon_color == _t.callout-important       { "IMPORTANT" }
         else if icon_color == _t.callout-caution       { "CAUTION" }
         else                                       { "NOTE" }
    (icon_color, lbl)
  } else if kind == "warn" or kind == "warning" {
    (_t.callout-warning, "WARNING")
  } else if kind == "tip" {
    (_t.callout-tip, "TIP")
  } else if kind == "caution" {
    (_t.callout-caution, "CAUTION")
  } else if kind == "important" {
    (_t.callout-important, "IMPORTANT")
  } else if kind == "note" {
    (_t.callout-note, "NOTE")
  } else if kind == "do" {
    (_t.callout-do, "DO")
  } else if kind == "dont" {
    (_t.callout-dont, "DON'T")
  } else {
    (_t.primary, upper(kind))
  }

  let type-label = if eyebrow != none { upper(eyebrow) } else { auto-label }
  let display-title = if title != none { title } else { type-label }

  block(
    fill: _t.callout-surface,
    // Marco a canto vivo y más fino que el filete interno: el cuadro encierra
    // sin dibujarse, y la separación entre el rótulo y el cuerpo es lo que
    // pesa adentro.
    //
    // El tipo de aviso lo dice el canto izquierdo, no un punto: la barra vive
    // en el borde del cuadro, así que el color se lee de reojo sin meter un
    // objeto más adentro del rótulo.
    stroke: (left: 0.3mm + accent, rest: 0.3pt + _t.border-cool),
    // Esquinas a 4pt como el panel de código; `clip` recorta la banda del
    // rótulo a la misma curva.
    radius: 4pt,
    width: 100%,
    inset: 0pt,
    above: 10mm,
    below: 10mm,
    breakable: false,
    clip: true,
  )[
    // La banda del rótulo mide 28.6pt: un 15% menos que los 33.7pt de la
    // vuelta anterior, que ya eran un 15% menos que los 39.6pt originales.
    // El inset sale de esa cuenta —el título mide 6.5pt y el resto se reparte
    // arriba y abajo—, no de un número redondo, asi que si cambia el cuerpo
    // del título hay que volver a medir la banda y repartir la diferencia.
    #block(fill: _t.callout-header, inset: (x: 4.5mm, top: 3.89mm, bottom: 3.89mm), width: 100%, spacing: 0pt)[
      #grid(
        columns: (auto, 1fr),
        column-gutter: 5pt,
        align: left + horizon,
        text(font: _t.font-mono, size: 7pt, fill: _t.fg-subtle, "//"),
        // El rótulo en JetBrains Mono: es un renglón de servicio, no un
        // titular. Mismo peso que el resto de los rótulos mono del formato.
        text(font: _t.font-mono, size: 8pt, weight: _t.weight-medium, tracking: 0.12em, fill: _t.ink, upper(display-title)),
      )
    ]
    // Mismo grosor y mismo tono que el marco: un solo filete para todo el cuadro.
    #block(spacing: 0pt)[#line(length: 100%, stroke: 0.3pt + _t.border-cool)]
    #block(inset: (x: 4.5mm, y: 5mm), width: 100%, spacing: 0pt)[
      #set block(spacing: 0.85em)
      #set text(fill: _t.fg-muted, size: 9.5pt)
      #content
    ]
  ]
}

// La cita corta desde Typst crudo es la misma cita en bloque de markdown
// (`> …`): se emite como `quote` y la viste la regla `show quote` del
// formato —panel slate, canto naranja, Cormorant en cursiva y la atribución
// debajo—, así las dos salen idénticas. Antes tenía su propio panel sin
// fondo y la atribución en mono.
#let pullquote(body, attribution: none) = quote(
  block: true, attribution: attribution, body,
)

// `light` va sobre surface-slate (#EBF0F6), el mismo slate del abstract y
// de los paneles de código; `slate` y `beige` siguen valiendo como alias.
#let _gq-scheme(color, inset: false) = if color == "light" or color == "slate" or color == "beige" {
  (
    bg:     _t.surface-slate,
    eyebrow: _t.primary,
    quote:  _t.fg,
    emph:   _t.primary,
    attr:   _t.fg,
    source: _t.fg-subtle,
    line:   _t.primary,
  )
} else if color == "primary" {
  (
    // El naranja de marca, también en los insertos: el tono oscurecido que
    // usaban (primary-dark) se leía como otro naranja.
    bg:     _t.primary,
    eyebrow: _t.white,
    quote:  _t.white,
    emph:   _t.white,
    attr:   _t.white,
    source: _t.white.transparentize(30%),
    line:   _t.white,
  )
} else {
  (
    bg:     _t.ink,
    eyebrow: _t.primary,
    // Texto sobre obsidiana en rule-cool, no en blanco: la regla de la marca
    // para tipo sobre tinta.
    quote:  _t.rule-cool,
    emph:   _t.primary,
    attr:   _t.rule-cool,
    source: _t.rule-cool,
    line:   _t.primary,
  )
}

#let page-great-quote(caption: none, source: none, color: "dark", eyebrow: "Verbatim", body) = {
  let s = _gq-scheme(color)
  set page(paper: _chanwe-paper, margin: 0pt, header: none, footer: none, fill: s.bg)
  block(
    width: 100%, height: 100%,
    inset: (x: 22mm, top: 40mm, bottom: 30mm),
    fill: s.bg,
  )[
    #show emph: it => text(fill: s.emph, style: "italic", it.body)
    #chanwe-eyebrow(eyebrow, color: s.eyebrow, with-rule: true, size: 12pt)
    // Misma estructura que el inserto —5mm y la cita dentro de un bloque— para
    // que el aire entre rótulo y cita sea el mismo. Suelta en el flujo, la
    // cita a 28pt resolvía el espaciado de párrafo del cuerpo (2.6em) contra
    // sus propios 28pt y caía 26mm más abajo que en el inserto.
    #v(5mm)
    #set par(leading: 0.32em)
    #block(width: 100%)[
      // Un 15% más que la cita del inserto (28pt): a página completa la cita
      // tiene la hoja entera para respirar.
      #text(
        font: _t.font-serif, size: 32.2pt, style: "italic", weight: _t.weight-body,
        tracking: -0.025em, fill: s.quote,
      )[\u{201C}#body\u{201D}]
    ]
    #v(1fr)
    // El filete cierra siempre, con o sin firma. La firma pesa —tres veces
    // el cuerpo que tenía— y la fuente va en la ficha de marco, en blanco
    // sobre naranja y en el slate de obsidiana sobre tinta. Sin aire de
    // párrafo adentro: a 22pt el 2.6em del cuerpo metía dos centímetros
    // entre cada objeto.
    #set block(spacing: 0pt)
    #set par(spacing: 0pt)
    #line(length: 30%, stroke: 1pt + s.line)
    #if caption != none {
      v(6mm)
      // La firma en la familia de cuerpo, no en la de display: acompaña a la
      // cita en vez de titularla.
      text(font: _t.font-sans, size: 20.25pt, weight: _t.weight-body, tracking: -0.02em, fill: s.attr, caption)
    }
    #if source != none {
      let chip-tone = if color == "primary" { _t.white }
        else if color == "light" or color == "slate" or color == "beige" { none }
        else { _t.rule-cool }
      v(4.5mm)
      _chip-label(source, tone: chip-tone, size: 7.3pt, inset: (x: 2.5mm, y: 2mm))
    }
  ]
}

#let inset-great-quote(caption: none, source: none, color: "dark", eyebrow: "Verbatim", body) = {
  let s = _gq-scheme(color, inset: true)
  // La firma y el filete van en slate sobre papel; sobre obsidiana el slate no
  // se lee, así que ahí vuelven al blanco del esquema y al filete de tinta.
  let on-dark = color == "dark" or color == "primary"
  let on-primary = color == "primary"
  let attr-fill = if on-dark { s.attr } else { _t.fg-muted }
  // Sobre naranja, filete y ficha en blanco y el filete más fino: el slate de
  // obsidiana se leía como una raya negra sobre el naranja.
  let rule-fill = if on-primary { _t.white } else if on-dark { _t.rule-cool } else { _t.border-cool }
  let rule-w    = if on-primary { 0.2pt } else { 0.3pt }
  let chip-tone = if on-primary { _t.white } else if on-dark { _t.rule-cool } else { none }
  move(dx: -18mm,
    block(
      width: 210mm,
      fill: s.bg,
      inset: (x: 22mm, top: 12mm, bottom: 14mm),
    )[
      #show emph: it => text(fill: s.emph, style: "italic", it.body)
      #set par(leading: 0.32em)
      #chanwe-eyebrow(eyebrow, color: s.eyebrow, with-rule: true)
      #v(5mm)
      // La cita no usa los 166mm del bloque: a 122mm rompe en dos renglones
      // parejos y deja aire a la derecha, que es lo que la separa de un párrafo.
      #block(width: 122mm)[
        #text(
          font: _t.font-serif, size: 28pt, style: "italic", weight: _t.weight-body,
          tracking: -0.05em, fill: s.quote,
        )[\u{201C}#body\u{201D}]
      ]
      // El filete cierra siempre, con o sin firma: pertenece al bloque, no a
      // la atribución. Mucho aire arriba y poco abajo, así se lee como el
      // renglón que abre la firma. Los `v` van sin aire de bloque alrededor
      // —adentro del inserto el cuerpo trae 2.6em de espaciado de párrafo,
      // que se sumaba a cada uno.
      #set block(spacing: 0pt)
      #set par(spacing: 0pt)
      #v(16mm)
      #line(length: 100%, stroke: rule-w + rule-fill)
      #if caption != none or source != none {
        v(3.5mm)
        // La ficha de fuente abre la firma y va al eje del texto: una grilla
        // con `horizon` en vez de la corrección de base medida a mano.
        grid(
          columns: (auto, auto),
          column-gutter: 3mm,
          align: (left + horizon, left + horizon),
          if source != none {
            _chip-label(source, tone: chip-tone, size: 7.15pt, inset: (x: 2mm, y: 1.8mm))
          } else { [] },
          if caption != none {
            text(font: _t.font-display, size: 9.6pt, weight: _t.weight-display, tracking: -0.05em, fill: attr-fill, caption)
          } else { [] },
        )
      }
    ]
  )
}

#let inset-great-figure(
  eyebrow: none,
  title: "",
  source: none,
  source-label: none,
  layout: "center",
  position: "right",
  color: "dark",
  caption: [],
  body,
) = {
  let s = _gq-scheme(color, inset: true)
  let on-dark = color == "dark" or color == "primary"
  let col-widths = if layout == "left" {
    (3fr, 7fr)
  } else if layout == "right" {
    (7fr, 3fr)
  } else {
    (1fr, 1fr)
  }

  let text-col = block(width: 100%)[
    #if eyebrow != none {
      block(below: 8mm)[
        // Un 20% por debajo del rótulo estándar (8.5pt): acompaña al titular
        // de 14pt en vez de competir con él.
        #chanwe-eyebrow(eyebrow, color: s.eyebrow, with-rule: true, size: 6.8pt)
      ]
    }
    #if title != "" {
      block(below: 5mm, above: if eyebrow != none { 8mm } else { 0mm })[
        #set par(leading: 0.64em)
        #text(font: _t.font-display, size: 14pt, weight: _t.weight-display,
              tracking: -0.05em, fill: s.quote, title)
      ]
    }
    #set text(font: _t.font-sans, size: 7.5pt, fill: s.source)
    #caption
  ]

  // El pie de la figura repite el de una imagen del cuerpo: filete arriba, mono
  // chico en versalita y contra el margen izquierdo. Sobre obsidiana el filete
  // pasa a `rule-ink`, que es el que se dibuja sobre oscuro.
  let plot-col = block(width: 100%)[
    // Adentro del inserto la imagen no trae su propio marco: el pie del bloque
    // ya es el pie de la figura. Sin esto arrastraba los filetes, el rótulo y
    // los 26mm de aire del `show figure` del cuerpo —sobre obsidiana, tinta
    // sobre tinta: un rótulo invisible—, y el pie quedaba flotando lejos de la
    // imagen.
    #show figure.where(kind: image): it => it.body
    // Sin aire de bloque ni de párrafo adentro de la columna: el espaciado de
    // párrafo del cuerpo (2.6em) se sumaba debajo de la imagen y a cada `v`,
    // y el filete quedaba flotando a un centímetro del sello. Así la imagen
    // arranca arriba con el eyebrow y el pie va pegado, como en el marco.
    // El cuerpo además fija `show figure: set block(above: 11mm, below: 12mm)`
    // para las figuras corrientes, y esa regla sigue viva adentro de la
    // figura aunque aquí se dibuje sólo su cuerpo: hay que apagarla aparte.
    #show figure: set block(above: 0pt, below: 0pt)
    #set block(spacing: 0pt)
    #set par(spacing: 0pt)
    #body
    // El pie es el del marco de figura: filete slate, sello naranja a la
    // izquierda y la glosa contra el margen derecho. Sobre obsidiana el filete
    // pasa a `rule-ink`, que es el que se dibuja sobre oscuro.
    #if source != none or source-label != none {
      // Sobre naranja el filete va blanco y más fino, y el sello se invierte
      // —blanco con el texto en naranja—: naranja sobre naranja no existía.
      let on-primary = color == "primary"
      v(2.4mm)
      line(length: 100%, stroke: (if on-primary { 0.2pt } else { 0.3pt })
        + (if on-primary { _t.white } else if on-dark { _t.rule-ink } else { _t.border-cool }))
      v(1.6mm)
      grid(
        columns: (auto, 1fr),
        column-gutter: 7mm,
        align: (left + horizon, right + horizon),
        if source-label != none {
          box(
            fill: if on-primary { _t.white } else { _t.primary },
            inset: (x: 4mm, y: 1.6mm),
            text(font: _t.font-mono, size: 4.7pt, weight: _t.weight-display, tracking: 0.16em,
                 fill: if on-primary { _t.primary } else { _t.white }, upper(source-label)),
          )
        } else { [] },
        if source != none {
          text(font: _t.font-sans, size: 7.2pt, weight: _t.weight-body-plus,
               fill: if on-dark { s.source } else { _t.fg-muted }, source)
        } else { [] },
      )
    }
  ]

  let (first-col, second-col) = if position == "left" {
    (plot-col, text-col)
  } else {
    (text-col, plot-col)
  }

  move(dx: -18mm,
    block(
      width: 210mm,
      fill: s.bg,
      inset: (x: 22mm, top: 20mm, bottom: 20mm),
    )[
      #show emph: it => text(fill: s.emph, style: "italic", it.body)
      #grid(
        columns: col-widths,
        column-gutter: 14mm,
        align: (left + top, left + top),
        first-col,
        second-col,
      )
    ]
  )
}

#let inset-great-summary(
  eyebrow: "Executive Summary",
  title: "",
  color: "white",
  body,
) = {
  // Cuatro variantes: white (hoja), light (panel editorial), dark (obsidiana,
  // texto en rule-cool) y primary (naranja, texto en blanco).
  let s = if color == "dark" {
    (bg: _t.ink, eyebrow: _t.primary, title: _t.rule-cool, rule: _t.primary, body: _t.rule-cool)
  } else if color == "primary" {
    (bg: _t.primary, eyebrow: _t.white, title: _t.white, rule: _t.white, body: _t.white)
  } else if color == "light" or color == "slate" or color == "beige" {
    (bg: _t.surface-slate, eyebrow: _t.primary, title: _t.ink, rule: _t.primary, body: _t.body-fg)
  } else {
    (bg: _t.white, eyebrow: _t.primary, title: _t.ink, rule: _t.primary, body: _t.body-fg)
  }
  let borders = not ("white", "light", "slate", "beige", "dark", "primary").contains(color)
  move(dx: -18mm,
    block(
      width: 210mm,
      fill: s.bg,
      inset: (x: 22mm, top: 0pt, bottom: 0pt),
    )[
      #if borders { line(length: 100%, stroke: 0.5pt + _t.ink) }
      #block(width: 100%, inset: (top: 12mm, bottom: 14mm))[
        #grid(
          columns: (4fr, 6fr),
          column-gutter: 14mm,
          align: (left + top, left + top),
          text(
            font: _t.font-mono, size: 8.5pt, weight: _t.weight-medium,
            tracking: -0.05em, fill: s.eyebrow,
            "// " + upper(eyebrow),
          ),
          block(width: 100%)[
            #if title != "" {
              block(below: 7mm)[
                #set par(leading: 0.72em)
                #text(font: _t.font-display, tracking: -0.05em, size: 14pt, weight: _t.weight-display, fill: s.title, title)
              ]
              line(length: 18mm, stroke: 1pt + s.rule)
              v(4mm)
            }
            // Cuerpo en el slate de la prosa, no en el negro del titular.
            #set text(size: 10pt, fill: s.body)
            #set par(leading: 0.75em)
            #body
          ],
        )
      ]
      #if borders { line(length: 100%, stroke: 0.5pt + _t.ink) }
    ]
  )
}

// El hallazgo se reparte en cuatro franjas: el numeral suelto contra el margen,
// un filete naranja que abre la columna de texto, la glosa a medida corta, y el
// tema al otro extremo.
//
// Las columnas van en porcentaje del ancho disponible, no en milímetros: el
// reparto tiene que sobrevivir a que el bloque se dibuje dentro de un panel con
// sangría, y a que la fila con tema y la fila sin tema queden alineadas entre
// sí —con una columna `auto` a la derecha, un ítem sin tema ensancharía su
// texto y las dos filas dejarían de coincidir—.
#let _gf-columns = (8%, 60%, 1fr)
#let _gf-gutter  = (4%, 6%)
// Aire arriba y abajo de cada fila. Es la mitad de la separación entre filas,
// así que la divisoria queda centrada entre las dos.
#let _gf-pad-y   = 5mm

// La paleta de la lista por variante: `white` es la hoja con filetes, `light`
// el panel editorial, `dark` obsidiana con el texto en rule-cool y `primary`
// naranja con todo en blanco, incluidos el numeral y el filete.
#let _gf-scheme(color) = if color == "dark" {
  (bg: _t.ink, numeral: _t.primary, title: _t.rule-cool, body: _t.rule-cool,
   accent: _t.primary, rule: _t.rule-ink, label: _t.rule-cool.transparentize(35%), chip: _t.rule-cool)
} else if color == "primary" {
  (bg: _t.primary, numeral: _t.white, title: _t.white, body: _t.white.transparentize(12%),
   accent: _t.white, rule: _t.white.transparentize(60%), label: _t.white.transparentize(30%), chip: _t.white)
} else if color == "light" or color == "slate" or color == "beige" {
  (bg: _t.surface-slate, numeral: _t.primary, title: _t.ink, body: _t.fg-muted,
   accent: _t.primary, rule: _t.rule, label: _t.fg-subtle, chip: none)
} else {
  (bg: none, numeral: _t.primary, title: _t.ink, body: _t.fg-muted,
   accent: _t.primary, rule: _t.rule, label: _t.fg-subtle, chip: none)
}

// `height` fija el alto de la fila: la celda del texto —y con ella el filete
// naranja, que es su borde izquierdo— se estira hasta ahí. `auto` mide sola.
#let _great-findings-row(number: "01", title: "", topic: "", topic-label: "Tema", height: auto, scheme: _gf-scheme("white"), body) = {
  let s = scheme
  grid(
    columns: _gf-columns,
    rows: (height,),
    column-gutter: _gf-gutter,
    align: (left + top, left + top, right + top),

    // Instrument Serif trae un solo corte, 400: pedirle 300 se renderiza igual
    // pero miente sobre lo que pasa. El numeral no se alinea al título sino que
    // cuelga —con las dos celdas al borde de arriba, su propio cuerpo lo deja
    // caer casi hasta la base que pide el reparto—. El inset de arriba es lo
    // que falta: medido, no elegido, y hay que volver a medirlo si cambia el
    // cuerpo del numeral o el del título.
    grid.cell(inset: (top: 0.67mm), text(
      font: _t.font-serif-display, size: 27.5pt, weight: _t.weight-regular, style: "italic",
      fill: s.numeral, number,
    )),

    // El filete naranja es el borde izquierdo de la celda, no una línea aparte:
    // así mide exactamente el alto de la fila sin tener que calcularlo.
    grid.cell(stroke: (left: 0.5pt + s.accent), inset: (left: 4mm))[
      #block(below: 3.4mm)[
        #set par(leading: 0.45em)
        #text(font: _t.font-display, tracking: -0.05em, size: 10.8pt, weight: _t.weight-display, fill: s.title, title)
      ]
      // El interlineado se mide contra el renglón real, no contra el cuerpo: el
      // documento recorta el alto de línea a la altura de mayúscula, así que
      // `leading` arranca desde 0.72em y no desde 1.2em como haría el ajuste
      // por defecto. 0.95em deja los dos renglones a 1.67 cuerpos de distancia.
      #set text(size: 8pt, fill: s.body)
      #set par(leading: 0.95em)
      #body
    ],

    if topic != "" {
      align(right)[
        #set par(spacing: 0pt)
        #text(font: _t.font-mono, size: 5.2pt, weight: _t.weight-regular, tracking: 0.18em,
              fill: s.label, upper(topic-label))
        #v(1.6mm)
        #_chip-label(topic, tone: s.chip)
      ]
    } else { [] },
  )
}

// El marco de la lista: los filetes de cierre son los mismos que la divisoria
// entre ítems —mismo grosor, mismo tono—, así que la lista se lee como un
// pentagrama parejo y no como una banda con bordes pesados. `color` mantiene
// las variantes en panel para los documentos que ya las usan.
#let _gf-frame(color, body) = {
  let s = _gf-scheme(color)
  if s.bg == none {
    block(width: 100%, inset: 0pt, above: 10mm, below: 10mm,
      stroke: (top: 0.3pt + s.rule, bottom: 0.3pt + s.rule))[#body]
  } else {
    block(width: 100%, fill: s.bg, radius: 4pt, inset: (x: 6mm),
      above: 10mm, below: 10mm)[#body]
  }
}

#let great-findings(number: "01", title: "", topic: "", topic-label: "Tema", color: "white", body) = {
  _gf-frame(color, block(width: 100%, inset: (y: _gf-pad-y), spacing: 0pt)[
    #_great-findings-row(number: number, title: title, topic: topic, topic-label: topic-label, scheme: _gf-scheme(color), body)
  ])
}

// item used inside a great-findings-grid (the frame is the wrapper's job)
#let great-findings-item(number: "01", title: "", topic: "", topic-label: "Tema", height: auto, scheme: _gf-scheme("white"), body) = {
  block(width: 100%, inset: (y: _gf-pad-y), spacing: 0pt)[
    #_great-findings-row(number: number, title: title, topic: topic, topic-label: topic-label, height: height, scheme: scheme, body)
  ]
}

// La divisoria entre ítems. Va envuelta en un bloque sin espaciado porque una
// `line` suelta cobra el espaciado de bloque del cuerpo a cada lado, y eso era
// lo que abría el hueco muerto entre un hallazgo y el siguiente.
#let _gf-rule(s) = block(spacing: 0pt, line(length: 100%, stroke: 0.3pt + s.rule))
#let great-findings-rule = _gf-rule(_gf-scheme("white"))

// wrapper that frames the list and separates items with a hairline
// La lista recibe los ítems como lista de contenidos, no como un cuerpo
// suelto, para poder medirlos: todas las filas miden lo mismo —la más alta
// manda—, así una lista de tres hallazgos no cambia de ritmo porque uno lleve
// dos renglones más. `row-height` pone un piso en milímetros por si hace
// falta emparejar dos listas distintas. Un cuerpo de contenido suelto (la
// forma vieja) sigue valiendo: es una lista de un solo ítem.
#let great-findings-grid(color: "white", row-height: none, items) = {
  let items = if type(items) == array { items } else { (items,) }
  // Un ítem es un diccionario (number, title, topic, topic-label, body): así
  // se puede dibujar dos veces, una para medirlo y otra a la altura pareja,
  // y el filete naranja acompaña esa altura. Un contenido suelto (la forma
  // vieja) se envuelve en un bloque de alto fijo, sin estirar el filete.
  let s = _gf-scheme(color)
  let render(it, h) = if type(it) == dictionary {
    great-findings-item(
      number: it.at("number", default: "01"), title: it.at("title", default: ""),
      topic: it.at("topic", default: ""), topic-label: it.at("topic-label", default: "Tema"),
      height: h, scheme: s, it.at("body", default: []),
    )
  } else if h == auto { it } else {
    block(width: 100%, height: h + 2 * _gf-pad-y, spacing: 0pt, breakable: false, it)
  }
  _gf-frame(color, layout(size => {
    let floor = if row-height != none { row-height } else { 0pt }
    let h = calc.max(floor, ..items.map(it => measure(block(width: size.width, render(it, auto))).height))
    // La fila mide el bloque menos el aire de arriba y abajo.
    let row-h = h - 2 * _gf-pad-y
    for (i, it) in items.enumerate() {
      if i > 0 { _gf-rule(s) }
      render(it, row-h)
    }
  }))
}

// =============================================================
// KPI cards
// =============================================================

// "green"/"red" resolve to the canonical signed tokens so KPI cards, chart
// arrows, and table deltas share one positive/negative pair. Raw "#RRGGBB"
// strings pass through for self-describing swatches.
#let _kpi-color(name) = {
  if name == "primary" { _t.primary }
  else if name == "green" { _t.kpi-green }
  else if name == "red" { _t.kpi-red }
  else if name == "ink" { _t.ink }
  else if type(name) == str and name.starts-with("#") { rgb(name) }
  else { _t.fg-muted }
}

// El alto de la celda, su aire vertical y la canaleta entre columnas viven en
// constantes porque `kpi-grid` necesita las tres para dibujar las divisorias a
// la altura exacta de la banda: la ficha no las puede medir sola.
#let _kpi-card-h = 44mm
#let _kpi-pad-y  = 6.5mm
#let _kpi-gutter = 14mm
// Alto fijo de la fila ficha+glosa: entran dos renglones de glosa y la ficha
// queda centrada contra ellos sin moverse de columna a columna.
#let _kpi-chip-row-h = 7mm

// La sparkline del KPI. Recibe los valores en crudo y los normaliza sola, asi
// que la serie se escribe con los numeros del dato y no con fracciones.
//
// Solo la curva, la base y el punto del final: la trama de rayas verticales
// que llenaba el area bajo la curva se fue —ensuciaba mas de lo que decia.
#let _kpi-spark(values, height: 12mm) = {
  if values.len() < 2 { return }
  let lo = calc.min(..values)
  let hi = calc.max(..values)
  let mid = (hi + lo) / 2
  // Normalizar contra el rango propio de la serie convierte cualquier ruido en
  // una montaña rusa: reservas que se mueven 0,4 sobre 28 dibujarian el mismo
  // relieve que una inflacion que cae 2,7 sobre 4,8. El rango se ensancha
  // hasta un 15% del nivel, asi que una serie que casi no se mueve se dibuja
  // casi plana y el grafico dice lo que dice el dato.
  let floor-span = calc.abs(mid) * 0.15
  let raw-span = hi - lo
  let span = calc.max(raw-span, floor-span)
  // El 0.14/0.72 deja aire arriba y abajo: la curva no toca los bordes.
  let norm = values.map(v =>
    if span == 0 { 0.5 } else { 0.5 + 0.72 * (v - mid) / span })

  layout(size => {
    let n = values.len()
    // El area de dibujo se achica el radio del punto final, que si no queda
    // medio afuera de la celda.
    let pw = size.width - 3pt
    let step = pw / (n - 1)
    let y = i => height * (1 - norm.at(i))

    block(width: 100%, height: height, {
      // La curva.
      for i in range(n - 1) {
        place(top + left, dx: step * i, dy: y(i),
          line(end: (step, y(i + 1) - y(i)), stroke: 0.6pt + _t.ink))
      }
      place(bottom + left, line(length: 100%, stroke: 0.3pt + _t.border))
      // El punto del ultimo dato, con halo. `circle` mide 2r, asi que se corre
      // el radio para que el centro caiga sobre el dato.
      place(top + left, dx: step * (n - 1) - 2.6pt, dy: y(n - 1) - 2.6pt,
        circle(radius: 2.6pt, fill: _t.primary.transparentize(78%), stroke: none))
      place(top + left, dx: step * (n - 1) - 1.3pt, dy: y(n - 1) - 1.3pt,
        circle(radius: 1.3pt, fill: _t.primary, stroke: none))
    })
  })
}

#let kpi-card(
  title: "",
  main: "",
  prefix: "",
  unit: "",
  unit-note: "",
  source: "",
  main-color: "ink",
  secondary: "",
  secondary-color: "muted",
  direction: "none",
  delta: "",
  series: (),
  from-label: "",
  state-label: "",
  to-label: "",
) = {
  let mc = if main-color == "ink" { _t.fg } else { _kpi-color(main-color) }
  let dir-symbol = {
    if direction == "up" { "▲" }
    else if direction == "down" { "▼" }
    else if direction == "neutral" { "—" }
    else { "" }
  }
  // Un movimiento lleva la ficha en naranja; una lectura sin cambio la lleva
  // en slate. Naranja sigue siendo el unico acento: la direccion la dice el
  // glifo, no un verde contra un rojo.
  // La ficha sin movimiento va en el slate de los filetes, no en el de las
  // superficies: sobre una hoja slate, `surface-sunken` casi no se despegaba y
  // la ficha dejaba de leerse como ficha.
  let moving = direction == "up" or direction == "down"
  let chip-bg = if moving { _t.primary } else { _t.border-cool }
  let chip-fg = if moving { _t.paper } else { _t.fg }

  // Alto fijo: las tres celdas miden lo mismo pase lo que pase con el largo de
  // la glosa, asi las series quedan alineadas entre columnas y nada se
  // desborda por debajo del filete de cierre.
  block(width: 100%, height: _kpi-card-h)[
    #stack(dir: ttb, spacing: 0pt,
      // ── rotulo + procedencia ──────────────────────────────────
      // A tres columnas la fila entera entra en ~51mm, asi que el rotulo y el
      // sello van al cuerpo mas chico que los deja en un solo renglon.
      // Al eje y no a la base: la procedencia es una ficha con marco, así que
      // lo que tiene que coincidir con el rótulo es su centro, no su borde
      // de abajo.
      grid(
        columns: (auto, 1fr),
        align: (left + horizon, right + horizon),
        {
          text(font: _t.font-mono, size: 6.3pt, weight: _t.weight-bold, tracking: 0.1em,
               fill: _t.primary, "//")
          h(1.8mm)
          text(font: _t.font-mono, size: 6.3pt, weight: _t.weight-medium, tracking: -0.05em,
               fill: _t.fg, upper(title))
        },
        if source != "" { _chip-label(source) } else { [] },
      ),
      v(5.5mm),

      // ── la cifra ──────────────────────────────────────────────
      // El numeral y la unidad se alinean por la base; la aclaracion de la
      // unidad cuelga de la unidad, no del numeral.
      grid(
        columns: (auto, auto),
        column-gutter: 2mm,
        align: (left + bottom, left + bottom),
        {
          if prefix != "" {
            text(font: _t.font-display, size: 18pt, weight: _t.weight-display,
                 tracking: -0.05em, fill: mc, prefix)
            h(0.8mm)
          }
          text(font: _t.font-display, size: 36pt, weight: _t.weight-display,
               tracking: -0.05em, fill: mc, main)
        },
        block(spacing: 0pt)[
          #set par(spacing: 0pt, leading: 0pt)
          #if unit != "" {
            text(font: _t.font-display, size: 10.8pt, weight: _t.weight-display,
                 tracking: -0.05em, fill: mc, unit)
          }
          #if unit-note != "" {
            v(2.2mm)
            text(font: _t.font-mono, size: 5.4pt, weight: _t.weight-regular, tracking: 0.14em,
                 fill: _t.fg-subtle, upper(unit-note))
          }
        ],
      ),
      v(5mm),

      // ── ficha de variacion + glosa ────────────────────────────
      // La fila va a alto fijo y las dos celdas al eje: asi la glosa queda
      // centrada contra la ficha lleve uno o dos renglones, y la ficha cae a la
      // misma altura en las tres columnas. Centrar dentro de una fila de alto
      // automatico no alcanzaba: una glosa de dos renglones estiraba la fila y
      // bajaba la ficha, y las columnas dejaban de coincidir.
      block(width: 100%, height: _kpi-chip-row-h)[
        #grid(
          columns: (auto, 1fr),
          column-gutter: 3mm,
          align: (left + horizon, left + horizon),
          if delta != "" {
            box(fill: chip-bg, radius: 1pt, inset: (x: 2.6mm, y: 1.15mm),
              text(font: _t.font-mono, size: 5.9pt, weight: _t.weight-regular, tracking: 0.08em,
                   fill: chip-fg,
                   if dir-symbol != "" { dir-symbol + " " + delta } else { delta }))
          } else { [] },
          if secondary != "" {
            block(spacing: 0pt)[
              #set par(leading: 0.6em, spacing: 0pt)
              #text(font: _t.font-sans, size: 6.6pt, weight: _t.weight-body,
                    fill: _t.body-fg, secondary)
            ]
          } else { [] },
        )
      ],

      // ── serie ─────────────────────────────────────────────────
      v(1fr),
      if series.len() > 1 { _kpi-spark(series) } else { [] },
      if from-label != "" or state-label != "" or to-label != "" {
        v(2.6mm)
        grid(
          columns: (auto, 1fr, auto),
          align: (left + horizon, center + horizon, right + horizon),
          ..(from-label, state-label, to-label).map(l =>
            text(font: _t.font-mono, size: 4.4pt, weight: _t.weight-regular, tracking: 0.16em,
                 fill: _t.fg-subtle, upper(l))),
        )
      } else { [] },
    )
  ]
}

// La grilla de KPIs no son tarjetas sino una banda: cuatro filetes del mismo
// grosor y del mismo tono —dos cerrando arriba y abajo, y uno entre columna y
// columna—, así que la retícula se lee entera y no como un marco con tabiques.
//
// Las divisorias no se cuelgan de la celda sino que se dibujan en el medio de
// la canaleta: si se pusieran como borde izquierdo, la primera columna seria
// la unica sin sangria y quedaria 7mm mas ancha que las demas —una serie
// visiblemente mas larga que las otras dos—. Asi las tres columnas miden lo
// mismo y la primera sigue alineada al margen del texto, como el cuerpo.
#let kpi-grid(cols: 4, rows: auto, items) = {
  let nrows = calc.ceil(items.len() / cols)
  let band-h = (_kpi-card-h + 2 * _kpi-pad-y) * nrows
  layout(size => {
    let cw = (size.width - _kpi-gutter * (cols - 1)) / cols
    block(
      width: 100%,
      above: 11mm, below: 12mm,
      inset: 0pt,
      stroke: (top: 0.5pt + _t.border, bottom: 0.5pt + _t.border),
    )[
      #for i in range(1, cols) {
        place(top + left,
          dx: (cw + _kpi-gutter) * i - _kpi-gutter / 2,
          line(end: (0mm, band-h), stroke: 0.5pt + _t.border))
      }
      #grid(
        columns: range(cols).map(_ => 1fr),
        rows: if rows == auto { auto } else { range(rows).map(_ => auto) },
        column-gutter: _kpi-gutter,
        row-gutter: 0mm,
        ..items.map(it => grid.cell(inset: (y: _kpi-pad-y), it)),
      )
    ]
  })
}

// =============================================================
// ZONE HIGHLIGHT — full-bleed background color zone
// =============================================================
// color: "light" (por defecto) | "white" | "dark" | "primary"
// ("slate"/"beige" valen por light, "orange" por primary y "metallic", que
// era la hoja misma, ahora cae en light).
// `margin` es el aire adentro del panel, arriba y abajo del texto: a 2mm el
// cuerpo tocaba el borde de la banda. Se mide contra el ancho de la columna,
// no contra el cuerpo del texto, así que no cambia con `body-size`.
#let zone-highlight(color: "light", margin: 8mm, above: 3mm, below: 3mm, col-gutter: 14mm, ..bodies) = {
  // La zona `light` va un paso más abajo que los demás paneles light
  // (surface-slate en vez del beige): corre dentro del cuerpo y sobre la
  // hoja necesita un poco más de contraste para leerse como banda.
  let bg = if color == "light" or color == "slate" or color == "beige" or color == "metallic" { _t.surface-slate }
    else if color == "dark"              { _t.ink         }
    else if color == "primary" or color == "orange" { _t.primary }
    else if color.starts-with("#")       { rgb(color)     }
    else                                 { _t.white          }
  let on-dark = color == "dark" or color == "primary" or color == "orange"
  // Sobre obsidiana el texto va en rule-cool, como en todo el formato; sobre
  // naranja, en blanco.
  let on-color = if color == "dark" { _t.rule-cool } else { _t.white }

  if above != none { v(above) }
  move(dx: -18mm,
    block(
      width: 210mm,
      fill: bg,
      inset: (x: 22mm, top: margin, bottom: margin),
      spacing: 0pt,
    )[
      // Un `set` adentro de un `if` no llega a ninguna parte: el bloque del
      // `if` termina en esa misma línea y la regla muere con él. La forma que
      // sí aplica es `set ... if`. Y `strong` necesita su propia regla porque
      // el cuerpo del documento lo fija en `body-fg` pase lo que pase, así que
      // sobre obsidiana o naranja la negrita seguía siendo slate.
      #set text(fill: on-color) if on-dark
      #show strong: it => text(
        weight: _t.weight-display,
        fill: if on-dark { on-color } else { _t.body-fg },
        it.body,
      )
      #let parts = bodies.pos()
      #if parts.len() > 1 {
        grid(
          columns: range(parts.len()).map(_ => 1fr),
          column-gutter: col-gutter,
          align: left + top,
          ..parts,
        )
      } else if parts.len() == 1 {
        parts.first()
      }
    ]
  )
  if below != none { v(below) }
}

// =============================================================
// FIGURE FRAME — figure-local footer + alt-footer treatment
// top-left/top-right form the upper footer; bottom-left/bottom-right
// form the lower alt-footer. The body may contain a Markdown image,
// generated plot, table, or raw Typst figure.
// =============================================================
// Fila superior del marco: rótulo mono con filete naranja a la izquierda,
// glosa a la derecha, y el filete que cierra la fila. La comparten el marco
// de figura y las figuras nativas de Quarto (ver `chanwe-native-figure`).
#let _chanwe-frame-top(top-left, top-right) = {
  grid(
    columns: (5fr, 7fr),
    column-gutter: 7mm,
    align: (left + horizon, right + horizon),
    if top-left != none {
      grid(
        columns: (8mm, 1fr),
        column-gutter: 3mm,
        align: left + horizon,
        line(length: 8mm, stroke: 1.1pt + _t.primary),
        text(
          font: _t.font-mono,
          size: 6pt,
          weight: _t.weight-medium,
          tracking: 0.18em,
          fill: _t.ink,
          upper(top-left),
        ),
      )
    } else { [] },
    if top-right != none {
      align(right, text(
        font: _t.font-sans,
        size: 7.4pt,
        weight: _t.weight-body-plus,
        fill: _t.fg-muted,
        top-right,
      ))
    } else { [] },
  )
  v(1.6mm)
  line(length: 100%, stroke: 0.3pt + _t.border-cool)
  v(2.4mm)
}

// Fila inferior del marco: filete, sello naranja a la izquierda y glosa
// contra el margen derecho. El pie de la derecha va contra el margen, como
// el de arriba: los dos rótulos largos comparten el mismo canto y el sello
// queda solo a la izquierda.
#let _chanwe-frame-bottom(bottom-left, bottom-right) = {
  v(2.4mm)
  line(length: 100%, stroke: 0.3pt + _t.border-cool)
  v(1.6mm)
  grid(
    columns: (auto, 1fr),
    column-gutter: 7mm,
    align: (left + horizon, right + horizon),
    if bottom-left != none {
      box(
        fill: _t.primary,
        inset: (x: 4mm, y: 1.6mm),
        text(
          font: _t.font-mono,
          size: 4.7pt,
          weight: _t.weight-display,
          tracking: 0.16em,
          fill: _t.white,
          upper(bottom-left),
        ),
      )
    } else { [] },
    if bottom-right != none {
      text(
        font: _t.font-sans,
        size: 7.2pt,
        weight: _t.weight-body-plus,
        fill: _t.fg-muted,
        bottom-right,
      )
    } else { [] },
  )
}

#let chanwe-figure-frame(
  top-left: none,
  top-right: none,
  bottom-left: none,
  bottom-right: none,
  body,
) = {
  let has-top = top-left != none or top-right != none
  let has-bottom = bottom-left != none or bottom-right != none

  figure(
    block(
      width: 100%,
      breakable: false,
    )[
    #set block(spacing: 0pt)
    #if has-top { _chanwe-frame-top(top-left, top-right) }

    #block(width: 100%)[
      #show figure.where(kind: image): it => block(width: 100%)[#it.body]
      #show figure.where(kind: table): it => block(width: 100%)[#it.body]
      #show figure: it => block(width: 100%)[#it.body]
      #body
    ]

    #if has-bottom { _chanwe-frame-bottom(bottom-left, bottom-right) }
    ],
    kind: "chanwe-figure-frame",
    supplement: [Figure],
    numbering: "1",
  )
}

// Figura nativa de Quarto — `![pie](…){#fig-x}` o una tabla con
// `: pie {#tbl-x}` — vestida con el mismo marco que `.chanwe-figure-frame`:
// arriba el rótulo "FIGURA 1" / "TABLA 1" (el suplemento sigue a `lang`) con
// el pie como glosa, y abajo el sello de la serie de la publicación. La
// numeración y las referencias cruzadas (`@fig-x`) no cambian: el contador
// es el de Quarto. `it` es el `figure` de tipo `quarto-float-*`.
#let chanwe-native-figure(it, stamp: none) = block(
  width: 100%, breakable: false, above: 11mm, below: 12mm,
)[
  #set block(spacing: 0pt)
  #_chanwe-frame-top(
    upper(it.supplement) + " " + it.counter.display(),
    if it.caption != none { it.caption.body } else { none },
  )
  #block(width: 100%, it.body)
  #_chanwe-frame-bottom(stamp, none)
]

// El marco sin casilleros: un filete arriba y otro abajo, del mismo tono y
// grosor que el que abre el pie de página (`border`, 0.5pt), y adentro sólo
// el cuerpo de la figura. La regla del cuerpo para `figure` —filetes en
// tinta y pie en mono— no entra acá, igual que en `.chanwe-figure-frame`:
// antes se colaba y el marco salía con dos filetes de cada lado, uno slate y
// otro negro, más un pie numerado por el contador suelto de Typst.
#let fig-border(body) = {
  v(4mm, weak: true)
  block(breakable: false, width: 100%)[
    #set block(spacing: 0pt)
    #line(length: 100%, stroke: 0.5pt + _t.border)
    #block(width: 100%, inset: (y: 4mm))[
      #show figure: it => block(width: 100%, align(center, it.body))
      #body
    ]
    #line(length: 100%, stroke: 0.5pt + _t.border)
  ]
  v(4mm, weak: true)
}// =============================================================
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
  (bg: _t.white, eyebrow: _t.fg-subtle, title: _t.ink, body: _t.fg-muted,
   bar-primary: _t.primary, bar-light: _t.rule-cool, bar-dark: _t.ink)
} else {
  (bg: _t.surface-slate, eyebrow: _t.fg-subtle, title: _t.ink, body: _t.fg-muted,
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

#let _ch-cell(eyebrow, title, body, s, wide: false) = grid.cell(
  fill: s.bg,
  inset: if wide { (left: 5mm, right: 5mm, top: 3.4mm, bottom: 3.4mm) }
         else { (left: 4mm, right: 4mm, top: 3.4mm, bottom: 3.4mm) },
)[
  #set block(spacing: 0pt)
  #set par(leading: 0.68em, spacing: 0.7em)
  #if eyebrow != none {
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
#let card-highlight(eyebrow: none, title: none, accent: none, color: "light", body) = {
  let s = _ch-scheme(color)
  block(width: 100%, above: 5mm, below: 5mm, breakable: false, grid(
    columns: (_ch-bar-w, 1fr),
    column-gutter: 0mm,
    grid.cell(fill: _ch-bar(accent, s, none))[],
    _ch-cell(eyebrow, title, body, s, wide: true),
  ))
}

// El set: `items` es una tupla de diccionarios (eyebrow, title, accent,
// body). Cada tarjeta son dos celdas de la misma fila —barra y panel— y las
// celdas se estiran a la altura de la fila, así las tarjetas quedan parejas
// aunque una lleve dos líneas de bajada y otra cuatro. `cols` parte el set
// en filas; sin él, todas las tarjetas van en una.
#let card-highlight-set(color: "light", cols: none, items) = {
  let s = _ch-scheme(color)
  let n = if cols == none { items.len() } else { cols }
  let n = calc.max(1, calc.min(n, items.len()))
  block(width: 100%, above: 6mm, below: 6mm, grid(
    columns: range(n).map(_ => (_ch-bar-w, 1fr)).flatten(),
    column-gutter: range(2 * n - 1).map(j => if calc.rem(j, 2) == 0 { 0mm } else { 4mm }),
    row-gutter: 4mm,
    ..items.enumerate().map(((i, c)) => (
      grid.cell(fill: _ch-bar(c.at("accent", default: none), s, i))[],
      _ch-cell(c.at("eyebrow", default: none), c.at("title", default: none),
               c.at("body", default: []), s, wide: false),
    )).flatten(),
  ))
}// =============================================================
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
))// =============================================================
// chanwe-pages.typ — editorial pages 1:1 to HTML
// AGENDA · ABSTRACT · CHAPTER SEPARATOR · BACK COVER
// =============================================================

#let _pad2(n) = if n < 10 { "0" + str(n) } else { str(n) }

// Ancho de la columna del numeral en el indice. El titulo del H1 arranca
// aca, y el bloque de subniveles se sangra lo mismo para que el riel caiga
// justo debajo del titulo. Una sola constante para que no se separen.
//
// El numeral a 22pt mide ~5.5mm de glifo, asi que de estos 30mm quedan 24mm
// de aire entre el numero y el titulo: el doble del hueco anterior, que era
// de 12mm con la columna a 18mm. Si se cambia el cuerpo del numeral, el
// hueco se mueve con el —la constante fija la columna, no la separacion.
#let _toc-indent = 30mm

// La guia que lleva del subnivel al folio. Mismo filete que todas las
// divisiones del documento —encabezado, pie, cierre de capitulo—: `border` a
// 0.5pt. Antes iba en `rule-cool`, que al lado del cierre de capitulo se leia
// mas oscura.
#let _toc-leader = 0.5pt + _t.border

// El filete que cierra un capitulo: arranca donde arranca el titulo del H1 y
// llega hasta el folio. Va en el mismo `border` a 0.5pt que el resto de las
// divisiones del documento.
//
// Se dibuja *antes* del capitulo siguiente, no despues del propio: desde
// adentro del `outline` cada entrada se emite suelta y un subnivel no sabe si
// es el ultimo de su capitulo. Por eso el ultimo de todos lo pone
// `chanwe-agenda` a mano, despues del `outline`.
#let _toc-chapter-rule = block(spacing: 0pt,
  pad(left: _toc-indent, line(length: 100%, stroke: 0.5pt + _t.border)))

// El cuerpo del titulo de capitulo en el indice, y el de seccion derivado de
// el: cinco puntos por encima y un 15% mas (23.23pt). La relacion vive en el
// codigo para que mover uno mueva el otro.
#let _toc-h1-size      = 15.2pt
#let _toc-section-size = (_toc-h1-size + 5pt) * 1.15

// Todos los folios del indice —rango de la seccion, rango del capitulo y
// pagina del subnivel— comparten un solo estilo, el del capitulo. Un helper
// en vez de tres copias, para que no vuelvan a separarse. Sin `weight`: asi
// los tres heredan el mismo del cuerpo.
#let _toc-folio(body) = text(
  font: _t.font-mono, size: 7pt, tracking: 0.17em, fill: _t.fg-muted, body,
)

// ---------- AGENDA / TABLE OF CONTENTS -----------------------

// Recuento del documento para la losa del índice: secciones (las portadillas
// de `chanwe-chapter-divider`), capítulos (los H1) y páginas. Se cuenta solo,
// nadie lo escribe en el YAML. Va sobre obsidiana: el rótulo en `ink-subtle`
// (#646464, el gris hundido sobre tinta) y el número en `rule-cool`, que es
// la regla para texto sobre tinta.
#let _chanwe-agenda-counts() = context {
  let rows = (
    ("Secciones", query(<chanwe-part>).len()),
    ("Capítulos", query(heading.where(level: 1)).len()),
    ("Páginas",   counter(page).final().first()),
  )
  // Se omiten los renglones en cero: un documento sin portadillas no debería
  // anunciar "SECCIONES 00".
  let rows = rows.filter(((_, n)) => n > 0)
  if rows.len() == 0 { return }
  grid(
    columns: (auto, auto),
    column-gutter: 7mm,
    row-gutter: 4.2mm,
    align: (left + horizon, right + horizon),
    ..rows.map(((label, n)) => (
      text(font: _t.font-mono, size: 8.05pt, weight: _t.weight-regular, tracking: 0.18em,
           fill: _t.ink-subtle, upper(label)),
      text(font: _t.font-mono, size: 8.05pt, weight: _t.weight-body, tracking: 0.18em,
           fill: _t.rule-cool, _pad2(n)),
    )).flatten(),
  )
}
// Los renglones de subnivel cuelgan de un riel naranja continuo: cada uno
// dibuja su propio tramo y, al ir pegados (`spacing: 0pt` y el aire adentro
// del bloque), los tramos se sueldan en una sola línea. La guía lleva el ojo
// hasta el folio sin necesidad de un filete por renglón.
// La sangría va en un bloque exterior con `spacing: 0pt` y no en un `pad()`:
// el `pad` es un elemento de bloque propio y los renglones consecutivos se
// separaban con el espaciado de párrafo, que partía el riel en tramos.
#let chanwe-toc-subrow(num: "", label: "", page: "") = block(
  width: 100%,
  spacing: 0pt,
  inset: (left: _toc-indent),
)[
  #block(
  width: 100%,
  spacing: 0pt,
  stroke: (left: 1pt + _t.primary),
  inset: (left: 7mm, top: 3mm, bottom: 3mm),
)[
  #set par(spacing: 0pt, leading: 0pt)
  #grid(
    columns: (12mm, auto, 1fr, auto),
    column-gutter: 3mm,
    align: (left + horizon, left + horizon, center + horizon, right + horizon),
    text(font: _t.font-mono, size: 7.5pt, tracking: 0.1em, weight: _t.weight-regular, fill: _t.primary, num),
    // Mismo tono y peso que el texto corrido: el subnivel acompaña, no titula.
    text(font: _t.font-sans, size: 9.5pt, weight: _t.weight-body, fill: _t.body-fg, label),
    // La guía se dibuja en el hueco elástico, así que se estira sola.
    box(width: 100%, inset: (x: 3mm), line(length: 100%, stroke: _toc-leader)),
    _toc-folio(page),
  )
]
]

#let chanwe-toc-row(num: "", label: "", page: "", sub: false) = block(spacing: 0pt)[
  #set par(spacing: 0pt, leading: 0pt)
  #if sub {
    chanwe-toc-subrow(num: num, label: label, page: page)
  } else {
    grid(
      columns: (14mm, 1fr, 12mm),
      column-gutter: 4mm,
      align: (left + bottom, left + bottom, right + bottom),
      text(font: _t.font-mono, size: 7.5pt, tracking: 0.12em, weight: _t.weight-hairline, fill: _t.fg-muted, num),
      text(font: _t.font-mono, size: 7.5pt, weight: _t.weight-hairline, fill: _t.ink, label),
      text(font: _t.font-mono, size: 7.5pt, tracking: 0.14em, weight: _t.weight-hairline, fill: _t.fg-muted, page),
    )
  }
]

#let chanwe-toc-group(numeral: "01", title: "", pages: "", rows: ()) = {
  block(above: 0mm, below: 8mm)[
    // group head: giant italic numeral · title · page range
    #grid(
      columns: (20mm, 1fr, 30mm),
      column-gutter: 4mm,
      align: (left + bottom, left + bottom, right + bottom),
      text(
        font: _t.font-serif, style: "italic", weight: _t.weight-body,
        size: 28pt, tracking: -0.025em, fill: _t.primary,
        numeral,
      ),
      text(
        font: _t.font-display, size: 14pt, weight: _t.weight-display,
        tracking: -0.05em, fill: _t.fg, title,
      ),
      text(
        font: _t.font-mono, size: 8pt, tracking: 0.18em,
        fill: _t.fg-muted, upper(pages),
      ),
    )
    #v(2mm)
    #line(length: 100%, stroke: 0.5pt + _t.ink)
    // rows with explicit spacing and light gray separator after each
    #for (i, r) in rows.enumerate() {
      let is_sub = r.at("sub", default: false)
      v(if i == 0 { 0.1mm } else if is_sub { 0mm } else { 0.1mm })
      chanwe-toc-row(..r)
      v(0.1mm)
      line(length: 100%, stroke: 0.5pt + _t.border)
    }
  ]
}

#let chanwe-agenda(
  eyebrow: "Document map",
  title: "Agenda",
  lede: none,
  groups: none,
  parts: none,
) = {
  // El encabezado del índice repite la losa del H1: obsidiana de orilla a
  // orilla, pegada al filete del encabezado y con la misma trama de puntos.
  v(-4.5mm)
  context move(dx: -18mm, block(
    width: page.width,
    fill: _t.ink,
    inset: (left: 18mm, right: 18mm, top: 14mm, bottom: 16mm),
    clip: true,
  )[
    #place(top + left, dx: -18mm, dy: -14mm,
      _chanwe-dot-field(width: page.width, height: 140mm, ramp: (88%, 58%)))
    #chanwe-section-eyebrow(eyebrow)
    #v(7.5mm)
    // El titular a la izquierda y el recuento del documento a la derecha,
    // alineados por la base: la losa cuenta de qué está hecho el documento
    // sin que haya que escribirlo a mano.
    #grid(
      columns: (1fr, auto),
      align: (left + bottom, right + bottom),
      block(spacing: 0pt)[
        #text(
          font: _t.font-display, size: 72.8pt, weight: _t.weight-display,
          tracking: -0.05em, fill: _t.rule-cool, title,
        )
        #box(width: 13pt, height: 13pt, baseline: 0pt,
          circle(fill: _t.primary, stroke: none))
      ],
      block(spacing: 0pt, _chanwe-agenda-counts()),
    )
  ])
  v(12mm)

  if lede != none {
    v(15mm)
    block(width: 130mm)[
      #set par(leading: 0.55em)
      #set text(font: _t.font-sans, size: 10pt, weight: _t.weight-regular, fill: _t.fg-muted)
      #lede
    ]
  }

  v(14mm)

  if groups != none {
    // --- manual groups mode ---
    for g in groups { chanwe-toc-group(..g) }
  } else if parts != none {
    // --- simple parts list ---
    for part in parts {
      let (num, ptitle, desc, pg) = part
      grid(
        columns: (16mm, 1fr, 20mm),
        column-gutter: 5mm,
        align: (right + top, left + top, right + top),
        text(font: _t.font-serif-display, style: "italic", weight: _t.weight-body, size: 24pt, fill: _t.primary, num),
        {
          text(font: _t.font-display, size: 13pt, weight: _t.weight-display, tracking: -0.05em, fill: _t.fg, ptitle)
          linebreak()
          v(1.5mm)
          text(font: _t.font-sans, size: 9.5pt, fill: _t.fg-muted, desc)
        },
        text(font: _t.font-mono, size: 8pt, tracking: 0.12em, fill: _t.fg-muted, upper(pg)),
      )
      v(3mm)
      line(length: 100%, stroke: 0.5pt + _t.border)
      v(4mm)
    }
  } else {
    // --- AUTO mode: driven by outline() with independent counters ---
    // Part labels (from chanwe-chapter-divider) are injected between groups
    // without changing the H1 group-header hierarchy.
    // La agenda lista capítulos (H1) y secciones (H2). Los H3 quedan fuera:
    // son subdivisiones de lectura, no puntos de entrada del documento.
    let _h1 = counter("_chanwe-toc-h1")
    let _h2 = counter("_chanwe-toc-h2")

    show outline.entry: it => {
      if it.level == 1 {
        // Un capítulo sin numerar no avanza el contador: en lugar del "01"
        // lleva el filete corto que el cuerpo le pone a la losa.
        let numbered = it.element.numbering != none
        if numbered { _h1.step() }
        _h2.update(0)
        context {
          let n   = _h1.get().first()
          let pg  = counter(page).at(it.element.location()).first()
          let next_h1s = query(heading.where(level: 1).after(it.element.location(), inclusive: false))
          let end_pg = if next_h1s.len() > 0 {
            let np = counter(page).at(next_h1s.first().location()).first()
            if np > pg { np - 1 } else { pg }
          } else {
            counter(page).final().first()
          }
          let pages_str = if end_pg > pg {
            _pad2(pg) + " — " + _pad2(end_pg)
          } else { _pad2(pg) }
          let prev_h1s = query(heading.where(level: 1).before(it.element.location(), inclusive: false))
          let is-first = prev_h1s.len() == 0

          // Cierra el capitulo anterior antes de abrir este, incluso si el
          // que sigue abre una seccion nueva: el filete pertenece al capitulo
          // que termina, no al que empieza. Solo si ese capitulo no tuvo
          // subniveles: cuando los tuvo, el riel naranja de los renglones ya
          // lo cierra y el filete sobraba.
          if not is-first {
            let prev-loc = prev_h1s.last().location()
            let prev-had-sub = query(
              heading.where(level: 2)
                .after(prev-loc, inclusive: false)
                .before(it.element.location(), inclusive: false)
            ).len() > 0
            v(7mm)
            if not prev-had-sub { _toc-chapter-rule }
          }

          // Inject part label when a new chapter-divider section starts.
          // Filter by page number — avoids any selector.before() ambiguity.
          let h-loc   = it.element.location()
          let h-page  = counter(page).at(h-loc).first()
          let all-parts = query(<chanwe-part>)
          let cur-part = {
            let before = all-parts.filter(p => counter(page).at(p.location()).first() <= h-page)
            if before.len() > 0 { before.last().value } else { none }
          }

          let prev-part = if is-first { none } else {
            let ph = counter(page).at(prev_h1s.last().location()).first()
            let before = all-parts.filter(p => counter(page).at(p.location()).first() <= ph)
            if before.len() > 0 { before.last().value } else { none }
          }

          let cur-num  = if cur-part  != none { cur-part.number  } else { none }
          let prev-num = if prev-part != none { prev-part.number } else { none }

          if cur-part != none and cur-num != prev-num {
            // La banda de parte ya no lleva rectángulo de fondo: el renglón
            // se apoya en la columna de texto y cierra con un filete. La
            // jerarquía se la da el cuerpo del titular, no el filete: éste es
            // el mismo `border` a 0.5pt que usan el encabezado, el pie y el
            // cierre del titular del abstract.
            v(if is-first { 0mm } else { 14mm })
            block(width: 100%, spacing: 0pt)[
              #grid(
                // El numeral vive en la misma columna que el del capitulo, asi
                // que el titulo de la seccion arranca exactamente donde arranca
                // el del H1. Sin separacion en el primer hueco: la alineacion
                // la da el ancho de la columna, no el gutter.
                columns: (_toc-indent, auto, 1fr, auto),
                column-gutter: (0mm, 6mm, 6mm),
                align: (left + bottom, left + bottom, left + bottom, right + bottom),
                text(font: _t.font-serif-display, style: "italic", weight: _t.weight-body,
                     size: 42pt, fill: _t.primary, cur-part.number),
                {
                  // Misma familia y tracking que el H1 del índice, un paso más
                  // liviano (700 -> 600) y con más cuerpo: la sección pesa por
                  // tamaño, no por trazo. El numeral sigue en la serif
                  // itálica, que es lo que separa sección de capítulo.
                  text(font: _t.font-display, weight: _t.weight-display,
                       size: _toc-section-size, tracking: -0.05em,
                       fill: _t.fg, cur-part.title)
                  text(font: _t.font-display, weight: _t.weight-display,
                       size: _toc-section-size, tracking: -0.05em,
                       fill: _t.primary, ".")
                },
                [],
                {
                  // Rango de la parte: de esta portadilla hasta la anterior a
                  // la siguiente, o hasta el final si es la última.
                  let part-loc = all-parts.filter(p => p.value.number == cur-num).first().location()
                  let start-pg = counter(page).at(part-loc).first() + 1
                  let later = all-parts.filter(p =>
                    counter(page).at(p.location()).first() > counter(page).at(part-loc).first())
                  let end-pg = if later.len() > 0 {
                    counter(page).at(later.first().location()).first() - 1
                  } else {
                    counter(page).final().first()
                  }
                  let range = if end-pg > start-pg {
                    _pad2(start-pg) + " — " + _pad2(end-pg)
                  } else { _pad2(start-pg) }
                  _toc-folio(upper(range))
                },
              )
              // 4.8mm arriba y 2.7mm abajo, no 3.5 y 4: el filete queda
              // opticamente centrado entre los dos titulares. La asimetria
              // compensa el hueco que cada caja deja alrededor de su tinta
              // —debajo del titular de seccion entra el descendente de una
              // itálica a 38pt, y encima del H1 sobra el ascendente a 19.2pt—.
              // Medido sobre el PDF: 8.00mm de tinta a tinta de cada lado.
              #v(4.8mm)
              // Mismo filete que el resto del documento: encabezado, pie y el
              // que cierra el titular del abstract. Un solo tono y un solo
              // grosor para todas las divisiones.
              #line(length: 100%, stroke: 0.5pt + _t.border)
            ]
            // El capitulo que abre la seccion arranca pegado a su filete: el
            // bloque del H1 entra con `above: 0mm` y aporta 4mm propios, asi
            // que el aire total es este mas esos cuatro.
            v(2.7mm)
          }

          block(above: if cur-part != none and cur-num != prev-num { 0mm } else if is-first { 0mm } else { 12mm }, below: 0pt)[
            #v(4mm)
            #grid(
              // El folio se dimensiona solo, como el de la seccion: ahora
              // lleva rotulo delante y ya no entra en un ancho fijo.
              columns: (_toc-indent, 1fr, auto),
              column-gutter: 0mm,
              align: (left + bottom, left + bottom, right + bottom),
              if numbered {
                text(font: _t.font-serif-display, style: "italic", weight: _t.weight-body,
                     size: 22pt, fill: _t.primary, _pad2(n))
              } else {
                box(width: 22pt * 1.5, height: 0.5pt + 22pt * 0.03, fill: _t.primary, baseline: -5pt)
              },
              // Un paso mas liviano que el H1 del cuerpo (800 -> 700): el
              // cuerpo ya le da la jerarquia sobre el subnivel.
              text(font: _t.font-display, size: _toc-h1-size, weight: _t.weight-display,
                   tracking: -0.05em, fill: _t.fg, it.body()),
              // Solo el rango, sin rotulo: el renglon ya dice que es.
              _toc-folio(upper(pages_str)),
            )
            #v(3mm)
          ]
        }
      } else if it.level == 2 {
        // Un H2 sin numerar no avanza el contador ni lleva numeral: en su
        // lugar va el mismo filete corto que el cuerpo le pone al titular.
        let numbered = it.element.numbering != none
        if numbered { _h2.step() }
        context {
          let h1n = _h1.get().first()
          let n   = _h2.get().first()
          let pg  = counter(page).at(it.element.location()).first()
          // Numeración relativa al capítulo: 2.1, 2.2 — no un contador suelto.
          // Sin filete por renglón: el riel naranja del subrenglón ya agrupa.
          // El aire va solo antes del primero, para que el riel salga entero.
          if n == 1 and numbered { v(3mm) }
          if n == 0 { v(3mm) }
          chanwe-toc-subrow(
            num: if numbered { str(h1n) + "." + str(n) }
                 else { box(width: 7mm, height: 0.75pt, fill: _t.primary, baseline: -2pt) },
            label: it.element.body,
            page: _pad2(pg),
          )
        }
      }
    }
    outline(title: none, depth: 2)
    // El cierre del ultimo capitulo. Adentro del `outline` no hay forma de
    // saber cual es, asi que se emite aca, ya fuera de el. Misma regla que
    // adentro: solo si el capitulo no tuvo subniveles.
    context {
      let h1s = query(heading.where(level: 1))
      if h1s.len() > 0 {
        let last-loc = h1s.last().location()
        let had-sub = query(heading.where(level: 2).after(last-loc, inclusive: false)).len() > 0
        if not had-sub {
          v(7mm)
          _toc-chapter-rule
        }
      }
    }
  }
}

// =============================================================
// ABSTRACT WITH DROP-CAP
// =============================================================
// HTML structure:
//   .abstract-wrap  (60mm side rail | 1fr body)
//     .abstract-side  (label-row × N, hairline border-right)
//     .abstract-body
//       h2 (Schibsted Grotesk 28pt 700)
//       p.lead   (Cormorant Garamond 12pt body, ::first-letter 56pt drop-cap)
//       p · p · ... (Cormorant Garamond 12pt body)
// =============================================================
// El rotulo va un paso mas claro que el valor (`fg-subtle`, el tono de toda
// la metadata) y el valor entra en el mismo chip contorneado que la portada
// usa para el taggy: filete de 0.5pt, radio 2pt, mono en versalitas. Es un
// `block` y no un `box` a proposito: asi un valor largo parte de linea dentro
// del chip en vez de desbordar el riel de 60mm.
#let chanwe-side-row(label: "", value: "", dark: false, accent: _t.primary) = {
  // Sobre la hoja: rótulo y texto del chip en el mismo fg-subtle, el marco
  // del chip en border-cool.
  let lc = if dark { _t.white.transparentize(62%) } else { _t.fg-subtle }
  let vc = if dark { _t.white                     } else { _t.fg-subtle }
  let pc = if dark { _t.white.transparentize(75%) } else { _t.border-cool }
  // El aire interior del chip vive en una constante porque el rotulo se
  // sangra lo mismo: asi el rotulo se alinea con el texto del chip y no con
  // el borde, y los dos se mueven juntos si cambia el inset.
  let pill-pad = (x: 4mm, y: 2.2mm)
  let chip-text(t) = text(font: _t.font-mono, size: 6.75pt, weight: _t.weight-regular,
                          tracking: 0.18em, fill: vc, upper(t))
  // Todos los chips del riel miden lo mismo: el ancho del riel. Un valor suelto
  // parte de linea adentro del chip en vez de desbordar, y una lista —los
  // keywords— apila un chip por item en vez de dejarlos fluir con el ancho de
  // su texto, que era lo unico que rompia la columna.
  let pill(t) = block(width: 100%, stroke: 0.5pt + pc, radius: 2pt,
                      inset: pill-pad, chip-text(t))
  let values = if type(value) == array {
    stack(dir: ttb, spacing: 4pt, ..value.map(pill))
  } else {
    pill(value)
  }
  stack(dir: ttb, spacing: 8pt,
    // El punto bermellon vive en la canaleta que deja la sangria del rotulo,
    // asi que queda alineado con el borde del chip mientras el rotulo sigue
    // alineado con su texto.
    grid(
      columns: (pill-pad.x, auto),
      align: (left + horizon, left + horizon),
      circle(radius: 1.15pt, fill: accent, stroke: none),
      text(font: _t.font-mono, size: 7.5pt, weight: _t.weight-medium,
           tracking: 0.18em, fill: lc, upper(label)),
    ),
    values,
  )
}

#let chanwe-abstract(
  // new compact call style: eyebrow / title / meta
  eyebrow: none,
  title: none,
  meta: none,            // array of (label, value, sub) 3-tuples
  takeaway: none,
  dark: false,           // true → inverted text colors for dark backgrounds
  accent: _t.primary,    // the one accent: white on a primary page
  on-primary: false,
  // original verbose style kept for backward compat
  page-eyebrow: "01 · Abstract",
  page-title: "A reference, not a document.",
  side-rows: (),
  abstract-heading: "Abstract",
  lead: none,
  paragraphs: (),
  // captures optional trailing content block [...]
  ..args,
) = {
  let body = if args.pos().len() > 0 { args.pos().at(0) } else { none }
  // resolve aliases
  let resolved-eyebrow = if eyebrow != none { eyebrow } else { page-eyebrow }
  let resolved-title   = if title   != none { title   } else { page-title   }
  let resolved-rows    = if meta    != none {
    // El tercer campo de la tupla es un subtitulo opcional. Solo se concatena
    // si el valor es texto: los keywords llegan como lista y pasan enteros.
    meta.map(((lbl, val, ..rest)) => (
      label: lbl,
      value: if type(val) == str and rest.len() > 0 and rest.at(0) != none {
        val + "\n" + rest.at(0)
      } else { val },
    ))
  } else { side-rows }

  // color scheme shortcuts
  let title-color  = if dark { _t.white                     } else { _t.fg }
  // El filete vertical del riel de metadata es el unico acento de la pagina.
  let rail-stroke  = accent
  let body-color   = if dark { _t.white.transparentize(15%) } else { _t.fg-muted    }
  let takwy-color  = if dark { _t.white                     } else { _t.ink         }
  // Filete bajo el titular: sangra hasta el borde del papel y usa el mismo
  // tono y grosor que el filete que cierra el encabezado. Sobre tinta pasa al
  // filete de obsidiana, que ahi si se ve.
  let under-rule   = if on-primary { _t.white.transparentize(60%) } else if dark { _t.rule-ink } else { _t.border }

  v(10mm)
  chanwe-eyebrow(resolved-eyebrow, with-rule: true, color: accent)
  v(7.5mm)
  block[
    #text(
      font: _t.font-display, size: 56pt, weight: _t.weight-display,
      tracking: -0.05em, fill: title-color, resolved-title,
    )
    #box(width: 10pt, height: 10pt, baseline: 0pt,
      circle(fill: accent, stroke: none))
  ]
  v(13mm)
  // Mismo truco de sangrado que el encabezado: el margen lateral es 18mm, asi
  // que el filete se corre -18mm y mide 100% + 36mm para llegar a los bordes.
  block(spacing: 0pt,
    pad(x: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + under-rule)))
  v(14mm)

  // --- simple body layout when called with eyebrow/title/meta/body ---
  if body != none {
    grid(
      columns: (60mm, 1fr),
      column-gutter: 14mm,
      align: (left + top, left + top),
      // side rail: meta rows
      block(
        stroke: (right: 0.5pt + rail-stroke),
        inset: (right: 10mm),
        width: 100%,
      )[
        #stack(
          dir: ttb, spacing: 9mm,
          ..resolved-rows.map(r => chanwe-side-row(..r, dark: dark, accent: accent))
        )
      ],
      // body block
      block[
        #set par(leading: 0.65em, justify: true)
        #set text(font: _t.font-sans, size: 10pt, weight: _t.weight-regular, fill: body-color)
        #show emph: it => if dark { text(font: _t.font-serif, style: "italic", weight: _t.weight-body, size: 1.414em, fill: body-color, it.body) } else { it }
        #if takeaway != none {
          let s = str(takeaway)
          let parts = s.split(" ")
          let first-word = parts.at(0)
          let rest = if parts.len() > 1 { " " + parts.slice(1).join(" ") } else { "" }
          block(below: 6mm)[
            #text(font: _t.font-serif, size: 32pt, weight: _t.weight-body, style: "italic", fill: accent, first-word)#text(weight: _t.weight-bold, fill: takwy-color, rest)
          ]
        }
        #body
      ],
    )
    return
  }

  // --- original verbose layout ---
  grid(
    columns: (60mm, 1fr),
    column-gutter: 14mm,
    align: (left + top, left + top),
    // ---- side rail ----
    block(
      stroke: (right: 0.5pt + _t.border),
      inset: (right: 10mm),
      width: 100%,
    )[
      #stack(
        dir: ttb, spacing: 6mm,
        ..side-rows.map(r => chanwe-side-row(..r))
      )
    ],
    // ---- body with real drop-cap ----
    block[
      // h2 abstract heading
      #block(below: 4mm)[
        #text(font: _t.font-display, size: 28pt, weight: _t.weight-display,
              tracking: -0.05em, fill: _t.fg, abstract-heading)
      ]

      // Lead paragraph with manual drop-cap
      #if lead != none {
        let first = lead.at(0)
        let rest  = lead.slice(1)
        block(below: 4mm)[
          #place(top + left, dx: 0pt, dy: 8pt)[
            #text(
              font: _t.font-serif, size: 56pt, weight: _t.weight-body,
              fill: _t.fg, first,
            )
          ]
          #pad(left: 24mm)[
            #set par(leading: 0.62em, justify: true, first-line-indent: 0pt)
            #set text(font: _t.font-serif, size: 12pt, weight: _t.weight-body, fill: _t.fg)
            #text(weight: _t.weight-body, fill: _t.fg,
                  rest.slice(0, calc.min(rest.len(), 60)))
            #rest.slice(calc.min(rest.len(), 60))
          ]
        ]
      }

      // remaining paragraphs (no drop cap)
      #set par(leading: 0.62em, justify: true)
      #set text(font: _t.font-serif, size: 12pt, weight: _t.weight-body, fill: _t.fg)
      #for p in paragraphs {
        block(below: 4mm, p)
      }
    ],
  )
}

// =============================================================
// EXECUTIVE SUMMARY PAGE — same layout as the abstract page,
// callable inline from ::: {.chanwe-executive-summary ...} divs.
// Pulls meta-rows from doc state automatically.
// =============================================================
#let chanwe-exec-summary-page(
  eyebrow: "Executive Summary",
  title: none,
  takeaway: none,
  color: none,
  meta: none,
  body,
) = {
  // Sin color, la página va sobre surface-slate, como la del abstract, que
  // es la misma página con otro nombre.
  let bg = if color == "light" or color == "slate" or color == "beige" { _t.surface-slate }
      else if color == "dark"   { _t.ink          }
      else if color == "primary" { _t.primary     }
      else if color == "white"  { _t.white           }
      else                      { _t.surface-slate }
  let inverse = color == "dark" or color == "primary"
  let accent  = if color == "primary" { _t.white } else { _t.primary }
  pagebreak(weak: true)
  if bg != none {
    // Sobre obsidiana o naranja el encabezado y el pie se invierten.
    let inv = _chanwe-inverse-of(color)
    set page(fill: bg, header: chanwe-header-auto(inverse: inv), footer: chanwe-footer-auto(inverse: inv))
    context {
      let doc = _chanwe-doc.get()
      chanwe-abstract(
        eyebrow: eyebrow,
        title: title,
        meta: if meta != none { meta } else { doc.meta-rows },
        takeaway: takeaway,
        dark: inverse,
        accent: accent,
        on-primary: color == "primary",
        body,
      )
    }
  } else {
    context {
      let doc = _chanwe-doc.get()
      chanwe-abstract(
        eyebrow: eyebrow,
        title: title,
        meta: if meta != none { meta } else { doc.meta-rows },
        takeaway: takeaway,
        dark: inverse,
        accent: accent,
        on-primary: color == "primary",
        body,
      )
    }
  }
  pagebreak(weak: true)
}

// =============================================================
// DOUBLE EXECUTIVE SUMMARY — two summary halves filling one page
// =============================================================
// Each half = 140.5mm (= (297 - 8 top - 8 bottom) / 2).
// margin.top=8mm = header height, margin.bottom=8mm ≈ footer height → rules flush with content.
// Internal helper returns a block (no move wrapper — caller stacks both).
#let _chanwe-exec-half(
  eyebrow:          "Executive Summary",
  title:            none,
  takeaway:         none,
  meta:             (),
  // Status section
  status-label:     none,   // small eyebrow above hero word (e.g. "Convicción")
  status-hero:      none,   // large italic serif word (e.g. "Alza")
  status-kind:      none,   // "good" | "regular" | "bad" — determines color
  status-value:     none,   // 1–5: fills that many scale segments
  status-meta-label: "",    // single meta label shown right of hero word
  status-meta-value: "",    // single meta value shown right of hero word
  drivers:          (),     // max 3 × (dir, title, desc, tag, tag-color) tuples
  drivers-label:    "Factores Clave",  // eyebrow above the driver list
  color:            none,
  content:          [],
  divider:          false,
) = {
  let bg = if color == "light" or color == "slate" or color == "beige" { _t.surface-slate }
      else if color == "dark"   { _t.ink         }
      else if color == "primary" { _t.primary    }
      else if color == "white"  { _t.white          }
      else                      { _t.paper       }
  // Sobre obsidiana y sobre naranja el texto se invierte; sobre naranja el
  // acento pasa a blanco, porque el naranja ya es el fondo.
  let on-primary  = color == "primary"
  let dark        = color == "dark" or on-primary
  let accent      = if on-primary { _t.white } else { _t.primary }
  let title-color = if dark { _t.white                      } else { _t.fg }
  // El riel se separa con el mismo filete slate que las demás bandas; sobre
  // obsidiana, con el que se dibuja encima.
  let rail-stroke = if on-primary { _t.white.transparentize(60%) } else if dark { _t.rule-ink } else { _t.border-cool }
  let body-color  = if dark { _t.white.transparentize(15%)  } else { _t.fg-muted    }
  let takwy-color = if dark { _t.white                      } else { _t.ink         }
  // La divisoria entre las dos mitades es el mismo filete que cierra el
  // encabezado y abre el pie: `border` a 0.5pt, no el negro de la rampa.
  let div-stroke  = if divider { (bottom: 0.5pt + _t.border) } else { none }
  let lc          = if dark { _t.white.transparentize(45%) } else { _t.fg-subtle }
  let vc          = if dark { _t.white                     } else { _t.fg }
  let hair        = if on-primary { _t.white.transparentize(60%) } else if dark { _t.rule-ink } else { _t.rule }

  // El riel izquierdo se arma con las piezas de la tarjeta de KPI: el rótulo
  // con las dos barras naranjas y el nombre en mono, la ficha con marco slate
  // —o rellena de naranja cuando marca movimiento— y la cifra en display
  // pesado sobre obsidiana. Aquí la cifra es la palabra de estado.
  // La ficha es la de variación del KPI: naranja cuando hay movimiento y,
  // si no, rellena de slate —el de los filetes— con el texto en obsidiana.
  // Sobre obsidiana el relleno pasa a ink-soft.
  let chip(t, filled: false) = box(
    fill: if filled { accent } else if on-primary { _t.white.transparentize(80%) } else if dark { _t.ink-soft } else { _t.border-cool },
    radius: 1pt,
    inset: (x: 1.5mm, y: 1.2mm),
    text(font: _t.font-mono, size: 5.2pt, weight: _t.weight-regular, tracking: 0.1em,
         fill: if filled and on-primary { _t.primary } else if filled { _t.paper } else if dark { _t.white.transparentize(15%) } else { _t.fg },
         upper(str(t))),
  )
  let rail-label(t) = {
    text(font: _t.font-mono, size: 6.3pt, weight: _t.weight-display, tracking: 0.1em,
         fill: accent, "//")
    h(1.8mm)
    text(font: _t.font-mono, size: 6.3pt, weight: _t.weight-regular, tracking: 0.12em,
         fill: vc, upper(str(t)))
  }

  // Status color from kind — lo lleva la barra, no la palabra.
  let s-color = if status-kind == "good"    { _t.exec-status-good }
    else if status-kind == "regular"         { _t.exec-status-regular }
    else if status-kind == "bad"             { _t.exec-status-bad }
    else                                     { accent         }

  // 5-segment fill bar: first status-value segments colored, rest slate
  let filled = if status-value != none { status-value } else { 0 }
  let scale-bar = grid(
    columns: range(5).map(_ => 1fr),
    column-gutter: 1.5mm,
    ..range(5).map(i => {
      rect(width: 100%, height: 4pt, radius: 1pt,
           fill: if i < filled { s-color } else { rail-stroke })
    })
  )

  // Pre-compute left rail
  let left-rail = if status-hero != none or drivers.len() > 0 {
    [
      #set block(spacing: 0pt)
      #set par(spacing: 0pt)
      #if status-hero != none {
        if status-label != none {
          rail-label(status-label)
          v(4.5mm)
        }
        text(font: _t.font-display, size: 26pt, weight: _t.weight-display, tracking: -0.05em,
             fill: vc, str(status-hero))
        // El par de contexto va como la fila ficha + glosa del KPI: la
        // etiqueta en la ficha slate y el valor al lado, en sans chico. En la
        // cabecera no entraba: el riel mide 46mm y la ficha partía en dos.
        if status-meta-label != "" {
          v(2.5mm)
          grid(
            columns: (auto, 1fr),
            column-gutter: 2.5mm,
            align: (left + horizon, left + horizon),
            chip(status-meta-label),
            text(font: _t.font-sans, size: 6.6pt, weight: _t.weight-thin, fill: body-color,
                 str(status-meta-value)),
          )
        }
        v(3mm)
        scale-bar
        v(1.8mm)
        // El pie de la barra es el de la serie del KPI: mono chico, el tipo
        // de estado a la izquierda y el nivel sobre cinco a la derecha.
        grid(
          columns: (1fr, auto),
          align: (left + horizon, right + horizon),
          text(font: _t.font-mono, size: 5.85pt, weight: _t.weight-body, tracking: 0.16em,
               fill: lc, if status-kind != none { upper(str(status-kind)) } else { "" }),
          text(font: _t.font-mono, size: 5.85pt, weight: _t.weight-body, tracking: 0.16em,
               fill: lc, str(filled) + " / 5"),
        )
        if drivers.len() > 0 { v(7mm) }
      }
      #if drivers.len() > 0 {
        rail-label(drivers-label)
        v(5mm)
        line(length: 100%, stroke: 0.3pt + hair)
        // Cada driver es una fila entre filetes, como los hallazgos: la
        // dirección va en la ficha —naranja si se mueve, slate si no— y la
        // etiqueta en la ficha de marco, a la derecha.
        for drv in drivers.slice(0, calc.min(drivers.len(), 3)) {
          let (dir, dtitle, ddesc, dtag, dtag-k) = drv
          let moving  = dir == "up" or dir == "down"
          let dir-sym = if dir == "up" { "▲" } else if dir == "down" { "▼" } else { "—" }
          block(width: 100%, inset: (y: 4mm))[
            #grid(
              columns: (auto, 1fr, auto),
              column-gutter: 2.5mm,
              align: (left + top, left + top, right + top),
              chip(dir-sym, filled: moving),
              {
                text(font: _t.font-display, tracking: -0.05em, size: 7.5pt, weight: _t.weight-display, fill: vc, dtitle)
                if ddesc != "" {
                  v(1.6mm)
                  block(spacing: 0pt)[
                    #set par(leading: 0.35em)
                    #text(font: _t.font-sans, size: 6.5pt, weight: _t.weight-thin, fill: body-color, ddesc)
                  ]
                }
              },
              if dtag != "" {
                chip(dtag, filled: dtag-k == "primary" or dtag-k == "orange")
              } else { [] },
            )
          ]
          line(length: 100%, stroke: 0.3pt + hair)
        }
      }
    ]
  } else {
    [
      #stack(
        dir: ttb, spacing: 7mm,
        ..meta.map(((lbl, val, ..rest)) => chanwe-side-row(
          label: lbl,
          value: if rest.len() > 0 { val + "\n" + rest.at(0) } else { val },
          dark: dark, accent: accent,
        ))
      )
    ]
  }

  block(
    width: 210mm,
    height: 140.5mm,
    fill: bg,
    stroke: div-stroke,
    inset: (x: 18mm, top: 10mm, bottom: 10mm),
    clip: true,
  )[
    #chanwe-eyebrow(eyebrow, with-rule: true, color: accent)
    // `above: 0pt` en el bloque del titular: sin eso el espaciado de párrafo
    // del cuerpo (2.6em) se sumaba a los 6mm y el rótulo quedaba a 15mm.
    #v(5mm)
    #if title != none {
      block(above: 0pt, below: 0pt)[
        #set par(leading: 0.75em, justify: false)
        #text(
          font: _t.font-display, size: 36pt, weight: _t.weight-display,
          tracking: -0.05em, fill: title-color, title,
        )#box(width: 8pt, height: 8pt, baseline: -1pt,
          circle(fill: accent, stroke: none))
      ]
      v(10mm)
    }
    #grid(
      columns: (56mm, 1fr),
      column-gutter: 14mm,
      align: (left + top, left + top),
      // left rail — status + drivers or meta rows
      block(
        stroke: (right: 0.5pt + rail-stroke),
        inset: (right: 10mm),
        width: 100%,
      )[#left-rail],
      // right body — la misma columna que la página de abstract: palabra de
      // arranque en serif cursiva naranja a 32pt, resto en negrita, cuerpo en
      // sans a 10pt sobre fg-muted.
      block[
        #set par(leading: 0.65em, justify: true)
        #set text(font: _t.font-sans, size: 10pt, weight: _t.weight-regular, fill: body-color)
        // Sobre obsidiana o naranja la cursiva va en el color del cuerpo: la
        // regla global la pinta de naranja y sobre naranja desaparecía.
        #show emph: it => if dark { text(font: _t.font-serif, style: "italic", weight: _t.weight-body, size: 1.414em, fill: body-color, it.body) } else { it }
        #if takeaway != none {
          let s     = str(takeaway)
          let parts = s.split(" ")
          let fw    = parts.at(0)
          let rest  = if parts.len() > 1 { " " + parts.slice(1).join(" ") } else { "" }
          block(below: 6mm)[
            #set text(hyphenate: false)
            #text(font: _t.font-serif, size: 32pt, weight: _t.weight-body,
                  style: "italic", fill: accent, fw
            )#text(weight: _t.weight-bold, fill: takwy-color, rest)
          ]
        }
        #content
      ],
    )
  ]
}

// Public function — call with [top body][bottom body]
#let chanwe-double-exec-summary(
  // top half
  top-eyebrow:           "Executive Summary",
  top-title:             none,
  top-takeaway:          none,
  top-meta:              (),
  top-status-label:      none,
  top-status-hero:       none,
  top-status-kind:       none,
  top-status-value:      none,
  top-status-meta-label: "",
  top-status-meta-value: "",
  top-drivers:           (),
  top-drivers-label:     "Factores Clave",
  top-color:             none,
  // bottom half
  bot-eyebrow:           "Executive Summary",
  bot-title:             none,
  bot-takeaway:          none,
  bot-meta:              (),
  bot-status-label:      none,
  bot-status-hero:       none,
  bot-status-kind:       none,
  bot-status-value:      none,
  bot-status-meta-label: "",
  bot-status-meta-value: "",
  bot-drivers:           (),
  bot-drivers-label:     "Factores Clave",
  bot-color:             none,
  // two positional content blocks [top][bottom]
  ..bodies,
) = {
  let top-content = bodies.pos().at(0, default: [])
  let bot-content = bodies.pos().at(1, default: [])

  pagebreak(weak: true)

  // margin.top=8mm = header height, margin.bottom=8mm ≈ footer height → rules flush with content edges.
  // El encabezado cae sobre la mitad de arriba y el pie sobre la de abajo:
  // cada uno se invierte según el color de su mitad.
  set page(
    margin: (top: 8mm, bottom: 8mm, x: 18mm), header-ascent: 0pt, footer-descent: 0pt,
    header: chanwe-header-auto(inverse: _chanwe-inverse-of(top-color)),
    footer: chanwe-footer-auto(inverse: _chanwe-inverse-of(bot-color)),
  )

  // block(above/below: 0pt) prevents global body-spacing from leaking around the stack
  // without cascading into the exec-half content (unlike set block which would kill internal spacing).
  block(above: 0pt, below: 0pt, move(dx: -18mm,
    stack(
      dir: ttb,
      spacing: 0pt,
      _chanwe-exec-half(
        eyebrow: top-eyebrow, title: top-title,
        takeaway: top-takeaway, meta: top-meta,
        status-label: top-status-label, status-hero: top-status-hero,
        status-kind: top-status-kind, status-value: top-status-value,
        status-meta-label: top-status-meta-label,
        status-meta-value: top-status-meta-value,
        drivers: top-drivers, drivers-label: top-drivers-label,
        color: top-color, content: top-content,
        divider: true,
      ),
      _chanwe-exec-half(
        eyebrow: bot-eyebrow, title: bot-title,
        takeaway: bot-takeaway, meta: bot-meta,
        status-label: bot-status-label, status-hero: bot-status-hero,
        status-kind: bot-status-kind, status-value: bot-status-value,
        status-meta-label: bot-status-meta-label,
        status-meta-value: bot-status-meta-value,
        drivers: bot-drivers, drivers-label: bot-drivers-label,
        color: bot-color, content: bot-content,
        divider: false,
      ),
    )
  ))

  pagebreak(weak: true)
}

// =============================================================
// CHAPTER SEPARATOR (full-page divider)
// =============================================================
// HTML .chapter-cover layout:
//   - black background
//   - subtle gray radial halo (top-left, low opacity)
//   - .cc-top   : mark left, doc id right (mono micro-type, white/60)
//   - .cc-mid   : eyebrow + cc-num-row (giant 02 + title block)
//   - .cc-bottom: meta items + page number
// =============================================================
#let chanwe-chapter-divider(
  number: "02",
  eyebrow: "Part 02 · Worked Example",
  title: [Mendoza Wine — \ a sample report.],
  blurb: "A short consultancy brief assembled from every component on the previous pages. Real shape; illustrative numbers.",
  top-left-mark: none,
  top-right-mark: none,
  meta: none,
  page-counter: none,
) = {
  _chanwe-cur-part.update(_ => (number: number, title: title, eyebrow: eyebrow))

  // Mismo papel que una pagina de cuerpo (`page-bg`, que es `callout-surface`):
  // la portadilla se separa por su composicion, no por un tono distinto. El
  // halo radial cierra contra ese mismo color, asi que se mueven juntos.
  set page(
    paper: _chanwe-paper, margin: 0pt, fill: _t.callout-surface,
    header: none, footer: none,
    background: place(top + left, dx: -50mm, dy: -50mm,
      circle(radius: 145mm,
        fill: gradient.radial(
          _t.ink-fg.transparentize(90%),
          _t.callout-surface.transparentize(100%),
        ),
        stroke: none,
      )
    ),
  )
  set text(fill: _t.fg)

  context {
    let doc = _chanwe-doc.get()
    let _left  = if top-left-mark != none { top-left-mark } else { doc.doc-id }
    let _right = if top-right-mark != none { top-right-mark } else { doc.edition }
    let _meta  = if meta != none { meta } else {
      doc.meta-rows.slice(0, calc.min(3, doc.meta-rows.len())).map(((l, v, ..)) => (l, v))
    }
    let _pages = if page-counter != none { page-counter } else {
      str(counter(page).get().first()) + " / " + str(counter(page).final().first())
    }

  block(
    width: 100%, height: 100%,
    inset: (x: 18mm, top: 18mm, bottom: 18mm),
  )[
    // ---- TOP: la marca a la izquierda ----
    #block(width: 100%)[
      // Mismo tono que el encabezado y el pie del cuerpo.
      #set text(font: _t.font-mono, size: 7pt, tracking: 0.22em,
                fill: _t.fg-subtle)
      #upper(_chanwe-clean-str(doc.taggy))
      #h(3mm)
      #text(fill: _t.primary, "//")
      #h(3mm)
      #upper(_chanwe-clean-str(eyebrow))
    ]

    // ---- RIEL: la metadata gira y corre por el margen derecho, arrancando
    // a la misma altura que la marca ----
    #place(top + right,
      block(width: 8mm, height: 52mm)[
        #place(top + right, rotate(-90deg, origin: top + right,
          box(width: 52mm, align(right,
            text(font: _t.font-mono, size: 6.4pt, tracking: 0.22em,
                 fill: _t.fg-subtle, upper(_chanwe-clean-str(_right)))))))
      ])

    #v(1fr)

    // La línea que parte la hoja es un filete suave, no el trazo en tinta.
    #move(dx: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + _t.rule-cool))
    #v(14mm)

    // ---- MIDDLE: numeral gigante · filete · (título · bajada) ----
    #grid(
      columns: (auto, 1fr),
      column-gutter: 26mm,
      align: (left + top, left + top),
      // Numeral gigante, alineado por arriba con el bloque de título.
      text(
        font: _t.font-serif, style: "italic", weight: _t.weight-body,
        size: 220pt, tracking: -0.05em,
        fill: _t.primary,
        number,
      ),
      stack(
        dir: ttb, spacing: 9mm,
        // Misma familia y prosa que el H1: display, peso 700 y su tracking.
        // El numeral gigante se queda en la serif itálica.
        text(
          font: _t.font-display, weight: _t.weight-display,
          size: 51.75pt, tracking: -0.05em, fill: _t.fg,
          title,
        ),
        // La bajada va en el slate de marca, un escalón más fina.
        block(width: 78mm, text(
          font: _t.font-sans, size: 14pt, weight: _t.weight-thin,
          fill: _t.fg-muted,
          blurb,
        )),
      ),
    )

    #v(24.75mm)

    // ---- BOTTOM: doc-id · edition ----
    #move(dx: -18mm, line(length: 100% + 36mm, stroke: 0.5pt + _t.border))
    #v(3mm)
    #grid(
      columns: (1fr, auto),
      align: (left + horizon, right + horizon),
      {
        // Todo el pie en el mismo tono que el del cuerpo.
        set text(font: _t.font-mono, size: 8pt, tracking: 0.18em,
                 fill: _t.fg-subtle)
        upper(_chanwe-clean-str(doc.doc-id))
        if doc.edition != "" {
          h(14mm)
          upper(_chanwe-clean-str(doc.edition))
        }
      },
      text(font: _t.font-mono, size: 8pt, tracking: 0.18em,
           fill: _t.fg-subtle, upper(_pages)),
    )
  ]
  }
}

// =============================================================
// BACK COVER
// =============================================================
// HTML .back-cover layout:
//   - black bg + gray radial halo (centered)
//   - top: bc-mark (white wordmark)
//   - middle: italic 36pt tagline ("Less template, more report.")
//   - bc-rule (orange short bar)
//   - bc-grid (3 items: Studio · Web · Document)
//   - bc-arrow (small arrow logo)
//   - bc-bottom (legal · page num)
// =============================================================
#let chanwe-back-cover(
  wordmark-white: none,
  arrow-icon: none,
  tagline-line1: "Less template,",
  tagline-line2: "more report.",
  grid-items: (
    ("Studio",   "Chanwe — Estrategia Activa", "Mendoza · Argentina"),
    ("Web",      "chanwe.com.ar",              "contacto@chanwe.com.ar"),
    ("Document", "CHW-RPT-2026-04",            "Rev. A · 17·04·2026"),
  ),
  legal: "Información confidencial · Prohibida su distribución sin autorización",
  page-counter: "17 / 19",
) = {
  set page(
    paper: _chanwe-paper, margin: 0pt, fill: _t.ink,
    header: none, footer: none,
    background: place(center + horizon,
      circle(radius: 105mm,
        fill: gradient.radial(
          _t.white.transparentize(90%),
          _t.black.transparentize(100%),
        ),
        stroke: none,
      )
    ),
  )
  set text(fill: _t.white)

  block(
    width: 100%, height: 100%,
    inset: (x: 22mm, top: 22mm, bottom: 22mm),
  )[
    // ---- TOP: white wordmark ----
    #if wordmark-white != none {
      image(wordmark-white, height: 14mm)
    } else {
      text(font: _t.font-display, size: 28pt, weight: _t.weight-display, tracking: -0.05em,
           fill: _t.white, "chanwe")
    }

    #v(1fr)

    // ---- TAGLINE: italic 36pt, orange on second line ----
    #block[
      #set par(leading: 0.45em)
      #text(
        font: _t.font-serif, style: "italic", weight: _t.weight-body,
        size: 36pt, tracking: -0.025em, fill: _t.white,
        tagline-line1,
      )
      \
      #text(
        font: _t.font-serif, style: "italic", weight: _t.weight-body,
        size: 36pt, tracking: -0.025em, fill: _t.primary,
        tagline-line2,
      )
    ]

    #v(8mm)
    #line(length: 30mm, stroke: 1.5pt + _t.primary)
    #v(10mm)

    // ---- INFO GRID: 3 columns ----
    #grid(
      columns: (1fr, 1fr, 1fr),
      column-gutter: 8mm,
      ..grid-items.map(((label, val, sub)) => {
        stack(
          dir: ttb, spacing: 3mm,
          text(font: _t.font-mono, size: 7.5pt, weight: _t.weight-medium,
               tracking: -0.05em, fill: _t.white.transparentize(45%),
               upper(label)),
          stack(
            dir: ttb, spacing: 2pt,
            text(font: _t.font-display, tracking: -0.05em, size: 12pt, weight: _t.weight-display,
                 fill: _t.white, val),
            text(font: _t.font-sans, size: 9pt, weight: _t.weight-regular,
                 fill: _t.white.transparentize(35%), sub),
          ),
        )
      })
    )

    #v(1fr)

    // ---- ARROW ICON (small, left-aligned, above bottom) ----
    #if arrow-icon != none {
      image(arrow-icon, width: 14mm)
      v(4mm)
    }

    // ---- BOTTOM: legal + page num + hairline rule ----
    #line(length: 100%, stroke: 0.5pt + _t.white.transparentize(80%))
    #v(3mm)
    #grid(
      columns: (1fr, auto),
      align: (left + horizon, right + horizon),
      text(font: _t.font-mono, size: 7.5pt, weight: _t.weight-medium,
           tracking: 0.18em, fill: _t.white.transparentize(45%),
           upper(legal)),
      text(font: _t.font-mono, size: 7.5pt, weight: _t.weight-medium,
           tracking: 0.18em, fill: _t.white.transparentize(45%),
           upper(page-counter)),
    )
  ]
}// =============================================================
// chanwe-charts.typ — reusable data-viz primitives
// All components consume _t tokens — no hardcoded colors.
// =============================================================

// ---- BAR CHART ----------------------------------------------
// data: array of (label, value) tuples, value ∈ [0, 1]
// threshold: bars at or above this value get full opacity
// label-color: auto resolves to _t.fg-subtle
#let chanwe-bar-chart(
  data,
  height:      50mm,
  bar-width:   18mm,
  gap:         5mm,
  label-size:  7.5pt,
  label-color: auto,
  threshold:   0.7,
) = {
  let lc = if label-color == auto { _t.fg-subtle } else { label-color }
  align(center,
    stack(dir: ltr, spacing: gap,
      ..data.map(((lbl, val)) =>
        stack(dir: ttb, spacing: 2mm,
          rect(width: bar-width, height: height * (1 - val), fill: none, stroke: none),
          rect(
            width: bar-width,
            height: height * val,
            fill: _t.primary.transparentize(if val >= threshold { 10% } else { 45% }),
            stroke: none,
            radius: 1.5pt,
          ),
          align(center, text(size: label-size, fill: lc, lbl)),
        )
      ),
    )
  )
}

// ---- LINE CHART ---------------------------------------------
// series: array of (label, values-array) — all series same length
// x-labels: array of strings for x-axis ticks
#let chanwe-line-chart(
  series,
  x-labels:    (),
  width:       120mm,
  height:      60mm,
  label-size:  7pt,
  y-min:       0,
  y-max:       1,
  colors:      auto,
) = {
  // `meta.chart-palette-order` de brand.yml, en ese orden. La serie era
  // monocroma —un acento y tres grises—; ahora son los ocho matices de la
  // marca. `chart-red` va ultimo a proposito: esta a dE00 5.0 de `primary`,
  // asi que nada choca hasta que un grafico pide las ocho series. Para
  // volver a la version monocroma, pasar `colors:` a mano.
  let palette = if colors == auto {
    (_t.primary, _t.chart-blue, _t.chart-green, _t.chart-indigo,
     _t.chart-orange, _t.chart-teal, _t.chart-purple, _t.chart-red)
  } else { colors }
  let n = if series.len() > 0 { series.first().at(1).len() } else { 0 }
  if n == 0 { return [] }
  let x-step = if n > 1 { width / (n - 1) } else { width }
  let y-range = y-max - y-min

  // Sin cortar: el gráfico se dibuja con `place` dentro de un bloque de alto
  // fijo, así que partirlo no reparte el contenido —lo deja colgando fuera de
  // la caja de texto—. Si no entra, pasa entero a la página siguiente.
  block(width: width, height: height + 10mm, breakable: false)[
    #place(top + left,
      rect(width: width, height: height,
        fill: none, stroke: 0.5pt + _t.border)
    )
    #for (si, (name, vals)) in series.enumerate() {
      let col = palette.at(calc.rem(si, palette.len()))
      for i in range(vals.len() - 1) {
        let x1 = x-step * i
        let y1 = height * (1 - (vals.at(i) - y-min) / y-range)
        let x2 = x-step * (i + 1)
        let y2 = height * (1 - (vals.at(i + 1) - y-min) / y-range)
        place(top + left, dx: x1, dy: y1,
          line(end: (x2 - x1, y2 - y1), stroke: 1.5pt + col))
      }
    }
    #if x-labels.len() > 0 {
      place(bottom + left, dy: 8mm,
        stack(dir: ltr,
          ..x-labels.enumerate().map(((i, lbl)) =>
            move(dx: x-step * i,
              align(center, text(size: label-size, fill: _t.fg-subtle, lbl)))
          )
        )
      )
    }
  ]
}
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
#let brand-color = (
  background: rgb("#f8fafc"),
  body-fg: rgb("#475569"),
  border: rgb("#1113191a"),
  border-cool: rgb("#cfd6df"),
  callout-caution: rgb("#af52de"),
  callout-do: rgb("#34c759"),
  callout-dont: rgb("#ff3b30"),
  callout-header: rgb("#ebf0f6"),
  callout-important: rgb("#fd3810"),
  callout-note: rgb("#007aff"),
  callout-surface: rgb("#f8fafc"),
  callout-tip: rgb("#00c7be"),
  callout-warning: rgb("#ff9500"),
  chart-blue: rgb("#007aff"),
  chart-cyan: rgb("#11f7e6"),
  chart-cyan-soft: rgb("#b6fff8"),
  chart-gray: rgb("#71706c"),
  chart-green: rgb("#34c759"),
  chart-indigo: rgb("#5856d6"),
  chart-magenta: rgb("#eb03f2"),
  chart-orange: rgb("#ff9500"),
  chart-purple: rgb("#af52de"),
  chart-red: rgb("#ff3b30"),
  chart-teal: rgb("#00c7be"),
  code-comment: rgb("#928d86"),
  code-function: rgb("#475569"),
  code-keyword: rgb("#fd3810"),
  code-number: rgb("#7c3aed"),
  code-operator: rgb("#0758e5"),
  code-string: rgb("#15803d"),
  code-type: rgb("#353535"),
  danger: rgb("#d32f2f"),
  emphasis: rgb("#484848"),
  exec-status-bad: rgb("#cc1914"),
  exec-status-good: rgb("#15803d"),
  exec-status-regular: rgb("#d97706"),
  fg: rgb("#111319"),
  fg-muted: rgb("#475569"),
  fg-subtle: rgb("#8a94a6"),
  foreground: rgb("#475569"),
  info: rgb("#0c48ed"),
  ink: rgb("#111319"),
  ink-fg: rgb("#64748b"),
  ink-soft: rgb("#37393f"),
  ink-subtle: rgb("#646464"),
  kpi-green: rgb("#147705"),
  kpi-red: rgb("#cc1914"),
  neutral-300: rgb("#d4d4d4"),
  neutral-700: rgb("#525252"),
  paper: rgb("#f8fafc"),
  primary: rgb("#fd3810"),
  primary-active: rgb("#fd3810"),
  primary-text: rgb("#fd3810"),
  pure-black: rgb("#000000"),
  pure-white: rgb("#ffffff"),
  research-muted: rgb("#99999e"),
  rule: rgb("#e2e8f0"),
  rule-cool: rgb("#c6cdd6"),
  rule-ink: rgb("#434d5d"),
  secondary: rgb("#111319"),
  status-error: rgb("#d32f2f"),
  status-error-bg: rgb("#fdecea"),
  status-info: rgb("#0c48ed"),
  status-info-bg: rgb("#b8ceff"),
  status-success: rgb("#1eb508"),
  status-success-soft: rgb("#c9ffc0"),
  status-warning: rgb("#f9e710"),
  status-warning-bg: rgb("#fff8b8"),
  success: rgb("#1eb508"),
  surface-slate: rgb("#ebf0f6"),
  surface-sunken: rgb("#f1f5f9"),
  warning: rgb("#f9e710")
)
#let brand-color-background = (
  background: color.mix((brand-color.background, 15%), (brand-color.background, 85%)),
  body-fg: color.mix((brand-color.body-fg, 15%), (brand-color.background, 85%)),
  border: color.mix((brand-color.border, 15%), (brand-color.background, 85%)),
  border-cool: color.mix((brand-color.border-cool, 15%), (brand-color.background, 85%)),
  callout-caution: color.mix((brand-color.callout-caution, 15%), (brand-color.background, 85%)),
  callout-do: color.mix((brand-color.callout-do, 15%), (brand-color.background, 85%)),
  callout-dont: color.mix((brand-color.callout-dont, 15%), (brand-color.background, 85%)),
  callout-header: color.mix((brand-color.callout-header, 15%), (brand-color.background, 85%)),
  callout-important: color.mix((brand-color.callout-important, 15%), (brand-color.background, 85%)),
  callout-note: color.mix((brand-color.callout-note, 15%), (brand-color.background, 85%)),
  callout-surface: color.mix((brand-color.callout-surface, 15%), (brand-color.background, 85%)),
  callout-tip: color.mix((brand-color.callout-tip, 15%), (brand-color.background, 85%)),
  callout-warning: color.mix((brand-color.callout-warning, 15%), (brand-color.background, 85%)),
  chart-blue: color.mix((brand-color.chart-blue, 15%), (brand-color.background, 85%)),
  chart-cyan: color.mix((brand-color.chart-cyan, 15%), (brand-color.background, 85%)),
  chart-cyan-soft: color.mix((brand-color.chart-cyan-soft, 15%), (brand-color.background, 85%)),
  chart-gray: color.mix((brand-color.chart-gray, 15%), (brand-color.background, 85%)),
  chart-green: color.mix((brand-color.chart-green, 15%), (brand-color.background, 85%)),
  chart-indigo: color.mix((brand-color.chart-indigo, 15%), (brand-color.background, 85%)),
  chart-magenta: color.mix((brand-color.chart-magenta, 15%), (brand-color.background, 85%)),
  chart-orange: color.mix((brand-color.chart-orange, 15%), (brand-color.background, 85%)),
  chart-purple: color.mix((brand-color.chart-purple, 15%), (brand-color.background, 85%)),
  chart-red: color.mix((brand-color.chart-red, 15%), (brand-color.background, 85%)),
  chart-teal: color.mix((brand-color.chart-teal, 15%), (brand-color.background, 85%)),
  code-comment: color.mix((brand-color.code-comment, 15%), (brand-color.background, 85%)),
  code-function: color.mix((brand-color.code-function, 15%), (brand-color.background, 85%)),
  code-keyword: color.mix((brand-color.code-keyword, 15%), (brand-color.background, 85%)),
  code-number: color.mix((brand-color.code-number, 15%), (brand-color.background, 85%)),
  code-operator: color.mix((brand-color.code-operator, 15%), (brand-color.background, 85%)),
  code-string: color.mix((brand-color.code-string, 15%), (brand-color.background, 85%)),
  code-type: color.mix((brand-color.code-type, 15%), (brand-color.background, 85%)),
  danger: color.mix((brand-color.danger, 15%), (brand-color.background, 85%)),
  emphasis: color.mix((brand-color.emphasis, 15%), (brand-color.background, 85%)),
  exec-status-bad: color.mix((brand-color.exec-status-bad, 15%), (brand-color.background, 85%)),
  exec-status-good: color.mix((brand-color.exec-status-good, 15%), (brand-color.background, 85%)),
  exec-status-regular: color.mix((brand-color.exec-status-regular, 15%), (brand-color.background, 85%)),
  fg: color.mix((brand-color.fg, 15%), (brand-color.background, 85%)),
  fg-muted: color.mix((brand-color.fg-muted, 15%), (brand-color.background, 85%)),
  fg-subtle: color.mix((brand-color.fg-subtle, 15%), (brand-color.background, 85%)),
  foreground: color.mix((brand-color.foreground, 15%), (brand-color.background, 85%)),
  info: color.mix((brand-color.info, 15%), (brand-color.background, 85%)),
  ink: color.mix((brand-color.ink, 15%), (brand-color.background, 85%)),
  ink-fg: color.mix((brand-color.ink-fg, 15%), (brand-color.background, 85%)),
  ink-soft: color.mix((brand-color.ink-soft, 15%), (brand-color.background, 85%)),
  ink-subtle: color.mix((brand-color.ink-subtle, 15%), (brand-color.background, 85%)),
  kpi-green: color.mix((brand-color.kpi-green, 15%), (brand-color.background, 85%)),
  kpi-red: color.mix((brand-color.kpi-red, 15%), (brand-color.background, 85%)),
  neutral-300: color.mix((brand-color.neutral-300, 15%), (brand-color.background, 85%)),
  neutral-700: color.mix((brand-color.neutral-700, 15%), (brand-color.background, 85%)),
  paper: color.mix((brand-color.paper, 15%), (brand-color.background, 85%)),
  primary: color.mix((brand-color.primary, 15%), (brand-color.background, 85%)),
  primary-active: color.mix((brand-color.primary-active, 15%), (brand-color.background, 85%)),
  primary-text: color.mix((brand-color.primary-text, 15%), (brand-color.background, 85%)),
  pure-black: color.mix((brand-color.pure-black, 15%), (brand-color.background, 85%)),
  pure-white: color.mix((brand-color.pure-white, 15%), (brand-color.background, 85%)),
  research-muted: color.mix((brand-color.research-muted, 15%), (brand-color.background, 85%)),
  rule: color.mix((brand-color.rule, 15%), (brand-color.background, 85%)),
  rule-cool: color.mix((brand-color.rule-cool, 15%), (brand-color.background, 85%)),
  rule-ink: color.mix((brand-color.rule-ink, 15%), (brand-color.background, 85%)),
  secondary: color.mix((brand-color.secondary, 15%), (brand-color.background, 85%)),
  status-error: color.mix((brand-color.status-error, 15%), (brand-color.background, 85%)),
  status-error-bg: color.mix((brand-color.status-error-bg, 15%), (brand-color.background, 85%)),
  status-info: color.mix((brand-color.status-info, 15%), (brand-color.background, 85%)),
  status-info-bg: color.mix((brand-color.status-info-bg, 15%), (brand-color.background, 85%)),
  status-success: color.mix((brand-color.status-success, 15%), (brand-color.background, 85%)),
  status-success-soft: color.mix((brand-color.status-success-soft, 15%), (brand-color.background, 85%)),
  status-warning: color.mix((brand-color.status-warning, 15%), (brand-color.background, 85%)),
  status-warning-bg: color.mix((brand-color.status-warning-bg, 15%), (brand-color.background, 85%)),
  success: color.mix((brand-color.success, 15%), (brand-color.background, 85%)),
  surface-slate: color.mix((brand-color.surface-slate, 15%), (brand-color.background, 85%)),
  surface-sunken: color.mix((brand-color.surface-sunken, 15%), (brand-color.background, 85%)),
  warning: color.mix((brand-color.warning, 15%), (brand-color.background, 85%))
)
#set page(fill: brand-color.background)
#set text(fill: brand-color.foreground)
#set table.hline(stroke: (paint: brand-color.foreground))
#set line(stroke: (paint: brand-color.foreground))
#let brand-logo = (
  large: (
    path: "_extensions/chanwe-brand/assets/Logo_Negro.png"
  ),
  medium: (
    path: "_extensions/chanwe-brand/assets/Logo_Negro.png"
  ),
  small: (
    path: "_extensions/chanwe-brand/assets/Logo_Negro.png"
  )
)
#set text()
#set par(leading: 0.87em)
#show heading: set text(font: ("Schibsted Grotesk",), weight: 600, fill: rgb("#111319"), )
#show heading: set par(leading: 0.4em)
#show link: set text(weight: 500, fill: rgb("#fd3810"), )

#set page(
  paper: "a4",
  margin: (x: 18mm,y: 22mm,),
  numbering: "1",
  columns: 1,
)
#set page(background: align(left+top, box(inset: 0.75in, image("/_extensions/chanwe-brand/assets/Logo_Negro.png", width: 1.5in))))

// =============================================================
// typst-show.typ - Quarto metadata -> chanwe-report() template call
// =============================================================
// This is the bridge: Quarto fills chanwer Showcase, Every palette, scale, header treatment, surface, chart form and native Typst table pattern in the chanwer R package --- static output for chanwe-report-typst, etc. from
// the YAML front-matter of the .qmd file. Custom keys live under
// `chanwe:` and are mapped here.
// =============================================================

#show: doc => chanwe-report(
  title: [chanwer Showcase],
  subtitle: [Every palette, scale, header treatment, surface, chart form and native Typst table pattern in the chanwer R package --- static output for chanwe-report-typst],
  author: "Alejandro Abraham",
  date: "2026-09-26",
  doc-id: "CHW · DEV",
  edition: "SHOWCASE / 2026",
  volume: "MENDOZA · ARGENTINA",
  chapter: "Design System",
  section: "R Package",
  topic: "chanwer v2.3",
  rail-eyebrow: "VISUAL REFERENCE",
  hero-image: "\_extensions/chanwe-report/assets/bg\_mountains.jpg",
  hero-img-position: 10,
  cover: true,
  toc: true,
  toc-eyebrow: "Document map",
  toc-title: "Contents",
  toc-lede: [The complete static reference for chanwer: the brand color system and its validated palettes, the four scale jobs (categorical, ordinal, sequential, diverging), the signed system, every theme\_chanwe() header treatment and surface, the chart forms, and the full native-Typst table API --- all on the chanwe-report-typst tokens.],
  abstract-eyebrow: "TLDR;",
  abstract-title: [Static Reference],
  abstract-text: [This showcase covers every static output in the chanwer package: palette previews, categorical / ordinal / sequential / diverging scales, the signed positive-negative system with its KPI scoreboard, all header treatments (eyebrow, subtitle, note, KPI, title-only, no header line, compact and spacious), all four brand surfaces plus transparent, framed variants, the chart forms (scatter, bar, line, area, distribution, error bars, heatmap, facets), and every chanwe\_kbl() pattern --- surfaces, densities, totals, highlights, vertical rules, signed deltas, title-only and header-less tables. The interactive counterparts (gt, highcharter, reactable) live in chanwer-showcase-html.qmd.],
  abstract-status: "Stable · Internal",
  abstract-show: ("document", "edition", "author", "status"),
  abstract-takeaway: "One color system and one header grammar, mapped to every chart and table: the same tokens drive eyebrows, KPI arrows, table deltas, and this document.",
  meta-rows: (
    ("Package", "chanwer v2.3", "R design system"),
    ("Format", "chanwe-report-typst", "Quarto extension"),
    ("Author", "Chanwe", "Alejandro Abraham"),
  ),
  back-cover: true,
  back-cover-tagline-1: "Estrategia Activa,",
  back-cover-tagline-2: "Codo a codo.",
  back-cover-cols: (
    ("Web", "chanwe.com.ar", "contacto\@chanwe.com.ar"),
    ("Repo", "chanwe-ar/chanwer", "github.com"),
    ("Document", "CHW · DEV", "Showcase / 2026"),
  ),
  page-bg: rgb("#FBFBFB"),
  doc,
)

= The Color System
<the-color-system>
Every color in `chanwer` is a named token. `chanwe_palette()` returns the full inventory; `chanwe_palette("<group>")` returns one group; `chanwe_preview_palette("<group>")` draws its swatch grid. The values mirror `color.palette` in the chanwe-brand `brand.yml`.

#callout(kind: "note", eyebrow: "BRAND ROLES", title: "The manual assigns each family a job")[
Orange is the one accent, blue is structural, green is positive, red is
alert, ink is the neutral anchor. The scales below are built on those
roles --- positive/negative is never an arbitrary red/green pair.

]
== The categorical eight
<the-categorical-eight>
The slot order is `meta.chart-palette-order` from `brand.yml` --- primary orange, blue, green, indigo, orange, teal, purple, red --- the eight Apple-HIG-calibrated series hues, shared with the callouts. Red sits last: it is nearly the primary, so the two only meet in an eight-series chart.

#box(image("chanwer-showcase-pdf_files/figure-typst/preview-chart-1.png"))

== The signed trio
<the-signed-trio>
The brand's `kpi-green` and `kpi-red` with the slate `fg-muted` as neutral; each passes WCAG 4.5:1 small-text contrast on every brand surface.

#box(image("chanwer-showcase-pdf_files/figure-typst/preview-signed-1.png"))

== Semantic roles and family ramps
<semantic-roles-and-family-ramps>
#box(image("chanwer-showcase-pdf_files/figure-typst/preview-semantic-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/preview-teal-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/preview-mb-1.png"))

= Scales
<scales>
== Categorical
<categorical>
`scale_color_chanwe_d()` / `scale_fill_chanwe_d()` assign the chart palette in slot order, recycling past eight.

#box(image("chanwer-showcase-pdf_files/figure-typst/cat-scatter-1.png"))

#callout(kind: "warning", eyebrow: "SERIES CAP", title: "Scatter, bubble, and maps: three series maximum")[
In those forms any two marks can sit side by side, so the palette must
pass the stricter all-pairs check --- the first three slots do. Fold
extra series into "Other" or facet. Bars, lines, and stacks may use up
to six.

]
#box(image("chanwer-showcase-pdf_files/figure-typst/cat-bars-1.png"))

== Ordinal: one-hue ramp
<ordinal-one-hue-ramp>
When category order carries meaning, use a ramp group so the reader sees the order in the color: `scale_fill_chanwe_d(palette = "ramp_blue", reverse = TRUE)`.

#box(image("chanwer-showcase-pdf_files/figure-typst/ordinal-1.png"))

== Sequential
<sequential>
`scale_color_chanwe_c()` / `scale_fill_chanwe_c()` encode magnitude with one-hue, light-to-dark gradients built from the series hues: `orange` (default), `blue`, `indigo`, `teal`, `green`, `amber`, `red`, `purple`, plus `mustard` and `ink`.

#box(image("chanwer-showcase-pdf_files/figure-typst/seq-teal-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/seq-orange-1.png"))

== Diverging
<diverging>
`scale_fill_chanwe_div()` encodes polarity --- red through a neutral midpoint to green, signed tokens at the poles. Give it symmetric limits so zero lands on the midpoint.

#box(image("chanwer-showcase-pdf_files/figure-typst/div-heat-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/div-heat-cvd-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/div-bars-1.png"))

= The Signed System
<the-signed-system>
One pair everywhere: `chanwe_palette("signed")` drives the KPI arrows, table deltas and the diverging poles. `direction` states the movement (▲/▼); `valence` states whether that movement is good news and drives the color.

#kpi-grid(cols: 4, (
  kpi-card(
    title: "POSITIVE",
    main: "#147705",
    prefix: "",
    unit: "",
    unit-note: "",
    source: "",
    main-color: "#147705",
    secondary: "hue-true brand green",
    secondary-color: "muted",
    direction: "none",
    delta: "",
    series: (),
    from-label: "",
    state-label: "",
    to-label: "",
  ),
  kpi-card(
    title: "NEGATIVE",
    main: "#CC1914",
    prefix: "",
    unit: "",
    unit-note: "",
    source: "",
    main-color: "#CC1914",
    secondary: "hue-true vermillion",
    secondary-color: "muted",
    direction: "none",
    delta: "",
    series: (),
    from-label: "",
    state-label: "",
    to-label: "",
  ),
  kpi-card(
    title: "NEUTRAL",
    main: "#666666",
    prefix: "",
    unit: "",
    unit-note: "",
    source: "",
    main-color: "#666666",
    secondary: "brand ink-03",
    secondary-color: "muted",
    direction: "none",
    delta: "",
    series: (),
    from-label: "",
    state-label: "",
    to-label: "",
  ),
  kpi-card(
    title: "CONTRAST",
    main: "4.9+",
    prefix: "",
    unit: ":1",
    unit-note: "",
    source: "",
    main-color: "ink",
    secondary: "on all five surfaces",
    secondary-color: "muted",
    direction: "up",
    delta: "",
    series: (),
    from-label: "",
    state-label: "",
    to-label: "",
  )
))
== KPI scoreboard with valence
<kpi-scoreboard-with-valence>
#box(image("chanwer-showcase-pdf_files/figure-typst/kpi-valence-1.png"))

== Signed deltas in tables
<signed-deltas-in-tables>
`chanwe_col_signed()` colors by the column's #emph[raw] values; `flip` marks the smaller-is-better rows so color reads as valence, not sign.

#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: rgb("#F8FAFC"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F8FAFC"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr),
    align: (left, right, right, right,),
    table.header(
      table.cell(align: left, colspan: 4, inset: (top: 10pt, bottom: 3pt, x: 2.5mm), stroke: (top: 0.5pt + rgb("#CFD6DF")))[#v(4pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 4pt, color: rgb("#FD3810"))[SIGNED - TABLES]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold")[Quarterly performance]],
      table.cell(align: left, colspan: 4, inset: (top: 3pt, bottom: 10pt, x: 2.5mm))[#text(font: "Inter", size: 8pt, fill: _t.fg-muted, weight: "regular")[Signed deltas via chanwe\_col\_signed() - flip marks Opex and Churn so color reads as valence]#v(8pt, weak: false)],
      table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[METRIC]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[USD K]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[QOQ]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[YOY]],
    ),
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Revenue]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[1,240.5]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#147705"), weight: "thin")[+12.4%]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#147705"), weight: "thin")[+28.1%]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Gross margin]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[682.1]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#147705"), weight: "thin")[+4.2%]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#147705"), weight: "thin")[+9.6%]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[EBITDA]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[310.2]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#CC1914"), weight: "thin")[-3.1%]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#147705"), weight: "thin")[+11.2%]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Opex]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[-420.3]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#147705"), weight: "thin")[-1.9%]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#CC1914"), weight: "thin")[+6.3%]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Net income]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[185.7]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#147705"), weight: "thin")[+5.8%]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#CC1914"), weight: "thin")[-2.4%]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Churn]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[42.0]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#147705"), weight: "thin")[-0.8%]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#147705"), weight: "thin")[-4.1%]],
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.footer(
      table.cell(colspan: 4, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#box(fill: rgb("#FD3810"), inset: (x: 4mm, y: 1.6mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "medium", tracking: 0.16em, fill: rgb("#FFFFFF"))[#upper[Source: finance close, Q1 - simulated]]]],
    )
  )
  ]
}
]
]
= Header Treatments
<header-treatments>
The header grammar: mono-caps eyebrow with an orange rule, Schibsted Grotesk title at 1.85x base, Inter subtitle, optional note line or KPI scoreboard, and an orange stamp source caption.

===== Eyebrow · title · subtitle (default)
<eyebrow-title-subtitle-default>
#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-default-1.png"))

===== Subtitle with a note line
<subtitle-with-a-note-line>
#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-note-1.png"))

===== KPI scoreboard
<kpi-scoreboard>
#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-kpi-1.png"))

===== KPI only · no subtitle text
<kpi-only-no-subtitle-text>
#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-kpi-only-1.png"))

===== Title only · has\_subtitle = FALSE
<title-only-has_subtitle-false>
#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-title-only-1.png"))

===== Plain title · no eyebrow
<plain-title-no-eyebrow>
#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-plain-1.png"))

===== No title · no subtitle
<no-title-no-subtitle>
#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-none-1.png"))

== Header line and spacing
<header-line-and-spacing>
#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-line-spacious-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-line-compact-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-line-nosub-spacious-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-line-nosub-compact-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/hdr-compact-false-1.png"))

= Surfaces and Frames
<surfaces-and-frames>
`theme_chanwe()` exposes five named surfaces plus `"transparent"` and raw hex; grid colors adapt per surface.

===== paper · default
<paper-default>
#box(image("chanwer-showcase-pdf_files/figure-typst/bg-paper-1.png"))

===== white
<white>
#box(image("chanwer-showcase-pdf_files/figure-typst/bg-white-1.png"))

===== sunken
<sunken>
#box(image("chanwer-showcase-pdf_files/figure-typst/bg-sunken-1.png"))

===== slate
<slate>
#box(image("chanwer-showcase-pdf_files/figure-typst/bg-slate-1.png"))

===== white · padding 18
<white-padding-18>
#box(image("chanwer-showcase-pdf_files/figure-typst/bg-white-padding-1.png"))

===== transparent · zone-highlight
<transparent-zone-highlight>
#zone-highlight(color: "metallic", above: -2mm)[
#block[
#block[
#box(image("chanwer-showcase-pdf_files/figure-typst/bg-transparent-1.png"))

]
]
]
== Frames
<frames>
#box(image("chanwer-showcase-pdf_files/figure-typst/frame-true-1.png"))

#box(image("chanwer-showcase-pdf_files/figure-typst/frame-top-bottom-1.png"))

== Inset figure
<inset-figure>
#inset-great-figure(
  eyebrow: "FY 2025",
  title: "Revenue by Segment",
  color: "light",
  layout: "left",
  position: "right",
  source: "Data: FY 2025 — valores normalizados",
  caption: [
La categoría C presenta el valor más alto del conjunto. Los segmentos A
y E muestran rendimiento dentro del rango esperado, mientras que F
establece el piso de referencia para el análisis diferencial.

  ],
)[
#block[
#block[
#box(image("chanwer-showcase-pdf_files/figure-typst/inset-facets-1.png"))

]
]
]
= Chart Forms
<chart-forms>
===== Line · direct labels
<line-direct-labels>
#box(image("chanwer-showcase-pdf_files/figure-typst/form-line-1.png"))

===== Area
<area>
#box(image("chanwer-showcase-pdf_files/figure-typst/form-area-1.png"))

===== Distribution · density
<distribution-density>
#box(image("chanwer-showcase-pdf_files/figure-typst/form-density-1.png"))

===== Error bars · mean ± SD
<error-bars-mean-sd>
#box(image("chanwer-showcase-pdf_files/figure-typst/form-errorbar-1.png"))

===== Focus bar · value labels
<focus-bar-value-labels>
#box(image("chanwer-showcase-pdf_files/figure-typst/form-focus-1.png"))

===== Facets
<facets>
#box(image("chanwer-showcase-pdf_files/figure-typst/form-facets-1.png"))

= Typst Tables
<typst-tables>
`chanwe_kbl()` generates native Typst --- no HTML-to-PDF translation. Both densities, every surface, per-column formatting and coloring, stubs, totals, highlights and vertical rules.

== Surfaces
<surfaces>
===== paper · default
<paper-default-1>
#figure([
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: rgb("#F8FAFC"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F8FAFC"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 3pt, x: 2.5mm), stroke: (top: 0.5pt + rgb("#CFD6DF")))[#v(4pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 4pt, color: rgb("#FD3810"))[TABLE · SPACIOUS · PAPER]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold")[bg · paper]],
      table.cell(align: left, colspan: 5, inset: (top: 3pt, bottom: 10pt, x: 2.5mm))[#text(font: "Inter", size: 8pt, fill: _t.fg-muted, weight: "regular")[density · spacious]#v(8pt, weak: false)],
      table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MODEL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MPG]],
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[CYL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[HP]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[WT]],
    ),
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#box(fill: rgb("#FD3810"), inset: (x: 4mm, y: 1.6mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "medium", tracking: 0.16em, fill: rgb("#FFFFFF"))[#upper[Source · Motor Trend, 1974 · mtcars dataset.]]]],
    )
  )
  ]
}
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-paper>


===== white
<white-1>
#figure([
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: rgb("#FFFFFF"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#FFFFFF"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 3pt, x: 2.5mm), stroke: (top: 0.5pt + rgb("#CFD6DF")))[#v(4pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 4pt, color: rgb("#FD3810"))[TABLE · SPACIOUS · WHITE]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold")[bg · white]],
      table.cell(align: left, colspan: 5, inset: (top: 3pt, bottom: 10pt, x: 2.5mm))[#text(font: "Inter", size: 8pt, fill: _t.fg-muted, weight: "regular")[density · spacious]#v(8pt, weak: false)],
      table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MODEL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MPG]],
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[CYL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[HP]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[WT]],
    ),
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#box(fill: rgb("#FD3810"), inset: (x: 4mm, y: 1.6mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "medium", tracking: 0.16em, fill: rgb("#FFFFFF"))[#upper[Source · Motor Trend, 1974 · mtcars dataset.]]]],
    )
  )
  ]
}
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-white>


===== sunken · top\_border = FALSE
<sunken-top_border-false>
#figure([
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: rgb("#F1F5F9"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F1F5F9"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 3pt, x: 2.5mm))[#v(4pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 4pt, color: rgb("#FD3810"))[TABLE · SPACIOUS · SUNKEN]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold")[bg · sunken]],
      table.cell(align: left, colspan: 5, inset: (top: 3pt, bottom: 10pt, x: 2.5mm))[#text(font: "Inter", size: 8pt, fill: _t.fg-muted, weight: "regular")[top\_border = FALSE]#v(8pt, weak: false)],
      table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MODEL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MPG]],
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[CYL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[HP]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[WT]],
    ),
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#box(fill: rgb("#FD3810"), inset: (x: 4mm, y: 1.6mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "medium", tracking: 0.16em, fill: rgb("#FFFFFF"))[#upper[Source · Motor Trend, 1974 · mtcars dataset.]]]],
    )
  )
  ]
}
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-sunken>


===== slate · padding 0
<slate-padding-0>
#figure([
#block(above: 2.5em, below: 2.5em)[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#EBF0F6"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 3pt, x: 2.5mm))[#v(4pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 4pt, color: rgb("#FD3810"))[TABLE · SPACIOUS · SLATE]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold")[bg · slate]],
      table.cell(align: left, colspan: 5, inset: (top: 3pt, bottom: 10pt, x: 2.5mm))[#text(font: "Inter", size: 8pt, fill: _t.fg-muted, weight: "regular")[padding = 0  ·  top\_border = FALSE]#v(8pt, weak: false)],
      table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MODEL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MPG]],
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[CYL]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[HP]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[WT]],
    ),
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#box(fill: rgb("#FD3810"), inset: (x: 4mm, y: 1.6mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "medium", tracking: 0.16em, fill: rgb("#FFFFFF"))[#upper[Source · Motor Trend, 1974 · mtcars dataset.]]]],
    )
  )
  ]
}
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-slate>


== Densities and column widths
<densities-and-column-widths>
#figure([
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: rgb("#F8FAFC"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F8FAFC"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, right, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 3pt, x: 2.5mm), stroke: (top: 0.5pt + rgb("#CFD6DF")))[#v(4pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 4pt, color: rgb("#FD3810"))[TABLES - SPACIOUS]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold")[Fleet summary by cylinder count]],
      table.cell(align: left, colspan: 5, inset: (top: 3pt, bottom: 10pt, x: 2.5mm))[#text(font: "Inter", size: 8pt, fill: _t.fg-muted, weight: "regular")[Spacious density - the presentation default]#v(8pt, weak: false)],
      table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[CYLINDERS]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[AVG MPG]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[AVG HP]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[AVG WEIGHT]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[VEHICLES]],
    ),
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[26.7]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[83]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.29]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[11]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[19.7]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[122]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.12]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[7]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[15.1]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[209]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4.00]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14]],
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#box(fill: rgb("#FD3810"), inset: (x: 4mm, y: 1.6mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "medium", tracking: 0.16em, fill: rgb("#FFFFFF"))[#upper[Source: mtcars]]]],
    )
  )
  ]
}
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-spacious-summary>


#figure([
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: rgb("#EBF0F6"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 5pt), stroke: none, fill: rgb("#EBF0F6"))
  [
  #table(
    columns: (2.2fr, 1fr, 0.8fr, 1fr, 1.1fr, 1.6fr),
    align: (left, right, left, right, right, left,),
    table.header(
      table.cell(align: left, colspan: 6, inset: (top: 5pt, bottom: 3pt, x: 2.5mm), stroke: (top: 0.5pt + rgb("#CFD6DF")))[#v(2pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 4pt, color: rgb("#FD3810"))[TABLES - COMPACT]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold")[Vehicle detail]],
      table.cell(align: left, colspan: 6, inset: (top: 3pt, bottom: 5pt, x: 2.5mm))[#text(font: "Inter", size: 8pt, fill: _t.fg-muted, weight: "regular")[Compact density for dense reporting tables - explicit col\_widths]#v(4pt, weak: false)],
      table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
      table.cell(align: left, inset: (top: 14pt, bottom: 5pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MODEL]],
      table.cell(align: right, inset: (top: 14pt, bottom: 5pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MPG]],
      table.cell(align: left, inset: (top: 14pt, bottom: 5pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[CYL]],
      table.cell(align: right, inset: (top: 14pt, bottom: 5pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[HP]],
      table.cell(align: right, inset: (top: 14pt, bottom: 5pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[WEIGHT]],
      table.cell(align: left, inset: (top: 14pt, bottom: 5pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[TRANSMISSION]],
    ),
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.0]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[Manual]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.0]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[Manual]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.8]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[Manual]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.4]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[Automatic]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.7]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[Automatic]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.1]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[Automatic]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.3]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[Automatic]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.4]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[Automatic]],
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.footer(
      table.cell(colspan: 6, align: left, inset: (top: 9pt, bottom: 5pt, x: 2.5mm))[#box(fill: rgb("#FD3810"), inset: (x: 4mm, y: 1.6mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "medium", tracking: 0.16em, fill: rgb("#FFFFFF"))[#upper[Source: mtcars]]]],
    )
  )
  ]
}
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-compact>


== Totals, highlights and rules
<totals-highlights-and-rules>
#figure([
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: rgb("#F8FAFC"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F8FAFC"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr),
    align: (left, right, right, right,),
    table.vline(x: 3, stroke: 0.4pt + rgb("#CFD6DF")),
    table.header(
      table.cell(align: left, colspan: 4, inset: (top: 10pt, bottom: 3pt, x: 2.5mm), stroke: (top: 0.5pt + rgb("#CFD6DF")))[#v(4pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 4pt, color: rgb("#FD3810"))[TABLES - TOTALS + HIGHLIGHT]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold")[Revenue by region]],
      table.cell(align: left, colspan: 4, inset: (top: 3pt, bottom: 10pt, x: 2.5mm))[#text(font: "Inter", size: 8pt, fill: _t.fg-muted, weight: "regular")[Total row via n\_total; QoQ column highlighted and signed; vline separates quarters from the delta]#v(8pt, weak: false)],
      table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
      table.cell(align: left, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[REGION]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[Q1 USD K]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[Q2 USD K]],
      table.cell(align: right, inset: (top: 20pt, bottom: 10pt, x: 2.5mm), fill: rgb("#EBF0F6"))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[QOQ %]],
    ),
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[North]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[412.1]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[438.0]],
    table.cell(align: right, fill: rgb("#EBF0F6"))[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#147705"), weight: "thin")[+6.3%]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Center]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[388.4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[371.2]],
    table.cell(align: right, fill: rgb("#EBF0F6"))[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#CC1914"), weight: "thin")[-4.4%]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[West]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[251.9]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[266.3]],
    table.cell(align: right, fill: rgb("#EBF0F6"))[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#147705"), weight: "thin")[+5.7%]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[South]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[188.1]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[201.5]],
    table.cell(align: right, fill: rgb("#EBF0F6"))[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#147705"), weight: "thin")[+7.1%]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.hline(stroke: 0.7pt + rgb("#C6CDD6")),
    table.cell(align: left, fill: rgb("#F1F5F9"))[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Total]],
    table.cell(align: right, fill: rgb("#F1F5F9"))[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[1,240.5]],
    table.cell(align: right, fill: rgb("#F1F5F9"))[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[1,277.0]],
    table.cell(align: right, fill: rgb("#F1F5F9"))[#text(font: "JetBrains Mono", size: 7pt, fill: rgb("#147705"), weight: "thin")[+2.9%]],
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.footer(
      table.cell(colspan: 4, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#box(fill: rgb("#FD3810"), inset: (x: 4mm, y: 1.6mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "medium", tracking: 0.16em, fill: rgb("#FFFFFF"))[#upper[Source: finance close - simulated]]]],
    )
  )
  ]
}
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-totals>


== Header variants
<header-variants>
===== Title only
<title-only>
#figure([
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: rgb("#F8FAFC"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F8FAFC"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 14pt, x: 2.5mm), stroke: (top: 0.5pt + rgb("#CFD6DF")))[#v(4pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 4pt, color: rgb("#FD3810"))[TABLE · COMPACT HERO]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold")[title only · no subtitle]],
      table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
      table.cell(align: left, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MODEL]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MPG]],
      table.cell(align: left, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[CYL]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[HP]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[WT]],
    ),
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#box(fill: rgb("#FD3810"), inset: (x: 4mm, y: 1.6mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "medium", tracking: 0.16em, fill: rgb("#FFFFFF"))[#upper[Source · Motor Trend, 1974 · mtcars dataset.]]]],
    )
  )
  ]
}
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-title-only>


===== Title only · zone-highlight
<title-only-zone-highlight>
#zone-highlight(color: "metallic", above: -2mm)[
#block[
#block[
#block[
#block[
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: none)[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: none)
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.header(
      table.cell(align: left, colspan: 5, inset: (top: 10pt, bottom: 14pt, x: 2.5mm), stroke: (top: 0.5pt + rgb("#CFD6DF")))[#v(4pt, weak: false)#chanwe-eyebrow(with-rule: true, size: 4pt, color: rgb("#FD3810"))[TABLE · COMPACT HERO]#v(-6pt, weak: false)#text(font: "Schibsted Grotesk", size: 13pt, fill: _t.ink, weight: "semibold")[title only · zone-highlight]],
      table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
      table.cell(align: left, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MODEL]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[MPG]],
      table.cell(align: left, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[CYL]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[HP]],
      table.cell(align: right, inset: (top: 18pt, bottom: 10pt, x: 2.5mm))[#text(font: "JetBrains Mono", size: 5.5pt, fill: _t.fg-muted, weight: "thin", tracking: 0.05em)[WT]],
    ),
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#box(fill: rgb("#FD3810"), inset: (x: 4mm, y: 1.6mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "medium", tracking: 0.16em, fill: rgb("#FFFFFF"))[#upper[Source · Motor Trend, 1974 · mtcars dataset.]]]],
    )
  )
  ]
}
]
]
]
]
#block[
]
]
]
]
===== No title · no subtitle
<no-title-no-subtitle-1>
#figure([
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: rgb("#F8FAFC"))[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: rgb("#F8FAFC"))
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#box(fill: rgb("#FD3810"), inset: (x: 4mm, y: 1.6mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "medium", tracking: 0.16em, fill: rgb("#FFFFFF"))[#upper[Source · Motor Trend, 1974 · mtcars dataset.]]]],
    )
  )
  ]
}
]
]
], caption: figure.caption(
separator: "", 
position: top, 
[
]), 
kind: "quarto-float-tbl", 
supplement: "Table", 
)
<tbl-no-header>


===== No title · no subtitle · zone-highlight
<no-title-no-subtitle-zone-highlight>
#zone-highlight(color: "metallic", above: -2mm)[
#block[
#block[
#block[
#block[
#block(above: 2.5em, below: 2.5em)[
#block(inset: (x: 12.5pt, y: 0pt), fill: none)[
#{ set text(size: 10pt, fill: _t.ink, weight: "regular", tracking: 0pt, style: "normal"); set table(inset: (x: 2.5mm, y: 10pt), stroke: none, fill: none)
  [
  #table(
    columns: (1fr, 1fr, 1fr, 1fr, 1fr),
    align: (left, right, left, right, right,),
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.62]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Mazda RX4 Wag]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.00]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.88]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Datsun 710]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[22.80]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[93]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[2.32]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet 4 Drive]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[21.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[110]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.21]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Hornet Sportabout]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.70]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[175]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.44]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Valiant]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[18.10]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[6]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[105]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.46]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Duster 360]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[14.30]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[8]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[245]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.57]],
    table.hline(stroke: 0.4pt + rgb("#E2E8F0")),
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "medium")[Merc 240D]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[24.40]],
    table.cell(align: left)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[4]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[62]],
    table.cell(align: right)[#text(font: "JetBrains Mono", size: 7pt, fill: _t.ink, weight: "thin")[3.19]],
    table.hline(stroke: 0.5pt + rgb("#CFD6DF")),
    table.footer(
      table.cell(colspan: 5, align: left, inset: (top: 10pt, bottom: 10pt, x: 2.5mm))[#box(fill: rgb("#FD3810"), inset: (x: 4mm, y: 1.6mm))[#text(font: "JetBrains Mono", size: 5.5pt, weight: "medium", tracking: 0.16em, fill: rgb("#FFFFFF"))[#upper[Source · Motor Trend, 1974 · mtcars dataset.]]]],
    )
  )
  ]
}
]
]
]
]
#block[
]
]
]
]
#callout(kind: "success", eyebrow: "ONE SYSTEM", title: "The same tokens, everywhere")[
The QoQ columns above, the KPI arrows and the diverging heatmap poles
are the exact same three hexes --- `chanwe_palette("signed")`. Change
them once and every chart, table and report follows.

]



