// =============================================================
// chanwe-cover.typ — portadas de Chanwe Report
// =============================================================
// La portada research (por defecto) y, al final del archivo, las v2
// (`paper`, `photo-obsidian`, `series`). La "hero" se retiro el 2026-11-18.
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
  hero-image: none,
  wordmark: none,
  hero-caption-1: "32°53'24.8\"S  68°50'45.6\"W",
  hero-caption-2: "ELEV: 6967M // CERRO ACONCAGUA",
  hero-caption-3: "CORDILLERA PRINCIPAL · MENDOZA, AR",
  meta-rows: (),
  date: "",
  show-date-strip: false,
  cover-edge: none,
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
    // The Papel cut on the obsidian rail, with the rail's white text
    // (2026-11-19; it was the cool grey `Logo_Gris`).
    _chanwe-assets + "Logo_Papel.svg"
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
  // v2: the rail is a floating band, 6mm from three paper edges (brand-v2 §2:
  // "bands float with a margin, never edge to edge"). The field's foot band
  // grows by the same 6mm, so its hairline still meets the rail's.
  let rail-gap = 6mm
  let rail-band-w = rail-w - rail-gap
  let rail-band-h = _chanwe-page-h - rail-gap * 2
  let foot-h = 13.758mm

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
          rows: (26.6mm, 1fr, auto, foot-h + rail-gap),
          row-gutter: 0pt,

          block(
          width: 100%,
          height: 26.6mm,
          // The masthead's top is the rail's top (rail-gap), 2026-11-19.
          inset: (left: pad, right: pad, top: rail-gap, bottom: 26.6mm - rail-gap - 11.4mm),
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
                  radius: _t.radius-pill,
                  inset: (x: 3.06mm, y: 1.44mm),
                  text(
                    font: _t.font-mono, size: 6.5pt, weight: _t.weight-regular,
                    tracking: 0.18em, fill: _publication-muted, upper(_chanwe-clean-str(badge)),
                  ),
                ))
              #place(top + left,
                box(
                  fill: _publication-ink,
                  radius: _t.radius-pill,
                  inset: (x: 3.06mm, y: 1.44mm),
                  // Texto sobre tinta en blanco (Ale, 2026-11-19).
                  text(
                    font: _t.font-mono, size: 6.5pt, weight: _t.weight-regular,
                    tracking: 0.18em, fill: _t.white, upper(edition-label),
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

          // ── Campo de arte: la fila elástica. v2: the photograph floats inside
          // the margins with the band's 24px corners, and the veil drops from
          // 80% to 45% of paper: bleeding behind a heavy veil it read as a
          // white page.
          block(width: 100%, height: 100%, inset: (x: pad, bottom: 8mm))[
            // No border round the photograph (Ale, 2026-11-19): the light veil
            // keeps its edge.
            #block(width: 100%, height: 100%, clip: true, radius: _t.radius-band)[
              // 190% deja 45% de sobrante por lado; el corrimiento no puede
              // pasar de eso sin destapar el papel por abajo.
              #place(center + horizon, dy: -39%,
                     image(art, width: 190%, height: 190%, fit: "cover"))
              // Typst no expone opacidad sobre imágenes: el velo es el papel
              // encima, a esa opacidad. 15% since 2026-11-19 (it was 45%): under
              // the heavier veil the photograph's snow melted into the page and
              // its edges read as rough.
              #place(top + left, rect(width: 100%, height: 100%, stroke: none,
                                      fill: _publication-paper.transparentize(85%)))
            ]
          ],

          // ── Losa: ledger de datos y, debajo, el titular con su línea
          // bermellón. De alto automático: crece con el titular.
          block(width: 100%, inset: (left: pad, right: pad, top: 0mm, bottom: 10.5mm))[
          #if meta-rows.len() > 0 {
            // The hairline runs from the content margin to the rail, like the
            // photograph and the text above it (2026-11-19: it started at the
            // paper's edge, the one line on the cover that did).
            move(dx: 0pt, block(
              width: field-w - pad,
              stroke: (bottom: 0.5pt + _publication-rule),
              inset: (left: 0pt, right: pad, top: 0mm, bottom: 8.4mm),
              spacing: 0pt,
            )[
              // The ledger (Ale's pick, 2026-11-19): up to three columns, label
              // over value, as on the v2 covers.
              #grid(
                columns: range(calc.min(3, meta-rows.len())).map(_ => 1fr),
                column-gutter: 6mm,
                ..meta-rows.slice(0, calc.min(3, meta-rows.len())).map(((label, value, sub)) => block({
                  text(font: _t.font-mono, size: 6.4pt, weight: _t.weight-medium, tracking: 0.18em,
                       fill: _publication-muted, upper(_chanwe-clean-str(label)))
                  v(2.2mm)
                  text(font: _t.font-sans, size: 10pt, weight: _t.weight-regular, fill: _t.fg, _chanwe-clean-str(value))
                  if sub != none and sub != "" { linebreak(); text(font: _t.font-sans, size: 8.5pt, fill: _t.fg-muted, _chanwe-clean-str(sub)) }
                })),
              )
            ])
            v(11mm)
          }

          // El titular y su bajada, sin filete al costado desde 2026-11-07. El texto
            // mide de altura de mayúscula a línea de base (top-edge / bottom-edge).
            #block(
              width: content-w,
              spacing: 0pt,
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
                  font: _t.font-serif, size: 15pt, weight: _t.weight-body,
                  style: "italic", fill: _t.fg-muted, subtitle,
                )
              ]
            ]
        ],

          // ── Pie del campo: la pastilla de serie y, a la derecha, el doc-id
          // con su sello. Comparte banda con el pie del riel.
          block(
          width: 100%,
          height: foot-h + rail-gap,
          fill: _publication-paper,
          inset: (left: pad, right: 11.112mm, bottom: rail-gap),
        )[
          // The foot hairline starts at the margin too and meets the rail's.
          #place(top + left, dy: 0pt, line(length: field-w - pad, stroke: 0.5pt + _publication-rule))
          #align(horizon, grid(
            columns: (1fr, auto),
            align: (left + horizon, right + horizon),
            box(fill: _t.primary, radius: _t.radius-pill, inset: (x: 3.4mm, y: 1.6mm))[
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
      block(width: 100%, height: _chanwe-page-h, inset: (top: rail-gap, right: rail-gap))[
      #cw-band(width: rail-band-w, height: rail-band-h, inset: 0pt)[

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

        // ── Legal rotado, a mitad de camino entre el borde del riel y el
        // wordmark (2026-11-19: iba pegado al borde).
        #place(center + horizon, dx: -14.5mm,
          rotate(-90deg, origin: center + horizon,
            box(width: 175mm)[
              #set align(center)
              #text(
                font: _t.font-mono, size: 6.2pt, weight: _t.weight-regular,
                tracking: 0.24em, fill: _t.fg-subtle, upper(copyright),
              )
            ]
          )
        )

        // ── El wordmark, rotado y grande.
        #place(center + horizon,
          rotate(-90deg, origin: center + horizon,
            image(rail-wordmark, width: 52mm, fit: "contain")
          )
        )

        // ── Pie del riel, con su filete.
        #place(bottom + left, dy: 0mm,
          block(
            width: rail-band-w,
            height: foot-h,
            stroke: (top: 0.5pt + _t.rule-ink),
          )[
            #align(center + horizon, {
              set text(font: _t.font-mono, size: 5.6pt, weight: _t.weight-regular, tracking: 0.16em)
              // En blanco, la regla de la marca para texto sobre tinta (2026-11-19).
              text(fill: _t.white, upper(rail-location-1))
              text(fill: _t.primary, " / ")
              text(fill: _t.white, upper(rail-location-2))
            })
          ])
      ]],
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
  // On obsidian the wordmark is the Papel cut, with the white text (2026-11-19).
  let wl = if wordmark-light != none { _chanwe-clean-path(wordmark-light) } else { _chanwe-assets + "Logo_Papel.svg" }
  let qr = if qr-art != none { _chanwe-clean-path(qr-art) } else { _chanwe-assets + "contact-qr.svg" }

  _chanwe-blank-interstitial()

  set page(
    paper: _chanwe-paper, margin: 0pt, header: none, footer: none, fill: _t.ink,
    // Obsidian with the dot field only (Ale, 2026-11-13). From 3.1 until then
    // the series contour art (`01-radar-macro-dark.svg`) ran off the top right.
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
            // otras dos se corren atrás, como en la referencia, en `fg-subtle`,
            // el slate de los rótulos del pie (hasta 2026-11-13 `ink-subtle`,
            // un gris neutro que sobre la obsidiana tiraba a marrón).
            #set align(right)
            #set text(font: _t.font-mono, weight: _t.weight-body, tracking: 0.16em)
            #text(size: 5.9pt, fill: _t.fg-subtle, upper(caption-1))
            #v(0.9mm)
            #text(size: 5.9pt, weight: _t.weight-regular, fill: _t.white, upper(caption-2))
            #v(0.9mm)
            #text(size: 5.9pt, fill: _t.fg-subtle, upper(caption-3))
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
                  weight: _t.weight-regular, tracking: -0.02em, fill: _t.white, tagline-1)
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
        #v(11mm)
        // v2: the document's details sit in a frame at the foot: the `rule-ink`
        // hairline only, no fill, so the obsidian and its dot field show through
        // (Ale, 2026-11-13; until then an `ink-light` pane). Labels on ink read
        // `fg-subtle` (6:1); `ink-subtle` was too faint at 6pt.
        #block(
          width: 100%, fill: none, radius: _t.radius-surface,
          stroke: cw-hairline + _t.rule-ink,
          inset: (x: 7mm, top: 6mm, bottom: 6mm),
        )[
          #if back-cols.len() > 0 {
            grid(
              columns: back-cols.map(_ => 1fr),
              column-gutter: 8mm,
              ..back-cols.map(col => {
                let (label, value, sub) = col
                block(spacing: 0pt, width: 100%)[
                  #set par(spacing: 0pt, leading: 0pt)
                  #text(font: _t.font-mono, size: 6pt, weight: _t.weight-regular, tracking: 0.20em,
                        fill: _t.fg-subtle, upper(_chanwe-clean-str(label)))
                  #v(3mm)
                  #text(font: _t.font-mono, size: 6.4pt, weight: _t.weight-regular, tracking: 0.12em,
                        fill: _t.white, upper(_chanwe-clean-str(value)))
                  #if sub != none and sub != "" {
                    v(3mm)
                    text(font: _t.font-mono, size: 6pt, weight: _t.weight-body, tracking: 0.12em,
                         fill: _t.fg-subtle, upper(_chanwe-clean-str(sub)))
                  }
                ]
              })
            )
            v(5mm)
            line(length: 100%, stroke: 0.5pt + _t.rule-ink)
            v(4mm)
          }
          // Pie en tres partes: serie, referencia del documento y plaza.
          #grid(
            columns: (1fr, 1fr, 1fr),
            align: (left + horizon, center + horizon, right + horizon),
            {
              set text(font: _t.font-mono, size: 6pt, weight: _t.weight-body, tracking: 0.12em)
              text(fill: _t.primary, "//")
              h(2.2mm)
              text(fill: _t.fg-subtle, upper(_chanwe-clean-str(series)))
            },
            text(font: _t.font-mono, size: 6pt, weight: _t.weight-body, tracking: 0.08em,
                 fill: _t.fg-subtle, _chanwe-clean-str(doc-ref)),
            text(font: _t.font-mono, size: 6pt, weight: _t.weight-body, tracking: 0.12em,
                 fill: _t.fg-subtle, upper(_chanwe-clean-str(place-label))),
          )
        ]
      ],
    )
  ]
}

