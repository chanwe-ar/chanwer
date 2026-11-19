// =============================================================
// chanwe-elements.typ — callouts, pull quotes, great quote pages
// Available to authors as #callout, #pullquote, #great-quote
// =============================================================

// La ficha de rótulo: marco slate, fondo transparente, mono en versalita. La
// llevan el tema del hallazgo y la procedencia del KPI, así que vive en un solo
// lugar —son el mismo objeto y no tienen por qué separarse con el tiempo—.
// `tone` pinta marco y texto del mismo color, para las superficies donde el
// slate del marco y el fg-muted del texto no se leen: border-cool sobre
// obsidiana, blanco sobre naranja.
#let _chip-label(body, tone: none, size: 5.2pt, inset: (x: 1.8mm, y: 1.2mm)) = box(
  stroke: 0.3pt + (if tone != none { tone } else { _t.border-cool }),
  // v2: every chip is a pill.
  radius: _t.radius-pill,
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

  // v2-print (brand-v2 §7): the callout is a pane — white on paper, the
  // 1px hairline, 16px corners, no shadow. Its first line is the kind: a dot
  // in its role colour and the mono label; then the title, then the body. No
  // tinted title row (the last 1.x trace, dropped 2026-11-18), no side bar.
  // The title row shows only a real title: Quarto's native callouts send
  // their default title ("Note", "Tip"...), which the label already says.
  let _plain(x) = if type(x) == str { x } else if type(x) == content and x.has("text") { x.text } else { none }
  let pt = if title != none { _plain(title) } else { none }
  let show-title = title != none and (pt == none or (lower(pt) != lower(auto-label) and pt != type-label))
  // Radius `pane` 12px on paper and screen alike (unified with the kit, 2026-11-18).
  cw-pane(
    fill: _t.pane,
    radius: _t.radius-pane,
    inset: (x: _t.space-lg, y: _t.space-md),
    above: 10mm,
    below: 10mm,
    breakable: false,
  )[
    #set block(spacing: 0pt)
    #grid(
      columns: (auto, 1fr),
      column-gutter: _t.space-xs,
      align: left + horizon,
      cw-dot(accent, size: 5.5pt, baseline: 0pt),
      cw-label(type-label, fill: _t.fg-muted, size: 7pt, tracking: 0.14em),
    )
    #if show-title {
      v(2.4mm)
      text(font: _t.font-display, size: 11pt, weight: _t.weight-display, tracking: -0.02em, fill: _t.fg, title)
    }
    #v(2mm)
    #block[
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

// v2-print: an insert floats inside the text block. Until 3.0.2 the quote,
// figure, summary and zone inserts bled to both paper edges with square
// corners, while the chapter band of the same page floated with 24px ones;
// now they are the same family (brand-v2 §2: "bands float with a margin,
// never edge to edge"). Obsidian is the band itself (dot field, sheen);
// slate and orange take its corners; white is a pane with the hairline.
// `gap` is the air above and below: two inserts in a row no longer touch
// (edge to edge they read as one striped band; floating, as a collision).
// An insert never splits across two pages (it did not when it was a `move`).
// Orange is a signal, not a fill (decided 2026-11-18): `primary` is the
// obsidian band with one orange Aspa in its top right corner, where the
// insert's padding leaves room for it.
#let _cw-signal-mark(inset) = {
  let _get(k, d) = if type(inset) == dictionary { inset.at(k, default: d) } else { inset }
  let r = _get("right", _get("x", 12mm))
  let t = _get("top", _get("y", 12mm))
  place(top + right, dx: r - 4mm, dy: if t > 6mm { -t + 4mm } else { 4mm },
    cw-icon("Aspa", fill: _t.primary, width: 7mm))
}
#let _cw-insert(color, bg, inset, gap: 8mm, body) = if color == "dark" or color == "primary" {
  cw-band(inset: inset, above: gap, below: gap, breakable: false, {
    if color == "primary" { _cw-signal-mark(inset) }
    body
  })
} else {
  block(
    width: 100%, fill: bg, radius: _t.radius-band, inset: inset, above: gap, below: gap,
    breakable: false, clip: true,
    stroke: if bg == _t.white { cw-hairline + _t.rule } else { none },
    body,
  )
}

