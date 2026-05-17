// =============================================================
// chanwe-cover.typ — full-bleed A4 cover page (1:1 to HTML)
// =============================================================
// HTML grid:  10mm top bar | 1fr hero (rail 86mm + panel) | 50mm slab
// At A4 (297mm tall) the hero region is 237mm.
// =============================================================

// Pandoc/Quarto escapes underscores in YAML values (bg_x → bg\_x).
// Strip those backslashes so image() gets the real filesystem path.
#let _chanwe-clean-path(p) = if p == none { none } else { p.replace("\\_", "_").replace("\\-", "-") }

#let chanwe-cover-page(
  title: "Untitled",
  subtitle: none,
  doc-id: "CHW · DOC · 2026 · 01",
  edition: "Edition 01 / 2026",
  volume: "Vol. II",
  rail-eyebrow: "Quarto · Style Guide",
  hero-image: none,
  hero-img-position: none,  // 1–10 (left→right); none = fit:cover (centered)
  wordmark: none, // defaults to Logo_Negro.png below
  stamp: ("est.", "mdz", "2026"),
  hero-caption-1: "S 32°53′ · W 68°50′",
  hero-caption-2: "Cordón del Plata · ARG",
  hero-date: "17 · 04 · 2026",
  meta-rows: (),
  date: "",
  show-date-strip: false,
  cover-edge: none,
  cover-edge-color: none,
) = {
  let hero-image = if hero-image == none {
    _chanwe-assets + "hero-img.svg"
  } else {
    _chanwe-clean-path(hero-image)
  }
  let _edge-color = if cover-edge-color != none { cover-edge-color } else { _t.primary }
  let wordmark   = if wordmark == none { _chanwe-assets + "Logo_Negro.png" } else { _chanwe-clean-path(wordmark) }
  set page(
    paper: "a4", margin: 0pt, header: none, footer: none, fill: _t.paper,
    foreground: {
      place(top + left, dx: 50mm, dy: -50mm,
        circle(radius: 110mm,
          fill: gradient.radial(_t.primary.transparentize(78%), black.transparentize(100%)),
          stroke: none,
        )
      )
      if cover-edge != none {
        place(right + top, dx: -3mm, dy: 14mm,
          rotate(-90deg, origin: right + horizon,
            text(font: _t.font-mono, size: 7pt, weight: 200, tracking: 0.5em,
                 fill: _edge-color, upper(cover-edge))
          )
        )
      }
    },
  )
  set block(spacing: 0pt)

  // ---- 1. TOP METADATA BAR (10mm) ---------------------------
  block(
    width: 100%, height: 10mm,
    fill: _t.paper,
    stroke: (bottom: 0.5pt + _t.neutral-900),
    inset: (x: 16mm, y: 0pt),
  )[
    #set align(horizon)
    #grid(
      columns: (1fr, 1fr),
      align: (left + horizon, right + horizon),
      // doc id (left)
      {
        set text(font: _t.font-mono, size: 7pt, tracking: 0.16em, fill: _t.fg)
        text(weight: 700, fill: _t.primary, "//")
        h(6pt)
        upper[#text(weight: 600, fill: _t.fg, doc-id)]
      },
      // edition · volume (right)
      {
        set text(font: _t.font-mono, size: 7pt, tracking: 0.16em)
        upper[#text(weight: 600, fill: _t.fg, edition)]
        h(16pt)
        upper[#text(fill: _t.fg-muted, volume)]
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
        fill: _t.paper,
        stroke: (right: 1pt + _t.neutral-900),
        inset: (left: 16mm, right: 9mm, top: 14mm, bottom: 12mm),
      )[
        // eyebrow with rule
        #chanwe-eyebrow(rail-eyebrow, with-rule: true)

        #v(8mm)

        // big display title — emph parts render in Fraunces italic
        #set par(leading: 0.8em, justify: false)
        #show emph: it => text(font: _t.font-serif, size: 44pt, weight: 200, style: "italic", fill: _t.primary, it.body)
        #block[
          #text(
            font: _t.font-display, size: 36pt, weight: 600,
            tracking: -0.04em, fill: _t.neutral-900,
            title,
          )#h(3pt)#box(width: 8pt, height: 8pt, baseline: -2pt,
            circle(fill: _t.primary, stroke: none))
        ]

        #if subtitle != none {
          v(8mm)
          set par(leading: 0.55em)
          set text(font: _t.font-serif, size: 14pt, weight: 200, style: "italic", fill: _t.fg-subtle)
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
          // place() must be in direct content flow; context{} computes the
          // shift and returns move(dx, img) which gets placed at top+left
          place(top + left,
            context {
              let pos-frac = calc.clamp((hero-img-position - 1) / 9, 0, 1)
              let img = image(hero-image, height: 237mm)
              let excess = calc.max(measure(img).width - 73.5mm, 0pt)
              move(dx: -pos-frac * excess, img)
            }
          )
        }


        // Bottom-right caption (geographic coords)
        #place(bottom + right, dx: -16mm, dy: -16mm)[
          #box(
            inset: (x: 8pt, y: 4pt),
            fill: white.transparentize(50%),
            stroke: 0.5pt + black.transparentize(90%),
          )[
            #set align(right)
            #set par(leading: 0.4em)
            #text(
              font: _t.font-mono, size: 6.5pt, weight: 500, tracking: 0.20em,
              fill: black.transparentize(35%),
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
  block(
    width: 100%, height: 50mm,
    fill: _t.paper,
    stroke: (top: 0.5pt + _t.neutral-900),
    inset: (x: 14mm, top: 0mm, bottom: 0mm),
  )[
    #set align(center + horizon)
    #align(center + horizon, image(wordmark, height: 45mm, fit: "contain"))
  ]

  // ---- BLANK INTERSTITIAL PAGE ------------------------------
  set page(paper: "a4", margin: 0pt, header: none, footer: none, fill: _t.neutral-100, foreground: none)
  set block(spacing: 0pt)

  // centered icon
  place(center + horizon, image(_chanwe-assets + "Iconos_Beige.png", width: 60mm, fit: "contain"))

  // full-height spacer pushes wordmark to bottom
  block(width: 100%, height: 247mm)[]
  block(
    width: 100%, height: 50mm,
    fill: _t.neutral-100,
    inset: (x: 14mm, top: 0mm, bottom: 0mm),
  )[
    #set align(center + horizon)
    #align(center + horizon, image(_chanwe-assets + "Logo_Beige.png", height: 45mm, fit: "contain"))
  ]
}

// =============================================================
// BACK COVER — full-bleed black page
// =============================================================
#let _chanwe-blank-interstitial() = {
  set page(paper: "a4", margin: 0pt, header: none, footer: none, fill: _t.neutral-100, foreground: none)
  set block(spacing: 0pt)
  place(center + horizon, image(_chanwe-assets + "Iconos_Beige.png", width: 60mm, fit: "contain"))
  block(width: 100%, height: 297mm)[]
}