// =============================================================
// BACK COVER — full-bleed black page
// =============================================================
// Campo de puntos de contratapa: trama pareja sobre obsidiana y un foco donde
// los mismos puntos se encienden. El foco se dibuja punto por punto — un
// tiling no se puede enmascarar con un degradado.

// =============================================================
// v2 COVERS (2026-11-18) — `chanwe.cover-variant` and
// `chanwe.back-cover-variant`. Today's research cover and back cover stay the
// default; these are the hub's v2 document covers
// (brand/applications/documentos/covers/cover-*-a4) with the document's text
// on them. Every one carries the super subtle dot field.
// =============================================================

// The ledger of the v2 covers: up to three meta rows, label over value.
#let _v2-ledger(rows, label-fill, value-fill, rule) = if rows.len() > 0 {
  let rows = rows.slice(0, calc.min(3, rows.len()))
  block(width: 100%, spacing: 0pt, stroke: (top: 0.5pt + rule), inset: (top: 5mm), grid(
    columns: range(rows.len()).map(_ => 1fr),
    column-gutter: 6mm,
    row-gutter: 2.4mm,
    ..rows.map(((l, ..)) => cw-label(_chanwe-clean-str(l), fill: label-fill, size: 6pt)),
    ..rows.map(((_, val, ..)) => text(font: _t.font-sans, size: 9pt, weight: _t.weight-regular, fill: value-fill, _chanwe-clean-str(val))),
  ))
}