// `light` va sobre surface-slate (#EBF0F6), el mismo slate del abstract y
// de los paneles de código; `slate` vale igual.
#let _gq-scheme(color, inset: false) = if color == "light" or color == "slate" {
  (
    bg:     _t.surface-slate,
    eyebrow: _t.primary,
    quote:  _t.fg,
    emph:   _t.primary,
    attr:   _t.fg,
    source: _t.fg-muted,
    line:   _t.primary,
    rule:   _t.rule-cool,
    art:    _t.pane,
    label:  _t.fg-muted,
  )
} else if color == "white" {
  (
    bg:     _t.white,
    eyebrow: _t.primary,
    quote:  _t.fg,
    emph:   _t.primary,
    attr:   _t.fg,
    source: _t.fg-muted,
    line:   _t.primary,
    rule:   _t.rule,
    art:    _t.surface-slate,
    label:  _t.fg-muted,
  )
} else {
  // `dark`, and `primary`, which is the same band with the orange as a signal.
  (
    bg:     _t.ink,
    eyebrow: _t.primary,
    // Texto sobre obsidiana en blanco (Ale, 2026-11-19).
    quote:  _t.white,
    emph:   _t.primary,
    attr:   _t.white,
    source: _t.fg-subtle,
    line:   _t.primary,
    rule:   _t.rule-ink,
    art:    _t.ink-light,
    label:  _t.white,
  )
}

// The quote's text in one of the three styles (`quote-style`, or the Div's
// `style`): `serif` (Cormorant italic, the default), `display` (Schibsted 600,
// as the v2 band sets display type) and `serif-art` (the serif, with a
// Fundido icon bleeding off the corner).
#let _gq-text(style, size, fill, body) = if style == "display" {
  text(font: _t.font-display, size: size * 0.86, weight: _t.weight-display, tracking: -0.035em,
       fill: fill)[\u{201C}#body\u{201D}]
} else {
  text(font: _t.font-serif, size: size, style: "italic", weight: _t.weight-body,
       tracking: -0.025em, fill: fill)[\u{201C}#body\u{201D}]
}

// The signature, the v2 way (2026-11-18): a hairline across the measure, then
// a dot and the name, and the source as a mono label under it. No pill, no
// short orange rule: the dot is the one orange.
#let _gq-attribution(caption, source, s, big: false) = {
  set block(spacing: 0pt)
  set par(spacing: 0pt)
  line(length: 100%, stroke: 0.5pt + s.rule)
  if caption != none or source != none {
    v(if big { 6mm } else { 4mm })
    let dot = if big { 6pt } else { 4.6pt }
    let gap = if big { 3mm } else { 2.2mm }
    grid(
      columns: (auto, 1fr),
      column-gutter: gap,
      row-gutter: if big { 3mm } else { 2mm },
      align: (left + horizon, left + horizon),
      cw-dot(_t.primary, size: dot, baseline: 0pt),
      if caption != none {
        text(font: _t.font-sans, size: if big { 15pt } else { 9.6pt }, weight: _t.weight-medium,
             tracking: -0.01em, fill: s.attr, caption)
      } else { cw-label(source, fill: s.source, size: if big { 7pt } else { 6pt }) },
      [],
      if caption != none and source != none { cw-label(source, fill: s.source, size: if big { 7pt } else { 6pt }) },
    )
  }
}

