// =============================================================
// chanwe-cover.typ — Chanwe Publications Letter cover
// =============================================================
// Geometry is matched to reports-covers.pdf:
//   532 px editorial field | 34 px legal gutter | 250 px black rail
//   700 px artwork/title header | 304 px title slab | 52 px footer
// at a 96 dpi, 816 x 1056 px US Letter canvas.
// =============================================================

// Pandoc/Quarto escapes underscores and hyphens in YAML values.
#let _chanwe-clean-path(p) = if p == none { none } else { p.replace("\\_", "_").replace("\\-", "-") }

#let _publication-paper = rgb("#F7F7F7")
#let _publication-art-paper = rgb("#FAF9F7")
#let _publication-ink = rgb("#14141A")
#let _publication-orange = rgb("#F4380F")
#let _publication-rule = rgb("#DFDEDA")
#let _publication-muted = rgb("#99999E")
#let _publication-metallic = rgb("#AFAFAF")

#let _publication-meta-row(label, value, sub: none) = block(
  width: 90mm,
  height: 7.673mm,
  stroke: (top: 0.5pt + _publication-rule),
)[
  #align(horizon, grid(
    columns: (1fr, 1fr),
    align: (left + horizon, right + horizon),
    text(
      font: "IBM Plex Mono",
      size: 6.6pt,
      weight: 500,
      tracking: 0.15em,
      fill: _publication-muted,
      upper(label),
    ),
    block(spacing: 0pt)[
      #set align(right)
      #set par(leading: 0.78em)
      #text(font: "Archivo", size: 9pt, weight: 400, fill: _publication-ink, value)
      #if sub != none and sub != "" {
        linebreak()
        text(font: "IBM Plex Mono", size: 5.5pt, tracking: 0.08em, fill: _publication-muted, sub)
      }
    ],
  ))
]