#let _v2-title(title, subtitle, fill, soft, size: 52pt) = {
  set par(leading: 0.16em, justify: false)
  text(font: _t.font-display, size: size, weight: _t.weight-display, tracking: -0.045em, fill: fill, title)
  _chanwe-title-dot(size)
  if subtitle != none {
    v(5mm)
    set par(leading: 0.42em)
    block(width: 85%, text(font: _t.font-serif, style: "italic", size: 19pt, weight: _t.weight-body, fill: soft, subtitle))
  }
}

#let _v2-foot(mark-cut, label, rule, quiet, qr: none) = block(width: 100%, spacing: 0pt,
  stroke: (top: 0.5pt + rule), inset: (top: 6mm), grid(
    columns: (auto, 1fr, auto),
    column-gutter: 6mm,
    align: (left + horizon, right + horizon, right + horizon),
    cw-wordmark(cut: mark-cut, height: 6.6mm),
    cw-label(label, fill: quiet, size: 6.2pt),
    if qr != none { image(qr, width: 17mm) },
  ))

// `paper`: the hub's paper cover. The Aspa large at the top left, the title
// block low, the wordmark at the foot.
#let chanwe-cover-paper(title: none, subtitle: none, eyebrow: none, top-lines: (), meta-rows: (), place-label: "") = page(
  paper: _chanwe-paper, margin: 18mm, header: none, footer: none, numbering: none, fill: _t.paper,
  background: cw-dot-gradient(),
  {
    set block(spacing: 0pt)
    place(top + left, cw-icon("Aspa", fill: _t.primary, width: 46mm))
    place(top + right, align(right, {
      set par(leading: 0.9em)
      for l in top-lines { cw-label(l, size: 6.2pt); linebreak() }
    }))
    place(bottom + left, block(width: 100%, {
      if eyebrow != none { chanwe-eyebrow(eyebrow, size: 7.5pt); v(6mm) }
      _v2-title(title, subtitle, _t.fg, _t.fg-muted)
      v(11mm)
      _v2-ledger(meta-rows, _t.fg-muted, _t.fg, _t.rule)
      v(22mm)
      _v2-foot("Negro", place-label, _t.rule, _t.fg-muted)
    }))
  },
)