#let page-great-quote(caption: none, source: none, color: "dark", eyebrow: "Verbatim", style: auto, body) = context {
  let style = if style == auto { cw-style("quote-style", "serif") } else { style }
  let s = _gq-scheme(color)
  set page(paper: _chanwe-paper, margin: 0pt, header: none, footer: none, fill: s.bg)
  block(width: 100%, height: 100%, fill: s.bg, clip: true)[
    #if style == "serif-art" {
      place(bottom + right, dx: 46mm, dy: 40mm, cw-icon("Onda", fill: s.art, width: 190mm))
    }
    #if color == "primary" {
      place(top + right, dx: -22mm, dy: 22mm, cw-icon("Aspa", fill: _t.primary, width: 14mm))
    }
    #if color == "dark" or color == "primary" { place(top + left, cw-dot-gradient()) }
    #block(width: 100%, height: 100%, inset: (x: 22mm, top: 40mm, bottom: 30mm))[
      #show emph: it => text(fill: s.emph, style: "italic", it.body)
      #chanwe-eyebrow(eyebrow, fill: s.label, size: 12pt)
      // Misma estructura que el inserto —5mm y la cita dentro de un bloque— para
      // que el aire entre rótulo y cita sea el mismo.
      #v(5mm)
      #set par(leading: 0.32em)
      // The quote takes the page: the largest of these sizes that keeps it
      // within 150mm of height, so a short line is set at 64pt and a long
      // paragraph falls back to 32.2pt.
      #layout(size => {
        let q(sz) = block(width: 100%, _gq-text(style, sz, s.quote, body))
        let fit = (64pt, 56pt, 48pt, 40pt).find(sz => measure(q(sz), width: size.width).height <= 150mm)
        q(if fit == none { 32.2pt } else { fit })
      })
      #v(1fr)
      #_gq-attribution(caption, source, s, big: true)
    ]
  ]
}

#let inset-great-quote(caption: none, source: none, color: "dark", eyebrow: "Verbatim", style: auto, body) = context {
  let style = if style == auto { cw-style("quote-style", "serif") } else { style }
  let s = _gq-scheme(color, inset: true)
  _cw-insert(color, s.bg, (x: 12mm, top: 12mm, bottom: 12mm))[
      #if style == "serif-art" {
        place(bottom + right, dx: 12mm + 22mm, dy: 12mm + 24mm, cw-icon("Onda", fill: s.art, width: 92mm))
      }
      #show emph: it => text(fill: s.emph, style: "italic", it.body)
      #set par(leading: 0.32em)
      #chanwe-eyebrow(eyebrow, fill: s.label)
      #v(5mm)
      // La cita no usa los 166mm del bloque: a 122mm rompe en dos renglones
      // parejos y deja aire a la derecha, que es lo que la separa de un párrafo.
      #block(width: 122mm, _gq-text(style, 28pt, s.quote, body))
      #v(14mm)
      #_gq-attribution(caption, source, s)
    ]
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
        #chanwe-eyebrow(eyebrow, fill: s.label, size: 6.8pt)
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
      // The foot of a figure: quiet mono over a hairline, in the tone of the surface.
      let foot-tone = if on-dark { s.source } else { _t.fg-muted }
      v(2.6mm)
      line(length: 100%, stroke: 0.5pt
        + (if on-dark { _t.rule-ink } else { _t.rule }))
      v(1.8mm)
      grid(
        columns: (auto, 1fr),
        column-gutter: 7mm,
        align: (left + top, right + top),
        if source-label != none {
          cw-label(source-label, size: 5.6pt, weight: _t.weight-regular, fill: foot-tone)
        } else { [] },
        if source != none {
          text(font: _t.font-sans, size: 7.2pt, weight: _t.weight-body-plus, fill: foot-tone, source)
        } else { [] },
      )
    }
  ]

  let (first-col, second-col) = if position == "left" {
    (plot-col, text-col)
  } else {
    (text-col, plot-col)
  }

  _cw-insert(color, s.bg, (x: 12mm, y: 14mm))[
      #show emph: it => text(fill: s.emph, style: "italic", it.body)
      #grid(
        columns: col-widths,
        column-gutter: 12mm,
        align: (left + top, left + top),
        first-col,
        second-col,
      )
    ]
}