#let chanwe-cover-page(
  title: "Untitled",
  subtitle: none,
  doc-id: "CHW · DOC · 2026 · 01",
  edition: "Edition 01 / 2026",
  volume: "PÚBLICO",
  rail-eyebrow: "Quarto · Style Guide",
  hero-image: none,
  hero-img-position: none,
  wordmark: none,
  stamp: ("est.", "mdz", "2026"),
  hero-caption-1: "S 32°53′ · W 68°50′",
  hero-caption-2: "Cordón del Plata · ARG",
  hero-date: "",
  meta-rows: (),
  date: "",
  show-date-strip: false,
  cover-edge: none,
  cover-edge-color: none,
  publication-period: none,
  publication-edition: none,
  publication-art: none,
  publication-audience: "PÚBLICO",
  publication-series: "CHANWE / RESEARCH",
  publication-location: "MENDOZA / ARGENTINA",
  publication-copyright: "PROHIBIDA SU REPRODUCCIÓN SIN AUTORIZACIÓN | TODOS LOS DERECHOS RESERVADOS",
) = {
  let art = if publication-art != none {
    _chanwe-clean-path(publication-art)
  } else if hero-image != none {
    _chanwe-clean-path(hero-image)
  } else {
    _chanwe-assets + "01-radar-macro.svg"
  }
  let period = if publication-period != none { publication-period } else { date }
  let edition-label = if publication-edition != none { publication-edition } else { edition }
  let copyright = if cover-edge != none { cover-edge } else { publication-copyright }
  let rail-wordmark = if wordmark == none {
    _chanwe-assets + "Logo_Blanco.svg"
  } else {
    _chanwe-clean-path(wordmark)
  }

  set page(
    paper: "us-letter",
    margin: 0pt,
    header: none,
    footer: none,
    fill: _publication-paper,
    background: none,
    foreground: {
      // Match the chanwe-report cover halo with a neutral metallic-gray tint.
      place(top + left, dx: 50mm, dy: -50mm,
        circle(
          radius: 110mm,
          fill: gradient.radial(
            _publication-metallic.transparentize(78%),
            black.transparentize(100%),
          ),
          stroke: none,
        )
      )
    },
  )
  set block(spacing: 0pt)

  // ---- COVER BODY (1004 / 1056 px) --------------------------
  block(width: 100%, height: 265.642mm, breakable: false)[
    #grid(
      columns: (140.758mm, 8.996mm, 66.146mm),
      rows: (265.642mm,),
      column-gutter: 0pt,

      // ---- Left editorial field ------------------------------
      block(
        width: 100%,
        height: 265.642mm,
        stroke: (right: 0.75pt + _publication-rule),
      )[
        // Artwork covers the reference field and crops laterally as needed.
        #block(width: 100%, height: 185.208mm, fill: _publication-art-paper, clip: true)[
          #if art.contains("01-radar-macro.svg") {
            // Enlarge the radar artwork around its center and lower it slightly.
            place(
              top + left,
              dx: -10.557mm,
              dy: 4mm,
              image(art, width: 161.872mm, height: 212.989mm, fit: "cover"),
            )
          } else {
            place(top + left, image(art, width: 100%, height: 185.208mm, fit: "cover"))
          }

          // Keep the publication masthead fully opaque above the separator.
          #place(top + left,
            rect(width: 100%, height: 22.225mm, fill: white, stroke: none))

          // Period and edition overlay the artwork.
          #place(top + left, dx: 10.583mm, dy: 6.44mm)[
            #text(
              font: "IBM Plex Mono",
              size: 19.4pt,
              weight: 400,
              fill: _publication-ink,
              period,
            )
          ]
          #place(top + left, dx: 10.583mm, dy: 15.36mm)[
            #text(
              font: "IBM Plex Mono",
              size: 7.5pt,
              weight: 500,
              tracking: 0.117em,
              fill: _publication-orange,
              upper(edition-label),
            )
          ]
          #place(top + left, dy: 22.225mm,
            line(length: 100%, stroke: 0.5pt + _publication-rule))
        ]

        // Lower metadata and title slab.
        #block(
          width: 100%,
          height: 80.433mm,
          fill: white,
          stroke: (top: 0.5pt + _publication-rule),
          clip: true,
        )[
          #place(top + left, dx: 10.583mm, dy: 7.144mm,
            line(length: 67.998mm, angle: 90deg, stroke: 1pt + _publication-orange))

          #if meta-rows.len() > 0 {
            place(top + left, dx: 17.727mm, dy: 6.02mm,
              stack(
                dir: ttb,
                spacing: 0pt,
                ..meta-rows.map(((label, value, sub)) => _publication-meta-row(label, value, sub: sub)),
              )
            )
          }

          // The title/subtitle group is bottom-anchored so a two-line lede
          // raises the title exactly like Quarterly Review in the reference.
          #place(bottom + left, dx: 17.727mm, dy: -8.5mm)[
            #block(width: 118mm, spacing: 0pt)[
              #stack(
                dir: ttb,
                spacing: 8mm,
                block(width: 118mm)[
                  #set par(leading: 0.8em, justify: false, spacing: 0pt)
                  #text(
                    font: _t.font-display,
                    size: 36pt,
                    weight: 600,
                    tracking: -0.04em,
                    fill: _t.neutral-900,
                    title,
                  )#h(3pt)#box(
                    width: 8pt,
                    height: 8pt,
                    baseline: -2pt,
                    circle(fill: _t.primary, stroke: none),
                  )
                ],
                if subtitle != none {
                  block(width: 118mm)[
                    #set par(leading: 0.55em, justify: false, spacing: 0pt)
                    #text(
                      font: _t.font-serif,
                      size: 14pt,
                      weight: 300,
                      style: "italic",
                      fill: rgb("#484848"),
                      subtitle,
                    )
                  ]
                } else { [] },
              )
            ]
          ]
        ]
      ],

      // ---- Legal gutter --------------------------------------
      block(
        width: 100%,
        height: 265.642mm,
        fill: white,
        stroke: (left: 0.5pt + _publication-rule),
      )[
        #place(center + horizon, dx: 0.23mm,
          rotate(-90deg, origin: center + horizon,
            box(width: 175mm)[
              #set align(center)
              #text(
                font: "IBM Plex Mono", size: 6.75pt, weight: 500,
                tracking: 0.325em, fill: _publication-muted, upper(copyright),
              )
            ]
          )
        )
      ],

      // ---- Black brand rail ----------------------------------
      block(width: 100%, height: 265.642mm, fill: _publication-ink, clip: true)[
        #place(center + horizon,
          rotate(-90deg, origin: center + horizon,
            image(rail-wordmark, width: 248.8mm, fit: "contain")
          )
        )
      ],
    )
  ]

  // ---- Full-width footer (52 / 1056 px) ---------------------
  block(
    width: 100%,
    height: 13.758mm,
    fill: white,
    stroke: (top: 0.5pt + _publication-rule),
    inset: (left: 10.583mm, right: 11.112mm),
  )[
    #align(horizon, grid(
      columns: (1fr, auto),
      align: (left + horizon, right + horizon),
      {
        set text(font: "IBM Plex Mono", size: 7.5pt, weight: 500, tracking: 0.20em)
        text(weight: 600, fill: _publication-orange, "//")
        h(4.76mm)
        text(fill: _publication-ink, upper(publication-series))
      },
      text(
        font: "IBM Plex Mono",
        size: 7.5pt,
        weight: 500,
        tracking: 0.20em,
        fill: _publication-muted,
        upper(publication-location),
      ),
    ))
  ]

  // ---- Blank interstitial page (same behavior as chanwe-report)
  set page(
    paper: "us-letter", margin: 0pt, header: none, footer: none,
    fill: rgb("#F7F7F7"), foreground: none,
  )
  set block(spacing: 0pt)
  place(center + horizon, image(_chanwe-assets + "Iconos_Beige.png", width: 60mm, fit: "contain"))
  block(width: 100%, height: 229.4mm)[]
  block(
    width: 100%, height: 50mm, fill: rgb("#F7F7F7"),
    inset: (x: 14mm),
  )[
    #align(center + horizon,
      image(_chanwe-assets + "Logo_Beige.svg", height: 45mm, fit: "contain"))
  ]
}

