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
}