#let inset-great-summary(
  eyebrow: "Executive Summary",
  title: "",
  color: "white",
  body,
) = {
  // Cuatro variantes: white (hoja), light (panel editorial), dark (obsidiana,
  // texto en blanco) y primary (la banda de obsidiana con el naranja como
  // señal: el Aspa en la esquina, 2026-11-18).
  let s = if color == "dark" or color == "primary" {
    (bg: _t.ink, eyebrow: _t.primary, title: _t.white, rule: _t.primary, body: _t.white)
  } else if color == "light" or color == "slate" {
    (bg: _t.surface-slate, eyebrow: _t.primary, title: _t.ink, rule: _t.primary, body: _t.body-fg)
  } else {
    (bg: _t.white, eyebrow: _t.primary, title: _t.ink, rule: _t.primary, body: _t.body-fg)
  }
  let borders = not ("white", "light", "slate", "dark", "primary").contains(color)
  _cw-insert(color, s.bg, (x: 12mm, top: 0pt, bottom: 0pt))[
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
// el panel editorial y `dark` obsidiana con el texto en blanco. `primary`
// es obsidiana también: el naranja queda como señal (el numeral), no de fondo
// (2026-11-18).
#let _gf-scheme(color) = if color == "dark" or color == "primary" {
  (bg: _t.ink, numeral: _t.primary, title: _t.white, body: _t.white,
   accent: _t.primary, rule: _t.rule-ink, label: _t.white.transparentize(35%), chip: _t.white)
} else if color == "light" or color == "slate" {
  (bg: _t.surface-slate, numeral: _t.primary, title: _t.ink, body: _t.fg-muted,
   accent: _t.primary, rule: _t.rule, label: _t.fg-muted, chip: none)
} else {
  (bg: none, numeral: _t.primary, title: _t.ink, body: _t.fg-muted,
   accent: _t.primary, rule: _t.rule, label: _t.fg-muted, chip: none)
}

// `height` fija el alto de la fila: la celda del texto —y con ella el filete
// naranja, que es su borde izquierdo— se estira hasta ahí. `auto` mide sola.
#let _great-findings-row(number: "01", title: "", topic: "", topic-label: "Tema", height: auto, scheme: _gf-scheme("white"), numeral: auto, body) = context {
  // The numeral (2026-11-18): Schibsted 600, tabular. `orange` (the default)
  // or `slate`; the Div's `numeral` or the document's `findings-numeral`.
  let numeral = if numeral == auto { cw-style("findings-numeral", "orange") } else { numeral }
  let num-fill = if numeral == "slate" { if scheme.bg == _t.ink { _t.fg-subtle } else { _t.fg-muted } } else { scheme.numeral }
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
    grid.cell(inset: (top: 0.2mm), text(
      font: _t.font-display, size: 22pt, weight: _t.weight-display, tracking: -0.03em,
      number-type: "lining", number-width: "tabular", fill: num-fill, number,
    )),

    // v2 (Ale, 2026-10-30, opción C): sin filete lateral; el hallazgo es un panel
    // y el numeral naranja es la única señal.
    grid.cell(inset: (left: 0mm))[
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

    // El tema arriba a la derecha, alineado con el título: la etiqueta mono y
    // debajo, pegada, la pill.
    if topic != "" {
      align(right + top, stack(dir: ttb, spacing: 1.4mm,
        align(right, text(font: _t.font-mono, size: 5.2pt, weight: _t.weight-regular, tracking: 0.18em,
              fill: s.label, upper(topic-label))),
        align(right, _chip-label(topic, tone: s.chip)),
      ))
    } else { [] },
  )
}

// El marco de la lista: los filetes de cierre son los mismos que la divisoria
// entre ítems —mismo grosor, mismo tono—, así que la lista se lee como un
// pentagrama parejo y no como una banda con bordes pesados. `color` mantiene
// las variantes en panel para los documentos que ya las usan.
#let _gf-panes(color) = color in ("white", "light", "slate")
#let _gf-frame(color, body) = {
  let s = _gf-scheme(color)
  if _gf-panes(color) {
    block(width: 100%, fill: _t.surface-slate, radius: _t.radius-surface, inset: 4mm,
      above: 10mm, below: 10mm)[#body]
  } else if s.bg == none {
    block(width: 100%, inset: 0pt, above: 10mm, below: 10mm,
      stroke: (top: 0.3pt + s.rule, bottom: 0.3pt + s.rule))[#body]
  } else {
    block(width: 100%, fill: s.bg, radius: _t.radius-surface, inset: (x: 6mm),
      above: 10mm, below: 10mm)[#body]
  }
}

#let great-findings(number: "01", title: "", topic: "", topic-label: "Tema", color: "white", numeral: auto, body) = {
  let row = _great-findings-row(number: number, title: title, topic: topic, topic-label: topic-label, scheme: _gf-scheme(color), numeral: numeral, body)
  _gf-frame(color, if _gf-panes(color) {
    cw-pane(inset: (x: 6mm, y: _gf-pad-y), spacing: 0pt, row)
  } else {
    block(width: 100%, inset: (y: _gf-pad-y), spacing: 0pt, row)
  })
}

// item used inside a great-findings-grid (the frame is the wrapper's job)
#let great-findings-item(number: "01", title: "", topic: "", topic-label: "Tema", height: auto, scheme: _gf-scheme("white"), numeral: auto, body) = {
  block(width: 100%, inset: (y: _gf-pad-y), spacing: 0pt)[
    #_great-findings-row(number: number, title: title, topic: topic, topic-label: topic-label, height: height, scheme: scheme, numeral: numeral, body)
  ]
}