// =============================================================
// BACK COVER — retained from chanwe-report, sized to US Letter
// =============================================================
#let _chanwe-blank-interstitial() = {
  set page(paper: "us-letter", margin: 0pt, header: none, footer: none, fill: rgb("#F7F7F7"), foreground: none)
  set block(spacing: 0pt)
  place(center + horizon, image(_chanwe-assets + "Iconos_Beige.png", width: 60mm, fit: "contain"))
  block(width: 100%, height: 279.4mm)[]
}

#let chanwe-back-cover-page(
  wordmark-light: none,
  tagline-1: "Less template,",
  tagline-2: "more report.",
  back-cols: (),
  cover-edge: none,
) = {
  let wl = if wordmark-light != none { _chanwe-clean-path(wordmark-light) } else { _chanwe-assets + "Logo_Blanco.svg" }

  _chanwe-blank-interstitial()

  set page(
    paper: "us-letter", margin: 0pt, header: none, footer: none, fill: _t.ink,
    background: place(top + left, dx: -50mm, dy: -50mm,
      circle(radius: 110mm,
        fill: gradient.radial(_t.primary.transparentize(93%), black.transparentize(100%)),
        stroke: none,
      )
    ),
    foreground: if cover-edge != none {
      place(right + top, dx: -3mm, dy: 14mm,
        rotate(-90deg, origin: right + horizon,
          text(font: _t.font-mono, size: 7pt, weight: 200, tracking: 0.5em,
               fill: white.transparentize(25%), upper(cover-edge))
        )
      )
    },
  )
  set block(spacing: 0pt)

  block(
    width: 100%, height: 279.4mm, breakable: false,
    inset: (x: 16mm, top: 14mm, bottom: 14mm),
  )[
    #grid(
      rows: (auto, 1fr, auto),
      row-gutter: 0pt,

      align(left + top,
        if wl != none {
          image(wl, height: 20.2mm, fit: "contain")
        } else {
          text(font: _t.font-display, size: 36pt, weight: 800,
               tracking: -0.04em, fill: white, "chanwe")
        }
      ),

      [],

      block[
        #image(_chanwe-assets + "Estrategia_Color.png", height: 10mm, fit: "contain")
        #v(12mm)
        #set par(leading: 0.8em, justify: false)
        #text(font: _t.font-serif, style: "italic", size: 40pt,
              weight: 300, fill: white, tagline-1)
        #linebreak()
        #text(font: _t.font-serif, style: "italic", size: 40pt,
              weight: 300, fill: _t.primary, tagline-2)
        #v(8mm)
        #line(length: 100%, stroke: 0.5pt + white.transparentize(75%))
        #v(8mm)
        #if back-cols.len() > 0 {
          grid(
            columns: back-cols.map(_ => 1fr),
            column-gutter: 8mm,
            ..back-cols.map(((label, value, sub)) => block(spacing: 0pt)[
              #text(font: _t.font-mono, size: 6pt, tracking: 0.20em,
                    fill: white.transparentize(50%), upper(label))
              #v(2.5mm)
              #text(font: _t.font-display, size: 9.5pt, weight: 700, fill: white, value)
              #if sub != none and sub != "" {
                linebreak()
                v(0.5mm)
                text(font: _t.font-sans, size: 8pt, fill: white.transparentize(40%), sub)
              }
            ])
          )
        }
      ],
    )
  ]
}