// `photo-obsidian`: the hub's photo cover. The photograph on the top half,
// the title on obsidian below it.
#let chanwe-cover-photo-obsidian(title: none, subtitle: none, eyebrow: none, image-path: none, edition: "", meta-rows: ()) = page(
  paper: _chanwe-paper, margin: 0pt, header: none, footer: none, numbering: none, fill: _t.ink,
  background: cw-dot-gradient(),
  {
    set block(spacing: 0pt)
    context {
      let src = if image-path != none { image-path } else { cw-style("assets", "") + "v2/alps-blue-hour.jpg" }
      // The photograph melts into the obsidian (Ale, 2026-11-18: the hard
      // edge read as a cut). A light veil at the top, clear through the
      // middle, then an eased fade that reaches full ink before the box ends,
      // so no edge is left where the photo stops.
      place(top + left, box(width: 100%, height: 62%, clip: true, {
        image(src, width: 100%, height: 100%, fit: "cover")
        place(top + left, rect(width: 100%, height: 100%, stroke: none, fill: gradient.linear(
          (_t.ink.transparentize(70%), 0%),
          (_t.ink.transparentize(100%), 22%),
          (_t.ink.transparentize(100%), 38%),
          (_t.ink.transparentize(82%), 55%),
          (_t.ink.transparentize(50%), 70%),
          (_t.ink.transparentize(18%), 84%),
          (_t.ink, 96%),
          (_t.ink, 100%),
          angle: 90deg)))
      }))
    }
    place(bottom + left, block(width: 100%, inset: (x: 18mm, bottom: 18mm), {
      if eyebrow != none { chanwe-eyebrow(eyebrow, fill: _t.white, size: 7.5pt); v(6mm) }
      _v2-title(title, subtitle, _t.white, _t.white)
      v(10mm)
      _v2-ledger(meta-rows, _t.fg-subtle, _t.white, _t.rule-ink)
      v(18mm)
      _v2-foot("Papel", edition, _t.rule-ink, _t.fg-subtle)
    }))
  },
)