// La divisoria entre ítems. Va envuelta en un bloque sin espaciado porque una
// `line` suelta cobra el espaciado de bloque del cuerpo a cada lado, y eso era
// lo que abría el hueco muerto entre un hallazgo y el siguiente.
#let _gf-rule(s) = block(spacing: 0pt, line(length: 100%, stroke: 0.3pt + s.rule))

// wrapper that frames the list and separates items with a hairline
// La lista recibe los ítems como lista de contenidos, no como un cuerpo
// suelto, para poder medirlos: todas las filas miden lo mismo —la más alta
// manda—, así una lista de tres hallazgos no cambia de ritmo porque uno lleve
// dos renglones más. `row-height` pone un piso en milímetros por si hace
// falta emparejar dos listas distintas.
#let great-findings-grid(color: "white", row-height: none, numeral: auto, items) = {
  // Un ítem es un diccionario (number, title, topic, topic-label, body): así
  // se puede dibujar dos veces, una para medirlo y otra a la altura pareja,
  // y el filete naranja acompaña esa altura.
  let s = _gf-scheme(color)
  let render(it, h) = great-findings-item(
    number: it.at("number", default: "01"), title: it.at("title", default: ""),
    topic: it.at("topic", default: ""), topic-label: it.at("topic-label", default: "Tema"),
    height: h, scheme: s, numeral: numeral, it.at("body", default: []),
  )
  _gf-frame(color, layout(size => {
    let floor = if row-height != none { row-height } else { 0pt }
    let w = if _gf-panes(color) { size.width - 12mm } else { size.width }
    let h = calc.max(floor, ..items.map(it => measure(block(width: w, render(it, auto))).height))
    // La fila mide el bloque menos el aire de arriba y abajo.
    let row-h = h - 2 * _gf-pad-y
    for (i, it) in items.enumerate() {
      if _gf-panes(color) {
        if i > 0 { v(3mm) }
        cw-pane(inset: (x: 6mm, y: 0mm), spacing: 0pt, render(it, row-h))
      } else {
        if i > 0 { _gf-rule(s) }
        render(it, row-h)
      }
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
    if direction == "up" { "↑" }
    else if direction == "down" { "↓" }
    else if direction == "neutral" { "—" }
    else { "" }
  }
  // The variation is a signed pill (option A, 2026-11-07): the sign's colour
  // as text on the same colour at 10%, as chanwer's KPI pane and table deltas.
  // `secondary-color` names the valence when it is not the direction's
  // ("green" / "red"); otherwise up is green, down is red, no move is slate.
  let valence = if secondary-color == "green" or secondary-color == "red" { secondary-color }
    else if direction == "up" { "green" } else if direction == "down" { "red" } else { "muted" }
  let chip-fg = _kpi-color(valence)
  let chip-bg = chip-fg.transparentize(90%)

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
          // The figure head's gesture: a dot and the mono label.
          cw-dot(_t.primary, size: 4pt)
          h(1.8mm)
          cw-label(title, fill: _t.fg, size: 6pt)
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
                 fill: _t.fg-muted, upper(unit-note))
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
            box(fill: chip-bg, radius: _t.radius-pill, inset: (x: 2.4mm, y: 1.15mm),
              text(font: _t.font-mono, size: 5.9pt, weight: _t.weight-medium, tracking: 0.06em,
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
                 fill: _t.fg-muted, upper(l))),
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
  // Option A (2026-11-07): one pane, with a hairline between the tiles. Four
  // panes in a row was the one place the pane language got loud.
  let n-rows = calc.ceil(items.len() / cols)
  block(width: 100%, above: 11mm, below: 12mm,
    cw-pane(inset: 0pt, breakable: false, grid(
      columns: range(cols).map(_ => 1fr),
      inset: (x: _t.space-md, y: _kpi-pad-y),
      stroke: none,
      ..range(1, cols).map(i => grid.vline(x: i, stroke: cw-hairline + _t.rule)),
      ..range(1, n-rows).map(i => grid.hline(y: i, stroke: cw-hairline + _t.rule)),
      ..items,
    )))
}

// =============================================================
// ZONE HIGHLIGHT — a floating background colour zone (v2: 24px corners)
// =============================================================
// color: "light" (por defecto) | "white" | "dark" | "primary"
// ("slate" vale por light, "orange" por primary y "metallic", que
// era la hoja misma, ahora cae en light).
// `margin` es el aire adentro del panel, arriba y abajo del texto: a 2mm el
// cuerpo tocaba el borde de la banda. Se mide contra el ancho de la columna,
// no contra el cuerpo del texto, así que no cambia con `body-size`.
#let zone-highlight(color: "light", margin: 8mm, above: 3mm, below: 3mm, col-gutter: 14mm, ..bodies) = {
  // La zona `light` va un paso más abajo que los demás paneles light
  // (surface-slate en vez del beige): corre dentro del cuerpo y sobre la
  // hoja necesita un poco más de contraste para leerse como banda.
  let bg = if color == "light" or color == "slate" or color == "metallic" { _t.surface-slate }
    // `primary` is obsidian with the orange Aspa as its signal (2026-11-18).
    else if color == "dark" or color == "primary" or color == "orange" { _t.ink }
    else if color.starts-with("#")       { rgb(color)     }
    else                                 { _t.white          }
  let on-dark = color == "dark" or color == "primary" or color == "orange"
  // Sobre obsidiana el texto va en blanco, como en todo el formato; sobre
  // naranja, en blanco.
  let on-color = _t.white

  if above != none { v(above) }
  _cw-insert(if color == "orange" { "primary" } else { color }, bg, (x: 10mm, top: margin, bottom: margin), gap: 0pt)[
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
  if below != none { v(below) }
}

// =============================================================
// FIGURE FRAME — figure-local footer + alt-footer treatment
// top-left/top-right form the upper footer; bottom-left/bottom-right
// form the lower alt-footer. The body may contain a Markdown image,
// generated plot, table, or raw Typst figure.
// =============================================================
// The frame's two rows are the shared footer language (chanwe-v2.typ).
#let _chanwe-frame-top(top-left, top-right) = if top-left != none {
  cw-figure-head(top-left, gloss: top-right)
} else if top-right != none {
  text(font: _t.font-sans, size: 7.6pt, weight: _t.weight-body-plus, fill: _t.fg-muted, top-right)
  v(3mm)
}

#let _chanwe-frame-bottom(bottom-left, bottom-right) = cw-figure-foot(bottom-left, bottom-right)

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
// `: pie {#tbl-x}` — vestida con la cabeza del marco: "FIGURA 1" / "TABLA 1" (el
// suplemento sigue a `lang`) y el pie al lado. Nada debajo: lo que cierra una
// figura es su fuente, y esa la escribe el autor. La numeración y las referencias
// cruzadas (`@fig-x`) no cambian: el contador es el de Quarto. `it` es el `figure`
// de tipo `quarto-float-*`.
#let chanwe-native-figure(it) = block(
  width: 100%, breakable: false, above: 11mm, below: 12mm,
)[
  #set block(spacing: 0pt)
  #_chanwe-frame-top(
    upper(it.supplement) + " " + it.counter.display(),
    if it.caption != none { it.caption.body } else { none },
  )
  #block(width: 100%, it.body)
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
}