#let chanwe-back-cover-page(
  wordmark-light: none,
  tagline-1: "Less template,",
  tagline-2: "more report.",
  back-cols: (),
  cover-edge: none,
) = {
  let wl = if wordmark-light != none { _chanwe-clean-path(wordmark-light) } else { _chanwe-assets + "Logo_Blanco.png" }

  // ---- blank interstitial before back cover -----------------
  _chanwe-blank-interstitial()

  // ---- back cover -------------------------------------------
  set page(
    paper: "a4", margin: 0pt, header: none, footer: none, fill: _t.ink,
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
    width: 100%, height: 297mm, breakable: false,
    inset: (x: 16mm, top: 14mm, bottom: 14mm),
  )[
    #grid(
      rows: (auto, 1fr, auto),
      row-gutter: 0pt,

      // Row 1: wordmark
      align(left + top,
        if wl != none {
          image(wl, height: 20.2mm, fit: "contain")
        } else {
          text(font: _t.font-display, size: 36pt, weight: 800,
               tracking: -0.04em, fill: white, "chanwe")
        }
      ),

      // Row 2: spacer
      [],

      // Row 3: icon + tagline + separator + metadata
      block[
        #image(_chanwe-assets + "Estrategia_Color.png", height: 10mm, fit: "contain")
        #v(12mm)
        #set par(leading: 0.8em, justify: false)
        #text(font: _t.font-serif, style: "italic", size: 40pt,
              weight: 200, fill: white, tagline-1)
        #linebreak()
        #text(font: _t.font-serif, style: "italic", size: 40pt,
              weight: 200, fill: _t.primary, tagline-2)
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