// `series`: today's research layout with v2 parts. The field is the series'
// Fundido icon on slate (no photograph); the rail carries the QR and the
// wordmark, upright, instead of the turned one.
#let chanwe-cover-series(title: none, subtitle: none, series: "", place-label: "", icon: "Onda") = page(
  paper: _chanwe-paper, margin: 10mm, header: none, footer: none, numbering: none, fill: _t.paper,
  background: cw-dot-gradient(),
  {
    set block(spacing: 0pt)
    grid(
      columns: (1fr, 46mm),
      column-gutter: 6mm,
      // the field and the title
      grid(
        rows: (64%, 1fr),
        block(width: 100%, height: 100%, radius: _t.radius-band, clip: true, fill: _t.surface-slate, {
          place(top + left, cw-dot-gradient())
          place(top + right, dx: 58mm, dy: 26mm, cw-icon(icon, fill: _t.ink, width: 200mm))
        }),
        block(width: 100%, height: 100%, inset: (x: 4mm, bottom: 2mm), align(bottom + left, {
          _v2-title(title, subtitle, _t.fg, _t.fg-muted, size: 40pt)
          v(7mm)
          box(fill: _t.primary, radius: _t.radius-pill, inset: (x: 3mm, y: 1.8mm),
            text(font: _t.font-mono, size: 6.4pt, weight: _t.weight-medium, tracking: 0.14em, fill: _t.white, "// " + upper(series)))
        })),
      ),
      // the rail
      block(width: 100%, height: 100%, radius: _t.radius-band, clip: true, fill: _t.ink, inset: (x: 7mm, y: 8mm), {
        place(top + left, dx: -7mm, dy: -8mm, block(width: 46mm, height: 297mm, cw-dot-gradient(from: (1.0, 0.0))))
        grid(
          rows: (auto, 1fr, auto, auto),
          row-gutter: 6mm,
          context image(cw-style("assets", "") + "v2/contact-qr-papel.svg", width: 100%),
          [],
          align(center, cw-wordmark(cut: "Papel", width: 28mm)),
          align(center, cw-label(place-label, fill: _t.fg-subtle, size: 5.6pt)),
        )
      }),
    )
  },
)

