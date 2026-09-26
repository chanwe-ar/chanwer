// =============================================================
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
// tiling no se puede enmascarar con un degradado.