// ---- back covers -------------------------------------------------------
#let _v2-contact(cols, place-label) = {
  let cols = if cols.len() > 0 { cols.slice(0, calc.min(2, cols.len())).map(((lab, val, ..)) => (lab, val)) }
    else { (("Contacto", "hola@chanwe.ar"), ("Sede", place-label)) }
  cols
}
#let _v2-tagline(t1, t2, display: false, fill: _t.white, accent: _t.primary) = {
  set par(leading: 0.2em)
  if display {
    text(font: _t.font-display, size: 34pt, weight: _t.weight-display, tracking: -0.04em, fill: fill, t1)
    linebreak()
    text(font: _t.font-display, size: 34pt, weight: _t.weight-display, tracking: -0.04em, fill: accent, t2)
  } else {
    text(font: _t.font-serif, style: "italic", size: 38pt, weight: _t.weight-body, tracking: -0.02em, fill: fill, t1)
    linebreak()
    text(font: _t.font-serif, style: "italic", size: 38pt, weight: _t.weight-body, tracking: -0.02em, fill: accent, t2)
  }
}
#let _v2-frame(cols, qr, stroke, label-fill, value-fill) = block(width: 100%, radius: _t.radius-pane,
  stroke: 0.6pt + stroke, inset: 6mm, grid(
    columns: (1fr, 1fr, auto),
    column-gutter: 6mm,
    align: (left + bottom, left + bottom, right + bottom),
    ..cols.map(((lab, val)) => block({
      cw-label(_chanwe-clean-str(lab), fill: label-fill, size: 5.8pt)
      v(2mm)
      text(font: _t.font-sans, size: 9pt, fill: value-fill, _chanwe-clean-str(val))
    })),
    ..range(2 - cols.len()).map(_ => []),
    box(stroke: 0.8pt + _t.white, radius: 1.6mm, clip: true, image(qr, width: 24mm)),
  ))

// `aspa`: obsidian; the Aspa in `ink-light` bleeds off the corner, as the
// series art does; the wordmark top left; the tagline and the contact frame.
#let chanwe-back-cover-aspa(tagline-1: "", tagline-2: "", back-cols: (), place-label: "") = page(
  paper: _chanwe-paper, margin: 18mm, header: none, footer: none, numbering: none, fill: _t.ink,
  background: {
    place(top + left, cw-dot-gradient())
    place(bottom + right, dx: 50mm, dy: 42mm, cw-icon("Aspa", fill: _t.ink-light, width: 196mm))
  },
  context {
    set block(spacing: 0pt)
    let a = cw-style("assets", "")
    place(top + left, cw-wordmark(cut: "Papel", height: 7.4mm))
    place(bottom + left, block(width: 100%, {
      _v2-tagline(tagline-1, tagline-2)
      v(16mm)
      _v2-frame(_v2-contact(back-cols, place-label), a + "v2/contact-qr-papel.svg", _t.rule-ink, _t.fg-subtle, _t.white)
    }))
  },
)

// `orange`: the brand orange as the ground of an identity piece (orange may
// be the background of identity tiles, CLAUDE.md): the Papel wordmark, tagline and
// frame, the orange contact code.
#let chanwe-back-cover-orange(tagline-1: "", tagline-2: "", back-cols: (), place-label: "") = page(
  paper: _chanwe-paper, margin: 18mm, header: none, footer: none, numbering: none, fill: _t.primary,
  background: cw-dot-gradient(color: _t.white),
  context {
    set block(spacing: 0pt)
    let a = cw-style("assets", "")
    place(top + left, cw-wordmark(cut: "Papel", height: 7.4mm))
    place(bottom + left, block(width: 100%, {
      _v2-tagline(tagline-1, tagline-2, display: true, fill: _t.white, accent: _t.white)
      v(16mm)
      _v2-frame(_v2-contact(back-cols, place-label), a + "v2/contact-qr-naranja.svg",
        _t.white.transparentize(45%), _t.white.transparentize(20%), _t.white)
    }))
  },
)

// `mark`: the mirror of the hub's obsidian cover. The orange Aspa top left;
// at the foot the wordmark, the address and a small code. No tagline.
#let chanwe-back-cover-mark(place-label: "") = page(
  paper: _chanwe-paper, margin: 18mm, header: none, footer: none, numbering: none, fill: _t.ink,
  background: cw-dot-gradient(),
  context {
    set block(spacing: 0pt)
    let a = cw-style("assets", "")
    place(top + left, cw-icon("Aspa", fill: _t.primary, width: 46mm))
    place(bottom + left, _v2-foot("Papel", "chanwe.ar  ·  " + place-label, _t.rule-ink, _t.fg-subtle,
      qr: a + "v2/contact-qr-obsidiana.svg"))
  },
)
